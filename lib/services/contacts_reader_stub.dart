/// Fallback for targets where device contacts are not available.
Future<List<Map<String, String>>> readDeviceContacts() async {
  throw UnsupportedError(
    'La lecture du répertoire n’est pas prise en charge sur cet appareil. '
    'Recherchez les membres BIIC CHAT par leur nom ou numéro.',
  );
}
