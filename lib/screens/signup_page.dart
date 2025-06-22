import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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

  // ✅ صفحة رئيسية مؤقتة للانتقال إليها بعد النجاح
  void _navigateToHome() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => const Scaffold(
          body: Center(child: Text('مرحباً بك في الصفحة الرئيسية')),
        ),
      ),
    );
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
        data: {'username': username},
      );

      if (res.user != null) {
        if (res.session == null) {
          _showMessage(
            'تم التسجيل بنجاح! تحقق من بريدك الإلكتروني لتأكيد الحساب.',
            Colors.green,
          );
        } else {
          _showMessage('تم التسجيل وتسجيل الدخول بنجاح!', Colors.green);
          _navigateToHome(); // ✅ انتقال إلى الصفحة الرئيسية
        }
      }
    } on AuthException catch (e) {
      _showMessage('خطأ في التسجيل: ${e.message}', Colors.red);
    } catch (e) {
      _showMessage('حدث خطأ غير متوقع: $e', Colors.red);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showMessage(String text, Color color) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(text), backgroundColor: color));
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
                            obscureText: true,
                            decoration: const InputDecoration(
                              labelText: 'كلمة المرور',
                              hintText: 'ادخل كلمة المرور',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.lock),
                            ),
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
