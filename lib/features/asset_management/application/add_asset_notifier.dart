import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/asset_repository.dart';
import 'asset_list_notifier.dart';

enum AddAssetStatus { idle, validating, submitting, success, failure }

class AddAssetState {
  const AddAssetState({this.status = AddAssetStatus.idle, this.urlError, this.submitError, this.isUrlValid = false});
  final AddAssetStatus status;
  final String? urlError;
  final String? submitError;
  final bool isUrlValid;
  bool get canSubmit => isUrlValid && status != AddAssetStatus.submitting;
  AddAssetState copyWith({AddAssetStatus? status, String? urlError, bool clearUrlError = false, String? submitError, bool clearSubmitError = false, bool? isUrlValid}) => AddAssetState(status: status ?? this.status, urlError: clearUrlError ? null : urlError ?? this.urlError, submitError: clearSubmitError ? null : submitError ?? this.submitError, isUrlValid: isUrlValid ?? this.isUrlValid);
}

final addAssetProvider = NotifierProvider.family<AddAssetNotifier, AddAssetState, String>(AddAssetNotifier.new);

class AddAssetNotifier extends FamilyNotifier<AddAssetState, String> {
  static final _repositoryUrl = RegExp(r'^https://(github\.com|gitlab\.com)/[^/\s]+/[^/\s]+/?$');

  @override
  AddAssetState build(String projectId) => const AddAssetState();

  void validateRepositoryUrl(String value) {
    final url = value.trim();
    final error = url.isEmpty
        ? 'URL repositori wajib diisi.'
        : !_repositoryUrl.hasMatch(url)
            ? 'Gunakan URL GitHub atau GitLab yang valid.'
            : null;
    state = AddAssetState(status: AddAssetStatus.validating, urlError: error, isUrlValid: error == null);
  }

  Future<void> submit(String repositoryUrl) async {
    validateRepositoryUrl(repositoryUrl);
    if (state.urlError != null || state.status == AddAssetStatus.submitting) return;
    state = const AddAssetState(status: AddAssetStatus.submitting);
    try {
      await ref.read(assetRepositoryProvider).addAsset(arg, repositoryUrl.trim());
      ref.read(assetListProvider(arg).notifier).refresh();
      state = const AddAssetState(status: AddAssetStatus.success);
    } catch (_) {
      state = const AddAssetState(status: AddAssetStatus.failure, submitError: 'Aset gagal ditambahkan. Silakan coba lagi.', isUrlValid: true);
    }
  }

  void showDemoSubmitting() {
    state = const AddAssetState(status: AddAssetStatus.submitting, isUrlValid: true);
  }
}
