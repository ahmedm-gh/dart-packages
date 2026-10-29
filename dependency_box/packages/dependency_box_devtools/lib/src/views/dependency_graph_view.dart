import 'package:dependency_box/devtools.dart';
import 'package:flutter/material.dart';

import '../controllers/extension_controller.dart';

/// Screen visualizing scope relationships, registration clustering,
/// and dependency relationships in an interactive pan/zoom canvas.
class DependencyGraphView extends StatefulWidget {
  const DependencyGraphView({super.key, required this.controller});

  final ExtensionController controller;

  @override
  State<DependencyGraphView> createState() => _DependencyGraphViewState();
}

class _DependencyGraphViewState extends State<DependencyGraphView> {
  final TransformationController _transformationController =
      TransformationController();
  RegistrationSnapshot? _highlightedRegistration;

  @override
  void dispose() {
    _transformationController.dispose();
    super.dispose();
  }

  void _resetZoom() {
    _transformationController.value = Matrix4.identity();
  }

  @override
  Widget build(BuildContext context) {
    final scopes = widget.controller.snapshot?.scopes ?? [];
    final registrations = widget.controller.snapshot?.registrations ?? [];

    if (scopes.isEmpty) {
      return const Center(
        child: Text('No scope data available to render graph.'),
      );
    }

    return Stack(
      children: [
        InteractiveViewer(
          transformationController: _transformationController,
          boundaryMargin: const EdgeInsets.all(500),
          minScale: 0.2,
          maxScale: 2.5,
          child: Center(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(40),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      for (final scope in scopes)
                        _buildScopeCluster(context, scope, registrations),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
        // Overlay Controls
        Positioned(
          top: 12,
          right: 12,
          child: Card(
            elevation: 2,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.zoom_in, size: 20),
                  tooltip: 'Zoom in',
                  onPressed: () {
                    final matrix = _transformationController.value.clone();
                    matrix.scaleByDouble(1.2, 1.2, 1.0, 1.0);
                    _transformationController.value = matrix;
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.zoom_out, size: 20),
                  tooltip: 'Zoom out',
                  onPressed: () {
                    final matrix = _transformationController.value.clone();
                    matrix.scaleByDouble(0.8, 0.8, 1.0, 1.0);
                    _transformationController.value = matrix;
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.center_focus_strong, size: 20),
                  tooltip: 'Reset view',
                  onPressed: _resetZoom,
                ),
              ],
            ),
          ),
        ),
        if (_highlightedRegistration != null)
          Positioned(
            bottom: 16,
            left: 16,
            right: 16,
            child: Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
                side: const BorderSide(color: Colors.blueAccent),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline, color: Colors.blueAccent),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Selected: ${_highlightedRegistration!.typeName} (${_highlightedRegistration!.lifetime}) in "${_highlightedRegistration!.scopeName}"',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        widget.controller.selectRegistration(
                          _highlightedRegistration,
                        );
                        widget.controller.selectTab(ExtensionTab.registrations);
                      },
                      child: const Text('View Details'),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, size: 16),
                      onPressed: () {
                        setState(() {
                          _highlightedRegistration = null;
                        });
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildScopeCluster(
    BuildContext context,
    ScopeSnapshot scope,
    List<RegistrationSnapshot> allRegistrations,
  ) {
    final theme = Theme.of(context);
    final scopeRegistrations = allRegistrations
        .where((r) => r.scopeId == scope.id)
        .toList();

    return Container(
      width: 280,
      margin: const EdgeInsets.only(right: 24),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: scope.isRoot
              ? Colors.indigo.shade300
              : theme.dividerColor.withValues(alpha: 0.5),
          width: scope.isRoot ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: scope.isRoot
                  ? Colors.indigo.withValues(alpha: 0.12)
                  : theme.colorScheme.surfaceContainerHighest.withValues(
                      alpha: 0.4,
                    ),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(11),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  scope.isRoot ? Icons.hub : Icons.inventory_2_outlined,
                  size: 16,
                  color: scope.isRoot ? Colors.indigo : Colors.grey.shade700,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    scope.name,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 1,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.grey.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'depth ${scope.depth}',
                    style: const TextStyle(fontSize: 10, color: Colors.grey),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: scopeRegistrations.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      child: Text(
                        '(No direct registrations)',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ),
                  )
                : Column(
                    children: [
                      for (final reg in scopeRegistrations)
                        _buildNodeCard(context, reg),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildNodeCard(BuildContext context, RegistrationSnapshot reg) {
    final isHighlighted = _highlightedRegistration?.id == reg.id;
    final (chipColor, chipIcon) = switch (reg.lifetime) {
      'Singleton' => (Colors.green, Icons.lock),
      'LazySingleton' => (Colors.teal, Icons.lock_clock),
      'CachedFactory' => (Colors.purple, Icons.history),
      'Factory' || 'FactoryWith' => (Colors.orange, Icons.autorenew),
      'AsyncSingleton' => (Colors.indigo, Icons.cloud_sync),
      _ => (Colors.grey, Icons.circle),
    };

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: isHighlighted
            ? Colors.blue.withValues(alpha: 0.12)
            : Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(
            color: isHighlighted
                ? Colors.blueAccent
                : Colors.grey.withValues(alpha: 0.25),
            width: isHighlighted ? 1.5 : 1,
          ),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: () {
            setState(() {
              _highlightedRegistration = reg;
            });
          },
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Row(
              children: [
                Icon(chipIcon, size: 14, color: chipColor),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        reg.typeName,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                      if (reg.key != null)
                        Text(
                          'key: ${reg.key}',
                          style: const TextStyle(
                            fontSize: 10,
                            color: Colors.blueGrey,
                          ),
                        ),
                    ],
                  ),
                ),
                if (reg.isCreated)
                  const Icon(Icons.check_circle, size: 14, color: Colors.green)
                else
                  Icon(
                    Icons.circle_outlined,
                    size: 14,
                    color: Colors.grey.shade400,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
