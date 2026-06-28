import 'package:flutter/material.dart';

/// ──────────────────────────────────────────────────────────────────────────────
/// APP SHADOWS
/// Extracted from the Figma Design (Design.jpg)
///
/// Shadow definitions for elevation, cards, modals, and overlays.
/// ──────────────────────────────────────────────────────────────────────────────

class AppShadows {
  AppShadows._();

  // ═══════════════════════════════════════════════════════════════════════════
  // ELEVATION SHADOWS
  // Progressive shadow scale matching the design's depth system
  // ═══════════════════════════════════════════════════════════════════════════

  /// No shadow
  static const List<BoxShadow> none = [];

  /// Subtle shadow - used on cards in lists, divider-like separation
  static const List<BoxShadow> xs = [
    BoxShadow(color: Color(0x0A000000), blurRadius: 2, offset: Offset(0, 1)),
  ];

  /// Light shadow - default card elevation
  static const List<BoxShadow> sm = [
    BoxShadow(color: Color(0x0F000000), blurRadius: 4, offset: Offset(0, 2)),
    BoxShadow(color: Color(0x05000000), blurRadius: 2, offset: Offset(0, 1)),
  ];

  /// Medium shadow - elevated cards, floating elements
  static const List<BoxShadow> md = [
    BoxShadow(color: Color(0x14000000), blurRadius: 8, offset: Offset(0, 4)),
    BoxShadow(color: Color(0x0A000000), blurRadius: 4, offset: Offset(0, 2)),
  ];

  /// High shadow - modals, bottom sheets, dropdowns
  static const List<BoxShadow> lg = [
    BoxShadow(color: Color(0x1A000000), blurRadius: 16, offset: Offset(0, 8)),
    BoxShadow(color: Color(0x0F000000), blurRadius: 6, offset: Offset(0, 3)),
  ];

  /// Very high shadow - dialogs, popovers
  static const List<BoxShadow> xl = [
    BoxShadow(color: Color(0x1F000000), blurRadius: 24, offset: Offset(0, 12)),
    BoxShadow(color: Color(0x14000000), blurRadius: 8, offset: Offset(0, 4)),
  ];

  /// Maximum shadow - floating action menus
  static const List<BoxShadow> xxl = [
    BoxShadow(color: Color(0x29000000), blurRadius: 48, offset: Offset(0, 24)),
    BoxShadow(color: Color(0x1A000000), blurRadius: 16, offset: Offset(0, 8)),
  ];

  // ═══════════════════════════════════════════════════════════════════════════
  // COLORED SHADOWS
  // Brand-colored shadows for primary/accent elements
  // ═══════════════════════════════════════════════════════════════════════════

  /// Primary button shadow (verified: #21438A)
  static const List<BoxShadow> primaryButton = [
    BoxShadow(color: Color(0x4021438A), blurRadius: 12, offset: Offset(0, 4)),
  ];

  /// Accent/CTA button shadow (verified: #D12E7D magenta)
  static const List<BoxShadow> accentButton = [
    BoxShadow(color: Color(0x40D12E7D), blurRadius: 12, offset: Offset(0, 4)),
  ];

  /// Purple button shadow (verified: #9747FF)
  static const List<BoxShadow> purpleButton = [
    BoxShadow(color: Color(0x409747FF), blurRadius: 12, offset: Offset(0, 4)),
  ];

  /// Indigo button shadow (verified: #5046E5)
  static const List<BoxShadow> indigoButton = [
    BoxShadow(color: Color(0x405046E5), blurRadius: 12, offset: Offset(0, 4)),
  ];

  // ═══════════════════════════════════════════════════════════════════════════
  // COMPONENT-SPECIFIC SHADOWS
  // ═══════════════════════════════════════════════════════════════════════════

  /// Bottom navigation bar shadow
  static const List<BoxShadow> bottomNav = [
    BoxShadow(color: Color(0x14000000), blurRadius: 8, offset: Offset(0, -2)),
  ];

  /// App bar shadow
  static const List<BoxShadow> appBar = [
    BoxShadow(color: Color(0x0A000000), blurRadius: 4, offset: Offset(0, 2)),
  ];

  /// Floating Action Button shadow
  static const List<BoxShadow> fab = [
    BoxShadow(color: Color(0x29000000), blurRadius: 16, offset: Offset(0, 6)),
  ];

  /// Profile card / swipe card shadow
  static const List<BoxShadow> swipeCard = [
    BoxShadow(
      color: Color(0x1F000000),
      blurRadius: 20,
      offset: Offset(0, 10),
      spreadRadius: -5,
    ),
  ];
}
