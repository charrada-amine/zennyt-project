import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter_native_ocr/flutter_native_ocr.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdfrx/pdfrx.dart' as pdfrx;
import 'package:syncfusion_flutter_pdf/pdf.dart' as syncfusion;

class CvOcrService {
  // PROVISOIRE — à valider : guardrails for on-device scanned-PDF OCR.
  static const int maximumScannedPdfPages = 10;
  static const double scannedPdfDpi = 150;
  static const double maximumRenderedPageDimension = 2048;

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
    final file = File(pdfPath);
    final bytes = await file.readAsBytes();
    final document = syncfusion.PdfDocument(inputBytes: bytes);
    try {
      // Extract text directly from the PDF
      final textExtractor = syncfusion.PdfTextExtractor(document);
      final text = textExtractor.extractText();
      if (text.trim().isNotEmpty) return text;

      return await _extractScannedPdfText(pdfPath);
    } finally {
      document.dispose();
    }
  }

  /// Renders scanned PDF pages to temporary PNG files, then sends every page
  /// through the native OCR implementation (Vision on iOS, ML Kit on Android).
  Future<String> _extractScannedPdfText(String pdfPath) async {
    await pdfrx.pdfrxInitialize();
    final document = await pdfrx.PdfDocument.openFile(pdfPath);
    final temporaryDirectory = await getTemporaryDirectory();
    final generatedPaths = <String>[];

    try {
      if (document.pages.length > maximumScannedPdfPages) {
        throw Exception(
          'Scanned CVs can contain at most $maximumScannedPdfPages pages.',
        );
      }

      final text = StringBuffer();
      for (final page in document.pages) {
        final scale = math.min(
          scannedPdfDpi / 72,
          maximumRenderedPageDimension / math.max(page.width, page.height),
        );
        final image = await page.render(
          fullWidth: page.width * scale,
          fullHeight: page.height * scale,
        );
        if (image == null) continue;

        try {
          final pngBytes = await _encodePng(image);
          final pagePath =
              '${temporaryDirectory.path}/cv_ocr_${DateTime.now().microsecondsSinceEpoch}_${page.pageNumber}.png';
          await File(pagePath).writeAsBytes(pngBytes, flush: true);
          generatedPaths.add(pagePath);
          text.writeln(await _ocr.recognizeText(pagePath));
          text.writeln('\n--- PAGE BREAK ---\n');
        } finally {
          image.dispose();
        }
      }
      return text.toString();
    } finally {
      await document.dispose();
      for (final path in generatedPaths) {
        final file = File(path);
        if (await file.exists()) {
          await file.delete();
        }
      }
    }
  }

  Future<List<int>> _encodePng(pdfrx.PdfImage image) async {
    final completer = Completer<ui.Image>();
    ui.decodeImageFromPixels(
      image.pixels,
      image.width,
      image.height,
      ui.PixelFormat.bgra8888,
      completer.complete,
      rowBytes: image.width * 4,
    );
    final decoded = await completer.future;
    try {
      final byteData = await decoded.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) {
        throw Exception('Unable to encode scanned CV page.');
      }
      return byteData.buffer.asUint8List();
    } finally {
      decoded.dispose();
    }
  }

  Future<void> dispose() async {
    // Apple Vision / ML Kit natif ne nécessite pas de libération explicite.
  }
}
