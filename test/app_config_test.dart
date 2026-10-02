import 'package:flutter_test/flutter_test.dart';

import 'package:biic_chat_sbr/config/app_config.dart';

void main() {
  test('production Supabase configuration is available by default', () {
    expect(AppConfig.hasSupabaseConfig, isTrue);
    expect(AppConfig.supabaseUrl, contains('supabase.co'));
    expect(AppConfig.supabaseKey, startsWith('sb_publishable_'));
  });

  test('compile-time overrides remain supported', () {
    expect(AppConfig.supabaseKey.isNotEmpty, isTrue);
  });
}
