import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../providers/cart_provider.dart';
import 'payment_bottom_sheet.dart';

class CartPanel extends ConsumerWidget {
  final String? tableName;
  final String checkoutLabel;

  const CartPanel({
    super.key,
    this.tableName,
    this.checkoutLabel = 'Checkout',
  });

  void _showPaymentSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => PaymentBottomSheet(tableName: tableName),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cart = ref.watch(cartProvider);
    final cartNotifier = ref.read(cartProvider.notifier);
    final currencyFormatter = NumberFormat.currency(symbol: '\$');

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          left: BorderSide(color: Theme.of(context).dividerColor),
        ),
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(color: Theme.of(context).dividerColor),
              ),
            ),
            child: Row(
              children: [
                Text(
                  'Cart',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(width: 8),
                if (cart.items.isNotEmpty)
                  CircleAvatar(
                    radius: 12,
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    child: Text(
                      '${cart.items.length}',
                      style: const TextStyle(fontSize: 12, color: Colors.white),
                    ),
                  ),
                const Spacer(),
                if (cart.items.isNotEmpty)
                  TextButton(
                    onPressed: () => cartNotifier.clear(),
                    child: const Text('Clear'),
                  ),
              ],
            ),
          ),

          // Items list
          Expanded(
            child: cart.items.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.shopping_cart_outlined,
                          size: 64,
                          color: Theme.of(context).disabledColor,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Cart is empty',
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                color: Theme.of(context).disabledColor,
                              ),
                        ),
                      ],
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.all(8),
                    itemCount: cart.items.length,
                    separatorBuilder: (_, index) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final item = cart.items[index];
                      return CartItemTile(
                        item: item,
                        onQuantityChanged: (newQty) {
                          cartNotifier.updateQuantity(item.id, newQty);
                        },
                        onRemove: () {
                          cartNotifier.removeItem(item.id);
                        },
                      );
                    },
                  ),
          ),

          // Summary section
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              border: Border(
                top: BorderSide(color: Theme.of(context).dividerColor),
              ),
            ),
            child: Column(
              children: [
                _SummaryRow(
                  label: 'Subtotal',
                  value: currencyFormatter.format(cart.subtotal),
                ),
                const SizedBox(height: 8),
                _SummaryRow(
                  label: 'Tax',
                  value: currencyFormatter.format(cart.tax),
                ),
                if (cart.discount > 0) ...[
                  const SizedBox(height: 8),
                  _SummaryRow(
                    label: 'Discount',
                    value: '-${currencyFormatter.format(cart.discount)}',
                    valueColor: Colors.green,
                  ),
                ],
                const Divider(height: 24),
                _SummaryRow(
                  label: 'TOTAL',
                  value: currencyFormatter.format(cart.total),
                  labelStyle: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                  valueStyle: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: FilledButton(
                    onPressed: cart.items.isEmpty ? null : () => _showPaymentSheet(context),
                    child: Text(
                      checkoutLabel,
                      style: const TextStyle(fontSize: 18),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;
  final TextStyle? labelStyle;
  final TextStyle? valueStyle;
  final Color? valueColor;

  const _SummaryRow({
    required this.label,
    required this.value,
    this.labelStyle,
    this.valueStyle,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: labelStyle ?? Theme.of(context).textTheme.bodyLarge,
        ),
        Text(
          value,
          style: (valueStyle ?? Theme.of(context).textTheme.bodyLarge)
              ?.copyWith(color: valueColor),
        ),
      ],
    );
  }
}

class CartItemTile extends StatelessWidget {
  final CartItem item;
  final ValueChanged<int>? onQuantityChanged;
  final VoidCallback? onRemove;

  const CartItemTile({
    super.key,
    required this.item,
    this.onQuantityChanged,
    this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final currencyFormatter = NumberFormat.currency(symbol: '\$');

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Thumbnail
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.shopping_bag_outlined,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          const SizedBox(width: 12),

          // Item details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  style: Theme.of(context).textTheme.bodyLarge,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                if (item.modifiers.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    item.modifiers.join(', '),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                const SizedBox(height: 8),
                // Quantity controls
                Row(
                  children: [
                    IconButton.outlined(
                      onPressed: item.quantity > 1
                          ? () => onQuantityChanged?.call(item.quantity - 1)
                          : onRemove,
                      icon: Icon(
                        item.quantity > 1 ? Icons.remove : Icons.delete_outline,
                        size: 20,
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 36,
                        minHeight: 36,
                      ),
                      padding: EdgeInsets.zero,
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Text(
                        '${item.quantity}',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                    IconButton.outlined(
                      onPressed: () => onQuantityChanged?.call(item.quantity + 1),
                      icon: const Icon(Icons.add, size: 20),
                      constraints: const BoxConstraints(
                        minWidth: 36,
                        minHeight: 36,
                      ),
                      padding: EdgeInsets.zero,
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Price
          const SizedBox(width: 8),
          Text(
            currencyFormatter.format(item.price * item.quantity),
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
        ],
      ),
    );
  }
}
