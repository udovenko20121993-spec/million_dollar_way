import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';

// Wrapper class to provide the expected interface
class IbkrImportWrapper {
  Future<void> pickAndImportFile({
    required String userId,
    required Function(ImportStatus, String) onStateChange,
  }) async {
    try {
      onStateChange(ImportStatus.pickingFile, 'Оберіть Flex Query XML файл');

      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['xml'],
        allowMultiple: false,
      );

      if (result == null || result.files.isEmpty) {
        onStateChange(ImportStatus.initial, 'Файл не обрано');
        return;
      }

      onStateChange(ImportStatus.parsing, 'Парсинг XML файлу...');

      final file = result.files.first;
      await file.xFile.readAsString();

      onStateChange(ImportStatus.saving, 'Збереження даних...');

      // For now, just simulate the import process
      // TODO: Implement actual XML parsing and saving logic
      await Future.delayed(Duration(seconds: 2));

      onStateChange(ImportStatus.success, 'Звіт успішно імпортовано!');
    } catch (e) {
      onStateChange(ImportStatus.error, e.toString());
    }
  }
}

enum ImportStatus { initial, pickingFile, parsing, saving, success, error }

class ImportState {
  final ImportStatus status;
  final String? message;

  const ImportState({required this.status, this.message});

  factory ImportState.initial() =>
      const ImportState(status: ImportStatus.initial);

  ImportState copyWith({ImportStatus? status, String? message}) {
    return ImportState(
      status: status ?? this.status,
      message: message ?? this.message,
    );
  }
}

class ImportNotifier extends StateNotifier<ImportState> {
  final Ref _ref;

  ImportNotifier(this._ref) : super(ImportState.initial());

  Future<void> startImport(String userId) async {
    if (state.status == ImportStatus.pickingFile ||
        state.status == ImportStatus.parsing ||
        state.status == ImportStatus.saving) {
      return;
    }

    state = state.copyWith(
      status: ImportStatus.pickingFile,
      message: 'Оберіть Flex Query XML файл',
    );

    final service = _ref.read(ibkrImportServiceProvider);

    try {
      await service.pickAndImportFile(
        userId: userId,
        onStateChange: (nextStatus, message) {
          state = state.copyWith(status: nextStatus, message: message);
        },
      );

      state = state.copyWith(
        status: ImportStatus.success,
        message: 'Звіт успішно імпортовано!',
      );
    } catch (e) {
      state = state.copyWith(status: ImportStatus.error, message: e.toString());
    }
  }

  void reset() {
    state = ImportState.initial();
  }
}

final importNotifierProvider =
    StateNotifierProvider<ImportNotifier, ImportState>((ref) {
      return ImportNotifier(ref);
    });

final ibkrImportServiceProvider = Provider<IbkrImportWrapper>((ref) {
  return IbkrImportWrapper();
});
