import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Brand colors
  static const Color primary = Color(0xFF1B5E20);       // Deep green
  static const Color primaryLight = Color(0xFF4CAF50);
  static const Color accent = Color(0xFFF9A825);         // Amber
  static const Color background = Color(0xFFF5F5F5);
  static const Color surface = Colors.white;
  static const Color sidebarBg = Color(0xFF1B2B1E);      // Dark green sidebar
  static const Color sidebarActive = Color(0xFF2E7D32);
  static const Color sidebarText = Color(0xFFCCE5CC);
  static const Color cardBorder = Color(0xFFE0E0E0);
  static const Color danger = Color(0xFFC62828);
  static const Color info = Color(0xFF1565C0);

  static ThemeData get lightTheme => ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: primary,
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: background,
        textTheme: GoogleFonts.interTextTheme(),
        cardTheme: CardThemeData(
          color: surface,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: const BorderSide(color: cardBorder),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: cardBorder),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: cardBorder),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: primaryLight, width: 2),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: primary,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        ),
        dataTableTheme: DataTableThemeData(
          headingRowColor: WidgetStateProperty.all(const Color(0xFFE8F5E9)),
          dataRowColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.hovered)) {
              return const Color(0xFFF1F8E9);
            }
            return Colors.white;
          }),
          headingTextStyle: GoogleFonts.inter(
            fontWeight: FontWeight.w600,
            fontSize: 13,
            color: primary,
          ),
          dataTextStyle: GoogleFonts.inter(fontSize: 13),
          dividerThickness: 1,
          horizontalMargin: 16,
          columnSpacing: 20,
        ),
      );
}