import 'package:supabase_flutter/supabase_flutter.dart';

import 'contacts_reader_stub.dart'
    if (dart.library.html) 'contacts_reader_web.dart'
    if (dart.library.io) 'contacts_reader_native.dart' as platform_contacts;

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
    final deviceContacts = await platform_contacts.readDeviceContacts();
    final payload = <Map<String, String>>[];
    final seen = <String>{};

    for (final contact in deviceContacts) {
      final name = (contact['display_name'] ?? '').trim();
      final value = (contact['phone'] ?? '').trim();
      final digits = value.replaceAll(RegExp(r'[^0-9]'), '');
      if (digits.length < 8 || !seen.add(digits)) continue;
      payload.add({'phone': value, 'display_name': name});
    }

    if (payload.isEmpty) return const [];

    // Keep each RPC request small so large address books do not fail at once.
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
