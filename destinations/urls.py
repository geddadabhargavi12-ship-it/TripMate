from django.urls import path

from .views import (
    DestinationDetailView,
    DestinationListView,
    PlaceDiscoveryView,
    PlaceRouteView,
    SaveDiscoveredPlaceView,
    AddDiscoveredPlaceToItineraryView,
    SaveDestinationAPIView,
    SavedDestinationListView,
)

urlpatterns = [
    path('discover/', PlaceDiscoveryView.as_view(), name='place-discovery'),
    path('route/', PlaceRouteView.as_view(), name='place-route'),
    path('places/save/', SaveDiscoveredPlaceView.as_view(), name='save-discovered-place'),
    path('places/add-to-itinerary/', AddDiscoveredPlaceToItineraryView.as_view(), name='add-discovered-place-to-itinerary'),
    path('', DestinationListView.as_view(), name='destinations-list'),
    path('<int:pk>/', DestinationDetailView.as_view(), name='destination-detail'),
    path('<int:pk>/save/', SaveDestinationAPIView.as_view(), name='save-destination'),
    path('saved/', SavedDestinationListView.as_view(), name='saved-destinations'),
]
