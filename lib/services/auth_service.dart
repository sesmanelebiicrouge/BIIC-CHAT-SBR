import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  SupabaseClient get _client => Supabase.instance.client;
  Session? get currentSession => _client.auth.currentSession;
  Stream<AuthState> get authStateChanges => _client.auth.onAuthStateChange;

  Future<void> signIn({required String phone, required String password}) async {
    await _client.auth.signInWithPassword(phone: phone.trim(), password: password);
  }

  Future<AuthResponse> signUp({required String phone, required String password, required String displayName}) {
    return _client.auth.signUp(
      phone: phone.trim(),
      password: password,
      data: {'display_name': displayName.trim()},
    );
  }

  Future<AuthResponse> verifyPhone({required String phone, required String token}) {
    return _client.auth.verifyOTP(type: OtpType.sms, phone: phone.trim(), token: token.trim());
  }

  Future<void> resendPhoneCode(String phone) async {
    await _client.auth.signInWithOtp(phone: phone.trim(), shouldCreateUser: false);
  }

  Future<void> requestPasswordReset(String phone) async {
    await _client.auth.signInWithOtp(phone: phone.trim(), shouldCreateUser: false);
  }

  Future<AuthResponse> verifyPasswordResetCode({required String phone, required String token}) {
    return _client.auth.verifyOTP(type: OtpType.sms, phone: phone.trim(), token: token.trim());
  }

  Future<void> updatePassword(String password) async {
    await _client.auth.updateUser(UserAttributes(password: password));
  }

  Future<void> signOut() => _client.auth.signOut();
}
