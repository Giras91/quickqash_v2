import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'repositories/isar_provider.dart';
import 'screens/retail/retail_pos_screen.dart';
import 'screens/cafe/cafe_pos_screen.dart';
import 'screens/restaurant/restaurant_pos_screen.dart';
import 'screens/settings/settings_screen.dart';
import 'screens/settings/category_list_screen.dart';
import 'screens/settings/category_form_screen.dart';
import 'screens/settings/product_list_screen.dart';
import 'screens/settings/product_form_screen.dart';
import 'screens/settings/printer_list_screen.dart';
import 'screens/settings/printer_discovery_screen.dart';
import 'screens/settings/printer_form_screen.dart';
import 'screens/order_history_screen.dart';
import 'screens/order_details_screen.dart';
import 'screens/reports_screen.dart';
import 'screens/inventory_management_screen.dart';
import 'screens/low_stock_alerts_screen.dart';
import 'screens/inventory_history_screen.dart';
import 'services/printer_discovery_service.dart';

enum AppMode { retail, cafe, restaurant }

final trainingModeProvider = StateProvider<bool>((ref) => false);
final appModeProvider = StateProvider<AppMode?>((ref) => null);

final _routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        name: 'modeSelect',
        builder: (context, state) => const ModeSelectScreen(),
      ),
      GoRoute(
        path: '/retail',
        name: 'retail',
        builder: (context, state) => const RetailPosScreen(),
      ),
      GoRoute(
        path: '/cafe',
        name: 'cafe',
        builder: (context, state) => const CafePosScreen(),
      ),
      GoRoute(
        path: '/restaurant',
        name: 'restaurant',
        builder: (context, state) => const RestaurantPosScreen(),
      ),
      GoRoute(
        path: '/settings',
        name: 'settings',
        builder: (context, state) => const SettingsScreen(),
      ),
      GoRoute(
        path: '/settings/printers',
        name: 'printers',
        builder: (context, state) => const PrinterListScreen(),
      ),
      GoRoute(
        path: '/settings/printers/discover',
        name: 'printerDiscover',
        builder: (context, state) => const PrinterDiscoveryScreen(),
      ),
      GoRoute(
        path: '/settings/printers/add/manual',
        name: 'addPrinterManual',
        builder: (context, state) => const PrinterFormScreen(),
      ),
      GoRoute(
        path: '/settings/printers/add/configure',
        name: 'addPrinterConfigure',
        builder: (context, state) {
          final device = state.extra as PrinterDevice?;
          return PrinterFormScreen(discoveredDevice: device);
        },
      ),
      GoRoute(
        path: '/settings/printers/edit/:id',
        name: 'editPrinter',
        builder: (context, state) {
          final id = int.parse(state.pathParameters['id']!);
          return PrinterFormScreen(printerId: id);
        },
      ),
      GoRoute(
        path: '/settings/products',
        name: 'products',
        builder: (context, state) => const ProductListScreen(),
      ),
      GoRoute(
        path: '/settings/products/add',
        name: 'addProduct',
        builder: (context, state) => const ProductFormScreen(),
      ),
      GoRoute(
        path: '/settings/products/edit/:id',
        name: 'editProduct',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return ProductFormScreen(productId: id);
        },
      ),
      GoRoute(
        path: '/settings/categories',
        name: 'categories',
        builder: (context, state) => const CategoryListScreen(),
      ),
      GoRoute(
        path: '/settings/categories/add',
        name: 'addCategory',
        builder: (context, state) => const CategoryFormScreen(),
      ),
      GoRoute(
        path: '/settings/categories/edit/:id',
        name: 'editCategory',
        builder: (context, state) {
          final id = int.parse(state.pathParameters['id']!);
          return CategoryFormScreen(categoryId: id);
        },
      ),
      GoRoute(
        path: '/order-history',
        name: 'orderHistory',
        builder: (context, state) => const OrderHistoryScreen(),
      ),
      GoRoute(
        path: '/order-details/:id',
        name: 'orderDetails',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return OrderDetailsScreen(orderId: id);
        },
      ),
      GoRoute(
        path: '/reports',
        name: 'reports',
        builder: (context, state) => const ReportsScreen(),
      ),
      GoRoute(
        path: '/inventory',
        name: 'inventory',
        builder: (context, state) => const InventoryManagementScreen(),
      ),
      GoRoute(
        path: '/inventory/alerts',
        name: 'inventoryAlerts',
        builder: (context, state) => const LowStockAlertsScreen(),
      ),
      GoRoute(
        path: '/inventory/details/:id',
        name: 'inventoryDetails',
        builder: (context, state) {
          final id = int.parse(state.pathParameters['id']!);
          final itemName = state.extra as String? ?? 'Item';
          return InventoryHistoryScreen(itemId: id, itemName: itemName);
        },
      ),
      GoRoute(
        path: '/settings/orders',
        name: 'orders',
        builder: (context, state) => const Scaffold(
          body: Center(child: Text('Order History - Coming soon')),
        ),
      ),
    ],
  );
});

void main() {
  runApp(const ProviderScope(child: MainApp()));
}

/// Preload Isar instances on app start
class _IsarInitializer extends ConsumerWidget {
  final Widget child;
  const _IsarInitializer({required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Eagerly initialize both databases
    ref.watch(isarProvider);
    ref.watch(trainingIsarProvider);
    return child;
  }
}

class MainApp extends ConsumerWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(_routerProvider);
    final training = ref.watch(trainingModeProvider);

    return _IsarInitializer(
      child: MaterialApp.router(
        routerConfig: router,
        title: 'QuickQash',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
          useMaterial3: true,
          appBarTheme: const AppBarTheme(centerTitle: false),
        ),
        builder: (context, child) {
          return Banner(
            message: training ? 'TRAINING' : '',
            location: BannerLocation.topEnd,
            color: training ? Colors.orange : Colors.transparent,
            child: child ?? const SizedBox.shrink(),
          );
        },
      ),
    );
  }
}

class ModeSelectScreen extends ConsumerWidget {
  const ModeSelectScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final training = ref.watch(trainingModeProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('QuickQash — Select Mode'),
        actions: [
          Row(
            children: [
              const Text('Training'),
              Switch(
                value: training,
                onChanged: (v) => ref.read(trainingModeProvider.notifier).state = v,
              ),
            ],
          ),
          const SizedBox(width: 12),
        ],
      ),
      body: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Wrap(
                spacing: 16,
                runSpacing: 16,
                children: [
                  _ModeCard(
                    title: 'Retail POS',
                    icon: Icons.point_of_sale,
                    onTap: () {
                      ref.read(appModeProvider.notifier).state = AppMode.retail;
                      context.go('/retail');
                    },
                  ),
                  _ModeCard(
                    title: 'Cafe POS',
                    icon: Icons.local_cafe,
                    onTap: () {
                      ref.read(appModeProvider.notifier).state = AppMode.cafe;
                      context.go('/cafe');
                    },
                  ),
                  _ModeCard(
                    title: 'Restaurant POS',
                    icon: Icons.restaurant,
                    onTap: () {
                      ref.read(appModeProvider.notifier).state = AppMode.restaurant;
                      context.go('/restaurant');
                    },
                  ),
                ],
              ),
              const SizedBox(height: 32),
              // Navigation to reports and history
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  OutlinedButton.icon(
                    icon: const Icon(Icons.receipt_long),
                    label: const Text('Order History'),
                    onPressed: () => context.go('/order-history'),
                  ),
                  const SizedBox(width: 12),
                  OutlinedButton.icon(
                    icon: const Icon(Icons.bar_chart),
                    label: const Text('Reports'),
                    onPressed: () => context.go('/reports'),
                  ),
                  const SizedBox(width: 12),
                  OutlinedButton.icon(
                    icon: const Icon(Icons.warning_amber),
                    label: const Text('Low Stock'),
                    onPressed: () => context.go('/inventory/alerts'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ModeCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final VoidCallback onTap;
  const _ModeCard({required this.title, required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        child: SizedBox(
          width: 220,
          height: 140,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 40),
                const SizedBox(height: 12),
                Text(title, style: Theme.of(context).textTheme.titleMedium),
              ],
            ),
          ),
        ),
      ),
    );
  }
}


