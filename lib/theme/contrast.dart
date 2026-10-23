import 'dart:math';
import 'package:flutter/material.dart';

double contrastRatio(Color foreground, Color background) {
  final a = foreground.computeLuminance();
  final b = background.computeLuminance();
  return (max(a, b) + .05) / (min(a, b) + .05);
}

Color badgeBackground(Color fill, Color surface) =>
    Color.alphaBlend(fill.withValues(alpha: .16), surface);

Color accessibleBadgeText(Color preferred, Color background, Color fallback) {
  for (var step = 0; step <= 100; step++) {
    final candidate = Color.lerp(preferred, fallback, step / 100)!;
    if (contrastRatio(candidate, background) >= 4.5) return candidate;
  }
  return fallback;
}
