import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../widgets/shared/cart_panel.dart';
import '../../widgets/shared/category_tabs.dart';
import '../../widgets/shared/product_card.dart';
import '../../widgets/shared/training_banner.dart';
import '../../widgets/shared/modifier_bottom_sheet.dart';
import '../../providers/cart_provider.dart';
import '../../models/item.dart';
import '../../models/category.dart';
import '../../repositories/repositories.dart';

class CafePosScreen extends ConsumerStatefulWidget {
  const CafePosScreen({super.key});

  @override
  ConsumerState<CafePosScreen> createState() => _CafePosScreenState();
}

class _CafePosScreenState extends ConsumerState<CafePosScreen> {
  late TextEditingController _searchController;
  int _selectedCategory = 0;

  void _addToOrder(Item item) {
    ref.read(cartProvider.notifier).addItem(
      itemId: item.id.toString(),
      name: item.name,
      price: item.price,
      kitchenRoute: item.kitchenRoute,
    );
  }

  void _showModifierSheet(Item item) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ModifierBottomSheet(
        itemName: item.name,
        basePrice: item.price,
        modifierGroups: _getModifiersForItem(item),
        onConfirm: (modifiers, notes) {
          ref.read(cartProvider.notifier).addItem(
            itemId: item.id.toString(),
            name: item.name,
            price: item.price,
            modifiers: modifiers,
            kitchenRoute: item.kitchenRoute,
            notes: notes,
          );
        },
      ),
    );
  }

  List<ModifierGroup> _getModifiersForItem(Item item) {
    // Return different modifiers based on category
    // Treat beverages (category name contains 'Brew', 'Espresso', 'Drink') as drinks
    final catName = item.category?.toLowerCase() ?? '';
    final isDrink = catName.contains('brew') || catName.contains('espresso') || catName.contains('drink');
    if (isDrink) {
      // Drinks: Espresso, Brewed, Cold Drinks
      return [
        ModifierGroup(
          name: 'Size',
          type: ModifierType.single,
          required: true,
          options: [
            ModifierOption(name: 'Small'),
            ModifierOption(name: 'Medium', extraCost: 0.50),
            ModifierOption(name: 'Large', extraCost: 1.00),
          ],
        ),
        ModifierGroup(
          name: 'Milk',
          subtitle: 'Select one',
          type: ModifierType.single,
          options: [
            ModifierOption(name: 'Whole Milk'),
            ModifierOption(name: 'Oat Milk', extraCost: 0.75),
            ModifierOption(name: 'Almond Milk', extraCost: 0.75),
            ModifierOption(name: 'Soy Milk', extraCost: 0.75),
            ModifierOption(name: 'No Milk'),
          ],
        ),
        ModifierGroup(
          name: 'Extras',
          subtitle: 'Select any',
          type: ModifierType.multi,
          options: [
            ModifierOption(name: 'Extra Shot', extraCost: 1.00),
            ModifierOption(name: 'Whipped Cream', extraCost: 0.50),
            ModifierOption(name: 'Vanilla Syrup', extraCost: 0.50),
            ModifierOption(name: 'Caramel Syrup', extraCost: 0.50),
            ModifierOption(name: 'Less Ice'),
          ],
        ),
      ];
    } else {
      // Food items
      return [
        ModifierGroup(
          name: 'Temperature',
          type: ModifierType.single,
          options: [
            ModifierOption(name: 'Hot'),
            ModifierOption(name: 'Cold'),
          ],
        ),
        ModifierGroup(
          name: 'Add-ons',
          subtitle: 'Select any',
          type: ModifierType.multi,
          options: [
            ModifierOption(name: 'Butter', extraCost: 0.25),
            ModifierOption(name: 'Cream Cheese', extraCost: 0.75),
            ModifierOption(name: 'Extra Bacon', extraCost: 2.00),
          ],
        ),
      ];
    }
  }

  @override
  Widget build(BuildContext context) {
    // Load categories and items from repositories using StreamProviders
    final categoriesAsync = ref.watch(cafeCategoriesProvider);
    final itemsAsync = ref.watch(cafeItemsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            Text('QuickQash Cafe'),
            SizedBox(width: 12),
            TrainingBadge(),
          ],
        ),
        leading: const BackButton(),
        actions: [
          TextButton.icon(
            icon: const Icon(Icons.list_alt),
            label: const Text('0 Pending'),
            onPressed: () {
              // TODO: Show order queue
            },
          ),
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
          // Search bar for barcode/name
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
                      hintText: 'Search or scan barcode...',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                    ),
                    onChanged: (_) => setState(() {}),
                    onSubmitted: (barcode) async {
                      final messenger = ScaffoldMessenger.of(context);
                      final repo = ref.read(itemRepositoryProvider);
                      final found = await repo.getByBarcode(barcode.trim());
                      if (found != null) {
                        _addToOrder(found);
                        messenger.showSnackBar(SnackBar(content: Text('Added ${found.name}')));
                        _searchController.clear();
                        setState(() {});
                      } else {
                        messenger.showSnackBar(const SnackBar(content: Text('Item not found for barcode')));
                      }
                    },
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Row(
              children: [
                // Left: Menu (65%)
                Expanded(
                  flex: 65,
                  child: Column(
                    children: [
                      // Category tabs loaded from DB
                      categoriesAsync.when(
                        data: (categories) {
                          final names = categories.map((c) => c.name).toList();
                          return CategoryTabs(
                            categories: names,
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
                        error: (e, s) => const SizedBox(
                          height: 50,
                          child: Center(child: Text('Error loading categories')),
                        ),
                      ),
                      // Menu grid from DB
                      Expanded(
                        child: itemsAsync.when(
                          data: (items) {
                            if (items.isEmpty) {
                              return Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.local_cafe,
                                      size: 64,
                                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                                    ),
                                    const SizedBox(height: 16),
                                    const Text('No menu items'),
                                  ],
                                ),
                              );
                            }
                            // Show only active items
                            var filtered = items.where((i) => i.isActive).toList();

                            // Filter by selected category name if available
                            final categoryNames = categoriesAsync.asData?.value.map((c) => c.name).toList() ?? const <String>[];
                            if (categoryNames.isNotEmpty && _selectedCategory >= 0 && _selectedCategory < categoryNames.length) {
                              final selectedName = categoryNames[_selectedCategory];
                              filtered = filtered.where((i) => (i.category ?? '') == selectedName).toList();
                            }

                            // Search filter by name or barcode
                            final q = _searchController.text.trim().toLowerCase();
                            if (q.isNotEmpty) {
                              filtered = filtered.where((i) => i.name.toLowerCase().contains(q) || (i.barcode?.toLowerCase().contains(q) ?? false)).toList();
                            }

                            return GridView.builder(
                              padding: const EdgeInsets.all(16),
                              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 3,
                                childAspectRatio: 0.9,
                                crossAxisSpacing: 12,
                                mainAxisSpacing: 12,
                              ),
                              itemCount: filtered.length,
                              itemBuilder: (context, index) {
                                final item = filtered[index];
                                return ProductCard(
                                  name: item.name,
                                  price: item.price,
                                  onTap: () => _addToOrder(item),
                                  onLongPress: () => _showModifierSheet(item),
                                );
                              },
                            );
                          },
                          loading: () => const Center(child: CircularProgressIndicator()),
                          error: (e, s) => Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.error_outline, size: 64),
                                const SizedBox(height: 16),
                                Text('Error: $e'),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Right: Order summary (35%)
                Expanded(
                  flex: 35,
                  child: const CartPanel(
                    checkoutLabel: 'Send to Kitchen',
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

// Stream providers for Cafe POS data
final cafeCategoriesProvider = StreamProvider<List<Category>>((ref) {
  final repo = ref.watch(categoryRepositoryProvider);
  return repo.watchAll();
});

final cafeItemsProvider = StreamProvider<List<Item>>((ref) {
  final repo = ref.watch(itemRepositoryProvider);
  return repo.watchAll();
});

