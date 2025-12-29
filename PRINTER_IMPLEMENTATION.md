# Android Thermal Printer Implementation - Complete

## ✅ Implementation Status

All core components for Android thermal printer support (USB, Bluetooth, LAN, 80mm/58mm) have been successfully implemented.

### Completed Tasks

1. **Dependencies Added** ([pubspec.yaml](pubspec.yaml))
   - `blue_thermal_printer: ^1.2.3` - Bluetooth classic printer support
   - `usb_serial: ^0.5.2` - USB OTG printer support  
   - `permission_handler: ^11.4.0` - Runtime permissions (Bluetooth, Location)
   - `sunmi_printer_plus: ^2.1.3` - Sunmi POS device built-in printer

2. **Printer Model Extended** ([lib/models/printer.dart](lib/models/printer.dart))
   - Added `connectionType` field: `'network'|'bluetooth'|'usb'|'sunmi'`
   - Added Bluetooth fields: `bluetoothAddress`, `bluetoothName`
   - Added USB fields: `usbVendorId`, `usbProductId`
   - Added `paperSize` field: `'80mm'|'58mm'`
   - Isar schemas regenerated successfully

3. **Android Configuration** ([android/app/src/main/AndroidManifest.xml](android/app/src/main/AndroidManifest.xml))
   - **Bluetooth permissions**: `BLUETOOTH_SCAN`, `BLUETOOTH_CONNECT` (Android 12+)
   - **Bluetooth legacy**: `BLUETOOTH`, `BLUETOOTH_ADMIN` (Android 11 and below)
   - **Location permissions**: Required for Bluetooth scanning on Android 6-11
   - **Network permissions**: `INTERNET`, `ACCESS_NETWORK_STATE`
   - **USB feature**: `android.hardware.usb.host`
   - **USB device filters**: Created [usb_device_filter.xml](android/app/src/main/res/xml/usb_device_filter.xml) with vendor IDs for Epson (1208), Star (1305), Bixolon (5380), Citizen (2655), and generic printer class

4. **Printer Adapters** ([lib/printing/printer_adapter.dart](lib/printing/printer_adapter.dart))
   - `EscPosNetworkPrinter` - TCP socket (port 9100) for LAN printers ✅
   - `EscPosBluetoothPrinter` - Bluetooth classic using `blue_thermal_printer` ✅
   - `EscPosUsbPrinter` - USB OTG using `usb_serial` with 9600 baud rate ✅
   - `SunmiBuiltInPrinter` - Sunmi POS device integration ✅
   - All implement `PrinterAdapter.printBytes(Uint8List)` interface

5. **Printer Discovery Service** ([lib/services/printer_discovery_service.dart](lib/services/printer_discovery_service.dart))
   - `discoverBluetoothPrinters()` - Scans bonded Bluetooth devices
   - `discoverUsbPrinters()` - Lists USB devices filtered by known vendor IDs
   - `discoverAllPrinters()` - Combined discovery for all types
   - `requestBluetoothPermissions()` - Runtime permission requests
   - `testBluetoothConnection()` / `testUsbConnection()` - Connection validation

6. **Kitchen Ticket Service Updated** ([lib/printing/kitchen_ticket_service.dart](lib/printing/kitchen_ticket_service.dart))
   - Dynamic paper size support: `PaperSize.mm80` or `PaperSize.mm58`
   - `buildSimpleTicket()` - Basic ticket generation with paper size parameter
   - `buildKitchenTicket()` - Formatted kitchen orders with item details, modifiers, notes, table name, and timestamp
   - `printFormattedKitchenTicket()` - Full kitchen printing workflow

## 📋 How to Use

### 1. Request Permissions (Required for Bluetooth)

```dart
import 'package:quickqash/services/printer_discovery_service.dart';

final discoveryService = PrinterDiscoveryService();

// Request Bluetooth permissions before discovery
final granted = await discoveryService.requestBluetoothPermissions();
if (!granted) {
  // Handle permission denial
}
```

### 2. Discover Printers

```dart
// Discover all printers
final allPrinters = await discoveryService.discoverAllPrinters();

// Or discover by type
final bluetoothPrinters = await discoveryService.discoverBluetoothPrinters();
final usbPrinters = await discoveryService.discoverUsbPrinters();

// Test connection
for (final printer in bluetoothPrinters) {
  final connected = await discoveryService.testBluetoothConnection(printer.address!);
  print('${printer.name}: ${connected ? "✅" : "❌"}');
}
```

### 3. Save Printer to Database

```dart
import 'package:quickqash/models/printer.dart';
import 'package:quickqash/repositories/isar_provider.dart';

// Example: Bluetooth printer
final printer = Printer()
  ..name = 'Kitchen Printer'
  ..connectionType = 'bluetooth'
  ..bluetoothAddress = 'AA:BB:CC:DD:EE:FF'
  ..bluetoothName = 'Thermal Printer'
  ..paperSize = '80mm'
  ..type = 'kitchen'
  ..isActive = true;

// Save to Isar
final isar = await ref.read(isarProvider.future);
await isar.writeTxn(() => isar.printers.put(printer));
```

### 4. Print Kitchen Ticket

```dart
import 'package:quickqash/printing/printer_adapter.dart';
import 'package:quickqash/printing/kitchen_ticket_service.dart';

// Create adapter based on connectionType
final PrinterAdapter adapter;
switch (printer.connectionType) {
  case 'bluetooth':
    adapter = EscPosBluetoothPrinter(
      address: printer.bluetoothAddress!,
      name: printer.bluetoothName!,
    );
    break;
  case 'usb':
    adapter = EscPosUsbPrinter(
      vendorId: printer.usbVendorId!,
      productId: printer.usbProductId!,
    );
    break;
  case 'network':
    adapter = EscPosNetworkPrinter(
      host: printer.host!,
      port: printer.port ?? 9100,
    );
    break;
  case 'sunmi':
    adapter = SunmiBuiltInPrinter();
    break;
}

// Print formatted kitchen ticket
final ticketService = KitchenTicketService();
await ticketService.printFormattedKitchenTicket(
  adapter: adapter,
  orderNumber: '001',
  tableName: 'Table 5',
  items: [
    {
      'quantity': 2,
      'name': 'Latte',
      'modifiers': ['Large', 'Oat Milk', 'Extra Shot'],
      'notes': 'Extra hot',
    },
    {
      'quantity': 1,
      'name': 'Croissant',
      'modifiers': ['Butter'],
    },
  ],
  notes: 'Allergy: Nuts',
  paperSize: printer.paperSize, // '80mm' or '58mm'
);
```

## ⚠️ Important Notes

### Bluetooth
- **Pairing Required**: Devices must be paired in Android Bluetooth settings before discovery
- **Location Permission**: Required on Android 6-11 for Bluetooth scanning (privacy requirement)
- **Connection Persistence**: Bluetooth adapters automatically disconnect after printing
- **Interference**: May be unreliable in RF-heavy environments (crowded kitchens, near microwaves)

### USB
- **OTG Cable Required**: Most Android phones/tablets need USB OTG adapter
- **Power Draw**: Some thermal printers draw too much power for phone USB hosts
- **Vendor IDs**: `usb_device_filter.xml` includes common vendors (Epson, Star, Bixolon, Citizen)
  - Add more vendor IDs as needed for specific hardware
- **Permissions**: USB permissions requested automatically when connecting

### Network (LAN)
- **Static IP Recommended**: DHCP can change printer IPs; consider static assignment or mDNS
- **Port 9100**: Standard ESC/POS raw printing port (configure on printer)
- **Firewall**: Corporate networks may block port 9100

### Sunmi Devices
- **Built-in Printer**: Fastest option on Sunmi POS terminals (V2, V2 Pro, T2, etc.)
- **No Discovery**: Automatically available on Sunmi hardware
- **Text Only**: Current implementation uses `printText()` which may not support all ESC/POS features

### Paper Sizes
- **80mm**: Standard thermal paper (most common)
- **58mm**: Compact receipts (common for mobile printers)
- Paper size configured per printer in database

## 🚀 Next Steps (Not Implemented Yet)

1. **Printer Setup UI**
   - Printer discovery screen with scan button
   - Add printer form (name, type, connection details, paper size)
   - Printer list with edit/delete/test options
   - Settings screen integration

2. **Network Printer Discovery**
   - mDNS/Bonjour discovery for network printers
   - IP range scanning (e.g., 192.168.1.1-254)
   - Port availability checking

3. **Enhanced Error Handling**
   - Paper-out detection (if supported by printer)
   - Connection retry logic
   - Print queue for offline scenarios
   - Detailed error messages for users

4. **Receipt Printing**
   - Customer receipt generation (sales receipts, order confirmations)
   - PDF receipt backup (already have `pdf` + `printing` packages)
   - Email receipt option

5. **Testing**
   - Test on physical Android device with Bluetooth printer
   - Test USB printing with OTG cable
   - Test 58mm vs 80mm paper formatting
   - Test Sunmi device integration (if available)

## 📦 Packages Used

| Package | Version | Purpose |
|---------|---------|---------|
| `blue_thermal_printer` | ^1.2.3 | Bluetooth classic thermal printers |
| `usb_serial` | ^0.5.2 | USB OTG serial communication |
| `permission_handler` | ^11.4.0 | Runtime permissions (Android 6+) |
| `sunmi_printer_plus` | ^2.1.3 | Sunmi device built-in printer |
| `esc_pos_utils_plus` | ^2.0.4 | ESC/POS command generation (existing) |

## 🔗 Related Files

- [Printer Model](lib/models/printer.dart) - Isar database schema
- [Printer Adapters](lib/printing/printer_adapter.dart) - Connection implementations
- [Discovery Service](lib/services/printer_discovery_service.dart) - Device scanning
- [Kitchen Ticket Service](lib/printing/kitchen_ticket_service.dart) - Ticket formatting
- [Android Manifest](android/app/src/main/AndroidManifest.xml) - Permissions & USB filters
- [USB Device Filter](android/app/src/main/res/xml/usb_device_filter.xml) - Vendor IDs

---

**Status**: ✅ Core implementation complete. Ready for UI development and physical hardware testing.
