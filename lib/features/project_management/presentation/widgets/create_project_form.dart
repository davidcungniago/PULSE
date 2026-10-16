import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../widgets/app_text_field.dart';
import '../../../../widgets/primary_button.dart';
import '../../application/create_project_notifier.dart';

class CreateProjectForm extends ConsumerStatefulWidget {
  const CreateProjectForm({super.key});

  @override
  ConsumerState<CreateProjectForm> createState() => _CreateProjectFormState();
}

class _CreateProjectFormState extends ConsumerState<CreateProjectForm> {
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<CreateProjectState>(createProjectProvider, (previous, next) {
      if (next.status == CreateProjectStatus.success) {
        Navigator.of(context).pop(true);
      }
    });
    final state = ref.watch(createProjectProvider);
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
            Text('Buat Proyek',
                style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 8),
            const Text('Isi nama proyek. Deskripsi bersifat opsional.'),
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
              label: 'Nama proyek',
              controller: _nameController,
              errorText: state.nameError,
              validator: (_) => state.nameError,
              onChanged: ref.read(createProjectProvider.notifier).validateName,
            ),
            const SizedBox(height: 16),
            AppTextField(
              label: 'Deskripsi (opsional)',
              controller: _descriptionController,
            ),
            const SizedBox(height: 20),
            PrimaryButton(
              label: 'Buat Proyek',
              isLoading: state.status == CreateProjectStatus.submitting,
              onPressed: state.canSubmit
                  ? () => ref.read(createProjectProvider.notifier).submit(
                        name: _nameController.text,
                        description: _descriptionController.text,
                      )
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}
