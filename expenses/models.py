from django.conf import settings
from django.db import models

from itineraries.models import Itinerary


class Expense(models.Model):
    CATEGORY_CHOICES = [
        ('transport', 'Transportation'),
        ('accommodation', 'Accommodation'),
        ('food', 'Food'),
        ('activities', 'Activities'),
        ('shopping', 'Shopping'),
        ('other', 'Other expenses'),
    ]

    itinerary = models.ForeignKey(Itinerary, on_delete=models.CASCADE, related_name='expenses')
    title = models.CharField(max_length=200)
    category = models.CharField(max_length=50, choices=CATEGORY_CHOICES)
    amount = models.DecimalField(max_digits=12, decimal_places=2, default=0)
    notes = models.TextField(blank=True)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        ordering = ['-created_at']
        indexes = [models.Index(fields=['itinerary', 'category'])]

    def __str__(self):
        return f'{self.title} - ₹{self.amount}'
