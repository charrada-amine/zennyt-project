// ignore_for_file: deprecated_member_use
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/constants.dart';

class PlatformAppBar extends StatelessWidget
    implements ObstructingPreferredSizeWidget {
  final Widget title;
  final bool showBack;
  final List<Widget>? actions;
  final Widget? leading;
  final VoidCallback? onLeadingPressed;

  const PlatformAppBar({
    super.key,
    required this.title,
    this.showBack = true,
    this.actions,
    this.leading,
    this.onLeadingPressed,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    if (AppConstants.isCupertino) {
      return CupertinoNavigationBar(
        middle: title,
        leading: leading ??
            (showBack
                ? GestureDetector(
                    onTap: onLeadingPressed ??
                        () {
                          if (Navigator.canPop(context)) Navigator.pop(context);
                        },
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: colors.cardSurface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: colors.border,
                          width: 0.5,
                        ),
                      ),
                      child: Icon(
                        CupertinoIcons.back,
                        size: 20,
                        color: colors.iconDefault,
                      ),
                    ),
                  )
                : null),
        trailing: actions == null
            ? null
            : Row(mainAxisSize: MainAxisSize.min, children: actions!),
        border: null,
        backgroundColor: colors.cardSurface,
      );
    }

    return AppBar(
      centerTitle: true,
      backgroundColor: colors.navBg,
      elevation: 0,
      scrolledUnderElevation: 0,
      toolbarHeight: preferredSize.height,
      surfaceTintColor: Colors.transparent,
      shadowColor: Colors.transparent,
      systemOverlayStyle: SystemUiOverlayStyle(
        statusBarIconBrightness:
            isDarkMode ? Brightness.light : Brightness.dark,
        statusBarColor: Colors.transparent,
        statusBarBrightness: isDarkMode ? Brightness.light : Brightness.dark,
        systemNavigationBarColor: Colors.transparent,
        systemNavigationBarIconBrightness:
            isDarkMode ? Brightness.dark : Brightness.light,
      ),
      automaticallyImplyLeading: false,
      leadingWidth: 70,
      leading: leading != null
          ? InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: onLeadingPressed,
              child: leading,
            )
          : (showBack
              ? Padding(
                  padding: const EdgeInsets.only(
                    left: 16.0,
                    top: 20.0,
                    bottom: 18.0,
                  ),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(14),
                    onTap: onLeadingPressed ??
                        () {
                          if (Navigator.canPop(context)) Navigator.pop(context);
                        },
                    child: AspectRatio(
                      aspectRatio: 1.0,
                      child: Container(
                        decoration: BoxDecoration(
                          color: colors.cardSurface,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: colors.border,
                            width: 1.5,
                          ),
                        ),
                        child: Icon(
                          Icons.arrow_back_ios_rounded,
                          size: 18,
                          color: colors.iconDefault,
                        ),
                      ),
                    ),
                  ),
                )
              : null),
      title: title,
      actions: actions,
    );
  }

  @override
  Size get preferredSize => AppConstants.isCupertino
      ? const Size.fromHeight(50.0)
      : const Size.fromHeight(90.0);

  @override
  bool shouldFullyObstruct(BuildContext context) => true;
}
