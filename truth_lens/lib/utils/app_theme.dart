import 'package:flutter/material.dart';

/// App color palette
class AppColors {
  // Primary brand colors
  static const Color primary = Color(0xFF10B981);
  static const Color primaryDark = Color(0xFF059669);
  
  // Health score colors
  static const Color scoreGood = Color(0xFF22C55E);
  static const Color scoreModerate = Color(0xFFF59E0B);
  static const Color scorePoor = Color(0xFFEF4444);
  
  // Text colors
  static const Color textPrimary = Color(0xFF1F2937);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color textTertiary = Color(0xFF9CA3AF);
  
  // Background colors
  static const Color background = Color(0xFFFEF9F3);
  static const Color cardBackground = Colors.white;
  static const Color divider = Color(0xFFE5E7EB);
  
  /// Get color based on health score
  static Color getScoreColor(int score) {
    if (score >= 75) return scoreGood;
    if (score >= 50) return scoreModerate;
    return scorePoor;
  }
  
  /// Get gradient based on health score
  static LinearGradient getScoreGradient(int score) {
    if (score >= 75) {
      return const LinearGradient(
        colors: [Color(0xFF22C55E), Color(0xFF16A34A)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );
    }
    if (score >= 50) {
      return const LinearGradient(
        colors: [Color(0xFFF59E0B), Color(0xFFD97706)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );
    }
    return const LinearGradient(
      colors: [Color(0xFFEF4444), Color(0xFFDC2626)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );
  }
  
  /// Primary gradient for buttons
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primary, primaryDark],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}

/// App text styles
class AppTextStyles {
  static const TextStyle heading1 = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
    height: 1.2,
  );
  
  static const TextStyle heading2 = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
  );
  
  static const TextStyle heading3 = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );
  
  static const TextStyle body = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w400,
    color: AppColors.textPrimary,
    height: 1.6,
  );
  
  static const TextStyle bodySmall = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w400,
    color: AppColors.textSecondary,
  );
  
  static const TextStyle label = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w600,
    color: AppColors.textSecondary,
    letterSpacing: 0.5,
  );
}

/// Spacing constants
class AppSpacing {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;
}

/// Border radius constants
class AppRadius {
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 20;
  static const double xxl = 24;
}
