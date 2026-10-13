from datetime import date
from unittest.mock import Mock, patch

from django.contrib.auth import get_user_model
from django.core.cache import cache
from django.test import TestCase
from django.test.utils import override_settings
from rest_framework.test import APITestCase

from itineraries.models import Itinerary, ItineraryActivity
from .models import Destination, SavedDestination
from .place_search import GeoapifyConfigurationError, search_places


class PlaceDiscoveryTests(APITestCase):
	@patch('destinations.views.search_places')
	def test_search_forwards_query_and_returns_provider_results(self, search):
		search.side_effect = lambda query, limit: [
			{
				'id': query,
				'name': query,
				'latitude': 48.8566 if query == 'Paris' else 35.6762,
				'longitude': 2.3522 if query == 'Paris' else 139.6503,
				'categories': ['place.city'],
			}
		]

		paris = self.client.get('/api/destinations/discover/', {'q': 'Paris'})
		tokyo = self.client.get('/api/destinations/discover/', {'q': 'Tokyo'})

		self.assertEqual(paris.status_code, 200)
		self.assertEqual(tokyo.status_code, 200)
		self.assertEqual(paris.data['results'][0]['name'], 'Paris')
		self.assertEqual(tokyo.data['results'][0]['name'], 'Tokyo')
		self.assertNotEqual(
			paris.data['results'][0]['latitude'],
			tokyo.data['results'][0]['latitude'],
		)
		self.assertEqual(search.call_args_list[0].args, ('Paris',))
		self.assertEqual(search.call_args_list[1].args, ('Tokyo',))

	@patch('destinations.views.search_places')
	def test_search_requires_query_and_does_not_call_provider(self, search):
		response = self.client.get('/api/destinations/discover/', {'q': ' '})

		self.assertEqual(response.status_code, 400)
		search.assert_not_called()

	@patch(
		'destinations.views.search_places',
		side_effect=GeoapifyConfigurationError,
	)
	def test_missing_provider_configuration_is_reported(self, search):
		response = self.client.get('/api/destinations/discover/', {'q': 'Paris'})

		self.assertEqual(response.status_code, 503)
		self.assertIn('GEOAPIFY_API_KEY', response.data['detail'])


class GeoapifyServiceTests(TestCase):
	def setUp(self):
		cache.clear()

	@override_settings(GEOAPIFY_API_KEY='test-geoapify-key')
	@patch('destinations.place_search.requests.get')
	def test_search_geocodes_each_query_and_uses_actual_coordinates(self, get):
		paris_location = Mock()
		paris_location.json.return_value = {
			'results': [{'name': 'Paris', 'formatted': 'Paris, France', 'lat': 48.8566, 'lon': 2.3522}]
		}
		paris_places = Mock()
		paris_places.json.return_value = {
			'features': [
				{
					'geometry': {'coordinates': [2.2945, 48.8584]},
					'properties': {
						'place_id': 'paris-eiffel',
						'name': 'Eiffel Tower',
						'formatted': 'Champ de Mars, Paris, France',
						'categories': ['tourism.attraction'],
					},
				}
			]
		}
		tokyo_location = Mock()
		tokyo_location.json.return_value = {
			'results': [{'name': 'Tokyo', 'formatted': 'Tokyo, Japan', 'lat': 35.6762, 'lon': 139.6503}]
		}
		tokyo_places = Mock()
		tokyo_places.json.return_value = {'features': []}
		get.side_effect = [paris_location, paris_places, tokyo_location, tokyo_places]

		paris = search_places('Paris', limit=5)
		tokyo = search_places('Tokyo', limit=5)

		self.assertEqual(paris[0]['name'], 'Paris')
		self.assertEqual(paris[0]['address'], 'Paris, France')
		self.assertEqual(paris[0]['latitude'], 48.8566)
		self.assertEqual(paris[1]['name'], 'Eiffel Tower')
		self.assertEqual(paris[1]['latitude'], 48.8584)
		self.assertEqual(tokyo[0]['name'], 'Tokyo')
		self.assertEqual(tokyo[0]['address'], 'Tokyo, Japan')
		self.assertEqual(tokyo[0]['latitude'], 35.6762)
		self.assertNotEqual(paris[0]['latitude'], tokyo[0]['latitude'])
		self.assertEqual(
			get.call_args_list[1].args[0],
			'https://api.geoapify.com/v2/places',
		)
		self.assertIn('2.3522,48.8566', get.call_args_list[1].kwargs['params']['filter'])
		self.assertIn('139.6503,35.6762', get.call_args_list[3].kwargs['params']['filter'])
		self.assertEqual(get.call_args_list[1].kwargs['params']['limit'], 5)

	@override_settings(GEOAPIFY_API_KEY='test-geoapify-key')
	@patch('destinations.place_search.requests.get')
	def test_search_results_are_cached_per_query(self, get):
		geocoding = Mock()
		geocoding.json.return_value = {
			'results': [{'formatted': 'Lalibela, Ethiopia', 'lat': 12.03, 'lon': 39.04}]
		}
		places = Mock()
		places.json.return_value = {'features': []}
		get.side_effect = [geocoding, places]

		first = search_places('Lalibela', limit=10)
		second = search_places('Lalibela', limit=10)

		self.assertEqual(first, second)
		self.assertEqual(get.call_count, 2)


class DiscoveredPlacePersistenceTests(APITestCase):
	def setUp(self):
		self.user = get_user_model().objects.create_user(
			username='planner',
			email='planner@example.com',
			password='TripMate-test-password-1',
		)
		self.client.force_authenticate(self.user)
		self.place = {
			'id': 'geoapify:paris-landmark-1',
			'name': 'Example Landmark',
			'address': 'Paris, France',
			'city': 'Paris',
			'country': 'France',
			'latitude': 48.8566,
			'longitude': 2.3522,
			'categories': ['tourism.attraction'],
		}

	def test_saving_discovered_place_toggles_existing_favorite(self):
		url = '/api/destinations/places/save/'

		first = self.client.post(url, {'place': self.place}, format='json')
		second = self.client.post(url, {'place': self.place}, format='json')

		self.assertEqual(first.status_code, 200)
		self.assertTrue(first.data['saved'])
		self.assertFalse(second.data['saved'])
		self.assertEqual(SavedDestination.objects.count(), 0)
		destination = Destination.objects.get(provider_place_id=self.place['id'])
		self.assertEqual(destination.place_address, self.place['address'])

	def test_saved_endpoint_exposes_provider_identity_for_discovered_favorites(self):
		self.client.post(
			'/api/destinations/places/save/',
			{'place': self.place},
			format='json',
		)

		response = self.client.get('/api/destinations/saved/')

		self.assertEqual(response.status_code, 200)
		saved = response.data['results'][0]['destination']
		self.assertEqual(saved['provider_place_id'], self.place['id'])
		self.assertEqual(saved['place_address'], self.place['address'])

	def test_discovered_place_is_added_to_owned_itinerary(self):
		itinerary = Itinerary.objects.create(
			user=self.user,
			trip_name='Paris',
			start_date=date(2027, 1, 1),
			end_date=date(2027, 1, 3),
		)

		response = self.client.post(
			'/api/destinations/places/add-to-itinerary/',
			{'itinerary_id': itinerary.pk, 'place': self.place},
			format='json',
		)

		self.assertEqual(response.status_code, 201)
		activity = ItineraryActivity.objects.get(pk=response.data['activity_id'])
		self.assertEqual(activity.title, 'Example Landmark')
		self.assertIn('Paris, France', activity.notes)

	def test_cannot_add_discovered_place_to_another_users_itinerary(self):
		other_user = get_user_model().objects.create_user(
			username='other',
			email='other@example.com',
			password='TripMate-test-password-2',
		)
		itinerary = Itinerary.objects.create(
			user=other_user,
			trip_name='Private trip',
			start_date=date(2027, 1, 1),
			end_date=date(2027, 1, 2),
		)

		response = self.client.post(
			'/api/destinations/places/add-to-itinerary/',
			{'itinerary_id': itinerary.pk, 'place': self.place},
			format='json',
		)

		self.assertEqual(response.status_code, 404)
		self.assertEqual(ItineraryActivity.objects.count(), 0)
