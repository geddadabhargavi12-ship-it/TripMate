import hashlib

import requests
from django.conf import settings
from django.core.cache import cache


class GeoapifyConfigurationError(Exception):
    pass


class GeoapifyProviderError(Exception):
    pass


ATTRIBUTION = 'Powered by Geoapify | © OpenStreetMap contributors'
CATEGORIES = (
    'tourism,leisure,beach,natural,entertainment,catering,'
    'accommodation,commercial,sport'
)


def search_places(query, limit=20):
    api_key = getattr(settings, 'GEOAPIFY_API_KEY', '').strip()
    if not api_key:
        raise GeoapifyConfigurationError

    cache_key = 'geoapify:places:' + hashlib.sha256(
        f'{query.casefold()}:{limit}'.encode('utf-8')
    ).hexdigest()
    cached = cache.get(cache_key)
    if cached is not None:
        return cached

    geocoded = _get_json(
        'https://api.geoapify.com/v1/geocode/search',
        {'text': query, 'format': 'json', 'limit': 1, 'apiKey': api_key},
    ).get('results', [])
    if not geocoded:
        cache.set(cache_key, [], 600)
        return []

    location = geocoded[0]
    latitude = _coordinate(location.get('lat'))
    longitude = _coordinate(location.get('lon'))
    if latitude is None or longitude is None:
        raise GeoapifyProviderError

    features = _get_json(
        'https://api.geoapify.com/v2/places',
        {
            'categories': CATEGORIES,
            'filter': f'circle:{longitude},{latitude},20000',
            'limit': limit,
            'apiKey': api_key,
        },
    ).get('features', [])

    places = [_normalize(location)]
    places.extend(
        _normalize(feature.get('properties', {}), feature.get('geometry'))
        for feature in features
        if isinstance(feature, dict)
    )

    unique = []
    seen = set()
    for place in places:
        if place is None or place['id'] in seen:
            continue
        seen.add(place['id'])
        unique.append(place)
        if len(unique) >= limit:
            break

    cache.set(cache_key, unique, 600)
    return unique


def _get_json(url, params):
    try:
        response = requests.get(url, params=params, timeout=8)
        response.raise_for_status()
        payload = response.json()
    except (requests.RequestException, ValueError):
        raise GeoapifyProviderError from None
    if not isinstance(payload, dict):
        raise GeoapifyProviderError
    return payload


def _coordinate(value):
    try:
        return float(value)
    except (TypeError, ValueError):
        return None


def _normalize(properties, geometry=None):
    if not isinstance(properties, dict):
        return None
    latitude = _coordinate(properties.get('lat'))
    longitude = _coordinate(properties.get('lon'))
    if latitude is None or longitude is None:
        coordinates = geometry.get('coordinates') if isinstance(geometry, dict) else None
        if isinstance(coordinates, (list, tuple)) and len(coordinates) >= 2:
            longitude = _coordinate(coordinates[0])
            latitude = _coordinate(coordinates[1])
    if latitude is None or longitude is None:
        return None

    name = str(properties.get('name') or properties.get('address_line1') or properties.get('formatted') or '').strip()
    if not name:
        return None

    datasource = properties.get('datasource')
    raw = datasource.get('raw', {}) if isinstance(datasource, dict) else {}
    external_id = properties.get('place_id') or properties.get('id')
    if not external_id:
        digest = hashlib.sha256(
            f'{name}:{latitude:.6f}:{longitude:.6f}'.encode('utf-8')
        ).hexdigest()[:24]
        external_id = f'geoapify:{digest}'

    categories = properties.get('categories') or []
    if isinstance(categories, str):
        categories = [categories]

    image_url = (
        properties.get('image_url')
        or properties.get('image')
        or (raw.get('image') if isinstance(raw, dict) else None)
    )
    if not isinstance(image_url, str) or not image_url.startswith(('https://', 'http://')):
        image_url = None

    return {
        'id': str(external_id),
        'name': name,
        'address': properties.get('formatted') or properties.get('address_line1') or '',
        'city': properties.get('city') or properties.get('town') or properties.get('village') or '',
        'state': properties.get('state') or '',
        'country': properties.get('country') or '',
        'latitude': latitude,
        'longitude': longitude,
        'categories': [str(category) for category in categories if category],
        'website': properties.get('website') or None,
        'image_url': image_url,
        'description': properties.get('description') or None,
        'attribution': ATTRIBUTION,
    }
