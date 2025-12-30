import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../models/item.dart';
import '../../models/category.dart';
import '../../repositories/repositories.dart';
import '../../widgets/shared/cart_panel.dart';
import '../../widgets/shared/category_tabs.dart';
import '../../widgets/shared/product_card.dart';
import '../../widgets/shared/training_banner.dart';
import '../../providers/cart_provider.dart';

class RetailPosScreen extends ConsumerStatefulWidget {
  const RetailPosScreen({super.key});

  @override
  ConsumerState<RetailPosScreen> createState() => _RetailPosScreenState();
}

class _RetailPosScreenState extends ConsumerState<RetailPosScreen> {
  late TextEditingController _searchController;
  int _selectedCategory = 0;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _addToCart(Item item) {
    ref.read(cartProvider.notifier).addItem(
      itemId: item.id.toString(),
      name: item.name,
      price: item.price,
    );
  }

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(retailCategoriesProvider);
    final itemsAsync = ref.watch(retailItemsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            Text('QuickQash Retail'),
            SizedBox(width: 12),
            TrainingBadge(),
          ],
        ),
        leading: const BackButton(),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => context.push('/settings'),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          const TrainingBanner(),
          // Search bar
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              border: Border(
                bottom: BorderSide(color: Theme.of(context).dividerColor),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search products or scan barcode...',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.qr_code_scanner),
                        onPressed: () {
                          // TODO: Barcode scanner
                        },
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                    ),
                    onChanged: (_) => setState(() {}),
                    onSubmitted: (barcode) async {
                      if (barcode.trim().isEmpty) return;
                      final messenger = ScaffoldMessenger.of(context);
                      final itemRepo = ref.read(itemRepositoryProvider);
                      final found = await itemRepo.getByBarcode(barcode.trim());
                      if (found != null) {
                        _addToCart(found);
                        messenger.showSnackBar(
                          SnackBar(content: Text('Added ${found.name}')),
                        );
                        _searchController.clear();
                        setState(() {});
                      } else {
                        messenger.showSnackBar(
                          const SnackBar(content: Text('Item not found for barcode')),
                        );
                      }
                    },
                  ),
                ),
              ],
            ),
          ),
          // Category tabs
          categoriesAsync.when(
            data: (categories) {
              final categoryNames = categories.map((c) => c.name).toList();
              return CategoryTabs(
                categories: categoryNames,
                selectedIndex: _selectedCategory,
                onCategoryChanged: (index) {
                  setState(() {
                    _selectedCategory = index;
                  });
                },
              );
            },
            loading: () => const SizedBox(
              height: 50,
              child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
            ),
            error: (error, stack) => const SizedBox(
              height: 50,
              child: Center(child: Text('Error loading categories')),
            ),
          ),
          // Products grid
          Expanded(
            child: itemsAsync.when(
              data: (items) {
                if (items.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.inventory_2_outlined,
                          size: 64,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(height: 16),
                        const Text('No products available'),
                      ],
                    ),
                  );
                }

                // Filter items by active, category selection, and search query
                var filtered = items.where((i) => i.isActive).toList();
                final names = categoriesAsync.asData?.value.map((c) => c.name).toList() ?? const <String>[];
                if (names.isNotEmpty && _selectedCategory >= 0 && _selectedCategory < names.length) {
                  final selectedName = names[_selectedCategory];
                  filtered = filtered.where((i) => (i.category ?? '') == selectedName).toList();
                }
                final q = _searchController.text.trim().toLowerCase();
                if (q.isNotEmpty) {
                  filtered = filtered.where((i) => i.name.toLowerCase().contains(q) || (i.barcode?.toLowerCase().contains(q) ?? false)).toList();
                }

                return GridView.builder(
                  padding: const EdgeInsets.all(8),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    mainAxisSpacing: 8,
                    crossAxisSpacing: 8,
                    childAspectRatio: 0.75,
                  ),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final item = filtered[index];
                    return ProductCard(
                      name: item.name,
                      price: item.price,
                      onTap: () => _addToCart(item),
                    );
                  },
                );
              },
              loading: () => const Center(
                child: CircularProgressIndicator(),
              ),
              error: (error, stack) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, size: 64),
                    const SizedBox(height: 16),
                    Text('Error loading products: $error'),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: Consumer(
        builder: (context, ref, child) {
          final cart = ref.watch(cartProvider);
          return CartPanel(
            checkoutLabel: 'Charge \$${cart.total.toStringAsFixed(2)}',
          );
        },
      ),
    );
  }
}

// Stream providers for Retail POS data
final retailCategoriesProvider = StreamProvider<List<Category>>((ref) {
  final repo = ref.watch(categoryRepositoryProvider);
  return repo.watchAll();
});

final retailItemsProvider = StreamProvider<List<Item>>((ref) {
  final repo = ref.watch(itemRepositoryProvider);
  return repo.watchAll();
});
