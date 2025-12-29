import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../models/item.dart';
import '../repositories/repositories.dart';

// Providers for watching item and inventory data
final _itemsStreamProvider = StreamProvider<List<Item>>((ref) async* {
  final repo = ref.watch(itemRepositoryProvider);
  yield* repo.watchAll();
});

final _lowStockItemsStreamProvider = StreamProvider<List<Item>>((ref) async* {
  final repo = ref.watch(inventoryRepositoryProvider);
  yield* repo.watchLowStockItems();
});

class InventoryManagementScreen extends ConsumerStatefulWidget {
  const InventoryManagementScreen({super.key});

  @override
  ConsumerState<InventoryManagementScreen> createState() => _InventoryManagementScreenState();
}

class _InventoryManagementScreenState extends ConsumerState<InventoryManagementScreen> {
  bool _showLowStockOnly = false;

  @override
  Widget build(BuildContext context) {
    final itemsAsync = ref.watch(_itemsStreamProvider);
    final lowStockAsync = ref.watch(_lowStockItemsStreamProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Inventory Management'),
        leading: const BackButton(),
      ),
      body: Column(
        children: [
          // Toggle low-stock view
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              border: Border(
                bottom: BorderSide(color: Theme.of(context).dividerColor),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: CheckboxListTile(
                    title: const Text('Show Low Stock Only'),
                    value: _showLowStockOnly,
                    onChanged: (v) => setState(() => _showLowStockOnly = v ?? false),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ],
            ),
          ),
          // Items list
          Expanded(
            child: _showLowStockOnly
                ? lowStockAsync.when(
                    data: (lowStockItems) => _buildItemsList(context, lowStockItems),
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (e, s) => Center(child: Text('Error: $e')),
                  )
                : itemsAsync.when(
                    data: (items) {
                      final active = items.where((i) => i.isActive).toList();
                      return _buildItemsList(context, active);
                    },
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (e, s) => Center(child: Text('Error: $e')),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildItemsList(BuildContext context, List<Item> items) {
    if (items.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.inventory_2_outlined,
              size: 64,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 16),
            Text(_showLowStockOnly ? 'No low stock items' : 'No items'),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        final isLow = item.lowStockThreshold != null && item.quantity <= item.lowStockThreshold!;

        return Card(
          color: isLow ? Colors.red.shade50 : null,
          child: ListTile(
            leading: isLow
                ? Icon(Icons.warning, color: Colors.red.shade700)
                : Icon(Icons.inventory, color: Theme.of(context).colorScheme.primary),
            title: Text(item.name),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Stock: ${item.quantity.toStringAsFixed(2)} ${item.unit}'),
                if (item.lowStockThreshold != null)
                  Text(
                    'Threshold: ${item.lowStockThreshold!.toStringAsFixed(2)} ${item.unit}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: isLow ? Colors.red : Colors.orange,
                        ),
                  ),
              ],
            ),
            trailing: IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () => _showAdjustmentDialog(context, item),
            ),
            onTap: () => context.push('/inventory/details/${item.id}'),
          ),
        );
      },
    );
  }

  void _showAdjustmentDialog(BuildContext context, Item item) {
    final quantityController = TextEditingController();
    final notesController = TextEditingController();
    String selectedReason = 'adjustment';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Adjust Stock: ${item.name}'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Current: ${item.quantity.toStringAsFixed(2)} ${item.unit}'),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: selectedReason,
                decoration: const InputDecoration(labelText: 'Reason'),
                items: ['adjustment', 'restock', 'damage', 'loss']
                    .map((r) => DropdownMenuItem(value: r, child: Text(r)))
                    .toList(),
                onChanged: (v) => selectedReason = v ?? 'adjustment',
              ),
              const SizedBox(height: 12),
              TextField(
                controller: quantityController,
                decoration: const InputDecoration(
                  labelText: 'Quantity Change',
                  hintText: 'e.g., +10 or -5',
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: notesController,
                decoration: const InputDecoration(
                  labelText: 'Notes (optional)',
                ),
                maxLines: 2,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              final messenger = ScaffoldMessenger.of(context);
              final navigator = Navigator.of(context);
              
              final change = double.tryParse(quantityController.text);
              if (change == null) {
                messenger.showSnackBar(
                  const SnackBar(content: Text('Invalid quantity')),
                );
                return;
              }

              final repo = ref.read(inventoryRepositoryProvider);
              await repo.logMovement(
                itemId: int.tryParse(item.id.toString()) ?? 0,
                itemName: item.name,
                quantityChange: change,
                reason: selectedReason,
                notes: notesController.text.isEmpty ? null : notesController.text,
              );

              if (mounted) {
                navigator.pop();
                messenger.showSnackBar(
                  SnackBar(content: Text('Stock adjusted by $change')),
                );
              }
            },
            child: const Text('Apply'),
          ),
        ],
      ),
    );
  }
}
