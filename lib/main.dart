import 'package:flutter/material.dart';
import 'package:mizaniflutter/Theme/dark_theme_page.dart';
import 'package:mizaniflutter/Theme/light_them_page.dart';
// تأكد من استخدامه إذا كان ضرورياً
import 'package:mizaniflutter/screens/login_page.dart';
// تأكد من المسار الصحيح
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart'; // 🔴 استيراد shared_preferences

// 🔴 إضافة ValueNotifier لإدارة حالة الثيم
// يتم تهيئته لاحقًا بعد تحميل الإعدادات المحفوظة
final ValueNotifier<ThemeMode> themeModeNotifier = ValueNotifier(
  ThemeMode.system,
);

// 🔴 مفتاح حفظ الثيم في SharedPreferences
const String _themeModeKey = 'themeMode';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://uhxniafzyttpqpcxateo.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InVoeG5pYWZ6eXR0cHFwY3hhdGVvIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTA1MDc1OTMsImV4cCI6MjA2NjA4MzU5M30.s-_L0okwAv6czNdYAPqGkGzK6HjwBgCpfmh9IHKjDPo',
  );

  // 🔴 تحميل الثيم المحفوظ
  await _loadThemeMode();

  runApp(const MyApp());
}

// 🔴 دالة لتحميل الثيم من SharedPreferences
Future<void> _loadThemeMode() async {
  final prefs = await SharedPreferences.getInstance();
  final savedTheme = prefs.getString(_themeModeKey); // قراءة الثيم كـ String

  ThemeMode initialThemeMode;
  switch (savedTheme) {
    case 'light':
      initialThemeMode = ThemeMode.light;
      break;
    case 'dark':
      initialThemeMode = ThemeMode.dark;
      break;
    default: // في حال عدم وجود قيمة محفوظة أو كانت غير صالحة
      initialThemeMode = ThemeMode.system;
      break;
  }
  themeModeNotifier.value = initialThemeMode; // تحديث قيمة الـ ValueNotifier
}

// 🔴 دالة لحفظ الثيم في SharedPreferences
Future<void> saveThemeMode(ThemeMode themeMode) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString(
    _themeModeKey,
    themeMode.toString().split('.').last,
  ); // حفظ كـ String (مثل 'light', 'dark', 'system')
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // 🔴 استخدام ValueListenableBuilder للاستماع لتغييرات الثيم
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeModeNotifier,
      builder: (context, currentThemeMode, child) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'Mizani Flutter App',
          theme: lightThemePage().lightTheme(), // الثيم الافتراضي للوضع الفاتح
          darkTheme: DarkThemePage().darkTheme(), // الثيم للوضع الداكن
          themeMode:
              currentThemeMode, // يستخدم الثيم الحالي من themeModeNotifier

          home: LoginPage(), // HomeWidgest هو نقطة البداية لتطبيقك
        );
      },
    );
  }
}
