import 'dart:io';
import 'package:flutter_native_ocr/flutter_native_ocr.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';

class CvOcrService {
  // OCR natif : Apple Vision sur iOS/macOS, Google ML Kit sur Android.
  // Contrairement à google_mlkit_text_recognition, cette approche n'embarque
  // aucun pod ML Kit côté iOS (Vision est un framework système), ce qui permet
  // de compiler sur le simulateur arm64 (iOS 26+ / Apple Silicon).
  final FlutterNativeOcr _ocr = FlutterNativeOcr();

  Future<String> extractTextFromImages(List<String> imagePaths) async {
    final buffer = StringBuffer();
    for (final path in imagePaths) {
      final recognizedText = await _ocr.recognizeText(path);
      buffer.writeln(recognizedText);
      buffer.writeln('\n--- PAGE BREAK ---\n');
    }
    return buffer.toString();
  }

  Future<String> extractTextFromPdf(String pdfPath) async {
    try {
      final file = File(pdfPath);
      final bytes = await file.readAsBytes();
      // Load the PDF document
      final document = PdfDocument(inputBytes: bytes);
      
      // Extract text directly from the PDF
      final textExtractor = PdfTextExtractor(document);
      final text = textExtractor.extractText();
      
      document.dispose();
      
      if (text.trim().isEmpty) {
        // If it's an image-based PDF (like a scanned photo), Syncfusion won't extract text.
        // For a full implementation, you could fallback to pdfrx to render the pages to images and run MLKit OCR.
        // However, 99% of modern CVs have embedded text layers.
        return "";
      }
      return text;
    } catch (e) {
      return "";
    }
  }

  Future<void> dispose() async {
    // Apple Vision / ML Kit natif ne nécessite pas de libération explicite.
  }
}
