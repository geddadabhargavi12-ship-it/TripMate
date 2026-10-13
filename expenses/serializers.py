from rest_framework import serializers

from .models import Expense


class ExpenseSerializer(serializers.ModelSerializer):
    class Meta:
        model = Expense
        fields = ['id', 'itinerary', 'title', 'category', 'amount', 'notes', 'created_at', 'updated_at']
        read_only_fields = ['created_at', 'updated_at']

    def validate_itinerary(self, itinerary):
        request = self.context.get('request')
        if request and itinerary.user_id != request.user.id:
            raise serializers.ValidationError('You can only add expenses to your own trips.')
        return itinerary
