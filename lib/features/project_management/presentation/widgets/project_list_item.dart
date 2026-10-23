import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../monitoring/application/monitoring_notifier.dart';
import '../../../management/presentation/edit_form.dart';

import '../../../../models/project_model.dart';
import '../../../../widgets/status_badge.dart';
import '../../../../widgets/project_monitor_card.dart';

class ProjectListItem extends ConsumerWidget {
  const ProjectListItem({super.key, required this.project});

  final Project project;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summary = ref.watch(dashboardProvider(project.id));
    return Column(children: [
      ProjectMonitorCard(
        id: project.id,
        onTap: () => context.push('/projects/${project.id}'),
        name: project.name,
        description: project.description,
        status: summary.valueOrNull?.status ?? RiskStatus.notScanned,
      ),
      TextButton(
          onPressed: () => showModalBottomSheet<void>(
              context: context,
              isScrollControlled: true,
              builder: (_) => EditForm(
                  id: project.id,
                  name: project.name,
                  detail: project.description)),
          child: const Text('Ubah proyek')),
      if (summary.isLoading) const Text('Memuat ringkasan risiko…'),
      if (summary.hasError)
        TextButton(
            onPressed: () => ref.invalidate(dashboardProvider(project.id)),
            child: const Text('Ringkasan gagal dimuat. Coba Lagi')),
    ]);
  }
}
