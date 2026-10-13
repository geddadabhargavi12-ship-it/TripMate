class Destination {
  final String id;
  final String name;
  final String location;
  final String country;
  final String category;
  final String description;
  final String imageUrl;
  final double dailyBudget;
  final double latitude;
  final double longitude;
  final bool isFeatured;
  final bool isSaved;

  const Destination({
    required this.id,
    required this.name,
    required this.location,
    required this.country,
    required this.category,
    required this.description,
    required this.imageUrl,
    required this.dailyBudget,
    required this.latitude,
    required this.longitude,
    this.isFeatured = false,
    this.isSaved = false,
  });

  static List<Destination> sampleDestinations() {
    return [
      const Destination(
        id: 'araku',
        name: 'Araku Valley',
        location: 'Andhra Pradesh',
        country: 'India',
        category: 'Nature',
        description: 'A cool hill station with coffee estates, tribal heritage, and misty mountain roads.',
        imageUrl: 'https://images.unsplash.com/photo-1501785888041-af3ef285b470',
        dailyBudget: 2500,
        latitude: 18.3279,
        longitude: 82.8683,
        isFeatured: true,
      ),
      const Destination(
        id: 'goa',
        name: 'Goa',
        location: 'Western Coast',
        country: 'India',
        category: 'Beach',
        description: 'Sunrises, seafood, beach clubs and vibrant culture across the coastline.',
        imageUrl: 'https://images.unsplash.com/photo-1500375592092-40eb2168fd21',
        dailyBudget: 4200,
        latitude: 15.2993,
        longitude: 74.1240,
        isFeatured: true,
      ),
      const Destination(
        id: 'jaipur',
        name: 'Jaipur',
        location: 'Rajasthan',
        country: 'India',
        category: 'Heritage',
        description: 'Pink sandstone palaces, forts, bazaars and royal architecture.',
        imageUrl: 'https://images.unsplash.com/photo-1539650116574-75c0c6d73f6e',
        dailyBudget: 3800,
        latitude: 26.9124,
        longitude: 75.7873,
      ),
      const Destination(
        id: 'manali',
        name: 'Manali',
        location: 'Himachal Pradesh',
        country: 'India',
        category: 'Adventure',
        description: 'Snowy treks, alpine views and cosy mountain stays in the Himalayas.',
        imageUrl: 'https://images.unsplash.com/photo-1516483638261-f4dbaf036963',
        dailyBudget: 4200,
        latitude: 32.2396,
        longitude: 77.1887,
        isFeatured: true,
      ),
      const Destination(
        id: 'munnar',
        name: 'Munnar',
        location: 'Kerala',
        country: 'India',
        category: 'Mountain',
        description: 'Rolling tea gardens and cool mountain air.',
        imageUrl: 'https://images.unsplash.com/photo-1504593811423-6dd665756598?auto=format&fit=crop&w=960&q=80',
        dailyBudget: 3100,
        latitude: 10.0889,
        longitude: 77.0595,
      ),
      const Destination(
        id: 'visakhapatnam',
        name: 'Visakhapatnam',
        location: 'Andhra Pradesh',
        country: 'India',
        category: 'City',
        description: 'A coastal city with beaches, hills, and a lively waterfront.',
        imageUrl: 'https://images.unsplash.com/photo-1507525428034-b723cf961d3e?auto=format&fit=crop&w=960&q=80',
        dailyBudget: 3200,
        latitude: 17.6868,
        longitude: 83.2185,
        isFeatured: true,
      ),
    ];
  }
}
