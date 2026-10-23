import 'package:flutter/material.dart';
import '../models/severity.dart';
import '../widgets/status_badge.dart';
import 'contrast.dart';

class PulseColors {
  const PulseColors(this.brightness);
  final Brightness brightness;
  bool get isDark => brightness == Brightness.dark;
  static PulseColors of(BuildContext context) =>
      PulseColors(Theme.of(context).brightness);

  Color get bg => Color(isDark ? 0xFF0F1512 : 0xFFF6F5F0);
  Color get surface => Color(isDark ? 0xFF161E1A : 0xFFFFFFFF);
  Color get surfaceTrace => Color(isDark ? 0xFF121A16 : 0xFFEEF2EF);
  Color get line => Color(isDark ? 0xFF26312C : 0xFFD9DDD8);
  Color get gridMinor => Color(isDark ? 0xFF1B2621 : 0xFFE3E8E4);
  Color get gridMajor => Color(isDark ? 0xFF26332C : 0xFFCBD3CD);
  Color get text => Color(isDark ? 0xFFE9E5D8 : 0xFF1A211D);
  Color get textMuted => Color(isDark ? 0xFF9AA59E : 0xFF5B665F);
  Color get scanning => const Color(0xFF60A5FA);
  Color get drift => const Color(0xFF93C5FD);
  Color get transparent => const Color(0x00000000);

  Color riskFill(RiskStatus status) => switch (status) {
        RiskStatus.healthy || RiskStatus.active => const Color(0xFF4ADE80),
        RiskStatus.warning => const Color(0xFFEAB308),
        RiskStatus.critical => const Color(0xFFEF4444),
        RiskStatus.notScanned || RiskStatus.inactive => const Color(0xFF9CA3AF),
      };

  Color severityFill(Severity severity) => switch (severity) {
        Severity.critical => const Color(0xFFEF4444),
        Severity.high => const Color(0xFFF97316),
        Severity.medium => const Color(0xFFEAB308),
        Severity.low => const Color(0xFF60A5FA),
        Severity.unknown => const Color(0xFF9CA3AF),
        Severity.safe => const Color(0xFF22C55E),
      };

  Color severityText(Severity severity) {
    final preferred = isDark
        ? severityFill(severity)
        : switch (severity) {
            Severity.critical => const Color(0xFFB91C1C),
            Severity.high => const Color(0xFFC2410C),
            Severity.medium => const Color(0xFFA16207),
            Severity.low => const Color(0xFF1D4ED8),
            Severity.unknown => const Color(0xFF4B5563),
            Severity.safe => const Color(0xFF15803D),
          };
    return accessibleBadgeText(
        preferred, badgeBackground(severityFill(severity), surface), text);
  }

  Color riskText(RiskStatus status) {
    final preferred = isDark
        ? riskFill(status)
        : switch (status) {
            RiskStatus.healthy || RiskStatus.active => const Color(0xFF15803D),
            RiskStatus.warning => const Color(0xFFA16207),
            RiskStatus.critical => const Color(0xFFB91C1C),
            RiskStatus.notScanned ||
            RiskStatus.inactive =>
              const Color(0xFF4B5563),
          };
    return accessibleBadgeText(
        preferred, badgeBackground(riskFill(status), surface), text);
  }
}
