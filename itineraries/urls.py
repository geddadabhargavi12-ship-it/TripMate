from django.urls import path

from .views import ItineraryDetailView, ItineraryListCreateView

urlpatterns = [
    path('', ItineraryListCreateView.as_view(), name='itinerary-list-create'),
    path('<int:pk>/', ItineraryDetailView.as_view(), name='itinerary-detail'),
]
