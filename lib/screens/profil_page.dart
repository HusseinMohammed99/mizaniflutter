import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart'; // لضغط الصور
import 'package:flutter/foundation.dart'
    show kIsWeb, Uint8List; // للتحقق من المنصة

// الوصول إلى عميل Supabase المهيأ عالمياً
final supabase = Supabase.instance.client;

class PersonalInformationPage extends StatefulWidget {
  const PersonalInformationPage({super.key});

  @override
  State<PersonalInformationPage> createState() =>
      _PersonalInformationPageState();
}

class _PersonalInformationPageState extends State<PersonalInformationPage> {
  // متحكمات حقول الإدخال
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();

  // حالة التحميل
  bool _isLoading = false;
  // رابط الصورة الشخصية
  String? _avatarUrl;
  // المستخدم الحالي من Supabase Auth
  User? _currentUser;

  @override
  void initState() {
    super.initState();
    _currentUser = supabase.auth.currentUser; // جلب المستخدم الحالي
    _loadUserProfile(); // تحميل بيانات الملف الشخصي
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _fullNameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  // دالة لتحميل بيانات الملف الشخصي من Supabase
  Future<void> _loadUserProfile() async {
    if (_currentUser == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('الرجاء تسجيل الدخول لعرض ملفك الشخصي.'),
          ),
        );
      }
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // جلب بيانات ملف التعريف من جدول 'profiles'
      final response = await supabase
          .from('profiles')
          .select('username, full_name, avatar_url')
          .eq('id', _currentUser!.id)
          .single();

      if (mounted) {
        setState(() {
          _usernameController.text = response['username'] ?? '';
          _fullNameController.text = response['full_name'] ?? '';
          _emailController.text = _currentUser!.email ?? '';
          _avatarUrl = response['avatar_url'];
        });
      }
    } on PostgrestException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ في تحميل الملف الشخصي: ${e.message}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('حدث خطأ غير متوقع في التحميل: $e'),
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

  // دالة لتحديث بيانات الملف الشخصي في Supabase
  Future<void> _updateProfile() async {
    if (_currentUser == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('الرجاء تسجيل الدخول لتحديث ملفك الشخصي.'),
          ),
        );
      }
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final updates = {
        'username': _usernameController.text.trim(),
        'full_name': _fullNameController.text.trim(),
        'updated_at': DateTime.now().toIso8601String(), // تحديث وقت التعديل
      };

      // تحديث البيانات في جدول 'profiles'
      await supabase
          .from('profiles')
          .update(updates)
          .eq('id', _currentUser!.id);

      // تحديث اسم المستخدم في Auth metadata إذا تغير
      if (_usernameController.text.trim() !=
          (_currentUser!.userMetadata?['username'] ?? '')) {
        await supabase.auth.updateUser(
          UserAttributes(data: {'username': _usernameController.text.trim()}),
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم تحديث الملف الشخصي بنجاح!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } on PostgrestException catch (e) {
      // أخطاء من Postgrest (قاعدة البيانات)
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ في تحديث البيانات: ${e.message}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } on AuthException catch (e) {
      // أخطاء من Auth (مثل تحديث بيانات المستخدم)
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ في المصادقة أثناء التحديث: ${e.message}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('حدث خطأ غير متوقع أثناء التحديث: $e'),
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

  // دالة لتحديد صورة شخصية ورفعها إلى Supabase Storage
  Future<void> _pickAndUploadImage() async {
    if (_currentUser == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('الرجاء تسجيل الدخول لرفع الصورة.'),
            backgroundColor: Colors.orange,
          ),
        );
      }
      return;
    }

    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _isLoading = true;
      });

      try {
        // التعامل مع الملفات كـ Uint8List (بايتات) للعمل عبر المنصات (خاصة الويب)
        final Uint8List? imageBytes = await pickedFile.readAsBytes();

        if (imageBytes == null) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('فشل في قراءة بيانات الصورة.'),
                backgroundColor: Colors.red,
              ),
            );
          }
          return;
        }

        Uint8List? compressedBytes;
        // ضغط الصورة باستخدام FlutterImageCompress مع البيانات الخام (bytes)
        compressedBytes = await FlutterImageCompress.compressWithList(
          imageBytes,
          quality: 70, // جودة الضغط (0-100)
          minWidth: 800, // يمكن تغيير الأبعاد لتقليل الحجم
          minHeight: 800,
          format: CompressFormat.jpeg, // تحديد صيغة الضغط
        );

        if (compressedBytes == null || compressedBytes.isEmpty) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('فشل في ضغط الصورة.'),
                backgroundColor: Colors.red,
              ),
            );
          }
          return;
        }

        // تحديد مسار الملف في Supabase Storage (مثلاً: avatars/user_id/timestamp.jpg)
        final String path =
            'avatars/${_currentUser!.id}/${DateTime.now().millisecondsSinceEpoch}.jpg';

        // رفع الصورة كـ Uint8List باستخدام uploadBinary
        final String uploadedPath = await supabase.storage
            .from('avatars')
            .uploadBinary(
              path,
              compressedBytes, // استخدام البايتات المضغوطة
              fileOptions: const FileOptions(
                upsert: true, // تحديث إذا كان الملف موجوداً بنفس المسار
                contentType: 'image/jpeg', // تحديد نوع المحتوى
              ),
            );

        // الحصول على الرابط العام للصورة المرفوعة
        final String publicUrl = supabase.storage
            .from('avatars')
            .getPublicUrl(uploadedPath);

        if (mounted) {
          setState(() {
            _avatarUrl = publicUrl; // تحديث رابط الصورة في الـ state
          });
          // تحديث رابط الصورة في جدول الـ profiles مباشرة بعد الرفع
          await supabase
              .from('profiles')
              .update({'avatar_url': _avatarUrl})
              .eq('id', _currentUser!.id);

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('تم رفع الصورة بنجاح!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } on StorageException catch (e) {
        // التعامل مع أخطاء التخزين
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('خطأ في رفع الصورة إلى التخزين: ${e.message}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('حدث خطأ غير متوقع أثناء رفع الصورة: $e'),
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
  }

  // 🔴 دالة جديدة لتسجيل الخروج
  Future<void> _signOut() async {
    setState(() {
      _isLoading = true; // تفعيل حالة التحميل
    });

    try {
      await supabase.auth
          .signOut(); // استدعاء دالة تسجيل الخروج من Supabase Auth

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم تسجيل الخروج بنجاح!'),
            backgroundColor: Colors.green,
          ),
        );
        // 🔴 استبدل '/login' بالمسار الفعلي لصفحة تسجيل الدخول الخاصة بك
        Navigator.pushReplacementNamed(context, '/login');
      }
    } on AuthException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ في تسجيل الخروج: ${e.message}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('حدث خطأ غير متوقع أثناء تسجيل الخروج: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false; // تعطيل حالة التحميل دائماً
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final cardWidth = screenWidth > 600 ? 500.0 : screenWidth * 0.9;
    // يتم حساب textFieldWidth بناءً على cardWidth لضمان الاستجابة
    final textFieldWidth = cardWidth * 0.9;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'ملفي الشخصي', // تغيير العنوان ليكون أكثر وضوحاً
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 24,
            color: Colors.blueGrey, // لون أنيق للعنوان
          ),
        ),
        backgroundColor: Colors.transparent, // لجعل الخلفية شفافة
        elevation: 0, // إزالة الظل من شريط التطبيق
        centerTitle: true,
        // يمكنك إضافة زر رجوع مخصص إذا لزم الأمر
        // leading: IconButton(
        //   icon: const Icon(Icons.arrow_back_ios, color: Colors.blueGrey),
        //   onPressed: () => Navigator.of(context).pop(),
        // ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Colors.blueAccent),
            ) // مؤشر تحميل بلون جذاب
          : SingleChildScrollView(
              padding: const EdgeInsets.symmetric(
                horizontal: 20.0,
                vertical: 10.0,
              ), // تباعد أفضل
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // بطاقة الملف الشخصي المصممة باحترافية
                    Card(
                      elevation: 12, // ظل أكبر لإبراز البطاقة
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                          25,
                        ), // حواف دائرية أكبر
                      ),
                      margin: const EdgeInsets.symmetric(
                        vertical: 20,
                      ), // تباعد عن الحواف
                      child: Padding(
                        padding: const EdgeInsets.all(35.0), // تباعد داخلي أكبر
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // الصورة الشخصية مع تأثير جميل
                            Stack(
                              alignment: Alignment.center,
                              children: [
                                CircleAvatar(
                                  radius: 70, // حجم أكبر للصورة
                                  backgroundColor:
                                      Colors.blueGrey.shade100, // خلفية خفيفة
                                  backgroundImage:
                                      _avatarUrl != null &&
                                          _avatarUrl!.isNotEmpty
                                      ? NetworkImage(_avatarUrl!)
                                      : null,
                                  child:
                                      _avatarUrl == null || _avatarUrl!.isEmpty
                                      ? Icon(
                                          Icons
                                              .person, // أيقونة شخص بدلاً من الكاميرا إذا لا توجد صورة
                                          size: 70,
                                          color: Colors.blueGrey.shade400,
                                        )
                                      : null,
                                ),
                                // زر الكاميرا للتغيير
                                Positioned(
                                  bottom: 0,
                                  right: 0,
                                  child: GestureDetector(
                                    onTap: _pickAndUploadImage,
                                    child: CircleAvatar(
                                      radius: 22, // حجم صغير لزر الكاميرا
                                      backgroundColor: Theme.of(context)
                                          .colorScheme
                                          .primary, // لون أساسي من الثيم
                                      child: const Icon(
                                        Icons.camera_alt,
                                        color: Colors.white,
                                        size: 18,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 35), // تباعد بعد الصورة
                            // حقل اسم المستخدم بتصميم محسّن
                            SizedBox(
                              width: textFieldWidth,
                              child: TextField(
                                controller: _usernameController,
                                decoration: InputDecoration(
                                  labelText: 'اسم المستخدم',
                                  hintText: 'ادخل اسم المستخدم',
                                  prefixIcon: const Icon(
                                    Icons.person_outline,
                                    color: Colors.blueGrey,
                                  ),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(
                                      12,
                                    ), // حواف دائرية
                                    borderSide: BorderSide
                                        .none, // إزالة الحدود الافتراضية
                                  ),
                                  filled: true, // خلفية مملوءة
                                  fillColor:
                                      Theme.of(
                                        context,
                                      ).inputDecorationTheme.fillColor ??
                                      Colors.grey.shade100, // لون خلفية الحقل
                                  contentPadding: const EdgeInsets.symmetric(
                                    vertical: 16,
                                    horizontal: 12,
                                  ), // تباعد داخلي
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(
                                      color: Colors.grey.shade300,
                                      width: 1,
                                    ), // حدود خفيفة
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: const BorderSide(
                                      color: Colors.blueAccent,
                                      width: 2,
                                    ), // حدود عند التركيز
                                  ),
                                ),
                                style: const TextStyle(
                                  fontSize: 16,
                                ), // حجم خط مناسب
                              ),
                            ),
                            const SizedBox(height: 25), // تباعد
                            // حقل الاسم الكامل بتصميم محسّن
                            SizedBox(
                              width: textFieldWidth,
                              child: TextField(
                                controller: _fullNameController,
                                decoration: InputDecoration(
                                  labelText: 'الاسم الكامل',
                                  hintText: 'ادخل اسمك الكامل',
                                  prefixIcon: const Icon(
                                    Icons.badge_outlined,
                                    color: Colors.blueGrey,
                                  ),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide.none,
                                  ),
                                  filled: true,
                                  fillColor:
                                      Theme.of(
                                        context,
                                      ).inputDecorationTheme.fillColor ??
                                      Colors.grey.shade100,
                                  contentPadding: const EdgeInsets.symmetric(
                                    vertical: 16,
                                    horizontal: 12,
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(
                                      color: Colors.grey.shade300,
                                      width: 1,
                                    ),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: const BorderSide(
                                      color: Colors.blueAccent,
                                      width: 2,
                                    ),
                                  ),
                                ),
                                style: const TextStyle(fontSize: 16),
                              ),
                            ),
                            const SizedBox(height: 25),

                            // حقل البريد الإلكتروني (للعرض فقط) بتصميم محسّن
                            SizedBox(
                              width: textFieldWidth,
                              child: TextField(
                                controller: _emailController,
                                decoration: InputDecoration(
                                  labelText: 'البريد الإلكتروني',
                                  prefixIcon: const Icon(
                                    Icons.email_outlined,
                                    color: Colors.blueGrey,
                                  ),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide.none,
                                  ),
                                  filled: true,
                                  fillColor:
                                      Theme.of(
                                        context,
                                      ).inputDecorationTheme.fillColor ??
                                      Colors.grey.shade100,
                                  contentPadding: const EdgeInsets.symmetric(
                                    vertical: 16,
                                    horizontal: 12,
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(
                                      color: Colors.grey.shade300,
                                      width: 1,
                                    ),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: const BorderSide(
                                      color: Colors.blueAccent,
                                      width: 2,
                                    ),
                                  ),
                                ),
                                readOnly: true, // لا يمكن تعديله من هنا
                                keyboardType: TextInputType.emailAddress,
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Theme.of(context)
                                      .textTheme
                                      .bodyLarge
                                      ?.color
                                      ?.withOpacity(0.7), // لون فاتح
                                ),
                              ),
                            ),
                            const SizedBox(height: 35), // تباعد قبل الزر
                            // زر حفظ التغييرات بتصميم عصري
                            SizedBox(
                              width: textFieldWidth,
                              child: ElevatedButton(
                                onPressed: _updateProfile,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Theme.of(
                                    context,
                                  ).colorScheme.primary, // لون أساسي من الثيم
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 16,
                                  ), // تباعد أكبر للزر
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(
                                      15,
                                    ), // حواف دائرية أكثر
                                  ),
                                  elevation: 8, // ظل أكبر للزر
                                  textStyle: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                child: const Text("حفظ التغييرات"),
                              ),
                            ),
                            const SizedBox(height: 15), // تباعد بين الأزرار
                            // 🔴 زر تسجيل الخروج
                            SizedBox(
                              width: textFieldWidth,
                              child: ElevatedButton(
                                onPressed: _isLoading
                                    ? null
                                    : _signOut, // تعطيل الزر أثناء التحميل
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors
                                      .red
                                      .shade700, // لون أحمر لزر تسجيل الخروج
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 16,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(15),
                                  ),
                                  elevation: 8,
                                  textStyle: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                child: _isLoading
                                    ? const SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.white,
                                        ),
                                      )
                                    : const Text("تسجيل الخروج"),
                              ),
                            ),
                          ],
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
