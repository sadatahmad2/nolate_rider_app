import 'package:flutter/material.dart';

class AppColors {
  // Main Background
  static const Color background = Color(0xFF0F0F13);
  static const Color surface = Color(0xFF1A1A24);
  static const Color surfaceLight = Color(0xFF262635);

  // Accents
  static const Color primary = Color(0xFFFF6B35); // Vibrant Orange
  static const Color secondary = Color(0xFF4A90E2); // Bright Blue
  static const Color success = Color(0xFF4ade80); // Neon Green
  static const Color error = Color(0xFFF87171); // Soft Red
  static const Color gold = Color(0xFFFFB800); // Premium Gold

  // Text
  static const Color textPrimary = Color(0xFFF3F4F6);
  static const Color textSecondary = Color(0xFF9CA3AF);
  static const Color textMuted = Color(0xFF6B7280);

  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFFFF6B35), Color(0xFFFF8E5E)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient darkGradient = LinearGradient(
    colors: [Color(0xFF1A1A24), Color(0xFF0F0F13)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );
  
  static const LinearGradient greenGradient = LinearGradient(
    colors: [Color(0xFF4ade80), Color(0xFF22c55e)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient purpleGradient = LinearGradient(
    colors: [Color(0xFFa855f7), Color(0xFF9333ea)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  static const LinearGradient goldGradient = LinearGradient(
    colors: [Color(0xFFFFB800), Color(0xFFF59E0B)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
