import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';

class MediaService {
  final SupabaseClient _client;
  MediaService({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  Future<String> uploadChatFile({
    required String conversationId,
    required String fileName,
    required Uint8List bytes,
    String? contentType,
  }) async {
    final conversation = conversationId.trim();
    final isUuid = RegExp(
      r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[1-8][0-9a-fA-F]{3}-[89abAB][0-9a-fA-F]{3}-[0-9a-fA-F]{12}$',
    ).hasMatch(conversation);
    if (!isUuid) {
      throw ArgumentError('Identifiant de conversation invalide.');
    }
    if (bytes.isEmpty) {
      throw ArgumentError('Le fichier est vide.');
    }
    if (bytes.length > 50 * 1024 * 1024) {
      throw ArgumentError('Fichier trop volumineux : 50 Mo maximum.');
    }

    final sanitizedName = fileName.trim().replaceAll(RegExp(r'[^a-zA-Z0-9._-]'), '_');
    final safeName = sanitizedName.isEmpty ? 'attachment.bin' : sanitizedName;
    final path =
        'chat/$conversation/${DateTime.now().microsecondsSinceEpoch}_$safeName';
    await _client.storage.from('chat-media').uploadBinary(
          path,
          bytes,
          fileOptions: FileOptions(
            contentType: contentType,
            upsert: false,
          ),
        );
    return path;
  }

  Future<void> deleteChatFile(String path) async {
    final cleanPath = path.trim();
    if (cleanPath.isEmpty) return;
    await _client.storage.from('chat-media').remove([cleanPath]);
  }

  Future<String> createSignedUrl(String path, {int expiresIn = 3600}) {
    return _client.storage.from('chat-media').createSignedUrl(path, expiresIn);
  }
}
