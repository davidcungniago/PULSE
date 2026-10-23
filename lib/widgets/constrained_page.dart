import 'package:flutter/material.dart';
import '../theme/pulse_dimensions.dart';

class ConstrainedPage extends StatelessWidget {
  const ConstrainedPage({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) => Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: PulseDimensions.maxWidth),
          child: SizedBox(width: double.infinity, child: child),
        ),
      );
}
