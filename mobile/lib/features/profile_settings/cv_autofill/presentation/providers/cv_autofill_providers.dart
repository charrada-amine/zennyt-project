import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../core/network/dio_client.dart';
import '../../data/cv_ocr_service.dart';
import '../../data/cv_parse_api_service.dart';
import '../../data/cv_autofill_repository.dart';
import '../viewmodel/cv_autofill_viewmodel.dart';

final cvOcrServiceProvider = Provider<CvOcrService>((ref) {
  final service = CvOcrService();
  ref.onDispose(() => service.dispose());
  return service;
});

final cvParseApiServiceProvider = Provider<CvParseApiService>((ref) {
  final dio = ref.watch(dioProvider);
  return CvParseApiService(dio);
});

final cvAutofillRepositoryProvider = Provider<CvAutofillRepository>((ref) {
  return CvAutofillRepository(
    ref.watch(cvOcrServiceProvider),
    ref.watch(cvParseApiServiceProvider),
  );
});

final cvAutofillViewModelProvider = NotifierProvider<CvAutofillViewModel, CvAutofillState>(() {
  return CvAutofillViewModel();
});
