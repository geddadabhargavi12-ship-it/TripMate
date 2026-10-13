import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart' as map_latlng;
import 'package:tripmate/models/discovered_place.dart';
import 'package:tripmate/models/route_plan.dart';

class DestinationMapWidget extends StatelessWidget {
  const DestinationMapWidget({
    super.key,
    required this.places,
    required this.onPlaceTapped,
    this.selectedPlace,
    this.userLocation,
    this.routePlan,
  });

  final List<DiscoveredPlace> places;
  final DiscoveredPlace? selectedPlace;
  final Position? userLocation;
  final RoutePlan? routePlan;
  final ValueChanged<DiscoveredPlace> onPlaceTapped;

  @override
  Widget build(BuildContext context) {
    final center = selectedPlace != null
        ? map_latlng.LatLng(selectedPlace!.latitude, selectedPlace!.longitude)
        : places.isNotEmpty
        ? map_latlng.LatLng(places.first.latitude, places.first.longitude)
        : userLocation != null
        ? map_latlng.LatLng(userLocation!.latitude, userLocation!.longitude)
        : const map_latlng.LatLng(20, 0);

    final markers = places.map((place) {
      final selected = place.id == selectedPlace?.id;
      return Marker(
        point: map_latlng.LatLng(place.latitude, place.longitude),
        width: 44,
        height: 48,
        child: Tooltip(
          message: place.name,
          child: GestureDetector(
            onTap: () => onPlaceTapped(place),
            child: Icon(
              selected ? Icons.location_pin : Icons.location_on,
              color: selected
                  ? Theme.of(context).colorScheme.primary
                  : Colors.red.shade700,
              size: selected ? 42 : 36,
            ),
          ),
        ),
      );
    }).toList();

    if (userLocation != null) {
      markers.add(
        Marker(
          point: map_latlng.LatLng(
            userLocation!.latitude,
            userLocation!.longitude,
          ),
          width: 40,
          height: 40,
          child: const Icon(Icons.my_location, color: Colors.blue, size: 28),
        ),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: FlutterMap(
        key: ValueKey(
          '${selectedPlace?.id ?? ''}:${places.length}:${routePlan?.coordinates.length ?? 0}',
        ),
        options: MapOptions(
          initialCenter: center,
          initialZoom: selectedPlace != null
              ? 14
              : places.isNotEmpty
              ? 12
              : 3,
          minZoom: 2,
          maxZoom: 18,
          initialCameraFit: routePlan == null
              ? null
              : CameraFit.coordinates(
                  coordinates: routePlan!.coordinates
                      .map((point) => map_latlng.LatLng(point[0], point[1]))
                      .toList(),
                  padding: const EdgeInsets.all(44),
                  maxZoom: 14,
                ),
        ),
        children: [
          TileLayer(
            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
            userAgentPackageName: 'com.tripmate.app',
          ),
          if (routePlan != null)
            PolylineLayer(
              polylines: [
                for (final path in routePlan!.paths)
                  Polyline(
                    points: path
                        .map((point) => map_latlng.LatLng(point[0], point[1]))
                        .toList(),
                    strokeWidth: 5,
                    color: Theme.of(context).colorScheme.primary,
                    borderStrokeWidth: 1.5,
                    borderColor: Colors.white,
                  ),
              ],
            ),
          MarkerLayer(markers: markers),
          const RichAttributionWidget(
            attributions: [TextSourceAttribution('OpenStreetMap contributors')],
          ),
        ],
      ),
    );
  }
}
