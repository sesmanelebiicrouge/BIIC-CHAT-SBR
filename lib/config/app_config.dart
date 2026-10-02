class AppConfig {
  // BIIC CHAT production Supabase project.
  // Publishable/anon keys are intended for client applications and are
  // protected by Supabase Auth + Row Level Security.
  static const _defaultSupabaseUrl =
      'https://ktiawqonbjhzzghksngr.supabase.co';
  static const _defaultSupabasePublishableKey =
      'sb_publishable_Fc0Ekq2igdnN-_dxIcDijQ_M0evXXoB';

  static const supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: _defaultSupabaseUrl,
  );
  static const supabasePublishableKey = String.fromEnvironment(
    'SUPABASE_PUBLISHABLE_KEY',
    defaultValue: _defaultSupabasePublishableKey,
  );
  static const supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
  );

  static String get supabaseKey =>
      supabasePublishableKey.isNotEmpty ? supabasePublishableKey : supabaseAnonKey;

  static bool get hasSupabaseConfig =>
      supabaseUrl.isNotEmpty && supabaseKey.isNotEmpty;
}
