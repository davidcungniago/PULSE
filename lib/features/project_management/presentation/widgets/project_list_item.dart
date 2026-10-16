import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../models/project_model.dart';
import '../../../../widgets/status_badge.dart';

class ProjectListItem extends StatelessWidget {
  const ProjectListItem({super.key, required this.project});

  final Project project;

  @override
  Widget build(BuildContext context) => Card(
        child: ListTile(
          onTap: () => context.push('/projects/${project.id}'),
          title: Text(project.name),
          subtitle: Text(project.description),
          trailing: const StatusBadge(status: RiskStatus.notScanned),
        ),
      );
}
