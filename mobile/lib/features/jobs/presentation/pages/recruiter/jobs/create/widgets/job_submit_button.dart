import 'package:flutter/material.dart';

class JobSubmitButton extends StatelessWidget {
  final bool isLoading;
  final bool isEditMode;
  final String labelPost;
  final String labelSave;
  final VoidCallback onPressed;

  const JobSubmitButton({
    super.key,
    required this.isLoading,
    required this.isEditMode,
    required this.labelPost,
    required this.labelSave,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.center,
      child: SizedBox(
        height: 48,
        child: OutlinedButton(
          onPressed: isLoading ? null : onPressed,
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            side: const BorderSide(color: Color(0xFF21438A), width: 1.2),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child: isLoading
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(
                  isEditMode ? labelSave : labelPost,
                  style: const TextStyle(
                    fontSize: 16,
                    color: Color(0xFF21438A),
                    fontWeight: FontWeight.w600,
                  ),
                ),
        ),
      ),
    );
  }
}
