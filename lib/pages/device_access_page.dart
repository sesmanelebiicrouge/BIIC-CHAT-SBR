import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart' as ph;

class DeviceAccessPage extends StatefulWidget {
  const DeviceAccessPage({super.key});

  @override
  State<DeviceAccessPage> createState() => _DeviceAccessPageState();
}

class _DeviceAccessPageState extends State<DeviceAccessPage> {
  bool _busy = false;

  Future<void> _manage({
    required ph.Permission permission,
    required String title,
    required String purpose,
  }) async {
    if (kIsWeb) {
      _message('$title dépend des capacités du navigateur et n’utilise pas les autorisations natives du téléphone.');
      return;
    }
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Autoriser $title ?'),
        content: Text('$purpose\n\nBIIC CHAT ne demandera cette autorisation que lorsque vous choisissez cette fonction. Vous pouvez refuser et continuer à utiliser le reste de l’application.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Continuer'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _busy = true);
    try {
      final current = await permission.status;
      if (current.isPermanentlyDenied || current.isRestricted) {
        final open = await showDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: const Text('Autorisation dans les paramètres'),
            content: Text('$title est actuellement bloqué. Ouvrez les paramètres du téléphone pour l’activer si vous souhaitez utiliser cette fonction.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: const Text('Plus tard'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(dialogContext, true),
                child: const Text('Ouvrir les paramètres'),
              ),
            ],
          ),
        );
        if (open == true) await ph.openAppSettings();
      } else if (current.isGranted || current.isLimited) {
        _message('L’accès à $title est déjà autorisé.');
      } else {
        final result = await permission.request();
        if (result.isGranted || result.isLimited) {
          _message('Accès à $title autorisé.');
        } else {
          _message('Accès à $title refusé. Vous pourrez réessayer plus tard.');
        }
      }
    } catch (e) {
      _message('Impossible de vérifier cette autorisation : $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _message(String value) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(value)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Autorisations du téléphone')),
      body: ListView(
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 18, 16, 8),
            child: Text(
              'BIIC CHAT demande chaque autorisation au moment où elle est utile. Aucun accès n’est nécessaire pour continuer à utiliser les autres fonctions.',
              style: TextStyle(height: 1.45),
            ),
          ),
          if (_busy) const LinearProgressIndicator(),
          ListTile(
            leading: const Icon(Icons.contacts_outlined),
            title: const Text('Contacts du répertoire'),
            subtitle: const Text('Rechercher les personnes inscrites et démarrer une discussion.'),
            trailing: const Icon(Icons.chevron_right),
            onTap: _busy ? null : () => _manage(
              permission: ph.Permission.contacts,
              title: 'les contacts',
              purpose: 'Lire les noms et numéros de votre répertoire uniquement pour vous aider à trouver vos contacts sur BIIC CHAT.',
            ),
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.camera_alt_outlined),
            title: const Text('Caméra'),
            subtitle: const Text('Prendre une photo pour le profil ou une conversation.'),
            trailing: const Icon(Icons.chevron_right),
            onTap: _busy ? null : () => _manage(
              permission: ph.Permission.camera,
              title: 'la caméra',
              purpose: 'Utiliser la caméra uniquement lorsque vous choisissez de prendre une photo.',
            ),
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.mic_none_outlined),
            title: const Text('Microphone'),
            subtitle: const Text('Enregistrer des messages vocaux et participer aux appels compatibles.'),
            trailing: const Icon(Icons.chevron_right),
            onTap: _busy ? null : () => _manage(
              permission: ph.Permission.microphone,
              title: 'le microphone',
              purpose: 'Le microphone est utilisé uniquement lorsque vous lancez un enregistrement ou un appel qui le nécessite.',
            ),
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.location_on_outlined),
            title: const Text('Localisation'),
            subtitle: const Text('Partager votre position ponctuellement dans une discussion.'),
            trailing: const Icon(Icons.chevron_right),
            onTap: _busy ? null : () => _manage(
              permission: ph.Permission.locationWhenInUse,
              title: 'la localisation',
              purpose: 'La position n’est obtenue que lorsque vous choisissez explicitement de la partager. BIIC CHAT ne suit pas votre position en arrière-plan.',
            ),
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.notifications_outlined),
            title: const Text('Notifications'),
            subtitle: const Text('Autoriser les notifications prises en charge par la version installée.'),
            trailing: const Icon(Icons.chevron_right),
            onTap: _busy ? null : () => _manage(
              permission: ph.Permission.notification,
              title: 'les notifications',
              purpose: 'Autoriser le système à afficher les notifications que BIIC CHAT est configuré pour envoyer.',
            ),
          ),
          const Divider(height: 1),
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'Photos et documents sont sélectionnés via les sélecteurs du système. BIIC CHAT ne demande pas un accès général à tous les fichiers. Les autorisations ne garantissent pas à elles seules que les notifications push ou les appels entrants sont configurés côté serveur.',
              style: TextStyle(color: Color(0xFF777777), height: 1.45),
            ),
          ),
        ],
      ),
    );
  }
}
