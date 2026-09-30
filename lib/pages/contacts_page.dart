import 'package:flutter/material.dart';
import '../services/contacts_service.dart';
import '../services/conversation_service.dart';
import 'chat_page.dart';

class ContactsPage extends StatefulWidget {
  const ContactsPage({super.key});
  @override
  State<ContactsPage> createState() => _ContactsPageState();
}

class _ContactsPageState extends State<ContactsPage> {
  final _contacts = ContactsService();
  final _conversations = ConversationService();
  List<ImportedContact> _items = const [];
  bool _loading = false;

  Future<void> _import() async {
    setState(() => _loading = true);
    try {
      final items = await _contacts.importDeviceContacts();
      if (!mounted) return;
      setState(() => _items = items);
      final available = items.where((item) => item.isOnBiicChat).length;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '$available contact(s) utilisent déjà BIIC CHAT.',
          ),
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
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
      appBar: AppBar(title: const Text('Contacts BIIC CHAT')),
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
                      'Importez vos contacts pour identifier ceux qui ont déjà un compte et ouvrir directement une discussion.',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),
                    FilledButton.icon(
                      onPressed: _import,
                      icon: const Icon(Icons.sync),
                      label: const Text('Importer mes contacts'),
                    ),
                  ],
                ),
              ),
            )
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                  child: FilledButton.icon(
                    onPressed: _loading ? null : _import,
                    icon: _loading
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.sync),
                    label: Text(_loading
                        ? 'Importation...'
                        : 'Actualiser mes contacts'),
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
                          trailing: const Icon(Icons.person_add_outlined),
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
