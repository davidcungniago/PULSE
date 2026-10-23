import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../services/repository_url.dart';

class QrState {
  const QrState({this.url, this.error});
  final String? url;
  final String? error;
}

final qrProvider =
    NotifierProvider.autoDispose<QrNotifier, QrState>(QrNotifier.new);

class QrNotifier extends AutoDisposeNotifier<QrState> {
  @override
  QrState build() => const QrState();

  void detect(Iterable<String?> values) {
    if (state.url != null) return;
    for (final value in values) {
      if (value != null && repositoryUrlError(value) == null) {
        state = QrState(url: value.trim());
        return;
      }
    }
    state = const QrState(
        error: 'QR harus berisi URL repository GitHub atau GitLab.');
  }
}
