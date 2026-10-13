import hashlib
from urllib.parse import urlparse

from django.db import transaction
from django.utils.text import slugify

from .models import Destination, DestinationImage


def _safe_url(value):
    if not isinstance(value, str):
        return ''
    parsed = urlparse(value)
    return value if parsed.scheme in {'http', 'https'} and parsed.netloc else ''


def _coordinate(value, name, minimum, maximum):
    try:
        result = float(value)
    except (TypeError, ValueError):
        raise ValueError(f'{name} must be a valid coordinate.') from None
    if not minimum <= result <= maximum:
        raise ValueError(f'{name} is outside the valid range.')
    return result


@transaction.atomic
def persist_discovered_place(payload):
    if not isinstance(payload, dict):
        raise ValueError('Place details are required.')

    provider_place_id = str(payload.get('id') or '').strip()
    name = str(payload.get('name') or '').strip()
    if not provider_place_id or not name:
        raise ValueError('The place needs a provider ID and name.')

    latitude = _coordinate(payload.get('latitude'), 'Latitude', -90, 90)
    longitude = _coordinate(payload.get('longitude'), 'Longitude', -180, 180)
    categories = payload.get('categories') or []
    if not isinstance(categories, list):
        categories = []
    category = next(
        (str(value)[:40] for value in categories if isinstance(value, str) and value),
        'Place',
    )
    slug_suffix = hashlib.sha256(provider_place_id.encode('utf-8')).hexdigest()[:24]
    slug = f'{slugify(name)[:70] or "place"}-{slug_suffix}'

    destination, _ = Destination.objects.update_or_create(
        provider_place_id=provider_place_id,
        defaults={
            'name': name[:200],
            'slug': slug,
            'country': str(payload.get('country') or '')[:120],
            'state': str(payload.get('state') or '')[:120],
            'city': str(payload.get('city') or '')[:120],
            'category': category,
            'description': str(payload.get('description') or ''),
            'daily_budget': 0,
            'latitude': latitude,
            'longitude': longitude,
            'place_address': str(payload.get('address') or ''),
            'website_url': _safe_url(payload.get('website')),
        },
    )

    image_url = _safe_url(payload.get('image_url'))
    if image_url:
        DestinationImage.objects.get_or_create(
            destination=destination,
            image_url=image_url,
            defaults={'caption': name, 'is_primary': True},
        )
    return destination
