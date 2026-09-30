import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';

class MediaService {
  final SupabaseClient _client;
  MediaService({SupabaseClient? client}) : _client = client ?? Supabase.instance.client;

  Future<String> uploadChatFile({
    required String conversationId,
    required String fileName,
    required Uint8List bytes,
    String? contentType,
  }) async {
    final safeName = fileName.replaceAll(RegExp(r'[^a-zA-Z0-9._-]'), '_');
    final path = 'chat/$conversationId/${DateTime.now().microsecondsSinceEpoch}_$safeName';
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

  Future<String> createSignedUrl(String path, {int expiresIn = 3600}) {
    return _client.storage.from('chat-media').createSignedUrl(path, expiresIn);
  }
}
