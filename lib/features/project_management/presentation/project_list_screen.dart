import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../widgets/empty_state.dart';
import '../../../widgets/error_state.dart';
import '../../../widgets/loading_indicator.dart';
import '../application/create_project_notifier.dart';
import '../application/project_list_notifier.dart';
import 'widgets/create_project_form.dart';
import 'widgets/project_list_item.dart';

class ProjectListScreen extends ConsumerWidget {
  const ProjectListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final projects = ref.watch(projectListProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Proyek Saya'), actions: [
        IconButton(
            onPressed: () => context.push('/watchlist'),
            icon: const Icon(Icons.bookmarks_outlined),
            tooltip: 'Daftar Pantau'),
        IconButton(
            onPressed: () => context.push('/profile'),
            icon: const Icon(Icons.person_outline))
      ]),
      floatingActionButton: FloatingActionButton.extended(
          onPressed: () => _openCreateProjectForm(context, ref),
          icon: const Icon(Icons.add),
          label: const Text('Buat Proyek')),
      body: projects.when(
        loading: () => const LoadingIndicator(),
        error: (_, __) => ErrorState(
          message: 'Proyek tidak dapat dimuat.',
          onRetry: () => ref.read(projectListProvider.notifier).refresh(),
        ),
        data: (items) => items.isEmpty
            ? EmptyState(
                message: 'Belum ada proyek.',
                actionLabel: 'Buat Proyek',
                onAction: () => _openCreateProjectForm(context, ref),
              )
            : ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: items.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (_, index) =>
                    ProjectListItem(project: items[index]),
              ),
      ),
    );
  }

  Future<void> _openCreateProjectForm(BuildContext context, WidgetRef ref) {
    ref.read(createProjectProvider.notifier).reset();
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => const CreateProjectForm(),
    );
  }
}
