import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../providers/cart_provider.dart';
import '../../services/order_service.dart';
import '../../repositories/repositories.dart';
import '../../main.dart';
import 'cash_payment_dialog.dart';

class PaymentBottomSheet extends ConsumerStatefulWidget {
  final String? tableName;

  const PaymentBottomSheet({
    super.key,
    this.tableName,
  });

  @override
  ConsumerState<PaymentBottomSheet> createState() => _PaymentBottomSheetState();
}

class _PaymentBottomSheetState extends ConsumerState<PaymentBottomSheet> {
  final _currencyFormat = NumberFormat.currency(symbol: '\$');
  bool _isProcessing = false;

  Future<void> _processPayment(String paymentMethod, double amountPaid) async {
    if (_isProcessing) return;

    setState(() => _isProcessing = true);

    try {
      final cart = ref.read(cartProvider);
      final orderService = ref.read(orderServiceProvider);
      final inventoryRepo = ref.read(inventoryRepositoryProvider);
      final appMode = ref.read(appModeProvider);

      // Create order and save to database
      final orderId = await orderService.createOrderFromCart(
        cart: cart,
        paymentMethod: paymentMethod,
        amountPaid: amountPaid,
        tableName: widget.tableName,
        mode: appMode,
      );

      // Decrement inventory for each cart item
      for (final item in cart.items) {
        await inventoryRepo.logMovement(
          itemId: int.tryParse(item.itemId) ?? 0,
          itemName: item.name,
          quantityChange: -item.quantity.toDouble(),
          reason: 'sale',
          notes: item.modifiers.isNotEmpty ? 'Modifiers: ${item.modifiers.join(", ")}' : null,
        );
      }

      // Clear cart
      ref.read(cartProvider.notifier).clear();

      if (mounted) {
        Navigator.of(context).pop();
        
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'Payment successful!',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text('Order #${orderId.substring(0, 8)}'),
                    ],
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
            action: SnackBarAction(
              label: 'Print',
              textColor: Colors.white,
              onPressed: () {
                // TODO: Print receipt
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Receipt printing not yet implemented')),
                );
              },
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Payment failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  void _handleCashPayment() async {
    final cart = ref.read(cartProvider);
    
    await showDialog(
      context: context,
      builder: (context) => CashPaymentDialog(
        totalAmount: cart.total,
        onConfirm: (tenderedAmount) {
          _processPayment('Cash', tenderedAmount);
        },
      ),
    );
  }

  void _handleCardPayment() {
    final cart = ref.read(cartProvider);
    _processPayment('Card', cart.total);
  }

  void _handleSplitPayment() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Split payment not yet implemented')),
    );
    // TODO: Implement split payment dialog
  }

  @override
  Widget build(BuildContext context) {
    final cart = ref.watch(cartProvider);

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Handle bar
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Header
          Row(
            children: [
              const Icon(Icons.payment, size: 32),
              const SizedBox(width: 12),
              Text(
                'Select Payment Method',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Order summary
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                _SummaryRow('Subtotal', cart.subtotal),
                _SummaryRow('Tax', cart.tax),
                if (cart.discount > 0) _SummaryRow('Discount', -cart.discount),
                const Divider(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Total',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    Text(
                      _currencyFormat.format(cart.total),
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Payment method buttons
          _PaymentMethodButton(
            icon: Icons.money,
            label: 'Cash',
            color: Colors.green,
            onPressed: _isProcessing ? null : _handleCashPayment,
          ),
          const SizedBox(height: 12),
          _PaymentMethodButton(
            icon: Icons.credit_card,
            label: 'Card',
            color: Colors.blue,
            onPressed: _isProcessing ? null : _handleCardPayment,
          ),
          const SizedBox(height: 12),
          _PaymentMethodButton(
            icon: Icons.call_split,
            label: 'Split Payment',
            color: Colors.orange,
            onPressed: _isProcessing ? null : _handleSplitPayment,
          ),
          const SizedBox(height: 24),

          // Cancel button
          OutlinedButton(
            onPressed: _isProcessing ? null : () => Navigator.of(context).pop(),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final double amount;

  const _SummaryRow(this.label, this.amount);

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(symbol: '\$');
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(
            currencyFormat.format(amount),
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }
}

class _PaymentMethodButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback? onPressed;

  const _PaymentMethodButton({
    required this.icon,
    required this.label,
    required this.color,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 80,
      child: FilledButton(
        onPressed: onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 32),
            const SizedBox(width: 16),
            Text(
              label,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}
