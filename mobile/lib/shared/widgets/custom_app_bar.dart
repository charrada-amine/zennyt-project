import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/theme.dart';
import 'app_back_button.dart';

const kAppBarTitleStyle = TextStyle(
  fontFamily: AppTypography.fontFamily,
  fontSize: 24,
  fontWeight: FontWeight.w700,
  color: AppColors.primaryDeep,
  letterSpacing: -.8,
);

BoxDecoration kAppBarButtonDecoration({Color? borderColor}) => BoxDecoration(
  color: Colors.white,
  borderRadius: BorderRadius.circular(16),
  border: Border.all(color: borderColor ?? AppColorScheme.light.border),
);

/// Shared page chrome. Flexible title space supports long localized labels.
class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  const CustomAppBar({
    super.key,
    required this.title,
    this.onBack,
    this.trailingAction,
  });

  final String title;
  final VoidCallback? onBack;
  final Widget? trailingAction;

  @override
  Size get preferredSize => const Size.fromHeight(76);

  @override
  Widget build(BuildContext context) {
    final showBack = onBack != null || context.canPop();
    return AppBar(
      backgroundColor: context.colors.scaffoldBg,
      foregroundColor: context.colors.textDarkBlue,
      elevation: 0,
      scrolledUnderElevation: 0,
      automaticallyImplyLeading: false,
      centerTitle: false,
      titleSpacing: 0,
      toolbarHeight: preferredSize.height,
      title: Padding(
        padding: EdgeInsets.only(left: showBack ? 4 : 24, right: 20),
        child: Row(
          children: [
            if (showBack) ...[
              AppBackButton(onPressed: onBack),
              const SizedBox(width: 12),
            ],
            Expanded(
              child: Text(
                title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: kAppBarTitleStyle.copyWith(
                  color: context.colors.textDarkBlue,
                ),
              ),
            ),
            if (trailingAction != null) ...[
              const SizedBox(width: 12),
              trailingAction!,
            ],
          ],
        ),
      ),
    );
  }
}
