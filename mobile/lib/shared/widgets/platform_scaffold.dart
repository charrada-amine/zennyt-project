import 'package:adaptive_platform_ui/adaptive_platform_ui.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../core/constants.dart';
import 'platform_app_bar.dart';

class PlatformScaffold extends StatelessWidget {
  final PreferredSizeWidget? appBar;
  final Widget body;
  final Widget? bottomNavigationBar;
  final Color? backgroundColor;

  const PlatformScaffold({
    super.key,
    this.appBar,
    required this.body,
    this.bottomNavigationBar,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final bar = appBar;

    // iOS 26+ : barre native Liquid Glass. Elle flotte au-dessus du contenu et
    // ne réserve sa hauteur que dans les insets, d'où le SafeArea (le
    // Scaffold/CupertinoPageScaffold s'en chargeaient pour les pages).
    if (PlatformInfo.isIOS26OrHigher() &&
        bottomNavigationBar == null &&
        bar is PlatformAppBar &&
        bar.supportsNativeToolbar) {
      return AdaptiveScaffold(
        appBar: AdaptiveAppBar(titleWidget: bar.title),
        body: ColoredBox(
          color: backgroundColor ?? colors.cardSurface,
          child: SafeArea(
            bottom: false,
            child: Material(type: MaterialType.transparency, child: body),
          ),
        ),
      );
    }

    if (AppConstants.isCupertino) {
      final navBar = appBar is ObstructingPreferredSizeWidget
          ? appBar as ObstructingPreferredSizeWidget
          : null;

      return CupertinoPageScaffold(
        navigationBar: navBar,
        backgroundColor: backgroundColor ?? colors.cardSurface,
        child: bottomNavigationBar == null
            ? body
            : Column(
                children: [
                  Expanded(child: body),
                  bottomNavigationBar!,
                ],
              ),
      );
    }

    return Scaffold(
      appBar: appBar,
      body: body,
      bottomNavigationBar: bottomNavigationBar,
      backgroundColor: backgroundColor ?? colors.scaffoldBg,
    );
  }
}
