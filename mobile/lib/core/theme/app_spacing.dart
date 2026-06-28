library;

/// ──────────────────────────────────────────────────────────────────────────────
/// APP SPACING & DIMENSIONS
/// Extracted from the Figma Design (Design.jpg)
///
/// Consistent spacing scale, border radii, icon sizes, and layout dimensions.
/// ──────────────────────────────────────────────────────────────────────────────

class AppSpacing {
  AppSpacing._();

  // ═══════════════════════════════════════════════════════════════════════════
  // SPACING SCALE (used for padding, margin, gaps)
  // Based on 4px grid system extracted from design
  // ═══════════════════════════════════════════════════════════════════════════

  static const double xxs = 2.0;
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 12.0;
  static const double base = 16.0;
  static const double lg = 20.0;
  static const double xl = 24.0;
  static const double xxl = 32.0;
  static const double xxxl = 40.0;
  static const double huge = 48.0;
  static const double massive = 64.0;
  static const double giant = 80.0;

  // ═══════════════════════════════════════════════════════════════════════════
  // BORDER RADIUS
  // Extracted from design's rounded corners
  // ═══════════════════════════════════════════════════════════════════════════

  static const double radiusNone = 0.0;
  static const double radiusXs = 4.0; // Small tags, chips
  static const double radiusSm = 8.0; // Buttons, input fields
  static const double radiusMd = 12.0; // Cards, tiles
  static const double radiusLg = 16.0; // Modal sheets, dialogs
  static const double radiusXl = 20.0; // Large cards
  static const double radiusXxl = 24.0; // Bottom sheets
  static const double radiusFull = 999.0; // Circular (avatars, pills)

  // ═══════════════════════════════════════════════════════════════════════════
  // ICON SIZES
  // ═══════════════════════════════════════════════════════════════════════════

  static const double iconXs = 12.0;
  static const double iconSm = 16.0;
  static const double iconMd = 20.0;
  static const double iconBase = 24.0; // Default icon size
  static const double iconLg = 28.0;
  static const double iconXl = 32.0;
  static const double iconXxl = 40.0;
  static const double iconHuge = 48.0;
  static const double iconMassive = 64.0;

  // ═══════════════════════════════════════════════════════════════════════════
  // AVATAR SIZES
  // Based on the various avatar sizes visible in the design
  // ═══════════════════════════════════════════════════════════════════════════

  static const double avatarXs = 24.0; // Inline avatars
  static const double avatarSm = 32.0; // Chat list secondary
  static const double avatarMd = 40.0; // Chat list, comments
  static const double avatarLg = 48.0; // Connection cards
  static const double avatarXl = 56.0; // Profile header
  static const double avatarXxl = 80.0; // Profile page
  static const double avatarHuge = 100.0; // Large profile view
  static const double avatarGiant = 120.0; // Profile edit screen

  // ═══════════════════════════════════════════════════════════════════════════
  // COMPONENT HEIGHTS
  // Standard heights for common components from the design
  // ═══════════════════════════════════════════════════════════════════════════

  static const double appBarHeight = 56.0;
  static const double bottomNavHeight = 64.0;
  static const double tabBarHeight = 48.0;
  static const double buttonHeightSm = 36.0;
  static const double buttonHeightMd = 44.0;
  static const double buttonHeightLg = 52.0;
  static const double inputFieldHeight = 48.0;
  static const double listTileHeight = 72.0;
  static const double chatInputHeight = 56.0;
  static const double searchBarHeight = 44.0;
  static const double chipHeight = 32.0;
  static const double dividerThickness = 0.5;
  static const double borderWidth = 1.0;
  static const double borderWidthThick = 2.0;

  // ═══════════════════════════════════════════════════════════════════════════
  // CARD DIMENSIONS
  // ═══════════════════════════════════════════════════════════════════════════

  static const double cardElevation = 2.0;
  static const double cardElevationHigh = 8.0;
  static const double swipeCardHeight = 500.0;
  static const double storyCardWidth = 80.0;
  static const double storyCardHeight = 100.0;

  // ═══════════════════════════════════════════════════════════════════════════
  // SCREEN PADDING
  // Standard padding values used across screens
  // ═══════════════════════════════════════════════════════════════════════════

  static const double screenPaddingH = 16.0; // Horizontal screen padding
  static const double screenPaddingV = 16.0; // Vertical screen padding
  static const double sectionGap = 24.0; // Gap between sections
  static const double cardGap = 12.0; // Gap between cards
  static const double listGap = 8.0; // Gap between list items
}
