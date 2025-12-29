import 'package:isar/isar.dart';

part 'printer.g.dart';

@collection
class Printer {
  Id id = Isar.autoIncrement;

  @Index(unique: true)
  late String name;

  // Connection type: 'network', 'bluetooth', 'usb', 'sunmi'
  late String connectionType;

  // Network settings
  String? host;
  int? port;

  // Bluetooth settings
  String? bluetoothAddress;
  String? bluetoothName;

  // USB settings
  int? usbVendorId;
  int? usbProductId;

  // Paper size: '80mm', '58mm'
  String paperSize = '80mm';

  late String type; // 'kitchen', 'receipt'
  bool isActive = true;
}
