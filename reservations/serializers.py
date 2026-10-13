from rest_framework import serializers

from .models import QRCheckIn, Reservation


class ReservationSerializer(serializers.ModelSerializer):
    class Meta:
        model = Reservation
        fields = [
            'id', 'user', 'destination', 'title', 'start_date', 'end_date', 'travelers_count',
            'status', 'amount', 'payment_status', 'notes', 'created_at', 'updated_at'
        ]
        read_only_fields = ['user', 'created_at', 'updated_at']

    def create(self, validated_data):
        validated_data['user'] = self.context['request'].user
        reservation = Reservation.objects.create(**validated_data)
        reservation.issue_qr()
        return reservation


class QRCheckInSerializer(serializers.ModelSerializer):
    class Meta:
        model = QRCheckIn
        fields = ['id', 'reservation', 'token', 'expires_at', 'used_at', 'status']
        read_only_fields = ['token', 'status', 'expires_at', 'used_at']
