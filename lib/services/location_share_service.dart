import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

import 'device_permissions_service.dart';

/// Obtains a one-time foreground position only after the user chooses to share it.
/// The coordinates are sent as a normal chat message containing a map link;
/// this service does not track the user in the background.
class LocationShareService {
  final DevicePermissionsService _permissions;

  LocationShareService({DevicePermissionsService? permissions})
      : _permissions = permissions ?? DevicePermissionsService();

  Future<String> createLocationMessage() async {
    // permission_handler's native permission dialog is not available on Web;
    // Geolocator uses the browser's own location permission there.
    if (!kIsWeb) {
      await _permissions.requestLocationWhileInUse();
    }

    if (!await Geolocator.isLocationServiceEnabled()) {
      throw StateError(
        'La localisation du téléphone est désactivée. Activez-la puis réessayez.',
      );
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.deniedForever) {
      throw StateError(
        'La localisation est bloquée pour BIIC CHAT dans les paramètres de votre appareil.',
      );
    }
    if (permission == LocationPermission.denied) {
      throw StateError(
        'Autorisez la localisation pour partager votre position.',
      );
    }

    final position = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        timeLimit: Duration(seconds: 20),
      ),
    );

    return '📍 Ma position : ${googleMapsUrl(position.latitude, position.longitude)}';
  }

  /// Kept pure so the generated map link can be tested without device GPS.
  static String googleMapsUrl(double latitude, double longitude) {
    if (!latitude.isFinite ||
        !longitude.isFinite ||
        latitude < -90 ||
        latitude > 90 ||
        longitude < -180 ||
        longitude > 180) {
      throw ArgumentError('Coordonnées GPS invalides.');
    }

    final coordinates =
        '${latitude.toStringAsFixed(6)},${longitude.toStringAsFixed(6)}';
    return Uri.https(
      'www.google.com',
      '/maps/search/',
      {'api': '1', 'query': coordinates},
    ).toString();
  }
}
