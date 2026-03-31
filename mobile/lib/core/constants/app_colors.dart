import 'package:flutter/material.dart';

class AppColors {
  // Brand Colors
  static const primary     = Color(0xFF6236FF); // Royal Purple
  static const secondary   = Color(0xFFB5A1FF); // Light Purple Accent
  
  // Backgrounds & Surface
  static const background  = Color(0xFFFFFFFF);
  static const surface     = Color(0xFFF8F9FE);
  
  // Text Colors
  static const textPrimary = Color(0xFF1A1A1A);
  static const textSecondary = Color(0xFF6B7280);
  
  // Status Colors
  static const success     = Color(0xFF27AE60);
  static const alert       = Color(0xFFEB5757);
  
  // Gradients
  static const gradientPurple = LinearGradient(
    colors: [Color(0xFF6236FF), Color(0xFFB5A1FF)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
