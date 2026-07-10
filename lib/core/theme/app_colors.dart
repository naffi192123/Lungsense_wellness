import 'package:flutter/material.dart';

/// Centralized color palette for the LungSense Wellness application.
/// Strictly adheres to the premium healthcare design guidelines.
abstract class AppColors {
  /// Primary color: #91D14D (Green accent for primary elements)
  static const Color primary = Color(0xFF91D14D);

  /// Secondary color: #60CFD3 (Teal/Cyan accent for secondary highlights)
  static const Color secondary = Color(0xFF60CFD3);

  /// Accent color: #D698EC (Purple/Lavender accent for special elements)
  static const Color accent = Color(0xFFD698EC);

  /// Text color: #140F2D (Very dark purple/navy for text and contrast)
  static const Color text = Color(0xFF140F2D);

  /// Secondary Text color: A muted version of the text color for subtitles
  static const Color textSecondary = Color(0xFF5C5870);

  /// Background color: #F8FAFC (Soft grey-blue background for screens)
  static const Color background = Color(0xFFF8FAFC);

  /// Surface color: #FFFFFF (White cards, sheets, and dialogs)
  static const Color surface = Color(0xFFFFFFFF);

  /// Supporting Green: #5A7438 (Dark forest green for icons and borders)
  static const Color supportingGreen = Color(0xFF5A7438);

  /// Alert and feedback colors
  static const Color success = Color(0xFF4CAF50);
  static const Color warning = Color(0xFFFFB74D);
  static const Color error = Color(0xFFE53935);
  static const Color info = Color(0xFF2196F3);

  /// Border and divider color
  static const Color border = Color(0xFFE2E8F0);
}
