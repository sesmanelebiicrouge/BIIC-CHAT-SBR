class AppConfig {
  // Public Supabase client configuration for BIIC CHAT.
  // Publishable keys are intended for browser/mobile clients; RLS protects the data.
  static const supabaseUrl = 'https://ktiawqonbjhzzghksngr.supabase.co';
  static const supabasePublishableKey = 'sb_publishable_Fc0Ekq2igdnN-_dxIcDijQ_M0evXXoB';
  static const supabaseAnonKey = '';

  static String get supabaseKey => supabasePublishableKey;

  static bool get hasSupabaseConfig =>
      supabaseUrl.isNotEmpty && supabaseKey.isNotEmpty;
}
