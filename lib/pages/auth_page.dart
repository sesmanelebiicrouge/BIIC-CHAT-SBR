import 'package:flutter/material.dart';

import '../services/auth_service.dart';

class AuthPage extends StatefulWidget {
  const AuthPage({super.key});

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _name = TextEditingController();
  final _auth = AuthService();
  bool _register = false;
  bool _loading = false;

  Future<void> _submit() async {
    if (_email.text.trim().isEmpty ||
        _password.text.isEmpty ||
        (_register && _name.text.trim().isEmpty)) {
      return;
    }

    setState(() => _loading = true);
    try {
      if (_register) {
        await _auth.signUp(
          email: _email.text,
          password: _password.text,
          displayName: _name.text,
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Compte créé. Vérifiez votre e-mail si nécessaire.'),
            ),
          );
        }
      } else {
        await _auth.signIn(email: _email.text, password: _password.text);
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error.toString())),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Column(
              children: [
                const Icon(Icons.chat_bubble_rounded, size: 72),
                const SizedBox(height: 16),
                Text(
                  'BIIC CHAT',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 24),
                if (_register)
                  TextField(
                    controller: _name,
                    decoration: const InputDecoration(
                      labelText: 'Nom affiché',
                      border: OutlineInputBorder(),
                    ),
                  ),
                if (_register) const SizedBox(height: 12),
                TextField(
                  controller: _email,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'E-mail',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _password,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Mot de passe',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: _loading ? null : _submit,
                    child: Text(
                      _loading
                          ? 'Chargement...'
                          : (_register ? 'Créer mon compte' : 'Se connecter'),
                    ),
                  ),
                ),
                TextButton(
                  onPressed: _loading
                      ? null
                      : () => setState(() => _register = !_register),
                  child: Text(
                    _register
                        ? 'J’ai déjà un compte'
                        : 'Créer un compte',
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    _name.dispose();
    super.dispose();
  }
}
