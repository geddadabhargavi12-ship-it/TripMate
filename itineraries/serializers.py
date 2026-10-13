from rest_framework import serializers

from .models import Itinerary, ItineraryActivity, ItineraryDay


class ItineraryActivitySerializer(serializers.ModelSerializer):
    class Meta:
        model = ItineraryActivity
        fields = ['id', 'title', 'notes', 'activity_type', 'time_from', 'time_to', 'estimated_cost', 'order']


class ItineraryDaySerializer(serializers.ModelSerializer):
    activities = ItineraryActivitySerializer(many=True, read_only=True)

    class Meta:
        model = ItineraryDay
        fields = ['id', 'day_number', 'title', 'note', 'activities']


class ItinerarySerializer(serializers.ModelSerializer):
    days = ItineraryDaySerializer(many=True, read_only=True)

    class Meta:
        model = Itinerary
        fields = [
            'id', 'user', 'destination', 'trip_name', 'start_date', 'end_date', 'travelers_count',
            'total_budget', 'status', 'notes', 'days', 'created_at', 'updated_at'
        ]
        read_only_fields = ['user', 'created_at', 'updated_at']

    def create(self, validated_data):
        user = self.context['request'].user
        validated_data['user'] = user
        return super().create(validated_data)
