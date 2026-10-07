class AppConfig {
  // Runtime configuration is provided by Flutter build-time defines.
  // Do not commit real production credentials.
  static const supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: '',
  );
  static const supabasePublishableKey = String.fromEnvironment(
    'SUPABASE_PUBLISHABLE_KEY',
    defaultValue: '',
  );
  static const supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: '',
  );

  // Temporary QA mode: allow direct access without sign-up in test builds only.
  // This must be disabled before production/public deployment.
  static const allowGuestAccess = bool.fromEnvironment(
    'BIIC_GUEST_ACCESS',
    defaultValue: false,
  );

  static String get supabaseKey =>
      supabasePublishableKey.isNotEmpty ? supabasePublishableKey : supabaseAnonKey;

  static bool get hasSupabaseConfig =>
      supabaseUrl.isNotEmpty && supabaseKey.isNotEmpty;
}
