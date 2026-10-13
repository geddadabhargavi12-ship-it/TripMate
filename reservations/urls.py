from django.urls import path

from .views import ReservationDetailView, ReservationListCreateView, ReservationQRCodeAPIView, VerifyQRCodeAPIView

urlpatterns = [
    path('', ReservationListCreateView.as_view(), name='reservation-list-create'),
    path('<int:pk>/', ReservationDetailView.as_view(), name='reservation-detail'),
    path('<int:pk>/qr/', ReservationQRCodeAPIView.as_view(), name='reservation-qr'),
    path('verify-qr/', VerifyQRCodeAPIView.as_view(), name='verify-qr'),
]
