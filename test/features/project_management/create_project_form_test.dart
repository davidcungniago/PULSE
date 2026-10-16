import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pulse/features/project_management/application/project_list_notifier.dart';
import 'package:pulse/features/project_management/data/project_repository.dart';
import 'package:pulse/features/project_management/presentation/project_list_screen.dart';
import 'package:pulse/features/project_management/presentation/widgets/create_project_form.dart';
import 'package:pulse/models/project_model.dart';
import 'package:pulse/services/api_client.dart';
import 'package:pulse/services/project_service.dart';

void main() {
  testWidgets('menampilkan validasi saat nama proyek kosong', (tester) async {
    final repository = FakeProjectRepository();
    await _pumpScreen(tester, repository);
    await tester.tap(find.text('Buat Proyek').first);
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).first, '   ');
    await tester.pump();
    expect(find.text('Nama proyek wajib diisi.'), findsOneWidget);
    expect(tester.widget<FilledButton>(_submitButton()).onPressed, isNull);
  });

  testWidgets(
      'menonaktifkan tombol dan menampilkan spinner saat proyek dikirim',
      (tester) async {
    final repository = FakeProjectRepository()
      ..addFuture = Completer<Project>().future;
    await _pumpScreen(tester, repository);
    await tester.tap(find.text('Buat Proyek').first);
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).first, 'Proyek Baru');
    await tester.pump();
    final submitButton = _submitButton();
    await tester.tap(submitButton);
    await tester.pump();
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(tester.widget<FilledButton>(submitButton).onPressed, isNull);
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

Finder _submitButton() => find.descendant(
      of: find.byType(CreateProjectForm),
      matching: find.byType(FilledButton),
    );

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
