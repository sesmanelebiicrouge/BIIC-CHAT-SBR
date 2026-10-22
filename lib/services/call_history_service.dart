import 'package:supabase_flutter/supabase_flutter.dart';

class CallHistoryService {
  final SupabaseClient _client;
  CallHistoryService({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  /// Checks eligibility before opening the external call provider.
  ///
  /// This avoids launching a Jitsi room for group chats, non-members, or
  /// blocked users when the database would reject the call-history record.
  Future<String> validateOutgoingCall({
    required String conversationId,
    required String callType,
  }) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) throw StateError('Connectez-vous pour appeler.');
    if (!{'audio', 'video'}.contains(callType)) {
      throw ArgumentError('Type d’appel invalide.');
    }
    if (conversationId.trim().isEmpty) {
      throw ArgumentError('Discussion invalide.');
    }

    final conversation = await _client
        .from('conversations')
        .select('id,is_group')
        .eq('id', conversationId)
        .maybeSingle();
    if (conversation == null) {
      throw StateError('Discussion introuvable ou accès refusé.');
    }
    if (conversation['is_group'] == true) {
      throw StateError('Les appels de groupe ne sont pas encore pris en charge.');
    }

    final rows = await _client
        .from('conversation_members')
        .select('user_id')
        .eq('conversation_id', conversationId);
    final members = List<Map<String, dynamic>>.from(rows);
    final memberIds = members
        .map((row) => row['user_id']?.toString() ?? '')
        .where((id) => id.isNotEmpty)
        .toSet();
    if (!memberIds.contains(userId)) {
      throw StateError('Vous ne participez pas à cette discussion.');
    }

    final otherIds = memberIds.where((id) => id != userId).toList();
    if (otherIds.length != 1) {
      throw StateError('Un appel nécessite exactement deux participants.');
    }

    final blocked = await _client.rpc(
      'users_blocked_between',
      params: {'first_user': userId, 'second_user': otherIds.single},
    );
    if (blocked == true) {
      throw StateError('Impossible d’appeler ce contact.');
    }
    return otherIds.single;
  }

  Future<void> recordOutgoingCall({
    required String conversationId,
    required String callType,
  }) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) throw StateError('Connectez-vous pour appeler.');
    final calleeId = await validateOutgoingCall(
      conversationId: conversationId,
      callType: callType,
    );

    await _client.from('call_logs').insert({
      'conversation_id': conversationId,
      'caller_id': userId,
      'callee_id': calleeId,
      'call_type': callType,
      'status': 'initiated',
    });
  }

  Future<List<Map<String, dynamic>>> getHistory() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) throw StateError('Connectez-vous pour voir vos appels.');
    final rows = await _client
        .from('call_logs')
        .select('id,conversation_id,caller_id,callee_id,call_type,status,started_at,ended_at')
        .or('caller_id.eq.$userId,callee_id.eq.$userId')
        .order('started_at', ascending: false)
        .limit(100);
    return List<Map<String, dynamic>>.from(rows);
  }
}
