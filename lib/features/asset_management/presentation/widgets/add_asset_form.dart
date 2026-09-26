import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../widgets/app_text_field.dart';
import '../../../../widgets/primary_button.dart';
import '../../application/add_asset_notifier.dart';

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
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          24,
          12,
          24,
          24 + MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Tambah Aset', style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 8),
            const Text('Masukkan URL repositori GitHub atau GitLab.'),
            const SizedBox(height: 20),
            if (state.submitError != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
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
            const SizedBox(height: 20),
            PrimaryButton(
              label: 'Tambah Aset',
              isLoading: state.status == AddAssetStatus.submitting,
              onPressed: state.canSubmit
                  ? () => ref
                      .read(addAssetProvider(widget.projectId).notifier)
                      .submit(_controller.text)
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}
