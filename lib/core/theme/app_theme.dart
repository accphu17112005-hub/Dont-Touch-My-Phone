import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  AppTheme._();

  // Brand colors
  static const Color gradientTop = Color(0xFF6A1B9A);
  static const Color gradientMid = Color(0xFFAD1457);
  static const Color gradientBottom = Color(0xFFBF360C);
  static const Color purpleDark = Color(0xFF4A148C);
  static const Color purpleMid = Color(0xFF7B1FA2);
  static const Color pinkAccent = Color(0xFFFF4081);
  static const Color danger = Color(0xFFFF1744);
  static const Color success = Color(0xFF00E676);
  static const Color warning = Color(0xFFFF9100);
  static const Color cardWhite = Color(0xFFFFFFFF);
  static const Color cardSemiWhite = Color(0xFFF8F9FA);
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFFE0E0E0);
  static const Color textDark = Color(0xFF212121);
  static const Color textDarkSecondary = Color(0xFF616161);
  static const Color iconBgBlue = Color(0xFF1565C0);
  static const Color iconBgGreen = Color(0xFF2E7D32);
  static const Color iconBgOrange = Color(0xFFE65100);
  static const Color iconBgPurple = Color(0xFF6A1B9A);
  static const Color iconBgRed = Color(0xFFB71C1C);
  static const Color iconBgTeal = Color(0xFF00695C);

  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [gradientTop, gradientMid, gradientBottom],
    stops: [0.0, 0.5, 1.0],
  );

  static const LinearGradient cardGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF8E24AA), Color(0xFFAD1457)],
  );

  static const LinearGradient dangerGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFB71C1C), Color(0xFFD32F2F)],
  );

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: gradientTop,
        brightness: Brightness.light,
      ),
      textTheme: GoogleFonts.poppinsTextTheme().copyWith(
        displayLarge: GoogleFonts.poppins(
          fontSize: 32,
          fontWeight: FontWeight.w800,
          color: textDark,
        ),
        displayMedium: GoogleFonts.poppins(
          fontSize: 28,
          fontWeight: FontWeight.w700,
          color: textDark,
        ),
        headlineLarge: GoogleFonts.poppins(
          fontSize: 24,
          fontWeight: FontWeight.w700,
          color: textDark,
        ),
        headlineMedium: GoogleFonts.poppins(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: textDark,
        ),
        headlineSmall: GoogleFonts.poppins(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: textDark,
        ),
        bodyLarge: GoogleFonts.poppins(
          fontSize: 16,
          fontWeight: FontWeight.w400,
          color: textDark,
        ),
        bodyMedium: GoogleFonts.poppins(
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color: textDark,
        ),
        labelLarge: GoogleFonts.poppins(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.white),
        titleTextStyle: TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
      ),
      scaffoldBackgroundColor: const Color(0xFFF5F5F5),
      cardTheme: CardThemeData(
        color: cardWhite,
        elevation: 8,
        shadowColor: Colors.black26,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith<Color>((states) {
          if (states.contains(WidgetState.selected)) return gradientTop;
          return Colors.grey;
        }),
        trackColor: WidgetStateProperty.resolveWith<Color>((states) {
          if (states.contains(WidgetState.selected)) return gradientTop.withOpacity(0.4);
          return Colors.grey.withOpacity(0.3);
        }),
      ),
      sliderTheme: SliderThemeData(
        activeTrackColor: gradientTop,
        inactiveTrackColor: gradientTop.withOpacity(0.2),
        thumbColor: gradientTop,
        overlayColor: gradientTop.withOpacity(0.2),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: gradientTop,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          textStyle: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
          ),
          elevation: 4,
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Colors.white,
        selectedItemColor: gradientTop,
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        elevation: 16,
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: gradientTop,
        brightness: Brightness.dark,
      ),
      textTheme: GoogleFonts.poppinsTextTheme(ThemeData.dark().textTheme),
      scaffoldBackgroundColor: const Color(0xFF121212),
      cardTheme: CardThemeData(
        color: const Color(0xFF1E1E1E),
        elevation: 8,
        shadowColor: Colors.black54,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Color(0xFF1E1E1E),
        selectedItemColor: pinkAccent,
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        elevation: 16,
      ),
    );
  }
}
