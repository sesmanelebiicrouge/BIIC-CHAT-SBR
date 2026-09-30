import 'package:supabase_flutter/supabase_flutter.dart';

class ConversationService {
  final SupabaseClient _supabase;
  ConversationService({SupabaseClient? client})
      : _supabase = client ?? Supabase.instance.client;

  SupabaseClient get client => _supabase;

  Future<String> createConversation({
    required String name,
    required String createdBy,
    required List<String> memberIds,
    bool isGroup = false,
  }) async {
    final creator = createdBy.trim();
    final members = {
      ...memberIds.map((id) => id.trim()).where((id) => id.isNotEmpty),
      creator,
    };
    if (creator.isEmpty || members.length < 2) {
      throw ArgumentError('Une conversation doit avoir au moins deux membres.');
    }
    if (isGroup && name.trim().isEmpty) {
      throw ArgumentError('Le nom du groupe est obligatoire.');
    }

    final response = await _supabase.from('conversations').insert({
      'name': name.trim(),
      'created_by': creator,
      'is_group': isGroup,
    }).select('id').single();

    final conversationId = response['id'] as String;
    await _supabase.from('conversation_members').insert(
      members
          .map((id) => {'conversation_id': conversationId, 'user_id': id})
          .toList(),
    );
    return conversationId;
  }

  Future<String> getOrCreateDirectConversation({
    required String currentUserId,
    required String otherUserId,
    required String otherName,
  }) async {
    final uid = currentUserId.trim();
    final other = otherUserId.trim();
    if (uid.isEmpty || other.isEmpty || uid == other) {
      throw ArgumentError('Membres invalides.');
    }

    final existing = await _supabase
        .from('conversation_members')
        .select('conversation_id, conversations!inner(id, is_group)')
        .eq('user_id', uid);

    for (final row in List<Map<String, dynamic>>.from(existing)) {
      final conversation = row['conversations'];
      if (conversation is Map && conversation['is_group'] == false) {
        final id = row['conversation_id'];
        final members = await _supabase
            .from('conversation_members')
            .select('user_id')
            .eq('conversation_id', id);
        final ids = List<Map<String, dynamic>>.from(members)
            .map((m) => m['user_id'])
            .toSet();
        if (ids.length == 2 && ids.contains(other) && ids.contains(uid)) {
          return id as String;
        }
      }
    }

    return createConversation(
      name: otherName.trim().isEmpty ? 'Conversation' : otherName.trim(),
      createdBy: uid,
      memberIds: [uid, other],
    );
  }

  Future<List<Map<String, dynamic>>> getConversationMembers(
      String conversationId) async {
    if (conversationId.trim().isEmpty) return const [];
    final rows =
        await _supabase.rpc('list_conversation_members', params: {
      'target_conversation': conversationId.trim(),
    });
    return List<Map<String, dynamic>>.from(rows);
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
          'A message needs a conversation, sender and content/media.');
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

  Future<void> markMessagesRead({
    required String userId,
    required String conversationId,
    required List<String> messageIds,
  }) async {
    final uid = userId.trim();
    final conversation = conversationId.trim();
    final ids = messageIds.map((id) => id.trim()).where((id) => id.isNotEmpty).toSet();
    if (uid.isEmpty || conversation.isEmpty || ids.isEmpty) return;

    await _supabase.from('message_reads').upsert(
      ids
          .map((messageId) => {
                'message_id': messageId,
                'user_id': uid,
                'conversation_id': conversation,
              })
          .toList(),
      onConflict: 'message_id,user_id',
      ignoreDuplicates: true,
    );
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

  Stream<List<Map<String, dynamic>>> watchMessageReads(String conversationId) {
    if (conversationId.trim().isEmpty) return const Stream.empty();
    return _supabase
        .from('message_reads')
        .stream(primaryKey: ['message_id', 'user_id'])
        .eq('conversation_id', conversationId.trim())
        .order('read_at', ascending: true)
        .map((rows) => List<Map<String, dynamic>>.from(rows));
  }
}
