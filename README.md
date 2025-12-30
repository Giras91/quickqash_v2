# QuickQash — Offline POS

QuickQash is an offline-only POS prototype with three modes:
- Retail POS
- Cafe POS
- Restaurant POS

It supports simple transactions for a single branch and kitchen printer ticketing (no KDS). A Training mode isolates practice data from real data.

## Getting Started

1. Enable Flutter desktop (optional) and Windows Developer Mode (for plugins requiring symlinks):

```powershell
start ms-settings:developers
```

2. Fetch dependencies:

```powershell
flutter pub get
```

3. Run the app (Windows desktop shown; use your target as needed):

```powershell
flutter run -d windows
```

## Current Status

✅ **Completed:**
- Three POS modes (Retail, Cafe, Restaurant) with mode-specific UX
- Isar database with training vs production isolation
- Product management (add/edit/delete) with categories
- Barcode scanning and search across all modes
- Shopping cart with modifiers and quick checkout
- Payment processing (Cash/Card) with order history
- Kitchen printer support (Network, Bluetooth, USB, Sunmi)
- Printer discovery and configuration UI
- Kitchen ticket generation (ESC/POS, 80mm/58mm paper)
- Daily/Weekly/Monthly sales reports by POS mode
- **Inventory tracking** with real-time stock levels, low-stock alerts, and complete audit trail
- Automatic inventory decrement on checkout
- Training mode banner and data isolation

⏭️ **Next Phase:**
- Multi-unit conversions (boxes → pieces)
- Supplier management and purchase orders
- Inventory forecasting and trend analysis
- Advanced reorder automation

## Documentation

- **[INVENTORY_IMPLEMENTATION.md](INVENTORY_IMPLEMENTATION.md)** - Complete inventory system overview
- **[INVENTORY_TESTING.md](INVENTORY_TESTING.md)** - Comprehensive testing guide with 50+ test cases

## Printing Notes

- Kitchen printers over LAN are preferred (ESC/POS via TCP port 9100)
- Bluetooth/USB support may require vendor SDKs and will be scoped later

## Structure

- `lib/main.dart`: App entry, routing, and screens
- `lib/printing/printer_adapter.dart`: Printer interface + LAN ESC/POS adapter
- `lib/printing/kitchen_ticket_service.dart`: Build and print simple kitchen tickets

