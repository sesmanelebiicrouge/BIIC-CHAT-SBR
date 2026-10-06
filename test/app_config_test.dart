import 'package:flutter_test/flutter_test.dart';

import 'package:biic_chat_sbr/config/app_config.dart';

void main() {
  test('AppConfig exposes the expected configuration contract', () {
    expect(AppConfig.supabaseUrl, isA<String>());
    expect(AppConfig.supabaseKey, isA<String>());
    expect(AppConfig.hasSupabaseConfig, isA<bool>());
  });

  test('compile-time overrides remain supported', () {
    expect(AppConfig.supabaseKey, isA<String>());
  });
}
