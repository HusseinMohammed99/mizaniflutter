import 'package:flutter/material.dart';
import 'package:mizaniflutter/app-color.dart';

class DarkThemePage extends StatefulWidget {
  const DarkThemePage({super.key});
  // ============= تعريف الثيم الداكن =============
  ThemeData darkTheme() {
    return ThemeData(
      brightness: Brightness.dark,
      primaryColor: AppColors.darkPrimary,
      colorScheme: ColorScheme.dark(
        primary: AppColors.darkPrimary,
        onPrimary: AppColors.darkOnPrimary,
        secondary: AppColors.darkSecondary,
        onSecondary: AppColors.darkOnSecondary,
        error: AppColors.darkError,
        onError: AppColors.darkOnError,
        surface: AppColors.darkSurface,
        onSurface: AppColors.darkOnSurface,
      ),
      // appBarTheme: AppBarTheme(
      //   backgroundColor: AppColors.darkPrimary,
      //   foregroundColor: AppColors.darkOnPrimary,
      //   centerTitle: true,
      //   elevation: 4,
      // ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: AppColors.darkSecondary,
        foregroundColor: AppColors.darkOnSecondary,
      ),
      scaffoldBackgroundColor: AppColors.darkBackground,
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.darkBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.darkPrimary, width: 2),
        ),
        labelStyle: TextStyle(
          color: AppColors.darkOnBackground.withOpacity(0.7),
        ),
        hintStyle: TextStyle(
          color: AppColors.darkOnBackground.withOpacity(0.5),
        ),
      ),
      cardTheme: CardThemeData(
        // 🔴 هنا كان CardThemeData تم تصحيحه إلى CardTheme
        color: AppColors.darkSurface,
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: AppColors.darkSurface,
        selectedItemColor: AppColors.darkPrimary,
        unselectedItemColor: AppColors.darkOnSurface.withOpacity(0.6),
        elevation: 8,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.darkPrimary,
          foregroundColor: AppColors.darkOnPrimary,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.darkOnSurface,
        contentTextStyle: TextStyle(color: AppColors.darkSurface),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: AppColors.darkPrimary),
      ),
      iconTheme: IconThemeData(
        color: AppColors.darkOnBackground.withOpacity(0.8),
      ),
      textTheme: TextTheme(
        headlineLarge: TextStyle(
          fontSize: 32.0,
          fontWeight: FontWeight.bold,
          color: AppColors.darkOnBackground,
        ),
        headlineMedium: TextStyle(
          fontSize: 28.0,
          fontWeight: FontWeight.bold,
          color: AppColors.darkOnBackground,
        ),
        headlineSmall: TextStyle(
          fontSize: 24.0,
          fontWeight: FontWeight.bold,
          color: AppColors.darkOnBackground,
        ),
        bodyLarge: TextStyle(fontSize: 16.0, color: AppColors.darkOnBackground),
        bodyMedium: TextStyle(
          fontSize: 14.0,
          color: AppColors.darkOnBackground,
        ),
        bodySmall: TextStyle(
          fontSize: 12.0,
          color: AppColors.darkOnBackground.withOpacity(0.7),
        ),
      ),
    );
  }

  @override
  State<DarkThemePage> createState() => _DarkThemeState();
}

class _DarkThemeState extends State<DarkThemePage> {
  @override
  Widget build(BuildContext context) {
    return DarkThemePage();
  }
}
