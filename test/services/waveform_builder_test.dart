import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:pulse/services/stable_hash.dart';
import 'package:pulse/services/waveform_builder.dart';
import 'package:pulse/widgets/status_badge.dart';

void main() {
  test('FNV-1a matches published 32-bit vectors and distinguishes ids', () {
    expect(stableHash(''), 0x811c9dc5);
    expect(stableHash('a'), 0xe40c292c);
    expect(stableHash('foobar'), 0xbf9cf968);
    expect(stableHash('project-1'), stableHash('project-1'));
    expect(stableHash('project-1'), isNot(stableHash('project-2')));
  });

  test('same inputs produce identical points and ectopic positions', () {
    for (final status in RiskStatus.values) {
      final a = buildWaveform(
          status: status, seed: 42, width: 560, height: 120, hasDrift: true);
      final b = buildWaveform(
          status: status, seed: 42, width: 560, height: 120, hasDrift: true);
      expect(a.points, b.points);
      expect(a.ectopicXs, b.ectopicXs);
      expect(a.isFlat, b.isFlat);
    }
  });

  test('same seed gives critical then warning then healthy peak amplitudes',
      () {
    for (final seed in [0, 1, 42, 1234, stableHash('project-1')]) {
      double amplitude(RiskStatus status) {
        final wave =
            buildWaveform(status: status, seed: seed, width: 560, height: 120);
        return .64 * 120 - wave.points.map((point) => point.dy).reduce(min);
      }

      expect(amplitude(RiskStatus.critical),
          greaterThan(amplitude(RiskStatus.warning)));
      expect(amplitude(RiskStatus.warning),
          greaterThan(amplitude(RiskStatus.healthy)));
    }
  });

  test('not scanned is exactly flat at baseline even when drift is requested',
      () {
    final wave = buildWaveform(
        status: RiskStatus.notScanned,
        seed: 42,
        width: 560,
        height: 120,
        hasDrift: true);
    expect(wave.isFlat, isTrue);
    expect(wave.ectopicXs, isEmpty);
    expect(wave.points.every((point) => point.dy == .64 * 120), isTrue);
  });

  test('drift marks every fourth beat only for non-flat traces', () {
    final wave = buildWaveform(
        status: RiskStatus.healthy,
        seed: 42,
        width: 1200,
        height: 120,
        hasDrift: true);
    expect(wave.ectopicXs, hasLength(3));
    expect(wave.ectopicXs.first, inInclusiveRange(290, 305));
    for (var i = 1; i < wave.ectopicXs.length; i++) {
      expect(wave.ectopicXs[i], greaterThan(wave.ectopicXs[i - 1]));
    }
    expect(
        buildWaveform(
                status: RiskStatus.healthy, seed: 42, width: 1200, height: 120)
            .ectopicXs,
        isEmpty);
  });

  test('every pixel column has a bounded sample for all statuses', () {
    for (final status in RiskStatus.values) {
      final wave = buildWaveform(
          status: status, seed: 23, width: 560, height: 120, hasDrift: true);
      expect(wave.points, hasLength(560));
      for (var i = 0; i < wave.points.length; i++) {
        expect(wave.points[i].dx, i.toDouble());
        expect(wave.points[i].dy, inInclusiveRange(0, 120));
      }
    }
  });

  test('empty and invalid dimensions have explicit behavior', () {
    expect(
        buildWaveform(
                status: RiskStatus.healthy, seed: 1, width: 0, height: 120)
            .points,
        isEmpty);
    expect(
        buildWaveform(status: RiskStatus.healthy, seed: 1, width: 5, height: 0)
            .points
            .every((p) => p.dy == 0),
        isTrue);
    for (final width in [-1.0, double.infinity, double.nan]) {
      expect(
          () => buildWaveform(
              status: RiskStatus.healthy, seed: 1, width: width, height: 120),
          throwsArgumentError);
    }
  });
}
