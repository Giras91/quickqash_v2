import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../repositories/repositories.dart';

class OrderHistoryScreen extends ConsumerStatefulWidget {
  const OrderHistoryScreen({super.key});

  @override
  ConsumerState<OrderHistoryScreen> createState() => _OrderHistoryScreenState();
}

class _OrderHistoryScreenState extends ConsumerState<OrderHistoryScreen> {
  DateTimeRange? _dateRange;
  String? _selectedMode; // retail, cafe, restaurant

  @override
  Widget build(BuildContext context) {
    final ordersAsync = ref.watch(ref.watch(orderRepositoryProvider).watchAll() as dynamic);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Order History'),
        leading: const BackButton(),
      ),
      body: Column(
        children: [
          // Filter bar
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              border: Border(
                bottom: BorderSide(color: Theme.of(context).dividerColor),
              ),
            ),
            child: Column(
              children: [
                // Date range picker
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.date_range),
                        label: Text(_dateRange == null
                            ? 'All dates'
                            : '${_dateRange!.start.toLocal().toString().split(' ')[0]} to ${_dateRange!.end.toLocal().toString().split(' ')[0]}'),
                        onPressed: () async {
                          final picked = await showDateRangePicker(
                            context: context,
                            firstDate: DateTime(2020),
                            lastDate: DateTime.now().add(const Duration(days: 1)),
                          );
                          if (picked != null) {
                            setState(() => _dateRange = picked);
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (_dateRange != null)
                      IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () => setState(() => _dateRange = null),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                // Mode filter
                Row(
                  children: [
                    const Text('Mode: '),
                    const SizedBox(width: 8),
                    Expanded(
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            FilterChip(
                              label: const Text('All'),
                              selected: _selectedMode == null,
                              onSelected: (_) => setState(() => _selectedMode = null),
                            ),
                            const SizedBox(width: 8),
                            FilterChip(
                              label: const Text('Retail'),
                              selected: _selectedMode == 'retail',
                              onSelected: (_) => setState(() => _selectedMode = 'retail'),
                            ),
                            const SizedBox(width: 8),
                            FilterChip(
                              label: const Text('Cafe'),
                              selected: _selectedMode == 'cafe',
                              onSelected: (_) => setState(() => _selectedMode = 'cafe'),
                            ),
                            const SizedBox(width: 8),
                            FilterChip(
                              label: const Text('Restaurant'),
                              selected: _selectedMode == 'restaurant',
                              onSelected: (_) => setState(() => _selectedMode = 'restaurant'),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Orders list
          Expanded(
            child: ordersAsync.when(
              data: (allOrders) {
                // Apply filters
                var filtered = allOrders;

                if (_dateRange != null) {
                  filtered = filtered
                      .where((o) =>
                          o.timestamp.isAfter(_dateRange!.start) &&
                          o.timestamp.isBefore(_dateRange!.end.add(const Duration(days: 1))))
                      .toList();
                }

                if (_selectedMode != null) {
                  filtered = filtered.where((o) => o.mode == _selectedMode).toList();
                }

                // Sort by timestamp descending
                filtered.sort((a, b) => b.timestamp.compareTo(a.timestamp));

                if (filtered.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.receipt_long_outlined,
                          size: 64,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(height: 16),
                        const Text('No orders found'),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(8),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final order = filtered[index];
                    return Card(
                      child: ListTile(
                        leading: _getModeIcon(order.mode),
                        title: Text(
                          '${order.orderId.substring(0, 8).toUpperCase()} • \$${order.total.toStringAsFixed(2)}',
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              order.timestamp.toLocal().toString().split('.')[0],
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                            if (order.tableName != null)
                              Text(order.tableName!, style: Theme.of(context).textTheme.bodySmall),
                          ],
                        ),
                        trailing: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Chip(
                              label: Text(order.status),
                              labelStyle: TextStyle(
                                fontSize: 12,
                                color: _getStatusColor(order.status),
                              ),
                            ),
                          ],
                        ),
                        onTap: () => context.push('/order-details/${order.id}'),
                      ),
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, s) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, size: 64),
                    const SizedBox(height: 16),
                    Text('Error loading orders: $e'),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Icon _getModeIcon(String mode) {
    switch (mode) {
      case 'retail':
        return const Icon(Icons.shopping_cart);
      case 'cafe':
        return const Icon(Icons.local_cafe);
      case 'restaurant':
        return const Icon(Icons.restaurant);
      default:
        return const Icon(Icons.receipt);
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'completed':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}
