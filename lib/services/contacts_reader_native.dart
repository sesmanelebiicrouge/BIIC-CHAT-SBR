import 'package:flutter_contacts/flutter_contacts.dart';

/// Reads contacts only after the operating system grants permission.
Future<List<Map<String, String>>> readDeviceContacts() async {
  final permission = await FlutterContacts.permissions.request(
    PermissionType.read,
  );
  if (permission != PermissionStatus.granted) {
    throw Exception(
      'Accès au répertoire refusé. Autorisez les contacts dans les paramètres '
      'du téléphone puis réessayez.',
    );
  }

  final contacts = await FlutterContacts.getAll(
    properties: {ContactProperty.name, ContactProperty.phone},
  );
  return [
    for (final contact in contacts)
      for (final phone in contact.phones)
        {
          'display_name': contact.displayName ?? '',
          'phone': phone.number,
        },
  ];
}
