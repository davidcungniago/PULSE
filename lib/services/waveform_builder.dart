import 'dart:math';
import 'dart:ui';

import '../models/waveform.dart';
import '../widgets/status_badge.dart';

Waveform buildWaveform({
  required RiskStatus status,
  required int seed,
  required double width,
  required double height,
  bool hasDrift = false,
}) {
  if (!width.isFinite || !height.isFinite || width < 0 || height < 0) {
    throw ArgumentError('Ukuran gelombang harus terbatas dan tidak negatif.');
  }
  final baseline = .64 * height;
  final flat = status == RiskStatus.notScanned || status == RiskStatus.inactive;
  if (flat || width == 0 || height == 0) {
    return Waveform(
      points:
          List.generate(width.floor(), (x) => Offset(x.toDouble(), baseline)),
      ectopicXs: const [],
      isFlat: true,
    );
  }
  final p = switch (status) {
    RiskStatus.warning => (
        interval: .78,
        spread: .5,
        r: 1.25,
        rSpread: .5,
        rSigma: .014,
        t: .42,
        st: .22,
        pScale: .8,
        noise: .03,
        fib: 0.0
      ),
    RiskStatus.critical => (
        interval: .46,
        spread: .28,
        r: 1.9,
        rSpread: .7,
        rSigma: .026,
        t: -.2,
        st: .35,
        pScale: .3,
        noise: .05,
        fib: .22
      ),
    _ => (
        interval: .92,
        spread: .04,
        r: 1.0,
        rSpread: .04,
        rSigma: .012,
        t: .26,
        st: 0.0,
        pScale: 1.0,
        noise: .012,
        fib: 0.0
      ),
  };
  final random = Random(seed);
  final beats = <({double time, double amplitude, bool ectopic})>[];
  final ectopicXs = <double>[];
  var time = .3;
  var index = 1;
  var previousWasEctopic = false;
  while (time < width / 110 + 1) {
    final interval = p.interval + (random.nextDouble() - .5) * p.spread;
    final ectopic = hasDrift && index % 4 == 0;
    if (index > 1) {
      time += interval *
          (ectopic
              ? .6
              : previousWasEctopic
                  ? 1.2
                  : 1);
    }
    final amplitude = p.r + (random.nextDouble() - .5) * p.rSpread;
    beats.add((time: time, amplitude: amplitude, ectopic: ectopic));
    if (ectopic && time * 110 < width) ectopicXs.add(time * 110);
    previousWasEctopic = ectopic;
    index++;
  }
  double g(double dt, double mu, double sigma) =>
      exp(-pow((dt - mu) / sigma, 2) / 2);
  final points = List.generate(width.floor(), (x) {
    final t = x / 110;
    var signal = (random.nextDouble() - .5) * p.noise;
    signal += p.fib * sin(t * 95 + sin(t * 7) * 3) * (.5 + .5 * sin(t * 1.3));
    for (final beat in beats) {
      final dt = t - beat.time;
      if (dt.abs() > 1) continue;
      signal += beat.ectopic
          ? 1.5 * .9 * g(dt, 0, .045) - .3 * g(dt, .3, .09)
          : .12 * p.pScale * g(dt, -.18, .04) -
              .12 * g(dt, -.035, .012) +
              beat.amplitude * g(dt, 0, p.rSigma) -
              .22 * g(dt, .04, .014) +
              p.t * g(dt, .28, .06) +
              p.st * g(dt, .13, .09);
    }
    return Offset(
        x.toDouble(), (baseline - .24 * height * signal).clamp(0.0, height));
  });
  return Waveform(points: points, ectopicXs: ectopicXs, isFlat: false);
}
