import 'package:flutter/material.dart';
import 'package:mizaniflutter/Theme/dark_theme_page.dart';
import 'package:mizaniflutter/Theme/light_them_page.dart';
import 'package:mizaniflutter/auth_checker.dart';
import 'package:mizaniflutter/screens/login_page.dart';
import 'package:mizaniflutter/screens/profil_page.dart';
import 'package:mizaniflutter/screens/signup_page.dart';
import 'package:mizaniflutter/screens/widgetpages/Home/home_widget.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

// 🔴 استيراد الـ AuthChecker الذي سيتولى منطق التحقق من تسجيل الدخول

// 🔴 إضافة ValueNotifier لإدارة حالة الثيم
// يتم تهيئته لاحقًا بعد تحميل الإعدادات المحفوظة
final ValueNotifier<ThemeMode> themeModeNotifier = ValueNotifier(
  ThemeMode.system,
);

// 🔴 مفتاح حفظ الثيم في SharedPreferences
const String _themeModeKey = 'themeMode';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // تأكد من أن الـ URL والـ Anon Key صحيحان لمشروعك في Supabase
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
          // 🔴 تحديد الثيم الفاتح وتضمين NavigationRailThemeData
          theme: lightThemePage().lightTheme().copyWith(
            navigationRailTheme: NavigationRailThemeData(
              // لون التأشير (hover) للثيم الفاتح
              selectedIconTheme: const IconThemeData(color: Color(0xFF2D6A4F)),
              unselectedIconTheme: IconThemeData(color: Colors.grey[600]),
            ),
            // يمكنك إضافة المزيد من التخصيصات العالمية للثيم هنا
          ),
          // 🔴 تحديد الثيم الداكن وتضمين NavigationRailThemeData
          darkTheme: DarkThemePage().darkTheme().copyWith(
            navigationRailTheme: NavigationRailThemeData(
              // لون التأشير (hover) للثيم الداكن
              selectedIconTheme: const IconThemeData(color: Colors.white),
              unselectedIconTheme: IconThemeData(color: Colors.grey[400]),
            ),
            // يمكنك إضافة المزيد من التخصيصات العالمية للثيم هنا
          ),
          themeMode:
              currentThemeMode, // يستخدم الثيم الحالي من themeModeNotifier
          // 🔴 استخدام AuthChecker كنقطة بداية للتطبيق
          home: const AuthChecker(),
          // 🔴 تحديد روت التطبيق
          routes: {
            '/login': (context) => const LoginPage(),
            '/register': (context) => const SignupPage(),
            '/profil': (context) => const PersonalInformationPage(),
            '/home': (context) => const HomeWidgest(),
            '/signup': (context) => const SignupPage(),
          },
        );
      },
    );
  }
}
