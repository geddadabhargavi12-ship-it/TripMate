import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tripmate/providers/tripmate_provider.dart';
import 'package:tripmate/widgets/destination_image.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key, this.onExplore});

  final VoidCallback? onExplore;

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<TripMateProvider>();
    final query = provider.searchQuery.trim().toLowerCase();
    final recommendations = provider.recommendedDestinations.where((
      destination,
    ) {
      if (query.isEmpty) return true;
      return destination.name.toLowerCase().contains(query) ||
          destination.location.toLowerCase().contains(query) ||
          destination.country.toLowerCase().contains(query) ||
          destination.description.toLowerCase().contains(query);
    }).toList();
    final featured = recommendations.where((d) => d.isFeatured).toList();
    final featuredToShow = featured.isEmpty
        ? recommendations.take(4).toList()
        : featured;

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Good morning',
                      style: TextStyle(color: Colors.grey),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      provider.userName,
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                  ],
                ),
                CircleAvatar(
                  radius: 22,
                  backgroundColor: const Color(0xFF0F766E),
                  child: const Icon(Icons.person, color: Colors.white),
                ),
              ],
            ),
            const SizedBox(height: 18),
            SearchBar(
              hintText: 'Search destinations',
              leading: const Icon(Icons.search),
              onChanged: provider.setSearchQuery,
              onSubmitted: (_) => onExplore?.call(),
              onTap: onExplore,
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: const Color(0xFF0F766E),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Weekend escape',
                          style: TextStyle(color: Colors.white70),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Plan your next adventure',
                          style: Theme.of(
                            context,
                          ).textTheme.titleLarge!.copyWith(color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.flight_takeoff_rounded,
                    color: Colors.white,
                    size: 40,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 26),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  provider.selectedInterests.isEmpty
                      ? 'Featured'
                      : 'Picked for you',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                TextButton(onPressed: onExplore, child: const Text('See all')),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 220,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: featuredToShow.length,
                separatorBuilder: (_, _) => const SizedBox(width: 14),
                itemBuilder: (context, index) {
                  final item = featuredToShow[index];
                  return ClipRRect(
                    borderRadius: BorderRadius.circular(18),
                    child: Stack(
                      children: [
                        DestinationImage(
                          url: item.imageUrl,
                          width: 190,
                          height: 220,
                        ),
                        Positioned(
                          left: 12,
                          right: 12,
                          bottom: 12,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.68),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(10),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item.name,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  Text(
                                    item.location,
                                    style: const TextStyle(
                                      color: Colors.white70,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 26),
            Text(
              'Popular destinations',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            ...recommendations
                .take(4)
                .map(
                  (item) => Card(
                    child: ListTile(
                      leading: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: DestinationImage(
                          url: item.imageUrl,
                          width: 70,
                          height: 70,
                        ),
                      ),
                      title: Text(item.name),
                      subtitle: Text('${item.location} • ${item.category}'),
                      trailing: IconButton(
                        onPressed: () => provider.toggleSave(item.id),
                        icon: Icon(
                          item.isSaved ? Icons.bookmark : Icons.bookmark_border,
                        ),
                      ),
                    ),
                  ),
                ),
          ],
        ),
      ),
    );
  }
}
