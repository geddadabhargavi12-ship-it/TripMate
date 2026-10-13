import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:tripmate/models/discovered_place.dart';
import 'package:tripmate/models/route_plan.dart';
import 'package:tripmate/widgets/destination_map.dart';

class RouteDetailsScreen extends StatelessWidget {
  const RouteDetailsScreen({
    super.key,
    required this.place,
    required this.route,
    required this.userLocation,
  });

  final DiscoveredPlace place;
  final RoutePlan route;
  final Position? userLocation;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Route details')),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: DestinationMapWidget(
                  places: [place],
                  selectedPlace: place,
                  userLocation: userLocation,
                  routePlan: route,
                  onPlaceTapped: (_) {},
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.directions_car,
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          '${route.durationLabel}  ·  ${route.distanceLabel}',
                          style: theme.textTheme.headlineSmall,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Estimated driving time. Actual travel time can change with traffic and road conditions.',
                    style: theme.textTheme.bodySmall,
                  ),
                  const Divider(height: 24),
                  _RouteStop(
                    icon: Icons.my_location,
                    label: 'Starting point',
                    name: 'Your current location',
                    detail: userLocation == null
                        ? null
                        : '${userLocation!.latitude.toStringAsFixed(5)}, ${userLocation!.longitude.toStringAsFixed(5)}',
                  ),
                  const SizedBox(height: 12),
                  _RouteStop(
                    icon: Icons.location_on,
                    label: 'Destination',
                    name: place.name,
                    detail: place.address,
                  ),
                  if (route.attribution.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Text(route.attribution, style: theme.textTheme.labelSmall),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RouteStop extends StatelessWidget {
  const _RouteStop({
    required this.icon,
    required this.label,
    required this.name,
    this.detail,
  });

  final IconData icon;
  final String label;
  final String name;
  final String? detail;

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Icon(icon, size: 22, color: Theme.of(context).colorScheme.primary),
      const SizedBox(width: 12),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: Theme.of(context).textTheme.labelMedium),
            Text(name, style: Theme.of(context).textTheme.titleMedium),
            if (detail != null && detail!.isNotEmpty)
              Text(detail!, style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      ),
    ],
  );
}
