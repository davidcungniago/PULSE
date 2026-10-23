import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pulse/models/severity.dart';
import 'package:pulse/theme/contrast.dart';
import 'package:pulse/theme/pulse_colors.dart';
import 'package:pulse/widgets/status_badge.dart';

void main() {
  test('contrast ratio has known endpoints and is symmetric', () {
    expect(contrastRatio(Colors.black, Colors.white), 21);
    expect(contrastRatio(Colors.white, Colors.black), 21);
    expect(contrastRatio(Colors.white, Colors.white), 1);
  });

  test('badge background composites sixteen percent over the surface', () {
    final background =
        badgeBackground(const Color(0xFFEF4444), const Color(0xFF161E1A));
    expect(
        background,
        Color.alphaBlend(const Color(0xFFEF4444).withValues(alpha: .16),
            const Color(0xFF161E1A)));
    expect(background.a, 1);
  });

  for (final brightness in Brightness.values) {
    final colors = PulseColors(brightness);
    for (final status in RiskStatus.values) {
      test('$brightness risk $status badge contrast is at least 4.5', () {
        expect(
            contrastRatio(colors.riskText(status),
                badgeBackground(colors.riskFill(status), colors.surface)),
            greaterThanOrEqualTo(4.5));
      });
    }
    for (final severity in Severity.values) {
      test('$brightness severity $severity badge contrast is at least 4.5', () {
        expect(
            contrastRatio(colors.severityText(severity),
                badgeBackground(colors.severityFill(severity), colors.surface)),
            greaterThanOrEqualTo(4.5));
      });
    }
  }
}
