import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../repositories/repositories.dart';

// Family providers for date-range based queries
final inventoryLogsProvider = FutureProvider.family<List<dynamic>, (DateTime, DateTime)>((ref, dates) async {
  final repo = ref.watch(inventoryRepositoryProvider);
  return repo.getLogsByDateRange(dates.$1, dates.$2);
});

final inventorySummaryProvider = FutureProvider.family<Map<String, double>, (DateTime, DateTime)>((ref, dates) async {
  final repo = ref.watch(inventoryRepositoryProvider);
  return repo.getMovementSummaryByReason(dates.$1, dates.$2);
});

class InventoryHistoryScreen extends ConsumerStatefulWidget {
  final int itemId;
  final String itemName;

  const InventoryHistoryScreen({
    required this.itemId,
    required this.itemName,
    super.key,
  });

  @override
  ConsumerState<InventoryHistoryScreen> createState() => InventoryHistoryScreenState();
}

class InventoryHistoryScreenState extends ConsumerState<InventoryHistoryScreen> {
  late DateTimeRange _dateRange;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _dateRange = DateTimeRange(
      start: now.subtract(const Duration(days: 30)),
      end: now,
    );
  }

  @override
  Widget build(BuildContext context) {
    return _buildContent(context);
  }

  Widget _buildContent(BuildContext context) {
    final logsAsync = ref.watch(
      inventoryLogsProvider((_dateRange.start, _dateRange.end)),
    );

    final summaryAsync = ref.watch(
      inventorySummaryProvider((_dateRange.start, _dateRange.end)),
    );

    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.itemName} - Inventory History'),
        leading: const BackButton(),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Date range picker
            Card(
              margin: const EdgeInsets.all(12),
              child: ListTile(
                title: const Text('Date Range'),
                subtitle: Text(
                  '${DateFormat('MMM d, y').format(_dateRange.start)} - ${DateFormat('MMM d, y').format(_dateRange.end)}',
                ),
                trailing: const Icon(Icons.calendar_today),
                onTap: () async {
                  final picked = await showDateRangePicker(
                    context: context,
                    firstDate: DateTime(2020),
                    lastDate: DateTime.now(),
                    initialDateRange: _dateRange,
                  );
                  if (picked != null) {
                    setState(() => _dateRange = picked);
                  }
                },
              ),
            ),
            // Summary
            summaryAsync.when(
              data: (summary) => _buildSummary(context, summary),
              loading: () => const SizedBox.shrink(),
              // ignore: unnecessary_underscores
              error: (_, __) => const SizedBox.shrink(),
            ),
            // Logs
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Movement History',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
            ),
            logsAsync.when(
              data: (logs) {
                if (logs.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.all(24),
                    child: Center(
                      child: Text(
                        'No movements in this period',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                      ),
                    ),
                  );
                }
                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  itemCount: logs.length,
                  itemBuilder: (context, index) {
                    final log = logs[index];
                    return _buildLogItem(context, log);
                  },
                );
              },
              loading: () => const Padding(
                padding: EdgeInsets.all(24),
                child: CircularProgressIndicator(),
              ),
              error: (e, s) => Padding(
                padding: const EdgeInsets.all(24),
                child: Text('Error: $e'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummary(BuildContext context, Map<String, double> summary) {
    if (summary.isEmpty) {
      return const SizedBox.shrink();
    }

    final colors = {
      'sale': Colors.red,
      'restock': Colors.green,
      'adjustment': Colors.blue,
      'damage': Colors.orange,
      'loss': Colors.grey,
    };

    return Padding(
      padding: const EdgeInsets.all(12),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Summary',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 8),
              ...summary.entries.map((e) {
                final isNegative = e.value < 0;
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: colors[e.key] ?? Colors.grey,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(e.key),
                      ),
                      Text(
                        '${isNegative ? '' : '+'}${e.value.toStringAsFixed(2)}',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: isNegative ? Colors.red : Colors.green,
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLogItem(BuildContext context, dynamic log) {
    final isIncrease = log.quantityChange >= 0;
    final reasonColors = {
      'sale': Colors.red,
      'restock': Colors.green,
      'adjustment': Colors.blue,
      'damage': Colors.orange,
      'loss': Colors.grey,
    };
    final color = reasonColors[log.reason] ?? Colors.grey;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(
          isIncrease ? Icons.arrow_upward : Icons.arrow_downward,
          color: isIncrease ? Colors.green : Colors.red,
        ),
        title: Text(log.reason),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(DateFormat('MMM d, y HH:mm').format(log.timestamp)),
            if (log.notes != null && log.notes!.isNotEmpty)
              Text(log.notes!, style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
        trailing: Text(
          '${isIncrease ? '+' : ''}${log.quantityChange.toStringAsFixed(2)}',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                color: color,
                fontWeight: FontWeight.bold,
              ),
        ),
      ),
    );
  }
}
