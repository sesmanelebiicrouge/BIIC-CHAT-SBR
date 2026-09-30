import 'package:supabase_flutter/supabase_flutter.dart';

class MembersService {
  SupabaseClient get _client => Supabase.instance.client;

  Future<List<Map<String, dynamic>>> getMembers() async {
    final response = await _client
        .from('users')
        .select('id, display_name, email, avatar_url, bio, status')
        .order('display_name');
    return List<Map<String, dynamic>>.from(response);
  }
}
