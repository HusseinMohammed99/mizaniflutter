import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
// 🔴 تم تغيير الاستيراد هنا
import 'package:flutter_image_compress/flutter_image_compress.dart'; // لضغط الصور

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

  // 🔴 دالة لتحميل بيانات الملف الشخصي من Supabase
  Future<void> _loadUserProfile() async {
    if (_currentUser == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('الرجاء تسجيل الدخول لعرض ملفك الشخصي.'),
          ),
        );
        // لا تغير _isLoading هنا، اتركه false لأن لا يوجد تحميل فعلي
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
          .select('username, full_name, avatar_url') // تحديد الأعمدة المطلوبة
          .eq('id', _currentUser!.id) // جلب الملف الشخصي الخاص بالمستخدم الحالي
          .single(); // نتوقع صفاً واحداً فقط

      if (mounted) {
        setState(() {
          _usernameController.text = response['username'] ?? '';
          _fullNameController.text = response['full_name'] ?? '';
          _emailController.text =
              _currentUser!.email ??
              ''; // البريد الإلكتروني يأتي من auth.currentUser
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

  // 🔴 دالة لتحديث بيانات الملف الشخصي في Supabase
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
        // 'avatar_url': _avatarUrl, // لا نحدث هذا هنا، يتم تحديثه في _pickAndUploadImage
        'updated_at': DateTime.now().toIso8601String(), // تحديث وقت التعديل
      };

      // تحديث البيانات في جدول 'profiles'
      await supabase
          .from('profiles')
          .update(updates)
          .eq('id', _currentUser!.id);

      // تحديث اسم المستخدم في Auth metadata إذا تغير
      // 🔴 التأكد من أن currentUser.userMetadata ليس null قبل الوصول
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

  // 🔴 دالة لتحديد صورة شخصية ورفعها إلى Supabase Storage
  Future<void> _pickAndUploadImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _isLoading = true;
      });

      try {
        final file = File(pickedFile.path);

        // 🔴 ضغط الصورة باستخدام FlutterImageCompress
        final XFile? compressedFile =
            await FlutterImageCompress.compressAndGetFile(
              file.absolute.path,
              '${file.absolute.path}_compressed.jpg', // مسار مؤقت لملف مضغوط
              quality: 70, // جودة الضغط (0-100)
              minWidth: 800, // يمكن تغيير الأبعاد لتقليل الحجم
              minHeight: 800,
              format: CompressFormat.jpeg, // 🔴 تحديد صيغة الضغط
            );

        if (compressedFile == null) {
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

        // 🔴 رفع الصورة إلى Supabase Storage. دالة upload ترجع String (مسار الملف المرفوع)
        final String uploadedPath = await supabase.storage
            .from('avatars')
            .upload(
              path,
              compressedFile as File, // استخدام الـ XFile المضغوط
              fileOptions: const FileOptions(
                upsert: true, // تحديث إذا كان الملف موجوداً بنفس المسار
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
          // 🔴 تحديث رابط الصورة في جدول الـ profiles مباشرة بعد الرفع
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
        // 🔴 التعامل مع أخطاء التخزين
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

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final cardWidth = screenWidth > 600 ? 500.0 : screenWidth * 0.9;
    final textFieldWidth = cardWidth * 0.85;

    return Scaffold(
      appBar: AppBar(
        title: const Text('المعلومات الشخصية'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Card(
                      elevation: 10,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(30.0),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // 🔴 الصورة الشخصية
                            GestureDetector(
                              onTap: _pickAndUploadImage,
                              child: CircleAvatar(
                                radius: 60,
                                backgroundColor: Colors.grey[200],
                                backgroundImage:
                                    _avatarUrl != null && _avatarUrl!.isNotEmpty
                                    ? NetworkImage(_avatarUrl!)
                                    : null,
                                child: _avatarUrl == null || _avatarUrl!.isEmpty
                                    ? Icon(
                                        Icons.camera_alt,
                                        size: 40,
                                        color: Colors.grey[700],
                                      )
                                    : null,
                              ),
                            ),
                            const SizedBox(height: 30),

                            // 🔴 حقل اسم المستخدم
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

                            // 🔴 حقل الاسم الكامل
                            SizedBox(
                              width: textFieldWidth,
                              child: TextField(
                                controller: _fullNameController,
                                decoration: const InputDecoration(
                                  labelText: 'الاسم الكامل',
                                  hintText: 'ادخل اسمك الكامل',
                                  border: OutlineInputBorder(),
                                  prefixIcon: Icon(Icons.badge),
                                ),
                              ),
                            ),
                            const SizedBox(height: 20),

                            // 🔴 حقل البريد الإلكتروني (للعرض فقط لأنه يأتي من المصادقة)
                            SizedBox(
                              width: textFieldWidth,
                              child: TextField(
                                controller: _emailController,
                                decoration: const InputDecoration(
                                  labelText: 'البريد الإلكتروني',
                                  border: OutlineInputBorder(),
                                  prefixIcon: Icon(Icons.email),
                                ),
                                readOnly: true, // لا يمكن تعديله من هنا
                                keyboardType: TextInputType.emailAddress,
                              ),
                            ),
                            const SizedBox(height: 30),

                            // 🔴 زر حفظ التغييرات
                            SizedBox(
                              width: textFieldWidth,
                              child: ElevatedButton(
                                onPressed: _updateProfile,
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
                                  "حفظ التغييرات",
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
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
