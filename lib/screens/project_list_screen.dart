import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../services/project_service.dart';
import '../widgets/empty_state.dart';
import '../widgets/loading_indicator.dart';
import '../widgets/status_badge.dart';

class ProjectListScreen extends StatelessWidget { const ProjectListScreen({super.key}); @override Widget build(BuildContext context) => Scaffold(appBar: AppBar(title: const Text('Proyek Saya'), actions: [IconButton(onPressed: () => context.push('/profile'), icon: const Icon(Icons.person_outline))]), floatingActionButton: FloatingActionButton.extended(onPressed: () {}, icon: const Icon(Icons.add), label: const Text('Buat Proyek')), body: FutureBuilder(future: ProjectService().getProjects(), builder: (context, snapshot) { if (!snapshot.hasData) return const LoadingIndicator(); final projects = snapshot.data!; if (projects.isEmpty) return const EmptyState(message: 'Belum ada proyek.', actionLabel: 'Buat Proyek'); return ListView.separated(padding: const EdgeInsets.all(16), itemCount: projects.length, separatorBuilder: (_, __) => const SizedBox(height: 10), itemBuilder: (context, index) { final project = projects[index]; return Card(child: ListTile(onTap: () => context.push('/projects/${project.id}'), title: Text(project.name), subtitle: Text(project.description), trailing: StatusBadge(status: index == 0 ? RiskStatus.critical : RiskStatus.warning))); }); })); }
