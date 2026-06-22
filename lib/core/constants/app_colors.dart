import 'package:flutter/material.dart';

class AppColors {
  const AppColors._();

  static const background = Color(0xFFF6F2EA);
  static const backgroundSoft = Color(0xFFFBF8F3);
  static const surface = Color(0xFFFFFFFF);
  static const surfaceMuted = Color(0xFFF8F4EE);
  static const surfaceElevated = Color(0xFFFFFCF8);
  static const borderSoft = Color(0xFFE8E0D4);
  static const borderStrong = Color(0xFFD8CCBC);

  static const textPrimary = Color(0xFF122033);
  static const textSecondary = Color(0xFF667085);
  static const textMuted = Color(0xFF8B95A7);

  static const navy = Color(0xFF102847);
  static const blue = Color(0xFF325D92);
  static const blueSoft = Color(0xFFEAF2FF);
  static const gold = Color(0xFFCC9A2A);
  static const goldSoft = Color(0xFFFFF6DD);

  static const danger = Color(0xFFD9534F);
  static const success = Color(0xFF2F9E62);
  static const warning = Color(0xFFE8A13A);
  static const info = Color(0xFF4587D7);

  static Color get glassFill => Colors.white.withValues(alpha: 0.66);
  static Color get glassFillStrong => Colors.white.withValues(alpha: 0.82);
  static Color get glassBorder => Colors.white.withValues(alpha: 0.92);
  static Color get shadow => const Color(0xFF1F2A37).withValues(alpha: 0.08);
}
