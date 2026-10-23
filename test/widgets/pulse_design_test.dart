import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pulse/models/severity.dart';
import 'package:pulse/theme/pulse_theme.dart';
import 'package:pulse/widgets/asset_card.dart';
import 'package:pulse/widgets/constrained_page.dart';
import 'package:pulse/widgets/project_monitor_card.dart';
import 'package:pulse/widgets/pulse_banner.dart';
import 'package:pulse/widgets/pulse_trace.dart';
import 'package:pulse/widgets/pulse_trace_painter.dart';
import 'package:pulse/widgets/severity_badge.dart';
import 'package:pulse/widgets/status_badge.dart';
import 'package:pulse/widgets/vital_tile.dart';

void main() {
  testWidgets('trace exposes a readable status and subline to semantics',
      (tester) async {
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(_app(const PulseTrace(
        status: RiskStatus.healthy,
        seed: 42,
        animate: false,
        sub: 'Tidak ada temuan')));
    expect(find.bySemanticsLabel('Status: Sehat. Tidak ada temuan'),
        findsOneWidget);
    semantics.dispose();
  });

  testWidgets('every severity displays its Indonesian label', (tester) async {
    await tester.pumpWidget(_app(Column(children: [
      for (final severity in Severity.values) SeverityBadge(severity: severity)
    ])));
    for (final severity in Severity.values) {
      expect(find.text(severity.label), findsOneWidget);
    }
  });

  testWidgets('page is centered and capped at 560 logical pixels',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(1200, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(_app(const ConstrainedPage(
        child: SizedBox(key: Key('content'), height: 100))));
    expect(tester.getSize(find.byKey(const Key('content'))).width, 560);
    expect(tester.getTopLeft(find.byKey(const Key('content'))).dx, 320);
  });

  testWidgets('animate false keeps scanning trace static and repaint isolated',
      (tester) async {
    await tester.pumpWidget(_app(const PulseTrace(
        status: RiskStatus.warning, seed: 42, scanning: true, animate: false)));
    final painter = _painter(tester);
    expect(painter.sweep, isNull);
    expect(
        find.ancestor(
            of: find.byType(CustomPaint).last,
            matching: find.byType(RepaintBoundary)),
        findsWidgets);
    await tester.pumpAndSettle();
  });

  testWidgets('reduced motion suppresses the dashboard sweep', (tester) async {
    await tester.pumpWidget(_app(const MediaQuery(
        data: MediaQueryData(disableAnimations: true),
        child: PulseTrace(
            status: RiskStatus.warning,
            seed: 42,
            scanning: true,
            animate: false))));
    expect(_painter(tester).sweep, isNull);
    await tester.pumpAndSettle();
  });

  testWidgets('project card stays static and forwards its tap', (tester) async {
    var tapped = 0;
    await tester.pumpWidget(_app(ProjectMonitorCard(
        id: 'project-1',
        name: 'Proyek',
        status: RiskStatus.healthy,
        onTap: () => tapped++)));
    expect(tester.widget<PulseTrace>(find.byType(PulseTrace)).animate, isFalse);
    await tester.tap(find.text('Proyek'));
    expect(tapped, 1);
  });

  testWidgets('asset scan callback is disabled while scanning', (tester) async {
    var scanned = 0;
    await tester.pumpWidget(_app(AssetCard(
        name: 'API',
        status: RiskStatus.warning,
        timeLabel: '2 jam lalu',
        scanning: true,
        onScan: () => scanned++)));
    expect(tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
        isNull);
    expect(scanned, 0);
  });

  for (final brightness in Brightness.values) {
    for (final size in [const Size(390, 844), const Size(1200, 844)]) {
      testWidgets('design components fit $size in $brightness', (tester) async {
        await tester.binding.setSurfaceSize(size);
        addTearDown(() => tester.binding.setSurfaceSize(null));
        await tester.pumpWidget(_app(
            ConstrainedPage(
                child: ListView(padding: const EdgeInsets.all(16), children: [
              const PulseBanner(
                  status: RiskStatus.critical,
                  seed: 42,
                  sub: '2 CVE kritis di 1 aset',
                  hasDrift: true,
                  animate: false),
              const SizedBox(height: 16),
              const Row(children: [
                Expanded(child: VitalTile(label: 'Komponen', value: '121')),
                SizedBox(width: 8),
                Expanded(child: VitalTile(label: 'CVE kritis', value: '2')),
                SizedBox(width: 8),
                Expanded(child: VitalTile(label: 'Drift', value: '1')),
              ]),
              const SizedBox(height: 16),
              Wrap(spacing: 8, runSpacing: 8, children: [
                for (final severity in Severity.values)
                  SeverityBadge(severity: severity)
              ]),
              const SizedBox(height: 16),
              AssetCard(
                  name: 'Layanan pembayaran dengan nama panjang',
                  status: RiskStatus.notScanned,
                  timeLabel: 'Belum pernah dipindai',
                  onScan: () {}),
            ])),
            brightness: brightness));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        expect(tester.getSize(find.byType(FilledButton)).height,
            greaterThanOrEqualTo(48));
      });
    }
  }
}

Widget _app(Widget child, {Brightness brightness = Brightness.dark}) =>
    MaterialApp(
        theme: buildPulseTheme(brightness), home: Scaffold(body: child));

PulseTracePainter _painter(WidgetTester tester) => tester
    .widgetList<CustomPaint>(find.byType(CustomPaint))
    .map((widget) => widget.painter)
    .whereType<PulseTracePainter>()
    .single;
