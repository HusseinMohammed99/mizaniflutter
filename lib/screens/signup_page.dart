import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:mizaniflutter/screens/widgetpages/Home/home_widget.dart'; // 🔴 تأكد من استيراد صفحتك الرئيسية الصحيحة هنا

// الوصول إلى عميل Supabase
final supabase = Supabase.instance.client;

class SignupPage extends StatefulWidget {
  const SignupPage({super.key});

  @override
  State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _isLoading = false;

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // ✅ دالة للانتقال إلى الصفحة الرئيسية
  void _navigateToHome() {
    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) =>
              const HomeWidgest(), // 🔴 استخدام صفحة HomeWidgets بدلاً من Scaffold مؤقت
        ),
      );
    }
  }

  // ✅ دالة لعرض رسائل للمستخدم
  void _showMessage(String text, Color color) {
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(text), backgroundColor: color));
    }
  }

  Future<void> _signUp() async {
    setState(() => _isLoading = true);

    final username = _usernameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    // ✅ التحقق من الحقول الفارغة
    if (username.isEmpty || email.isEmpty || password.isEmpty) {
      _showMessage('يرجى ملء جميع الحقول', Colors.orange);
      setState(() => _isLoading = false);
      return;
    }

    // ✅ التحقق من قوة كلمة المرور
    if (password.length < 6) {
      _showMessage('كلمة المرور يجب أن تكون 6 أحرف على الأقل', Colors.orange);
      setState(() => _isLoading = false);
      return;
    }

    try {
      final AuthResponse res = await supabase.auth.signUp(
        email: email,
        password: password,
        // لا نمرر اسم المستخدم هنا لتجنب تكرار البيانات ولنتحكم في إنشاء الملف الشخصي بشكل صريح
        // data: {'username': username}, // 🔴 تم إزالة هذا السطر
      );

      if (res.user != null) {
        // 🔴 تم تسجيل المستخدم بنجاح في Supabase Auth.
        // الآن نقوم بإنشاء سجل له في جدول 'profiles' مباشرة بعد التسجيل
        final userId = res.user!.id;

        try {
          await supabase.from('profiles').insert({
            'id': userId, // ربط الملف الشخصي بمعرف المستخدم في Auth
            'username': username, // 🔴 حفظ اسم المستخدم المدخل من الحقل
            'full_name': '', // يمكن تركها فارغة أو إضافة حقل لجمعها
            'avatar_url': null,
            'created_at': DateTime.now().toIso8601String(),
            'updated_at': DateTime.now().toIso8601String(),
          });
          print(
            'Profile created for new user $userId with username: $username',
          );
        } on PostgrestException catch (e) {
          print('Error creating profile for new user: ${e.message}');
          // لا توقف عملية التسجيل، ولكن سجل الخطأ وأبلغ المستخدم
          if (mounted) {
            _showMessage(
              'تم التسجيل، ولكن حدث خطأ في إنشاء الملف الشخصي: ${e.message}',
              Colors.orange,
            );
          }
        } catch (e) {
          print('Unexpected error creating profile: $e');
          if (mounted) {
            _showMessage(
              'تم التسجيل، ولكن حدث خطأ غير متوقع في إنشاء الملف الشخصي: $e',
              Colors.orange,
            );
          }
        }

        // بعد التسجيل وإنشاء الملف الشخصي، يمكن التحقق من تأكيد البريد الإلكتروني
        if (res.session == null) {
          // إذا لم يتم إنشاء جلسة تلقائيًا، فالمستخدم يحتاج إلى تأكيد البريد الإلكتروني
          _showMessage(
            'تم التسجيل بنجاح! تحقق من بريدك الإلكتروني لتأكيد الحساب.',
            Colors.green,
          );
          // 🔴 اختياري: إذا كان التأكيد مطلوبًا قبل تسجيل الدخول، فقد تحتاج لتسجيل الخروج
          // await supabase.auth.signOut();
        } else {
          _showMessage('تم التسجيل وتسجيل الدخول بنجاح!', Colors.green);
          _navigateToHome(); // ✅ انتقال إلى الصفحة الرئيسية بعد التسجيل والدخول
        }
      }
    } on AuthException catch (e) {
      _showMessage('خطأ في التسجيل: ${e.message}', Colors.red);
    } catch (e) {
      _showMessage('حدث خطأ غير متوقع: $e', Colors.red);
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final cardWidth = screenWidth > 600 ? 400.0 : screenWidth * 0.9;
    final textFieldWidth = cardWidth * 0.8;

    return Scaffold(
      appBar: AppBar(
        title: const Text('إنشاء حساب جديد'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
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
                      children: [
                        Image.asset("images/logo.png", width: 120, height: 120),
                        const SizedBox(height: 30),

                        // اسم المستخدم
                        SizedBox(
                          width: textFieldWidth,
                          child: TextField(
                            controller: _usernameController,
                            decoration: const InputDecoration(
                              labelText: 'اسم المستخدم',
                              hintText: 'ادخل اسم المستخدم',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.person),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),

                        // البريد الإلكتروني
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

                        // كلمة المرور
                        SizedBox(
                          width: textFieldWidth,
                          child: TextField(
                            controller: _passwordController,
                            decoration: const InputDecoration(
                              labelText: 'كلمة المرور',
                              hintText: 'ادخل كلمة المرور',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.lock),
                            ),
                            obscureText: true,
                          ),
                        ),
                        const SizedBox(height: 30),

                        // زر التسجيل أو التحميل
                        _isLoading
                            ? const CircularProgressIndicator()
                            : SizedBox(
                                width: textFieldWidth,
                                child: ElevatedButton(
                                  onPressed: _signUp,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.blue.shade700,
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
                                    "إنشاء حساب",
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                        const SizedBox(height: 15),

                        // زر الانتقال إلى صفحة تسجيل الدخول
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: const Text(
                            "لديك حساب بالفعل؟ تسجيل الدخول",
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
