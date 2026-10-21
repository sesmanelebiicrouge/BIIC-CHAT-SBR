import 'package:supabase_flutter/supabase_flutter.dart';

class MembersService {
  SupabaseClient get _client => Supabase.instance.client;

  Future<Map<String, dynamic>?> findByRegisteredPhone(String phone) async {
    final response = await _client.rpc('find_user_by_registered_phone', params: {'p_phone': phone.trim()});
    final rows = List<Map<String, dynamic>>.from(response as List);
    return rows.isEmpty ? null : rows.first;
  }

  Future<List<Map<String, dynamic>>> getMembers() async {
    final response = await _client.rpc('list_public_users');
    return List<Map<String, dynamic>>.from(response);
  }
}
