import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pulse/features/asset_management/application/asset_list_notifier.dart';
import 'package:pulse/features/asset_management/presentation/asset_list_screen.dart';
import 'package:pulse/features/project_management/application/project_list_notifier.dart';
import 'package:pulse/features/project_management/presentation/project_list_screen.dart';
import 'package:pulse/features/watchlist/application/watchlist_notifier.dart';
import 'package:pulse/features/watchlist/presentation/watchlist_screen.dart';
import 'package:pulse/models/asset_model.dart';
import 'package:pulse/models/project_model.dart';
import 'package:pulse/models/watched_repository.dart';
import 'package:pulse/screens/alerts_screen.dart';
import 'package:pulse/screens/login_screen.dart';
import 'package:pulse/screens/profile_screen.dart';
import 'package:pulse/screens/project_dashboard_screen.dart';
import 'package:pulse/screens/register_screen.dart';
import 'package:pulse/screens/scan_result_detail_screen.dart';
import 'package:pulse/services/watchlist_repository.dart';
import 'package:pulse/theme/pulse_theme.dart';
import 'package:pulse/features/monitoring/application/monitoring_notifier.dart';
import '../support/monitoring_fixture.dart';

import '../features/asset_management/asset_list_screen_test.dart'
    show FakeAssetRepository;
import '../features/project_management/project_list_screen_test.dart'
    show FakeProjectRepository;

void main() {
  for (final brightness in Brightness.values) {
    for (final size in [const Size(390, 844), const Size(1200, 844)]) {
      testWidgets(
          'existing screens render without overflow at $size in $brightness',
          (tester) async {
        await tester.binding.setSurfaceSize(size);
        addTearDown(() => tester.binding.setSurfaceSize(null));
        final projects = FakeProjectRepository()
          ..projects = [
            Project(
                id: 'project-1',
                name: 'Platform pembayaran',
                description: 'Layanan backend utama.',
                createdAt: DateTime.utc(2026, 10, 1))
          ];
        final assets = FakeAssetRepository()
          ..assets = [
            const Asset(
                id: 'asset-1',
                projectId: 'project-1',
                name: 'API utama',
                repositoryUrl: 'https://github.com/pulse/api',
                owner: 'pulse',
                repositoryName: 'api',
                isActive: true)
          ];
        final watchlist = InMemoryWatchlistRepository(seed: [
          WatchedRepository(
              id: 'watch-1',
              repositoryUrl: 'https://github.com/expressjs/express',
              owner: 'expressjs',
              repositoryName: 'express',
              note: 'Framework utama layanan API.',
              priority: WatchPriority.high,
              createdAt: DateTime.utc(2026, 10, 1),
              updatedAt: DateTime.utc(2026, 10, 1))
        ]);
        final screens = <String, Widget>{
          'login': const LoginScreen(),
          'register': const RegisterScreen(),
          'projects': const ProjectListScreen(),
          'dashboard': const ProjectDashboardScreen(projectId: 'project-1'),
          'assets': const AssetListScreen(projectId: 'project-1'),
          'results': const ScanResultDetailScreen(assetId: 'asset-1'),
          'alerts': const AlertsScreen(projectId: 'project-1'),
          'profile': const ProfileScreen(),
          'watchlist': const WatchlistScreen(),
        };
        for (final screen in screens.entries) {
          final boundary = GlobalKey();
          await tester.pumpWidget(ProviderScope(
              overrides: [
                monitoringRepositoryProvider
                    .overrideWithValue(FakeMonitoringRepository()),
                projectRepositoryProvider.overrideWithValue(projects),
                assetRepositoryProvider.overrideWithValue(assets),
                watchlistRepositoryProvider.overrideWithValue(watchlist),
              ],
              child: MaterialApp(
                  theme: buildPulseTheme(brightness),
                  home: RepaintBoundary(key: boundary, child: screen.value))));
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull, reason: screen.key);
          if (Platform.environment['PULSE_CAPTURE_DESIGN'] == '1') {
            final render = boundary.currentContext!.findRenderObject()!
                as RenderRepaintBoundary;
            final image = await render.toImage(pixelRatio: 1);
            final bytes =
                await image.toByteData(format: ui.ImageByteFormat.png);
            await tester.runAsync(() async {
              final folder = Directory('build/d1_qa');
              await folder.create(recursive: true);
              await File(
                      '${folder.path}/${screen.key}_${brightness.name}_${size.width.toInt()}.png')
                  .writeAsBytes(bytes!.buffer.asUint8List());
            });
            image.dispose();
          }
          await tester.pumpWidget(const SizedBox.shrink());
          await tester.pump();
        }
      });
    }
  }
}
