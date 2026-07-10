import 'dart:io';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';

class CvOcrService {
  final TextRecognizer _textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);

  Future<String> extractTextFromImages(List<String> imagePaths) async {
    final buffer = StringBuffer();
    for (final path in imagePaths) {
      final inputImage = InputImage.fromFilePath(path);
      final recognizedText = await _textRecognizer.processImage(inputImage);
      buffer.writeln(recognizedText.text);
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
    await _textRecognizer.close();
  }
}
