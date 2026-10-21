import 'dart:js_util' as js_util;

/// Uses the browser Contact Picker API where available (notably Chrome on
/// Android). The browser opens its own picker and only returns contacts chosen
/// explicitly by the user. It must be called directly from a user gesture.
Future<List<Map<String, String>>> readDeviceContacts() async {
  final navigator = js_util.getProperty<Object?>(js_util.globalThis, 'navigator');
  final contactsApi = js_util.getProperty<Object?>(navigator, 'contacts');
  final select = contactsApi == null
      ? null
      : js_util.getProperty<Object?>(contactsApi, 'select');

  if (contactsApi == null || select == null) {
    throw UnsupportedError(
      'Ce navigateur ne permet pas d’ouvrir le répertoire directement. '
      'Ouvrez BIIC CHAT dans Chrome sur Android, puis réessayez, ou utilisez '
      '« Rechercher par nom ou numéro ».',
    );
  }

  // Do not insert an await before this call: browsers require a direct user
  // gesture for the native contact picker.
  final promise = js_util.callMethod<Object?>(
    contactsApi,
    'select',
    [
      js_util.jsify(['name', 'tel']),
      js_util.jsify({'multiple': true}),
    ],
  );
  final selected = await js_util.promiseToFuture<Object?>(promise);
  final contacts = js_util.dartify(selected);
  if (contacts is! List) return const [];

  final result = <Map<String, String>>[];
  for (final entry in contacts) {
    final namesValue = js_util.getProperty<Object?>(entry, 'name');
    final phonesValue = js_util.getProperty<Object?>(entry, 'tel');
    final names = js_util.dartify(namesValue);
    final phones = js_util.dartify(phonesValue);
    final name = names is List && names.isNotEmpty ? names.first.toString() : '';

    if (phones is List) {
      for (final phone in phones) {
        final value = phone.toString().trim();
        if (value.isNotEmpty) {
          result.add({'display_name': name, 'phone': value});
        }
      }
    }
  }
  return result;
}
