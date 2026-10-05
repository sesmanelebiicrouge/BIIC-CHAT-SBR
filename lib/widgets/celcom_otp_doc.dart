import 'package:flutter/material.dart';

class CelcomOtpDocumentation extends StatelessWidget {
  const CelcomOtpDocumentation({super.key});

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.all(16),
      child: Text(
        'Celcom SMS OTP flow: Supabase Auth keeps the user session. Celcom sends the OTP via backend or Supabase Edge Function. The app validates the OTP before creating or signing in the user.',
      ),
    );
  }
}
