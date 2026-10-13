from django.conf import settings
from django.db import models


class Destination(models.Model):
    CATEGORY_CHOICES = [
        ('Beach', 'Beach'),
        ('Mountain', 'Mountain'),
        ('City', 'City'),
        ('Heritage', 'Heritage'),
        ('Nature', 'Nature'),
        ('Adventure', 'Adventure'),
    ]

    name = models.CharField(max_length=200)
    slug = models.SlugField(unique=True)
    country = models.CharField(max_length=120, blank=True)
    state = models.CharField(max_length=120, blank=True)
    city = models.CharField(max_length=120, blank=True)
    category = models.CharField(max_length=40, choices=CATEGORY_CHOICES, default='Nature')
    description = models.TextField()
    best_time_to_visit = models.CharField(max_length=200, blank=True)
    daily_budget = models.DecimalField(max_digits=12, decimal_places=2, default=0)
    trip_duration_days = models.PositiveIntegerField(default=3)
    latitude = models.FloatField(default=0.0)
    longitude = models.FloatField(default=0.0)
    provider_place_id = models.CharField(max_length=255, unique=True, null=True, blank=True)
    place_address = models.TextField(blank=True)
    website_url = models.URLField(blank=True)
    is_featured = models.BooleanField(default=False)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        indexes = [
            models.Index(fields=['category']),
            models.Index(fields=['country']),
            models.Index(fields=['state']),
            models.Index(fields=['is_featured']),
        ]

    def __str__(self):
        return self.name


class Attraction(models.Model):
    destination = models.ForeignKey(Destination, on_delete=models.CASCADE, related_name='attractions')
    name = models.CharField(max_length=200)
    description = models.TextField(blank=True)
    latitude = models.FloatField(default=0.0)
    longitude = models.FloatField(default=0.0)
    category = models.CharField(max_length=60, blank=True)

    class Meta:
        constraints = [models.UniqueConstraint(fields=['destination', 'name'], name='unique_attraction_name')]

    def __str__(self):
        return f'{self.destination.name} - {self.name}'


class DestinationImage(models.Model):
    destination = models.ForeignKey(Destination, on_delete=models.CASCADE, related_name='images')
    image_url = models.URLField()
    caption = models.CharField(max_length=200, blank=True)
    is_primary = models.BooleanField(default=False)

    class Meta:
        indexes = [models.Index(fields=['destination', 'is_primary'])]


class SavedDestination(models.Model):
    user = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.CASCADE, related_name='saved_destinations')
    destination = models.ForeignKey(Destination, on_delete=models.CASCADE, related_name='saved_by_users')
    saved_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        constraints = [models.UniqueConstraint(fields=['user', 'destination'], name='unique_saved_destination')]

    def __str__(self):
        return f'{self.user.email} saved {self.destination.name}'
