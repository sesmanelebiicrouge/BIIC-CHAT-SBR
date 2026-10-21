import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart' as ph;

/// Requests device permissions only when the user invokes the related feature.
/// It deliberately does not request broad storage access: image_picker and
/// file_picker use the platform's scoped pickers.
class DevicePermissionsService {
  Future<bool> _request(ph.Permission permission, String feature) async {
    if (kIsWeb) {
      throw UnsupportedError('$feature n’est pas disponible dans le navigateur.');
    }
    final status = await permission.status;
    if (status.isGranted || status.isLimited) return true;

    final result = await permission.request();
    if (result.isGranted || result.isLimited) return true;
    if (result.isPermanentlyDenied || result.isRestricted) {
      throw DevicePermissionDenied(
        '$feature est bloqué dans les paramètres du téléphone. '
        'Vous pouvez l’activer manuellement dans les autorisations de BIIC CHAT.',
        permanentlyDenied: true,
      );
    }
    throw DevicePermissionDenied('Autorisez $feature pour utiliser cette fonctionnalité.');
  }

  Future<bool> requestCamera() => _request(ph.Permission.camera, 'la caméra');
  Future<bool> requestMicrophone() => _request(ph.Permission.microphone, 'le microphone');
  Future<bool> requestContacts() => _request(ph.Permission.contacts, 'les contacts');
  Future<bool> requestLocationWhileInUse() =>
      _request(ph.Permission.locationWhenInUse, 'la localisation pendant l’utilisation');
  Future<bool> requestCalendarReadWrite() =>
      _request(ph.Permission.calendarFullAccess, 'le calendrier');
  Future<bool> requestNotifications() =>
      _request(ph.Permission.notification, 'les notifications');

  /// Opens the operating-system app settings after the user has been informed.
  Future<bool> openAppSettings() => ph.openAppSettings();
}

class DevicePermissionDenied implements Exception {
  final String message;
  final bool permanentlyDenied;
  const DevicePermissionDenied(this.message, {this.permanentlyDenied = false});

  @override
  String toString() => message;
}
