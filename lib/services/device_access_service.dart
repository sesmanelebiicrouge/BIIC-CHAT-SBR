import 'package:file_picker/file_picker.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';

class DeviceAccessService {
  final ImagePicker _imagePicker = ImagePicker();

  Future<XFile?> pickImageFromGallery() {
    return _imagePicker.pickImage(source: ImageSource.gallery);
  }

  Future<XFile?> takePhoto() {
    return _imagePicker.pickImage(source: ImageSource.camera);
  }

  Future<FilePickerResult?> pickFiles() {
    return FilePicker.platform.pickFiles(allowMultiple: true);
  }

  Future<List<Contact>> pickContacts() async {
    final granted = await FlutterContacts.requestPermission(readonly: true);
    if (!granted) {
      throw Exception('Accès aux contacts refusé');
    }

    return FlutterContacts.getContacts(withProperties: true);
  }

  Future<void> callNumber(String number) async {
    final uri = Uri(scheme: 'tel', path: number);
    if (!await launchUrl(uri)) {
      throw Exception('Impossible de lancer l’appel');
    }
  }
}
