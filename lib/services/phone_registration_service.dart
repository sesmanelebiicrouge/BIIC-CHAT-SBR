import 'package:supabase_flutter/supabase_flutter.dart';

class PhoneRegistrationService {
  final SupabaseClient _client;
  PhoneRegistrationService({SupabaseClient? client}) : _client = client ?? Supabase.instance.client;

  Future<Map<String, dynamic>> getStatus() async {
    final user = _client.auth.currentUser;
    if (user == null) throw StateError('Utilisateur non connecté.');
    final row = await _client.from('users').select('registered_phone, phone_verified_at, registration_email').eq('id', user.id).single();
    return Map<String, dynamic>.from(row);
  }

  Future<Map<String, dynamic>> _invoke(Map<String, dynamic> body) async {
    final response = await _client.functions.invoke('phone-registration', body: body);
    final data = Map<String, dynamic>.from(response.data as Map);
    if (response.status >= 400 || data['error'] != null) {
      throw Exception(data['error'] ?? 'Opération impossible.');
    }
    return data;
  }

  Future<String?> requestCode(String phone, {String? email}) async {
    final data = await _invoke({
      'action': 'start',
      'phone': phone.trim(),
      if (email != null && email.trim().isNotEmpty)
        'email': email.trim().toLowerCase(),
    });
    return data['emailHint'] as String?;
  }

  Future<void> verifyCode(String code) async {
    await _invoke({'action': 'verify', 'code': code.trim()});
  }
}
