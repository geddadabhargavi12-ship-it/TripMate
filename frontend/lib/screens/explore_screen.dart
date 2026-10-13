import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tripmate/models/discovered_place.dart';
import 'package:tripmate/models/route_plan.dart';
import 'package:tripmate/providers/tripmate_provider.dart';
import 'package:tripmate/screens/route_details_screen.dart';
import 'package:tripmate/widgets/destination_map.dart';

class ExploreScreen extends StatefulWidget {
  const ExploreScreen({super.key});

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  late final TextEditingController _searchController;
  bool _showMap = false;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController(
      text: context.read<TripMateProvider>().searchQuery,
    );
    if (_searchController.text.trim().length >= 2) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          context.read<TripMateProvider>().searchPlaces(_searchController.text);
        }
      });
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<TripMateProvider>();
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Explore places',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      textInputAction: TextInputAction.search,
                      onChanged: provider.searchPlaces,
                      onSubmitted: (value) =>
                          provider.searchPlaces(value, immediate: true),
                      decoration: InputDecoration(
                        hintText: 'Villages, districts, cities, landmarks…',
                        prefixIcon: const Icon(Icons.search),
                        suffixIcon: _searchController.text.isEmpty
                            ? null
                            : IconButton(
                                tooltip: 'Clear search',
                                onPressed: () {
                                  _searchController.clear();
                                  provider.searchPlaces('');
                                },
                                icon: const Icon(Icons.close),
                              ),
                        border: const OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filledTonal(
                    onPressed: provider.requestCurrentLocation,
                    tooltip: 'Use my location',
                    icon: const Icon(Icons.my_location),
                  ),
                ],
              ),
              if (provider.locationMessage != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    provider.locationMessage!,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
              const SizedBox(height: 12),
              SegmentedButton<bool>(
                segments: const [
                  ButtonSegment(
                    value: false,
                    icon: Icon(Icons.list),
                    label: Text('List'),
                  ),
                  ButtonSegment(
                    value: true,
                    icon: Icon(Icons.map_outlined),
                    label: Text('Map'),
                  ),
                ],
                selected: {_showMap},
                onSelectionChanged: (selection) =>
                    setState(() => _showMap = selection.first),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    if (provider.isSearchingPlaces) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (provider.placeSearchError != null) {
                      return _SearchMessage(
                        icon: Icons.cloud_off_outlined,
                        message: provider.placeSearchError!,
                        actionLabel: 'Retry',
                        onAction: () => provider.searchPlaces(
                          _searchController.text,
                          immediate: true,
                        ),
                      );
                    }
                    if (_searchController.text.trim().length < 2) {
                      return const _SearchMessage(
                        icon: Icons.travel_explore,
                        message:
                            'Search for a village, district, city, landmark, or other place.',
                      );
                    }
                    if (provider.discoveredPlaces.isEmpty) {
                      return const _SearchMessage(
                        icon: Icons.search_off,
                        message: 'No places found. Try another search.',
                      );
                    }

                    final map = DestinationMapWidget(
                      places: provider.discoveredPlaces,
                      selectedPlace: provider.selectedPlace,
                      userLocation: provider.userLocation,
                      routePlan: provider.routePlan,
                      onPlaceTapped: (place) {
                        provider.selectPlace(place);
                        _showPlaceDetails(context, place);
                      },
                    );
                    final list = _PlaceResults(
                      places: provider.discoveredPlaces,
                      onSelected: (place) {
                        provider.selectPlace(place);
                        _showPlaceDetails(context, place);
                      },
                    );

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(
                          child: _showMap
                              ? map
                              : constraints.maxWidth >= 900
                              ? Row(
                                  children: [
                                    Expanded(flex: 3, child: map),
                                    const SizedBox(width: 16),
                                    Expanded(flex: 2, child: list),
                                  ],
                                )
                              : list,
                        ),
                        if (provider.isLoadingRoute)
                          const LinearProgressIndicator(minHeight: 2),
                        if (provider.routePlan != null)
                          _RouteSummary(route: provider.routePlan!),
                        if (provider.routeError != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              provider.routeError!,
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.error,
                              ),
                            ),
                          ),
                        if (provider.placeAttribution.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              provider.placeAttribution,
                              textAlign: TextAlign.right,
                              style: Theme.of(context).textTheme.labelSmall,
                            ),
                          ),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showPlaceDetails(
    BuildContext context,
    DiscoveredPlace place,
  ) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) => _PlaceDetailsSheet(
        place: place,
        onShowRoute: () =>
            context.read<TripMateProvider>().createRouteTo(place),
      ),
    );
    if (mounted) {
      final provider = context.read<TripMateProvider>();
      final route = provider.routePlan;
      if (route != null) {
        setState(() => _showMap = true);
        await Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => RouteDetailsScreen(
              place: place,
              route: route,
              userLocation: provider.userLocation,
            ),
          ),
        );
      }
    }
  }
}

class _RouteSummary extends StatelessWidget {
  const _RouteSummary({required this.route});

  final RoutePlan route;

  @override
  Widget build(BuildContext context) => Card(
    margin: const EdgeInsets.only(top: 10),
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(
        children: [
          Icon(
            Icons.directions_car,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${route.durationLabel}  ·  ${route.distanceLabel}',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const Text('Estimated driving time; traffic may change it.'),
                if (route.attribution.isNotEmpty)
                  Text(
                    route.attribution,
                    style: Theme.of(context).textTheme.labelSmall,
                  ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

class _PlaceResults extends StatelessWidget {
  const _PlaceResults({required this.places, required this.onSelected});

  final List<DiscoveredPlace> places;
  final ValueChanged<DiscoveredPlace> onSelected;

  @override
  Widget build(BuildContext context) => ListView.separated(
    itemCount: places.length,
    separatorBuilder: (_, _) => const Divider(height: 1),
    itemBuilder: (context, index) {
      final place = places[index];
      return ListTile(
        contentPadding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
        leading: place.imageUrl == null
            ? const CircleAvatar(child: Icon(Icons.place_outlined))
            : CircleAvatar(backgroundImage: NetworkImage(place.imageUrl!)),
        title: Text(place.name, maxLines: 1, overflow: TextOverflow.ellipsis),
        subtitle: Text(
          [
            place.address,
            if (place.categories.isNotEmpty) place.categories.first,
          ].where((value) => value.isNotEmpty).join(' · '),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: IconButton(
          tooltip: place.isSaved
              ? 'Remove from favorites'
              : 'Save to favorites',
          onPressed: () =>
              context.read<TripMateProvider>().toggleDiscoveredPlaceSave(place),
          icon: Icon(place.isSaved ? Icons.bookmark : Icons.bookmark_border),
        ),
        onTap: () => onSelected(place),
      );
    },
  );
}

class _PlaceDetailsSheet extends StatelessWidget {
  const _PlaceDetailsSheet({required this.place, required this.onShowRoute});

  final DiscoveredPlace place;
  final Future<bool> Function() onShowRoute;

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<TripMateProvider>();
    final currentPlace = provider.selectedPlace?.id == place.id
        ? provider.selectedPlace!
        : place;
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          20,
          8,
          20,
          20 + MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (currentPlace.imageUrl != null)
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.network(
                    currentPlace.imageUrl!,
                    height: 190,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => const SizedBox.shrink(),
                  ),
                ),
              const SizedBox(height: 12),
              Text(
                currentPlace.name,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              if (currentPlace.address.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(currentPlace.address),
              ],
              const SizedBox(height: 8),
              SelectableText(
                '${currentPlace.latitude}, ${currentPlace.longitude}',
              ),
              if (currentPlace.categories.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(currentPlace.categories.join(' · ')),
              ],
              if (currentPlace.description != null) ...[
                const SizedBox(height: 8),
                Text(currentPlace.description!),
              ],
              if (currentPlace.website != null) ...[
                const SizedBox(height: 8),
                SelectableText(currentPlace.website!),
              ],
              if (currentPlace.attribution.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  currentPlace.attribution,
                  style: Theme.of(context).textTheme.labelSmall,
                ),
              ],
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: provider.isLoadingRoute
                      ? null
                      : () async {
                          final success = await onShowRoute();
                          if (success && context.mounted) {
                            Navigator.pop(context);
                          }
                        },
                  icon: provider.isLoadingRoute
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.directions),
                  label: Text(
                    provider.isLoadingRoute
                        ? 'Finding route…'
                        : 'Route from my location',
                  ),
                ),
              ),
              if (provider.routeError != null) ...[
                const SizedBox(height: 8),
                Text(
                  provider.routeError!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ],
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  OutlinedButton.icon(
                    onPressed: () =>
                        provider.toggleDiscoveredPlaceSave(currentPlace),
                    icon: Icon(
                      currentPlace.isSaved
                          ? Icons.bookmark
                          : Icons.bookmark_border,
                    ),
                    label: Text(currentPlace.isSaved ? 'Saved' : 'Save'),
                  ),
                  FilledButton.icon(
                    onPressed: provider.itineraries.isEmpty
                        ? null
                        : () => _chooseItinerary(context, currentPlace),
                    icon: const Icon(Icons.add_road),
                    label: const Text('Add to trip'),
                  ),
                ],
              ),
              if (provider.itineraries.isEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    provider.isAuthenticated
                        ? 'Create a trip before adding places.'
                        : 'Sign in and create a trip to add this place.',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _chooseItinerary(
    BuildContext context,
    DiscoveredPlace place,
  ) async {
    final provider = context.read<TripMateProvider>();
    final itinerary = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Add place to trip'),
        content: SizedBox(
          width: 360,
          child: ListView(
            shrinkWrap: true,
            children: provider.itineraries.map((trip) {
              return ListTile(
                title: Text(trip['trip_name']?.toString() ?? 'Trip'),
                onTap: () => Navigator.pop(dialogContext, trip),
              );
            }).toList(),
          ),
        ),
      ),
    );
    final id = itinerary?['id'];
    if (id is int) {
      final added = await provider.addDiscoveredPlaceToItinerary(place, id);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              added
                  ? 'Place added to trip.'
                  : provider.errorMessage ?? 'Could not add place.',
            ),
          ),
        );
      }
    }
  }
}

class _SearchMessage extends StatelessWidget {
  const _SearchMessage({
    required this.icon,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) => Center(
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 420),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 36),
          const SizedBox(height: 12),
          Text(message, textAlign: TextAlign.center),
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: 12),
            FilledButton.tonal(onPressed: onAction, child: Text(actionLabel!)),
          ],
        ],
      ),
    ),
  );
}
