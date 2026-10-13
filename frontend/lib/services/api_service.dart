import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import 'package:tripmate/models/destination.dart';
import 'package:tripmate/models/discovered_place.dart';
import 'package:tripmate/models/route_plan.dart';

class ApiService {
  static const String _configuredBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
  );
  static final String baseUrl = _configuredBaseUrl.isNotEmpty
      ? _configuredBaseUrl
      : kIsWeb
      ? 'http://127.0.0.1:8000/api'
      : 'http://10.0.2.2:8000/api';

  final Dio dio;

  ApiService()
    : dio = Dio(
        BaseOptions(
          baseUrl: baseUrl,
          connectTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 12),
          headers: {'Accept': 'application/json'},
        ),
      );

  Future<List<Destination>> fetchDestinations({
    String? search,
    String? category,
    String? state,
    String? country,
    String? maxBudget,
  }) async {
    try {
      final response = await dio.get(
        '/destinations/',
        queryParameters: {
          if (search != null && search.trim().isNotEmpty)
            'search': search.trim(),
          if (category != null && category.isNotEmpty) 'category': category,
          if (state != null && state.isNotEmpty) 'state': state,
          if (country != null && country.isNotEmpty) 'country': country,
          if (maxBudget != null && maxBudget.isNotEmpty)
            'max_budget': maxBudget,
        },
      );
      final data = _extractItems(response.data);
      if (data.isEmpty) {
        return [];
      }
      return data.map((item) {
        const fallbackImage =
            'https://images.unsplash.com/photo-1501785888041-af3ef285b470?auto=format&fit=crop&w=960&q=80';
        final images = item['images'] as List? ?? const [];
        final image = images.whereType<Map<String, dynamic>>().firstWhere(
          (image) => image['is_primary'] == true,
          orElse: () => {'image_url': fallbackImage},
        );
        return Destination(
          id: item['id'].toString(),
          name: item['name'] ?? 'Unknown',
          location: item['city'] ?? item['state'] ?? 'India',
          country: item['country'] ?? 'India',
          category: item['category'] ?? 'Nature',
          description: item['description'] ?? 'A hidden gem to explore.',
          imageUrl: image['image_url'] as String? ?? fallbackImage,
          dailyBudget: double.tryParse('${item['daily_budget'] ?? 0}') ?? 0,
          latitude: double.tryParse('${item['latitude'] ?? 0.0}') ?? 0.0,
          longitude: double.tryParse('${item['longitude'] ?? 0.0}') ?? 0.0,
          isFeatured: item['is_featured'] == true,
        );
      }).toList();
    } on DioException {
      rethrow;
    }
  }

  Future<List<DiscoveredPlace>> searchPlaces(String query) async {
    final response = await dio.get(
      '/destinations/discover/',
      queryParameters: {'q': query, 'limit': 20},
    );
    final payload = response.data;
    if (payload is! Map || payload['results'] is! List) {
      throw const FormatException(
        'The place provider returned an invalid response.',
      );
    }
    return (payload['results'] as List)
        .whereType<Map>()
        .map(
          (item) => DiscoveredPlace.fromJson(Map<String, dynamic>.from(item)),
        )
        .toList();
  }

  Future<RoutePlan> calculateRoute({
    required double originLatitude,
    required double originLongitude,
    required double destinationLatitude,
    required double destinationLongitude,
  }) async {
    final response = await dio.get(
      '/destinations/route/',
      queryParameters: {
        'origin_lat': originLatitude,
        'origin_lon': originLongitude,
        'destination_lat': destinationLatitude,
        'destination_lon': destinationLongitude,
      },
    );
    if (response.data is! Map) {
      throw const FormatException(
        'The route provider returned an invalid response.',
      );
    }
    return RoutePlan.fromJson(Map<String, dynamic>.from(response.data as Map));
  }

  Future<bool> saveDiscoveredPlace(
    String accessToken,
    DiscoveredPlace place,
  ) async {
    final response = await dio.post(
      '/destinations/places/save/',
      data: {'place': place.toJson()},
      options: _authorized(accessToken),
    );
    return response.data is Map && response.data['saved'] == true;
  }

  Future<List<DiscoveredPlace>> fetchSavedDiscoveredPlaces(
    String accessToken,
  ) async {
    final response = await dio.get(
      '/destinations/saved/',
      options: _authorized(accessToken),
    );
    return _extractItems(response.data)
        .whereType<Map>()
        .map((item) {
          final destination = item['destination'];
          if (destination is! Map || destination['provider_place_id'] == null) {
            return null;
          }
          final images = destination['images'];
          final image =
              images is List && images.isNotEmpty && images.first is Map
              ? images.first['image_url']
              : null;
          return DiscoveredPlace.fromJson({
            'id': destination['provider_place_id'],
            'name': destination['name'],
            'address': destination['place_address'],
            'city': destination['city'],
            'state': destination['state'],
            'country': destination['country'],
            'latitude': destination['latitude'],
            'longitude': destination['longitude'],
            'categories': [destination['category']],
            'website': destination['website_url'],
            'image_url': image,
            'description': destination['description'],
            'is_saved': true,
          }).copyWith(isSaved: true);
        })
        .whereType<DiscoveredPlace>()
        .toList();
  }

  Future<void> addDiscoveredPlaceToItinerary(
    String accessToken,
    DiscoveredPlace place,
    int itineraryId,
  ) async {
    await dio.post(
      '/destinations/places/add-to-itinerary/',
      data: {'itinerary_id': itineraryId, 'place': place.toJson()},
      options: _authorized(accessToken),
    );
  }

  Future<Map<String, dynamic>> login(String email, String password) async {
    final response = await dio.post(
      '/auth/login/',
      data: {'email': email, 'password': password},
    );
    return Map<String, dynamic>.from(response.data as Map);
  }

  Future<void> register({
    required String username,
    required String fullName,
    required String email,
    required String password,
  }) async {
    await dio.post(
      '/auth/register/',
      data: {
        'username': username,
        'full_name': fullName,
        'email': email,
        'password': password,
      },
    );
  }

  Future<List<Map<String, dynamic>>> fetchItineraries(
    String accessToken,
  ) async {
    final response = await dio.get(
      '/itineraries/',
      options: _authorized(accessToken),
    );
    return _extractItems(
      response.data,
    ).map((item) => Map<String, dynamic>.from(item as Map)).toList();
  }

  Future<Map<String, dynamic>> createItinerary(
    String accessToken,
    Map<String, dynamic> itinerary,
  ) async {
    final response = await dio.post(
      '/itineraries/',
      data: itinerary,
      options: _authorized(accessToken),
    );
    return Map<String, dynamic>.from(response.data as Map);
  }

  Future<void> deleteItinerary(String accessToken, int id) async {
    await dio.delete('/itineraries/$id/', options: _authorized(accessToken));
  }

  Options _authorized(String accessToken) =>
      Options(headers: {'Authorization': 'Bearer $accessToken'});

  List<dynamic> _extractItems(dynamic payload) {
    if (payload is List) return payload;
    if (payload is Map && payload['results'] is List) {
      return payload['results'] as List;
    }
    return [];
  }
}
