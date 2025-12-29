import 'dart:typed_data';
import 'package:esc_pos_utils_plus/esc_pos_utils_plus.dart';
import 'printer_adapter.dart';

class KitchenTicketService {
  /// Get paper size enum from string ('80mm' or '58mm')
  PaperSize _getPaperSize(String paperSizeStr) {
    return paperSizeStr == '58mm' ? PaperSize.mm58 : PaperSize.mm80;
  }

  /// Build a simple kitchen ticket with dynamic paper size
  Future<Uint8List> buildSimpleTicket(
    List<String> lines, {
    String paperSize = '80mm',
  }) async {
    final profile = await CapabilityProfile.load();
    final generator = Generator(_getPaperSize(paperSize), profile);

    final bytes = <int>[];
    bytes.addAll(generator.text(
      'KITCHEN TICKET',
      styles: const PosStyles(bold: true),
      linesAfter: 1,
    ));
    bytes.addAll(generator.hr());
    for (final line in lines) {
      bytes.addAll(generator.text(line));
    }
    bytes.addAll(generator.hr());
    bytes.addAll(generator.cut());

    return Uint8List.fromList(bytes);
  }

  /// Build a formatted kitchen ticket with order details
  Future<Uint8List> buildKitchenTicket({
    required String orderNumber,
    required String tableName,
    required List<Map<String, dynamic>> items,
    String? notes,
    String paperSize = '80mm',
  }) async {
    final profile = await CapabilityProfile.load();
    final generator = Generator(_getPaperSize(paperSize), profile);

    final bytes = <int>[];

    // Header
    bytes.addAll(generator.text(
      'KITCHEN ORDER',
      styles: const PosStyles(
        bold: true,
        align: PosAlign.center,
        height: PosTextSize.size2,
        width: PosTextSize.size2,
      ),
      linesAfter: 1,
    ));

    // Order info
    bytes.addAll(generator.text(
      'Order #$orderNumber',
      styles: const PosStyles(bold: true, align: PosAlign.center),
    ));
    bytes.addAll(generator.text(
      tableName,
      styles: const PosStyles(bold: true, align: PosAlign.center),
      linesAfter: 1,
    ));

    bytes.addAll(generator.hr());

    // Items
    for (final item in items) {
      final qty = item['quantity'] ?? 1;
      final name = item['name'] ?? '';
      final modifiers = item['modifiers'] as List<String>? ?? [];
      final itemNotes = item['notes'] as String?;

      // Item name with quantity
      bytes.addAll(generator.text(
        '$qty× $name',
        styles: const PosStyles(bold: true, height: PosTextSize.size2),
      ));

      // Modifiers
      for (final modifier in modifiers) {
        bytes.addAll(generator.text(
          '  • $modifier',
          styles: const PosStyles(),
        ));
      }

      // Item notes
      if (itemNotes != null && itemNotes.isNotEmpty) {
        bytes.addAll(generator.text(
          '  NOTE: $itemNotes',
          styles: const PosStyles(),
        ));
      }

      bytes.addAll(generator.emptyLines(1));
    }

    // Order notes
    if (notes != null && notes.isNotEmpty) {
      bytes.addAll(generator.hr());
      bytes.addAll(generator.text(
        'NOTES: $notes',
        styles: const PosStyles(bold: true),
      ));
    }

    // Footer
    bytes.addAll(generator.hr());
    final now = DateTime.now();
    bytes.addAll(generator.text(
      '${now.hour}:${now.minute.toString().padLeft(2, '0')}',
      styles: const PosStyles(align: PosAlign.center),
      linesAfter: 2,
    ));

    bytes.addAll(generator.cut());

    return Uint8List.fromList(bytes);
  }

  /// Print a simple kitchen ticket
  Future<void> printKitchenTicket(
    PrinterAdapter adapter,
    List<String> lines, {
    String paperSize = '80mm',
  }) async {
    final data = await buildSimpleTicket(lines, paperSize: paperSize);
    await adapter.printBytes(data);
  }

  /// Print a formatted kitchen ticket with order details
  Future<void> printFormattedKitchenTicket({
    required PrinterAdapter adapter,
    required String orderNumber,
    required String tableName,
    required List<Map<String, dynamic>> items,
    String? notes,
    String paperSize = '80mm',
  }) async {
    final data = await buildKitchenTicket(
      orderNumber: orderNumber,
      tableName: tableName,
      items: items,
      notes: notes,
      paperSize: paperSize,
    );
    await adapter.printBytes(data);
  }
}
