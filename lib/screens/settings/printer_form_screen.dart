import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../models/printer.dart';
import '../../repositories/repositories.dart';
import '../../services/printer_discovery_service.dart';

class PrinterFormScreen extends ConsumerStatefulWidget {
  final PrinterDevice? discoveredDevice;
  final int? printerId; // For editing existing printer

  const PrinterFormScreen({
    super.key,
    this.discoveredDevice,
    this.printerId,
  });

  @override
  ConsumerState<PrinterFormScreen> createState() => _PrinterFormScreenState();
}

class _PrinterFormScreenState extends ConsumerState<PrinterFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _hostController = TextEditingController();
  final _portController = TextEditingController(text: '9100');
  final _bluetoothAddressController = TextEditingController();
  final _bluetoothNameController = TextEditingController();
  final _usbVendorIdController = TextEditingController();
  final _usbProductIdController = TextEditingController();

  String _connectionType = 'network';
  String _printerType = 'kitchen';
  String _paperSize = '80mm';
  bool _isActive = true;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _initializeForm();
  }

  Future<void> _initializeForm() async {
    // If editing existing printer, load its data
    if (widget.printerId != null) {
      try {
        final repo = ref.read(printerRepositoryProvider);
        final printer = await repo.getById(widget.printerId!);
        if (printer != null && mounted) {
          _nameController.text = printer.name;
          _connectionType = printer.connectionType;
          _printerType = printer.type;
          _paperSize = printer.paperSize;
          _isActive = printer.isActive;

          _hostController.text = printer.host ?? '';
          _portController.text = printer.port?.toString() ?? '9100';
          _bluetoothAddressController.text = printer.bluetoothAddress ?? '';
          _bluetoothNameController.text = printer.bluetoothName ?? '';
          _usbVendorIdController.text = printer.usbVendorId?.toString() ?? '';
          _usbProductIdController.text = printer.usbProductId?.toString() ?? '';

          setState(() {});
        }
      } catch (e) {
        debugPrint('Error loading printer: $e');
      }
    }
    // If adding from discovered device, pre-fill data
    else if (widget.discoveredDevice != null) {
      final device = widget.discoveredDevice!;
      _nameController.text = device.name;
      _connectionType = device.type;

      if (device.type == 'bluetooth') {
        _bluetoothAddressController.text = device.address ?? '';
        _bluetoothNameController.text = device.name;
      } else if (device.type == 'usb') {
        _usbVendorIdController.text = device.vendorId?.toString() ?? '';
        _usbProductIdController.text = device.productId?.toString() ?? '';
      }

      setState(() {});
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _hostController.dispose();
    _portController.dispose();
    _bluetoothAddressController.dispose();
    _bluetoothNameController.dispose();
    _usbVendorIdController.dispose();
    _usbProductIdController.dispose();
    super.dispose();
  }

  Future<void> _savePrinter() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final repo = ref.read(printerRepositoryProvider);
      
      final printer = Printer()
        ..name = _nameController.text.trim()
        ..connectionType = _connectionType
        ..type = _printerType
        ..paperSize = _paperSize
        ..isActive = _isActive;

      // Set connection-specific fields
      switch (_connectionType) {
        case 'network':
          printer.host = _hostController.text.trim();
          printer.port = int.tryParse(_portController.text) ?? 9100;
          break;
        case 'bluetooth':
          printer.bluetoothAddress = _bluetoothAddressController.text.trim();
          printer.bluetoothName = _bluetoothNameController.text.trim();
          break;
        case 'usb':
          printer.usbVendorId = int.tryParse(_usbVendorIdController.text);
          printer.usbProductId = int.tryParse(_usbProductIdController.text);
          break;
        case 'sunmi':
          // No additional fields needed
          break;
      }

      // If editing, preserve the ID
      if (widget.printerId != null) {
        printer.id = widget.printerId!;
      }

      await repo.save(printer);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.printerId != null
                  ? 'Printer updated successfully'
                  : 'Printer added successfully',
            ),
          ),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving printer: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.printerId != null ? 'Edit Printer' : 'Add Printer'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Printer Name
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Printer Name',
                hintText: 'e.g., Kitchen Printer',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.print),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter a printer name';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Connection Type
            DropdownButtonFormField<String>(
              initialValue: _connectionType,
              decoration: const InputDecoration(
                labelText: 'Connection Type',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.cable),
              ),
              items: const [
                DropdownMenuItem(value: 'network', child: Text('Network (LAN)')),
                DropdownMenuItem(value: 'bluetooth', child: Text('Bluetooth')),
                DropdownMenuItem(value: 'usb', child: Text('USB')),
                DropdownMenuItem(value: 'sunmi', child: Text('Sunmi Built-in')),
              ],
              onChanged: widget.discoveredDevice == null
                  ? (value) => setState(() => _connectionType = value!)
                  : null,
            ),
            const SizedBox(height: 16),

            // Connection-specific fields
            ..._buildConnectionFields(),

            const SizedBox(height: 16),

            // Paper Size
            DropdownButtonFormField<String>(
              initialValue: _paperSize,
              decoration: const InputDecoration(
                labelText: 'Paper Size',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.straighten),
              ),
              items: const [
                DropdownMenuItem(value: '80mm', child: Text('80mm (Standard)')),
                DropdownMenuItem(value: '58mm', child: Text('58mm (Compact)')),
              ],
              onChanged: (value) => setState(() => _paperSize = value!),
            ),
            const SizedBox(height: 16),

            // Printer Type
            DropdownButtonFormField<String>(
              initialValue: _printerType,
              decoration: const InputDecoration(
                labelText: 'Printer Type',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.category),
              ),
              items: const [
                DropdownMenuItem(value: 'kitchen', child: Text('Kitchen')),
                DropdownMenuItem(value: 'receipt', child: Text('Receipt')),
              ],
              onChanged: (value) => setState(() => _printerType = value!),
            ),
            const SizedBox(height: 16),

            // Active Switch
            SwitchListTile(
              title: const Text('Enabled'),
              subtitle: const Text('Printer is active and ready to use'),
              value: _isActive,
              onChanged: (value) => setState(() => _isActive = value),
              secondary: const Icon(Icons.power_settings_new),
            ),
            const SizedBox(height: 24),

            // Save Button
            FilledButton(
              onPressed: _isLoading ? null : _savePrinter,
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(widget.printerId != null ? 'Update Printer' : 'Add Printer'),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildConnectionFields() {
    switch (_connectionType) {
      case 'network':
        return [
          TextFormField(
            controller: _hostController,
            decoration: const InputDecoration(
              labelText: 'IP Address',
              hintText: '192.168.1.100',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.computer),
            ),
            keyboardType: TextInputType.number,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Please enter IP address';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _portController,
            decoration: const InputDecoration(
              labelText: 'Port',
              hintText: '9100',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.numbers),
            ),
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Please enter port number';
              }
              return null;
            },
          ),
        ];

      case 'bluetooth':
        return [
          TextFormField(
            controller: _bluetoothAddressController,
            decoration: const InputDecoration(
              labelText: 'Bluetooth Address',
              hintText: 'AA:BB:CC:DD:EE:FF',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.bluetooth),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Please enter Bluetooth address';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _bluetoothNameController,
            decoration: const InputDecoration(
              labelText: 'Bluetooth Name',
              hintText: 'Thermal Printer',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.label),
            ),
          ),
        ];

      case 'usb':
        return [
          TextFormField(
            controller: _usbVendorIdController,
            decoration: const InputDecoration(
              labelText: 'Vendor ID',
              hintText: '1208',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.business),
            ),
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Please enter Vendor ID';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _usbProductIdController,
            decoration: const InputDecoration(
              labelText: 'Product ID',
              hintText: '1234',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.qr_code),
            ),
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Please enter Product ID';
              }
              return null;
            },
          ),
        ];

      case 'sunmi':
        return [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Icon(
                    Icons.info_outline,
                    size: 48,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Sunmi Built-in Printer',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'No additional configuration needed. The built-in printer will be used automatically on Sunmi devices.',
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ];

      default:
        return [];
    }
  }
}
