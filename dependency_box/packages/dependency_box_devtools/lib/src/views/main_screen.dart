import 'package:flutter/material.dart';

import '../controllers/extension_controller.dart';
import 'dependency_graph_view.dart';
import 'diagnostics_view.dart';
import 'registrations_view.dart';
import 'scopes_view.dart';

/// Main screen of the dependency_box DevTools extension.
class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  late final ExtensionController _controller;

  @override
  void initState() {
    super.initState();
    _controller = ExtensionController();
    _controller.addListener(_onControllerChanged);
  }

  void _onControllerChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _controller.removeListener(_onControllerChanged);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          _buildHeaderBar(context),
          _buildNavigationTabBar(context),
          const Divider(height: 1),
          if (_controller.errorMessage != null)
            _buildErrorBanner(context, _controller.errorMessage!),
          Expanded(
            child: _controller.isLoading
                ? const Center(child: CircularProgressIndicator())
                : _buildTabContent(),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderBar(BuildContext context) {
    final theme = Theme.of(context);
    final snapshot = _controller.snapshot;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          bottom: BorderSide(color: theme.dividerColor.withValues(alpha: 0.4)),
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.inventory_2, color: Colors.blueAccent, size: 22),
          const SizedBox(width: 10),
          Text(
            'dependency_box DevTools',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.blueAccent.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(4),
            ),
            child: const Text(
              'v1.0.0',
              style: TextStyle(
                fontSize: 10,
                color: Colors.blueAccent,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const Spacer(),
          if (snapshot != null) ...[
            Text(
              'Last snapshot: ${_formatTime(snapshot.timestamp)}',
              style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
            ),
            const SizedBox(width: 16),
          ],
          // Auto-refresh interval dropdown
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.timer_outlined, size: 16, color: Colors.grey),
              const SizedBox(width: 4),
              DropdownButton<AutoRefreshInterval>(
                value: _controller.autoRefreshInterval,
                underline: const SizedBox(),
                isDense: true,
                style: theme.textTheme.bodySmall,
                items: [
                  for (final interval in AutoRefreshInterval.values)
                    DropdownMenuItem(
                      value: interval,
                      child: Text('Auto-refresh: ${interval.label}'),
                    ),
                ],
                onChanged: (val) {
                  if (val != null) _controller.setAutoRefreshInterval(val);
                },
              ),
            ],
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: _controller.isLoading
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.refresh, size: 20),
            tooltip: 'Fetch fresh container snapshot',
            onPressed: _controller.isLoading
                ? null
                : () => _controller.fetchSnapshot(),
          ),
        ],
      ),
    );
  }

  Widget _buildNavigationTabBar(BuildContext context) {
    return Container(
      color: Theme.of(context).colorScheme.surface,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          for (final tab in ExtensionTab.values) _buildTabButton(context, tab),
        ],
      ),
    );
  }

  Widget _buildTabButton(BuildContext context, ExtensionTab tab) {
    final isSelected = _controller.currentTab == tab;
    final theme = Theme.of(context);

    return InkWell(
      onTap: () => _controller.selectTab(tab),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: isSelected
                  ? theme.colorScheme.primary
                  : Colors.transparent,
              width: 2,
            ),
          ),
        ),
        child: Text(
          tab.label,
          style: TextStyle(
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            color: isSelected ? theme.colorScheme.primary : null,
          ),
        ),
      ),
    );
  }

  Widget _buildErrorBanner(BuildContext context, String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      color: Colors.amber.withValues(alpha: 0.12),
      child: Row(
        children: [
          const Icon(Icons.info_outline, color: Colors.orange, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(fontSize: 12, color: Colors.brown),
            ),
          ),
          TextButton(
            onPressed: () => _controller.fetchSnapshot(),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildTabContent() {
    return switch (_controller.currentTab) {
      ExtensionTab.registrations => RegistrationsView(controller: _controller),
      ExtensionTab.scopes => ScopesView(controller: _controller),
      ExtensionTab.graph => DependencyGraphView(controller: _controller),
      ExtensionTab.diagnostics => DiagnosticsView(controller: _controller),
    };
  }

  String _formatTime(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    final s = dt.second.toString().padLeft(2, '0');
    return '$h:$m:$s';
  }
}
