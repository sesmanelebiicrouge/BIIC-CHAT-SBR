import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  SupabaseClient get _client => Supabase.instance.client;

  Session? get currentSession => _client.auth.currentSession;

  Stream<AuthState> get authStateChanges => _client.auth.onAuthStateChange;

  Future<void> signIn({
    required String phone,
    required String password,
  }) async {
    try {
      await _client.auth.signInWithPassword(
        phone: phone.trim(),
        password: password,
      );
    } on AuthException catch (e) {
      throw AuthServiceException.fromAuthException(e);
    } catch (e) {
      throw const AuthServiceException(
        'Connexion au serveur impossible. Vérifiez votre connexion Internet puis réessayez.',
        'network_error',
      );
    }
  }

  Future<AuthResponse> signUp({
    required String phone,
    required String password,
    required String displayName,
  }) async {
    try {
      final response = await _client.auth.signUp(
        phone: phone.trim(),
        password: password,
        channel: OtpChannel.sms,
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
      throw const AuthServiceException(
        'Création du compte impossible pour le moment. Réessayez dans quelques instants.',
        'signup_error',
      );
    }
  }

  Future<AuthResponse> verifySignupCode({
    required String phone,
    required String token,
  }) async {
    try {
      return await _client.auth.verifyOTP(
        type: OtpType.signup,
        phone: phone.trim(),
        token: token.trim(),
      );
    } on AuthException catch (e) {
      throw AuthServiceException.fromAuthException(e);
    } catch (e) {
      throw const AuthServiceException(
        'Vérification du compte impossible pour le moment. Réessayez.',
        'verify_signup_error',
      );
    }
  }

  Future<void> resendSignupCode(String phone) async {
    try {
      await _client.auth.resend(
        type: OtpType.sms,
        phone: phone.trim(),
      );
    } on AuthException catch (e) {
      throw AuthServiceException.fromAuthException(e);
    } catch (e) {
      throw const AuthServiceException(
        'Impossible de renvoyer le code. Attendez quelques instants puis réessayez.',
        'resend_signup_error',
      );
    }
  }

  Future<void> resendPasswordResetCode(String phone) async {
    try {
      await _client.auth.signInWithOtp(
        phone: phone.trim(),
        shouldCreateUser: false,
      );
    } on AuthException catch (e) {
      throw AuthServiceException.fromAuthException(e);
    } catch (e) {
      throw const AuthServiceException(
        'Impossible de renvoyer le code de récupération. Attendez quelques instants puis réessayez.',
        'resend_reset_error',
      );
    }
  }

  Future<void> requestPasswordReset(String phone) async {
    try {
      await _client.auth.signInWithOtp(
        phone: phone.trim(),
        shouldCreateUser: false,
      );
    } on AuthException catch (e) {
      throw AuthServiceException.fromAuthException(e);
    } catch (e) {
      throw const AuthServiceException(
        'Impossible d’envoyer le code de récupération. Réessayez.',
        'reset_request_error',
      );
    }
  }

  Future<AuthResponse> verifyPasswordResetCode({
    required String phone,
    required String token,
  }) async {
    try {
      return await _client.auth.verifyOTP(
        type: OtpType.sms,
        phone: phone.trim(),
        token: token.trim(),
      );
    } on AuthException catch (e) {
      throw AuthServiceException.fromAuthException(e);
    } catch (e) {
      throw const AuthServiceException(
        'Vérification du code de récupération impossible. Réessayez.',
        'reset_verify_error',
      );
    }
  }

  Future<void> updatePassword(String password) async {
    try {
      await _client.auth.updateUser(UserAttributes(password: password));
    } on AuthException catch (e) {
      throw AuthServiceException.fromAuthException(e);
    } catch (e) {
      throw const AuthServiceException(
        'Impossible de modifier le mot de passe. Réessayez.',
        'password_update_error',
      );
    }
  }

  Future<void> changePhone(String newPhone) async {
    try {
      await _client.auth.updateUser(
        UserAttributes(phone: newPhone.trim()),
      );
    } on AuthException catch (e) {
      throw AuthServiceException.fromAuthException(e);
    } catch (e) {
      throw const AuthServiceException(
        'Impossible de modifier le numéro de téléphone. Réessayez.',
        'phone_change_error',
      );
    }
  }

  Future<AuthResponse> verifyPhoneChange({
    required String phone,
    required String token,
  }) async {
    try {
      return await _client.auth.verifyOTP(
        type: OtpType.phoneChange,
        phone: phone.trim(),
        token: token.trim(),
      );
    } on AuthException catch (e) {
      throw AuthServiceException.fromAuthException(e);
    } catch (e) {
      throw const AuthServiceException(
        'Vérification du nouveau numéro impossible. Réessayez.',
        'phone_change_verify_error',
      );
    }
  }

  Future<AuthMFAEnrollResponse> enrollTotp({String? friendlyName}) async {
    try {
      return await _client.auth.mfa.enroll(
        factorType: FactorType.totp,
        friendlyName: friendlyName,
        issuer: 'BIIC CHAT',
      );
    } on AuthException catch (e) {
      throw AuthServiceException.fromAuthException(e);
    }
  }

  Future<AuthMFAVerifyResponse> verifyTotp({
    required String factorId,
    required String code,
  }) async {
    try {
      final challenge = await _client.auth.mfa.challenge(
        factorId: factorId,
      );
      return await _client.auth.mfa.verify(
        factorId: factorId,
        challengeId: challenge.id,
        code: code.trim(),
      );
    } on AuthException catch (e) {
      throw AuthServiceException.fromAuthException(e);
    }
  }

  Future<void> deleteMyAccount() async {
    try {
      await _client.rpc('delete_my_account');
      await _client.auth.signOut();
    } on AuthException catch (e) {
      throw AuthServiceException.fromAuthException(e);
    }
  }


  Future<void> signOut() => _client.auth.signOut();

  static String readableError(Object error) {
    if (error is AuthServiceException) return error.message;
    if (error is AuthException) {
      return AuthServiceException.fromAuthException(error).message;
    }
    return 'Une erreur inattendue est survenue. Réessayez.';
  }
}

class AuthServiceException implements Exception {
  final String message;
  final String code;

  const AuthServiceException(this.message, this.code);

  factory AuthServiceException.fromAuthException(AuthException e) {
    final code = (e.code ?? '').toLowerCase();
    final raw = e.message.toLowerCase();

    if (code == 'phone_provider_disabled' ||
        raw.contains('phone signups are disabled')) {
      return const AuthServiceException(
        'La création de compte par téléphone est désactivée sur le serveur. Le service SMS doit être activé dans Supabase avant de pouvoir créer un compte avec un numéro.',
        'phone_provider_disabled',
      );
    }

    if (code.contains('sms') ||
        raw.contains('sms') ||
        raw.contains('phone provider') ||
        raw.contains('sms provider')) {
      return const AuthServiceException(
        'Le service SMS de vérification n’est pas encore configuré sur le serveur. La création par téléphone ne peut pas être finalisée tant que ce service n’est pas activé.',
        'sms_provider',
      );
    }

    if (code.contains('rate') ||
        raw.contains('rate limit') ||
        raw.contains('too many')) {
      return const AuthServiceException(
        'Trop de tentatives. Attendez quelques instants avant de demander un nouveau code.',
        'rate_limit',
      );
    }

    if (code.contains('invalid') &&
        (raw.contains('phone') || raw.contains('number'))) {
      return const AuthServiceException(
        'Le numéro de téléphone n’est pas accepté. Utilisez un numéro ivoirien au format 07/05/01 suivi de 8 chiffres.',
        'invalid_phone',
      );
    }

    if (raw.contains('invalid login credentials') ||
        raw.contains('invalid password')) {
      return const AuthServiceException(
        'Le numéro ou le mot de passe est incorrect.',
        'invalid_credentials',
      );
    }

    if (raw.contains('password')) {
      return const AuthServiceException(
        'Le mot de passe est incorrect ou ne respecte pas les règles requises.',
        'password',
      );
    }

    if (raw.contains('already registered') ||
        raw.contains('already exists') ||
        code.contains('user_already_exists')) {
      return const AuthServiceException(
        'Ce numéro est déjà associé à un compte. Utilisez « Se connecter ».',
        'already_registered',
      );
    }

    if (raw.contains('not found') || raw.contains('user not found')) {
      return const AuthServiceException(
        'Aucun compte correspondant à ce numéro n’a été trouvé.',
        'user_not_found',
      );
    }

    return AuthServiceException(
      'Opération refusée par le serveur. Réessayez ou vérifiez les informations saisies.',
      (e.code ?? '').isEmpty ? 'auth_error' : (e.code ?? 'auth_error'),
    );
  }

  @override
  String toString() => message;
}
