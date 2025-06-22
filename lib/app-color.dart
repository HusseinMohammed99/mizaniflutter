// lib/app_colors.dart
import 'package:flutter/material.dart';

class AppColors {
  // ==================== ألوان الوضع الفاتح ====================
  static const Color lightPrimary = Color(0xFF6200EE); // بنفسجي
  static const Color lightOnPrimary = Colors.white;
  static const Color lightSecondary = Color(0xFF03DAC6); // فيروزي
  static const Color lightOnSecondary = Colors.black;
  static const Color lightError = Color(0xFFB00020);
  static const Color lightOnError = Colors.white;
  static const Color lightBackground = Color(
    0xFFF0F2F5,
  ); // رمادي فاتح جداً للخلفية
  static const Color lightOnBackground = Colors.black87;
  static const Color lightSurface = Colors.white; // أبيض للبطاقات والأسطح
  static const Color lightOnSurface = Colors.black87;
  static const Color lightBorder = Colors.grey;

  // ألوان الرسوم البيانية للوضع الفاتح
  static const Color lightSalaryChartColor = Color(0xFF4CAF50); // أخضر للراتب
  static const Color lightExpenseChartColor = Color(
    0xFFF44336,
  ); // أحمر للمصروفات
  static const Color lightSavingChartColor = Color(0xFF2196F3); // أزرق للادخار
  static const Color lightDebtChartColor = Color(0xFFFF9800); // برتقالي للديون
  static const Color lightCreditChartColor = Color(0xFF9C27B0); // بنفسجي للدائن

  // ==================== ألوان الوضع الداكن ====================
  static const Color darkPrimary = Color(
    0xFFBB86FC,
  ); // بنفسجي فاتح (مقابل لـ lightPrimary)
  static const Color darkOnPrimary = Colors.black;
  static const Color darkSecondary = Color(
    0xFF03DAC6,
  ); // نفس الفيروزي (يعمل جيدًا في الداكن)
  static const Color darkOnSecondary = Colors.black;
  static const Color darkError = Color(0xFFCF6679);
  static const Color darkOnError = Colors.black;
  static const Color darkBackground = Color(
    0xFF121212,
  ); // أسود داكن جداً للخلفية
  static const Color darkOnBackground = Colors.white;
  static const Color darkSurface = Color(
    0xFF1E1E1E,
  ); // رمادي داكن للبطاقات والأسطح
  static const Color darkOnSurface = Colors.white;
  static const Color darkBorder = Color(0xFF424242); // رمادي أغمق للحدود

  // ألوان الرسوم البيانية للوضع الداكن (قد تكون ألواناً أفتح قليلاً للوضوح)
  static const Color darkSalaryChartColor = Color(
    0xFF81C784,
  ); // أخضر فاتح للراتب
  static const Color darkExpenseChartColor = Color(
    0xFFEF9A9A,
  ); // أحمر فاتح للمصروفات
  static const Color darkSavingChartColor = Color(
    0xFF64B5F6,
  ); // أزرق فاتح للادخار
  static const Color darkDebtChartColor = Color(
    0xFFFFCC80,
  ); // برتقالي فاتح للديون
  static const Color darkCreditChartColor = Color(
    0xFFCE93D8,
  ); // بنفسجي فاتح للدائن
}
