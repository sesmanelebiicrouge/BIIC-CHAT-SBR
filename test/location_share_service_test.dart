import 'package:biic_chat_sbr/services/location_share_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('LocationShareService.googleMapsUrl', () {
    test('creates a Google Maps link with six decimal places', () {
      final uri = Uri.parse(
        LocationShareService.googleMapsUrl(5.34567891, -4.01234567),
      );

      expect(uri.scheme, 'https');
      expect(uri.host, 'www.google.com');
      expect(uri.path, '/maps/search/');
      expect(uri.queryParameters['api'], '1');
      expect(uri.queryParameters['query'], '5.345679,-4.012346');
    });

    test('rejects coordinates outside the valid GPS ranges', () {
      expect(
        () => LocationShareService.googleMapsUrl(91, 0),
        throwsArgumentError,
      );
      expect(
        () => LocationShareService.googleMapsUrl(0, -181),
        throwsArgumentError,
      );
      expect(
        () => LocationShareService.googleMapsUrl(double.nan, 0),
        throwsArgumentError,
      );
    });
  });
}
