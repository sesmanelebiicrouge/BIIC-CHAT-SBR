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

  Future<void> changePhone(String newPhone) async {
    await _client.auth.updateUser(UserAttributes(phone: newPhone.trim()));
  }

  Future<AuthResponse> verifyPhoneChange({required String phone, required String token}) {
    return _client.auth.verifyOTP(type: OtpType.phoneChange, phone: phone.trim(), token: token.trim());
  }

  Future<MFAEnrollResponse> enrollTotp({String? friendlyName}) {
    return _client.auth.mfa.enroll(
      factorType: FactorType.totp,
      friendlyName: friendlyName,
      issuer: 'BIIC CHAT',
    );
  }

  Future<AuthResponse> verifyTotp({required String factorId, required String code}) async {
    final challenge = await _client.auth.mfa.challenge(factorId: factorId);
    return _client.auth.mfa.verify(
      factorId: factorId,
      challengeId: challenge.id,
      code: code.trim(),
    );
  }

  Future<void> deleteMyAccount() async {
    await _client.rpc('delete_my_account');
    await _client.auth.signOut();
  }

  Future<void> signOut() => _client.auth.signOut();
}
