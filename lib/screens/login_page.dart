import 'package:flutter/material.dart';
import 'package:mizaniflutter/screens/signup_page.dart';
import 'package:mizaniflutter/screens/widgetpages/Home/home_widget.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
// تأكد من استيراد صفحتك الرئيسية (HomePage) هنا
// 🔴 مثال: تأكد من المسار الصحيح لصفحتك الرئيسية

// الوصول إلى عميل Supabase المهيأ عالمياً
final supabase = Supabase.instance.client;

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  // متحكمات حقول الإدخال للبريد الإلكتروني وكلمة المرور
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  // 🔴 حالة التحميل لعرض مؤشر التحميل أثناء العملية
  bool _isLoading = false;

  // التأكد من التخلص من المتحكمات عند إغلاق الـ Widget لتجنب تسرب الذاكرة
  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // 🔴 دالة تسجيل الدخول باستخدام Supabase
  Future<void> _signIn() async {
    setState(() {
      _isLoading = true; // تفعيل حالة التحميل
    });
    try {
      final AuthResponse res = await supabase.auth.signInWithPassword(
        email: _emailController.text
            .trim(), // 🔴 استخدام trim() لإزالة المسافات البيضاء
        password: _passwordController.text
            .trim(), // 🔴 استخدام trim() لإزالة المسافات البيضاء
      );

      // التحقق مما إذا كان تسجيل الدخول ناجحاً والمستخدم موجوداً
      if (res.user != null) {
        // 🔴 التحقق من تأكيد البريد الإلكتروني
        // يتم تحديث بيانات المستخدم بعد تسجيل الدخول، لذا يمكن التحقق هنا
        final User? currentUser =
            supabase.auth.currentUser; // جلب أحدث بيانات المستخدم

        if (currentUser != null && currentUser.emailConfirmedAt != null) {
          // البريد الإلكتروني مؤكد، يمكن الانتقال إلى الصفحة الرئيسية
          if (mounted) {
            // 🔴 التحقق من mounted قبل التفاعل مع السياق
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('تم تسجيل الدخول بنجاح!'),
                backgroundColor: Colors.green,
              ),
            );
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(
                builder: (_) => const HomeWidgest(),
              ), // 🔴 صفحتك الرئيسية
            );
          }
        } else {
          // 🔴 البريد الإلكتروني غير مؤكد
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'البريد الإلكتروني لم يتم تأكيده بعد. يرجى التحقق من بريدك لإكمال التسجيل.',
                ),
                backgroundColor: Colors.orange,
              ),
            );
            // تسجيل الخروج للمستخدم لمنعه من البقاء في حالة "مسجل دخول ولكن غير مؤكد"
            await supabase.auth.signOut();
          }
        }
      }
    } on AuthException catch (e) {
      // التعامل مع أخطاء المصادقة (مثل كلمة مرور خاطئة، مستخدم غير موجود)
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ في تسجيل الدخول: ${e.message}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      // التعامل مع أي أخطاء أخرى غير متوقعة
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('حدث خطأ غير متوقع: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false; // تعطيل حالة التحميل
        });
      }
    }
  }

  // 🔴 دالة لإعادة إرسال بريد التحقق
  Future<void> _resendVerificationEmail() async {
    if (_emailController.text.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('الرجاء إدخال البريد الإلكتروني لإعادة الإرسال.'),
          ),
        );
      }
      return;
    }
    setState(() {
      _isLoading = true;
    });
    try {
      // 🔴 تم تغيير اسم الدالة من resendAllConfirmationEmails إلى resend
      await supabase.auth.resend(
        type:
            OtpType.signup, // تحديد نوع الـ OTP المطلوب، في هذه الحالة للتسجيل
        email: _emailController.text.trim(),
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم إعادة إرسال بريد التحقق. يرجى التحقق من بريدك.'),
          ),
        );
      }
    } on AuthException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ في إعادة الإرسال: ${e.message}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // استخدام MediaQuery للحصول على أبعاد الشاشة لزيادة الاستجابة
    final screenWidth = MediaQuery.of(context).size.width;
    // تحديد عرض البطاقة بشكل أكثر استجابة
    final cardWidth = screenWidth > 600 ? 400.0 : screenWidth * 0.9;
    final textFieldWidth = cardWidth * 0.8; // عرض حقول الإدخال بالنسبة للبطاقة

    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(
                width: cardWidth,
                child: Card(
                  elevation: 10,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(25.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // 🔴 تأكد أن مسار الصورة صحيح وأنها معرفة في pubspec.yaml
                        // مثال على تعريف الصورة في pubspec.yaml:
                        // assets:
                        //   - images/logo.png
                        Image.asset(
                          "images/logo.png",
                          width: 120, // زيادة حجم الشعار قليلاً
                          height: 120, // إضافة ارتفاع لضمان تناسق الأبعاد
                        ),
                        const SizedBox(height: 30),

                        SizedBox(
                          width: textFieldWidth,
                          child: TextField(
                            controller: _emailController,
                            decoration: const InputDecoration(
                              labelText: 'البريد الإلكتروني',
                              hintText: 'ادخل بريدك الإلكتروني',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.email),
                            ),
                            keyboardType: TextInputType.emailAddress,
                          ),
                        ),
                        const SizedBox(height: 20),

                        SizedBox(
                          width: textFieldWidth,
                          child: TextField(
                            controller: _passwordController,
                            obscureText: true,
                            decoration: const InputDecoration(
                              labelText: 'كلمة المرور',
                              hintText: 'ادخل كلمة المرور',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.lock),
                            ),
                          ),
                        ),
                        const SizedBox(height: 15),

                        // 🔴 لجعل زر "هل نسيت كلمة المرور؟" محاذياً لليمين
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: () {
                              // منطق هل نسيت كلمة المرور؟
                              // يمكن هنا الانتقال لصفحة طلب إعادة تعيين كلمة المرور
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'الانتقال لصفحة استعادة كلمة المرور',
                                    ),
                                  ),
                                );
                              }
                            },
                            child: const Text(
                              "هل نسيت كلمة المرور؟",
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.blueAccent,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 25),

                        // 🔴 عرض مؤشر التحميل أو زر تسجيل الدخول
                        _isLoading
                            ? const CircularProgressIndicator()
                            : SizedBox(
                                width: textFieldWidth,
                                child: ElevatedButton(
                                  onPressed:
                                      _signIn, // 🔴 استدعاء دالة تسجيل الدخول
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.green.shade700,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 14,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    elevation: 5,
                                  ),
                                  child: const Text(
                                    "تسجيل الدخول",
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                        const SizedBox(height: 15),

                        // 🔴 زر لإعادة إرسال بريد التحقق
                        // إظهاره فقط عندما لا يكون هناك تحميل
                        if (!_isLoading)
                          TextButton(
                            onPressed: _resendVerificationEmail,
                            child: const Text(
                              "إعادة إرسال بريد التحقق",
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.orange,
                              ),
                            ),
                          ),
                        const SizedBox(height: 10),

                        TextButton(
                          onPressed: () {
                            // الانتقال إلى صفحة التسجيل
                            if (mounted) {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => const SignupPage(),
                                ),
                              );
                            }
                          },
                          child: const Text(
                            "ليس لديك حساب؟ سجل الآن",
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.blueGrey,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
