import 'package:flutter/material.dart';
import '../services/phone_registration_service.dart';

class PhoneRegistrationPage extends StatefulWidget {
  const PhoneRegistrationPage({super.key});

  @override
  State<PhoneRegistrationPage> createState() => _PhoneRegistrationPageState();
}

class _PhoneRegistrationPageState extends State<PhoneRegistrationPage> {
  final service = PhoneRegistrationService();
  final phone = TextEditingController();
  final email = TextEditingController();
  final code = TextEditingController();

  bool sent = false;
  bool busy = false;
  bool loadingStatus = true;
  String? status;
  String? registeredEmail;

  @override
  void initState() {
    super.initState();
    _loadStatus();
  }

  void message(String text) => ScaffoldMessenger.of(context)
      .showSnackBar(SnackBar(content: Text(text)));

  Future<void> _loadStatus() async {
    try {
      final row = await service.getStatus();
      if (!mounted) return;
      final savedEmail = (row['registration_email'] as String?)?.trim();
      final savedPhone = (row['registered_phone'] as String?)?.trim();
      setState(() {
        registeredEmail = savedEmail == null || savedEmail.isEmpty
            ? null
            : savedEmail;
        if (phone.text.trim().isEmpty && savedPhone != null) {
          phone.text = savedPhone;
        }
        if (row['phone_verified_at'] != null && savedPhone != null) {
          status = savedPhone;
        }
        loadingStatus = false;
      });
    } catch (_) {
      if (mounted) setState(() => loadingStatus = false);
    }
  }

  String _maskEmail(String value) {
    final parts = value.split('@');
    if (parts.length != 2) return 'adresse e-mail enregistrée';
    final local = parts.first;
    final visible = local.isEmpty ? '' : local.substring(0, 1);
    return '${visible}***@${parts.last}';
  }

  Future<void> request() async {
    final phoneValue = phone.text.trim();
    final emailValue = email.text.trim().toLowerCase();
    if (phoneValue.isEmpty) {
      message('Saisissez le numéro à enregistrer.');
      return;
    }
    if (registeredEmail == null &&
        !RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(emailValue)) {
      message('Saisissez une adresse e-mail valide.');
      return;
    }

    setState(() => busy = true);
    try {
      final hint = await service.requestCode(
        phoneValue,
        email: registeredEmail == null ? emailValue : null,
      );
      if (!mounted) return;
      setState(() => sent = true);
      message(hint == null
          ? 'Code envoyé à votre e-mail enregistré.'
          : 'Code envoyé à $hint.');
    } catch (e) {
      message(e.toString());
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> verify() async {
    setState(() => busy = true);
    try {
      await service.verifyCode(code.text);
      final row = await service.getStatus();
      if (!mounted) return;
      final savedEmail = (row['registration_email'] as String?)?.trim();
      setState(() {
        status = row['registered_phone'] as String? ?? phone.text.trim();
        registeredEmail =
            savedEmail == null || savedEmail.isEmpty ? registeredEmail : savedEmail;
        sent = false;
      });
      message('Numéro validé. Vous pouvez maintenant être trouvé sur BIIC CHAT.');
    } catch (e) {
      message(e.toString());
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Enregistrer mon numéro')),
        body: loadingStatus
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  const Text(
                    'Le code de validation est envoyé à l’adresse e-mail associée à votre compte. '
                    'Pour les anciens comptes sans e-mail enregistré, vous pouvez en ajouter un ici; '
                    'il ne sera enregistré qu’après validation du code.',
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: phone,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(
                      labelText: 'Numéro de téléphone',
                      hintText: '+225 07 00 00 00 00',
                    ),
                  ),
                  if (registeredEmail == null) ...[
                    const SizedBox(height: 12),
                    TextField(
                      controller: email,
                      keyboardType: TextInputType.emailAddress,
                      autocorrect: false,
                      autofillHints: const [AutofillHints.email],
                      decoration: const InputDecoration(
                        labelText: 'Adresse e-mail à enregistrer',
                        hintText: 'vous@exemple.com',
                      ),
                    ),
                  ] else ...[
                    const SizedBox(height: 12),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.email_outlined),
                      title: const Text('E-mail enregistré'),
                      subtitle: Text(_maskEmail(registeredEmail!)),
                    ),
                  ],
                  if (status != null) ...[
                    const SizedBox(height: 8),
                    Text('Numéro actuellement validé : $status'),
                  ],
                  if (sent) ...[
                    const SizedBox(height: 12),
                    TextField(
                      controller: code,
                      keyboardType: TextInputType.number,
                      maxLength: 6,
                      textAlign: TextAlign.center,
                      decoration: const InputDecoration(
                        labelText: 'Code reçu par e-mail',
                      ),
                    ),
                  ],
                  const SizedBox(height: 12),
                  FilledButton(
                    onPressed: busy ? null : (sent ? verify : request),
                    child: Text(busy
                        ? 'Chargement...'
                        : sent
                            ? 'Valider le code'
                            : 'Recevoir le code par e-mail'),
                  ),
                ],
              ),
      );

  @override
  void dispose() {
    phone.dispose();
    email.dispose();
    code.dispose();
    super.dispose();
  }
}
