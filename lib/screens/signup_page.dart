import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// الوصول إلى عميل Supabase المهيأ عالمياً
final supabase = Supabase.instance.client;

class SignupPage extends StatefulWidget {
  const SignupPage({super.key});

  @override
  State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  // متحكمات حقول الإدخال لاسم المستخدم، البريد الإلكتروني وكلمة المرور
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  // حالة التحميل لعرض مؤشر التحميل أثناء عملية التسجيل
  bool _isLoading = false;

  // التأكد من التخلص من المتحكمات عند إغلاق الـ Widget لتجنب تسرب الذاكرة
  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // 🔴 دالة التسجيل باستخدام Supabase
  Future<void> _signUp() async {
    setState(() {
      _isLoading = true; // تفعيل حالة التحميل
    });
    try {
      final AuthResponse res = await supabase.auth.signUp(
        email: _emailController.text
            .trim(), // استخدام trim لإزالة المسافات البيضاء
        password: _passwordController.text.trim(),
        data: {
          'username': _usernameController.text
              .trim(), // حفظ اسم المستخدم كبيانات وصفية (metadata)
        },
      );

      // 🔴 التحقق مما إذا كان التسجيل ناجحاً والمستخدم قد تم إنشاؤه
      if (res.user != null) {
        // إذا كان التسجيل يتطلب تأكيد البريد الإلكتروني (session تكون null)
        if (res.session == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'تم التسجيل بنجاح! يرجى التحقق من بريدك الإلكتروني لتأكيد حسابك.',
              ),
              backgroundColor: Colors.green,
            ),
          );
          // 🔴 لا تنتقل إلى صفحة أخرى، ابقِ المستخدم على صفحة التسجيل لينتظر التأكيد.
          // يمكن هنا أيضاً إظهار زر لإعادة إرسال البريد الإلكتروني
        } else {
          // هذه الحالة تحدث إذا كانت خاصية "Confirm new signups" معطلة في Supabase
          // أو إذا تم التسجيل عبر مزود اجتماعي يقوم بالتأكيد التلقائي.
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('تم التسجيل بنجاح وتم تسجيل الدخول.')),
          );
          // إذا حدث هذا وتأكدت أن التأكيد غير مطلوب، يمكن الانتقال إلى الصفحة الرئيسية
          // Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const HomePage()));
        }
      }
    } on AuthException catch (e) {
      // التعامل مع أخطاء المصادقة وعرضها للمستخدم
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('خطأ في التسجيل: ${e.message}'),
          backgroundColor: Colors.red,
        ),
      );
    } catch (e) {
      // التعامل مع أي أخطاء أخرى غير متوقعة
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('حدث خطأ غير متوقع: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false; // تعطيل حالة التحميل
      });
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
      appBar: AppBar(
        title: const Text('إنشاء حساب جديد'), // عنوان الصفحة
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () =>
              Navigator.of(context).pop(), // زر العودة للصفحة السابقة
        ),
      ),
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
                        Image.asset("images/logo.png", width: 120, height: 120),
                        const SizedBox(height: 30),

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
                        const SizedBox(height: 30),

                        _isLoading
                            ? const CircularProgressIndicator()
                            : SizedBox(
                                width: textFieldWidth,
                                child: ElevatedButton(
                                  onPressed: _signUp, // استدعاء دالة التسجيل
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

                        TextButton(
                          onPressed: () {
                            Navigator.of(
                              context,
                            ).pop(); // العودة إلى صفحة تسجيل الدخول
                          },
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
