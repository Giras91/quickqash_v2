import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/item.dart';
import '../repositories/repositories.dart';

final _lowStockAlertsProvider = StreamProvider<List<Item>>((ref) async* {
  final repo = ref.watch(inventoryRepositoryProvider);
  yield* repo.watchLowStockItems();
});

class LowStockAlertsScreen extends ConsumerWidget {
  const LowStockAlertsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lowStockAsync = ref.watch(_lowStockAlertsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Low Stock Alerts'),
        leading: const BackButton(),
      ),
      body: lowStockAsync.when(
        data: (items) {
          if (items.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.check_circle,
                    size: 64,
                    color: Colors.green.shade400,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'All items in stock!',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                ],
              ),
            );
          }

          // Group by criticality
          final critical = items
              .where((i) => i.quantity < 5)
              .toList();
          final warning = items
              .where((i) => i.quantity >= 5 && i.quantity < 10)
              .toList();

          return ListView(
            padding: const EdgeInsets.all(12),
            children: [
              if (critical.isNotEmpty) ...[
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(
                    'CRITICAL - Reorder Immediately',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: Colors.red.shade700,
                        ),
                  ),
                ),
                ...critical.map((item) => _buildAlertCard(context, item, Colors.red)),
                const SizedBox(height: 16),
              ],
              if (warning.isNotEmpty) ...[
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(
                    'WARNING - Low Stock',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: Colors.orange.shade700,
                        ),
                  ),
                ),
                ...warning.map((item) => _buildAlertCard(context, item, Colors.orange)),
              ],
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, s) => Center(child: Text('Error: $e')),
      ),
    );
  }

  Widget _buildAlertCard(BuildContext context, dynamic item, Color alertColor) {
    return Card(
      color: alertColor.withValues(alpha: 0.1),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: alertColor.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.warning_amber, color: alertColor),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.name,
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  Text(
                    'Stock: ${item.quantity.toStringAsFixed(2)} ${item.unit}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: alertColor,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  if (item.reorderQuantity != null)
                    Text(
                      'Reorder: ${item.reorderQuantity!.toStringAsFixed(2)} ${item.unit}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                ],
              ),
            ),
            FilledButton.tonal(
              style: FilledButton.styleFrom(
                backgroundColor: alertColor.withValues(alpha: 0.2),
              ),
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Reorder ${item.reorderQuantity ?? 'stock'} for ${item.name}')),
                );
              },
              child: const Text('Reorder'),
            ),
          ],
        ),
      ),
    );
  }
}
