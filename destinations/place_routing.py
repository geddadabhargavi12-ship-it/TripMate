import hashlib
import math

import requests
from django.conf import settings
from django.core.cache import cache


class GeoapifyRoutingConfigurationError(Exception):
    pass


class GeoapifyRoutingProviderError(Exception):
    pass


def calculate_route(origin_latitude, origin_longitude, destination_latitude, destination_longitude):
    api_key = getattr(settings, 'GEOAPIFY_API_KEY', '').strip()
    if not api_key:
        raise GeoapifyRoutingConfigurationError

    coordinates = (
        origin_latitude,
        origin_longitude,
        destination_latitude,
        destination_longitude,
    )
    cache_key = 'geoapify:route:' + hashlib.sha256(
        ':'.join(f'{value:.5f}' for value in coordinates).encode('utf-8')
    ).hexdigest()
    cached = cache.get(cache_key)
    if cached is not None:
        return cached

    waypoints = (
        f'{origin_latitude},{origin_longitude}|'
        f'{destination_latitude},{destination_longitude}'
    )
    try:
        response = requests.get(
            'https://api.geoapify.com/v1/routing',
            params={
                'waypoints': waypoints,
                'mode': 'drive',
                'format': 'geojson',
                'apiKey': api_key,
            },
            timeout=12,
        )
        response.raise_for_status()
        payload = response.json()
    except (requests.RequestException, ValueError):
        raise GeoapifyRoutingProviderError from None

    features = payload.get('features') if isinstance(payload, dict) else None
    feature = features[0] if isinstance(features, list) and features else None
    geometry = feature.get('geometry') if isinstance(feature, dict) else None
    properties = feature.get('properties') if isinstance(feature, dict) else None
    raw_coordinates = geometry.get('coordinates') if isinstance(geometry, dict) else None
    geometry_type = geometry.get('type') if isinstance(geometry, dict) else None
    if not isinstance(raw_coordinates, list) or not isinstance(properties, dict):
        raise GeoapifyRoutingProviderError

    if geometry_type == 'LineString':
        raw_paths = [raw_coordinates]
    elif geometry_type == 'MultiLineString':
        raw_paths = raw_coordinates
    else:
        raise GeoapifyRoutingProviderError

    route_paths = []
    for raw_path in raw_paths:
        if not isinstance(raw_path, list):
            continue
        path = []
        for point in raw_path:
            if not isinstance(point, (list, tuple)) or len(point) < 2:
                continue
            try:
                longitude, latitude = float(point[0]), float(point[1])
            except (TypeError, ValueError):
                continue
            if not (math.isfinite(latitude) and math.isfinite(longitude)):
                continue
            if not (-90 <= latitude <= 90 and -180 <= longitude <= 180):
                continue
            path.append([latitude, longitude])
        if len(path) >= 2:
            route_paths.append(path)

    try:
        distance_meters = float(properties['distance'])
        duration_seconds = float(properties['time'])
    except (KeyError, TypeError, ValueError):
        raise GeoapifyRoutingProviderError from None
    if (
        not route_paths
        or not math.isfinite(distance_meters)
        or not math.isfinite(duration_seconds)
        or distance_meters <= 0
        or duration_seconds <= 0
    ):
        raise GeoapifyRoutingProviderError

    route = {
        'distance_meters': distance_meters,
        'duration_seconds': duration_seconds,
        'paths': route_paths,
        'coordinates': [point for path in route_paths for point in path],
        'attribution': 'Routing by Geoapify | © OpenStreetMap contributors',
    }
    cache.set(cache_key, route, 300)
    return route
