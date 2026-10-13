import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tripmate/providers/tripmate_provider.dart';

class TripsScreen extends StatelessWidget {
  const TripsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<TripMateProvider>();

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'My Trips',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 18),
              Align(
                alignment: Alignment.centerRight,
                child: FilledButton.icon(
                  onPressed: () => _showCreateTripDialog(context),
                  icon: const Icon(Icons.add),
                  label: const Text('Plan a trip'),
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: provider.itineraries.isEmpty
                    ? Center(
                        child: Text(
                          'Your trips will appear here. Start with a destination you love.',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                      )
                    : ListView.separated(
                        itemCount: provider.itineraries.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final trip = provider.itineraries[index];
                          final destinationId = trip['destination']?.toString();
                          final destination = provider.destinations
                              .where((item) => item.id == destinationId)
                              .firstOrNull;
                          final start = trip['start_date']?.toString() ?? '';
                          final end = trip['end_date']?.toString() ?? '';
                          return Card(
                            child: ListTile(
                              leading: const CircleAvatar(
                                child: Icon(Icons.route_outlined),
                              ),
                              title: Text(
                                trip['trip_name']?.toString() ?? 'Trip',
                              ),
                              subtitle: Text(
                                '${destination?.name ?? 'Destination'} · $start to $end · ₹${trip['total_budget'] ?? 0}',
                              ),
                              trailing: PopupMenuButton<String>(
                                tooltip: 'Trip actions',
                                onSelected: (action) {
                                  if (action == 'delete' && trip['id'] is int) {
                                    provider.deleteItinerary(trip['id'] as int);
                                  }
                                },
                                itemBuilder: (_) => const [
                                  PopupMenuItem(
                                    value: 'delete',
                                    child: Text('Delete trip'),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showCreateTripDialog(BuildContext context) async {
    final provider = context.read<TripMateProvider>();
    final nameController = TextEditingController();
    final budgetController = TextEditingController(text: '15000');
    String? destinationId;
    DateTime startDate = DateTime.now().add(const Duration(days: 14));
    DateTime endDate = startDate.add(const Duration(days: 3));
    String? error;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Plan a trip'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'Trip name'),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: destinationId,
                  decoration: const InputDecoration(labelText: 'Destination'),
                  items: provider.destinations
                      .map(
                        (item) => DropdownMenuItem(
                          value: item.id,
                          child: Text(item.name),
                        ),
                      )
                      .toList(),
                  onChanged: (value) =>
                      setDialogState(() => destinationId = value),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: budgetController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Budget (INR)'),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: startDate,
                            firstDate: DateTime.now(),
                            lastDate: DateTime.now().add(
                              const Duration(days: 730),
                            ),
                          );
                          if (picked != null) {
                            setDialogState(() => startDate = picked);
                          }
                        },
                        child: Text('Start ${_date(startDate)}'),
                      ),
                    ),
                    Expanded(
                      child: TextButton(
                        onPressed: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: endDate.isBefore(startDate)
                                ? startDate
                                : endDate,
                            firstDate: startDate,
                            lastDate: DateTime.now().add(
                              const Duration(days: 730),
                            ),
                          );
                          if (picked != null) {
                            setDialogState(() => endDate = picked);
                          }
                        },
                        child: Text('End ${_date(endDate)}'),
                      ),
                    ),
                  ],
                ),
                if (error != null)
                  Text(
                    error!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () async {
                if (nameController.text.trim().isEmpty ||
                    destinationId == null) {
                  setDialogState(
                    () => error = 'Add a trip name and destination.',
                  );
                  return;
                }
                if (endDate.isBefore(startDate)) {
                  setDialogState(
                    () =>
                        error = 'End date must be on or after the start date.',
                  );
                  return;
                }
                final success = await provider.createItinerary({
                  'trip_name': nameController.text.trim(),
                  'destination': int.tryParse(destinationId!),
                  'start_date': _date(startDate),
                  'end_date': _date(endDate),
                  'travelers_count': 1,
                  'total_budget': double.tryParse(budgetController.text) ?? 0,
                });
                if (success && dialogContext.mounted) {
                  Navigator.pop(dialogContext);
                } else if (dialogContext.mounted) {
                  setDialogState(
                    () => error =
                        provider.errorMessage ?? 'Could not save this trip.',
                  );
                }
              },
              child: const Text('Save trip'),
            ),
          ],
        ),
      ),
    );
    nameController.dispose();
    budgetController.dispose();
  }

  static String _date(DateTime value) =>
      '${value.year.toString().padLeft(4, '0')}-${value.month.toString().padLeft(2, '0')}-${value.day.toString().padLeft(2, '0')}';
}
