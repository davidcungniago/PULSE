import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../widgets/app_text_field.dart';
import '../../../../widgets/primary_button.dart';
import '../../application/add_asset_notifier.dart';
import '../qr_scanner_screen.dart';

class AddAssetForm extends ConsumerStatefulWidget {
  const AddAssetForm({super.key, required this.projectId});
  final String projectId;
  @override
  ConsumerState<AddAssetForm> createState() => _AddAssetFormState();
}

class _AddAssetFormState extends ConsumerState<AddAssetForm> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AddAssetState>(
      addAssetProvider(widget.projectId),
      (previous, next) {
        if (next.status == AddAssetStatus.success) {
          Navigator.of(context).pop(true);
        }
      },
    );
    final state = ref.watch(addAssetProvider(widget.projectId));
    return SafeArea(
      child: SingleChildScrollView(
          child: Padding(
        padding: EdgeInsets.fromLTRB(
          16,
          16,
          16,
          16 + MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Tambah Aset',
                style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 8),
            const Text('Masukkan URL repositori GitHub atau GitLab.'),
            const SizedBox(height: 24),
            if (state.submitError != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Text(
                  state.submitError!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ),
            AppTextField(
              label: 'URL repositori',
              controller: _controller,
              keyboardType: TextInputType.url,
              errorText: state.urlError,
              validator: (_) => state.urlError,
              onChanged: ref
                  .read(addAssetProvider(widget.projectId).notifier)
                  .validateRepositoryUrl,
            ),
            const SizedBox(height: 24),
            PrimaryButton(
              label: 'Tambah Aset',
              isLoading: state.status == AddAssetStatus.submitting,
              onPressed: state.canSubmit
                  ? () => ref
                      .read(addAssetProvider(widget.projectId).notifier)
                      .submit(_controller.text)
                  : null,
            ),
            TextButton.icon(
              icon: const Icon(Icons.qr_code_scanner),
              label: const Text('Pindai QR repository'),
              onPressed: state.status == AddAssetStatus.submitting
                  ? null
                  : () async {
                      final url = await Navigator.of(context).push<String>(
                          MaterialPageRoute(
                              builder: (_) => const QrScannerScreen()));
                      if (!mounted || url == null) return;
                      _controller.text = url;
                      ref
                          .read(addAssetProvider(widget.projectId).notifier)
                          .validateRepositoryUrl(url);
                    },
            ),
          ],
        ),
      )),
    );
  }
}
