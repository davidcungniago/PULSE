import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../widgets/app_text_field.dart';
import '../../../widgets/primary_button.dart';
import '../application/edit_notifier.dart';

class EditForm extends ConsumerStatefulWidget {
  const EditForm(
      {super.key,
      required this.id,
      required this.name,
      required this.detail,
      this.isAsset = false,
      this.active = true});
  final String id, name, detail;
  final bool isAsset, active;
  @override
  ConsumerState<EditForm> createState() => _EditFormState();
}

class _EditFormState extends ConsumerState<EditForm> {
  late final _name = TextEditingController(text: widget.name);
  late final _detail = TextEditingController(text: widget.detail);
  late bool _active = widget.active;
  final _form = GlobalKey<FormState>();
  @override
  void dispose() {
    _name.dispose();
    _detail.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(editProvider, (_, next) {
      if (next.valueOrNull == true) Navigator.of(context).pop();
    });
    final state = ref.watch(editProvider);
    final notifier = ref.read(editProvider.notifier);
    return SafeArea(
        child: SingleChildScrollView(
            child: Padding(
      padding: EdgeInsets.fromLTRB(
          16, 16, 16, 16 + MediaQuery.viewInsetsOf(context).bottom),
      child: Form(
          key: _form,
          child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(widget.isAsset ? 'Ubah aset' : 'Ubah proyek',
                    style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 16),
                AppTextField(
                    label: 'Nama',
                    controller: _name,
                    validator: notifier.nameError),
                const SizedBox(height: 16),
                AppTextField(
                    label: widget.isAsset ? 'URL repositori' : 'Deskripsi',
                    controller: _detail,
                    validator: widget.isAsset ? notifier.urlError : null),
                if (widget.isAsset)
                  SwitchListTile(
                      title: const Text('Aset aktif'),
                      value: _active,
                      onChanged: state.isLoading
                          ? null
                          : (value) => setState(() => _active = value)),
                if (state.hasError)
                  Text('${state.error}',
                      style: TextStyle(
                          color: Theme.of(context).colorScheme.error)),
                const SizedBox(height: 16),
                PrimaryButton(
                    label: 'Simpan',
                    isLoading: state.isLoading,
                    onPressed: () {
                      if (_form.currentState!.validate()) {
                        notifier.save(
                            id: widget.id,
                            name: _name.text,
                            detail: _detail.text,
                            isAsset: widget.isAsset,
                            active: _active);
                      }
                    }),
                if (!widget.isAsset)
                  TextButton(
                      onPressed: state.isLoading
                          ? null
                          : () async {
                              final confirmed = await showDialog<bool>(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                        title: const Text('Hapus proyek?'),
                                        content: const Text(
                                            'Hanya proyek tanpa aset yang dapat dihapus.'),
                                        actions: [
                                          TextButton(
                                              onPressed: () =>
                                                  Navigator.pop(context, false),
                                              child: const Text('Batal')),
                                          TextButton(
                                              onPressed: () =>
                                                  Navigator.pop(context, true),
                                              child: const Text('Hapus'))
                                        ],
                                      ));
                              if (confirmed == true && mounted) {
                                notifier.remove(widget.id);
                              }
                            },
                      child: const Text('Hapus proyek')),
              ])),
    )));
  }
}
