import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../models/project_model.dart';
import '../../../../models/watched_repository.dart';
import '../../../../widgets/loading_indicator.dart';
import '../../../project_management/application/project_list_notifier.dart';
import '../../application/promote_watch_notifier.dart';

class PromoteSheet extends ConsumerWidget {
  const PromoteSheet({super.key, required this.item});

  final WatchedRepository item;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final projects = ref.watch(projectListProvider);
    final promote = ref.watch(promoteWatchProvider);
    return PopScope(
      canPop: !promote.isSubmitting,
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Jadikan aset',
                  style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 8),
              Text('Pilih proyek untuk ${item.repositoryName}.'),
              if (promote.error != null) ...[
                const SizedBox(height: 12),
                Text(promote.error!,
                    style:
                        TextStyle(color: Theme.of(context).colorScheme.error)),
              ],
              const SizedBox(height: 16),
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 320),
                child: projects.when(
                  loading: () =>
                      const SizedBox(height: 96, child: LoadingIndicator()),
                  error: (_, __) => Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('Proyek tidak dapat dimuat.'),
                      TextButton(
                        onPressed: () => ref.invalidate(projectListProvider),
                        child: const Text('Coba lagi'),
                      ),
                    ],
                  ),
                  data: (items) => items.isEmpty
                      ? const Padding(
                          padding: EdgeInsets.symmetric(vertical: 24),
                          child: Text(
                              'Belum ada proyek. Buat proyek terlebih dahulu.'),
                        )
                      : ListView.separated(
                          shrinkWrap: true,
                          itemCount: items.length,
                          separatorBuilder: (_, __) => const Divider(height: 1),
                          itemBuilder: (context, index) {
                            final project = items[index];
                            final submitting = promote.isSubmitting &&
                                promote.projectId == project.id;
                            return ListTile(
                              enabled: !promote.isSubmitting,
                              title: Text(project.name),
                              subtitle: project.description.isEmpty
                                  ? null
                                  : Text(project.description),
                              trailing: submitting
                                  ? const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                          strokeWidth: 2))
                                  : const Icon(Icons.chevron_right),
                              onTap: promote.isSubmitting
                                  ? null
                                  : () => _promote(context, ref, project),
                            );
                          },
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _promote(
      BuildContext context, WidgetRef ref, Project project) async {
    final promoted = await ref
        .read(promoteWatchProvider.notifier)
        .promote(item: item, project: project);
    if (!promoted || !context.mounted) return;
    Navigator.of(context).pop(project.name);
  }
}
