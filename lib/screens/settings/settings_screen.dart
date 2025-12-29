import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../main.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final training = ref.watch(trainingModeProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        actions: [
          Row(
            children: [
              const Text('Training Mode'),
              const SizedBox(width: 8),
              Switch(
                value: training,
                onChanged: (v) => ref.read(trainingModeProvider.notifier).state = v,
              ),
            ],
          ),
          const SizedBox(width: 12),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSettingsTile(
            context,
            icon: Icons.inventory_2,
            title: 'Products & Categories',
            subtitle: 'Manage menu items and categories',
            onTap: () => context.push('/settings/products'),
          ),
          const SizedBox(height: 8),
          _buildSettingsTile(
            context,
            icon: Icons.print,
            title: 'Printers',
            subtitle: 'Configure kitchen and receipt printers',
            onTap: () => context.push('/settings/printers'),
          ),
          const SizedBox(height: 8),
          _buildSettingsTile(
            context,
            icon: Icons.warehouse,
            title: 'Inventory',
            subtitle: 'Manage stock levels and low-stock alerts',
            onTap: () => context.push('/inventory'),
          ),
          const SizedBox(height: 8),
          _buildSettingsTile(
            context,
            icon: Icons.history,
            title: 'Order History',
            subtitle: 'View past orders and sales reports',
            onTap: () => context.push('/settings/orders'),
          ),
          const SizedBox(height: 8),
          _buildSettingsTile(
            context,
            icon: Icons.calculate,
            title: 'Tax & Discounts',
            subtitle: 'Configure tax rates and discount templates',
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Coming soon')),
              );
            },
            enabled: false,
          ),
          const SizedBox(height: 8),
          _buildSettingsTile(
            context,
            icon: Icons.business,
            title: 'Business Information',
            subtitle: 'Store name, address, and receipt details',
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Coming soon')),
              );
            },
            enabled: false,
          ),
          const SizedBox(height: 32),
          const Divider(),
          const SizedBox(height: 16),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text('About QuickQash'),
            subtitle: const Text('Version 1.0.0'),
            onTap: () {
              showAboutDialog(
                context: context,
                applicationName: 'QuickQash POS',
                applicationVersion: '1.0.0',
                applicationLegalese: '© 2025 QuickQash\nOffline POS System',
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    bool enabled = true,
  }) {
    return Card(
      child: ListTile(
        enabled: enabled,
        leading: Icon(
          icon,
          size: 32,
          color: enabled
              ? Theme.of(context).colorScheme.primary
              : Theme.of(context).colorScheme.onSurfaceVariant,
        ),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: enabled ? onTap : null,
      ),
    );
  }
}
