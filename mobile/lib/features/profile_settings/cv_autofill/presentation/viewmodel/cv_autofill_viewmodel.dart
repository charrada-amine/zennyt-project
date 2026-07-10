import 'dart:io';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/cv_parsed_data.dart';
import '../providers/cv_autofill_providers.dart';

class CvAutofillState {
  final bool isLoading;
  final String? error;
  final CvParsedData? data;

  CvAutofillState({this.isLoading = false, this.error, this.data});

  CvAutofillState copyWith({bool? isLoading, String? error, CvParsedData? data}) {
    return CvAutofillState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
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
    state = state.copyWith(isLoading: true, error: null);
    try {
      final repository = ref.read(cvAutofillRepositoryProvider);
      final parsedData = await repository.processLocalFile(filePath, languageCode);
      state = state.copyWith(isLoading: false, data: parsedData);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> processRemoteFile(String url, String languageCode) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final dir = await getTemporaryDirectory();
      final tempFilePath = '${dir.path}/temp_cv_download_${DateTime.now().millisecondsSinceEpoch}.pdf';
      
      final dio = Dio();
      await dio.download(url, tempFilePath);
      
      final repository = ref.read(cvAutofillRepositoryProvider);
      final parsedData = await repository.processLocalFile(tempFilePath, languageCode);
      
      // Clean up the temp file
      final file = File(tempFilePath);
      if (await file.exists()) {
        await file.delete();
      }

      state = state.copyWith(isLoading: false, data: parsedData);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> processCameraImages(List<String> imagePaths, String languageCode) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final repository = ref.read(cvAutofillRepositoryProvider);
      final parsedData = await repository.processCameraImages(imagePaths, languageCode);
      state = state.copyWith(isLoading: false, data: parsedData);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  void reset() {
    state = CvAutofillState();
  }
}
