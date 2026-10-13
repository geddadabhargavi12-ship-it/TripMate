from datetime import date

from django.contrib.auth import get_user_model
from rest_framework.test import APITestCase

from destinations.models import Destination
from itineraries.models import Itinerary

User = get_user_model()


class ExpenseOwnershipTests(APITestCase):
	def setUp(self):
		self.owner = User.objects.create_user(
			username='trip-owner', email='owner@example.com', password='Pass123!'
		)
		self.other_user = User.objects.create_user(
			username='other-traveler', email='other@example.com', password='Pass123!'
		)
		destination = Destination.objects.create(
			name='Goa', slug='goa-expense-test', country='India', state='Goa', city='Panaji',
			category='Beach', description='Coastal trip', best_time_to_visit='Winter',
			daily_budget=3000, trip_duration_days=3, latitude=15.3, longitude=74.1,
		)
		self.itinerary = Itinerary.objects.create(
			user=self.owner, destination=destination, trip_name='Goa trip',
			start_date=date(2026, 11, 1), end_date=date(2026, 11, 3),
			travelers_count=1, total_budget=10000,
		)
		self.client.force_authenticate(user=self.other_user)

	def test_user_cannot_add_expense_to_another_users_trip(self):
		response = self.client.post('/api/expenses/', {
			'itinerary': self.itinerary.id,
			'title': 'Hotel',
			'category': 'accommodation',
			'amount': '2500.00',
		}, format='json')

		self.assertEqual(response.status_code, 400)
		self.assertFalse(self.itinerary.expenses.exists())

	def test_user_can_add_expense_to_their_own_trip(self):
		self.client.force_authenticate(user=self.owner)
		response = self.client.post('/api/expenses/', {
			'itinerary': self.itinerary.id,
			'title': 'Hotel',
			'category': 'accommodation',
			'amount': '2500.00',
		}, format='json')

		self.assertEqual(response.status_code, 201)
		self.assertEqual(self.itinerary.expenses.count(), 1)
