import 'package:supabase_flutter/supabase_flutter.dart';

class ConversationService {
  final SupabaseClient _supabase;

  ConversationService({SupabaseClient? client})
      : _supabase = client ?? Supabase.instance.client;

  Future<String> createConversation({
    required String name,
    required String createdBy,
    required List<String> memberIds,
    bool isGroup = false,
  }) async {
    if (memberIds.isEmpty) {
      throw ArgumentError.value(memberIds, 'memberIds', 'must not be empty');
    }

    try {
      final response = await _supabase
          .from('conversations')
          .insert({
            'name': name.trim(),
            'created_by': createdBy,
            'is_group': isGroup,
          })
          .select('id')
          .single();

      final conversationId = response['id'] as String;
      final now = DateTime.now().toIso8601String();

      await _supabase.from('conversation_members').insert(
            memberIds
                .toSet()
                .map(
                  (memberId) => {
                    'conversation_id': conversationId,
                    'user_id': memberId,
                    'joined_at': now,
                  },
                )
                .toList(),
          );

      return conversationId;
    } on PostgrestException catch (error) {
      throw Exception(
        'Impossible de créer la conversation: ${error.message}',
      );
    }
  }

  Stream<List<Map<String, dynamic>>> getUserConversations(String userId) {
    if (userId.isEmpty) return const Stream.empty();

    return _supabase
        .from('conversations')
        .stream(primaryKey: ['id'])
        .order('created_at', ascending: false)
        .map((data) => List<Map<String, dynamic>>.from(data));
  }
}
