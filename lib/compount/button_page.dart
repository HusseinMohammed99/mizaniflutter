import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
// 🔴 استورد صفحة تسجيل الدخول الخاصة بك هنا
// على سبيل المثال: import 'package:mizaniflutter/screens/signup_page.dart';
// أو أي صفحة تريد الانتقال إليها بعد تسجيل الخروج.
// لتوضيح المثال، سأستخدم صفحة مؤقتة.

// الوصول إلى عميل Supabase
final supabase = Supabase.instance.client;

class LogoutButtonWidget extends StatefulWidget {
  const LogoutButtonWidget({super.key});

  @override
  State<LogoutButtonWidget> createState() => _LogoutButtonWidgetState();
}

class _LogoutButtonWidgetState extends State<LogoutButtonWidget> {
  bool _isLoading = false; // حالة التحميل لزر تسجيل الخروج

  // 🔴 دالة للانتقال إلى صفحة تسجيل الدخول أو أي صفحة بداية أخرى
  void _navigateToLoginPage() {
    if (mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (_) => const Scaffold(
            body: Center(
              child: Text(
                'تم تسجيل الخروج. يرجى تسجيل الدخول مجدداً.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 18),
              ),
            ),
          ),
        ),
        (route) => false, // هذا يزيل جميع المسارات السابقة من المكدس
      );
    }
  }

  // 🔴 دالة لعرض رسائل للمستخدم (SnackBar)
  void _showMessage(String message, Color color) {
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message), backgroundColor: color));
    }
  }

  // 🔴 دالة لتسجيل الخروج من Supabase
  Future<void> _signOut() async {
    setState(() {
      _isLoading = true; // تفعيل حالة التحميل
    });

    try {
      await supabase.auth
          .signOut(); // استدعاء دالة تسجيل الخروج من Supabase Auth

      _showMessage('تم تسجيل الخروج بنجاح!', Colors.green);
      _navigateToLoginPage(); // الانتقال إلى صفحة تسجيل الدخول
    } on AuthException catch (e) {
      // التعامل مع أخطاء المصادقة (AuthException)
      _showMessage('خطأ في تسجيل الخروج: ${e.message}', Colors.red);
      print('Supabase logout error: ${e.message}'); // للتبديل/التصحيح
    } catch (e) {
      // التعامل مع أي أخطاء غير متوقعة أخرى
      _showMessage('حدث خطأ غير متوقع أثناء تسجيل الخروج: $e', Colors.red);
      print('Unexpected logout error: $e'); // للتبديل/التصحيح
    } finally {
      setState(() {
        _isLoading = false; // تعطيل حالة التحميل دائماً
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: _isLoading ? null : _signOut, // تعطيل الزر أثناء التحميل
      icon: _isLoading
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            )
          : const Icon(Icons.logout), // أيقونة تسجيل الخروج
      label: Text(
        _isLoading ? 'جاري تسجيل الخروج...' : 'تسجيل الخروج',
        style: const TextStyle(fontSize: 16),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.red.shade700, // لون أحمر لزر تسجيل الخروج
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        elevation: 5,
      ),
    );
  }
}

/*
كيفية استخدام هذا الزر في تطبيقك:

يمكنك وضع هذا الـ Widget في أي مكان في شجرة الـ Widgets الخاصة بك.
على سبيل المثال، في صفحة الإعدادات (Settings Page) أو في قائمة جانبية (Drawer):

import 'package:flutter/material.dart';
import 'package:mizaniflutter/screens/widgetpages/authentication/logout_button_widget.dart'; // تأكد من المسار

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('الإعدادات'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('محتويات صفحة الإعدادات...'),
            const SizedBox(height: 30),
            const LogoutButtonWidget(), // 🔴 وضع زر تسجيل الخروج هنا
          ],
        ),
      ),
    );
  }
}
*/
