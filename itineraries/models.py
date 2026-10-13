from django.conf import settings
from django.core.exceptions import ValidationError
from django.db import models

from destinations.models import Destination


class Itinerary(models.Model):
    STATUS_CHOICES = [
        ('draft', 'Draft'),
        ('planned', 'Planned'),
        ('active', 'Active'),
        ('completed', 'Completed'),
        ('cancelled', 'Cancelled'),
    ]

    user = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.CASCADE, related_name='itineraries')
    destination = models.ForeignKey(Destination, on_delete=models.SET_NULL, null=True, blank=True, related_name='itineraries')
    trip_name = models.CharField(max_length=200)
    start_date = models.DateField()
    end_date = models.DateField()
    travelers_count = models.PositiveIntegerField(default=1)
    total_budget = models.DecimalField(max_digits=12, decimal_places=2, default=0)
    status = models.CharField(max_length=20, choices=STATUS_CHOICES, default='draft')
    notes = models.TextField(blank=True)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        indexes = [models.Index(fields=['user', 'start_date']), models.Index(fields=['status'])]

    def clean(self):
        if self.end_date < self.start_date:
            raise ValidationError('End date must be on or after the start date.')

    def save(self, *args, **kwargs):
        self.full_clean()
        super().save(*args, **kwargs)

    def day_count(self):
        if self.start_date and self.end_date:
            return (self.end_date - self.start_date).days + 1
        return 0

    def budget_summary(self):
        from expenses.models import Expense
        actual_total = sum((expense.amount for expense in self.expenses.all()), 0)
        planned_total = self.total_budget
        remaining_budget = planned_total - actual_total
        return {
            'planned_total': float(planned_total),
            'actual_total': float(actual_total),
            'remaining_budget': float(remaining_budget),
            'days': self.day_count(),
        }

    def __str__(self):
        return self.trip_name


class ItineraryDay(models.Model):
    itinerary = models.ForeignKey(Itinerary, on_delete=models.CASCADE, related_name='days')
    day_number = models.PositiveIntegerField(default=1)
    title = models.CharField(max_length=200, blank=True)
    note = models.TextField(blank=True)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ['day_number']


class ItineraryActivity(models.Model):
    day = models.ForeignKey(ItineraryDay, on_delete=models.CASCADE, related_name='activities')
    title = models.CharField(max_length=200)
    notes = models.TextField(blank=True)
    activity_type = models.CharField(max_length=50, default='attraction')
    time_from = models.TimeField(null=True, blank=True)
    time_to = models.TimeField(null=True, blank=True)
    estimated_cost = models.DecimalField(max_digits=12, decimal_places=2, default=0)
    order = models.PositiveIntegerField(default=0)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ['order', 'time_from']
