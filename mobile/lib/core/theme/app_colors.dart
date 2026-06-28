import 'package:flutter/material.dart';

/// ──────────────────────────────────────────────────────────────────────────────
/// APP COLOR PALETTE
/// Extracted from the Figma Design (Design.jpg) via pixel-level analysis
///
/// VERIFIED COLORS — sampled directly from the 9084x32629 design image.
/// Primary: #21438A (dark blue), Accent: #D12E7D (magenta/pink),
/// Indigo: #5046E5, Purple: #9747FF, Green: #2AC052
/// ──────────────────────────────────────────────────────────────────────────────

class AppColors {
  AppColors._(); // Prevent instantiation

  // ═══════════════════════════════════════════════════════════════════════════
  // PRIMARY BRAND COLORS
  // Dominant dark blue used in headers, nav bars, section banners
  // Pixel-verified: #21438A (freq: 22,336 — most used non-neutral color)
  // ═══════════════════════════════════════════════════════════════════════════

  static const Color primary = Color(0xFF21438A); // Main brand blue (verified)
  static const Color primaryDark = Color(
    0xFF11428E,
  ); // Darker blue variant (verified)
  static const Color primaryLight = Color(
    0xFF214488,
  ); // Lighter blue variant (verified)
  static const Color primaryDeep = Color(0xFF102759); // Deepest navy (verified)
  static const Color primaryDarkest = Color(
    0xFF001D55,
  ); // Near-black navy (verified)

  // Primary with opacity variants
  static const Color primary80 = Color(0xCC21438A); // 80% opacity
  static const Color primary60 = Color(0x9921438A); // 60% opacity
  static const Color primary40 = Color(0x6621438A); // 40% opacity
  static const Color primary20 = Color(0x3321438A); // 20% opacity
  static const Color primary10 = Color(0x1A21438A); // 10% opacity

  // ═══════════════════════════════════════════════════════════════════════════
  // ACCENT / CTA COLORS — MAGENTA / PINK
  // Used for primary action buttons, section header underlines, key CTAs
  // Pixel-verified: #D12E7D (freq: 4,467 — second most used color)
  // NOT red as initially estimated — it's a vibrant magenta/pink!
  // ═══════════════════════════════════════════════════════════════════════════

  static const Color accent = Color(
    0xFFD12E7D,
  ); // Primary magenta CTA (verified)
  static const Color accentDark = Color(0xFFB0256A); // Darker pressed state
  static const Color accentLight = Color(0xFFDE5A97); // Lighter variant
  static const Color accentSoft = Color(
    0xFFFCE4EC,
  ); // Very soft pink background

  // Darker magenta variant found in design
  static const Color magentaDark = Color(
    0xFF681E53,
  ); // Deep magenta/plum (verified)

  // ═══════════════════════════════════════════════════════════════════════════
  // SECONDARY / INDIGO ACCENT
  // Used in buttons, active states, interactive elements
  // Pixel-verified: #5046E5 (freq: 727)
  // ═══════════════════════════════════════════════════════════════════════════

  static const Color secondary = Color(0xFF5046E5); // Vibrant indigo (verified)
  static const Color secondaryLight = Color(
    0xFF675BEF,
  ); // Light indigo (verified)
  static const Color secondaryLighter = Color(
    0xFF7469F3,
  ); // Lighter indigo (verified)
  static const Color secondaryBright = Color(
    0xFF685EFF,
  ); // Bright indigo (verified)

  // ═══════════════════════════════════════════════════════════════════════════
  // PURPLE ACCENT
  // Used in Figma component annotations, accent elements
  // Pixel-verified: #9747FF
  // ═══════════════════════════════════════════════════════════════════════════

  static const Color purple = Color(
    0xFF9747FF,
  ); // Figma purple accent (verified)
  static const Color purpleLight = Color(0xFFB388FF); // Light purple
  static const Color purpleSoft = Color(0xFFE8DEFF); // Very soft purple bg

  // ═══════════════════════════════════════════════════════════════════════════
  // DARK UI ELEMENT COLORS
  // Additional dark colors found in cards, overlays, and UI elements
  // Pixel-verified: #27214D, #25224D, #232D39
  // ═══════════════════════════════════════════════════════════════════════════

  static const Color darkPurple = Color(
    0xFF27214D,
  ); // Dark purple element (verified)
  static const Color darkPurpleAlt = Color(
    0xFF25224D,
  ); // Alt dark purple (verified)
  static const Color darkSlate = Color(
    0xFF232D39,
  ); // Dark blue-slate (verified)
  static const Color darkSlateAlt = Color(
    0xFF242E3A,
  ); // Alt dark slate (verified)

  // ═══════════════════════════════════════════════════════════════════════════
  // SEMANTIC / STATUS COLORS
  // ═══════════════════════════════════════════════════════════════════════════

  static const Color success = Color(
    0xFF2AC052,
  ); // Green — success/online (verified)
  static const Color successDark = Color(0xFF15683E); // Dark green (verified)
  static const Color successLight = Color(0xFF81C784);
  static const Color successSoft = Color(0xFFE8F5E9); // Soft green bg

  static const Color warning = Color(0xFFFFC107); // Amber — warning
  static const Color warningDark = Color(0xFFFFA000);
  static const Color warningLight = Color(0xFFFFD54F);
  static const Color warningSoft = Color(0xFFFFF8E1); // Soft amber bg

  static const Color error = Color(0xFFE53935); // Red — error
  static const Color errorDark = Color(0xFFC62828);
  static const Color errorLight = Color(0xFFEF5350);
  static const Color errorSoft = Color(0xFFFFEBEE); // Soft red bg

  static const Color info = Color(0xFF2196F3); // Blue — info
  static const Color infoDark = Color(0xFF1976D2);
  static const Color infoLight = Color(0xFF64B5F6);
  static const Color infoSoft = Color(0xFFE3F2FD); // Soft blue bg

  // ═══════════════════════════════════════════════════════════════════════════
  // NEUTRAL / GRAY SCALE
  // Pixel-verified from design elements
  // ═══════════════════════════════════════════════════════════════════════════

  static const Color black = Color(0xFF000000);
  static const Color gray900 = Color(0xFF232323); // Near-black text (verified)
  static const Color gray850 = Color(0xFF242424); // Alt near-black (verified)
  static const Color gray700 = Color(0xFF3F4752); // Dark gray UI (verified)
  static const Color gray600 = Color(0xFF7A8191); // Secondary text (verified)
  static const Color gray550 = Color(
    0xFF7E8595,
  ); // Alt secondary text (verified)
  static const Color gray500 = Color(0xFF7C8393); // Placeholder text (verified)
  static const Color gray450 = Color(
    0xFF726C8E,
  ); // Muted purple-gray (verified)
  static const Color gray400 = Color(0xFFA2AEC4); // Light gray-blue (verified)
  static const Color gray350 = Color(0xFFA1AEC1); // Alt light gray (verified)
  static const Color gray300 = Color(
    0xFFD9D9D9,
  ); // Borders / dividers (verified)
  static const Color gray200 = Color(0xFFEEEEEE); // Light dividers
  static const Color gray100 = Color(0xFFF3F3F3); // Light background (verified)
  static const Color gray50 = Color(0xFFFAFAFA); // Subtle background (verified)
  static const Color white = Color(0xFFFFFFFF);

  // ═══════════════════════════════════════════════════════════════════════════
  // SURFACE & BACKGROUND COLORS
  // Pixel-verified screen backgrounds
  // ═══════════════════════════════════════════════════════════════════════════

  static const Color background = Color(
    0xFFF6F7FB,
  ); // Main screen bg — slight blue tint (verified)
  static const Color backgroundAlt = Color(
    0xFFFAFBFF,
  ); // Alt screen bg — subtle blue (verified)
  static const Color surface = Color(0xFFFFFFFF); // Card surface (white)
  static const Color surfaceVariant = Color(
    0xFFF3F2F8,
  ); // Slightly purple-tinted surface (verified)
  static const Color surfaceCool = Color(
    0xFFF3F4F6,
  ); // Cool gray surface (verified)
  static const Color surfaceWarm = Color(
    0xFFF4F5F9,
  ); // Warm blue surface (verified)

  static const Color darkBackground = Color(
    0xFF27214D,
  ); // Dark mode background (verified)
  static const Color darkSurface = Color(
    0xFF25224D,
  ); // Dark mode card surface (verified)
  static const Color darkSurfaceVariant = Color(
    0xFF232D39,
  ); // Dark mode elevated surface (verified)

  // Dark overlay for modals, bottom sheets
  static const Color overlay = Color(0x80000000); // 50% black overlay
  static const Color overlayLight = Color(0x33000000); // 20% black overlay

  // ═══════════════════════════════════════════════════════════════════════════
  // SPECIAL UI ELEMENT COLORS
  // ═══════════════════════════════════════════════════════════════════════════

  // Navigation Bar
  static const Color navBarBackground = Color(
    0xFF21438A,
  ); // Bottom nav bg (verified)
  static const Color navBarActive = Color(0xFFFFFFFF); // Active nav icon
  static const Color navBarInactive = Color(
    0xFFA2AEC4,
  ); // Inactive nav icon (verified gray)

  // Chat Bubbles
  static const Color chatBubbleSent = Color(
    0xFF21438A,
  ); // Sent message bubble (verified)
  static const Color chatBubbleReceived = Color(
    0xFFF3F2F8,
  ); // Received message bubble (verified)
  static const Color chatBubbleSentText = Color(
    0xFFFFFFFF,
  ); // Sent message text
  static const Color chatBubbleReceivedText = Color(
    0xFF232323,
  ); // Received text (verified)

  // Badges & Tags
  static const Color badge = Color(
    0xFFD12E7D,
  ); // Notification badge — magenta (verified)
  static const Color tagBackground = Color(
    0xFFF3F2F8,
  ); // Tag/chip background (verified)
  static const Color tagText = Color(
    0xFF5046E5,
  ); // Tag/chip text — indigo (verified)

  // Swipe Card Colors (Tinder-like feature)
  static const Color swipeLike = Color(
    0xFF2AC052,
  ); // Like / swipe right (verified)
  static const Color swipeDislike = Color(
    0xFFD12E7D,
  ); // Dislike / swipe left — magenta (verified)
  static const Color swipeSuperLike = Color(
    0xFF5046E5,
  ); // Super like — indigo (verified)
  static const Color swipeBoost = Color(
    0xFF9747FF,
  ); // Boost — purple (verified)

  // Online Status
  static const Color online = Color(0xFF2AC052); // Online indicator (verified)
  static const Color offline = Color(
    0xFF7A8191,
  ); // Offline indicator (verified)
  static const Color busy = Color(0xFFFFC107); // Busy/away indicator

  // ═══════════════════════════════════════════════════════════════════════════
  // PROFILE & SETTINGS MENU COLORS
  // Specific icon background and text colors matching the profile design
  // ═══════════════════════════════════════════════════════════════════════════

  static const Color iconPurple = Color(0xFF9E54D4);
  static const Color iconPink = Color(0xFFD6317A);
  static const Color iconBlue = Color(0xFF1E88E5);
  static const Color iconBlack = Color(0xFF1A1A1A);
  static const Color iconDeepPurple = Color(0xFF5E35B1);
  static const Color iconMediumBlue = Color(0xFF1976D2);
  static const Color iconGrey = Color(0xFF757575);
  static const Color iconNavy = Color(0xFF15448C);

  static const Color textDarkBlue = Color(0xFF283266);
  static const Color dividerLight = Color(0xFFF1F1F5);

  // ═══════════════════════════════════════════════════════════════════════════
  // GRADIENT DEFINITIONS
  // Using verified color values
  // ═══════════════════════════════════════════════════════════════════════════

  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF11428E), Color(0xFF21438A)],
  );

  static const LinearGradient accentGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFD12E7D), Color(0xFF9747FF)], // Magenta to purple
  );

  static const LinearGradient indigoGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF5046E5), Color(0xFF7469F3)], // Indigo gradient
  );

  static const LinearGradient darkGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFF27214D), Color(0xFF232D39)],
  );

  static const LinearGradient sectionHeaderGradient = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [Color(0xFF11428E), Color(0xFF21438A)],
  );

  // Shimmer / Loading gradient
  static const LinearGradient shimmerGradient = LinearGradient(
    begin: Alignment(-1.0, -0.3),
    end: Alignment(1.0, 0.3),
    colors: [Color(0xFFF3F3F3), Color(0xFFFAFBFF), Color(0xFFF3F3F3)],
    stops: [0.0, 0.5, 1.0],
  );

  // ═══════════════════════════════════════════════════════════════════════════
  // MATERIAL COLOR SWATCH (for MaterialApp theme)
  // Based on verified primary #21438A
  // ═══════════════════════════════════════════════════════════════════════════

  static const MaterialColor primarySwatch = MaterialColor(
    0xFF21438A,
    <int, Color>{
      50: Color(0xFFE4EAF5),
      100: Color(0xFFBCCBE5),
      200: Color(0xFF90A9D4),
      300: Color(0xFF6487C2),
      400: Color(0xFF426DB5),
      500: Color(0xFF21438A), // Primary
      600: Color(0xFF1D3C7E),
      700: Color(0xFF183370),
      800: Color(0xFF142B63),
      900: Color(0xFF0B1D49),
    },
  );
}
