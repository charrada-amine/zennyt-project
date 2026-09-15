import 'package:flutter_test/flutter_test.dart';
import 'package:zennyt/features/auth/domain/entities/legal_document.dart';

void main() {
  group('LegalDocument.fromJson', () {
    test('parses title, date and sections', () {
      final document = LegalDocument.fromJson({
        'slug': 'terms-of-use',
        'title': 'Terms of Use & Conditions',
        'lastUpdated': 'September 10, 2025',
        'sections': [
          {'heading': '1. Legal Notice', 'body': 'Company Name: Progress Careers'},
          {'heading': '2. Introduction', 'body': 'Welcome'},
        ],
      });

      expect(document.slug, 'terms-of-use');
      expect(document.title, 'Terms of Use & Conditions');
      expect(document.lastUpdated, 'September 10, 2025');
      expect(document.sections, hasLength(2));
      expect(document.sections.first.heading, '1. Legal Notice');
    });

    test('missing sections fall back to an empty list', () {
      final document = LegalDocument.fromJson({'slug': 'x', 'title': 'Y'});
      expect(document.sections, isEmpty);
    });
  });
}
