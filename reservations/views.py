from django.shortcuts import get_object_or_404
from django.utils import timezone
from rest_framework import generics, status
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response
from rest_framework.views import APIView

from .models import QRCheckIn, Reservation
from .serializers import ReservationSerializer


class ReservationListCreateView(generics.ListCreateAPIView):
    serializer_class = ReservationSerializer
    permission_classes = [IsAuthenticated]

    def get_queryset(self):
        return Reservation.objects.filter(user=self.request.user).order_by('-created_at')

    def perform_create(self, serializer):
        serializer.save(user=self.request.user)


class ReservationDetailView(generics.RetrieveUpdateDestroyAPIView):
    serializer_class = ReservationSerializer
    permission_classes = [IsAuthenticated]

    def get_queryset(self):
        return Reservation.objects.filter(user=self.request.user)


class ReservationQRCodeAPIView(APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request, pk):
        reservation = get_object_or_404(Reservation, pk=pk, user=request.user)
        qr = reservation.issue_qr()
        return Response({'token': qr.token, 'status': qr.status})


class VerifyQRCodeAPIView(APIView):
    permission_classes = [IsAuthenticated]

    def post(self, request):
        token = request.data.get('token')
        if not token:
            return Response({'detail': 'A QR token is required.'}, status=status.HTTP_400_BAD_REQUEST)
        qr = QRCheckIn.objects.filter(token=token).first()
        if not qr:
            return Response({'status': 'invalid'}, status=status.HTTP_400_BAD_REQUEST)
        if qr.reservation.user != request.user and not request.user.is_staff:
            return Response({'status': 'unauthorized'}, status=status.HTTP_403_FORBIDDEN)
        if qr.used_at:
            return Response({'status': 'already_used'})
        if qr.expires_at < timezone.now():
            qr.status = 'expired'
            qr.save(update_fields=['status'])
            return Response({'status': 'expired'})
        qr.mark_used()
        return Response({'status': 'valid', 'reservation_id': qr.reservation.id})
