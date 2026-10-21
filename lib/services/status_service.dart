import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';

class StatusService {
  final SupabaseClient _client;
  StatusService({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  String get _userId {
    final id = _client.auth.currentUser?.id;
    if (id == null || id.isEmpty) {
      throw StateError('Connectez-vous pour utiliser les statuts.');
    }
    return id;
  }

  Future<List<Map<String, dynamic>>> getVisibleStatuses() async {
    final rows = await _client
        .from('statuses')
        .select('id,user_id,content,media_path,media_type,audience,created_at,expires_at')
        .gt('expires_at', DateTime.now().toUtc().toIso8601String())
        .order('created_at', ascending: false)
        .limit(200);
    return List<Map<String, dynamic>>.from(rows);
  }

  Future<void> publishText({
    required String content,
    required String audience,
  }) async {
    final clean = content.trim();
    if (clean.isEmpty || clean.length > 700) {
      throw ArgumentError('Un statut texte doit contenir entre 1 et 700 caractères.');
    }
    if (!{'contacts', 'everyone'}.contains(audience)) {
      throw ArgumentError('Audience de statut invalide.');
    }
    await _client.from('statuses').insert({
      'user_id': _userId,
      'content': clean,
      'media_type': 'text',
      'audience': audience,
      'expires_at': DateTime.now().toUtc().add(const Duration(hours: 24)).toIso8601String(),
    });
  }

  Future<void> publishMedia({
    required Uint8List bytes,
    required String fileName,
    required String mediaType,
    required String audience,
  }) async {
    if (bytes.isEmpty || bytes.length > 50 * 1024 * 1024) {
      throw ArgumentError('Le fichier est vide ou dépasse la limite de 50 Mo.');
    }
    if (!{'image', 'video'}.contains(mediaType)) {
      throw ArgumentError('Type de média de statut invalide.');
    }
    if (!{'contacts', 'everyone'}.contains(audience)) {
      throw ArgumentError('Audience de statut invalide.');
    }
    final userId = _userId;
    final safeName = fileName.replaceAll(RegExp(r'[^a-zA-Z0-9._-]'), '_');
    final path = '$userId/${DateTime.now().microsecondsSinceEpoch}_${safeName.isEmpty ? 'status.bin' : safeName}';
    final extension = safeName.toLowerCase();
    if (mediaType == 'image' &&
        !(extension.endsWith('.jpg') || extension.endsWith('.jpeg') ||
          extension.endsWith('.png') || extension.endsWith('.webp'))) {
      throw ArgumentError('Format photo non pris en charge. Utilisez JPG, PNG ou WebP.');
    }
    if (mediaType == 'video' &&
        !(extension.endsWith('.mp4') || extension.endsWith('.mov'))) {
      throw ArgumentError('Format vidéo non pris en charge. Utilisez MP4 ou MOV.');
    }
    final contentType = mediaType == 'image'
        ? (extension.endsWith('.png')
            ? 'image/png'
            : extension.endsWith('.webp')
                ? 'image/webp'
                : 'image/jpeg')
        : (extension.endsWith('.mov') ? 'video/quicktime' : 'video/mp4');

    await _client.storage.from('status-media').uploadBinary(
      path,
      bytes,
      fileOptions: FileOptions(contentType: contentType, upsert: false),
    );
    try {
      await _client.from('statuses').insert({
        'user_id': userId,
        'media_path': path,
        'media_type': mediaType,
        'audience': audience,
        'expires_at': DateTime.now().toUtc().add(const Duration(hours: 24)).toIso8601String(),
      });
    } catch (_) {
      await _client.storage.from('status-media').remove([path]);
      rethrow;
    }
  }

  Future<String> createMediaUrl(String path) {
    return _client.storage.from('status-media').createSignedUrl(path, 300);
  }

  Future<void> markViewed(String statusId) async {
    final userId = _userId;
    await _client.from('status_views').upsert({
      'status_id': statusId,
      'viewer_id': userId,
      'viewed_at': DateTime.now().toUtc().toIso8601String(),
    }, onConflict: 'status_id,viewer_id');
  }

  Future<void> deleteStatus(String statusId) async {
    final row = await _client
        .from('statuses')
        .select('id,user_id,media_path')
        .eq('id', statusId)
        .eq('user_id', _userId)
        .maybeSingle();
    if (row == null) return;
    final mediaPath = row['media_path'] as String?;
    await _client.from('statuses').delete().eq('id', statusId).eq('user_id', _userId);
    if (mediaPath != null && mediaPath.isNotEmpty) {
      await _client.storage.from('status-media').remove([mediaPath]);
    }
  }
}
