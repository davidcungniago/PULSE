import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../models/watched_repository.dart';
import '../../../../widgets/app_text_field.dart';
import '../../../../widgets/primary_button.dart';
import '../../application/watchlist_form_notifier.dart';

class WatchlistForm extends ConsumerStatefulWidget {
  const WatchlistForm({super.key, this.editing});

  final WatchedRepository? editing;

  @override
  ConsumerState<WatchlistForm> createState() => _WatchlistFormState();
}

class _WatchlistFormState extends ConsumerState<WatchlistForm> {
  final _urlController = TextEditingController();
  final _noteController = TextEditingController();
  late WatchPriority _priority;

  bool get _isEditing => widget.editing != null;

  @override
  void initState() {
    super.initState();
    _priority = widget.editing?.priority ?? WatchPriority.medium;
    _urlController.text = widget.editing?.repositoryUrl ?? '';
    _noteController.text = widget.editing?.note ?? '';
  }

  @override
  void dispose() {
    _urlController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<WatchlistFormState>(watchlistFormProvider, (previous, next) {
      if (next.status == WatchlistFormStatus.success) {
        Navigator.of(context).pop(true);
      }
    });
    final state = ref.watch(watchlistFormProvider);
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
            Text(
              _isEditing ? 'Ubah Repositori' : 'Tambah Repositori',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(_isEditing
                ? 'Ubah catatan atau prioritas. URL tidak dapat diubah.'
                : 'Masukkan URL repository GitHub/GitLab untuk dipantau.'),
            const SizedBox(height: 20),
            if (state.submitError != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(
                  state.submitError!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ),
            if (_isEditing)
              _RepositoryUrlText(url: widget.editing!.repositoryUrl)
            else
              AppTextField(
                label: 'URL repositori',
                controller: _urlController,
                errorText: state.urlError,
                validator: (_) => state.urlError,
                onChanged: ref.read(watchlistFormProvider.notifier).validateUrl,
              ),
            const SizedBox(height: 16),
            AppTextField(
              label: 'Catatan (opsional)',
              controller: _noteController,
            ),
            const SizedBox(height: 16),
            SegmentedButton<WatchPriority>(
              segments: [
                for (final priority in WatchPriority.values)
                  ButtonSegment(
                    value: priority,
                    label: Text(priority.label),
                  ),
              ],
              selected: {_priority},
              onSelectionChanged: (selection) =>
                  setState(() => _priority = selection.first),
            ),
            const SizedBox(height: 20),
            PrimaryButton(
              label: _isEditing ? 'Simpan' : 'Tambah ke Daftar',
              isLoading: state.status == WatchlistFormStatus.submitting,
              onPressed: state.canSubmit
                  ? () => ref.read(watchlistFormProvider.notifier).submit(
                        repositoryUrl: _urlController.text,
                        note: _noteController.text,
                        priority: _priority,
                      )
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}

class _RepositoryUrlText extends StatelessWidget {
  const _RepositoryUrlText({required this.url});

  final String url;

  @override
  Widget build(BuildContext context) => InputDecorator(
        decoration: const InputDecoration(
          labelText: 'URL repositori',
          border: OutlineInputBorder(),
        ),
        child: Text(url),
      );
}
