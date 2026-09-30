import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ImportedContact {
  final String phone;
  final String displayName;
  final String? matchedUserId;
  final String? matchedDisplayName;
  final String? matchedStatus;

  const ImportedContact({
    required this.phone,
    required this.displayName,
    this.matchedUserId,
    this.matchedDisplayName,
    this.matchedStatus,
  });

  bool get isOnBiicChat => matchedUserId != null;
}

class ContactsService {
  final SupabaseClient _client;
  ContactsService({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  Future<List<ImportedContact>> importDeviceContacts() async {
    final permission =
        await FlutterContacts.permissions.request(PermissionType.readWrite);
    if (permission != PermissionStatus.granted) {
      throw Exception(
        'Autorisez l’accès aux contacts pour rechercher vos contacts sur BIIC CHAT.',
      );
    }

    final contacts = await FlutterContacts.getAll(
      properties: {ContactProperty.name, ContactProperty.phone},
    );

    final payload = <Map<String, String>>[];
    final seen = <String>{};

    for (final contact in contacts) {
      final name = (contact.displayName ?? '').trim();
      for (final phone in contact.phones) {
        final value = phone.number.trim();
        final digits = value.replaceAll(RegExp(r'[^0-9]'), '');
        if (digits.length < 8 || !seen.add(digits)) continue;
        payload.add({'phone': value, 'display_name': name});
      }
    }

    if (payload.isEmpty) return const [];

    final response = await _client.rpc(
      'sync_device_contacts',
      params: {'p_contacts': payload},
    );

    return List<Map<String, dynamic>>.from(response as List)
        .map(
          (row) => ImportedContact(
            phone: row['phone'] as String? ?? '',
            displayName: row['display_name'] as String? ?? '',
            matchedUserId: row['matched_user_id'] as String?,
            matchedDisplayName: row['matched_display_name'] as String?,
            matchedStatus: row['matched_status'] as String?,
          ),
        )
        .toList();
  }
}
