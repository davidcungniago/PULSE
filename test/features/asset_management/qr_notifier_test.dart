import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pulse/features/asset_management/application/qr_notifier.dart';

void main() {
  test('QR URL valid diterima sekali dan payload asing ditolak', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    container.listen(qrProvider, (_, __) {});
    final notifier = container.read(qrProvider.notifier);
    notifier.detect(['https://evilgithub.com/a/b']);
    expect(container.read(qrProvider).url, isNull);
    expect(container.read(qrProvider).error, isNotNull);
    notifier.detect(['https://github.com/pulse/api']);
    expect(container.read(qrProvider).url, 'https://github.com/pulse/api');
    notifier.detect(['https://gitlab.com/other/repo']);
    expect(container.read(qrProvider).url, 'https://github.com/pulse/api');
  });
}
