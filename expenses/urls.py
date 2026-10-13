from django.urls import path

from .views import BudgetSummaryAPIView, ExpenseDetailView, ExpenseListCreateView

urlpatterns = [
    path('', ExpenseListCreateView.as_view(), name='expense-list-create'),
    path('<int:pk>/', ExpenseDetailView.as_view(), name='expense-detail'),
    path('budget-summary/', BudgetSummaryAPIView.as_view(), name='budget-summary'),
]
