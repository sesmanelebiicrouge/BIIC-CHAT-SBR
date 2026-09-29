import 'package:supabase_flutter/supabase_flutter.dart';

class ConversationService {
  final _supabase = Supabase.instance.client;

  Future<String> createConversation({
    required String name,
    required String createdBy,
    required List<String> memberIds,
    bool isGroup = false,
  }) async {
    try {
      final response = await _supabase.from('conversations').insert({
        'name': name,
        'created_by': createdBy,
        'is_group': isGroup,
        'created_at': DateTime.now().toIso8601String(),
      }).select();

      final conversationId = response[0]['id'];

      final members = memberIds
          .map((memberId) => {
                'conversation_id': conversationId,
                'user_id': memberId,
                'joined_at': DateTime.now().toIso8601String(),
              })
          .toList();

      await _supabase.from('conversation_members').insert(members);

      return conversationId;
    } catch (e) {
      throw Exception('Erreur lors de la creation de la conversation: $e');
    }
  }

  Stream<List<Map<String, dynamic>>> getUserConversations(String userId) {
    return _supabase
        .from('conversations')
        .stream(primaryKey: ['id'])
        .order('created_at', ascending: false)
        .map((data) => List<Map<String, dynamic>>.from(data));
  }
}
