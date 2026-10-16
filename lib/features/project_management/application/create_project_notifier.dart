import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../services/api_error_mapper.dart';
import 'project_list_notifier.dart';

enum CreateProjectStatus { idle, submitting, success, failure }

class CreateProjectState {
  const CreateProjectState({
    this.status = CreateProjectStatus.idle,
    this.nameError,
    this.submitError,
    this.isNameValid = false,
  });
  final CreateProjectStatus status;
  final String? nameError;
  final String? submitError;
  final bool isNameValid;
  bool get canSubmit => isNameValid && status != CreateProjectStatus.submitting;
}

final createProjectProvider =
    NotifierProvider<CreateProjectNotifier, CreateProjectState>(
        CreateProjectNotifier.new);

class CreateProjectNotifier extends Notifier<CreateProjectState> {
  @override
  CreateProjectState build() => const CreateProjectState();

  void reset() => state = const CreateProjectState();

  void validateName(String value) {
    final name = value.trim();
    final error = name.isEmpty ? 'Nama proyek wajib diisi.' : null;
    state = CreateProjectState(
      status: state.status,
      nameError: error,
      submitError: state.submitError,
      isNameValid: error == null,
    );
  }

  Future<void> submit(
      {required String name, required String description}) async {
    validateName(name);
    if (state.nameError != null ||
        state.status == CreateProjectStatus.submitting) {
      return;
    }
    state = const CreateProjectState(status: CreateProjectStatus.submitting);
    try {
      await ref.read(projectRepositoryProvider).createProject(
            name: name.trim(),
            description: description.trim(),
          );
      await ref.read(projectListProvider.notifier).refresh();
      state = const CreateProjectState(status: CreateProjectStatus.success);
    } on DioException catch (error) {
      state = CreateProjectState(
          status: CreateProjectStatus.failure,
          submitError: mapApiErrorToMessage(error),
          isNameValid: true);
    } catch (_) {
      state = const CreateProjectState(
          status: CreateProjectStatus.failure,
          submitError: 'Proyek gagal dibuat. Silakan coba lagi.',
          isNameValid: true);
    }
  }
}
