import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tripmate/app.dart';
import 'package:tripmate/providers/tripmate_provider.dart';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (_) => TripMateProvider()..loadDestinations(),
      child: const TripMateApp(),
    ),
  );
}
