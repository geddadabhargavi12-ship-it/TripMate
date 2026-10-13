from django.urls import path

from .views import TravelVideoDetailView, TravelVideoListView

urlpatterns = [
    path('', TravelVideoListView.as_view(), name='travel-videos-list'),
    path('<int:pk>/', TravelVideoDetailView.as_view(), name='travel-video-detail'),
]
