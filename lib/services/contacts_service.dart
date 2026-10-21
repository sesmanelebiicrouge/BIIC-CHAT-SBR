import 'package:flutter/foundation.dart';
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

/// Splits large contact lists into requests small enough for the Supabase RPC.
/// Kept as a pure helper so batch boundaries can be tested without device access.
List<List<T>> splitIntoBatches<T>(List<T> items, {int batchSize = 500}) {
  if (batchSize < 1) {
    throw ArgumentError.value(batchSize, 'batchSize', 'Must be greater than zero.');
  }

  final batches = <List<T>>[];
  for (var start = 0; start < items.length; start += batchSize) {
    final end = (start + batchSize < items.length) ? start + batchSize : items.length;
    batches.add(items.sublist(start, end));
  }
  return batches;
}

class ContactsService {
  final SupabaseClient _client;
  ContactsService({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  Future<List<ImportedContact>> importDeviceContacts() async {
    if (kIsWeb) {
      throw UnsupportedError(
        'L’import des contacts de l’appareil est disponible sur Android/iOS. Sur le Web, utilisez la recherche de membres.',
      );
    }
    final permission =
        await FlutterContacts.permissions.request(PermissionType.read);
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

    // The database RPC deliberately limits each request to 1,000 contacts.
    // Smaller batches reduce request size and prevent large address books from
    // failing as one all-or-nothing import.
    final rows = <Map<String, dynamic>>[];
    for (final batch in splitIntoBatches(payload)) {
      final response = await _client.rpc(
        'sync_device_contacts',
        params: {'p_contacts': batch},
      );
      rows.addAll(List<Map<String, dynamic>>.from(response as List));
    }

    return rows
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
