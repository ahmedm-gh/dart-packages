import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../controllers/extension_controller.dart';

/// Screen displaying health diagnostics, warnings, circular dependency notices,
/// and snapshot export tools.
class DiagnosticsView extends StatelessWidget {
  const DiagnosticsView({super.key, required this.controller});

  final ExtensionController controller;

  @override
  Widget build(BuildContext context) {
    final diagnostics = controller.snapshot?.diagnostics ?? [];
    final snapshot = controller.snapshot;

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        _buildActionHeader(context),
        const SizedBox(height: 16),
        _buildHealthSummary(context),
        const SizedBox(height: 20),
        Text(
          'Diagnostic Notices (${diagnostics.length})',
          style: Theme.of(context).textTheme.titleSmall
              ?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        if (diagnostics.isEmpty)
          Card(
            elevation: 0,
            color: Colors.green.withValues(alpha: 0.08),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
              side: BorderSide(color: Colors.green.withValues(alpha: 0.3)),
            ),
            child: const Padding(
              padding: EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(Icons.check_circle_outline, color: Colors.green),
                  SizedBox(width: 12),
                  Text(
                    'All clear! No scope disposal leaks or registration conflicts detected.',
                    style: TextStyle(fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ),
          )
        else
          for (final notice in diagnostics)
            Card(
              margin: const EdgeInsets.only(bottom: 8),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
                side: BorderSide(
                  color: notice.severity == 'warning'
                      ? Colors.orange.withValues(alpha: 0.4)
                      : Colors.blue.withValues(alpha: 0.3),
                ),
              ),
              child: ListTile(
                dense: true,
                leading: Icon(
                  notice.severity == 'warning'
                      ? Icons.warning_amber_rounded
                      : Icons.info_outline,
                  color: notice.severity == 'warning'
                      ? Colors.orange
                      : Colors.blue,
                ),
                title: Text(
                  notice.title,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text(notice.message),
                trailing: notice.relatedScope != null
                    ? Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.grey.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          notice.relatedScope!,
                          style: const TextStyle(
                            fontSize: 10,
                            color: Colors.grey,
                          ),
                        ),
                      )
                    : null,
              ),
            ),
        const SizedBox(height: 24),
        if (snapshot != null) ...[
          Text(
            'Raw Point-in-Time Snapshot Payload',
            style: Theme.of(context).textTheme.titleSmall
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest
                  .withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: Theme.of(context).dividerColor.withValues(alpha: 0.4),
              ),
            ),
            child: SelectableText(
              snapshot.toJsonString(pretty: true),
              style: const TextStyle(fontFamily: 'monospace', fontSize: 11),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildActionHeader(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Container Health & Diagnostics',
              style: Theme.of(context).textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            Text(
              'Inspect memory usage, scope lifecycles, and configuration alerts.',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
          ],
        ),
        FilledButton.icon(
          icon: const Icon(Icons.copy, size: 16),
          label: const Text('Copy Snapshot JSON'),
          onPressed: () {
            final jsonStr = controller.snapshot?.toJsonString(pretty: true);
            if (jsonStr != null) {
              Clipboard.setData(ClipboardData(text: jsonStr));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Snapshot JSON copied to clipboard!'),
                  duration: Duration(seconds: 2),
                ),
              );
            }
          },
        ),
      ],
    );
  }

  Widget _buildHealthSummary(BuildContext context) {
    final theme = Theme.of(context);
    final total = controller.snapshot?.totalRegistrations ?? 0;
    final instantiated = controller.snapshot?.totalInstantiated ?? 0;
    final scopesCount = controller.snapshot?.scopes.length ?? 0;
    final disposedScopes =
        controller.snapshot?.scopes.where((s) => s.isDisposed).length ?? 0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: theme.dividerColor.withValues(alpha: 0.5)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildMetric('Active Scopes', '${scopesCount - disposedScopes}'),
          _buildMetric('Disposed Scopes', '$disposedScopes'),
          _buildMetric('Heap Retained Singletons', '$instantiated'),
          _buildMetric('Lazy / Unallocated', '${total - instantiated}'),
        ],
      ),
    );
  }

  Widget _buildMetric(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
      ],
    );
  }
}
