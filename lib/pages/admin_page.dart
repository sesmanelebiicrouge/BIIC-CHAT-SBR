import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'config/app_config.dart';

class AdminPage extends StatelessWidget {
  const AdminPage({super.key});

  bool _isAdmin() {
    final user = Supabase.instance.client.auth.currentUser;
    return AppConfig.allowGuestAccess || user?.appMetadata['role'] == 'admin';
  }

  @override
  Widget build(BuildContext context) {
    final user = Supabase.instance.client.auth.currentUser;
    if (!_isAdmin()) {
      return Scaffold(
        appBar: AppBar(title: const Text('Administration BIIC CHAT')),
        body: const Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.lock_outline, size: 64),
                SizedBox(height: 16),
                Text('Accès administrateur requis',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
                    textAlign: TextAlign.center),
                SizedBox(height: 10),
                Text(
                  'Cette zone est réservée au compte BIIC CHAT marqué administrateur. '
                  'Aucun compte public ne peut obtenir cet accès depuis cette page.',
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Administration BIIC CHAT')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Card(
            child: ListTile(
              leading: const CircleAvatar(child: Icon(Icons.admin_panel_settings)),
              title: const Text('Mode administrateur'),
              subtitle: Text(user?.phone ?? user?.email ?? 'Compte administrateur (mode démonstration)'),
              trailing: const Icon(Icons.verified),
            ),
          ),
          const SizedBox(height: 12),
          const Text('Contrôles de pré-publication',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
          const SizedBox(height: 10),
          const _CheckTile('Authentification et OTP'),
          const _CheckTile('Profils utilisateurs'),
          const _CheckTile('Messages privés et groupes'),
          const _CheckTile('Médias et fichiers'),
          const _CheckTile('Signalements et blocages'),
          const _CheckTile('Sécurité Supabase / RLS'),
          const SizedBox(height: 18),
          const Text(
            'Cette page est volontairement protégée par app_metadata.role = admin. '
            'Le mode démonstration autorise un accès temporaire pour validation sans compte utilisateur.',
            style: TextStyle(color: Colors.black54),
          ),
        ],
      ),
    );
  }
}

class _CheckTile extends StatelessWidget {
  final String label;
  const _CheckTile(this.label);

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: const Icon(Icons.fact_check_outlined),
        title: Text(label),
        trailing: const Icon(Icons.chevron_right),
      ),
    );
  }
}
