import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class CashPaymentDialog extends StatefulWidget {
  final double totalAmount;
  final Function(double tenderedAmount) onConfirm;

  const CashPaymentDialog({
    super.key,
    required this.totalAmount,
    required this.onConfirm,
  });

  @override
  State<CashPaymentDialog> createState() => _CashPaymentDialogState();
}

class _CashPaymentDialogState extends State<CashPaymentDialog> {
  double _tenderedAmount = 0.0;
  final _currencyFormat = NumberFormat.currency(symbol: '\$');

  double get _change => _tenderedAmount - widget.totalAmount;
  bool get _isValidPayment => _tenderedAmount >= widget.totalAmount;

  void _addAmount(double amount) {
    setState(() {
      _tenderedAmount += amount;
    });
  }

  void _setExactAmount() {
    setState(() {
      _tenderedAmount = widget.totalAmount;
    });
  }

  void _clear() {
    setState(() {
      _tenderedAmount = 0.0;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 500, maxHeight: 600),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Row(
                children: [
                  const Icon(Icons.payments, size: 32),
                  const SizedBox(width: 12),
                  Text(
                    'Cash Payment',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Total due
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    Text(
                      'Total Due',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: Theme.of(context).colorScheme.onPrimaryContainer,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _currencyFormat.format(widget.totalAmount),
                      style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.onPrimaryContainer,
                          ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Tendered amount display
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border.all(color: Theme.of(context).dividerColor, width: 2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    Text(
                      'Cash Tendered',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _currencyFormat.format(_tenderedAmount),
                      style: Theme.of(context).textTheme.displaySmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Change display
              if (_isValidPayment && _change > 0)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.tertiaryContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.change_circle,
                        color: Theme.of(context).colorScheme.onTertiaryContainer,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Change: ${_currencyFormat.format(_change)}',
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.onTertiaryContainer,
                            ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 24),

              // Quick amount buttons
              Wrap(
                spacing: 8,
                runSpacing: 8,
                alignment: WrapAlignment.center,
                children: [
                  _QuickAmountButton(amount: 1, onPressed: _addAmount),
                  _QuickAmountButton(amount: 5, onPressed: _addAmount),
                  _QuickAmountButton(amount: 10, onPressed: _addAmount),
                  _QuickAmountButton(amount: 20, onPressed: _addAmount),
                  _QuickAmountButton(amount: 50, onPressed: _addAmount),
                  _QuickAmountButton(amount: 100, onPressed: _addAmount),
                ],
              ),
              const SizedBox(height: 16),

              // Action buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _clear,
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: const Text('Clear'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _setExactAmount,
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: const Text('Exact Amount'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Complete payment button
              FilledButton(
                onPressed: _isValidPayment
                    ? () {
                        widget.onConfirm(_tenderedAmount);
                        Navigator.of(context).pop();
                      }
                    : null,
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: Text(
                  _isValidPayment ? 'Complete Payment' : 'Insufficient Amount',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _QuickAmountButton extends StatelessWidget {
  final double amount;
  final Function(double) onPressed;

  const _QuickAmountButton({
    required this.amount,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 80,
      height: 56,
      child: FilledButton.tonal(
        onPressed: () => onPressed(amount),
        style: FilledButton.styleFrom(
          padding: EdgeInsets.zero,
        ),
        child: Text(
          '\$${amount.toInt()}',
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
