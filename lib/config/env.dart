/// Environment configuration for BIIC CHAT
/// 
/// Load environment variables from Flutter's dart-define flags
class Environment {
  /// Supabase project URL
  static const String supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://your-project.supabase.co',
  );

  /// Supabase publishable key (anon)
  static const String supabasePublishableKey = String.fromEnvironment(
    'SUPABASE_PUBLISHABLE_KEY',
    defaultValue: 'your_anon_public_key',
  );

  /// Supabase service role key (server-side only, never expose in app)
  static const String supabaseServiceRoleKey = String.fromEnvironment(
    'SUPABASE_SERVICE_ROLE_KEY',
    defaultValue: '',
  );

  /// SMS Provider (e.g., 'supabase', 'celcom', 'twilio')
  static const String smsProvider = String.fromEnvironment(
    'SMS_PROVIDER',
    defaultValue: 'supabase',
  );

  /// SMS API Key (if using external SMS provider)
  static const String smsApiKey = String.fromEnvironment(
    'SMS_API_KEY',
    defaultValue: '',
  );

  /// Environment type (development, staging, production)
  static const String environment = String.fromEnvironment(
    'FLUTTER_ENV',
    defaultValue: 'development',
  );

  /// Check if running in production
  static bool get isProduction => environment == 'production';

  /// Check if running in development
  static bool get isDevelopment => environment == 'development';

  /// Validate critical configuration
  static bool isConfigured() {
    return supabaseUrl != 'https://your-project.supabase.co' &&
        supabasePublishableKey != 'your_anon_public_key';
  }
}
