import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:io';
import '../services/ibkr_parsing_service.dart';
import '../domain/models/upload_log_model.dart';
import '../domain/models/transaction_model.dart';

// Current user ID provider (implement based on your auth system)
final currentUserIdProvider = Provider<String>((ref) {
  // TODO: Get actual user ID from auth service
  return 'default_user';
});

// Upload history stream provider
final uploadHistoryProvider = StreamProvider<List<UploadLogModel>>((ref) {
  final userId = ref.watch(currentUserIdProvider);
  return IbkrParsingService.getUploadHistory(userId);
});

// Current upload status provider (for real-time updates)
final currentUploadStatusProvider = StreamProvider<UploadLogModel?>((ref) {
  final userId = ref.watch(currentUserIdProvider);
  return IbkrParsingService.getUploadHistory(
    userId,
  ).map((uploads) => uploads.isNotEmpty ? uploads.first : null);
});

// Upload action provider
class UploadNotifier extends AsyncNotifier<UploadLogModel> {
  @override
  UploadLogModel build() {
    throw UnimplementedError('Use uploadFile or parseAndBatchSave methods');
  }

  Future<UploadLogModel> uploadFile(String filePath) async {
    state = const AsyncLoading();

    try {
      final userId = ref.read(currentUserIdProvider);
      final file = File(filePath);

      final result = await IbkrParsingService.uploadFile(
        userId: userId,
        file: file,
      );

      state = AsyncData(result);
      return result;
    } catch (e, stackTrace) {
      state = AsyncError(e, stackTrace);
      rethrow;
    }
  }

  Future<UploadLogModel> parseAndBatchSave({
    required String xmlContent,
    required UploadSourceType sourceType,
    String? fileName,
    String? queryId,
  }) async {
    state = const AsyncLoading();

    try {
      final userId = ref.read(currentUserIdProvider);

      final result = await IbkrParsingService.parseAndBatchSave(
        xmlContent: xmlContent,
        userId: userId,
        sourceType: sourceType,
        fileName: fileName,
        queryId: queryId,
      );

      state = AsyncData(result);
      return result;
    } catch (e, stackTrace) {
      state = AsyncError(e, stackTrace);
      rethrow;
    }
  }
}

final uploadNotifierProvider =
    AsyncNotifierProvider<UploadNotifier, UploadLogModel>(
      () => UploadNotifier(),
    );

// Transactions by account provider
final transactionsByAccountProvider =
    FutureProvider.family<List<TransactionModel>, String>((
      ref,
      accountId,
    ) async {
      final userId = ref.read(currentUserIdProvider);
      return IbkrParsingService.getTransactionsByAccount(
        userId: userId,
        accountId: accountId,
      );
    });

// User account IDs provider
final userAccountIdsProvider = FutureProvider<List<String>>((ref) async {
  final userId = ref.read(currentUserIdProvider);
  return IbkrParsingService.getUserAccountIds(userId);
});

// Upload statistics provider
final uploadStatsProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final userId = ref.read(currentUserIdProvider);
  return IbkrParsingService.getAccountUploadStats(userId);
});

// Recent uploads provider (last 5 uploads)
final recentUploadsProvider = StreamProvider<List<UploadLogModel>>((ref) {
  final userId = ref.watch(currentUserIdProvider);
  return FirebaseFirestore.instance
      .collection('users')
      .doc(userId)
      .collection('uploads')
      .orderBy('timestamp', descending: true)
      .limit(5)
      .snapshots()
      .map(
        (snapshot) => snapshot.docs
            .map((doc) => UploadLogModel.fromFirestore(doc))
            .toList(),
      );
});

// Upload status summary provider
final uploadStatusSummaryProvider = Provider<Map<String, int>>((ref) {
  final uploadHistory = ref.watch(uploadHistoryProvider);

  return uploadHistory.when(
    data: (uploads) {
      final summary = <String, int>{
        'pending': 0,
        'processing': 0,
        'completed': 0,
        'error': 0,
      };

      for (final upload in uploads) {
        summary[upload.status.name] = (summary[upload.status.name] ?? 0) + 1;
      }

      return summary;
    },
    loading: () => {'pending': 0, 'processing': 0, 'completed': 0, 'error': 0},
    error: (_, __) => {
      'pending': 0,
      'processing': 0,
      'completed': 0,
      'error': 0,
    },
  );
});

// Individual upload progress provider
final uploadProgressProvider = StreamProvider.family<UploadLogModel?, String>((
  ref,
  uploadId,
) {
  final userId = ref.read(currentUserIdProvider);
  return FirebaseFirestore.instance
      .collection('users')
      .doc(userId)
      .collection('uploads')
      .doc(uploadId)
      .snapshots()
      .map((doc) => doc.exists ? UploadLogModel.fromFirestore(doc) : null);
});

// Flex Query settings provider (implement based on your settings system)
final flexQuerySettingsProvider = FutureProvider<Map<String, String>?>((
  ref,
) async {
  // TODO: Implement getting user's Flex Query settings
  // This should return { 'token': '...', 'queryId': '...' }
  return null;
});

// File upload state provider
class FileUploadState {
  final bool isUploading;
  final String uploadStatus;
  final String? selectedFilePath;

  const FileUploadState({
    this.isUploading = false,
    this.uploadStatus = '',
    this.selectedFilePath,
  });

  FileUploadState copyWith({
    bool? isUploading,
    String? uploadStatus,
    String? selectedFilePath,
  }) {
    return FileUploadState(
      isUploading: isUploading ?? this.isUploading,
      uploadStatus: uploadStatus ?? this.uploadStatus,
      selectedFilePath: selectedFilePath ?? this.selectedFilePath,
    );
  }
}

class FileUploadNotifier extends StateNotifier<FileUploadState> {
  FileUploadNotifier() : super(const FileUploadState());

  void setSelectedFile(String? filePath) {
    state = state.copyWith(selectedFilePath: filePath);
  }

  void setUploading(bool uploading) {
    state = state.copyWith(isUploading: uploading);
  }

  void setUploadStatus(String status) {
    state = state.copyWith(uploadStatus: status);
  }

  void reset() {
    state = const FileUploadState();
  }
}

final fileUploadProvider =
    StateNotifierProvider<FileUploadNotifier, FileUploadState>(
      (ref) => FileUploadNotifier(),
    );

// Auto-sync status provider
final autoSyncStatusProvider = StateProvider<bool>((ref) {
  return false; // Default: auto-sync disabled
});

// Last sync time provider
final lastSyncTimeProvider = Provider<DateTime?>((ref) {
  final recentUploads = ref.watch(recentUploadsProvider);

  return recentUploads.when(
    data: (uploads) {
      final flexUploads = uploads.where(
        (u) => u.sourceType == UploadSourceType.flex_auto,
      );
      return flexUploads.isNotEmpty ? flexUploads.first.timestamp : null;
    },
    loading: () => null,
    error: (_, __) => null,
  );
});
