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

- App scaffold with mode selection (Retail, Cafe, Restaurant)
- Global Training toggle and banner indicator
- Placeholder POS screens per mode
- Printer abstraction and basic ESC/POS kitchen ticket builder

## Roadmap

- Local storage (Isar/Drift) with training vs production isolation
- Kitchen printer configuration UI and LAN printing (TCP 9100)
- Transaction engine (orders, payments, taxes, discounts)
- Mode-specific UX (modifiers, tables, quick checkout)

## Printing Notes

- Kitchen printers over LAN are preferred (ESC/POS via TCP port 9100)
- Bluetooth/USB support may require vendor SDKs and will be scoped later

## Structure

- `lib/main.dart`: App entry, routing, and screens
- `lib/printing/printer_adapter.dart`: Printer interface + LAN ESC/POS adapter
- `lib/printing/kitchen_ticket_service.dart`: Build and print simple kitchen tickets

