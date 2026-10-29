import 'package:dependency_box/devtools.dart';
import 'package:flutter/material.dart';

import '../controllers/extension_controller.dart';

/// Screen displaying the scope hierarchy tree, parent-child relationships,
/// and registrations owned by each scope.
class ScopesView extends StatelessWidget {
  const ScopesView({super.key, required this.controller});

  final ExtensionController controller;

  @override
  Widget build(BuildContext context) {
    final scopes = controller.snapshot?.scopes ?? [];

    if (scopes.isEmpty) {
      return const Center(child: Text('No scopes available in snapshot.'));
    }

    final rootScope = controller.snapshot?.rootScope ?? scopes.first;
    final selectedScope = controller.selectedScope ?? rootScope;

    final scopeRegistrations =
        controller.snapshot?.registrations
            .where((r) => r.scopeId == selectedScope.id)
            .toList() ??
        [];

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Left pane: Scope hierarchy tree
        Expanded(
          flex: 2,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                color: Theme.of(context).colorScheme.surfaceContainerHighest
                    .withValues(alpha: 0.3),
                child: Row(
                  children: [
                    const Icon(Icons.account_tree_outlined, size: 18),
                    const SizedBox(width: 8),
                    Text(
                      'Scope Hierarchy (${scopes.length} scopes)',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  children: [
                    _buildScopeTreeNode(context, rootScope, scopes, 0),
                  ],
                ),
              ),
            ],
          ),
        ),
        const VerticalDivider(width: 1),
        // Right pane: Registrations inside the selected scope
        Expanded(
          flex: 3,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                color: Theme.of(context).colorScheme.surfaceContainerHighest
                    .withValues(alpha: 0.3),
                child: Row(
                  children: [
                    const Icon(Icons.view_list_outlined, size: 18),
                    const SizedBox(width: 8),
                    Text(
                      'Registrations in "${selectedScope.name}" (${scopeRegistrations.length})',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: selectedScope.isDisposed
                            ? Colors.red.withValues(alpha: 0.12)
                            : Colors.green.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        selectedScope.isDisposed ? 'Disposed' : 'Active Scope',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: selectedScope.isDisposed
                              ? Colors.red
                              : Colors.green,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: scopeRegistrations.isEmpty
                    ? Center(
                        child: Text(
                          'No registrations directly registered in this scope.',
                          style: TextStyle(color: Colors.grey.shade600),
                        ),
                      )
                    : ListView.separated(
                        itemCount: scopeRegistrations.length,
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final reg = scopeRegistrations[index];
                          return ListTile(
                            dense: true,
                            leading: Icon(
                              reg.isCreated
                                  ? Icons.check_circle
                                  : Icons.circle_outlined,
                              size: 16,
                              color: reg.isCreated ? Colors.green : Colors.grey,
                            ),
                            title: Text(
                              reg.typeName,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            subtitle: Text(
                              '${reg.lifetime}${reg.key != null ? ' (key: ${reg.key})' : ''}',
                              style: const TextStyle(fontSize: 12),
                            ),
                            trailing: Text(
                              reg.isCreated
                                  ? 'Active in heap'
                                  : 'Uninstantiated',
                              style: TextStyle(
                                fontSize: 11,
                                color: reg.isCreated
                                    ? Colors.green
                                    : Colors.grey.shade600,
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildScopeTreeNode(
    BuildContext context,
    ScopeSnapshot scope,
    List<ScopeSnapshot> allScopes,
    int indentLevel,
  ) {
    final isSelected = controller.selectedScope?.id == scope.id;
    final childScopes = allScopes.where((s) => s.parentId == scope.id).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.only(left: 12.0 * indentLevel, right: 8, top: 2),
          child: InkWell(
            borderRadius: BorderRadius.circular(8),
            onTap: () => controller.selectScope(scope),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              decoration: BoxDecoration(
                color: isSelected
                    ? Theme.of(context).colorScheme.primary
                          .withValues(alpha: 0.12)
                    : null,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    scope.isRoot ? Icons.hub : Icons.subdirectory_arrow_right,
                    size: 16,
                    color: scope.isRoot ? Colors.indigo : Colors.grey,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    scope.name,
                    style: TextStyle(
                      fontWeight: isSelected
                          ? FontWeight.bold
                          : FontWeight.w500,
                      color: scope.isDisposed ? Colors.red : null,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 1,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.grey.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      'd:${scope.depth} • ${scope.directRegistrationCount} reg',
                      style: const TextStyle(fontSize: 10, color: Colors.grey),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        for (final child in childScopes)
          _buildScopeTreeNode(context, child, allScopes, indentLevel + 1),
      ],
    );
  }
}
