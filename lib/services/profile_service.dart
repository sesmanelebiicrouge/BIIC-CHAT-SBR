import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart';

class ProfileService {
  final SupabaseClient _client;
  ProfileService({SupabaseClient? client}) : _client = client ?? Supabase.instance.client;

  Future<Map<String, dynamic>> getMyProfile() async {
    final user = _client.auth.currentUser;
    if (user == null) throw StateError('Utilisateur non connecté.');
    final row = await _client.from('users').select('id, display_name, email, avatar_url, bio, status').eq('id', user.id).single();
    return Map<String, dynamic>.from(row);
  }

  Future<void> updateProfile({required String displayName, String? bio, String? status}) async {
    final user = _client.auth.currentUser;
    if (user == null) throw StateError('Utilisateur non connecté.');
    final name = displayName.trim();
    if (name.length < 2 || name.length > 60) throw ArgumentError('Le nom doit contenir entre 2 et 60 caractères.');
    final cleanBio = bio?.trim();
    if (cleanBio != null && cleanBio.length > 280) throw ArgumentError('La bio ne peut pas dépasser 280 caractères.');
    final allowedStatus = {'online', 'offline', 'busy', 'away'};
    final cleanStatus = status == null || !allowedStatus.contains(status) ? 'offline' : status;
    await _client.from('users').update({'display_name': name, 'bio': cleanBio, 'status': cleanStatus}).eq('id', user.id);
  }

  Future<String> uploadAvatar(Uint8List bytes, {String fileName = 'avatar.jpg'}) async {
    final user = _client.auth.currentUser;
    if (user == null) throw StateError('Utilisateur non connecté.');
    if (bytes.isEmpty || bytes.length > 8 * 1024 * 1024) throw ArgumentError('Avatar invalide ou trop volumineux (8 Mo maximum).');
    final safe = fileName.replaceAll(RegExp(r'[^a-zA-Z0-9._-]'), '_');
    final path = '${user.id}/${DateTime.now().microsecondsSinceEpoch}_$safe';
    await _client.storage.from('avatars').uploadBinary(path, bytes, fileOptions: const FileOptions(upsert: false));
    await _client.from('users').update({'avatar_url': path}).eq('id', user.id);
    return path;
  }

  Future<String?> createAvatarSignedUrl(String? path) async {
    if (path == null || path.trim().isEmpty) return null;
    return _client.storage.from('avatars').createSignedUrl(path, 3600);
  }
}