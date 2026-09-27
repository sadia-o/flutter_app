import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTypography {
  static const String primaryFontFamily = 'Manrope';

  static TextStyle get manropeExtraBold =>
      GoogleFonts.manrope(fontWeight: FontWeight.w800);

  static TextStyle get manropeBold =>
      GoogleFonts.manrope(fontWeight: FontWeight.w700);

  static TextStyle get manropeSemiBold =>
      GoogleFonts.manrope(fontWeight: FontWeight.w600);

  static TextStyle get manropeMedium =>
      GoogleFonts.manrope(fontWeight: FontWeight.w500);

  static TextStyle get manropeRegular =>
      GoogleFonts.manrope(fontWeight: FontWeight.w400);

  // JetBrains Mono
  static TextStyle get jetbrainsMonoExtraBold =>
      GoogleFonts.jetBrainsMono(fontWeight: FontWeight.w800);

  static TextStyle get jetbrainsMonoBold =>
      GoogleFonts.jetBrainsMono(fontWeight: FontWeight.w700);

  static TextStyle get jetbrainsMonoMedium =>
      GoogleFonts.jetBrainsMono(fontWeight: FontWeight.w500);

  static TextStyle get jetbrainsMonoRegular =>
      GoogleFonts.jetBrainsMono(fontWeight: FontWeight.w400);

  // Inter
  static TextStyle get interBold =>
      GoogleFonts.inter(fontWeight: FontWeight.w700);

  static TextStyle get interSemiBold =>
      GoogleFonts.inter(fontWeight: FontWeight.w600);

  static TextStyle get interMedium =>
      GoogleFonts.inter(fontWeight: FontWeight.w500);

  static TextStyle get interRegular =>
      GoogleFonts.inter(fontWeight: FontWeight.w400);
}
