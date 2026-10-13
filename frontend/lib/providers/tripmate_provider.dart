import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:tripmate/models/destination.dart';
import 'package:tripmate/models/discovered_place.dart';
import 'package:tripmate/models/route_plan.dart';
import 'package:tripmate/services/api_service.dart';

class TripMateProvider extends ChangeNotifier {
  TripMateProvider({ApiService? apiService})
    : _apiService = apiService ?? ApiService();

  final ApiService _apiService;

  List<Destination> destinations = [];
  List<DiscoveredPlace> discoveredPlaces = [];
  List<DiscoveredPlace> savedDiscoveredPlaces = [];
  bool isAuthenticated = false;
  bool hasSeenOnboarding = false;
  bool isDarkMode = false;
  final Set<String> selectedInterests = {};
  String searchQuery = '';
  String userName = 'Aarav';
  String userEmail = 'aarav@tripmate.app';
  String preferredCurrency = 'INR';
  String? _accessToken;
  bool isBusy = false;
  bool isLoadingDestinations = false;
  bool isSearchingPlaces = false;
  String? placeSearchError;
  String placeAttribution = '';
  DiscoveredPlace? selectedPlace;
  RoutePlan? routePlan;
  bool isLoadingRoute = false;
  String? routeError;
  Timer? _placeSearchDebounce;
  int _placeSearchRequest = 0;
  Position? userLocation;
  String? locationMessage;
  String? errorMessage;
  List<Map<String, dynamic>> itineraries = [];

  static const List<String> travelInterests = [
    'Nature',
    'Beach',
    'Heritage',
    'Adventure',
    'Mountain',
    'City',
  ];

  List<Destination> get recommendedDestinations {
    if (selectedInterests.isEmpty) return destinations;
    final matches = destinations
        .where(
          (destination) => selectedInterests.contains(destination.category),
        )
        .toList();
    return matches.isEmpty ? destinations : matches;
  }

  List<Destination> get filteredDestinations {
    final query = searchQuery.trim().toLowerCase();
    final source = selectedInterests.isEmpty
        ? destinations
        : destinations.where(
            (destination) => selectedInterests.contains(destination.category),
          );

    if (query.isEmpty) {
      return source.toList();
    }

    final results = source.where((destination) {
      final matchesQuery =
          query.isEmpty ||
          destination.name.toLowerCase().contains(query) ||
          destination.location.toLowerCase().contains(query) ||
          destination.country.toLowerCase().contains(query) ||
          destination.description.toLowerCase().contains(query);
      return matchesQuery;
    }).toList();

    return results;
  }

  Future<void> loadDestinations({
    String? search,
    String? category,
    String? state,
    String? country,
    String? maxBudget,
  }) async {
    isLoadingDestinations = true;
    errorMessage = null;
    notifyListeners();

    try {
      final data = await _apiService.fetchDestinations(
        search: search ?? searchQuery,
        category: category,
        state: state,
        country: country,
        maxBudget: maxBudget,
      );
      destinations = data;
    } on DioException catch (error) {
      destinations = [];
      errorMessage = _apiErrorMessage(error);
    } finally {
      isLoadingDestinations = false;
      notifyListeners();
    }
  }

  void searchPlaces(String value, {bool immediate = false}) {
    searchQuery = value;
    _placeSearchDebounce?.cancel();
    final requestId = ++_placeSearchRequest;
    final query = value.trim();
    if (query.length < 2) {
      discoveredPlaces = [];
      placeSearchError = null;
      isSearchingPlaces = false;
      selectedPlace = null;
      routePlan = null;
      routeError = null;
      notifyListeners();
      return;
    }

    discoveredPlaces = [];
    selectedPlace = null;
    routePlan = null;
    routeError = null;
    isSearchingPlaces = true;
    placeSearchError = null;
    notifyListeners();
    if (immediate) {
      _loadPlaces(query, requestId);
    } else {
      _placeSearchDebounce = Timer(const Duration(milliseconds: 450), () {
        _loadPlaces(query, requestId);
      });
    }
  }

  Future<void> _loadPlaces(String query, int requestId) async {
    try {
      final results = await _apiService.searchPlaces(query);
      if (requestId != _placeSearchRequest) return;
      discoveredPlaces = results
          .map(
            (place) => place.copyWith(
              isSaved: savedDiscoveredPlaces.any(
                (saved) => saved.id == place.id,
              ),
            ),
          )
          .toList();
      placeSearchError = null;
      placeAttribution =
          results
              .map((place) => place.attribution)
              .where((value) => value.isNotEmpty)
              .firstOrNull ??
          '';
    } on DioException catch (error) {
      if (requestId != _placeSearchRequest) return;
      discoveredPlaces = [];
      placeSearchError = _apiErrorMessage(error);
    } on FormatException catch (error) {
      if (requestId != _placeSearchRequest) return;
      discoveredPlaces = [];
      placeSearchError = error.message;
    } catch (_) {
      if (requestId != _placeSearchRequest) return;
      discoveredPlaces = [];
      placeSearchError = 'Could not search places. Please try again.';
    } finally {
      if (requestId == _placeSearchRequest) {
        isSearchingPlaces = false;
        notifyListeners();
      }
    }
  }

  void selectPlace(DiscoveredPlace? place) {
    if (selectedPlace?.id != place?.id) {
      routePlan = null;
      routeError = null;
    }
    selectedPlace = place;
    notifyListeners();
  }

  Future<bool> createRouteTo(DiscoveredPlace place) async {
    selectedPlace = place;
    routePlan = null;
    routeError = null;
    isLoadingRoute = true;
    notifyListeners();

    try {
      if (userLocation == null) {
        await requestCurrentLocation();
      }
      final origin = userLocation;
      if (origin == null) {
        routeError =
            locationMessage ?? 'Allow location access to plan a route.';
        return false;
      }
      routePlan = await _apiService.calculateRoute(
        originLatitude: origin.latitude,
        originLongitude: origin.longitude,
        destinationLatitude: place.latitude,
        destinationLongitude: place.longitude,
      );
      routeError = null;
      return true;
    } on DioException catch (error) {
      routeError = _apiErrorMessage(error);
      return false;
    } on FormatException catch (error) {
      routeError = error.message;
      return false;
    } catch (_) {
      routeError = 'Could not calculate this route. Please try again.';
      return false;
    } finally {
      isLoadingRoute = false;
      notifyListeners();
    }
  }

  Future<bool> toggleDiscoveredPlaceSave(DiscoveredPlace place) async {
    final token = _accessToken;
    if (token == null) {
      errorMessage = 'Sign in to save places to your favorites.';
      notifyListeners();
      return false;
    }
    try {
      final saved = await _apiService.saveDiscoveredPlace(token, place);
      savedDiscoveredPlaces = saved
          ? [
              ...savedDiscoveredPlaces.where((item) => item.id != place.id),
              place.copyWith(isSaved: true),
            ]
          : savedDiscoveredPlaces.where((item) => item.id != place.id).toList();
      discoveredPlaces = discoveredPlaces
          .map(
            (item) =>
                item.id == place.id ? item.copyWith(isSaved: saved) : item,
          )
          .toList();
      selectedPlace = selectedPlace?.id == place.id
          ? selectedPlace!.copyWith(isSaved: saved)
          : selectedPlace;
      notifyListeners();
      return true;
    } on DioException catch (error) {
      errorMessage = _apiErrorMessage(error);
      notifyListeners();
      return false;
    }
  }

  Future<bool> addDiscoveredPlaceToItinerary(
    DiscoveredPlace place,
    int itineraryId,
  ) async {
    final token = _accessToken;
    if (token == null) {
      errorMessage = 'Sign in to add places to a trip.';
      notifyListeners();
      return false;
    }
    try {
      await _apiService.addDiscoveredPlaceToItinerary(
        token,
        place,
        itineraryId,
      );
      return true;
    } on DioException catch (error) {
      errorMessage = _apiErrorMessage(error);
      notifyListeners();
      return false;
    }
  }

  String _apiErrorMessage(DioException error) {
    final payload = error.response?.data;
    if (payload is Map && payload['detail'] is String) {
      return payload['detail'] as String;
    }
    if (error.response == null) {
      return 'Could not connect to TripMate. Check that the backend is running.';
    }
    return 'Place search failed (${error.response?.statusCode ?? 'network error'}). Please retry.';
  }

  void completeOnboarding() {
    hasSeenOnboarding = true;
    notifyListeners();
  }

  void toggleInterest(String interest) {
    if (!travelInterests.contains(interest)) return;
    if (!selectedInterests.add(interest)) {
      selectedInterests.remove(interest);
    }
    notifyListeners();
  }

  void setSearchQuery(String value) {
    searchQuery = value;
    notifyListeners();
    if (value.trim().isEmpty || value.trim().length >= 2) {
      Future.microtask(() => loadDestinations(search: value));
    }
  }

  Future<void> requestCurrentLocation() async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        locationMessage =
            'Location services are off. Turn on GPS to use nearby destinations.';
        notifyListeners();
        return;
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        locationMessage =
            'Location permission was denied. You can still search destinations manually.';
        notifyListeners();
        return;
      }

      userLocation = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
        ),
      );
      locationMessage = 'Using your current location';
      notifyListeners();
    } catch (_) {
      locationMessage =
          'Could not access GPS right now. Try again in a moment.';
      notifyListeners();
    }
  }

  Future<bool> authenticate({
    required String email,
    required String password,
    String fullName = '',
    bool register = false,
  }) async {
    isBusy = true;
    errorMessage = null;
    notifyListeners();
    try {
      if (register) {
        await _apiService.register(
          username: email.split('@').first,
          fullName: fullName,
          email: email,
          password: password,
        );
      }
      final result = await _apiService.login(email, password);
      _accessToken = result['access'] as String?;
      final user = result['user'] as Map<String, dynamic>?;
      userName = (user?['full_name'] as String?)?.isNotEmpty == true
          ? user!['full_name'] as String
          : (user?['username'] as String? ?? email.split('@').first);
      userEmail = email;
      isAuthenticated = _accessToken != null;
      if (isAuthenticated) {
        itineraries = await _apiService.fetchItineraries(_accessToken!);
        try {
          savedDiscoveredPlaces = await _apiService.fetchSavedDiscoveredPlaces(
            _accessToken!,
          );
        } on DioException {
          savedDiscoveredPlaces = [];
        }
      }
      return isAuthenticated;
    } on DioException catch (error) {
      final data = error.response?.data;
      if (data is Map && data['detail'] is String) {
        errorMessage = data['detail'] as String;
      } else if (data is Map) {
        errorMessage = data.values
            .expand((value) => value is List ? value : [value])
            .join(' ');
      } else {
        errorMessage =
            'Could not connect to TripMate. Check that the backend is running.';
      }
      return false;
    } finally {
      isBusy = false;
      notifyListeners();
    }
  }

  Future<bool> createItinerary(Map<String, dynamic> itinerary) async {
    final token = _accessToken;
    if (token == null) return false;
    errorMessage = null;
    try {
      final created = await _apiService.createItinerary(token, itinerary);
      itineraries = [created, ...itineraries];
      notifyListeners();
      return true;
    } on DioException catch (error) {
      errorMessage =
          error.response?.data?.toString() ?? 'Could not save this trip.';
      notifyListeners();
      return false;
    }
  }

  Future<void> deleteItinerary(int id) async {
    final token = _accessToken;
    if (token == null) return;
    await _apiService.deleteItinerary(token, id);
    itineraries.removeWhere((itinerary) => itinerary['id'] == id);
    notifyListeners();
  }

  void setAuthenticated(bool value) {
    isAuthenticated = value;
    if (!value) {
      _accessToken = null;
      itineraries = [];
      savedDiscoveredPlaces = [];
    }
    notifyListeners();
  }

  void toggleSave(String id) {
    destinations = destinations.map((destination) {
      if (destination.id == id) {
        return Destination(
          id: destination.id,
          name: destination.name,
          location: destination.location,
          country: destination.country,
          category: destination.category,
          description: destination.description,
          imageUrl: destination.imageUrl,
          dailyBudget: destination.dailyBudget,
          latitude: destination.latitude,
          longitude: destination.longitude,
          isFeatured: destination.isFeatured,
          isSaved: !destination.isSaved,
        );
      }
      return destination;
    }).toList();
    notifyListeners();
  }

  @override
  void dispose() {
    _placeSearchDebounce?.cancel();
    super.dispose();
  }

  void toggleTheme() {
    isDarkMode = !isDarkMode;
    notifyListeners();
  }

  void setPreferredCurrency(String currency) {
    if (!{'INR', 'USD', 'EUR', 'GBP'}.contains(currency)) return;
    preferredCurrency = currency;
    notifyListeners();
  }
}
