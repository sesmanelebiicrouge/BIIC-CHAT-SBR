import 'package:supabase_flutter/supabase_flutter.dart';

class MembersService {
  SupabaseClient get _client => Supabase.instance.client;

  Future<List<Map<String, dynamic>>> getMembers() async {
    final response = await _client.rpc('list_public_users');
    return List<Map<String, dynamic>>.from(response);
  }
}
