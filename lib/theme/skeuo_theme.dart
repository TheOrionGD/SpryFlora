import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// SpryFlora Playful Design System
/// Fun, childish, vibrant leaf green themed UI tokens for kids/family usage.
class SkeuoTheme {
  // Spacing Scale
  static const double space4 = 4.0;
  static const double space8 = 8.0;
  static const double space12 = 12.0;
  static const double space16 = 16.0;
  static const double space20 = 20.0;
  static const double space24 = 24.0;
  static const double space32 = 32.0;

  // ── Primary Leaf Green Palette (matching 255.jpg) ─────────────────────────
  static const Color primaryGreen = Color(0xFF38B638); // Vibrant natural action green
  static const Color primaryGreenLight = Color(0xFF5CD85C); // Lighter grass
  static const Color primaryGreenDark = Color(0xFF238823); // Deep botanical green
  static const Color darkGreen = Color(0xFF1B4D1E);
  static const Color lightGreen = Color(0xFFA5D6A7);
  static const Color accentGreen = Color(0xFF4CAF50);
  static const Color deepForest = Color(0xFF163E19);

  // ── Secondary & Accent ──────────────────────────────────────────────────
  static const Color funYellow = Color(0xFFFFD54F); // Warm sunny yellow
  static const Color funYellowLight = Color(0xFFFFF9C4);
  static const Color funCoral = Color(0xFFFF8A80);
  static const Color funOrange = Color(0xFFFFB74D);
  static const Color funPurple = Color(0xFFCE93D8);
  static const Color funBlue = Color(0xFF4FC3F7); // Water blue
  static const Color funMint = Color(0xFFB2DFDB);

  // ── Background / Surface (Warm Ivory/Cream from 255.jpg) ──────────────────
  static const Color background = Color(0xFFFFFDF2); // Warm cream / ivory
  static const Color creamCard = Color(0xFFFFFDF4); // Soft card surface
  static const Color surface = Color(0xFFFFFFFF); // Clean white surfaces
  static const Color surfaceLight = Color(0xFFFAFDFA);
  static const Color surfaceDark = Color(0xFFF1F8EE);
  static const Color surfacePressed = Color(0xFFE2F0DD);
  static const Color cardBorder = Color(0xFFE5EBD8); // Subtle organic border

  // ── Alert / Status ───────────────────────────────────────────────────────
  static const Color waterBlue = Color(0xFF29B6F6);
  static const Color waterLight = Color(0xFFB3E5FC);
  static const Color sunYellow = Color(0xFFFFC107);
  static const Color warningOrange = Color(0xFFFF7043);
  static const Color alertRed = Color(0xFFEF5350);
  static const Color alertRedLight = Color(0xFFFFEBEE);

  // ── Text Colors (Botanical Dark Greens) ──────────────────────────────────
  static const Color textPrimary = Color(0xFF1B4D1E); // Dark green heading
  static const Color textSecondary = Color(0xFF526E4F); // Mid green body
  static const Color textMuted = Color(0xFF88A382); // Soft green placeholder/meta
  static const Color textOnGreen = Color(0xFFFFFFFF);

  // ── Shadows ──────────────────────────────────────────────────────────────
  static const Color lightHighlight = Color(0xFFFFFFFF);
  static final Color darkShadow =
      const Color(0xFF2E7D32).withValues(alpha: 0.12);
  static final Color ambientShadow =
      const Color(0xFF000000).withValues(alpha: 0.05);

  // ── Typography (Nunito — rounded, playful, friendly) ─────────────────────
  static TextStyle funHeading({
    double size = 26,
    Color color = textPrimary,
    FontWeight weight = FontWeight.w900,
  }) {
    return GoogleFonts.nunito(
        fontSize: size, fontWeight: weight, color: color, letterSpacing: -0.3);
  }

  static TextStyle funBody({
    double size = 14,
    Color color = textSecondary,
    FontWeight weight = FontWeight.w600,
  }) {
    return GoogleFonts.nunito(fontSize: size, fontWeight: weight, color: color);
  }

  static TextStyle funLabel({
    double size = 12,
    Color color = textMuted,
    FontWeight weight = FontWeight.w700,
  }) {
    return GoogleFonts.nunito(
        fontSize: size, fontWeight: weight, color: color, letterSpacing: 0.3);
  }

  // ── Shadow Helpers ────────────────────────────────────────────────────────
  static List<BoxShadow> raisedShadows({
    double blur = 10,
    double offset = 3,
    Color? shadowColor,
  }) {
    return [
      BoxShadow(
        color: shadowColor ?? ambientShadow,
        offset: Offset(0, offset),
        blurRadius: blur,
        spreadRadius: 0,
      ),
    ];
  }

  static List<BoxShadow> highRaisedShadows() {
    return [
      BoxShadow(
        color: const Color(0xFF2E7D32).withValues(alpha: 0.16),
        offset: const Offset(0, 8),
        blurRadius: 16,
        spreadRadius: -2,
      ),
    ];
  }

  static List<BoxShadow> recessedShadows({double blur = 6, double offset = 2}) {
    return [
      BoxShadow(
        color: const Color(0xFF2E7D32).withValues(alpha: 0.08),
        offset: Offset(0, offset),
        blurRadius: blur,
        spreadRadius: 0,
      ),
    ];
  }

  static List<BoxShadow> pressedShadows() {
    return [
      BoxShadow(
        color: const Color(0xFF2E7D32).withValues(alpha: 0.15),
        offset: const Offset(0, 1),
        blurRadius: 2,
      ),
    ];
  }

  // ── Card Decorations ─────────────────────────────────────────────────────
  static BoxDecoration funCardDecoration({
    Color color = surface,
    double borderRadius = 20,
    Color borderColor = cardBorder,
    List<BoxShadow>? shadows,
  }) {
    return BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(borderRadius),
      border: Border.all(color: borderColor, width: 1.2),
      boxShadow: shadows ??
          [
            BoxShadow(
              color: const Color(0xFF2E7D32).withValues(alpha: 0.04),
              offset: const Offset(0, 3),
              blurRadius: 8,
            ),
          ],
    );
  }

  static BoxDecoration raisedBevelDecoration({
    Color color = surface,
    double borderRadius = 20,
    bool isPressed = false,
    Border? border,
    Gradient? gradient,
  }) {
    return BoxDecoration(
      color: isPressed ? surfacePressed : color,
      gradient: gradient,
      borderRadius: BorderRadius.circular(borderRadius),
      border: border ??
          Border.all(
            color: cardBorder,
            width: 1.2,
          ),
      boxShadow: isPressed ? pressedShadows() : raisedShadows(),
    );
  }

  // ── Gradient Helpers ─────────────────────────────────────────────────────
  static const LinearGradient greenGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF38B638), Color(0xFF238823)],
  );

  static const LinearGradient yellowGreenGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF8BC34A), Color(0xFF38B638)],
  );

  static const LinearGradient mintGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFFFFFDF2), Color(0xFFF7FBF4)],
  );

  static const LinearGradient sunsetGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFFFB74D), Color(0xFFFF8A80)],
  );
}
