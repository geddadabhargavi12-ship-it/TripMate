from django.db.models import Sum
from rest_framework import generics, status
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response
from rest_framework.views import APIView

from itineraries.models import Itinerary
from .models import Expense
from .serializers import ExpenseSerializer


class ExpenseListCreateView(generics.ListCreateAPIView):
    serializer_class = ExpenseSerializer
    permission_classes = [IsAuthenticated]

    def get_queryset(self):
        itinerary_id = self.request.query_params.get('itinerary')
        queryset = Expense.objects.filter(itinerary__user=self.request.user)
        if itinerary_id:
            queryset = queryset.filter(itinerary_id=itinerary_id)
        return queryset.order_by('-created_at')

    def perform_create(self, serializer):
        serializer.save()


class ExpenseDetailView(generics.RetrieveUpdateDestroyAPIView):
    serializer_class = ExpenseSerializer
    permission_classes = [IsAuthenticated]

    def get_queryset(self):
        return Expense.objects.filter(itinerary__user=self.request.user)


class BudgetSummaryAPIView(APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request):
        itinerary_id = request.query_params.get('itinerary')
        itinerary = Itinerary.objects.filter(pk=itinerary_id, user=request.user).first()
        if not itinerary:
            return Response({'detail': 'Trip not found.'}, status=status.HTTP_404_NOT_FOUND)
        expenses = itinerary.expenses.all()
        actual_total = sum((expense.amount for expense in expenses), 0)
        summary = {
            'currency': 'INR',
            'planned_total': float(itinerary.total_budget),
            'actual_total': float(actual_total),
            'remaining_budget': float(itinerary.total_budget - actual_total),
            'category_breakdown': {
                item['category']: float(item['total']) for item in expenses.values('category').annotate(total=Sum('amount'))
            },
        }
        return Response(summary)
