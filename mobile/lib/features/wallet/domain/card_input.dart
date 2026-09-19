import 'package:flutter/services.dart';

/// Réseaux de carte reconnus à la saisie (préfixes IIN publics).
enum CardBrand {
  visa('Visa', cvcLength: 3, maxDigits: 19),
  mastercard('Mastercard', cvcLength: 3, maxDigits: 16),
  amex('American Express', cvcLength: 4, maxDigits: 15),
  discover('Discover', cvcLength: 3, maxDigits: 19),
  unknown('Card', cvcLength: 3, maxDigits: 19);

  const CardBrand(this.label, {required this.cvcLength, required this.maxDigits});

  final String label;
  final int cvcLength;
  final int maxDigits;

  /// Longueurs de numéro valides pour ce réseau.
  List<int> get validLengths => switch (this) {
        CardBrand.visa => const [13, 16, 19],
        CardBrand.mastercard => const [16],
        CardBrand.amex => const [15],
        CardBrand.discover => const [16, 19],
        CardBrand.unknown => const [13, 14, 15, 16, 17, 18, 19],
      };

  /// Réseau d'après les premiers chiffres saisis.
  static CardBrand detect(String digits) {
    if (digits.isEmpty) return CardBrand.unknown;
    if (digits.startsWith('4')) return CardBrand.visa;
    if (RegExp(r'^3[47]').hasMatch(digits)) return CardBrand.amex;
    if (RegExp(r'^(6011|65|64[4-9])').hasMatch(digits)) return CardBrand.discover;
    if (digits.length >= 2) {
      final two = int.parse(digits.substring(0, 2));
      if (two >= 51 && two <= 55) return CardBrand.mastercard;
    }
    if (digits.length >= 4) {
      final four = int.parse(digits.substring(0, 4));
      if (four >= 2221 && four <= 2720) return CardBrand.mastercard;
    }
    return CardBrand.unknown;
  }

  /// Réseau renvoyé par le serveur (`VISA`, `MASTERCARD`…), pour la carte enregistrée.
  static CardBrand fromServer(String? value) {
    final v = (value ?? '').toUpperCase().replaceAll(RegExp(r'[^A-Z]'), '');
    if (v.contains('VISA')) return CardBrand.visa;
    if (v.contains('MASTER')) return CardBrand.mastercard;
    if (v.contains('AMEX') || v.contains('AMERICAN')) return CardBrand.amex;
    if (v.contains('DISCOVER')) return CardBrand.discover;
    return CardBrand.unknown;
  }
}

/// Règles de saisie d'une carte, sans Flutter : testables unitairement.
abstract final class CardInput {
  static String digitsOnly(String value) => value.replaceAll(RegExp(r'\D'), '');

  /// Groupes d'affichage : 4-6-5 pour American Express, 4-4-4-4(-3) sinon.
  static List<int> groups(CardBrand brand) =>
      brand == CardBrand.amex ? const [4, 6, 5] : const [4, 4, 4, 4, 3];

  /// Numéro formaté par groupes, ex. `4242 4242 4242 4242`.
  static String formatNumber(String digits) {
    final brand = CardBrand.detect(digits);
    final buffer = StringBuffer();
    var index = 0;
    for (final size in groups(brand)) {
      if (index >= digits.length) break;
      if (buffer.isNotEmpty) buffer.write(' ');
      final end = (index + size).clamp(0, digits.length);
      buffer.write(digits.substring(index, end));
      index = end;
    }
    return buffer.toString();
  }

  /// Algorithme de Luhn (clé de contrôle des numéros de carte).
  static bool luhn(String digits) {
    if (digits.isEmpty) return false;
    var sum = 0;
    var doubleIt = false;
    for (var i = digits.length - 1; i >= 0; i--) {
      var d = digits.codeUnitAt(i) - 48;
      if (doubleIt) {
        d *= 2;
        if (d > 9) d -= 9;
      }
      sum += d;
      doubleIt = !doubleIt;
    }
    return sum % 10 == 0;
  }

  static String? validateNumber(String value) {
    final digits = digitsOnly(value);
    if (digits.isEmpty) return 'Enter your card number';
    final brand = CardBrand.detect(digits);
    if (!brand.validLengths.contains(digits.length)) {
      return 'Card number is incomplete';
    }
    if (!luhn(digits)) return 'This card number is not valid';
    return null;
  }

  /// `MM/YY` → (mois, année sur 4 chiffres), ou null si incomplet.
  static (int, int)? parseExpiry(String value) {
    final digits = digitsOnly(value);
    if (digits.length != 4) return null;
    final month = int.parse(digits.substring(0, 2));
    final year = 2000 + int.parse(digits.substring(2));
    return (month, year);
  }

  static String? validateExpiry(String value, {DateTime? now}) {
    if (digitsOnly(value).isEmpty) return 'Enter the expiry date';
    final parsed = parseExpiry(value);
    if (parsed == null) return 'Use the MM/YY format';
    final (month, year) = parsed;
    if (month < 1 || month > 12) return 'Month must be between 01 and 12';
    final today = now ?? DateTime.now();
    // Une carte reste valide jusqu'au dernier jour de son mois d'expiration.
    final firstDayAfterExpiry = DateTime(year, month + 1);
    if (!today.isBefore(firstDayAfterExpiry)) return 'This card has expired';
    if (year > today.year + 20) return 'Check the expiry year';
    return null;
  }

  static String? validateCvc(String value, CardBrand brand) {
    final digits = digitsOnly(value);
    if (digits.isEmpty) return 'Enter the security code';
    if (digits.length != brand.cvcLength) {
      return 'The security code has ${brand.cvcLength} digits';
    }
    return null;
  }

  static final RegExp _nameChars = RegExp(r"^[A-Za-zÀ-ÖØ-öø-ÿ' .\-]+$");

  static String? validateName(String value) {
    final name = value.trim();
    if (name.isEmpty) return "Enter the cardholder's name";
    if (!_nameChars.hasMatch(name)) return 'Letters only, please';
    if (name.replaceAll(RegExp(r'[^A-Za-zÀ-ÖØ-öø-ÿ]'), '').length < 2) {
      return 'Name is too short';
    }
    return null;
  }
}

/// Numéro de carte : chiffres uniquement, groupés, longueur maximale du réseau.
class CardNumberInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    var digits = CardInput.digitsOnly(newValue.text);
    final max = CardBrand.detect(digits).maxDigits;
    if (digits.length > max) digits = digits.substring(0, max);
    final text = CardInput.formatNumber(digits);
    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }
}

/// Date d'expiration : `MM/YY`, barre insérée automatiquement, mois complété
/// (« 4 » → « 04/ ») pour ne jamais accepter un mois 13+.
class ExpiryInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    var digits = CardInput.digitsOnly(newValue.text);
    final deleting = newValue.text.length < oldValue.text.length;
    if (digits.length == 1 && int.parse(digits) > 1 && !deleting) digits = '0$digits';
    if (digits.length > 4) digits = digits.substring(0, 4);
    String text;
    if (digits.length >= 3) {
      text = '${digits.substring(0, 2)}/${digits.substring(2)}';
    } else if (digits.length == 2 && !deleting) {
      text = '$digits/';
    } else {
      text = digits;
    }
    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }
}
