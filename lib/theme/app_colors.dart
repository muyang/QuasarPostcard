import 'package:flutter/material.dart';

/// Centralized UI theme colors used across the app.
///
/// Template/stamp/postmark domain colors (gradients, accent colors, etc.)
/// stay inline in [PostcardTemplate] and related models since they are
/// data, not UI chrome.
class AppColors {
  AppColors._();

  // Brand
  static const primary = Color(0xFF7C4DFF);
  static const primaryLight = Color(0xFF9B7BFF);
  static const secondary = Color(0xFFB794FF);

  // Surfaces & backgrounds
  static const background = Color(0xFF0D0D1A);
  static const scaffoldBackground = Color(0xFF121212);
  static const surface = Color(0xFF1A1A2E);
  static const surfaceVariant = Color(0xFF1E1E36);
  static const panelDark = Color(0xFF13132B);
  static const selectModeBg = Color(0xFF1A1030);
  static const inputFill = Color(0xFF2A2A4A);
  static const divider = Color(0xFF1E1E3A);

  // Text
  static const textPrimary = Colors.white;
  static const textMuted = Color(0xFF666688);
  static const textDim = Color(0xFF555577);
  static const textFaint = Color(0xFF444466);
  static const textLabel = Color(0xFF888888);

  // Borders / outlines
  static const outline = Color(0xFF333355);
  static const borderDefault = Color(0xFF444444);

  // Status
  static const success = Color(0xFF4CAF50);
  static const error = Color(0xFFC62828);
  static const errorAccent = Colors.redAccent;

  // WeChat brand
  static const wechatGreen = Color(0xFF07C160);
  static const wechatGreenDark = Color(0xFF1B5E20);
  static const wechatGreenLight = Color(0xFF2EBD6F);

  // Misc functional
  static const shareBlue = Color(0xFF2196F3);
  static const emailRed = Color(0xFFEA4335);
  static const gold = Color(0xFFFF8F00);
  static const wavePattern = Color(0xFF4488AA);

  // Default template text colors (domain defaults, not UI chrome)
  static const defaultTextDark = Color(0xFF333333);
  static const defaultTextMid = Color(0xFF555555);
  static const defaultBorderGray = Color(0xFFCCCCCC);
  static const defaultBgWhite = Color(0xFFFFFFFF);
}
