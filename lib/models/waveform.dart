import 'dart:ui';

class Waveform {
  Waveform({
    required List<Offset> points,
    required List<double> ectopicXs,
    required this.isFlat,
  })  : points = List.unmodifiable(points),
        ectopicXs = List.unmodifiable(ectopicXs);

  final List<Offset> points;
  final List<double> ectopicXs;
  final bool isFlat;
}
