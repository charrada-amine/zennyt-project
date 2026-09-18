import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zennyt/features/wallet/domain/card_input.dart';

TextEditingValue _type(TextInputFormatter f, String old, String next) => f.formatEditUpdate(
      TextEditingValue(text: old, selection: TextSelection.collapsed(offset: old.length)),
      TextEditingValue(text: next, selection: TextSelection.collapsed(offset: next.length)),
    );

void main() {
  group('brand detection', () {
    test('recognises the major networks from their prefix', () {
      expect(CardBrand.detect('4242'), CardBrand.visa);
      expect(CardBrand.detect('5555'), CardBrand.mastercard);
      expect(CardBrand.detect('2223'), CardBrand.mastercard);
      expect(CardBrand.detect('3782'), CardBrand.amex);
      expect(CardBrand.detect('6011'), CardBrand.discover);
      expect(CardBrand.detect('9999'), CardBrand.unknown);
    });

    test('maps the server brand names', () {
      expect(CardBrand.fromServer('VISA'), CardBrand.visa);
      expect(CardBrand.fromServer('MasterCard'), CardBrand.mastercard);
      expect(CardBrand.fromServer('AMERICAN_EXPRESS'), CardBrand.amex);
      expect(CardBrand.fromServer(null), CardBrand.unknown);
    });
  });

  group('card number', () {
    final f = CardNumberInputFormatter();

    test('keeps digits only and groups them by 4', () {
      expect(_type(f, '', '4242a4242-4242 4242').text, '4242 4242 4242 4242');
    });

    test('groups American Express as 4-6-5 and caps it at 15 digits', () {
      expect(_type(f, '', '3782822463100051234').text, '3782 822463 10005');
    });

    test('caps Mastercard at 16 digits', () {
      expect(_type(f, '', '55555555555544449').text, '5555 5555 5555 4444');
    });

    test('validates length and the Luhn check digit', () {
      expect(CardInput.validateNumber(''), isNotNull);
      expect(CardInput.validateNumber('4242 4242 4242'), 'Card number is incomplete');
      expect(CardInput.validateNumber('4242 4242 4242 4241'), 'This card number is not valid');
      expect(CardInput.validateNumber('4242 4242 4242 4242'), isNull);
      expect(CardInput.validateNumber('3782 822463 10005'), isNull);
    });
  });

  group('expiry', () {
    final f = ExpiryInputFormatter();
    final now = DateTime(2026, 9, 18);

    test('inserts the slash and pads a single-digit month', () {
      expect(_type(f, '', '12').text, '12/');
      expect(_type(f, '', '4').text, '04/');
      expect(_type(f, '12/', '12/2').text, '12/2');
      expect(_type(f, '', '1228').text, '12/28');
      expect(_type(f, '', '12289').text, '12/28');
    });

    test('lets the user delete through the slash', () {
      expect(_type(f, '12/', '12').text, '12');
    });

    test('rejects impossible months and past dates, accepts this month', () {
      expect(CardInput.validateExpiry('13/28', now: now), 'Month must be between 01 and 12');
      expect(CardInput.validateExpiry('08/26', now: now), 'This card has expired');
      expect(CardInput.validateExpiry('09/26', now: now), isNull);
      expect(CardInput.validateExpiry('12/3', now: now), 'Use the MM/YY format');
    });
  });

  test('security code length follows the brand', () {
    expect(CardInput.validateCvc('123', CardBrand.visa), isNull);
    expect(CardInput.validateCvc('12', CardBrand.visa), 'The security code has 3 digits');
    expect(CardInput.validateCvc('123', CardBrand.amex), 'The security code has 4 digits');
    expect(CardInput.validateCvc('1234', CardBrand.amex), isNull);
  });

  test('cardholder name accepts letters, accents, hyphens and apostrophes only', () {
    expect(CardInput.validateName("Yassine Ben-Ali O'Neil"), isNull);
    expect(CardInput.validateName('Sarra Ben Ali'), isNull);
    expect(CardInput.validateName('Hélène Dupré'), isNull);
    expect(CardInput.validateName('J0hn'), 'Letters only, please');
    expect(CardInput.validateName(' '), "Enter the cardholder's name");
  });
}
