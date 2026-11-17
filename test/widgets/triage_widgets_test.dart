import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pulse/models/scan_report.dart';
import 'package:pulse/models/triage.dart';
import 'package:pulse/services/dashboard_service.dart';
import 'package:pulse/theme/pulse_theme.dart';
import 'package:pulse/widgets/scan_report_sheet.dart';
import 'package:pulse/widgets/status_badge.dart';
import 'package:pulse/widgets/triage_card.dart';
import 'package:pulse/widgets/vital_line.dart';

void main() {
  testWidgets('vital line reads as one monospace summary', (tester) async {
    await tester.pumpWidget(_app(const VitalLine(items: [
      VitalLineItem('4', 'aset'),
      VitalLineItem('128', 'komponen'),
      VitalLineItem('2', 'kritis', highlight: true),
      VitalLineItem('1', 'drift'),
    ])));
    expect(find.textContaining('128 komponen'), findsOneWidget);
    expect(find.textContaining('2 kritis'), findsOneWidget);
  });

  testWidgets('triage card shows one reason and one action', (tester) async {
    var tapped = 0;
    await tester.pumpWidget(_app(TriageCard(
      entry: const TriageEntry(
          kind: TriageKind.notScanned,
          asset: AssetRiskSummary(
              assetId: 'a', name: 'API utama', status: RiskStatus.notScanned)),
      onAction: () => tapped++,
    )));
    expect(find.text('API utama'), findsOneWidget);
    expect(find.text('Belum pernah dipindai'), findsOneWidget);
    await tester.tap(find.text('Pindai sekarang'));
    expect(tapped, 1);
  });

  testWidgets('scan report lists finished and failed assets', (tester) async {
    await tester.pumpWidget(_app(const ScanReportSheet(
      report: ScanReport([
        ScanAttempt(assetId: 'a', name: 'API utama'),
        ScanAttempt(assetId: 'b', name: 'Webhook', error: 'Jaringan offline.'),
      ]),
    )));
    expect(find.text('1 dari 2 aset selesai.'), findsOneWidget);
    expect(find.text('Selesai'), findsOneWidget);
    expect(find.text('Jaringan offline.'), findsOneWidget);
  });
}

Widget _app(Widget child) => MaterialApp(
    theme: buildPulseTheme(Brightness.dark),
    home: Scaffold(body: SingleChildScrollView(child: child)));
