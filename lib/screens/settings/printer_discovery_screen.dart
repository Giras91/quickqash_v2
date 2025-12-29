import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../services/printer_discovery_service.dart';

class PrinterDiscoveryScreen extends ConsumerStatefulWidget {
  const PrinterDiscoveryScreen({super.key});

  @override
  ConsumerState<PrinterDiscoveryScreen> createState() => _PrinterDiscoveryScreenState();
}

class _PrinterDiscoveryScreenState extends ConsumerState<PrinterDiscoveryScreen> {
  final _discoveryService = PrinterDiscoveryService();
  List<PrinterDevice> _discoveredPrinters = [];
  bool _isScanning = false;
  String _selectedTab = 'all';

  @override
  void initState() {
    super.initState();
    _startDiscovery();
  }

  Future<void> _startDiscovery() async {
    setState(() {
      _isScanning = true;
      _discoveredPrinters = [];
    });

    try {
      // Request Bluetooth permissions first
      final hasPermissions = await _discoveryService.hasBluetoothPermissions();
      if (!hasPermissions) {
        final granted = await _discoveryService.requestBluetoothPermissions();
        if (!granted && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Bluetooth permissions required for printer discovery'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }

      // Discover printers based on selected tab
      List<PrinterDevice> printers;
      switch (_selectedTab) {
        case 'bluetooth':
          printers = await _discoveryService.discoverBluetoothPrinters();
          break;
        case 'usb':
          printers = await _discoveryService.discoverUsbPrinters();
          break;
        case 'all':
        default:
          printers = await _discoveryService.discoverAllPrinters();
      }

      setState(() {
        _discoveredPrinters = printers;
        _isScanning = false;
      });
    } catch (e) {
      setState(() => _isScanning = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Discovery error: $e')),
        );
      }
    }
  }

  void _addManualPrinter() {
    context.push('/settings/printers/add/manual');
  }

  void _configurePrinter(PrinterDevice device) {
    // Pass printer device details to configuration screen
    context.push('/settings/printers/add/configure', extra: device);
  }

  @override
  Widget build(BuildContext context) {
    final filteredPrinters = _selectedTab == 'all'
        ? _discoveredPrinters
        : _discoveredPrinters.where((p) => p.type == _selectedTab).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Discover Printers'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_note),
            onPressed: _addManualPrinter,
            tooltip: 'Add Manually',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _isScanning ? null : _startDiscovery,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter tabs
          Container(
            height: 48,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                _buildFilterChip('All', 'all'),
                const SizedBox(width: 8),
                _buildFilterChip('Bluetooth', 'bluetooth'),
                const SizedBox(width: 8),
                _buildFilterChip('USB', 'usb'),
              ],
            ),
          ),

          const Divider(height: 1),

          // Scanning indicator
          if (_isScanning)
            const LinearProgressIndicator()
          else
            const SizedBox(height: 4),

          // Printer list
          Expanded(
            child: _isScanning && _discoveredPrinters.isEmpty
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 16),
                        Text('Scanning for printers...'),
                      ],
                    ),
                  )
                : filteredPrinters.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.search_off,
                              size: 64,
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No printers found',
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Make sure your printer is powered on and nearby',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                                  ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 24),
                            FilledButton.icon(
                              onPressed: _startDiscovery,
                              icon: const Icon(Icons.refresh),
                              label: const Text('Scan Again'),
                            ),
                            const SizedBox(height: 12),
                            OutlinedButton.icon(
                              onPressed: _addManualPrinter,
                              icon: const Icon(Icons.edit_note),
                              label: const Text('Add Manually'),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: filteredPrinters.length,
                        itemBuilder: (context, index) {
                          final printer = filteredPrinters[index];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            child: ListTile(
                              leading: Icon(
                                _getIconForType(printer.type),
                                size: 32,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                              title: Text(
                                printer.name,
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const SizedBox(height: 4),
                                  if (printer.address != null)
                                    Text(printer.address!),
                                  if (printer.vendorId != null)
                                    Text('VID: ${printer.vendorId}, PID: ${printer.productId}'),
                                  const SizedBox(height: 4),
                                  Chip(
                                    label: Text(printer.type.toUpperCase()),
                                    labelStyle: const TextStyle(fontSize: 11),
                                    visualDensity: VisualDensity.compact,
                                    padding: EdgeInsets.zero,
                                  ),
                                ],
                              ),
                              trailing: FilledButton(
                                onPressed: () => _configurePrinter(printer),
                                child: const Text('Configure'),
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String value) {
    final isSelected = _selectedTab == value;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) {
          setState(() => _selectedTab = value);
        }
      },
      selectedColor: Theme.of(context).colorScheme.primaryContainer,
    );
  }

  IconData _getIconForType(String type) {
    switch (type) {
      case 'bluetooth':
        return Icons.bluetooth;
      case 'usb':
        return Icons.usb;
      case 'network':
        return Icons.wifi;
      default:
        return Icons.print;
    }
  }
}
