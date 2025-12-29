import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../models/order.dart';
import '../models/order_item.dart';
import '../models/payment.dart';
import '../providers/cart_provider.dart';
import '../repositories/repositories.dart';
import '../main.dart';

final orderServiceProvider = Provider<OrderService>((ref) {
  final orderRepo = ref.read(orderRepositoryProvider);
  return OrderService(orderRepo);
});

class OrderService {
  final OrderRepository _orderRepository;
  final _uuid = const Uuid();

  OrderService(this._orderRepository);

  /// Creates an order from the current cart state and saves it to the database
  Future<String> createOrderFromCart({
    required Cart cart,
    required String paymentMethod,
    required double amountPaid,
    String? tableName,
    AppMode? mode,
  }) async {
    if (cart.items.isEmpty) {
      throw Exception('Cannot create order from empty cart');
    }

    final orderId = _uuid.v4();
    final now = DateTime.now();

    // Create order
    final order = Order()
      ..orderId = orderId
      ..mode = (mode ?? AppMode.retail).name
      ..timestamp = now
      ..subtotal = cart.subtotal
      ..tax = cart.tax
      ..discount = cart.discount
      ..total = cart.total
      ..tableName = tableName
      ..status = 'completed';

    // Create order items
    final orderItems = cart.items.map((cartItem) {
      return OrderItem()
        ..orderId = orderId
        ..itemId = cartItem.itemId
        ..itemName = cartItem.name
        ..price = cartItem.price
        ..quantity = cartItem.quantity
        ..kitchenRoute = cartItem.kitchenRoute
        ..modifiers = cartItem.modifiers
        ..notes = cartItem.notes;
    }).toList();

    // Save to database
    await _orderRepository.saveWithItems(order, orderItems);
    
    // Save payment separately (if payment repository exists)
    // For now, payments are tracked but not persisted
    // TODO: Implement payment repository and save payment record

    return orderId;
  }

  /// Retrieves all orders, respecting training mode
  Future<List<Order>> getAllOrders() async {
    return await _orderRepository.getAll();
  }

  /// Gets a specific order by ID
  Future<Order?> getOrderById(int orderId) async {
    return await _orderRepository.getById(orderId);
  }

  /// Gets order items for a specific order
  Future<List<OrderItem>> getOrderItems(String orderId) async {
    return await _orderRepository.getOrderItems(orderId);
  }

  /// Gets payment records for a specific order
  Future<List<Payment>> getOrderPayments(String orderId) async {
    return await _orderRepository.getOrderPayments(orderId);
  }

  /// Calculates daily sales summary
  Future<DailySummary> getDailySummary(DateTime date) async {
    final orders = await _orderRepository.getAll();
    
    // Filter orders for the specified date
    final dailyOrders = orders.where((order) {
      return order.timestamp.year == date.year &&
             order.timestamp.month == date.month &&
             order.timestamp.day == date.day &&
             order.status == 'completed';
    }).toList();

    final totalSales = dailyOrders.fold<double>(
      0.0,
      (sum, order) => sum + order.total,
    );

    final totalOrders = dailyOrders.length;

    return DailySummary(
      date: date,
      totalSales: totalSales,
      totalOrders: totalOrders,
      averageOrderValue: totalOrders > 0 ? totalSales / totalOrders : 0.0,
    );
  }
}

class DailySummary {
  final DateTime date;
  final double totalSales;
  final int totalOrders;
  final double averageOrderValue;

  DailySummary({
    required this.date,
    required this.totalSales,
    required this.totalOrders,
    required this.averageOrderValue,
  });
}
