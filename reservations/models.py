import hashlib
import secrets
from datetime import timedelta

from django.conf import settings
from django.db import models
from django.utils import timezone

from destinations.models import Destination


class Reservation(models.Model):
    STATUS_CHOICES = [
        ('pending', 'Pending'),
        ('confirmed', 'Confirmed'),
        ('cancelled', 'Cancelled'),
        ('completed', 'Completed'),
    ]

    user = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.CASCADE, related_name='reservations')
    destination = models.ForeignKey(Destination, on_delete=models.CASCADE, related_name='reservations')
    title = models.CharField(max_length=200)
    start_date = models.DateField()
    end_date = models.DateField()
    travelers_count = models.PositiveIntegerField(default=1)
    status = models.CharField(max_length=20, choices=STATUS_CHOICES, default='pending')
    amount = models.DecimalField(max_digits=12, decimal_places=2, default=0)
    payment_status = models.CharField(max_length=20, default='sample', blank=True)
    notes = models.TextField(blank=True)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        indexes = [models.Index(fields=['user', 'status']), models.Index(fields=['destination'])]

    def __str__(self):
        return self.title

    def issue_qr(self):
        token = secrets.token_urlsafe(24)
        expires_at = timezone.now() + timedelta(days=7)
        qr = QRCheckIn.objects.create(reservation=self, token=token, expires_at=expires_at)
        return qr


class QRCheckIn(models.Model):
    STATUS_CHOICES = [
        ('active', 'Active'),
        ('used', 'Used'),
        ('expired', 'Expired'),
    ]

    reservation = models.ForeignKey(Reservation, on_delete=models.CASCADE, related_name='qr_codes')
    token = models.CharField(max_length=255, unique=True)
    expires_at = models.DateTimeField()
    used_at = models.DateTimeField(null=True, blank=True)
    status = models.CharField(max_length=20, choices=STATUS_CHOICES, default='active')
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        indexes = [models.Index(fields=['reservation', 'status'])]

    @staticmethod
    def hash_token(token: str):
        return hashlib.sha256(token.encode('utf-8')).hexdigest()

    def mark_used(self):
        self.used_at = timezone.now()
        self.status = 'used'
        self.save(update_fields=['used_at', 'status'])

    def __str__(self):
        return f'{self.reservation.title} QR'
