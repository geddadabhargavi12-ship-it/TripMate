class DiscoveredPlace {
  const DiscoveredPlace({
    required this.id,
    required this.name,
    required this.latitude,
    required this.longitude,
    this.address = '',
    this.city = '',
    this.state = '',
    this.country = '',
    this.categories = const [],
    this.website,
    this.imageUrl,
    this.description,
    this.attribution = '',
    this.isSaved = false,
  });

  final String id;
  final String name;
  final double latitude;
  final double longitude;
  final String address;
  final String city;
  final String state;
  final String country;
  final List<String> categories;
  final String? website;
  final String? imageUrl;
  final String? description;
  final String attribution;
  final bool isSaved;

  String get region => [
    city,
    state,
    country,
  ].where((value) => value.isNotEmpty).toSet().join(', ');

  DiscoveredPlace copyWith({bool? isSaved}) => DiscoveredPlace(
    id: id,
    name: name,
    latitude: latitude,
    longitude: longitude,
    address: address,
    city: city,
    state: state,
    country: country,
    categories: categories,
    website: website,
    imageUrl: imageUrl,
    description: description,
    attribution: attribution,
    isSaved: isSaved ?? this.isSaved,
  );

  factory DiscoveredPlace.fromJson(Map<String, dynamic> json) {
    final latitude = _parseCoordinate(json['latitude']);
    final longitude = _parseCoordinate(json['longitude']);
    if (latitude == null || longitude == null) {
      throw const FormatException('Place is missing valid coordinates.');
    }
    final categories = json['categories'];
    return DiscoveredPlace(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? 'Unknown place',
      latitude: latitude,
      longitude: longitude,
      address: json['address']?.toString() ?? '',
      city: json['city']?.toString() ?? '',
      state: json['state']?.toString() ?? '',
      country: json['country']?.toString() ?? '',
      categories: categories is List
          ? categories.map((value) => value.toString()).toList()
          : const [],
      website: _optionalString(json['website']),
      imageUrl: _optionalString(json['image_url']),
      description: _optionalString(json['description']),
      attribution: json['attribution']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'latitude': latitude,
    'longitude': longitude,
    'address': address,
    'city': city,
    'state': state,
    'country': country,
    'categories': categories,
    'website': website,
    'image_url': imageUrl,
    'description': description,
  };

  static double? _parseCoordinate(dynamic value) {
    final parsed = double.tryParse('$value');
    if (parsed == null || !parsed.isFinite) return null;
    return parsed;
  }

  static String? _optionalString(dynamic value) {
    if (value is! String || value.isEmpty) return null;
    return value;
  }
}
