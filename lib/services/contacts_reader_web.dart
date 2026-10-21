import 'dart:js_interop';

@JS('navigator.contacts')
external JSObject? get _browserContacts;

@JS('navigator.contacts.select')
external JSPromise<JSArray<JSObject>> _selectBrowserContacts(
  JSArray<JSString> properties,
  _ContactPickerOptions options,
);

@JS()
@anonymous
extension type _ContactPickerOptions._(JSObject _) implements JSObject {
  external factory _ContactPickerOptions({bool multiple});
}

@JS()
@anonymous
extension type _BrowserContact._(JSObject _) implements JSObject {
  external JSArray<JSString>? get name;
  external JSArray<JSString>? get tel;
}

/// Uses the browser Contact Picker API where available (notably Chrome on
/// Android). Only contacts explicitly chosen by the user are returned.
Future<List<Map<String, String>>> readDeviceContacts() async {
  if (_browserContacts == null) {
    throw UnsupportedError(
      'Ce navigateur ne permet pas d’ouvrir le répertoire directement. '
      'Ouvrez BIIC CHAT dans Chrome sur Android, puis réessayez, ou utilisez '
      '« Rechercher par nom ou numéro ».',
    );
  }

  // Call immediately from the button tap: browsers require a user gesture.
  final selected = await _selectBrowserContacts(
    ['name'.toJS, 'tel'.toJS].toJS,
    _ContactPickerOptions(multiple: true),
  ).toDart;

  final result = <Map<String, String>>[];
  for (final rawContact in selected.toDart) {
    final contact = _BrowserContact(rawContact);
    final names = contact.name?.toDart ?? const <JSString>[];
    final phones = contact.tel?.toDart ?? const <JSString>[];
    final name = names.isNotEmpty ? names.first.toDart : '';

    for (final phone in phones) {
      final value = phone.toDart.trim();
      if (value.isNotEmpty) {
        result.add({'display_name': name, 'phone': value});
      }
    }
  }
  return result;
}
