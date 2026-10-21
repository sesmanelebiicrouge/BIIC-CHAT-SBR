import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '../services/contacts_service.dart';
import '../services/conversation_service.dart';
import 'package:url_launcher/url_launcher.dart';
import 'chat_page.dart';
import 'members_page.dart';

class ContactsPage extends StatefulWidget {
  const ContactsPage({super.key, this.showAppBar = true});

  final bool showAppBar;
  @override
  State<ContactsPage> createState() => _ContactsPageState();
}

class _ContactsPageState extends State<ContactsPage> {
  final _contacts = ContactsService();
  final _conversations = ConversationService();
  List<ImportedContact> _items = const [];
  bool _loading = false;

  Future<void> _import() async {
    // On the Web, the browser's own contact picker is the consent step. It
    // must open directly from the tap, without an earlier asynchronous dialog.
    if (!kIsWeb) {
      final consent = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Autoriser l’accès aux contacts ?'),
          content: const Text(
            'BIIC CHAT peut lire les noms et numéros de votre répertoire pour repérer les personnes inscrites et vous permettre de démarrer une discussion. Les contacts ne sont importés qu’après votre accord et l’autorisation du système. Vous pouvez refuser et continuer à rechercher des membres manuellement.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Pas maintenant'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Continuer'),
            ),
          ],
        ),
      );
      if (consent != true || !mounted) return;
    }

    setState(() => _loading = true);
    try {
      final items = await _contacts.importDeviceContacts();
      if (!mounted) return;
      setState(() => _items = items);
      final available = items.where((item) => item.isOnBiicChat).length;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$available contact(s) utilisent déjà BIIC CHAT.'),
        ),
      );
    } catch (e) {
      if (mounted) {
        final message = e.toString().replaceFirst('Unsupported operation: ', '');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message)),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _inviteContact(ImportedContact contact) async {
    final phone = contact.phone.trim();
    if (phone.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ce contact ne possède pas de numéro utilisable.')),
        );
      }
      return;
    }

    final invite = Uri(
      scheme: 'sms',
      path: phone,
      queryParameters: {
        'body': 'Salut ! Rejoins-moi sur BIIC CHAT pour discuter et partager des médias : '
            'https://sesmanelebiicrouge.github.io/BIIC-CHAT-SBR/',
      },
    );
    try {
      final opened = await launchUrl(
        invite,
        mode: LaunchMode.externalApplication,
      );
      if (!opened && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Impossible d’ouvrir l’application SMS.')),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Impossible de préparer l’invitation SMS.')),
        );
      }
    }
  }

  Future<void> _openChat(ImportedContact contact) async {
    final otherId = contact.matchedUserId;
    final me = _conversations.client.auth.currentUser;
    if (otherId == null || me == null) return;

    try {
      final id = await _conversations.getOrCreateDirectConversation(
        currentUserId: me.id,
        otherUserId: otherId,
        otherName: contact.matchedDisplayName ??
            (contact.displayName.isEmpty
                ? 'Contact BIIC CHAT'
                : contact.displayName),
      );
      if (!mounted) return;
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => ChatPage(
            conversationId: id,
            title: contact.matchedDisplayName ??
                (contact.displayName.isEmpty
                    ? 'Contact BIIC CHAT'
                    : contact.displayName),
          ),
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Discussion impossible : $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final available = _items.where((item) => item.isOnBiicChat).toList();
    final notAvailable = _items.where((item) => !item.isOnBiicChat).toList();

    return Scaffold(
      appBar: widget.showAppBar ? AppBar(title: const Text('Contacts BIIC CHAT')) : null,
      body: _items.isEmpty && !_loading
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.contacts_outlined, size: 64),
                    const SizedBox(height: 16),
                    const Text(
                      'Retrouvez vos contacts sur BIIC CHAT',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Choisissez les contacts de votre répertoire pour identifier ceux qui ont déjà un compte et ouvrir directement une discussion.',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),
                    FilledButton.icon(
                      onPressed: _loading ? null : _import,
                      icon: const Icon(Icons.contacts_outlined),
                      label: Text(
                        kIsWeb ? 'Choisir dans le répertoire' : 'Importer mes contacts',
                      ),
                    ),
                    const SizedBox(height: 8),
                    OutlinedButton.icon(
                      onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => const MembersPage(),
                        ),
                      ),
                      icon: const Icon(Icons.search),
                      label: const Text('Rechercher par nom ou numéro'),
                    ),
                  ],
                ),
              ),
            )
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: _loading ? null : _import,
                          icon: _loading
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Icon(Icons.contacts_outlined),
                          label: Text(
                            _loading
                                ? 'Importation...'
                                : (kIsWeb ? 'Choisir les contacts' : 'Actualiser'),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) => const MembersPage(),
                            ),
                          ),
                          icon: const Icon(Icons.search),
                          label: const Text('Rechercher'),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView(
                    children: [
                      if (available.isNotEmpty) ...[
                        const ListTile(
                          title: Text(
                            'Sur BIIC CHAT',
                            style: TextStyle(fontWeight: FontWeight.w800),
                          ),
                        ),
                        ...available.map(
                          (contact) => ListTile(
                            leading: CircleAvatar(
                              child: Text(
                                ((contact.matchedDisplayName ??
                                            contact.displayName)
                                        .trim()
                                        .isEmpty
                                    ? 'B'
                                    : (contact.matchedDisplayName ??
                                            contact.displayName)
                                        .trim()[0])
                                    .toUpperCase(),
                              ),
                            ),
                            title: Text(
                              contact.matchedDisplayName ??
                                  (contact.displayName.isEmpty
                                      ? 'Utilisateur BIIC CHAT'
                                      : contact.displayName),
                            ),
                            subtitle: Text(
                              contact.matchedStatus == null
                                  ? 'Disponible sur BIIC CHAT'
                                  : contact.matchedStatus!,
                            ),
                            trailing: const Icon(Icons.chat_bubble_outline),
                            onTap: () => _openChat(contact),
                          ),
                        ),
                      ],
                      if (notAvailable.isNotEmpty)
                        const ListTile(
                          title: Text(
                            'Inviter sur BIIC CHAT',
                            style: TextStyle(fontWeight: FontWeight.w800),
                          ),
                        ),
                      ...notAvailable.map(
                        (contact) => ListTile(
                          leading: const CircleAvatar(
                            child: Icon(Icons.person_outline),
                          ),
                          title: Text(
                            contact.displayName.isEmpty
                                ? 'Contact'
                                : contact.displayName,
                          ),
                          subtitle: Text(contact.phone),
                          trailing: IconButton(
                            tooltip: 'Inviter par SMS',
                            icon: const Icon(Icons.person_add_outlined),
                            onPressed: () => _inviteContact(contact),
                          ),
                          onTap: () => _inviteContact(contact),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}
