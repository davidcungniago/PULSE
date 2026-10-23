import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../../widgets/constrained_page.dart';
import '../../../widgets/error_state.dart';
import '../application/qr_notifier.dart';

class QrScannerScreen extends ConsumerStatefulWidget {
  const QrScannerScreen({super.key});
  @override
  ConsumerState<QrScannerScreen> createState() => _QrScannerScreenState();
}

class _QrScannerScreenState extends ConsumerState<QrScannerScreen> {
  int _attempt = 0;

  @override
  Widget build(BuildContext context) {
    ref.listen(qrProvider, (previous, next) {
      if (next.url != null) Navigator.of(context).pop(next.url);
    });
    final state = ref.watch(qrProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Pindai QR repository')),
      body: ConstrainedPage(
          child: Column(children: [
        const Padding(
            padding: EdgeInsets.all(16),
            child: Text('Arahkan kamera ke QR berisi URL repository.')),
        Expanded(
            child: MobileScanner(
          key: ValueKey(_attempt),
          onDetect: (capture) => ref
              .read(qrProvider.notifier)
              .detect(capture.barcodes.map((b) => b.rawValue)),
          errorBuilder: (context, error) => ErrorState(
            message:
                'Kamera tidak tersedia atau izin ditolak. Aktifkan izin kamera, atau kembali untuk mengetik URL.',
            onRetry: () => setState(() => _attempt++),
          ),
        )),
        if (state.error != null)
          Padding(padding: const EdgeInsets.all(16), child: Text(state.error!)),
        TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Batal')),
      ])),
    );
  }
}
