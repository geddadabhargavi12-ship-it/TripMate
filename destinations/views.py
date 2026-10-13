import math

from django.db.models import Q
from django.db.models import Max
from django.shortcuts import get_object_or_404
from rest_framework import generics, status
from rest_framework.permissions import AllowAny, IsAuthenticated
from rest_framework.response import Response
from rest_framework.throttling import ScopedRateThrottle
from rest_framework.views import APIView

from itineraries.models import Itinerary, ItineraryActivity, ItineraryDay

from .place_search import (
    GeoapifyConfigurationError,
    GeoapifyProviderError,
    search_places,
)
from .place_persistence import persist_discovered_place
from .place_routing import (
    GeoapifyRoutingConfigurationError,
    GeoapifyRoutingProviderError,
    calculate_route,
)
from .models import Destination, SavedDestination
from .serializers import DestinationSerializer, SavedDestinationSerializer


class PlaceDiscoveryView(APIView):
    permission_classes = [AllowAny]
    throttle_classes = [ScopedRateThrottle]
    throttle_scope = 'place_search'

    def get(self, request):
        query = request.query_params.get('q', '').strip()
        if len(query) < 2:
            return Response(
                {'detail': 'Enter at least two characters to search places.'},
                status=status.HTTP_400_BAD_REQUEST,
            )
        try:
            limit = min(max(int(request.query_params.get('limit', 20)), 1), 20)
        except (TypeError, ValueError):
            return Response(
                {'detail': 'Limit must be a whole number.'},
                status=status.HTTP_400_BAD_REQUEST,
            )

        try:
            results = search_places(query, limit=limit)
        except GeoapifyConfigurationError:
            return Response(
                {'detail': 'Place search is not configured. Set GEOAPIFY_API_KEY on the server.'},
                status=status.HTTP_503_SERVICE_UNAVAILABLE,
            )
        except GeoapifyProviderError:
            return Response(
                {'detail': 'The place provider is temporarily unavailable. Please retry.'},
                status=status.HTTP_502_BAD_GATEWAY,
            )

        return Response(
            {
                'results': results,
                'attribution': 'Powered by Geoapify | © OpenStreetMap contributors',
            }
        )


class PlaceRouteView(APIView):
    permission_classes = [AllowAny]
    throttle_classes = [ScopedRateThrottle]
    throttle_scope = 'place_route'

    def get(self, request):
        coordinate_names = (
            'origin_lat',
            'origin_lon',
            'destination_lat',
            'destination_lon',
        )
        coordinates = {}
        for name in coordinate_names:
            try:
                value = float(request.query_params.get(name, ''))
            except (TypeError, ValueError):
                return Response(
                    {'detail': f'{name} must be a valid coordinate.'},
                    status=status.HTTP_400_BAD_REQUEST,
                )
            if not math.isfinite(value):
                return Response(
                    {'detail': f'{name} must be a finite coordinate.'},
                    status=status.HTTP_400_BAD_REQUEST,
                )
            coordinates[name] = value

        for name in ('origin_lat', 'destination_lat'):
            if not -90 <= coordinates[name] <= 90:
                return Response(
                    {'detail': f'{name} must be between -90 and 90.'},
                    status=status.HTTP_400_BAD_REQUEST,
                )
        for name in ('origin_lon', 'destination_lon'):
            if not -180 <= coordinates[name] <= 180:
                return Response(
                    {'detail': f'{name} must be between -180 and 180.'},
                    status=status.HTTP_400_BAD_REQUEST,
                )

        try:
            route = calculate_route(
                coordinates['origin_lat'],
                coordinates['origin_lon'],
                coordinates['destination_lat'],
                coordinates['destination_lon'],
            )
        except GeoapifyRoutingConfigurationError:
            return Response(
                {'detail': 'Route planning is not configured. Set GEOAPIFY_API_KEY on the server.'},
                status=status.HTTP_503_SERVICE_UNAVAILABLE,
            )
        except GeoapifyRoutingProviderError:
            return Response(
                {'detail': 'A driving route could not be calculated. Please retry or choose another place.'},
                status=status.HTTP_502_BAD_GATEWAY,
            )

        return Response(route)


class SaveDiscoveredPlaceView(APIView):
    permission_classes = [IsAuthenticated]

    def post(self, request):
        try:
            destination = persist_discovered_place(request.data.get('place'))
        except ValueError as error:
            return Response({'detail': str(error)}, status=status.HTTP_400_BAD_REQUEST)

        saved, created = SavedDestination.objects.get_or_create(
            user=request.user,
            destination=destination,
        )
        if not created:
            saved.delete()
            return Response({'saved': False, 'destination_id': destination.pk})
        return Response({'saved': True, 'destination_id': destination.pk})


class AddDiscoveredPlaceToItineraryView(APIView):
    permission_classes = [IsAuthenticated]

    def post(self, request):
        itinerary_id = request.data.get('itinerary_id')
        itinerary = get_object_or_404(
            Itinerary.objects.filter(user=request.user),
            pk=itinerary_id,
        )
        try:
            destination = persist_discovered_place(request.data.get('place'))
        except ValueError as error:
            return Response({'detail': str(error)}, status=status.HTTP_400_BAD_REQUEST)

        day = itinerary.days.order_by('-day_number').first()
        if day is None:
            day = ItineraryDay.objects.create(
                itinerary=itinerary,
                day_number=1,
                title=destination.name,
            )
        last_order = day.activities.aggregate(last_order=Max('order'))['last_order']
        activity = ItineraryActivity.objects.create(
            day=day,
            title=destination.name,
            notes='\n'.join(
                value
                for value in (
                    destination.place_address,
                    f'Coordinates: {destination.latitude}, {destination.longitude}',
                    f'Website: {destination.website_url}' if destination.website_url else '',
                )
                if value
            ),
            activity_type='place',
            order=(last_order or 0) + 1,
        )
        return Response(
            {'activity_id': activity.pk, 'itinerary_id': itinerary.pk},
            status=status.HTTP_201_CREATED,
        )


class DestinationListView(generics.ListAPIView):
    serializer_class = DestinationSerializer
    permission_classes = [AllowAny]

    def get_queryset(self):
        queryset = Destination.objects.all().prefetch_related('attractions', 'images')
        query = self.request.query_params.get('search', '').strip()
        state = self.request.query_params.get('state')
        country = self.request.query_params.get('country')
        category = self.request.query_params.get('category')
        max_budget = self.request.query_params.get('max_budget')

        if query:
            queryset = queryset.filter(Q(name__icontains=query) | Q(description__icontains=query) | Q(city__icontains=query))
        if state:
            queryset = queryset.filter(state__icontains=state)
        if country:
            queryset = queryset.filter(country__icontains=country)
        if category:
            queryset = queryset.filter(category__icontains=category)
        if max_budget:
            queryset = queryset.filter(daily_budget__lte=max_budget)
        return queryset.order_by('-is_featured', 'name')


class DestinationDetailView(generics.RetrieveAPIView):
    queryset = Destination.objects.all().prefetch_related('attractions', 'images')
    serializer_class = DestinationSerializer
    permission_classes = [AllowAny]


class SaveDestinationAPIView(APIView):
    permission_classes = [IsAuthenticated]

    def post(self, request, pk):
        destination = Destination.objects.filter(pk=pk).first()
        if not destination:
            return Response({'detail': 'Destination not found.'}, status=status.HTTP_404_NOT_FOUND)
        saved, created = SavedDestination.objects.get_or_create(user=request.user, destination=destination)
        if not created:
            saved.delete()
            return Response({'saved': False, 'detail': 'Destination removed from saved list.'})
        return Response({'saved': True, 'detail': 'Destination saved.'})


class SavedDestinationListView(generics.ListAPIView):
    serializer_class = SavedDestinationSerializer
    permission_classes = [IsAuthenticated]

    def get_queryset(self):
        return SavedDestination.objects.filter(user=self.request.user).select_related('destination').order_by('-saved_at')
