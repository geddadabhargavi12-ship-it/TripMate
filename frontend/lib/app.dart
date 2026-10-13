import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tripmate/providers/tripmate_provider.dart';
import 'package:tripmate/screens/auth_screen.dart';
import 'package:tripmate/screens/explore_screen.dart';
import 'package:tripmate/screens/home_screen.dart';
import 'package:tripmate/screens/profile_screen.dart';
import 'package:tripmate/screens/trips_screen.dart';
import 'package:tripmate/screens/welcome_screen.dart';
import 'package:tripmate/theme/app_theme.dart';

class TripMateApp extends StatefulWidget {
  const TripMateApp({super.key});

  @override
  State<TripMateApp> createState() => _TripMateAppState();
}

class _TripMateAppState extends State<TripMateApp> {
  int _selectedIndex = 0;

  void _onDrawerSelect(int index) {
    setState(() {
      _selectedIndex = index;
    });
    if (Navigator.canPop(context)) {
      Navigator.of(context).pop();
    }
  }

  Widget _buildDrawer(BuildContext context) {
    final provider = context.watch<TripMateProvider>();
    final drawerItems = [
      const _DrawerItem(label: 'Home', icon: Icons.home_rounded),
      const _DrawerItem(label: 'Explore', icon: Icons.explore_rounded),
      const _DrawerItem(label: 'My Trips', icon: Icons.route_rounded),
      const _DrawerItem(label: 'Profile', icon: Icons.person_rounded),
    ];

    return Drawer(
      child: SafeArea(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    child: Text(
                      provider.userName.isNotEmpty
                          ? provider.userName[0].toUpperCase()
                          : 'T',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    provider.userName,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  Text(
                    provider.userEmail,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
            ...drawerItems.asMap().entries.map((entry) {
              final index = entry.key;
              final item = entry.value;
              final isSelected = _selectedIndex == index;
              return ListTile(
                leading: Icon(item.icon),
                title: Text(item.label),
                selected: isSelected,
                selectedTileColor: Theme.of(
                  context,
                ).colorScheme.primary.withValues(alpha: 0.12),
                onTap: () => _onDrawerSelect(index),
              );
            }),
            const Divider(),
            SwitchListTile(
              secondary: const Icon(Icons.dark_mode_outlined),
              title: const Text('Dark mode'),
              value: provider.isDarkMode,
              onChanged: (_) => provider.toggleTheme(),
            ),
            ListTile(
              leading: const Icon(Icons.logout_rounded),
              title: const Text('Logout'),
              onTap: () {
                provider.setAuthenticated(false);
                if (Navigator.canPop(context)) {
                  Navigator.of(context).pop();
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<TripMateProvider>();

    final pages = [
      HomeScreen(onExplore: () => setState(() => _selectedIndex = 1)),
      const ExploreScreen(),
      const TripsScreen(),
      const ProfileScreen(),
    ];

    final appHome = !provider.hasSeenOnboarding
        ? const WelcomeScreen()
        : !provider.isAuthenticated
        ? const AuthScreen()
        : Scaffold(
            appBar: AppBar(
              title: const Text('TripMate'),
              leading: Builder(
                builder: (context) => IconButton(
                  icon: const Icon(Icons.menu_rounded),
                  onPressed: () => Scaffold.of(context).openDrawer(),
                ),
              ),
              actions: [
                IconButton(
                  icon: Icon(
                    provider.isDarkMode
                        ? Icons.light_mode_rounded
                        : Icons.dark_mode_rounded,
                  ),
                  onPressed: provider.toggleTheme,
                ),
              ],
            ),
            drawer: _buildDrawer(context),
            body: IndexedStack(index: _selectedIndex, children: pages),
            bottomNavigationBar: NavigationBar(
              selectedIndex: _selectedIndex,
              onDestinationSelected: (index) {
                setState(() {
                  _selectedIndex = index;
                });
              },
              destinations: const [
                NavigationDestination(
                  icon: Icon(Icons.home_outlined),
                  selectedIcon: Icon(Icons.home),
                  label: 'Home',
                ),
                NavigationDestination(
                  icon: Icon(Icons.explore_outlined),
                  selectedIcon: Icon(Icons.explore),
                  label: 'Explore',
                ),
                NavigationDestination(
                  icon: Icon(Icons.route_outlined),
                  selectedIcon: Icon(Icons.route),
                  label: 'My Trips',
                ),
                NavigationDestination(
                  icon: Icon(Icons.person_outline),
                  selectedIcon: Icon(Icons.person),
                  label: 'Profile',
                ),
              ],
            ),
          );

    return MaterialApp(
      title: 'TripMate',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: provider.isDarkMode ? ThemeMode.dark : ThemeMode.light,
      home: appHome,
    );
  }
}

class _DrawerItem {
  const _DrawerItem({required this.label, required this.icon});

  final String label;
  final IconData icon;
}
