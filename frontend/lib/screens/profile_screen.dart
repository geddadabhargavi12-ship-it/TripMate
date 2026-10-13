import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tripmate/models/destination.dart';
import 'package:tripmate/providers/tripmate_provider.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<TripMateProvider>();

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const SizedBox(height: 12),
            CircleAvatar(
              radius: 42,
              backgroundColor: const Color(0xFF0F766E),
              child: const Icon(Icons.person, size: 42, color: Colors.white),
            ),
            const SizedBox(height: 16),
            Text(
              provider.userName,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            Text(
              provider.userEmail,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 24),
            ListTile(
              leading: const Icon(Icons.dark_mode_outlined),
              title: const Text('Dark mode'),
              trailing: Switch(
                value: provider.isDarkMode,
                onChanged: (_) => provider.toggleTheme(),
              ),
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.favorite_outline),
              title: const Text('Saved destinations'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => _showSavedDestinations(context, provider),
            ),
            ListTile(
              leading: const Icon(Icons.notifications_none),
              title: const Text('Notifications'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => showDialog<void>(
                context: context,
                builder: (dialogContext) => AlertDialog(
                  title: const Text('Notifications'),
                  content: const Text('You are all caught up.'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(dialogContext),
                      child: const Text('Close'),
                    ),
                  ],
                ),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.currency_exchange),
              title: const Text('Currency'),
              trailing: DropdownButton<String>(
                value: provider.preferredCurrency,
                items: const ['INR', 'USD', 'EUR', 'GBP']
                    .map(
                      (currency) => DropdownMenuItem(
                        value: currency,
                        child: Text(currency),
                      ),
                    )
                    .toList(),
                onChanged: (currency) {
                  if (currency != null) provider.setPreferredCurrency(currency);
                },
              ),
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Logout'),
              onTap: () => provider.setAuthenticated(false),
            ),
          ],
        ),
      ),
    );
  }

  void _showSavedDestinations(BuildContext context, TripMateProvider provider) {
    showModalBottomSheet<void>(
      context: context,
      builder: (sheetContext) {
        final saved = provider.destinations
            .where((destination) => destination.isSaved)
            .toList();
        final discovered = provider.savedDiscoveredPlaces;
        return SafeArea(
          child: SizedBox(
            height: 360,
            child: saved.isEmpty && discovered.isEmpty
                ? const Center(
                    child: Text(
                      'Save destinations from Explore to find them here.',
                    ),
                  )
                : ListView(
                    children: [
                      const ListTile(title: Text('Saved destinations')),
                      ...discovered.map(
                        (place) => ListTile(
                          title: Text(place.name),
                          subtitle: Text(place.address),
                          trailing: IconButton(
                            tooltip: 'Remove saved place',
                            icon: const Icon(Icons.bookmark_remove_outlined),
                            onPressed: () =>
                                provider.toggleDiscoveredPlaceSave(place),
                          ),
                        ),
                      ),
                      ...saved.map(
                        (Destination destination) => ListTile(
                          title: Text(destination.name),
                          subtitle: Text(destination.location),
                          trailing: IconButton(
                            tooltip: 'Remove saved destination',
                            icon: const Icon(Icons.bookmark_remove_outlined),
                            onPressed: () =>
                                provider.toggleSave(destination.id),
                          ),
                        ),
                      ),
                    ],
                  ),
          ),
        );
      },
    );
  }
}
