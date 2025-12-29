# QuickQash POS - GitHub Copilot Instructions

## Project Overview
QuickQash is an **offline-only POS system** for single-branch operations with **no cloud backend**. It supports three distinct modes: Retail POS, Cafe POS, and Restaurant POS. The app includes a Training Mode to isolate practice data from production data.

## Core Requirements
- ✅ **Offline-only**: No backend, no cloud sync
- ✅ **Single-branch**: No multi-location support
- ✅ **Three modes**: Retail, Cafe, Restaurant (different UX per mode)
- ✅ **Kitchen printing**: ESC/POS thermal printers (LAN preferred), NO KDS
- ✅ **Training mode**: Separate datastore for training vs production

## Architecture

### State Management & Routing
- **State**: `flutter_riverpod` (use `StateProvider`, `Provider`, `StateNotifierProvider`)
- **Routing**: `go_router` with named routes
- **Training mode**: Global `trainingModeProvider` controls data isolation
- **App mode**: `appModeProvider` tracks current POS mode (retail/cafe/restaurant)

### Storage
- **Database**: Isar for offline-first local storage
- **Training isolation**: Separate database instances
  - Production: `quickqash.isar`
  - Training: `quickqash_training.isar`
- **Repository pattern**: Abstract data access via `ItemRepository`, `OrderRepository`
- **Training mode selection**: Inject training vs production Isar instance based on `trainingModeProvider`

### Printing (Android Implemented)
- **Abstraction**: `PrinterAdapter` interface for all connection types
- **Network printers**: `EscPosNetworkPrinter` (TCP port 9100) - Windows/Android/iOS
- **Bluetooth printers**: `EscPosBluetoothPrinter` (blue_thermal_printer) - Android only
- **USB printers**: `EscPosUsbPrinter` (usb_serial) - Android only
- **Sunmi built-in**: `SunmiBuiltInPrinter` (sunmi_printer_plus) - Sunmi devices
- **ESC/POS commands**: `esc_pos_utils_plus` for ticket formatting
- **Kitchen tickets**: `KitchenTicketService` builds formatted tickets (80mm/58mm paper)
- **Printer discovery**: `PrinterDiscoveryService` for Bluetooth/USB device scanning
- **Printer management**: Settings UI for add/edit/test/delete printers
- **Receipt printing**: PDF via `printing` package (planned)

### Domain Models (Isar Collections)
```dart
✅ Item (id, name, price, category, kitchenRoute)
✅ Order (id, items, total, tax, discount, timestamp, mode)
✅ OrderItem (itemId, quantity, modifiers, price, kitchenRoute, notes)
✅ Payment (orderId, method, amount, timestamp)
✅ Printer (id, name, connectionType, host?, port?, bluetoothAddress?, bluetoothName?, 
          usbVendorId?, usbProductId?, paperSize, type, isActive)
⚠️  Category (id, name, icon) - Planned
⚠️  KitchenRoute (id, name, printerId) - Planned
⚠️  ShiftSession (id, startTime, endTime, userId, totalSales) - Planned
⚠️  Tax (id, name, rate) - Planned
⚠️  Discount (id, name, type, value) - Planned
```

## Code Conventions

### File Organization
```
lib/
  main.dart                          # App entry, routing, mode screens
  models/                            # Isar domain entities
    item.dart
    order.dart
    order_item.dart
    payment.dart
    printer.dart
  services/                          # Business logic
    order_service.dart               # Order creation/retrieval
    printer_discovery_service.dart   # Bluetooth/USB printer scanning
  repositories/                      # Data access layer
    isar_provider.dart               # Isar instances (prod/training)
    repositories.dart                # ItemRepository, OrderRepository
  printing/
    printer_adapter.dart             # PrinterAdapter interface + 4 implementations
    kitchen_ticket_service.dart      # ESC/POS ticket formatting
  providers/
    cart_provider.dart               # Cart state management
  screens/
    retail/                          # Retail mode UI
      retail_pos_screen.dart
    cafe/                            # Cafe mode UI
      cafe_pos_screen.dart
    restaurant/                      # Restaurant mode UI
      restaurant_pos_screen.dart
    settings/                        # Settings screens
      printer_list_screen.dart       # Printer management
      printer_discovery_screen.dart  # Scan for printers
      printer_form_screen.dart       # Add/edit printer config
  widgets/
    shared/                          # Reusable widgets
      cart_panel.dart
      category_tabs.dart
      modifier_bottom_sheet.dart
      payment_bottom_sheet.dart
      product_card.dart
      training_banner.dart
```

### Naming Conventions
- **Files**: `snake_case.dart`
- **Classes**: `PascalCase`
- **Variables/functions**: `camelCase`
- **Providers**: `camelCaseProvider` (e.g., `cartProvider`, `orderServiceProvider`)
- **Private**: Prefix with `_` (e.g., `_buildCartItem`)

### Riverpod Patterns
```dart
// State
final trainingModeProvider = StateProvider<bool>((ref) => false);

// Service provider
final orderServiceProvider = Provider<OrderService>((ref) {
  final training = ref.watch(trainingModeProvider);
  final repo = training ? ref.read(trainingOrderRepoProvider) : ref.read(orderRepoProvider);
  return OrderService(repo);
});

// StateNotifier for complex state
final cartProvider = StateNotifierProvider<CartNotifier, Cart>((ref) {
  return CartNotifier();
});
```

### Training Mode Isolation
- **Always check**: `ref.watch(trainingModeProvider)` before data operations
- **Repository selection**: Inject training-specific repos when training mode is active
- **UI indicators**: Show "TRAINING" banner and badge consistently
- **Clear separation**: No mixing of training and production data

## Mode-Specific Behaviors

### Retail POS
- Fast item scanning/selection (barcode or search)
- Cart-centric checkout
- Quick payment methods (cash, card)
- Simple receipt printing
- No kitchen routing (customer takes items immediately)

### Cafe POS
- Category-based menu grid
- Quick modifiers (size, milk, extras)
- Order-at-counter workflow
- Kitchen ticket printing for barista/prep area
- Basic routing (e.g., "Bar" for drinks, "Kitchen" for food)

### Restaurant POS
- Table management (select table → create order)
- Seat assignment (optional)
- Course/fire control (send items to kitchen in stages)
- Kitchen routing by item category (e.g., "Grill", "Fryer", "Salad")
- Split bills, void items
- Order modifications and special requests

## Platform Considerations

### Windows (Primary Target)
- Desar`: Offline-first NoSQL database
- `isar_flutter_libs`: Platform-specific Isar binaries
- `intl`: Currency and date formatting
- `uuid`: Unique IDs for orders/items
- `path_provider`: App directory paths
- `esc_pos_utils_plus`: ESC/POS command generation
- `blue_thermal_printer`: Bluetooth Classic thermal printers (Android)
- `usb_serial`: USB OTG serial communication (Android)
- `permission_handler`: Runtime permissions (Bluetooth/Location/USB)
- `sunmi_printer_plus`: Sunmi built-in printer integration
- `pdf`: Receipt PDF generation (planned)
- `printing`: OS print dialogs (planned)
- `network_info_plus`: Network discovery (planned)

**Dev Dependencies:**
- `build_runner`: Code generation for Isar
- `isar_generator`: Isar schema generation if needed)
- Tablet/phone layouts

### iOS
- MFi/vendor SDKs required for Bluetooth ESC/POS
- Prefer LAN printers or AirPrint for receipts
- Restricted Bluetooth access

### Web
- Network printers only (no USB/BLE raw access)
- PDF printing via browser

## Dependencies
- `flutter_riverpod`: State management
- `go_router`: Declarative routing
- `intl`: Currency and date formatting
- `uuid`: Unique IDs for orders/items
- `esc_pos_utils_plus`: ESC/POS ticket builder
- `pdf`: Receipt PDF generation
- `printing`: OS print dialogs
- `network_info_plus`: Network discovery helpers
- **Future**: `isar` or `drift` for storage
 (Isar entities are mutable by design)
- Handle errors gracefully (offline = no network fallbacks)
- Avoid `print()` in production code; use `debugPrint()` or remove entirely
- Keep UI responsive; async operations should show loading states
- Format currency with `intl` NumberFormat
- Validate inputs (prices, quantities, payment amounts)
- Guard against negative totals or invalid states
- Always check `ref.watch(trainingModeProvider)` before data operations
- Use `StreamProvider` with Isar `watchLazy()` for reactive UI updates
- Run `dart run build_runner build --delete-conflicting-outputs` after model changtion

## Best Practices
- Use `const` constructors wherever possible
- Prefer immutable data models
- Handle errors gracefully (offline = no network fallbacks)
- Log printer errors; don't crash on print failures
- Keep UI responsive; async operations should show loading states
- Format currency with `intl` NumberFormat
- VImplemented Features ✅
- Three POS modes (Retail, Cafe, Restaurant) with mode-specific UX
- Training mode with isolated data storage
- Cart management with modifiers (single/multi-choice, extras)
- Payment flow with cash/card/split tender
- Android thermal printer support (Network, Bluetooth, USB, Sunmi)
- Printer discovery and configuration UI
- Kitchen ticket generation with 80mm/58mm paper support
- Isar database with production/training isolation
- Repository pattern for data access
- Riverpod state management throughout

## Future Enhancements (Out of Scope Now)
- Network printer auto-discovery (mDNS/Bonjour, IP scanning)
- Receipt printing service (customer copies)
- Enhanced printer error handling (paper-out detection, retry queueayment amounts)
- Guard against negative totals or invalid states

## Future Enhancements (Out of Scope Now)
- Multi-branch sync (cloud backend)
- KDS (Kitchen Display System)
- Inventory management and low-stock alerts
- Employee time tracking
- Advanced reporting and analytics
- Customer loyalty programs
- Online ordering integration
