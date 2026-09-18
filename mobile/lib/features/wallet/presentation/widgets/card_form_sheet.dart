import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zennyt/core/error/api_exception.dart';
import 'package:zennyt/core/theme/theme.dart';
import 'package:zennyt/features/wallet/presentation/providers/wallet_providers.dart';
import 'package:zennyt/shared/icons/app_icons.dart';

import '../../domain/card_input.dart';
import 'payment_card_view.dart';

/// Ajout / remplacement de la carte (maquettes 107/119).
///
/// La carte se dessine en direct pendant la saisie et se retourne sur le CVC.
/// Chaque champ est formaté et vérifié à la frappe (réseau, longueur, clé de
/// Luhn, MM/YY non expiré, CVC du bon nombre de chiffres, nom en lettres) ;
/// « Save card » reste inactif tant que tout n'est pas valide. Le numéro complet
/// et le CVC partent au serveur mais n'y sont pas stockés.
Future<void> showCardFormSheet(BuildContext context, {required bool hasCard}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    builder: (_) => CardFormSheet(hasCard: hasCard),
  );
}

class CardFormSheet extends ConsumerStatefulWidget {
  const CardFormSheet({super.key, required this.hasCard});

  final bool hasCard;

  @override
  ConsumerState<CardFormSheet> createState() => _CardFormSheetState();
}

class _CardFormSheetState extends ConsumerState<CardFormSheet> {
  final _number = TextEditingController();
  final _expiry = TextEditingController();
  final _cvc = TextEditingController();
  final _name = TextEditingController();
  final _cvcFocus = FocusNode();

  /// Champs déjà quittés une fois : l'erreur ne s'affiche qu'ensuite, pour ne pas
  /// crier « invalide » dès le premier chiffre.
  final _touched = <String>{};
  bool _busy = false;
  String? _serverError;

  @override
  void initState() {
    super.initState();
    for (final c in [_number, _expiry, _cvc, _name]) {
      c.addListener(() => setState(() {}));
    }
    _cvcFocus.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    for (final c in [_number, _expiry, _cvc, _name]) {
      c.dispose();
    }
    _cvcFocus.dispose();
    super.dispose();
  }

  CardBrand get _brand => CardBrand.detect(CardInput.digitsOnly(_number.text));

  String? get _numberError => CardInput.validateNumber(_number.text);
  String? get _expiryError => CardInput.validateExpiry(_expiry.text);
  String? get _cvcError => CardInput.validateCvc(_cvc.text, _brand);
  String? get _nameError => CardInput.validateName(_name.text);

  bool get _valid =>
      _numberError == null && _expiryError == null && _cvcError == null && _nameError == null;

  String? _shown(String field, String? error) => _touched.contains(field) ? error : null;

  Future<void> _save() async {
    setState(() => _touched.addAll(['number', 'expiry', 'cvc', 'name']));
    if (!_valid) return;
    final (month, year) = CardInput.parseExpiry(_expiry.text)!;
    setState(() {
      _busy = true;
      _serverError = null;
    });
    try {
      await ref.read(walletProvider.notifier).saveCard(
            cardNumber: CardInput.digitsOnly(_number.text),
            expiryMonth: month,
            expiryYear: year,
            cvv: CardInput.digitsOnly(_cvc.text),
            cardholderName: _name.text.trim(),
          );
      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(widget.hasCard ? 'Card updated' : 'Card added')),
      );
    } on ApiException catch (e) {
      if (mounted) setState(() => _serverError = e.message);
    } catch (_) {
      if (mounted) setState(() => _serverError = 'Could not save the card. Please try again.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: Container(
        decoration: BoxDecoration(
          color: colors.cardSurface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: SafeArea(
          top: false,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 42,
                    height: 5,
                    decoration: BoxDecoration(
                      color: colors.border,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  widget.hasCard ? 'Change your card' : 'Add your card',
                  style: AppTypography.titleLarge.copyWith(
                    color: colors.textPrimary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Used to withdraw your earnings. Your full card number is never stored.',
                  style: TextStyle(color: colors.textSecondary, fontSize: 13),
                ),
                const SizedBox(height: 18),
                Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 360),
                    child: PaymentCardView(
                      key: const ValueKey('card-form-preview'),
                      brand: _brand,
                      number: _number.text,
                      holder: _name.text,
                      expiry: _expiry.text,
                      cvc: CardInput.digitsOnly(_cvc.text),
                      showBack: _cvcFocus.hasFocus,
                    ),
                  ),
                ),
                const SizedBox(height: 22),
                _Field(
                  key: const ValueKey('card-number-field'),
                  controller: _number,
                  label: 'Card number',
                  hint: '1234 5678 9012 3456',
                  icon: HugeIcons.strokeRoundedCreditCard,
                  keyboardType: TextInputType.number,
                  formatters: [CardNumberInputFormatter()],
                  autofillHints: const [AutofillHints.creditCardNumber],
                  error: _shown('number', _numberError),
                  trailing: _brand == CardBrand.unknown
                      ? null
                      : Text(
                          _brand.label,
                          style: TextStyle(
                            color: colors.textSecondary,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                  onBlur: () => setState(() => _touched.add('number')),
                ),
                const SizedBox(height: 14),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: _Field(
                        key: const ValueKey('card-expiry-field'),
                        controller: _expiry,
                        label: 'Expiry',
                        hint: 'MM/YY',
                        icon: HugeIcons.strokeRoundedCalendar03,
                        keyboardType: TextInputType.number,
                        formatters: [ExpiryInputFormatter()],
                        autofillHints: const [AutofillHints.creditCardExpirationDate],
                        error: _shown('expiry', _expiryError),
                        onBlur: () => setState(() => _touched.add('expiry')),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _Field(
                        key: const ValueKey('card-cvc-field'),
                        controller: _cvc,
                        focusNode: _cvcFocus,
                        label: 'CVC',
                        hint: '•' * _brand.cvcLength,
                        icon: HugeIcons.strokeRoundedLockKey,
                        keyboardType: TextInputType.number,
                        obscure: true,
                        formatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(_brand.cvcLength),
                        ],
                        autofillHints: const [AutofillHints.creditCardSecurityCode],
                        error: _shown('cvc', _cvcError),
                        onBlur: () => setState(() => _touched.add('cvc')),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                _Field(
                  key: const ValueKey('card-name-field'),
                  controller: _name,
                  label: "Cardholder's name",
                  hint: 'As printed on the card',
                  icon: HugeIcons.strokeRoundedUser,
                  keyboardType: TextInputType.name,
                  capitalization: TextCapitalization.words,
                  formatters: [
                    FilteringTextInputFormatter.allow(RegExp(r"[A-Za-zÀ-ÖØ-öø-ÿ' .\-]")),
                    LengthLimitingTextInputFormatter(40),
                  ],
                  autofillHints: const [AutofillHints.creditCardName],
                  error: _shown('name', _nameError),
                  onBlur: () => setState(() => _touched.add('name')),
                  onSubmitted: (_) => _save(),
                ),
                if (_serverError != null) ...[
                  const SizedBox(height: 12),
                  Text(_serverError!, style: TextStyle(color: colors.error, fontSize: 13)),
                ],
                const SizedBox(height: 22),
                SizedBox(
                  height: 54,
                  child: FilledButton(
                    key: const ValueKey('card-save'),
                    onPressed: _valid && !_busy ? _save : null,
                    style: FilledButton.styleFrom(
                      backgroundColor: colors.primary,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    child: _busy
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(strokeWidth: 2.4, color: Colors.white),
                          )
                        : Text(
                            widget.hasCard ? 'Update card' : 'Save card',
                            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                          ),
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    AppIcon(HugeIcons.strokeRoundedLockKey, color: colors.textSecondary, size: 14),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        'Encrypted in transit · only the last 4 digits are kept',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: colors.textSecondary, fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Field extends StatefulWidget {
  const _Field({
    super.key,
    required this.controller,
    required this.label,
    required this.hint,
    required this.icon,
    required this.keyboardType,
    required this.formatters,
    required this.onBlur,
    this.focusNode,
    this.error,
    this.trailing,
    this.obscure = false,
    this.capitalization = TextCapitalization.none,
    this.autofillHints,
    this.onSubmitted,
  });

  final TextEditingController controller;
  final String label;
  final String hint;
  final AppIconData icon;
  final TextInputType keyboardType;
  final List<TextInputFormatter> formatters;
  final VoidCallback onBlur;
  final FocusNode? focusNode;
  final String? error;
  final Widget? trailing;
  final bool obscure;
  final TextCapitalization capitalization;
  final Iterable<String>? autofillHints;
  final ValueChanged<String>? onSubmitted;

  @override
  State<_Field> createState() => _FieldState();
}

class _FieldState extends State<_Field> {
  late final FocusNode _focus = widget.focusNode ?? FocusNode();

  @override
  void initState() {
    super.initState();
    _focus.addListener(_onFocus);
  }

  void _onFocus() {
    if (!_focus.hasFocus) widget.onBlur();
  }

  @override
  void dispose() {
    _focus.removeListener(_onFocus);
    if (widget.focusNode == null) _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide(color: colors.border),
    );
    return TextField(
      controller: widget.controller,
      focusNode: _focus,
      keyboardType: widget.keyboardType,
      inputFormatters: widget.formatters,
      obscureText: widget.obscure,
      textCapitalization: widget.capitalization,
      autofillHints: widget.autofillHints,
      onSubmitted: widget.onSubmitted,
      textInputAction:
          widget.onSubmitted == null ? TextInputAction.next : TextInputAction.done,
      style: TextStyle(
        color: colors.textPrimary,
        fontWeight: FontWeight.w600,
        fontFeatures: const [FontFeature.tabularFigures()],
      ),
      decoration: InputDecoration(
        labelText: widget.label,
        hintText: widget.hint,
        errorText: widget.error,
        errorMaxLines: 2,
        filled: true,
        fillColor: colors.inputFill,
        prefixIcon: Padding(
          padding: const EdgeInsets.all(12),
          child: AppIcon(widget.icon, color: colors.textSecondary, size: 20),
        ),
        prefixIconConstraints: const BoxConstraints(minWidth: 44, minHeight: 44),
        suffixIcon: widget.trailing == null
            ? null
            : Padding(
                padding: const EdgeInsets.only(right: 14),
                child: Center(widthFactor: 1, child: widget.trailing),
              ),
        border: border,
        enabledBorder: border,
        focusedBorder: border.copyWith(
          borderSide: BorderSide(color: colors.primary, width: 1.6),
        ),
      ),
    );
  }
}
