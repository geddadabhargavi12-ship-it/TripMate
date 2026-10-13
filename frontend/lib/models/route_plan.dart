class RoutePlan {
  const RoutePlan({
    required this.distanceMeters,
    required this.durationSeconds,
    required this.paths,
    this.attribution = '',
  });

  final double distanceMeters;
  final double durationSeconds;
  // Each path stores [latitude, longitude] pairs, preserving separate segments.
  final List<List<List<double>>> paths;
  final String attribution;

  List<List<double>> get coordinates => paths.expand((path) => path).toList();

  String get distanceLabel {
    final kilometers = distanceMeters / 1000;
    return kilometers < 10
        ? '${kilometers.toStringAsFixed(1)} km'
        : '${kilometers.round()} km';
  }

  String get durationLabel {
    final totalMinutes = (durationSeconds / 60).round();
    final hours = totalMinutes ~/ 60;
    final minutes = totalMinutes % 60;
    if (hours == 0) return '$minutes min';
    if (minutes == 0) return '$hours hr';
    return '$hours hr $minutes min';
  }

  factory RoutePlan.fromJson(Map<String, dynamic> json) {
    final rawPaths = json['paths'];
    final rawCoordinates = json['coordinates'];
    final pathValues = rawPaths is List
        ? rawPaths
        : rawCoordinates is List
        ? [rawCoordinates]
        : const [];
    final paths = <List<List<double>>>[];
    for (final rawPath in pathValues.whereType<List>()) {
      final path = <List<double>>[];
      for (final rawPoint in rawPath.whereType<List>()) {
        if (rawPoint.length < 2) continue;
        final latitude = double.tryParse('${rawPoint[0]}');
        final longitude = double.tryParse('${rawPoint[1]}');
        if (latitude != null && longitude != null) {
          path.add([latitude, longitude]);
        }
      }
      if (path.length >= 2) paths.add(path);
    }
    final distance = double.tryParse('${json['distance_meters']}');
    final duration = double.tryParse('${json['duration_seconds']}');
    if (paths.isEmpty || distance == null || duration == null) {
      throw const FormatException('The route provider returned invalid data.');
    }
    return RoutePlan(
      distanceMeters: distance,
      durationSeconds: duration,
      paths: paths,
      attribution: json['attribution']?.toString() ?? '',
    );
  }
}
