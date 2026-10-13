import pytest
from datetime import date
from django.contrib.auth import get_user_model
from destinations.models import Destination, SavedDestination
from itineraries.models import Itinerary
from expenses.models import Expense
from reservations.models import Reservation, QRCheckIn

User = get_user_model()


def test_user_can_register(db):
    user = User.objects.create_user(
        username='traveler1',
        email='traveler1@example.com',
        password='TestPass123!'
    )
    assert user.email == 'traveler1@example.com'
    assert user.check_password('TestPass123!') is True


def test_destination_search_returns_result(db):
    destination = Destination.objects.create(
        name='Araku Valley',
        slug='araku-valley',
        country='India',
        state='Andhra Pradesh',
        city='Araku',
        category='Nature',
        description='Mountain valley with tribal heritage',
        best_time_to_visit='October to February',
        daily_budget=2500,
        trip_duration_days=3,
        latitude=18.3279,
        longitude=82.8683,
    )
    result = Destination.objects.filter(name__icontains='Araku').first()
    assert result == destination


def test_itinerary_budget_summary(db):
    user = User.objects.create_user(username='u1', email='u1@example.com', password='Pass123!')
    destination = Destination.objects.create(
        name='Goa', slug='goa', country='India', state='Goa', city='Panaji',
        category='Beach', description='Coastal escape', best_time_to_visit='November to March',
        daily_budget=4200, trip_duration_days=4, latitude=15.2993, longitude=74.1240
    )
    itinerary = Itinerary.objects.create(
        user=user, destination=destination, trip_name='Goa getaway',
        start_date=date(2026, 1, 10), end_date=date(2026, 1, 14), travelers_count=2, total_budget=30000
    )
    Expense.objects.create(itinerary=itinerary, category='transport', title='Bus', amount=1200)
    Expense.objects.create(itinerary=itinerary, category='food', title='Meals', amount=900)
    summary = itinerary.budget_summary()
    assert summary['planned_total'] == 30000
    assert summary['actual_total'] == 2100


def test_duplicate_qr_checkin_is_prevented(db):
    user = User.objects.create_user(username='u2', email='u2@example.com', password='Pass123!')
    destination = Destination.objects.create(
        name='Jaipur', slug='jaipur', country='India', state='Rajasthan', city='Jaipur',
        category='Heritage', description='Pink city', best_time_to_visit='October to March',
        daily_budget=3500, trip_duration_days=3, latitude=26.9124, longitude=75.7873
    )
    reservation = Reservation.objects.create(
        user=user, destination=destination, title='Jaipur Escape', start_date=date(2026, 2, 1), end_date=date(2026, 2, 4),
        travelers_count=2, status='confirmed', amount=6000
    )
    qr = QRCheckIn.objects.create(reservation=reservation, token='token-123', expires_at='2026-03-01T00:00:00Z')
    qr.mark_used()
    second_qr = QRCheckIn.objects.filter(reservation=reservation).first()
    assert second_qr.used_at is not None
