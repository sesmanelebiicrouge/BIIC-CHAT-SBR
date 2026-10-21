import 'package:supabase_flutter/supabase_flutter.dart';

class CallHistoryService {
  final SupabaseClient _client;
  CallHistoryService({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  Future<void> recordOutgoingCall({
    required String conversationId,
    required String callType,
  }) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) throw StateError('Connectez-vous pour appeler.');
    if (!{'audio', 'video'}.contains(callType)) {
      throw ArgumentError('Type d’appel invalide.');
    }

    final rows = await _client
        .from('conversation_members')
        .select('user_id')
        .eq('conversation_id', conversationId);
    final members = List<Map<String, dynamic>>.from(rows);
    final otherIds = members
        .map((row) => row['user_id']?.toString() ?? '')
        .where((id) => id.isNotEmpty && id != userId)
        .toList();
    if (otherIds.isEmpty) {
      throw StateError('Aucun autre participant dans cette conversation.');
    }
    if (otherIds.length > 1) {
      throw StateError('Les appels de groupe ne sont pas encore pris en charge.');
    }

    await _client.from('call_logs').insert({
      'conversation_id': conversationId,
      'caller_id': userId,
      'callee_id': otherIds.single,
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
