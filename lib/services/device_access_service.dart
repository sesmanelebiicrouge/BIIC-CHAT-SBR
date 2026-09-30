import 'package:file_picker/file_picker.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';

class DeviceAccessService {
  final ImagePicker _imagePicker = ImagePicker();

  Future<XFile?> pickImageFromGallery() => _imagePicker.pickImage(source: ImageSource.gallery);
  Future<XFile?> pickMedia() => _imagePicker.pickMedia();
  Future<XFile?> takePhoto() => _imagePicker.pickImage(source: ImageSource.camera);

  Future<List<PlatformFile>> pickFiles() => FilePicker.pickFiles();

  Future<List<Contact>> pickContacts() async {
    final permission = await FlutterContacts.permissions.request(PermissionType.readWrite);
    if (permission != PermissionStatus.granted) {
      throw Exception('Accès aux contacts refusé');
    }
    return FlutterContacts.getAll(
      properties: {ContactProperty.name, ContactProperty.phone},
    );
  }

  Future<void> callNumber(String number) async {
    final uri = Uri(scheme: 'tel', path: number.trim());
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      throw Exception('Impossible de lancer l’appel');
    }
  }
}
