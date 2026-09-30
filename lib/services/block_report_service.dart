import 'package:supabase_flutter/supabase_flutter.dart';

class BlockReportService {
  final SupabaseClient _client;
  BlockReportService({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  Future<Set<String>> getBlockedUserIds() async {
    final me = _client.auth.currentUser;
    if (me == null) return <String>{};
    final rows = await _client
        .from('blocked_users')
        .select('blocked_user_id')
        .eq('user_id', me.id);
    return List<Map<String, dynamic>>.from(rows)
        .map((row) => row['blocked_user_id'] as String)
        .toSet();
  }

  Future<bool> isBlocked(String userId) async {
    final me = _client.auth.currentUser;
    if (me == null) return false;
    final row = await _client
        .from('blocked_users')
        .select('id')
        .eq('user_id', me.id)
        .eq('blocked_user_id', userId)
        .maybeSingle();
    return row != null;
  }

  Future<void> blockUser(String userId) async {
    final me = _client.auth.currentUser;
    if (me == null || me.id == userId) {
      throw ArgumentError('Utilisateur invalide.');
    }
    await _client.from('blocked_users').upsert(
      {'user_id': me.id, 'blocked_user_id': userId},
      onConflict: 'user_id,blocked_user_id',
    );
  }

  Future<void> unblockUser(String userId) async {
    final me = _client.auth.currentUser;
    if (me == null) return;
    await _client
        .from('blocked_users')
        .delete()
        .eq('user_id', me.id)
        .eq('blocked_user_id', userId);
  }

  Future<void> reportUser({
    required String userId,
    required String reason,
    String? details,
  }) async {
    final me = _client.auth.currentUser;
    if (me == null || me.id == userId) {
      throw ArgumentError('Utilisateur invalide.');
    }
    final cleanReason = reason.trim();
    if (cleanReason.isEmpty) {
      throw ArgumentError('Indiquez une raison.');
    }
    await _client.from('user_reports').insert({
      'reporter_id': me.id,
      'reported_user_id': userId,
      'reason': cleanReason,
      'details': details?.trim(),
    });
  }
}
