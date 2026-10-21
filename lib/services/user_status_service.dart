import 'package:supabase_flutter/supabase_flutter.dart';

class UserStatusService {
  final SupabaseClient _client;
  UserStatusService({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  String? get currentUserId => _client.auth.currentUser?.id;

  Future<List<Map<String, dynamic>>> getActiveStatuses() async {
    if (_client.auth.currentUser == null) {
      throw StateError('Connectez-vous pour consulter les statuts.');
    }
    final rows = await _client
        .from('user_statuses')
        .select('id,user_id,content,created_at,expires_at,users!user_statuses_user_id_fkey(display_name,avatar_url)')
        .gt('expires_at', DateTime.now().toUtc().toIso8601String())
        .order('created_at', ascending: false)
        .limit(500);
    return List<Map<String, dynamic>>.from(rows);
  }

  Future<void> publish(String content) async {
    final user = _client.auth.currentUser;
    final text = content.trim();
    if (user == null) throw StateError('Connectez-vous pour publier un statut.');
    if (text.isEmpty || text.length > 500) {
      throw ArgumentError('Le statut doit contenir entre 1 et 500 caractères.');
    }
    final now = DateTime.now().toUtc();
    await _client.from('user_statuses').insert({
      'user_id': user.id,
      'content': text,
      'created_at': now.toIso8601String(),
      'expires_at': now.add(const Duration(hours: 24)).toIso8601String(),
    });
  }

  Future<void> delete(String id) async {
    final user = _client.auth.currentUser;
    if (user == null) throw StateError('Connectez-vous pour supprimer un statut.');
    await _client.from('user_statuses').delete().eq('id', id).eq('user_id', user.id);
  }
}
