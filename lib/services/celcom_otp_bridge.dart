import 'dart:convert';

import 'package:supabase_flutter/supabase_flutter.dart';

class CelcomOtpBridgeService {
  final SupabaseClient supabase;

  const CelcomOtpBridgeService({required this.supabase});

  Future<AuthResponse> beginSignupWithOtp({
    required String phone,
    required String password,
    required String displayName,
  }) async {
    return supabase.auth.signUp(
      phone: phone.trim(),
      password: password,
      channel: OtpChannel.sms,
      data: {'display_name': displayName.trim()},
    );
  }

  Future<AuthResponse> verifySignupCode({
    required String phone,
    required String token,
  }) async {
    return supabase.auth.verifyOTP(
      type: OtpType.signup,
      phone: phone.trim(),
      token: token.trim(),
    );
  }

  Future<AuthResponse> verifyResetCode({
    required String phone,
    required String token,
  }) async {
    return supabase.auth.verifyOTP(
      type: OtpType.sms,
      phone: phone.trim(),
      token: token.trim(),
    );
  }

  String normalizePhone(String value) {
    final raw = value.trim().replaceAll(RegExp(r'[\s\-]'), '');
    if (raw.isEmpty) {
      throw const FormatException('Phone number is empty');
    }
    if (raw.startsWith('+')) return raw;
    if (raw.startsWith('00')) return '+${raw.substring(2)}';
    if (raw.startsWith('0')) return '+225${raw.substring(1)}';
    return '+225$raw';
  }

  Map<String, dynamic> buildCelcomPayload({
    required String phone,
    required String otp,
    String sender = 'BIIC',
  }) {
    return {
      'phone': normalizePhone(phone),
      'otp': otp,
      'provider': 'celcom',
      'sender': sender,
      'message': 'Votre code BIIC CHAT est : $otp. Valable 10 minutes.',
      'timestamp': DateTime.now().toUtc().toIso8601String(),
    };
  }
}
