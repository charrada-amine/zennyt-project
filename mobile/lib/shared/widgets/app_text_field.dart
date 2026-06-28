import 'package:flutter/material.dart';

import '../../core/theme/theme.dart';

/// Validation/visual state used to color a field's border, shadow and icon.
enum FieldStatus { normal, error, valid }

Color _restingBorder(BuildContext context, FieldStatus status) {
  final colors = context.colors;
  switch (status) {
    case FieldStatus.error:
      return colors.error;
    case FieldStatus.valid:
      return colors.success;
    case FieldStatus.normal:
      return colors.border;
  }
}

/// Accent color for the focused border / shadow tint.
Color _accentForStatus(BuildContext context, FieldStatus status) {
  final colors = context.colors;
  switch (status) {
    case FieldStatus.error:
      return colors.error;
    case FieldStatus.valid:
      return colors.success;
    case FieldStatus.normal:
      return colors.primary;
  }
}

/// Shared rounded input decoration. Used by [AppTextField] internally and by
/// any other form control (e.g. [DropdownButtonFormField]) that needs to
/// visually match the app's text fields.
InputDecoration appInputDecoration(
  BuildContext context, {
  String? hint,
  Widget? prefixIcon,
  Widget? suffixIcon,
  FieldStatus status = FieldStatus.normal,
}) {
  final colors = context.colors;
  final restColor = _restingBorder(context, status);
  final focusColor = _accentForStatus(context, status);

  OutlineInputBorder border(Color color, [double width = 1.2]) =>
      OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        borderSide: BorderSide(color: color, width: width),
      );

  return InputDecoration(
    hintText: hint,
    hintStyle: AppTypography.bodyMedium.copyWith(color: colors.textMuted),
    filled: true,
    fillColor: colors.inputFill,
    isDense: true,
    contentPadding: const EdgeInsets.symmetric(
      horizontal: AppSpacing.base,
      vertical: AppSpacing.base,
    ),
    prefixIcon: prefixIcon,
    // Constrain the height only; the icon widget itself sets its width, which
    // keeps the icon pinned to the left and leaves the rest tappable.
    prefixIconConstraints: prefixIcon != null
        ? const BoxConstraints(minHeight: 48)
        : null,
    suffixIcon: suffixIcon,
    suffixIconConstraints: const BoxConstraints(minHeight: 48, minWidth: 48),
    enabledBorder: border(restColor),
    focusedBorder: border(focusColor, 1.6),
    border: border(restColor),
    errorBorder: border(colors.error),
    focusedErrorBorder: border(colors.error, 1.6),
  );
}

/// A fixed-width leading icon for inputs. Pinned left with consistent spacing
/// so the hint text and tap target are never covered. Reused by the
/// city/country dropdown so it lines up with the text fields.
class AppInputIcon extends StatelessWidget {
  const AppInputIcon(this.icon, {super.key, this.color});

  final IconData icon;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 46,
      child: Icon(
        icon,
        size: AppSpacing.iconMd,
        color: color ?? context.colors.textSecondary,
      ),
    );
  }
}

/// The single text-input widget used across the app.
///
/// Beyond a regular [TextFormField] it adds:
///   * an animated focus shadow (tinted to the field's status),
///   * a leading [prefixIcon] that brightens to the brand color on focus,
///   * a smoothly cross-faded password eye toggle when [obscureText] is true,
///   * an optional [label] rendered above the field.
class AppTextField extends StatefulWidget {
  const AppTextField({
    super.key,
    this.label,
    this.hint,
    this.controller,
    this.initialValue,
    this.validator,
    this.status = FieldStatus.normal,
    this.obscureText = false,
    this.keyboardType,
    this.textInputAction,
    this.onChanged,
    this.onSubmitted,
    this.prefixIcon,
    this.suffixIcon,
    this.readOnly = false,
    this.onTap,
    this.autovalidateMode,
  });

  final String? label;
  final String? hint;
  final TextEditingController? controller;
  final String? initialValue;
  final FormFieldValidator<String>? validator;
  final FieldStatus status;
  final bool obscureText;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final IconData? prefixIcon;
  final Widget? suffixIcon;
  final bool readOnly;
  final VoidCallback? onTap;
  final AutovalidateMode? autovalidateMode;

  @override
  State<AppTextField> createState() => _AppTextFieldState();
}

class _AppTextFieldState extends State<AppTextField> {
  late bool _obscured = widget.obscureText;
  final FocusNode _focusNode = FocusNode();
  bool _hasFocus = false;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(_handleFocusChange);
  }

  @override
  void dispose() {
    _focusNode.removeListener(_handleFocusChange);
    _focusNode.dispose();
    super.dispose();
  }

  void _handleFocusChange() {
    if (_hasFocus != _focusNode.hasFocus) {
      setState(() => _hasFocus = _focusNode.hasFocus);
    }
  }

  Color _iconColor(BuildContext context) {
    if (widget.status != FieldStatus.normal) {
      return _accentForStatus(context, widget.status);
    }
    return _hasFocus ? context.colors.primary : context.colors.textSecondary;
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final accent = _accentForStatus(context, widget.status);
    // Subtle lift on focus; kept visible for error/valid so the state reads
    // even when the field isn't focused.
    final showShadow = _hasFocus || widget.status != FieldStatus.normal;

    final prefix = widget.prefixIcon != null
        ? AppInputIcon(widget.prefixIcon!, color: _iconColor(context))
        : null;

    final suffix = widget.obscureText
        ? IconButton(
            splashRadius: 20,
            onPressed: () => setState(() => _obscured = !_obscured),
            icon: AnimatedSwitcher(
              duration: const Duration(milliseconds: 180),
              transitionBuilder: (child, anim) => FadeTransition(
                opacity: anim,
                child: ScaleTransition(scale: anim, child: child),
              ),
              child: Icon(
                _obscured
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
                key: ValueKey(_obscured),
                size: AppSpacing.iconMd,
                color: _hasFocus ? colors.primary : colors.textMuted,
              ),
            ),
          )
        : widget.suffixIcon;

    final field = AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOut,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        boxShadow: showShadow
            ? [
                BoxShadow(
                  color: accent.withValues(alpha: 0.12),
                  blurRadius: 14,
                  offset: const Offset(0, 4),
                ),
              ]
            : const [],
      ),
      child: TextFormField(
        controller: widget.controller,
        focusNode: _focusNode,
        initialValue: widget.controller == null ? widget.initialValue : null,
        validator: widget.validator,
        obscureText: _obscured,
        keyboardType: widget.keyboardType,
        textInputAction: widget.textInputAction,
        onChanged: widget.onChanged,
        onFieldSubmitted: widget.onSubmitted,
        readOnly: widget.readOnly,
        onTap: widget.onTap,
        cursorColor: colors.primary,
        autovalidateMode:
            widget.autovalidateMode ??
            (widget.validator != null
                ? AutovalidateMode.onUserInteraction
                : null),
        style: AppTypography.bodyMedium.copyWith(color: colors.textPrimary),
        decoration: appInputDecoration(
          context,
          hint: widget.hint ?? widget.label,
          status: widget.status,
          prefixIcon: prefix,
          suffixIcon: suffix,
        ),
      ),
    );

    if (widget.label == null) return field;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.label!,
          style: AppTypography.inputLabel.copyWith(color: colors.textSecondary),
        ),
        const SizedBox(height: AppSpacing.xs),
        field,
      ],
    );
  }
}
