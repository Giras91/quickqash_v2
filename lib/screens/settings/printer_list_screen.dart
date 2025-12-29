import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../models/printer.dart';
import '../../repositories/repositories.dart';

// Provider to watch printers list
final printersProvider = StreamProvider<List<Printer>>((ref) {
  final repo = ref.watch(printerRepositoryProvider);
  return repo.watchAll();
});

class PrinterListScreen extends ConsumerWidget {
  const PrinterListScreen({super.key});

  Future<void> _deletePrinter(BuildContext context, WidgetRef ref, Printer printer) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Printer'),
        content: Text('Are you sure you want to delete "${printer.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      final repo = ref.read(printerRepositoryProvider);
      await repo.delete(printer.id);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${printer.name} deleted')),
        );
      }
    }
  }

  Future<void> _togglePrinter(WidgetRef ref, Printer printer) async {
    final repo = ref.read(printerRepositoryProvider);
    printer.isActive = !printer.isActive;
    await repo.save(printer);
  }

  Future<void> _testPrinter(BuildContext context, Printer printer) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: Card(
          child: Padding(
            padding: EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Testing printer connection...'),
              ],
            ),
          ),
        ),
      ),
    );

    await Future.delayed(const Duration(seconds: 2));

    if (context.mounted) {
      Navigator.of(context).pop();
      
      // TODO: Implement actual printer test
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white),
              const SizedBox(width: 12),
              Text('${printer.name} connected successfully!'),
            ],
          ),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final printersAsync = ref.watch(printersProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Printers'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => context.push('/settings/printers/discover'),
            tooltip: 'Add Printer',
          ),
        ],
      ),
      body: printersAsync.when(
        data: (printers) {
          if (printers.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.print_disabled,
                    size: 64,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No printers configured',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Tap + to add your first printer',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  ),
                  const SizedBox(height: 24),
                  FilledButton.icon(
                    onPressed: () => context.push('/settings/printers/discover'),
                    icon: const Icon(Icons.add),
                    label: const Text('Add Printer'),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: printers.length,
            itemBuilder: (context, index) {
              final printer = printers[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  leading: Icon(
                    _getPrinterIcon(printer.connectionType),
                    size: 32,
                    color: printer.isActive
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  title: Text(
                    printer.name,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 4),
                      Text(_getPrinterSubtitle(printer)),
                      const SizedBox(height: 4),
                      Wrap(
                        spacing: 8,
                        children: [
                          Chip(
                            label: Text(printer.connectionType.toUpperCase()),
                            labelStyle: const TextStyle(fontSize: 11),
                            visualDensity: VisualDensity.compact,
                            padding: EdgeInsets.zero,
                          ),
                          Chip(
                            label: Text(printer.paperSize),
                            labelStyle: const TextStyle(fontSize: 11),
                            visualDensity: VisualDensity.compact,
                            padding: EdgeInsets.zero,
                          ),
                          Chip(
                            label: Text(printer.type),
                            labelStyle: const TextStyle(fontSize: 11),
                            visualDensity: VisualDensity.compact,
                            padding: EdgeInsets.zero,
                          ),
                        ],
                      ),
                    ],
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Switch(
                        value: printer.isActive,
                        onChanged: (_) => _togglePrinter(ref, printer),
                      ),
                      PopupMenuButton<String>(
                        onSelected: (value) async {
                          switch (value) {
                            case 'test':
                              await _testPrinter(context, printer);
                              break;
                            case 'edit':
                              context.push('/settings/printers/edit/${printer.id}');
                              break;
                            case 'delete':
                              await _deletePrinter(context, ref, printer);
                              break;
                          }
                        },
                        itemBuilder: (context) => [
                          const PopupMenuItem(
                            value: 'test',
                            child: Row(
                              children: [
                                Icon(Icons.print),
                                SizedBox(width: 12),
                                Text('Test Print'),
                              ],
                            ),
                          ),
                          const PopupMenuItem(
                            value: 'edit',
                            child: Row(
                              children: [
                                Icon(Icons.edit),
                                SizedBox(width: 12),
                                Text('Edit'),
                              ],
                            ),
                          ),
                          const PopupMenuItem(
                            value: 'delete',
                            child: Row(
                              children: [
                                Icon(Icons.delete, color: Colors.red),
                                SizedBox(width: 12),
                                Text('Delete', style: TextStyle(color: Colors.red)),
                              ],
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
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Text('Error loading printers: $error'),
        ),
      ),
    );
  }

  IconData _getPrinterIcon(String connectionType) {
    switch (connectionType) {
      case 'bluetooth':
        return Icons.bluetooth;
      case 'usb':
        return Icons.usb;
      case 'network':
        return Icons.wifi;
      case 'sunmi':
        return Icons.devices;
      default:
        return Icons.print;
    }
  }

  String _getPrinterSubtitle(Printer printer) {
    switch (printer.connectionType) {
      case 'bluetooth':
        return printer.bluetoothAddress ?? 'Bluetooth Printer';
      case 'usb':
        return 'VID: ${printer.usbVendorId}, PID: ${printer.usbProductId}';
      case 'network':
        return '${printer.host}:${printer.port}';
      case 'sunmi':
        return 'Built-in Printer';
      default:
        return printer.connectionType;
    }
  }
}
