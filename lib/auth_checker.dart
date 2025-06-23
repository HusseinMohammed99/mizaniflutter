import 'package:flutter/material.dart';
import 'package:mizaniflutter/screens/widgetpages/Home/home_widget.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:mizaniflutter/screens/login_page.dart'; // 🔴 تأكد من المسار الصحيح لصفحة تسجيل الدخول
// 🔴 تأكد من المسار الصحيح لصفحتك الرئيسية

// الوصول إلى عميل Supabase المهيأ عالمياً
final supabase = Supabase.instance.client;

// هذا الـ Widget سيكون نقطة الدخول لتطبيقك في `main.dart`
// يقوم بالاستماع لتغييرات حالة المصادقة في Supabase وتوجيه المستخدم بناءً عليها.
class AuthChecker extends StatefulWidget {
  const AuthChecker({super.key});

  @override
  State<AuthChecker> createState() => _AuthCheckerState();
}

class _AuthCheckerState extends State<AuthChecker> {
  // قناة الاستماع لحالة المصادقة
  late final Stream<AuthState> _authStateChanges;

  @override
  void initState() {
    super.initState();
    // 🔴 الاستماع إلى تغييرات حالة المصادقة من Supabase
    // هذا Stream يرسل حدثاً كلما تغيرت حالة المستخدم (تسجيل دخول، خروج، تجديد جلسة)
    _authStateChanges = supabase.auth.onAuthStateChange;
  }

  @override
  Widget build(BuildContext context) {
    // StreamBuilder يستمع إلى التغييرات في _authStateChanges ويعيد بناء الواجهة
    return StreamBuilder<AuthState>(
      stream: _authStateChanges,
      builder: (context, snapshot) {
        // إذا كان الاتصال لا يزال في انتظار البيانات الأولية، اعرض مؤشر تحميل
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(), // مؤشر تحميل دائري
            ),
          );
        }

        // جلب جلسة المستخدم ونوع الحدث وبيانات المستخدم من الـ snapshot
        final session = snapshot.data?.session; // جلسة المستخدم الحالية
        // final event = snapshot.data?.event;    // نوع الحدث (SIGNED_IN, SIGNED_OUT, etc.) - لم يتم استخدامه مباشرة هنا ولكن مفيد
        final user = snapshot.data?.session?.user; // بيانات كائن المستخدم

        // 🔴 المنطق الرئيسي:
        // إذا كان هناك جلسة نشطة (المستخدم مسجل دخول)
        if (session != null) {
          // 🔴 التحقق من تأكيد البريد الإلكتروني للمستخدم
          // إذا كان البريد الإلكتروني مؤكداً (emailConfirmedAt ليس null)
          if (user != null && user.emailConfirmedAt != null) {
            // البريد الإلكتروني مؤكد، انتقل إلى الصفحة الرئيسية
            return const HomeWidgest(); // 🔴 صفحتك الرئيسية بعد تسجيل الدخول
          } else {
            // البريد الإلكتروني غير مؤكد، أو تم تسجيل الدخول بطريقة لا تتطلب تأكيداً فورياً
            // في هذه الحالة، نعيدهم إلى صفحة تسجيل الدخول، ويمكنهم من هناك محاولة تسجيل الدخول
            // مرة أخرى بعد التأكيد أو استخدام خيار "إعادة إرسال بريد التحقق".
            return const HomeWidgest(); // 🔴 صفحة تسجيل الدخول
          }
        } else {
          // 🔴 لا توجد جلسة (المستخدم غير مسجل دخول على الإطلاق)
          // في هذه الحالة، نأخذهم مباشرة إلى صفحة تسجيل الدخول.
          return const LoginPage(); // 🔴 صفحة تسجيل الدخول
        }
      },
    );
  }
}
