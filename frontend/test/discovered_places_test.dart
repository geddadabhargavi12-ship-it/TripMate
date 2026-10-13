import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dio/dio.dart';
import 'package:tripmate/models/discovered_place.dart';
import 'package:tripmate/providers/tripmate_provider.dart';
import 'package:tripmate/services/api_service.dart';
import 'package:tripmate/widgets/destination_map.dart';

void main() {
  test(
    'provider-backed searches return distinct coordinates per query',
    () async {
      final api = _FakePlacesApi();
      final provider = TripMateProvider(apiService: api);

      provider.searchPlaces('Paris', immediate: true);
      await Future<void>.delayed(Duration.zero);
      expect(provider.discoveredPlaces.single.name, 'Paris');
      expect(provider.discoveredPlaces.single.latitude, 48.8566);

      provider.searchPlaces('Tokyo', immediate: true);
      await Future<void>.delayed(Duration.zero);
      expect(provider.discoveredPlaces.single.name, 'Tokyo');
      expect(provider.discoveredPlaces.single.latitude, 35.6762);
      expect(api.queries, ['Paris', 'Tokyo']);

      provider.dispose();
    },
  );

  test(
    'provider reports failures without inserting sample destinations',
    () async {
      final provider = TripMateProvider(apiService: _FakePlacesApi(fail: true));

      provider.searchPlaces('Lalibela', immediate: true);
      await Future<void>.delayed(Duration.zero);

      expect(provider.discoveredPlaces, isEmpty);
      expect(provider.placeSearchError, contains('Could not connect'));
      provider.dispose();
    },
  );

  testWidgets('rapid search input only requests the latest query', (
    tester,
  ) async {
    final api = _FakePlacesApi();
    final provider = TripMateProvider(apiService: api);

    provider.searchPlaces('Par');
    provider.searchPlaces('Paris');
    await tester.pump(const Duration(milliseconds: 449));
    expect(api.queries, isEmpty);

    await tester.pump(const Duration(milliseconds: 1));
    await tester.pump();
    expect(api.queries, ['Paris']);
    expect(provider.discoveredPlaces.single.name, 'Paris');
    provider.dispose();
  });

  testWidgets('tapping a map marker selects the provider place', (
    tester,
  ) async {
    const place = DiscoveredPlace(
      id: 'geoapify:eiffel',
      name: 'Eiffel Tower',
      latitude: 48.8584,
      longitude: 2.2945,
      address: 'Paris, France',
    );
    DiscoveredPlace? selected;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 400,
            height: 320,
            child: DestinationMapWidget(
              places: const [place],
              onPlaceTapped: (value) => selected = value,
            ),
          ),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 100));
    await tester.tap(find.byTooltip('Eiffel Tower'));

    expect(selected?.id, place.id);
    expect(selected?.latitude, 48.8584);
  });
}

class _FakePlacesApi extends ApiService {
  _FakePlacesApi({this.fail = false});

  final bool fail;
  final List<String> queries = [];

  @override
  Future<List<DiscoveredPlace>> searchPlaces(String query) async {
    queries.add(query);
    if (fail) {
      throw DioException(requestOptions: RequestOptions(path: '/discover/'));
    }
    final coordinates = query == 'Paris'
        ? (48.8566, 2.3522)
        : (35.6762, 139.6503);
    return [
      DiscoveredPlace(
        id: 'geoapify:$query',
        name: query,
        latitude: coordinates.$1,
        longitude: coordinates.$2,
      ),
    ];
  }
}
