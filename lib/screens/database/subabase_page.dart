import 'package:supabase_flutter/supabase_flutter.dart';

final supabase = Supabase.instance.client;

void getUserInfo() {
  final User? currentUser = supabase.auth.currentUser;

  if (currentUser != null) {
    print('User ID: ${currentUser.id}');
    print('User Email: ${currentUser.email}');

    // الوصول إلى اسم المستخدم من raw_user_meta_data
    final Map<String, dynamic>? userMetadata = currentUser.userMetadata;
    if (userMetadata != null && userMetadata.containsKey('username')) {
      final String username = userMetadata['username'];
      print('Username from metadata: $username');
    } else {
      print('Username not found in metadata.');
    }
  } else {
    print('No user is currently logged in.');
  }
}
