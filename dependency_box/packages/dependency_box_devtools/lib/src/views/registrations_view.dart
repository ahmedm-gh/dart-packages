import 'package:dependency_box/devtools.dart';
import 'package:flutter/material.dart';

import '../controllers/extension_controller.dart';

/// Screen displaying the table of dependency registrations with rich filtering
/// and inspector side drawer.
class RegistrationsView extends StatelessWidget {
  const RegistrationsView({super.key, required this.controller});

  final ExtensionController controller;

  @override
  Widget build(BuildContext context) {
    final registrations = controller.filteredRegistrations;
    final total = controller.snapshot?.totalRegistrations ?? 0;
    final instantiated = controller.snapshot?.totalInstantiated ?? 0;

    return Column(
      children: [
        _buildSummaryBar(context, total, instantiated),
        _buildFilterToolbar(context),
        const Divider(height: 1),
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 3,
                child: registrations.isEmpty
                    ? _buildEmptyState(context)
                    : _buildRegistrationsList(context, registrations),
              ),
              if (controller.selectedRegistration != null) ...[
                const VerticalDivider(width: 1),
                Expanded(
                  flex: 2,
                  child: _buildDetailsPanel(
                    context,
                    controller.selectedRegistration!,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryBar(BuildContext context, int total, int instantiated) {
    final theme = Theme.of(context);
    final singletons =
        controller.snapshot?.registrations
            .where((r) => r.lifetime.contains('Singleton'))
            .length ??
        0;
    final factories =
        controller.snapshot?.registrations
            .where((r) => r.lifetime.contains('Factory'))
            .length ??
        0;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
      child: Row(
        children: [
          _buildStatCard(
            context,
            'Total Registrations',
            '$total',
            Icons.inventory_2_outlined,
            theme.colorScheme.primary,
          ),
          const SizedBox(width: 12),
          _buildStatCard(
            context,
            'Singletons',
            '$singletons',
            Icons.lock_clock_outlined,
            Colors.teal,
          ),
          const SizedBox(width: 12),
          _buildStatCard(
            context,
            'Factories',
            '$factories',
            Icons.build_circle_outlined,
            Colors.orange,
          ),
          const SizedBox(width: 12),
          _buildStatCard(
            context,
            'Instantiated',
            '$instantiated / $total',
            Icons.check_circle_outline,
            Colors.green,
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    BuildContext context,
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    final theme = Theme.of(context);
    return Card(
      elevation: 0,
      color: theme.colorScheme.surface,
      shape: RoundedRectangleBorder(
        side: BorderSide(color: theme.dividerColor.withValues(alpha: 0.5)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                Text(
                  value,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterToolbar(BuildContext context) {
    final scopes = controller.snapshot?.scopes ?? [];
    final lifetimes = [
      'Singleton',
      'LazySingleton',
      'CachedFactory',
      'Factory',
      'AsyncSingleton',
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: SizedBox(
              height: 36,
              child: TextField(
                decoration: InputDecoration(
                  hintText: 'Search type or key...',
                  prefixIcon: const Icon(Icons.search, size: 18),
                  contentPadding: EdgeInsets.zero,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onChanged: controller.setSearchQuery,
              ),
            ),
          ),
          const SizedBox(width: 12),
          DropdownButton<String?>(
            value: controller.selectedScopeFilter,
            hint: const Text('All Scopes'),
            isDense: true,
            items: [
              const DropdownMenuItem(value: null, child: Text('All Scopes')),
              for (final s in scopes)
                DropdownMenuItem(
                  value: s.id,
                  child: Text('${s.name} (d:${s.depth})'),
                ),
            ],
            onChanged: controller.setScopeFilter,
          ),
          const SizedBox(width: 12),
          DropdownButton<String?>(
            value: controller.selectedLifetimeFilter,
            hint: const Text('All Lifetimes'),
            isDense: true,
            items: [
              const DropdownMenuItem(value: null, child: Text('All Lifetimes')),
              for (final l in lifetimes)
                DropdownMenuItem(value: l, child: Text(l)),
            ],
            onChanged: controller.setLifetimeFilter,
          ),
          const SizedBox(width: 12),
          DropdownButton<bool?>(
            value: controller.isCreatedFilter,
            hint: const Text('All States'),
            isDense: true,
            items: const [
              DropdownMenuItem(value: null, child: Text('All States')),
              DropdownMenuItem(value: true, child: Text('Instantiated Only')),
              DropdownMenuItem(
                value: false,
                child: Text('Uninstantiated Only'),
              ),
            ],
            onChanged: controller.setIsCreatedFilter,
          ),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.filter_alt_off, size: 20),
            tooltip: 'Clear filters',
            onPressed: controller.clearFilters,
          ),
        ],
      ),
    );
  }

  Widget _buildRegistrationsList(
    BuildContext context,
    List<RegistrationSnapshot> registrations,
  ) {
    return ListView.separated(
      itemCount: registrations.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final reg = registrations[index];
        final isSelected = controller.selectedRegistration?.id == reg.id;

        return ListTile(
          dense: true,
          selected: isSelected,
          onTap: () => controller.selectRegistration(reg),
          leading: _buildLifetimeIcon(reg.lifetime),
          title: Row(
            children: [
              Text(
                reg.typeName,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              if (reg.key != null) ...[
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.blue.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    'key: ${reg.key}',
                    style: const TextStyle(fontSize: 11, color: Colors.blue),
                  ),
                ),
              ],
              if (reg.isShadowed) ...[
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.amber.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    'shadowed',
                    style: TextStyle(fontSize: 10, color: Colors.orange),
                  ),
                ),
              ],
              if (reg.isMulti) ...[
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.purple.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    'multi (${reg.multiIndex! + 1}/${reg.multiTotal})',
                    style: const TextStyle(fontSize: 10, color: Colors.purple),
                  ),
                ),
              ],
            ],
          ),
          subtitle: Text(
            'Scope: ${reg.scopeName} (depth ${reg.scopeDepth}) • ${reg.lifetime}',
            style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
          ),
          trailing: _buildStatusChip(context, reg),
        );
      },
    );
  }

  Widget _buildLifetimeIcon(String lifetime) {
    final (icon, color) = switch (lifetime) {
      'Singleton' => (Icons.lock, Colors.green),
      'LazySingleton' => (Icons.lock_clock, Colors.teal),
      'CachedFactory' => (Icons.history, Colors.purple),
      'Factory' || 'FactoryWith' => (Icons.autorenew, Colors.orange),
      'AsyncSingleton' => (Icons.cloud_sync, Colors.indigo),
      _ => (Icons.circle, Colors.grey),
    };
    return CircleAvatar(
      radius: 14,
      backgroundColor: color.withValues(alpha: 0.15),
      child: Icon(icon, size: 16, color: color),
    );
  }

  Widget _buildStatusChip(BuildContext context, RegistrationSnapshot reg) {
    if (reg.isResolving) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: Colors.amber.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Text(
          'Resolving...',
          style: TextStyle(color: Colors.orange, fontSize: 11),
        ),
      );
    }

    if (reg.isCreated) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: Colors.green.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check, size: 12, color: Colors.green),
            const SizedBox(width: 4),
            Text(
              reg.instanceRuntimeType ?? 'Instantiated',
              style: const TextStyle(color: Colors.green, fontSize: 11),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.grey.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Text(
        'Uninstantiated',
        style: TextStyle(color: Colors.grey, fontSize: 11),
      ),
    );
  }

  Widget _buildDetailsPanel(BuildContext context, RegistrationSnapshot reg) {
    final theme = Theme.of(context);
    return Container(
      color: theme.colorScheme.surface,
      padding: const EdgeInsets.all(16),
      child: ListView(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Registration Details',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close, size: 18),
                onPressed: () => controller.selectRegistration(null),
              ),
            ],
          ),
          const Divider(),
          _buildDetailRow('Type', reg.typeName),
          _buildDetailRow('Identifier', reg.id),
          _buildDetailRow('Key', reg.key ?? '<none>'),
          _buildDetailRow('Lifetime', reg.lifetime),
          if (reg.paramType != null)
            _buildDetailRow('Parameter Type', reg.paramType!),
          _buildDetailRow('Scope Name', reg.scopeName),
          _buildDetailRow('Scope ID', reg.scopeId),
          _buildDetailRow('Scope Depth', '${reg.scopeDepth}'),
          _buildDetailRow(
            'Instance State',
            reg.isCreated ? 'Instantiated in memory' : 'Not yet created',
          ),
          if (reg.instanceRuntimeType != null)
            _buildDetailRow('Instance Type', reg.instanceRuntimeType!),
          _buildDetailRow('Is Resolving', reg.isResolving ? 'Yes' : 'No'),
          _buildDetailRow(
            'Is Shadowed',
            reg.isShadowed ? 'Yes (shadows parent)' : 'No',
          ),
          _buildDetailRow('Is Multi', reg.isMulti ? 'Yes' : 'No'),
          if (reg.multiResolution != null)
            _buildDetailRow('Multi Strategy', reg.multiResolution!),
          if (reg.multiIndex != null)
            _buildDetailRow(
              'Multi Position',
              'Index ${reg.multiIndex} of ${reg.multiTotal}',
            ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
            ),
          ),
          Expanded(
            child: SelectableText(value, style: const TextStyle(fontSize: 12)),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.search_off, size: 48, color: Colors.grey.shade400),
          const SizedBox(height: 12),
          const Text(
            'No registrations match the current filters.',
            style: TextStyle(fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 6),
          TextButton(
            onPressed: controller.clearFilters,
            child: const Text('Clear Filters'),
          ),
        ],
      ),
    );
  }
}
