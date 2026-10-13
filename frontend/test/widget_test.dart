// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:tripmate/app.dart';
import 'package:tripmate/models/destination.dart';
import 'package:tripmate/providers/tripmate_provider.dart';

void main() {
  test(
    'search with no matches returns an empty result instead of fallback sample data',
    () {
      final provider = TripMateProvider();
      provider.destinations = Destination.sampleDestinations();
      provider.searchQuery = 'Bali';

      expect(provider.filteredDestinations, isEmpty);
    },
  );

  testWidgets('TripMate shows the welcome screen initially', (tester) async {
    final provider = TripMateProvider();
    provider.destinations = Destination.sampleDestinations();
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => provider,
        child: const TripMateApp(),
      ),
    );

    expect(find.text('What makes a great trip for you?'), findsOneWidget);
    expect(find.text('Choose at least one interest'), findsOneWidget);

    await tester.tap(find.text('Beach'));
    await tester.pump();

    expect(provider.selectedInterests, contains('Beach'));
    expect(find.text('Show my trip ideas'), findsOneWidget);

    await tester.tap(find.text('Show my trip ideas'));
    await tester.pump();

    expect(provider.hasSeenOnboarding, isTrue);
    expect(find.text('Welcome back'), findsOneWidget);
    expect(find.text('Sign in'), findsOneWidget);

    await tester.tap(find.text('New to TripMate? Create an account'));
    await tester.pumpAndSettle();
    expect(find.text('Full name'), findsOneWidget);

    await tester.tap(find.text('Already have an account? Sign in'));
    await tester.pumpAndSettle();
    expect(find.text('Full name'), findsNothing);

    provider.setAuthenticated(true);
    await tester.pumpAndSettle();

    expect(find.text('Goa'), findsWidgets);
    expect(find.text('Jaipur'), findsNothing);

    await tester.tap(find.text('Explore').last);
    await tester.pumpAndSettle();
    expect(find.text('Explore places'), findsOneWidget);
    expect(
      find.text(
        'Search for a city, country, landmark, restaurant, or natural place.',
      ),
      findsOneWidget,
    );

    await tester.tap(find.text('My Trips'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Plan a trip'));
    await tester.pumpAndSettle();
    expect(find.text('Budget (INR)'), findsOneWidget);
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
  });
}
