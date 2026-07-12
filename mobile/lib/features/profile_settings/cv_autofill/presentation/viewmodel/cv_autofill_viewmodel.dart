import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../core/network/dio_client.dart';
import '../../domain/cv_parsed_data.dart';
import '../providers/cv_autofill_providers.dart';

class CvAutofillState {
  final bool isLoading;
  final String? error;
  final CvParsedData? data;

  CvAutofillState({this.isLoading = false, this.error, this.data});

  CvAutofillState copyWith({
    bool? isLoading,
    String? error,
    CvParsedData? data,
    bool clearError = false,
  }) {
    return CvAutofillState(
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : error ?? this.error,
      data: data ?? this.data,
    );
  }
}

class CvAutofillViewModel extends Notifier<CvAutofillState> {
  @override
  CvAutofillState build() {
    return CvAutofillState();
  }

  Future<void> processLocalFile(String filePath, String languageCode) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final repository = ref.read(cvAutofillRepositoryProvider);
      final parsedData = await repository.processLocalFile(
        filePath,
        languageCode,
      );
      state = state.copyWith(isLoading: false, data: parsedData);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> processRemoteFile(String url, String languageCode) async {
    state = state.copyWith(isLoading: true, clearError: true);
    String? tempFilePath;
    try {
      final dir = await getTemporaryDirectory();
      tempFilePath =
          '${dir.path}/temp_cv_download_${DateTime.now().millisecondsSinceEpoch}.pdf';

      final dio = ref.read(dioProvider);
      await dio.download(url, tempFilePath);

      final repository = ref.read(cvAutofillRepositoryProvider);
      final parsedData = await repository.processLocalFile(
        tempFilePath,
        languageCode,
      );
      state = state.copyWith(isLoading: false, data: parsedData);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    } finally {
      final file = tempFilePath == null ? null : File(tempFilePath);
      if (file != null && await file.exists()) {
        await file.delete();
      }
    }
  }

  Future<void> processCameraImages(
    List<String> imagePaths,
    String languageCode,
  ) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final repository = ref.read(cvAutofillRepositoryProvider);
      final parsedData = await repository.processCameraImages(
        imagePaths,
        languageCode,
      );
      state = state.copyWith(isLoading: false, data: parsedData);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  void reset() {
    state = CvAutofillState();
  }
}
