import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../../widgets/constrained_page.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../widgets/empty_state.dart';
import '../../../widgets/error_state.dart';
import '../../../widgets/loading_indicator.dart';
import '../application/add_asset_notifier.dart';
import '../application/asset_list_notifier.dart';
import 'widgets/add_asset_form.dart';
import 'widgets/asset_list_item.dart';

class AssetListScreen extends ConsumerWidget {
  const AssetListScreen({super.key, required this.projectId});
  final String projectId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final assets = ref.watch(assetListProvider(projectId));
    return Scaffold(
      appBar: AppBar(title: const Text('Kelola Aset')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openAddAssetForm(context),
        icon: const Icon(Icons.add),
        label: const Text('Tambah Aset'),
      ),
      body: ConstrainedPage(
          child: Column(
        children: [
          if (kDebugMode)
            _DemoModeControls(
                projectId: projectId,
                onShowSubmitting: () =>
                    _openAddAssetForm(context, showSubmitting: true)),
          Expanded(
            child: assets.when(
              loading: () => const LoadingIndicator(),
              error: (_, __) => ErrorState(
                message: 'Aset tidak dapat dimuat.',
                onRetry: () =>
                    ref.read(assetListProvider(projectId).notifier).refresh(),
              ),
              data: (items) => items.isEmpty
                  ? EmptyState(
                      message: 'Belum ada aset di project ini',
                      actionLabel: 'Tambah Aset',
                      onAction: () => _openAddAssetForm(context),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: items.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (_, index) =>
                          AssetListItem(asset: items[index]),
                    ),
            ),
          ),
        ],
      )),
    );
  }

  Future<void> _openAddAssetForm(BuildContext context,
      {bool showSubmitting = false}) async {
    final container = ProviderScope.containerOf(context, listen: false);
    container.read(addAssetProvider(projectId).notifier).reset();
    if (showSubmitting) {
      final container = ProviderScope.containerOf(context);
      container.read(addAssetProvider(projectId).notifier).showDemoSubmitting();
    }
    final added = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => AddAssetForm(projectId: projectId),
    );
    if (added == true && context.mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Aset ditambahkan.')));
    }
  }
}

class _DemoModeControls extends ConsumerWidget {
  const _DemoModeControls(
      {required this.projectId, required this.onShowSubmitting});

  final String projectId;
  final VoidCallback onShowSubmitting;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(assetListProvider(projectId).notifier);
    return Material(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Wrap(
          spacing: 8,
          runSpacing: 4,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            const Text('Mode Demo (Debug)'),
            TextButton(
                onPressed: notifier.showDemoLoading,
                child: const Text('Memuat')),
            TextButton(
                onPressed: notifier.showDemoEmpty, child: const Text('Kosong')),
            TextButton(
                onPressed: notifier.showDemoError, child: const Text('Error')),
            TextButton(
                onPressed: notifier.refresh, child: const Text('Data normal')),
            TextButton(
                onPressed: onShowSubmitting,
                child: const Text('Form mengirim')),
          ],
        ),
      ),
    );
  }
}
