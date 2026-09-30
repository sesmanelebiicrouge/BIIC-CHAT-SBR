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
    final normalizedMembers =
        memberIds.map((id) => id.trim()).where((id) => id.isNotEmpty).toSet();

    if (normalizedMembers.isEmpty) {
      throw ArgumentError.value(memberIds, 'memberIds', 'must not be empty');
    }
    if (createdBy.trim().isEmpty) {
      throw ArgumentError.value(createdBy, 'createdBy', 'must not be empty');
    }
    if (name.trim().isEmpty && isGroup) {
      throw ArgumentError.value(name, 'name', 'must not be empty for a group');
    }

    final response = await _supabase
        .from('conversations')
        .insert({
          'name': name.trim(),
          'created_by': createdBy.trim(),
          'is_group': isGroup,
        })
        .select('id')
        .single();

    final conversationId = response['id'] as String;

    await _supabase.from('conversation_members').insert(
          normalizedMembers
              .map((memberId) => {
                    'conversation_id': conversationId,
                    'user_id': memberId,
                  })
              .toList(),
        );

    return conversationId;
  }

  Stream<List<Map<String, dynamic>>> getUserConversations(String userId) {
    if (userId.trim().isEmpty) return const Stream.empty();

    return _supabase
        .from('conversations')
        .stream(primaryKey: ['id'])
        .order('updated_at', ascending: false)
        .map((rows) => List<Map<String, dynamic>>.from(rows));
  }

  Future<void> sendMessage({
    required String conversationId,
    required String senderId,
    required String content,
    String? mediaUrl,
    String? mediaType,
  }) async {
    final text = content.trim();
    final media = mediaUrl?.trim();
    if (conversationId.trim().isEmpty ||
        senderId.trim().isEmpty ||
        (text.isEmpty && (media == null || media.isEmpty))) {
      throw ArgumentError(
        'A message needs a conversation, sender and content/media.',
      );
    }

    await _supabase.from('messages').insert({
      'conversation_id': conversationId.trim(),
      'sender_id': senderId.trim(),
      'content': text,
      if (media != null && media.isNotEmpty) 'media_url': media,
      if (mediaType != null && mediaType.trim().isNotEmpty)
        'media_type': mediaType.trim(),
    });
  }

  Stream<List<Map<String, dynamic>>> watchMessages(String conversationId) {
    if (conversationId.trim().isEmpty) return const Stream.empty();

    return _supabase
        .from('messages')
        .stream(primaryKey: ['id'])
        .eq('conversation_id', conversationId.trim())
        .order('created_at', ascending: true)
        .map((rows) => List<Map<String, dynamic>>.from(rows));
  }
}
