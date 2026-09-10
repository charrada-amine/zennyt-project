import 'package:flutter/material.dart';

/// Presentation timing only. Never use these values for game protocols.
abstract final class AppMotion {
  static const press = Duration(milliseconds: 110);
  static const settle = Duration(milliseconds: 280);
  static const reveal = Duration(milliseconds: 420);
  static const navigation = Duration(milliseconds: 320);
  static const curve = Curves.easeOutCubic;

  static bool reduced(BuildContext context) =>
      MediaQuery.disableAnimationsOf(context) ||
      MediaQuery.accessibleNavigationOf(context);

  static Duration duration(BuildContext context, Duration value) =>
      reduced(context) ? Duration.zero : value;
}
