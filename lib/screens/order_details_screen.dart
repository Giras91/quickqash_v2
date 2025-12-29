import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/order.dart';
import '../models/order_item.dart';
import '../repositories/repositories.dart';

class OrderDetailsScreen extends ConsumerWidget {
  final String orderId;

  const OrderDetailsScreen({super.key, required this.orderId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final orderRepo = ref.watch(orderRepositoryProvider);
    final id = int.tryParse(orderId);
    if (id == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Order Details')),
        body: const Center(child: Text('Invalid order ID')),
      );
    }

    return FutureBuilder<Order?>(
      future: orderRepo.getById(id),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            appBar: AppBar(title: const Text('Order Details')),
            body: const Center(child: CircularProgressIndicator()),
          );
        }

        final order = snapshot.data;
        if (order == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Order Details')),
            body: const Center(child: Text('Order not found')),
          );
        }

        return FutureBuilder<List<OrderItem>>(
          future: orderRepo.getOrderItems(order.orderId),
          builder: (context, itemsSnapshot) {
            final items = itemsSnapshot.data ?? [];

            return Scaffold(
              appBar: AppBar(
                title: const Text('Order Details'),
                leading: const BackButton(),
              ),
              body: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Order ID: ${order.orderId.substring(0, 8).toUpperCase()}',
                                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      order.timestamp.toLocal().toString().split('.')[0],
                                      style: Theme.of(context).textTheme.bodySmall,
                                    ),
                                  ],
                                ),
                                Chip(
                                  label: Text(order.status),
                                  backgroundColor: _getStatusBgColor(order.status),
                                  labelStyle: TextStyle(color: _getStatusColor(order.status)),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('Mode: ${order.mode.toUpperCase()}'),
                                if (order.tableName != null) Text('Table: ${order.tableName}'),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Items
                    Text(
                      'Items',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    if (items.isEmpty)
                      const Center(child: Text('No items'))
                    else
                      Card(
                        child: Column(
                          children: items.asMap().entries.map((entry) {
                            final item = entry.value;
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(item.itemName),
                                        if (item.notes != null && item.notes!.isNotEmpty)
                                          Text(
                                            'Notes: ${item.notes}',
                                            style: Theme.of(context).textTheme.bodySmall,
                                          ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text('x${item.quantity}'),
                                  const SizedBox(width: 8),
                                  Text('\$${(item.price * item.quantity).toStringAsFixed(2)}'),
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    const SizedBox(height: 16),

                    // Totals
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          children: [
                            _buildTotalRow(context, 'Subtotal', order.subtotal),
                            _buildTotalRow(context, 'Tax', order.tax),
                            if (order.discount > 0) _buildTotalRow(context, 'Discount', -order.discount),
                            const Divider(),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Total',
                                  style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                                ),
                                Text(
                                  '\$${order.total.toStringAsFixed(2)}',
                                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                        fontWeight: FontWeight.bold,
                                        color: Theme.of(context).colorScheme.primary,
                                      ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Actions
                    Row(
                      children: [
                        Expanded(
                          child: FilledButton.icon(
                            icon: const Icon(Icons.print),
                            label: const Text('Reprint'),
                            onPressed: () {
                              // TODO: Trigger reprint of order
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Printing order...')),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildTotalRow(BuildContext context, String label, double amount) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label),
        Text('\$${amount.toStringAsFixed(2)}'),
      ],
    );
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

  Color _getStatusBgColor(String status) {
    switch (status) {
      case 'completed':
        return Colors.green.shade50;
      case 'pending':
        return Colors.orange.shade50;
      case 'cancelled':
        return Colors.red.shade50;
      default:
        return Colors.grey.shade50;
    }
  }
}
