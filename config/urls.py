from django.contrib import admin
from django.urls import include, path

urlpatterns = [
    path('admin/', admin.site.urls),
    path('api/auth/', include('accounts.urls')),
    path('api/destinations/', include('destinations.urls')),
    path('api/itineraries/', include('itineraries.urls')),
    path('api/expenses/', include('expenses.urls')),
    path('api/reservations/', include('reservations.urls')),
    path('api/videos/', include('travel_videos.urls')),
    path('api/notifications/', include('notifications.urls')),
]
