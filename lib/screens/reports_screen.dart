import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/order.dart';
import '../repositories/repositories.dart';

class ReportsScreen extends ConsumerStatefulWidget {
  const ReportsScreen({super.key});

  @override
  ConsumerState<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends ConsumerState<ReportsScreen> {
  int _selectedTab = 0; // 0=Daily, 1=Weekly, 2=Monthly

  @override
  Widget build(BuildContext context) {
    final ordersAsync = ref.watch(ref.watch(orderRepositoryProvider).watchAll() as dynamic);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Reports'),
        leading: const BackButton(),
      ),
      body: Column(
        children: [
          // Tab selector
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              border: Border(
                bottom: BorderSide(color: Theme.of(context).dividerColor),
              ),
            ),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  FilterChip(
                    label: const Text('Daily'),
                    selected: _selectedTab == 0,
                    onSelected: (_) => setState(() => _selectedTab = 0),
                  ),
                  const SizedBox(width: 8),
                  FilterChip(
                    label: const Text('Weekly'),
                    selected: _selectedTab == 1,
                    onSelected: (_) => setState(() => _selectedTab = 1),
                  ),
                  const SizedBox(width: 8),
                  FilterChip(
                    label: const Text('Monthly'),
                    selected: _selectedTab == 2,
                    onSelected: (_) => setState(() => _selectedTab = 2),
                  ),
                ],
              ),
            ),
          ),
          // Content
          Expanded(
            child: ordersAsync.when(
              data: (allOrders) {
                final now = DateTime.now();
                List<Order> filtered;

                if (_selectedTab == 0) {
                  // Daily: today only
                  final today = DateTime(now.year, now.month, now.day);
                  filtered = allOrders
                      .where((o) => o.timestamp.isAfter(today) && o.timestamp.isBefore(today.add(const Duration(days: 1))))
                      .toList();
                } else if (_selectedTab == 1) {
                  // Weekly: last 7 days
                  final sevenDaysAgo = now.subtract(const Duration(days: 7));
                  filtered = allOrders.where((o) => o.timestamp.isAfter(sevenDaysAgo)).toList();
                } else {
                  // Monthly: this month
                  final firstDay = DateTime(now.year, now.month, 1);
                  final lastDay = DateTime(now.year, now.month + 1, 1);
                  filtered = allOrders.where((o) => o.timestamp.isAfter(firstDay) && o.timestamp.isBefore(lastDay)).toList();
                }

                if (filtered.isEmpty) {
                  return Center(
                    child: Text(
                      'No orders in selected period',
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                  );
                }

                // Calculate summaries by mode
                final summaryByMode = <String, ({int count, double total})>{};
                double grandTotal = 0.0;
                int totalOrders = 0;

                for (final order in filtered) {
                  final mode = order.mode;
                  summaryByMode.update(
                    mode,
                    (existing) => (
                      count: existing.count + 1,
                      total: existing.total + order.total,
                    ),
                    ifAbsent: () => (count: 1, total: order.total),
                  );
                  grandTotal += order.total;
                  totalOrders += 1;
                }

                return SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Summary cards
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _getTabLabel(),
                                style: Theme.of(context).textTheme.titleLarge,
                              ),
                              const SizedBox(height: 16),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text('Total Orders', style: Theme.of(context).textTheme.bodySmall),
                                      Text(
                                        totalOrders.toString(),
                                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                                      ),
                                    ],
                                  ),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text('Total Revenue', style: Theme.of(context).textTheme.bodySmall),
                                      Text(
                                        '\$${grandTotal.toStringAsFixed(2)}',
                                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                              fontWeight: FontWeight.bold,
                                              color: Theme.of(context).colorScheme.primary,
                                            ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Breakdown by mode
                      Text(
                        'Breakdown by Mode',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 8),
                      ...summaryByMode.entries.map((entry) {
                        final mode = entry.key;
                        final count = entry.value.count;
                        final total = entry.value.total;
                        final percentage = (total / grandTotal) * 100;

                        return Card(
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      mode.toUpperCase(),
                                      style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                                    ),
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.end,
                                      children: [
                                        Text('\$${total.toStringAsFixed(2)}'),
                                        Text(
                                          '$count order${count == 1 ? '' : 's'}',
                                          style: Theme.of(context).textTheme.bodySmall,
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(4),
                                  child: LinearProgressIndicator(
                                    value: percentage / 100,
                                    minHeight: 8,
                                    backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                                    valueColor: AlwaysStoppedAnimation<Color>(_getModeColor(mode)),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${percentage.toStringAsFixed(1)}% of revenue',
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              ],
                            ),
                          ),
                        );
                      }),
                    ],
                  ),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, s) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, size: 64),
                    const SizedBox(height: 16),
                    Text('Error loading reports: $e'),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getTabLabel() {
    switch (_selectedTab) {
      case 0:
        return 'Today';
      case 1:
        return 'Last 7 Days';
      case 2:
        return 'This Month';
      default:
        return 'Report';
    }
  }

  Color _getModeColor(String mode) {
    switch (mode) {
      case 'retail':
        return Colors.blue;
      case 'cafe':
        return Colors.orange;
      case 'restaurant':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }
}
