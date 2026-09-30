import 'package:flutter_test/flutter_test.dart';

import 'package:biic_chat_sbr/config/app_config.dart';

void main() {
  test('Supabase configuration is disabled when compile-time values are absent', () {
    expect(AppConfig.hasSupabaseConfig, isFalse);
  });
}
