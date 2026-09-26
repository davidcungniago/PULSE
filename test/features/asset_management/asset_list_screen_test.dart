import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pulse/features/asset_management/application/asset_list_notifier.dart';
import 'package:pulse/features/asset_management/data/asset_repository.dart';
import 'package:pulse/features/asset_management/presentation/asset_list_screen.dart';
import 'package:pulse/features/asset_management/presentation/widgets/add_asset_form.dart';
import 'package:pulse/models/asset_model.dart';

const projectId = 'project-1';

void main() {
  testWidgets('menampilkan indikator saat aset sedang dimuat', (tester) async {
    final repository = FakeAssetRepository()..assetsFuture = Completer<List<Asset>>().future;
    await _pumpScreen(tester, repository);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('menampilkan daftar aset saat data tersedia', (tester) async {
    final repository = FakeAssetRepository()..assets = [_asset()];
    await _pumpScreen(tester, repository);
    expect(find.text('API Utama'), findsOneWidget);
    expect(find.textContaining('pulse/api'), findsOneWidget);
  });

  testWidgets('menampilkan empty state saat tidak ada aset', (tester) async {
    final repository = FakeAssetRepository();
    await _pumpScreen(tester, repository);
    expect(find.text('Belum ada aset di project ini'), findsOneWidget);
  });

  testWidgets('menampilkan error dan memuat ulang saat Coba Lagi ditekan', (tester) async {
    final repository = FakeAssetRepository()..shouldFail = true;
    await _pumpScreen(tester, repository);
    expect(find.text('Aset tidak dapat dimuat.'), findsOneWidget);
    repository.shouldFail = false;
    repository.assets = [_asset()];
    await tester.tap(find.text('Coba Lagi'));
    await tester.pump();
    await tester.pump();
    expect(find.text('API Utama'), findsOneWidget);
  });

  testWidgets('menampilkan validasi inline untuk URL repositori tidak valid', (tester) async {
    final repository = FakeAssetRepository();
    await _pumpScreen(tester, repository);
    await tester.tap(find.text('Tambah Aset').first);
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField), 'https://contoh.com/repo');
    await tester.pump();
    expect(find.text('Gunakan URL GitHub atau GitLab yang valid.'), findsOneWidget);
    final submitButton = _addAssetSubmitButton();
    expect(tester.widget<FilledButton>(submitButton).onPressed, isNull);
  });

  testWidgets('menonaktifkan submit dan menampilkan spinner saat aset dikirim', (tester) async {
    final repository = FakeAssetRepository()..addFuture = Completer<Asset>().future;
    await _pumpScreen(tester, repository);
    await tester.tap(find.text('Tambah Aset').first);
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField), 'https://github.com/pulse/api');
    await tester.pump();
    final submitButton = _addAssetSubmitButton();
    await tester.tap(submitButton);
    await tester.pump();
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(tester.widget<FilledButton>(submitButton).onPressed, isNull);
  });
}

Future<void> _pumpScreen(WidgetTester tester, FakeAssetRepository repository) => tester.pumpWidget(
      ProviderScope(
        overrides: [assetRepositoryProvider.overrideWithValue(repository)],
        child: const MaterialApp(home: AssetListScreen(projectId: projectId)),
      ),
    ).then((_) => tester.pump());

Finder _addAssetSubmitButton() => find.descendant(
      of: find.byType(AddAssetForm),
      matching: find.byType(FilledButton),
    );

Asset _asset() => Asset(id: 'asset-1', projectId: projectId, name: 'API Utama', repositoryUrl: 'https://github.com/pulse/api', owner: 'pulse', repositoryName: 'api', isActive: true, lastScannedAt: DateTime(2026, 9, 26, 10));

class FakeAssetRepository extends AssetRepository {
  List<Asset> assets = [];
  bool shouldFail = false;
  Future<List<Asset>>? assetsFuture;
  Future<Asset>? addFuture;

  @override
  Future<List<Asset>> getAssets(String projectId) {
    if (shouldFail) return Future<List<Asset>>.error(Exception('gagal'));
    return assetsFuture ?? Future<List<Asset>>.value(assets);
  }

  @override
  Future<Asset> addAsset(String projectId, String repositoryUrl) {
    return addFuture ?? Future<Asset>.value(_asset());
  }
}
