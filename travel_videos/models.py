from django.db import models

from destinations.models import Destination


class TravelVideo(models.Model):
    category = models.CharField(max_length=80, default='destination')
    title = models.CharField(max_length=200)
    description = models.TextField(blank=True)
    destination = models.ForeignKey(Destination, on_delete=models.SET_NULL, null=True, blank=True, related_name='videos')
    video_url = models.URLField()
    thumbnail_url = models.URLField(blank=True)
    is_featured = models.BooleanField(default=False)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        ordering = ['-is_featured', '-created_at']

    def __str__(self):
        return self.title
