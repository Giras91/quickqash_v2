import 'dart:io';
import 'dart:typed_data';
import 'package:blue_thermal_printer/blue_thermal_printer.dart';
import 'package:usb_serial/usb_serial.dart';
import 'package:sunmi_printer_plus/sunmi_printer_plus.dart';

/// Simple printer abstraction.
abstract class PrinterAdapter {
  Future<void> printBytes(Uint8List data);
}

/// ESC/POS network printer over TCP (e.g., port 9100).
class EscPosNetworkPrinter implements PrinterAdapter {
  final String host;
  final int port;
  final Duration timeout;

  EscPosNetworkPrinter({
    required this.host,
    this.port = 9100,
    this.timeout = const Duration(seconds: 5),
  });

  @override
  Future<void> printBytes(Uint8List data) async {
    final socket = await Socket.connect(host, port, timeout: timeout);
    try {
      socket.add(data);
      await socket.flush();
    } finally {
      await socket.close();
    }
  }
}

/// ESC/POS Bluetooth thermal printer adapter
class EscPosBluetoothPrinter implements PrinterAdapter {
  final String address;
  final String name;
  final BlueThermalPrinter _bluetooth = BlueThermalPrinter.instance;

  EscPosBluetoothPrinter({
    required this.address,
    required this.name,
  });

  @override
  Future<void> printBytes(Uint8List data) async {
    try {
      // Check if already connected
      final isConnected = await _bluetooth.isConnected ?? false;
      
      if (!isConnected) {
        // Get bonded devices and find our printer
        final devices = await _bluetooth.getBondedDevices();
        final device = devices.firstWhere(
          (d) => d.address == address,
          orElse: () => throw Exception('Bluetooth device not found: $address'),
        );

        // Connect to the device
        await _bluetooth.connect(device);
      }

      // Send print data
      _bluetooth.writeBytes(data);

      // Wait a bit for printing to complete
      await Future.delayed(const Duration(milliseconds: 500));
    } catch (e) {
      throw Exception('Bluetooth print error: $e');
    }
  }

  /// Disconnect from Bluetooth printer
  Future<void> disconnect() async {
    try {
      await _bluetooth.disconnect();
    } catch (e) {
      // Silently handle disconnect errors
    }
  }
}

/// ESC/POS USB thermal printer adapter
class EscPosUsbPrinter implements PrinterAdapter {
  final int vendorId;
  final int productId;
  UsbPort? _port;

  EscPosUsbPrinter({
    required this.vendorId,
    required this.productId,
  });

  @override
  Future<void> printBytes(Uint8List data) async {
    try {
      // List USB devices
      final devices = await UsbSerial.listDevices();

      // Find our printer
      final device = devices.firstWhere(
        (d) => d.vid == vendorId && d.pid == productId,
        orElse: () => throw Exception('USB device not found: VID=$vendorId, PID=$productId'),
      );

      // Create port
      _port = await device.create();
      if (_port == null) {
        throw Exception('Failed to create USB port');
      }

      // Open port and configure
      final opened = await _port!.open();
      if (!opened) {
        throw Exception('Failed to open USB port');
      }

      await _port!.setDTR(true);
      await _port!.setRTS(true);
      await _port!.setPortParameters(
        9600, // Baud rate
        UsbPort.DATABITS_8,
        UsbPort.STOPBITS_1,
        UsbPort.PARITY_NONE,
      );

      // Send print data
      await _port!.write(data);

      // Wait for data to be transmitted
      await Future.delayed(const Duration(milliseconds: 500));
    } catch (e) {
      throw Exception('USB print error: $e');
    } finally {
      // Close port
      await _port?.close();
      _port = null;
    }
  }
}

/// Sunmi built-in thermal printer adapter (for Sunmi POS devices)
class SunmiBuiltInPrinter implements PrinterAdapter {
  @override
  Future<void> printBytes(Uint8List data) async {
    try {
      // Bind to Sunmi printer service
      await SunmiPrinter.bindingPrinter();
      
      // Initialize printer
      await SunmiPrinter.initPrinter();
      
      // Convert bytes to string and print (Sunmi doesn't support raw bytes directly)
      // For proper ESC/POS support, you may need to use Sunmi's specific methods
      await SunmiPrinter.printText(String.fromCharCodes(data));
      
      // Cut paper
      await SunmiPrinter.cut();
    } catch (e) {
      throw Exception('Sunmi printer error: $e');
    }
  }
}
