import 'package:blue_thermal_printer/blue_thermal_printer.dart';
import 'package:usb_serial/usb_serial.dart';
import 'package:permission_handler/permission_handler.dart';

class PrinterDevice {
  final String name;
  final String? address;
  final String type; // 'network', 'bluetooth', 'usb'
  final int? vendorId;
  final int? productId;

  PrinterDevice({
    required this.name,
    this.address,
    required this.type,
    this.vendorId,
    this.productId,
  });
}

class PrinterDiscoveryService {
  final BlueThermalPrinter _bluetooth = BlueThermalPrinter.instance;

  /// Request Bluetooth permissions (required on Android 6+)
  Future<bool> requestBluetoothPermissions() async {
    Map<Permission, PermissionStatus> statuses = await [
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
      Permission.location, // Required on Android 6-11 for Bluetooth scanning
    ].request();

    return statuses.values.every((status) => status.isGranted);
  }

  /// Check if Bluetooth permissions are granted
  Future<bool> hasBluetoothPermissions() async {
    final scanPermission = await Permission.bluetoothScan.status;
    final connectPermission = await Permission.bluetoothConnect.status;
    return scanPermission.isGranted && connectPermission.isGranted;
  }

  /// Discover Bluetooth printers (bonded devices)
  Future<List<PrinterDevice>> discoverBluetoothPrinters() async {
    try {
      // Check permissions
      if (!await hasBluetoothPermissions()) {
        final granted = await requestBluetoothPermissions();
        if (!granted) {
          throw Exception('Bluetooth permissions denied');
        }
      }

      // Get bonded Bluetooth devices
      final devices = await _bluetooth.getBondedDevices();

      return devices.map((device) => PrinterDevice(
        name: device.name ?? 'Unknown',
        address: device.address,
        type: 'bluetooth',
      )).toList();
    } catch (e) {
      return [];
    }
  }

  /// Discover USB printers
  Future<List<PrinterDevice>> discoverUsbPrinters() async {
    try {
      final devices = await UsbSerial.listDevices();

      // Filter for printer devices (class 7) or known thermal printer vendors
      final printers = devices.where((device) {
        // Common thermal printer vendor IDs
        final knownVendors = [
          0x0416, // Vendor 1
          0x04b8, // Epson
          0x0519, // Star Micronics
          0x1504, // Bixolon
          0x0A5F, // Citizen
        ];

        return knownVendors.contains(device.vid);
      }).toList();

      return printers.map((device) => PrinterDevice(
        name: device.productName ?? 'USB Printer (${device.vid}:${device.pid})',
        address: null,
        type: 'usb',
        vendorId: device.vid,
        productId: device.pid,
      )).toList();
    } catch (e) {
      return [];
    }
  }

  /// Discover all available printers
  Future<List<PrinterDevice>> discoverAllPrinters() async {
    final results = <PrinterDevice>[];

    // Bluetooth discovery
    try {
      final btPrinters = await discoverBluetoothPrinters();
      results.addAll(btPrinters);
    } catch (e) {
      // Ignore Bluetooth discovery errors
    }

    // USB discovery
    try {
      final usbPrinters = await discoverUsbPrinters();
      results.addAll(usbPrinters);
    } catch (e) {
      // Ignore USB discovery errors
    }

    return results;
  }

  /// Test Bluetooth connection to a printer
  Future<bool> testBluetoothConnection(String address) async {
    try {
      final devices = await _bluetooth.getBondedDevices();
      final device = devices.firstWhere(
        (d) => d.address == address,
        orElse: () => throw Exception('Device not found'),
      );

      await _bluetooth.connect(device);
      await Future.delayed(const Duration(seconds: 1));
      await _bluetooth.disconnect();
      
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Test USB connection to a printer
  Future<bool> testUsbConnection(int vendorId, int productId) async {
    try {
      final devices = await UsbSerial.listDevices();
      final device = devices.firstWhere(
        (d) => d.vid == vendorId && d.pid == productId,
        orElse: () => throw Exception('USB device not found'),
      );

      final port = await device.create();
      if (port == null) return false;

      final opened = await port.open();
      if (!opened) return false;

      await port.close();
      return true;
    } catch (e) {
      return false;
    }
  }
}
