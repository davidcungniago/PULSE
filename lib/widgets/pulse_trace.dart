import 'package:flutter/material.dart';
import '../models/waveform.dart';
import '../services/waveform_builder.dart';
import '../theme/pulse_colors.dart';
import '../theme/pulse_dimensions.dart';
import 'pulse_trace_painter.dart';
import 'status_badge.dart';

class PulseTrace extends StatefulWidget {
  const PulseTrace(
      {super.key,
      required this.status,
      required this.seed,
      this.hasDrift = false,
      this.scanning = false,
      this.animate = false,
      this.sub = '',
      this.height = 120});

  final RiskStatus status;
  final int seed;
  final bool hasDrift;
  final bool scanning;
  final bool animate;
  final String sub;
  final double height;

  @override
  State<PulseTrace> createState() => _PulseTraceState();
}

class _PulseTraceState extends State<PulseTrace>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(vsync: this);
  Waveform? _waveform;
  double? _width;

  @override
  void didUpdateWidget(PulseTrace oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.status != widget.status ||
        oldWidget.seed != widget.seed ||
        oldWidget.hasDrift != widget.hasDrift ||
        oldWidget.height != widget.height) {
      _waveform = null;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = PulseColors.of(context);
    final moving = widget.animate &&
        widget.scanning &&
        !MediaQuery.disableAnimationsOf(context) &&
        TickerMode.valuesOf(context).enabled;
    final sub = widget.scanning ? 'Memindai…' : widget.sub;
    return Semantics(
      label: 'Status: ${widget.status.label}. $sub',
      image: true,
      child: ExcludeSemantics(
        child: SizedBox(
            height: widget.height,
            child: LayoutBuilder(builder: (context, constraints) {
              final width = constraints.hasBoundedWidth
                  ? constraints.maxWidth
                  : PulseDimensions.maxWidth;
              if (_waveform == null || _width != width) {
                _width = width;
                _waveform = buildWaveform(
                    status: widget.status,
                    seed: widget.seed,
                    width: width,
                    height: widget.height,
                    hasDrift: widget.hasDrift);
              }
              final duration = Duration(
                  microseconds:
                      (width / 176 * 1000000).round().clamp(1, 100000000));
              if (moving && width > 0 && !_waveform!.isFlat) {
                if (!_controller.isAnimating ||
                    _controller.duration != duration) {
                  _controller.duration = duration;
                  _controller.repeat();
                }
              } else {
                _controller.stop();
              }
              return RepaintBoundary(
                  child: ClipRRect(
                borderRadius: BorderRadius.circular(PulseDimensions.tileRadius),
                child: CustomPaint(
                    size: Size(width, widget.height),
                    painter: PulseTracePainter(
                      waveform: _waveform!,
                      colors: colors,
                      traceColor: widget.scanning
                          ? colors.scanning
                          : colors.riskFill(widget.status),
                      sweep: moving && !_waveform!.isFlat ? _controller : null,
                      textDirection: Directionality.of(context),
                    )),
              ));
            })),
      ),
    );
  }
}
