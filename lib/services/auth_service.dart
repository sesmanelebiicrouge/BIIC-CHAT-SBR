import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  SupabaseClient get _client => Supabase.instance.client;
  Session? get currentSession => _client.auth.currentSession;
  Stream<AuthState> get authStateChanges => _client.auth.onAuthStateChange;

  Future<void> signIn({required String phone, required String password}) async {
    try {
      await _client.auth.signInWithPassword(phone: phone.trim(), password: password);
    } on AuthException catch (e) {
      throw AuthServiceException.fromAuthException(e);
    } catch (e) {
      throw AuthServiceException('Connexion au serveur impossible. Vérifiez votre connexion Internet puis réessayez.', e.toString());
    }
  }

  Future<AuthResponse> signUp({required String phone, required String password, required String displayName}) async {
    try {
      final response = await _client.auth.signUp(
        phone: phone.trim(),
        password: password,
        data: {'display_name': displayName.trim()},
      );
      if (response.user == null) {
        throw const AuthServiceException(
          'Le serveur n’a pas créé le compte. Vérifiez le numéro puis réessayez.',
          'signup_no_user',
        );
      }
      return response;
    } on AuthServiceException {
      rethrow;
    } on AuthException catch (e) {
      throw AuthServiceException.fromAuthException(e);
    } catch (e) {
      throw AuthServiceException('Création du compte impossible pour le moment. Réessayez dans quelques instants.', e.toString());
    }
  }

  static String readableError(Object error) {
    if (error is AuthServiceException) return error.message;
    if (error is AuthException) return AuthServiceException.fromAuthException(error).message;
    return 'Une erreur inattendue est survenue. Réessayez.';
  }
}

class AuthServiceException implements Exception {
  final String message;
  final String code;

  const AuthServiceException(this.message, this.code);

  factory AuthServiceException.fromAuthException(AuthException e) {
    final code = e.code.toLowerCase();
    final raw = e.message.toLowerCase();

    if (code.contains('sms') || raw.contains('sms') || raw.contains('phone provider')) {
      return const AuthServiceException(
        'Le service SMS de vérification n’est pas encore configuré sur le serveur. La création par téléphone ne peut pas être finalisée tant que ce service n’est pas activé.',
        'sms_provider',
      );
    }
    if (code.contains('rate') || raw.contains('rate limit') || raw.contains('too many')) {
      return const AuthServiceException(
        'Trop de tentatives. Attendez quelques instants avant de demander un nouveau code.',
        'rate_limit',
      );
    }
    if (code.contains('invalid') && (raw.contains('phone') || raw.contains('number'))) {
      return const AuthServiceException(
        'Le numéro de téléphone n’est pas accepté. Utilisez un numéro ivoirien au format 07/05/01 suivi de 8 chiffres.',
        'invalid_phone',
      );
    }
    if (raw.contains('password')) {
      return const AuthServiceException(
        'Le mot de passe est incorrect ou ne respecte pas les règles requises.',
        'password',
      );
    }
    if (raw.contains('already registered') || raw.contains('already exists')) {
      return const AuthServiceException(
        'Ce numéro est déjà associé à un compte. Utilisez « Se connecter ».',
        'already_registered',
      );
    }
    return AuthServiceException(
      'Opération refusée par le serveur. Réessayez ou vérifiez les informations saisies.',
      e.code.isEmpty ? 'auth_error' : e.code,
    );
  }

  @override
  String toString() => message;
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

  Future<AuthMFAEnrollResponse> enrollTotp({String? friendlyName}) {
    return _client.auth.mfa.enroll(
      factorType: FactorType.totp,
      friendlyName: friendlyName,
      issuer: 'BIIC CHAT',
    );
  }

  Future<AuthMFAVerifyResponse> verifyTotp({required String factorId, required String code}) async {
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
