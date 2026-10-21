import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart';

class ConversationService {
  final SupabaseClient _supabase;
  ConversationService({SupabaseClient? client})
      : _supabase = client ?? Supabase.instance.client;

  SupabaseClient get client => _supabase;

  String _requireAuthenticatedUserId() {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null || userId.isEmpty) {
      throw StateError('Utilisateur non connecté.');
    }
    return userId;
  }

  void _assertCallerIsAuthenticatedUser(String claimedUserId) {
    if (_requireAuthenticatedUserId() != claimedUserId.trim()) {
      throw StateError('Action refusée : identité utilisateur incohérente.');
    }
  }

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
    _assertCallerIsAuthenticatedUser(creator);
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
    _assertCallerIsAuthenticatedUser(uid);

    final response = await _supabase.rpc(
      'get_or_create_direct_conversation',
      params: {
        'target_user': uid,
        'other_user': other,
        'other_name': otherName.trim(),
      },
    );

    return response.toString();
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
    final uid = userId.trim();
    if (uid.isEmpty) return const Stream.empty();
    _assertCallerIsAuthenticatedUser(uid);
    return Stream.multi((controller) {
      List<Map<String, dynamic>>? conversations;
      Set<String>? archivedIds;
      void emitIfReady() {
        if (conversations == null || archivedIds == null) return;
        controller.add(
          conversations!
              .where((row) => !archivedIds!.contains(row['id']?.toString()))
              .toList(),
        );
      }

      final conversationsSubscription = _supabase
          .from('conversations')
          .stream(primaryKey: ['id'])
          .order('updated_at', ascending: false)
          .listen(
        (rows) {
          conversations = List<Map<String, dynamic>>.from(rows);
          emitIfReady();
        },
        onError: (Object error, StackTrace stackTrace) {
          controller.addError(error, stackTrace);
        },
      );

      final archivedSubscription = _supabase
          .from('archived_conversations')
          .stream(primaryKey: ['user_id', 'conversation_id'])
          .eq('user_id', uid)
          .listen(
        (rows) {
          archivedIds = rows
              .map((row) => row['conversation_id']?.toString() ?? '')
              .where((id) => id.isNotEmpty)
              .toSet();
          emitIfReady();
        },
        onError: (Object error, StackTrace stackTrace) {
          controller.addError(error, stackTrace);
        },
      );

      controller.onCancel = () async {
        await conversationsSubscription.cancel();
        await archivedSubscription.cancel();
      };
    });
  }

  Future<void> sendMessage({
    required String conversationId,
    required String senderId,
    required String content,
    String? mediaUrl,
    String? mediaType,
    String? replyToMessageId,
  }) async {
    final text = content.trim();
    final media = mediaUrl?.trim();
    if (conversationId.trim().isEmpty ||
        senderId.trim().isEmpty ||
        (text.isEmpty && (media == null || media.isEmpty))) {
      throw ArgumentError(
          'A message needs a conversation, sender and content/media.');
    }
    _assertCallerIsAuthenticatedUser(senderId);
    await _supabase.from('messages').insert({
      'conversation_id': conversationId.trim(),
      'sender_id': senderId.trim(),
      'content': text,
      if (media != null && media.isNotEmpty) 'media_url': media,
      if (mediaType != null && mediaType.trim().isNotEmpty)
        'media_type': mediaType.trim(),
      if (replyToMessageId != null && replyToMessageId.trim().isNotEmpty)
        'reply_to_message_id': replyToMessageId.trim(),
    });
  }


  Future<void> editMessage({
    required String messageId,
    required String content,
  }) async {
    final userId = _requireAuthenticatedUserId();
    final text = content.trim();
    if (text.isEmpty || text.length > 4000) {
      throw ArgumentError('Le message doit contenir entre 1 et 4 000 caractères.');
    }
    await _supabase.from('messages').update({
      'content': text,
      'edited_at': DateTime.now().toUtc().toIso8601String(),
    }).eq('id', messageId).eq('sender_id', userId);
  }

  Future<void> deleteMessage(String messageId) async {
    final userId = _requireAuthenticatedUserId();
    await _supabase.from('messages').update({
      'content': '',
      'deleted_at': DateTime.now().toUtc().toIso8601String(),
      'edited_at': DateTime.now().toUtc().toIso8601String(),
      'is_pinned': false,
    }).eq('id', messageId).eq('sender_id', userId);
  }

  Future<void> setMessagePinned({
    required String messageId,
    required bool pinned,
  }) async {
    final userId = _requireAuthenticatedUserId();
    await _supabase.from('messages').update({
      'is_pinned': pinned,
    }).eq('id', messageId).eq('sender_id', userId);
  }

  Future<void> setReaction({
    required String messageId,
    required String reaction,
  }) async {
    final userId = _requireAuthenticatedUserId();
    const allowed = {'👍', '❤️', '😂', '😮', '😢', '🙏', '🔥', '👏'};
    if (!allowed.contains(reaction)) throw ArgumentError('Réaction non prise en charge.');
    final existing = await _supabase
        .from('message_reactions')
        .select('reaction')
        .eq('message_id', messageId)
        .eq('user_id', userId)
        .maybeSingle();
    if (existing != null && existing['reaction'] == reaction) {
      await _supabase.from('message_reactions')
          .delete().eq('message_id', messageId).eq('user_id', userId);
    } else {
      await _supabase.from('message_reactions').upsert({
        'message_id': messageId,
        'user_id': userId,
        'reaction': reaction,
        'created_at': DateTime.now().toUtc().toIso8601String(),
      }, onConflict: 'message_id,user_id');
    }
  }

  Future<void> archiveConversation(String conversationId) async {
    final userId = _requireAuthenticatedUserId();
    await _supabase.from('archived_conversations').upsert({
      'user_id': userId,
      'conversation_id': conversationId,
      'archived_at': DateTime.now().toUtc().toIso8601String(),
    }, onConflict: 'user_id,conversation_id');
  }

  Future<void> unarchiveConversation(String conversationId) async {
    final userId = _requireAuthenticatedUserId();
    await _supabase.from('archived_conversations')
        .delete().eq('user_id', userId).eq('conversation_id', conversationId);
  }

  Future<List<Map<String, dynamic>>> getArchivedConversations() async {
    final userId = _requireAuthenticatedUserId();
    final rows = await _supabase
        .from('archived_conversations')
        .select('conversation_id,archived_at')
        .eq('user_id', userId)
        .order('archived_at', ascending: false);
    return List<Map<String, dynamic>>.from(rows);
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
    _assertCallerIsAuthenticatedUser(uid);

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

  Stream<List<Map<String, dynamic>>> watchMessageReactions() {
    return _supabase
        .from('message_reactions')
        .stream(primaryKey: ['message_id', 'user_id'])
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
