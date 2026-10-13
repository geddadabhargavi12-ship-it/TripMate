import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tripmate/providers/tripmate_provider.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  static const Map<String, IconData> _interestIcons = {
    'Nature': Icons.landscape_outlined,
    'Beach': Icons.beach_access_outlined,
    'Heritage': Icons.account_balance_outlined,
    'Adventure': Icons.hiking_outlined,
    'Mountain': Icons.terrain_outlined,
    'City': Icons.location_city_outlined,
  };

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<TripMateProvider>();

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: ListView(
              padding: const EdgeInsets.all(24),
              shrinkWrap: true,
              children: [
                const Icon(Icons.flight_takeoff_rounded, size: 52, color: Color(0xFF0F766E)),
                const SizedBox(height: 20),
                Text(
                  'What makes a great trip for you?',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 10),
                Text(
                  'Choose a few interests and we’ll tailor destination ideas to your style.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Colors.grey[700]),
                ),
                const SizedBox(height: 26),
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 10,
                  runSpacing: 10,
                  children: TripMateProvider.travelInterests.map((interest) {
                    final selected = provider.selectedInterests.contains(interest);
                    return FilterChip(
                      avatar: Icon(_interestIcons[interest], size: 18),
                      label: Text(interest),
                      selected: selected,
                      onSelected: (_) => context.read<TripMateProvider>().toggleInterest(interest),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 28),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: provider.selectedInterests.isEmpty
                        ? null
                        : () => context.read<TripMateProvider>().completeOnboarding(),
                    icon: const Icon(Icons.arrow_forward_rounded),
                    label: Text(
                      provider.selectedInterests.isEmpty
                          ? 'Choose at least one interest'
                          : 'Show my trip ideas',
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
