import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pulse/features/project_management/application/project_list_notifier.dart';
import 'package:pulse/features/project_management/data/project_repository.dart';
import 'package:pulse/features/project_management/presentation/project_list_screen.dart';
import 'package:pulse/models/project_model.dart';
import 'package:pulse/services/api_client.dart';
import 'package:pulse/services/project_service.dart';

void main() {
  testWidgets('menampilkan indikator saat daftar proyek sedang dimuat',
      (tester) async {
    final repository = FakeProjectRepository()
      ..projectsFuture = Completer<List<Project>>().future;
    await _pumpScreen(tester, repository);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('menampilkan daftar proyek saat data tersedia', (tester) async {
    final repository = FakeProjectRepository()..projects = [_project()];
    await _pumpScreen(tester, repository);
    expect(find.text('Platform Pembayaran'), findsOneWidget);
  });

  testWidgets('menampilkan empty state saat tidak ada proyek', (tester) async {
    final repository = FakeProjectRepository();
    await _pumpScreen(tester, repository);
    expect(find.text('Belum ada proyek.'), findsOneWidget);
  });

  testWidgets('menampilkan error dan memuat ulang saat Coba Lagi ditekan',
      (tester) async {
    final repository = FakeProjectRepository()..shouldFail = true;
    await _pumpScreen(tester, repository);
    expect(find.text('Proyek tidak dapat dimuat.'), findsOneWidget);
    repository.shouldFail = false;
    repository.projects = [_project()];
    await tester.tap(find.text('Coba Lagi'));
    await tester.pump();
    await tester.pump();
    expect(find.text('Platform Pembayaran'), findsOneWidget);
  });
}

Future<void> _pumpScreen(
        WidgetTester tester, FakeProjectRepository repository) =>
    tester
        .pumpWidget(
          ProviderScope(
            overrides: [
              projectRepositoryProvider.overrideWithValue(repository),
            ],
            child: const MaterialApp(home: ProjectListScreen()),
          ),
        )
        .then((_) => tester.pump());

Project _project() => Project(
    id: 'project-1',
    name: 'Platform Pembayaran',
    description: 'Layanan backend utama.',
    createdAt: DateTime.utc(2026, 10, 1));

class FakeProjectRepository extends ProjectRepository {
  FakeProjectRepository()
      : super(projectService: ProjectService(client: ApiClient()));

  List<Project> projects = [];
  bool shouldFail = false;
  Future<List<Project>>? projectsFuture;
  Future<Project>? addFuture;

  @override
  Future<List<Project>> getProjects() {
    if (shouldFail) return Future<List<Project>>.error(Exception('gagal'));
    return projectsFuture ?? Future<List<Project>>.value(projects);
  }

  @override
  Future<Project> createProject(
          {required String name, required String description}) =>
      addFuture ?? Future<Project>.value(_project());
}
