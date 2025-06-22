// ============= تعريف الثيم الفاتح =============
import 'package:flutter/material.dart';
import 'package:mizaniflutter/app-color.dart';

class lightThemePage extends StatefulWidget {
  const lightThemePage({super.key});
  ThemeData lightTheme() {
    return ThemeData(
      brightness: Brightness.light,
      primaryColor: AppColors.lightSalaryChartColor,
      colorScheme: ColorScheme.light(
        primary: AppColors.lightPrimary,
        onPrimary: AppColors.lightOnPrimary,
        secondary: AppColors.lightSecondary,
        onSecondary: AppColors.lightOnSecondary,
        error: AppColors.lightError,
        onError: AppColors.lightOnError,
        background: AppColors.lightBackground,
        onBackground: AppColors.lightOnBackground,
        surface: AppColors.lightSurface,
        onSurface: AppColors.lightOnSurface,
      ),
      // appBarTheme: AppBarTheme(
      //   backgroundColor: AppColors.lightPrimary,
      //   foregroundColor: AppColors.lightOnPrimary,
      //   centerTitle: true,
      //   elevation: 4,
      // ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: AppColors.lightSecondary,
        foregroundColor: AppColors.lightOnSecondary,
      ),
      scaffoldBackgroundColor: AppColors.lightBackground,
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.lightBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.lightPrimary, width: 2),
        ),
        labelStyle: TextStyle(
          color: AppColors.lightOnBackground.withOpacity(0.7),
        ),
        hintStyle: TextStyle(
          color: AppColors.lightOnBackground.withOpacity(0.5),
        ),
      ),
      cardTheme: CardThemeData(
        // 🔴 هنا كان CardThemeData تم تصحيحه إلى CardTheme
        color: AppColors.lightSurface,
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: AppColors.lightSurface,
        selectedItemColor: AppColors.lightPrimary,
        unselectedItemColor: AppColors.lightOnSurface.withOpacity(0.6),
        elevation: 8,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.lightPrimary,
          foregroundColor: AppColors.lightOnPrimary,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.lightOnSurface,
        contentTextStyle: TextStyle(color: AppColors.lightSurface),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: AppColors.lightPrimary),
      ),
      iconTheme: IconThemeData(
        color: AppColors.lightOnBackground.withOpacity(0.8),
      ),
      textTheme: TextTheme(
        headlineLarge: TextStyle(
          fontSize: 32.0,
          fontWeight: FontWeight.bold,
          color: AppColors.lightOnBackground,
        ),
        headlineMedium: TextStyle(
          fontSize: 28.0,
          fontWeight: FontWeight.bold,
          color: AppColors.lightOnBackground,
        ),
        headlineSmall: TextStyle(
          fontSize: 24.0,
          fontWeight: FontWeight.bold,
          color: AppColors.lightOnBackground,
        ),
        bodyLarge: TextStyle(
          fontSize: 16.0,
          color: AppColors.lightOnBackground,
        ),
        bodyMedium: TextStyle(
          fontSize: 14.0,
          color: AppColors.lightOnBackground,
        ),
        bodySmall: TextStyle(
          fontSize: 12.0,
          color: AppColors.lightOnBackground.withOpacity(0.7),
        ),
      ),
    );
  }

  @override
  State<lightThemePage> createState() => _lightThemePageState();
}

class _lightThemePageState extends State<lightThemePage> {
  @override
  Widget build(BuildContext context) {
    return lightThemePage();
  }
}
