import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart'; // To compress images
import 'package:flutter/foundation.dart'
    show kIsWeb, Uint8List; // To check platform
import 'package:mizaniflutter/screens/login_page.dart'; // Ensure the correct path to your login page

// Access the globally initialized Supabase client
final supabase = Supabase.instance.client;

class PersonalInformationPage extends StatefulWidget {
  const PersonalInformationPage({super.key});

  @override
  State<PersonalInformationPage> createState() =>
      _PersonalInformationPageState();
}

class _PersonalInformationPageState extends State<PersonalInformationPage> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();

  bool _isLoading = false;
  String? _avatarUrl;
  User? _currentUser; // Current Supabase Auth user

  @override
  void initState() {
    super.initState();
    _currentUser = supabase.auth.currentUser; // Get current user on startup

    // Listen for authentication state changes to update user data
    // This ensures UI updates if user logs in/out or updates their data
    supabase.auth.onAuthStateChange.listen((data) {
      if (mounted) {
        setState(() {
          _currentUser = data.session?.user;
          if (_currentUser != null) {
            _loadUserProfile(); // Reload profile on user change
          } else {
            // Clear data if user logs out
            _usernameController.clear();
            _fullNameController.clear();
            _emailController.clear();
            _avatarUrl = null;
          }
        });
      }
    });

    _loadUserProfile(); // Load profile data on page initialization
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _fullNameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  // Function to load user profile data from Supabase
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
      // 🔴 استخدام .maybeSingle() للتعامل مع عدم وجود صف
      // إذا لم يتم العثور على صف، ستُرجع null بدلاً من رمي خطأ.
      final Map<String, dynamic>? response = await supabase
          .from('profiles')
          .select('username, full_name, avatar_url')
          .eq('id', _currentUser!.id)
          .maybeSingle();

      if (mounted) {
        setState(() {
          if (response != null) {
            // إذا تم العثور على ملف شخصي، قم بتعبئة البيانات
            final String? authDisplayName =
                _currentUser!.userMetadata?['display_name'] as String?;
            _usernameController.text = authDisplayName?.isNotEmpty == true
                ? authDisplayName!
                : (response['username'] ?? '');

            _fullNameController.text = response['full_name'] ?? '';
            _emailController.text = _currentUser!.email ?? '';
            _avatarUrl = response['avatar_url'];
          } else {
            // 🔴 إذا لم يتم العثور على ملف شخصي، قم بتهيئته
            _usernameController.text =
                _currentUser!.userMetadata?['display_name'] as String? ?? '';
            _fullNameController.text = '';
            _emailController.text = _currentUser!.email ?? '';
            _avatarUrl = null;
            // يمكنك أيضاً عرض رسالة للمستخدم هنا بأنه لا يوجد ملف شخصي
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('لا يوجد ملف شخصي. يرجى ملء البيانات وحفظها.'),
                  backgroundColor: Colors.blue,
                ),
              );
            }
          }
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

  // Function to update user profile data in Supabase
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
      final String newUsername = _usernameController.text.trim();
      final String newFullName = _fullNameController.text.trim();

      final profileUpdates = {
        'id': _currentUser!.id, // تأكد من تمرير الـ ID للـ upsert
        'username': newUsername,
        'full_name': newFullName,
        'updated_at': DateTime.now().toIso8601String(),
        // 'avatar_url' سيتم تحديثه بشكل منفصل عند رفع الصورة
      };

      // 🔴 استخدام .upsert() لإضافة أو تحديث ملف التعريف
      // هذا سيضيف صفاً جديداً إذا لم يكن موجوداً، أو يحدث الصف الموجود.
      await supabase.from('profiles').upsert(profileUpdates);

      // تحديث 'display_name' في Auth metadata
      if (newUsername != (_currentUser!.userMetadata?['display_name'] ?? '')) {
        await supabase.auth.updateUser(
          UserAttributes(data: {'display_name': newUsername}),
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم تحديث الملف الشخصي بنجاح!'),
            backgroundColor: Colors.green,
          ),
        );
        await _loadUserProfile(); // Reload profile after update/upsert
      }
    } on PostgrestException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ في تحديث البيانات: ${e.message}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } on AuthException catch (e) {
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

  // Function to pick and upload profile image to Supabase Storage
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

    setState(() {
      _isLoading = true;
    });

    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(source: ImageSource.gallery);

      if (pickedFile == null) {
        return; // User cancelled picking
      }

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
      compressedBytes = await FlutterImageCompress.compressWithList(
        imageBytes,
        quality: 70, // Compression quality (0-100)
        minWidth: 800, // Can change dimensions to reduce size
        minHeight: 800,
        format: CompressFormat.jpeg, // Specify compression format
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

      // Define file path in Supabase Storage (e.g., avatars/user_id/timestamp.jpg)
      final String path =
          'avatars/${_currentUser!.id}/${DateTime.now().millisecondsSinceEpoch}.jpg';

      // Upload image as Uint8List using uploadBinary
      final String uploadedPath = await supabase.storage
          .from('avatars')
          .uploadBinary(
            path,
            compressedBytes, // Use compressed bytes
            fileOptions: const FileOptions(
              upsert: true, // Update if file exists at the same path
              contentType: 'image/jpeg', // Set content type
            ),
          );

      // Get public URL of the uploaded image
      final String publicUrl = supabase.storage
          .from('avatars')
          .getPublicUrl(uploadedPath);

      if (mounted) {
        setState(() {
          _avatarUrl = publicUrl; // Update image URL in state
        });
        // Update image URL in 'profiles' table directly after upload
        // 🔴 استخدام .upsert() لـ avatar_url أيضاً
        await supabase.from('profiles').upsert({
          'id': _currentUser!.id,
          'avatar_url': _avatarUrl,
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم رفع الصورة بنجاح!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } on StorageException catch (e) {
      // Handle storage errors
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

  // Function to sign out
  Future<void> _signOut() async {
    setState(() {
      _isLoading = true; // Activate loading state
    });

    try {
      await supabase.auth.signOut(); // Call Supabase Auth sign out function

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم تسجيل الخروج بنجاح!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder: (context) => const LoginPage(),
          ), // Use LoginPage
          (Route<dynamic> route) => false, // Remove all previous routes
        );
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
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final cardWidth = screenWidth > 600 ? 500.0 : screenWidth * 0.9;
    final textFieldWidth = cardWidth * 0.9;

    // Ensure current user is not null before attempting to render UI
    if (_currentUser == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('الملف الشخصي'), centerTitle: true),
        body: const Center(
          child: Padding(
            padding: EdgeInsets.all(20.0),
            child: Text(
              'يرجى تسجيل الدخول لعرض وتعديل ملفك الشخصي.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'ملفي الشخصي',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 24,
            color: Colors.blueGrey,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Colors.blueAccent),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.symmetric(
                horizontal: 20.0,
                vertical: 10.0,
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Card(
                      elevation: 12,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25),
                      ),
                      margin: const EdgeInsets.symmetric(vertical: 20),
                      child: Padding(
                        padding: const EdgeInsets.all(35.0),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Profile image with aesthetic effect
                            Stack(
                              alignment: Alignment.center,
                              children: [
                                CircleAvatar(
                                  radius: 70,
                                  backgroundColor: Colors.blueGrey.shade100,
                                  backgroundImage:
                                      _avatarUrl != null &&
                                          _avatarUrl!.isNotEmpty
                                      ? NetworkImage(_avatarUrl!)
                                      : null,
                                  child:
                                      _avatarUrl == null || _avatarUrl!.isEmpty
                                      ? Icon(
                                          Icons.person,
                                          size: 70,
                                          color: Colors.blueGrey.shade400,
                                        )
                                      : null,
                                ),
                                // Camera button to change image
                                Positioned(
                                  bottom: 0,
                                  right: 0,
                                  child: GestureDetector(
                                    onTap: _pickAndUploadImage,
                                    child: CircleAvatar(
                                      radius: 22,
                                      backgroundColor: Theme.of(
                                        context,
                                      ).colorScheme.primary,
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
                            const SizedBox(height: 15),
                            // Explicitly display current display_name here
                            if (_currentUser?.userMetadata?['display_name'] !=
                                    null &&
                                _currentUser!
                                    .userMetadata!['display_name']
                                    .isNotEmpty)
                              Text(
                                'مرحباً، ${_currentUser!.userMetadata!['display_name']}',
                                style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blueGrey,
                                ),
                                textAlign: TextAlign.center,
                              )
                            else if (_currentUser !=
                                null) // If user exists but no display name
                              const Text(
                                'الرجاء تحديث اسم العرض الخاص بك',
                                style: TextStyle(
                                  fontSize: 18,
                                  color: Colors.grey,
                                ),
                                textAlign: TextAlign.center,
                              )
                            else
                              const SizedBox.shrink(), // Don't show anything if no user
                            const SizedBox(height: 35),
                            // Username field with improved design
                            SizedBox(
                              width: textFieldWidth,
                              child: TextField(
                                controller: _usernameController,
                                decoration: InputDecoration(
                                  labelText: 'اسم المستخدم (اسم العرض)',
                                  hintText: 'ادخل اسم المستخدم الخاص بك',
                                  prefixIcon: const Icon(
                                    Icons.person_outline,
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
                            // Full name field with improved design
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

                            // Email field (read-only) with improved design
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
                                readOnly: true, // Cannot be edited from here
                                keyboardType: TextInputType.emailAddress,
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Theme.of(context)
                                      .textTheme
                                      .bodyLarge
                                      ?.color
                                      ?.withOpacity(0.7),
                                ),
                              ),
                            ),
                            const SizedBox(height: 35),
                            // Save Changes button with modern design
                            SizedBox(
                              width: textFieldWidth,
                              child: ElevatedButton(
                                onPressed: _updateProfile,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Theme.of(
                                    context,
                                  ).colorScheme.primary,
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
                                child: const Text("حفظ التغييرات"),
                              ),
                            ),
                            const SizedBox(height: 15),
                            // Sign Out button
                            SizedBox(
                              width: textFieldWidth,
                              child: ElevatedButton(
                                onPressed: _isLoading
                                    ? null
                                    : _signOut, // Disable button while loading
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.red.shade700,
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
