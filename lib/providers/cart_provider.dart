import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

class Cart {
  final List<CartItem> items;
  final double taxRate;
  final double discount;

  Cart({
    this.items = const [],
    this.taxRate = 0.08,
    this.discount = 0.0,
  });

  double get subtotal {
    return items.fold(0.0, (sum, item) => sum + (item.price * item.quantity));
  }

  double get tax => subtotal * taxRate;
  double get total => subtotal + tax - discount;

  int get itemCount => items.length;

  Cart copyWith({
    List<CartItem>? items,
    double? taxRate,
    double? discount,
  }) {
    return Cart(
      items: items ?? this.items,
      taxRate: taxRate ?? this.taxRate,
      discount: discount ?? this.discount,
    );
  }
}

class CartItem {
  final String id;
  final String itemId; // Reference to actual item
  final String name;
  final double price;
  final int quantity;
  final List<String> modifiers;
  final String? kitchenRoute;
  final String? notes;

  CartItem({
    String? id,
    required this.itemId,
    required this.name,
    required this.price,
    this.quantity = 1,
    this.modifiers = const [],
    this.kitchenRoute,
    this.notes,
  }) : id = id ?? const Uuid().v4();

  CartItem copyWith({
    String? id,
    String? itemId,
    String? name,
    double? price,
    int? quantity,
    List<String>? modifiers,
    String? kitchenRoute,
    String? notes,
  }) {
    return CartItem(
      id: id ?? this.id,
      itemId: itemId ?? this.itemId,
      name: name ?? this.name,
      price: price ?? this.price,
      quantity: quantity ?? this.quantity,
      modifiers: modifiers ?? this.modifiers,
      kitchenRoute: kitchenRoute ?? this.kitchenRoute,
      notes: notes ?? this.notes,
    );
  }
}

class CartNotifier extends StateNotifier<Cart> {
  CartNotifier() : super(Cart());

  void addItem({
    required String itemId,
    required String name,
    required double price,
    List<String> modifiers = const [],
    String? kitchenRoute,
    String? notes,
  }) {
    // Check if item with same modifiers exists
    final existingIndex = state.items.indexWhere(
      (item) =>
          item.itemId == itemId &&
          item.modifiers.join(',') == modifiers.join(','),
    );

    if (existingIndex >= 0) {
      // Increment quantity
      final updatedItems = List<CartItem>.from(state.items);
      updatedItems[existingIndex] = updatedItems[existingIndex].copyWith(
        quantity: updatedItems[existingIndex].quantity + 1,
      );
      state = state.copyWith(items: updatedItems);
    } else {
      // Add new item
      final newItem = CartItem(
        itemId: itemId,
        name: name,
        price: price,
        quantity: 1,
        modifiers: modifiers,
        kitchenRoute: kitchenRoute,
        notes: notes,
      );
      state = state.copyWith(items: [...state.items, newItem]);
    }
  }

  void updateQuantity(String cartItemId, int newQuantity) {
    if (newQuantity <= 0) {
      removeItem(cartItemId);
      return;
    }

    final updatedItems = state.items.map((item) {
      if (item.id == cartItemId) {
        return item.copyWith(quantity: newQuantity);
      }
      return item;
    }).toList();

    state = state.copyWith(items: updatedItems);
  }

  void removeItem(String cartItemId) {
    final updatedItems = state.items.where((item) => item.id != cartItemId).toList();
    state = state.copyWith(items: updatedItems);
  }

  void updateItemModifiers(String cartItemId, List<String> modifiers) {
    final updatedItems = state.items.map((item) {
      if (item.id == cartItemId) {
        return item.copyWith(modifiers: modifiers);
      }
      return item;
    }).toList();

    state = state.copyWith(items: updatedItems);
  }

  void setDiscount(double amount) {
    state = state.copyWith(discount: amount);
  }

  void clear() {
    state = Cart(taxRate: state.taxRate);
  }
}

// Cart provider - separate instances for training and production
final cartProvider = StateNotifierProvider<CartNotifier, Cart>((ref) {
  return CartNotifier();
});
