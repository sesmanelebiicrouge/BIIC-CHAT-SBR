import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/app_config.dart';

Future<void> initializeBackend() async {
  if (!AppConfig.hasSupabaseConfig) return;

  await Supabase.initialize(
    url: AppConfig.supabaseUrl,
    publishableKey: AppConfig.supabaseKey,
  );
}
