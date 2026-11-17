import 'package:flutter/material.dart';
import '../../../widgets/constrained_page.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../models/watched_repository.dart';
import '../../../widgets/empty_state.dart';
import '../../../widgets/error_state.dart';
import '../../../widgets/loading_indicator.dart';
import '../application/promote_watch_notifier.dart';
import '../application/watchlist_form_notifier.dart';
import '../application/watchlist_notifier.dart';
import 'widgets/promote_sheet.dart';
import 'widgets/watchlist_form.dart';
import 'widgets/watchlist_item.dart';

class WatchlistScreen extends ConsumerWidget {
  const WatchlistScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final watched = ref.watch(watchlistProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Radar')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openForm(context, ref),
        icon: const Icon(Icons.add),
        label: const Text('Tambah repositori'),
      ),
      body: ConstrainedPage(
          child: watched.when(
        loading: () => const LoadingIndicator(),
        error: (_, __) => ErrorState(
          message: 'Radar tidak dapat dimuat.',
          onRetry: () => ref.read(watchlistProvider.notifier).refresh(),
        ),
        data: (items) => items.isEmpty
            ? EmptyState(
                message: 'Belum ada repositori di Radar.',
                actionLabel: 'Tambah repositori',
                onAction: () => _openForm(context, ref),
              )
            : ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: items.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (_, index) => WatchlistItem(
                  item: items[index],
                  onEdit: () => _openForm(context, ref, editing: items[index]),
                  onPromote: () => _openPromote(context, ref, items[index]),
                ),
              ),
      )),
    );
  }

  Future<void> _openForm(
    BuildContext context,
    WidgetRef ref, {
    WatchedRepository? editing,
  }) {
    final notifier = ref.read(watchlistFormProvider.notifier);
    if (editing == null) {
      notifier.startAdd();
    } else {
      notifier.startEdit(editing);
    }
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => WatchlistForm(editing: editing),
    );
  }

  Future<void> _openPromote(
    BuildContext context,
    WidgetRef ref,
    WatchedRepository item,
  ) async {
    ref.read(promoteWatchProvider.notifier).reset();
    final projectName = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => PromoteSheet(item: item),
    );
    if (projectName != null && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Aset ditambahkan ke $projectName.')));
    }
  }
}
