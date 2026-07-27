import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:zennyt/l10n/gen/app_localizations.dart';
import 'package:zennyt/core/constants.dart';

class CreatePostTextField extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  const CreatePostTextField({
    super.key,
    required this.controller,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: AppConstants.isCupertino
          ? CupertinoTextField(
              controller: controller,
              placeholder: l10n.newProject,
              placeholderStyle: const TextStyle(color: AppColors.primaryGrey),
              style: TextStyle(
                color: context.colors.textPrimary,
                fontSize: 16,
              ),
              textAlignVertical: TextAlignVertical.top,
              minLines: 1,
              maxLines: null,
              decoration: const BoxDecoration(),
              onChanged: onChanged,
            )
          : TextField(
              controller: controller,
              decoration: InputDecoration(
                hintText: l10n.newProject,
                hintStyle: TextStyle(color: AppColors.primaryGrey),
                filled: false,
                fillColor: Colors.transparent,
                border: InputBorder.none,
                focusedBorder: InputBorder.none,
                enabledBorder: InputBorder.none,
                disabledBorder: InputBorder.none,
                contentPadding: EdgeInsets.zero,
              ),
              style: TextStyle(
                color: context.colors.textPrimary,
                fontSize: 16,
              ),
              textAlignVertical: TextAlignVertical.top,
              minLines: 1,
              maxLines: null,
              onChanged: onChanged,
            ),
    );
  }
}
