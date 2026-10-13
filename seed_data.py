import os
from decimal import Decimal

import django

os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'config.settings')
django.setup()

from destinations.models import Attraction, Destination, DestinationImage
from travel_videos.models import TravelVideo

DESTINATIONS = [
    {
        'name': 'Araku Valley', 'slug': 'araku-valley', 'country': 'India', 'state': 'Andhra Pradesh', 'city': 'Araku',
        'category': 'Nature', 'description': 'A lush hill station with coffee plantations and tribal culture.',
        'best_time_to_visit': 'October to February', 'daily_budget': Decimal('2500'), 'trip_duration_days': 3,
        'latitude': 18.3279, 'longitude': 82.8683, 'is_featured': True,
        'attractions': ['Borra Caves', 'Coffee Plantations', 'Tribal Museum'],
        'image_url': 'https://images.unsplash.com/photo-1501785888041-af3ef285b470',
    },
    {
        'name': 'Visakhapatnam', 'slug': 'visakhapatnam', 'country': 'India', 'state': 'Andhra Pradesh', 'city': 'Visakhapatnam',
        'category': 'City', 'description': 'A coastal city with beaches, hills, and industrial charm.',
        'best_time_to_visit': 'November to February', 'daily_budget': Decimal('3200'), 'trip_duration_days': 4,
        'latitude': 17.6868, 'longitude': 83.2185, 'is_featured': True,
        'attractions': ['RK Beach', 'Kailasagiri', 'Submarine Museum'],
        'image_url': 'https://images.unsplash.com/photo-1507525428034-b723cf961d3e',
    },
    {
        'name': 'Hyderabad', 'slug': 'hyderabad', 'country': 'India', 'state': 'Telangana', 'city': 'Hyderabad',
        'category': 'Heritage', 'description': 'A vibrant city of biryani, bazaars, and historic landmarks.',
        'best_time_to_visit': 'October to March', 'daily_budget': Decimal('2800'), 'trip_duration_days': 3,
        'latitude': 17.3850, 'longitude': 78.4867, 'is_featured': False,
        'attractions': ['Charminar', 'Golconda Fort', 'Hitech City'],
        'image_url': 'https://images.unsplash.com/photo-1524492412937-b28074a5d7da',
    },
    {
        'name': 'Bengaluru', 'slug': 'bengaluru', 'country': 'India', 'state': 'Karnataka', 'city': 'Bengaluru',
        'category': 'City', 'description': 'A tech capital with gardens, cafés, and nightlife.',
        'best_time_to_visit': 'October to February', 'daily_budget': Decimal('3400'), 'trip_duration_days': 3,
        'latitude': 12.9716, 'longitude': 77.5946, 'is_featured': False,
        'attractions': ['Lalbagh', 'Cubbon Park', 'MG Road'],
        'image_url': 'https://images.unsplash.com/photo-1477959858617-67f85cf4f1df',
    },
    {
        'name': 'Goa', 'slug': 'goa', 'country': 'India', 'state': 'Goa', 'city': 'Panaji',
        'category': 'Beach', 'description': 'Sun-kissed coastline, sea breeze, and laid-back nightlife.',
        'best_time_to_visit': 'November to March', 'daily_budget': Decimal('4200'), 'trip_duration_days': 4,
        'latitude': 15.2993, 'longitude': 74.1240, 'is_featured': True,
        'attractions': ['Baga Beach', 'Fort Aguada', 'Old Goa'],
        'image_url': 'https://images.unsplash.com/photo-1500375592092-40eb2168fd21',
    },
    {
        'name': 'Jaipur', 'slug': 'jaipur', 'country': 'India', 'state': 'Rajasthan', 'city': 'Jaipur',
        'category': 'Heritage', 'description': 'The Pink City filled with palaces, forts, and markets.',
        'best_time_to_visit': 'October to March', 'daily_budget': Decimal('3800'), 'trip_duration_days': 3,
        'latitude': 26.9124, 'longitude': 75.7873, 'is_featured': False,
        'attractions': ['Hawa Mahal', 'Amer Fort', 'Jal Mahal'],
        'image_url': 'https://images.unsplash.com/photo-1539650116574-75c0c6d73f6e',
    },
    {
        'name': 'Munnar', 'slug': 'munnar', 'country': 'India', 'state': 'Kerala', 'city': 'Munnar',
        'category': 'Mountain', 'description': 'Rolling tea gardens and cool mountain air.',
        'best_time_to_visit': 'September to April', 'daily_budget': Decimal('3100'), 'trip_duration_days': 3,
        'latitude': 10.0889, 'longitude': 77.0595, 'is_featured': False,
        'attractions': ['Eravikulam National Park', 'Tea Gardens', 'Mattupetty Dam'],
        'image_url': 'https://images.unsplash.com/photo-1504593811423-6dd665756598',
    },
    {
        'name': 'Manali', 'slug': 'manali', 'country': 'India', 'state': 'Himachal Pradesh', 'city': 'Manali',
        'category': 'Adventure', 'description': 'Snow-capped peaks, snow sports, and Himalayan views.',
        'best_time_to_visit': 'October to June', 'daily_budget': Decimal('4200'), 'trip_duration_days': 4,
        'latitude': 32.2396, 'longitude': 77.1887, 'is_featured': True,
        'attractions': ['Solang Valley', 'Rohtang Pass', 'Hadimba Temple'],
        'image_url': 'https://images.unsplash.com/photo-1516483638261-f4dbaf036963',
    },
]

for item in DESTINATIONS:
    destination, _ = Destination.objects.get_or_create(
        slug=item['slug'],
        defaults={
            'name': item['name'],
            'country': item['country'],
            'state': item['state'],
            'city': item['city'],
            'category': item['category'],
            'description': item['description'],
            'best_time_to_visit': item['best_time_to_visit'],
            'daily_budget': item['daily_budget'],
            'trip_duration_days': item['trip_duration_days'],
            'latitude': item['latitude'],
            'longitude': item['longitude'],
            'is_featured': item['is_featured'],
        },
    )
    DestinationImage.objects.get_or_create(
        destination=destination,
        image_url=item['image_url'],
        defaults={'caption': item['name'], 'is_primary': True},
    )
    for attraction in item['attractions']:
        Attraction.objects.get_or_create(destination=destination, name=attraction, defaults={'description': f'Explore {attraction} in {destination.name}.'})

TravelVideo.objects.get_or_create(
    title='Araku Valley Scenic Walk',
    defaults={'description': 'A short scenic guide to the valley roads and coffee plantations.', 'destination': Destination.objects.get(slug='araku-valley'), 'video_url': 'https://www.w3schools.com/html/mov_bbb.mp4', 'thumbnail_url': 'https://images.unsplash.com/photo-1501785888041-af3ef285b470', 'category': 'destination'}
)
TravelVideo.objects.get_or_create(
    title='Goa Beach Escape',
    defaults={'description': 'Travel inspiration for a coastal getaway in Goa.', 'destination': Destination.objects.get(slug='goa'), 'video_url': 'https://www.w3schools.com/html/movie.mp4', 'thumbnail_url': 'https://images.unsplash.com/photo-1500375592092-40eb2168fd21', 'category': 'adventure'}
)

print('Seed data loaded for TripMate destinations and videos.')
