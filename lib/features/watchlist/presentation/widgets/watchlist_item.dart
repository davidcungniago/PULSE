import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../models/watched_repository.dart';
import '../../application/watchlist_notifier.dart';
import 'priority_badge.dart';

class WatchlistItem extends ConsumerWidget {
  const WatchlistItem({super.key, required this.item, required this.onEdit});

  final WatchedRepository item;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context, WidgetRef ref) => Card(
        child: InkWell(
          onTap: onEdit,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.repositoryName,
                      style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  Text(item.repositoryUrl),
                  if (item.note.isNotEmpty) Text(item.note),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      PriorityBadge(priority: item.priority),
                      IconButton(
                        onPressed: onEdit,
                        icon: const Icon(Icons.edit_outlined),
                        tooltip: 'Ubah',
                      ),
                      IconButton(
                        onPressed: () => _confirmDelete(context, ref),
                        icon: const Icon(Icons.delete_outline),
                        tooltip: 'Hapus',
                      ),
                    ],
                  ),
                ],
              )),
        ),
      );

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Hapus repositori?'),
        content: Text(
            '${item.repositoryName} akan dihapus dari daftar pantau lokal.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
    if (confirmed ?? false) {
      await ref.read(watchlistProvider.notifier).remove(item.id);
    }
  }
}
