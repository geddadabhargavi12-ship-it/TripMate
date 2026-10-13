from rest_framework import serializers
from .models import Attraction, Destination, DestinationImage, SavedDestination


class AttractionSerializer(serializers.ModelSerializer):
    class Meta:
        model = Attraction
        fields = ['id', 'name', 'description', 'latitude', 'longitude', 'category']


class DestinationImageSerializer(serializers.ModelSerializer):
    class Meta:
        model = DestinationImage
        fields = ['id', 'image_url', 'caption', 'is_primary']


class DestinationSerializer(serializers.ModelSerializer):
    attractions = AttractionSerializer(many=True, read_only=True)
    images = DestinationImageSerializer(many=True, read_only=True)

    class Meta:
        model = Destination
        fields = [
            'id', 'name', 'slug', 'country', 'state', 'city', 'category', 'description',
            'best_time_to_visit', 'daily_budget', 'trip_duration_days', 'latitude', 'longitude',
            'provider_place_id', 'place_address', 'website_url', 'is_featured',
            'attractions', 'images'
        ]


class SavedDestinationSerializer(serializers.ModelSerializer):
    destination = DestinationSerializer(read_only=True)

    class Meta:
        model = SavedDestination
        fields = ['id', 'destination', 'saved_at']
