import 'package:path/path.dart' as p;

import '../domain/cv_parsed_data.dart';
import 'cv_ocr_service.dart';
import 'cv_parse_api_service.dart';

class CvAutofillRepository {
  final CvOcrService _ocrService;
  final CvParseApiService _apiService;

  CvAutofillRepository(this._ocrService, this._apiService);

  Future<CvParsedData> processLocalFile(String filePath, String languageCode) async {
    final extension = p.extension(filePath).toLowerCase();
    String extractedText = '';

    if (extension == '.pdf') {
      extractedText = await _ocrService.extractTextFromPdf(filePath);
    } else if (extension == '.png' || extension == '.jpg' || extension == '.jpeg' || extension == '.webp') {
      extractedText = await _ocrService.extractTextFromImages([filePath]);
    } else {
      throw Exception('Format de fichier non supporté pour l\'extraction locale.');
    }

    if (extractedText.trim().isEmpty) {
      throw Exception('Aucun texte n\'a pu être extrait du document.');
    }

    // Call backend to parse text
    return await _apiService.parseCvData(extractedText, languageCode);
  }

  Future<CvParsedData> processCameraImages(List<String> imagePaths, String languageCode) async {
    if (imagePaths.isEmpty) {
      throw Exception('Aucune image fournie.');
    }

    final extractedText = await _ocrService.extractTextFromImages(imagePaths);
    
    if (extractedText.trim().isEmpty) {
      throw Exception('Aucun texte n\'a pu être extrait des images.');
    }

    return await _apiService.parseCvData(extractedText, languageCode);
  }
}
