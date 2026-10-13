from rest_framework import serializers

from .models import TravelVideo


class TravelVideoSerializer(serializers.ModelSerializer):
    class Meta:
        model = TravelVideo
        fields = ['id', 'title', 'description', 'category', 'destination', 'video_url', 'thumbnail_url', 'is_featured']
