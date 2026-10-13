from django.db.models import Q
from rest_framework import generics
from rest_framework.permissions import AllowAny

from .models import TravelVideo
from .serializers import TravelVideoSerializer


class TravelVideoListView(generics.ListAPIView):
    serializer_class = TravelVideoSerializer
    permission_classes = [AllowAny]

    def get_queryset(self):
        queryset = TravelVideo.objects.select_related('destination')
        destination_id = self.request.query_params.get('destination')
        search = self.request.query_params.get('search', '').strip()
        if destination_id:
            queryset = queryset.filter(destination_id=destination_id)
        if search:
            queryset = queryset.filter(Q(title__icontains=search) | Q(description__icontains=search))
        return queryset.order_by('-is_featured', '-created_at')


class TravelVideoDetailView(generics.RetrieveAPIView):
    queryset = TravelVideo.objects.select_related('destination')
    serializer_class = TravelVideoSerializer
    permission_classes = [AllowAny]
