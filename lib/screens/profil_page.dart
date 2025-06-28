// import 'package:flutter/material.dart';
// import 'package:supabase_flutter/supabase_flutter.dart';
// import 'package:image_picker/image_picker.dart';
// import 'package:flutter_image_compress/flutter_image_compress.dart';
// import 'package:flutter/foundation.dart' show kIsWeb;
// import 'dart:typed_data';
// import 'package:mizaniflutter/screens/login_page.dart';

// // Access the globally initialized Supabase client
// final supabase = Supabase.instance.client;

// class PersonalInformationPage extends StatefulWidget {
//   const PersonalInformationPage({super.key});

//   @override
//   State<PersonalInformationPage> createState() =>
//       _PersonalInformationPageState();
// }

// class _PersonalInformationPageState extends State<PersonalInformationPage> {
//   final TextEditingController _usernameController = TextEditingController();
//   final TextEditingController _fullNameController = TextEditingController();
//   final TextEditingController _emailController = TextEditingController();

//   bool _isLoading = false;
//   String? _avatarUrl;
//   User? _currentUser;

//   @override
//   void initState() {
//     super.initState();
//     _currentUser = supabase.auth.currentUser;

//     supabase.auth.onAuthStateChange.listen((data) {
//       if (mounted) {
//         setState(() {
//           _currentUser = data.session?.user;
//           if (_currentUser != null) {
//             _loadUserProfile();
//           } else {
//             _usernameController.clear();
//             _fullNameController.clear();
//             _emailController.clear();
//             _avatarUrl = null;
//           }
//         });
//       }
//     });

//     _loadUserProfile();
//   }

//   @override
//   void dispose() {
//     _usernameController.dispose();
//     _fullNameController.dispose();
//     _emailController.dispose();
//     super.dispose();
//   }

//   Future<void> _loadUserProfile() async {
//     if (_currentUser == null) {
//       if (mounted) {
//         _showSnackBar(
//             'الرجاء تسجيل الدخول لعرض ملفك الشخصي.', Colors.orange);
//       }
//       return;
//     }

//     setState(() {
//       _isLoading = true;
//     });

//     try {
//       final Map<String, dynamic>? response = await supabase
//           .from('profiles')
//           .select('username, full_name, avatar_url')
//           .eq('id', _currentUser!.id)
//           .maybeSingle();

//       if (mounted) {
//         setState(() {
//           if (response != null) {
//             _usernameController.text = response['username'] ?? '';
//             _fullNameController.text = response['full_name'] ?? '';
//             _emailController.text = _currentUser!.email ?? '';
//             _avatarUrl = response['avatar_url'];
//             if (_avatarUrl != null && _avatarUrl!.isNotEmpty) {
//               debugPrint('Loaded Avatar URL: $_avatarUrl');
//             }
//           } else {
//             _usernameController.text =
//                 _currentUser!.userMetadata?['display_name'] as String? ?? '';
//             _fullNameController.text = '';
//             _emailController.text = _currentUser!.email ?? '';
//             _avatarUrl = null;
//             if (mounted) {
//               _showSnackBar(
//                   'لا يوجد ملف شخصي. يرجى ملء البيانات وحفظها.', Colors.blue);
//             }
//           }
//         });
//       }
//     } on PostgrestException catch (e) {
//       if (mounted) {
//         _showSnackBar(
//             'خطأ في تحميل الملف الشخصي: ${e.message}', Colors.red);
//       }
//       debugPrint('PostgrestException: ${e.message}');
//     } catch (e) {
//       if (mounted) {
//         _showSnackBar(
//             'حدث خطأ غير متوقع في التحميل: $e', Colors.red);
//       }
//       debugPrint('Unexpected error loading profile: $e');
//     } finally {
//       if (mounted) {
//         setState(() {
//           _isLoading = false;
//         });
//       }
//     }
//   }

//   Future<void> _updateProfile() async {
//     if (_currentUser == null) {
//       if (mounted) {
//         _showSnackBar(
//             'الرجاء تسجيل الدخول لتحديث ملفك الشخصي.', Colors.orange);
//       }
//       return;
//     }

//     setState(() {
//       _isLoading = true;
//     });

//     try {
//       final String newUsername = _usernameController.text.trim();
//       final String newFullName = _fullNameController.text.trim();

//       final profileUpdates = {
//         'id': _currentUser!.id,
//         'username': newUsername,
//         'full_name': newFullName,
//         'updated_at': DateTime.now().toIso8601String(),
//       };

//       await supabase.from('profiles').upsert(profileUpdates);

//       if (newUsername != (_currentUser!.userMetadata?['display_name'] ?? '')) {
//         await supabase.auth.updateUser(
//           UserAttributes(data: {'display_name': newUsername}),
//         );
//       }

//       if (mounted) {
//         _showSnackBar('تم تحديث الملف الشخصي بنجاح!', Colors.green);
//         await _loadUserProfile();
//       }
//     } on PostgrestException catch (e) {
//       if (mounted) {
//         _showSnackBar(
//             'خطأ في تحديث البيانات: ${e.message}', Colors.red);
//       }
//       debugPrint('PostgrestException updating profile: ${e.message}');
//     } on AuthException catch (e) {
//       if (mounted) {
//         _showSnackBar(
//             'خطأ في المصادقة أثناء التحديث: ${e.message}', Colors.red);
//       }
//       debugPrint('AuthException updating profile: ${e.message}');
//     } catch (e) {
//       if (mounted) {
//         _showSnackBar(
//             'حدث خطأ غير متوقع أثناء التحديث: $e', Colors.red);
//       }
//       debugPrint('Unexpected error updating profile: $e');
//     } finally {
//       if (mounted) {
//         setState(() {
//           _isLoading = false;
//         });
//       }
//     }
//   }

//   Future<void> _pickAndUploadImage() async {
//     if (_currentUser == null) {
//       if (mounted) {
//         _showSnackBar('الرجاء تسجيل الدخول لرفع الصورة.', Colors.orange);
//       }
//       return;
//     }

//     setState(() {
//       _isLoading = true;
//     });

//     try {
//       final picker = ImagePicker();
//       final pickedFile = await picker.pickImage(source: ImageSource.gallery);

//       if (pickedFile == null) {
//         return;
//       }

//       final Uint8List? imageBytes = await pickedFile.readAsBytes();

//       if (imageBytes == null) {
//         if (mounted) {
//           _showSnackBar('فشل في قراءة بيانات الصورة.', Colors.red);
//         }
//         return;
//       }

//       Uint8List? finalImageBytes = imageBytes;

//       if (!kIsWeb) {
//         try {
//           Uint8List? compressedBytes = await FlutterImageCompress.compressWithList(
//             imageBytes,
//             quality: 70,
//             minWidth: 800,
//             minHeight: 800,
//             format: CompressFormat.jpeg,
//           );

//           if (compressedBytes != null && compressedBytes.isNotEmpty) {
//             finalImageBytes = compressedBytes;
//           } else {
//             if (mounted) {
//               _showSnackBar('فشل في ضغط الصورة. سيتم رفع الصورة الأصلية.', Colors.orange);
//             }
//           }
//         } catch (e) {
//           if (mounted) {
//             _showSnackBar('خطأ أثناء ضغط الصورة: $e. سيتم رفع الصورة الأصلية.', Colors.orange);
//           }
//           debugPrint('Error during compression on non-web platform: $e');
//           finalImageBytes = imageBytes;
//         }
//       }

//       if (finalImageBytes == null || finalImageBytes.isEmpty) {
//          if (mounted) {
//           _showSnackBar('لا توجد بيانات صورة لرفعها.', Colors.red);
//         }
//         return;
//       }

//       final String pathInBucket = '${_currentUser!.id}/${DateTime.now().millisecondsSinceEpoch}.jpg';

//       await supabase.storage
//           .from('avatars')
//           .uploadBinary(
//             pathInBucket,
//             finalImageBytes,
//             fileOptions: const FileOptions(
//               upsert: true,
//               contentType: 'image/jpeg',
//             ),
//           );

//       // 🔴 هذا هو التغيير: استخدم Supabase.instance.options.projectUrl
//       final String baseUrl = Supabase.instance.options.projectUrl;
//       final String publicUrl = '$baseUrl/storage/v1/object/public/avatars/$pathInBucket';

//       if (mounted) {
//         setState(() {
//           _avatarUrl = publicUrl;
//         });
//         await supabase.from('profiles').upsert({
//           'id': _currentUser!.id,
//           'avatar_url': _avatarUrl,
//         });

//         _showSnackBar('تم رفع الصورة بنجاح!', Colors.green);
//         debugPrint('Uploaded and Set Avatar URL (Manual): $_avatarUrl');
//       }
//     } on StorageException catch (e) {
//       if (mounted) {
//         _showSnackBar(
//             'خطأ في رفع الصورة إلى التخزين: ${e.message}', Colors.red);
//       }
//       debugPrint('StorageException: ${e.message}');
//     } catch (e) {
//       if (mounted) {
//         _showSnackBar(
//             'حدث خطأ غير متوقع أثناء رفع الصورة: $e', Colors.red);
//       }
//       debugPrint('Unexpected error picking/uploading image: $e');
//     } finally {
//       if (mounted) {
//         setState(() {
//           _isLoading = false;
//         });
//       }
//     }
//   }

//   Future<void> _signOut() async {
//     setState(() {
//       _isLoading = true;
//     });

//     try {
//       await supabase.auth.signOut();

//       if (mounted) {
//         _showSnackBar('تم تسجيل الخروج بنجاح!', Colors.green);
//         Navigator.pushAndRemoveUntil(
//           context,
//           MaterialPageRoute(
//             builder: (context) => const LoginPage(),
//           ),
//           (Route<dynamic> route) => false,
//         );
//       }
//     } on AuthException catch (e) {
//       if (mounted) {
//         _showSnackBar(
//             'خطأ في تسجيل الخروج: ${e.message}', Colors.red);
//       }
//       debugPrint('AuthException during sign out: ${e.message}');
//     } catch (e) {
//       if (mounted) {
//         _showSnackBar(
//             'حدث خطأ غير متوقع أثناء تسجيل الخروج: $e', Colors.red);
//       }
//       debugPrint('Unexpected error during sign out: $e');
//     } finally {
//       if (mounted) {
//         setState(() {
//           _isLoading = false;
//         });
//       }
//     }
//   }

//   void _showSnackBar(String message, Color backgroundColor) {
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(
//         content: Text(message),
//         backgroundColor: backgroundColor,
//         duration: const Duration(seconds: 3),
//       ),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     final screenWidth = MediaQuery.of(context).size.width;
//     final cardWidth = screenWidth > 600 ? 500.0 : screenWidth * 0.9;
//     final textFieldWidth = cardWidth * 0.9;

//     if (_currentUser == null) {
//       return Scaffold(
//         appBar: AppBar(title: const Text('الملف الشخصي'), centerTitle: true),
//         body: const Center(
//           child: Padding(
//             padding: EdgeInsets.all(20.0),
//             child: Text(
//               'يرجى تسجيل الدخول لعرض وتعديل ملفك الشخصي.',
//               textAlign: TextAlign.center,
//               style: TextStyle(fontSize: 18, color: Colors.grey),
//             ),
//           ),
//         ),
//       );
//     }

//     return Scaffold(
//       appBar: AppBar(
//         title: const Text(
//           'ملفي الشخصي',
//           style: TextStyle(
//             fontWeight: FontWeight.bold,
//             fontSize: 24,
//             color: Colors.blueGrey,
//           ),
//         ),
//         backgroundColor: Colors.transparent,
//         elevation: 0,
//         centerTitle: true,
//       ),
//       body: _isLoading
//           ? const Center(
//               child: CircularProgressIndicator(color: Colors.blueAccent),
//             )
//           : SingleChildScrollView(
//               padding: const EdgeInsets.symmetric(
//                 horizontal: 20.0,
//                 vertical: 10.0,
//               ),
//               child: Center(
//                 child: Column(
//                   mainAxisAlignment: MainAxisAlignment.center,
//                   crossAxisAlignment: CrossAxisAlignment.center,
//                   children: [
//                     Card(
//                       elevation: 12,
//                       shape: RoundedRectangleBorder(
//                         borderRadius: BorderRadius.circular(25),
//                       ),
//                       margin: const EdgeInsets.symmetric(vertical: 20),
//                       child: Padding(
//                         padding: const EdgeInsets.all(35.0),
//                         child: Column(
//                           mainAxisSize: MainAxisSize.min,
//                           children: [
//                             Stack(
//                               alignment: Alignment.center,
//                               children: [
//                                 CircleAvatar(
//                                   radius: 70,
//                                   backgroundColor: Colors.blueGrey.shade100,
//                                   backgroundImage:
//                                       _avatarUrl != null && _avatarUrl!.isNotEmpty
//                                           ? NetworkImage(_avatarUrl!)
//                                           : null,
//                                   child:
//                                       _avatarUrl == null || _avatarUrl!.isEmpty
//                                           ? Icon(
//                                               Icons.person,
//                                               size: 70,
//                                               color: Colors.blueGrey.shade400,
//                                             )
//                                           : null,
//                                 ),
//                                 Positioned(
//                                   bottom: 0,
//                                   right: 0,
//                                   child: GestureDetector(
//                                     onTap: _pickAndUploadImage,
//                                     child: CircleAvatar(
//                                       radius: 22,
//                                       backgroundColor: Theme.of(
//                                         context,
//                                       ).colorScheme.primary,
//                                       child: const Icon(
//                                         Icons.camera_alt,
//                                         color: Colors.white,
//                                         size: 18,
//                                       ),
//                                     ),
//                                   ),
//                                 ),
//                               ],
//                             ),
//                             const SizedBox(height: 15),
//                             if (_currentUser?.userMetadata?['display_name'] !=
//                                     null &&
//                                 _currentUser!
//                                     .userMetadata!['display_name']
//                                     .isNotEmpty)
//                               Text(
//                                 'مرحباً، ${_currentUser!.userMetadata!['display_name']}',
//                                 style: const TextStyle(
//                                   fontSize: 22,
//                                   fontWeight: FontWeight.bold,
//                                   color: Colors.blueGrey,
//                                 ),
//                                 textAlign: TextAlign.center,
//                               )
//                             else if (_currentUser != null)
//                               const Text(
//                                 'الرجاء تحديث اسم العرض الخاص بك',
//                                 style: TextStyle(
//                                   fontSize: 18,
//                                   color: Colors.grey,
//                                 ),
//                                 textAlign: TextAlign.center,
//                               )
//                             else
//                               const SizedBox.shrink(),
//                             const SizedBox(height: 35),
//                             SizedBox(
//                               width: textFieldWidth,
//                               child: TextField(
//                                 controller: _usernameController,
//                                 decoration: InputDecoration(
//                                   labelText: 'اسم المستخدم (اسم العرض)',
//                                   hintText: 'ادخل اسم المستخدم الخاص بك',
//                                   prefixIcon: const Icon(
//                                     Icons.person_outline,
//                                     color: Colors.blueGrey,
//                                   ),
//                                   border: OutlineInputBorder(
//                                     borderRadius: BorderRadius.circular(12),
//                                     borderSide: BorderSide.none,
//                                   ),
//                                   filled: true,
//                                   fillColor:
//                                       Theme.of(
//                                             context,
//                                           ).inputDecorationTheme.fillColor ??
//                                           Colors.grey.shade100,
//                                   contentPadding: const EdgeInsets.symmetric(
//                                     vertical: 16,
//                                     horizontal: 12,
//                                   ),
//                                   enabledBorder: OutlineInputBorder(
//                                     borderRadius: BorderRadius.circular(12),
//                                     borderSide: BorderSide(
//                                       color: Colors.grey.shade300,
//                                       width: 1,
//                                     ),
//                                   ),
//                                   focusedBorder: OutlineInputBorder(
//                                     borderRadius: BorderRadius.circular(12),
//                                     borderSide: const BorderSide(
//                                       color: Colors.blueAccent,
//                                       width: 2,
//                                     ),
//                                   ),
//                                 ),
//                                 style: const TextStyle(fontSize: 16),
//                               ),
//                             ),
//                             const SizedBox(height: 25),
//                             SizedBox(
//                               width: textFieldWidth,
//                               child: TextField(
//                                 controller: _fullNameController,
//                                 decoration: InputDecoration(
//                                   labelText: 'الاسم الكامل',
//                                   hintText: 'ادخل اسمك الكامل',
//                                   prefixIcon: const Icon(
//                                     Icons.badge_outlined,
//                                     color: Colors.blueGrey,
//                                   ),
//                                   border: OutlineInputBorder(
//                                     borderRadius: BorderRadius.circular(12),
//                                     borderSide: BorderSide.none,
//                                   ),
//                                   filled: true,
//                                   fillColor:
//                                       Theme.of(
//                                             context,
//                                           ).inputDecorationTheme.fillColor ??
//                                           Colors.grey.shade100,
//                                   contentPadding: const EdgeInsets.symmetric(
//                                     vertical: 16,
//                                     horizontal: 12,
//                                   ),
//                                   enabledBorder: OutlineInputBorder(
//                                     borderRadius: BorderRadius.circular(12),
//                                     borderSide: BorderSide(
//                                       color: Colors.grey.shade300,
//                                       width: 1,
//                                     ),
//                                   ),
//                                   focusedBorder: OutlineInputBorder(
//                                     borderRadius: BorderRadius.circular(12),
//                                     borderSide: const BorderSide(
//                                       color: Colors.blueAccent,
//                                       width: 2,
//                                     ),
//                                   ),
//                                 ),
//                                 style: const TextStyle(fontSize: 16),
//                               ),
//                             ),
//                             const SizedBox(height: 25),
//                             SizedBox(
//                               width: textFieldWidth,
//                               child: TextField(
//                                 controller: _emailController,
//                                 decoration: InputDecoration(
//                                   labelText: 'البريد الإلكتروني',
//                                   prefixIcon: const Icon(
//                                     Icons.email_outlined,
//                                     color: Colors.blueGrey,
//                                   ),
//                                   border: OutlineInputBorder(
//                                     borderRadius: BorderRadius.circular(12),
//                                     borderSide: BorderSide.none,
//                                   ),
//                                   filled: true,
//                                   fillColor:
//                                       Theme.of(
//                                             context,
//                                           ).inputDecorationTheme.fillColor ??
//                                           Colors.grey.shade100,
//                                   contentPadding: const EdgeInsets.symmetric(
//                                     vertical: 16,
//                                     horizontal: 12,
//                                   ),
//                                   enabledBorder: OutlineInputBorder(
//                                     borderRadius: BorderRadius.circular(12),
//                                     borderSide: BorderSide(
//                                       color: Colors.grey.shade300,
//                                       width: 1,
//                                     ),
//                                   ),
//                                   focusedBorder: OutlineInputBorder(
//                                     borderRadius: BorderRadius.circular(12),
//                                     borderSide: const BorderSide(
//                                       color: Colors.blueAccent,
//                                       width: 2,
//                                     ),
//                                   ),
//                                 ),
//                                 readOnly: true,
//                                 keyboardType: TextInputType.emailAddress,
//                                 style: TextStyle(
//                                   fontSize: 16,
//                                   color: Theme.of(context)
//                                       .textTheme
//                                       .bodyLarge
//                                       ?.color
//                                       ?.withOpacity(0.7),
//                                 ),
//                               ),
//                             ),
//                             const SizedBox(height: 35),
//                             SizedBox(
//                               width: textFieldWidth,
//                               child: ElevatedButton(
//                                 onPressed: _updateProfile,
//                                 style: ElevatedButton.styleFrom(
//                                   backgroundColor: Theme.of(
//                                     context,
//                                   ).colorScheme.primary,
//                                   foregroundColor: Colors.white,
//                                   padding: const EdgeInsets.symmetric(
//                                     vertical: 16,
//                                   ),
//                                   shape: RoundedRectangleBorder(
//                                     borderRadius: BorderRadius.circular(15),
//                                   ),
//                                   elevation: 8,
//                                   textStyle: const TextStyle(
//                                     fontSize: 18,
//                                     fontWeight: FontWeight.bold,
//                                   ),
//                                 ),
//                                 child: const Text("حفظ التغييرات"),
//                               ),
//                             ),
//                             const SizedBox(height: 15),
//                             SizedBox(
//                               width: textFieldWidth,
//                               child: ElevatedButton(
//                                 onPressed: _isLoading
//                                     ? null
//                                     : _signOut,
//                                 style: ElevatedButton.styleFrom(
//                                   backgroundColor: Colors.red.shade700,
//                                   foregroundColor: Colors.white,
//                                   padding: const EdgeInsets.symmetric(
//                                     vertical: 16,
//                                   ),
//                                   shape: RoundedRectangleBorder(
//                                     borderRadius: BorderRadius.circular(15),
//                                   ),
//                                   elevation: 8,
//                                   textStyle: const TextStyle(
//                                     fontSize: 18,
//                                     fontWeight: FontWeight.bold,
//                                   ),
//                                 ),
//                                 child: _isLoading
//                                     ? const SizedBox(
//                                         width: 20,
//                                         height: 20,
//                                         child: CircularProgressIndicator(
//                                           strokeWidth: 2,
//                                           color: Colors.white,
//                                         ),
//                                       )
//                                     : const Text("تسجيل الخروج"),
//                               ),
//                             ),
//                           ],
//                         ),
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//             ),
//     );
//   }
// }
