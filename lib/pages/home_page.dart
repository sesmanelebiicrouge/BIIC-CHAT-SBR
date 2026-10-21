import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/conversation_service.dart';
import '../widgets/biic_brand.dart';
import 'members_page.dart';
import 'contacts_page.dart';
import 'chat_page.dart';
import 'profile_page.dart';
import 'settings_page.dart';
import 'status_page.dart';
import 'call_history_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _tab = 0;

  void _openProfile() => Navigator.of(context).push(
        MaterialPageRoute<void>(builder: (_) => const ProfilePage()),
      );

  void _openSettings() => Navigator.of(context).push(
        MaterialPageRoute<void>(builder: (_) => const SettingsPage()),
      );

  void _newChat() => Navigator.of(context).push(
        MaterialPageRoute<void>(builder: (_) => const MembersPage()),
      );

  @override
  Widget build(BuildContext context) {
    final service = ConversationService();
    final user = service.client.auth.currentUser;
    if (user == null) return const MembersPage();

    return Scaffold(
      appBar: AppBar(
        title: const BiicBrand(iconSize: 36, showSubtitle: false),
        actions: [
          IconButton(
            tooltip: 'Nouvelle discussion',
            onPressed: _newChat,
            icon: const Icon(Icons.edit_square),
          ),
          PopupMenuButton<String>(
            tooltip: 'Profil et paramètres',
            onSelected: (value) {
              if (value == 'profile') _openProfile();
              if (value == 'settings') _openSettings();
              if (value == 'logout') AuthService().signOut();
            },
            itemBuilder: (_) => const [
              PopupMenuItem(
                value: 'profile',
                child: ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(Icons.account_circle_outlined),
                  title: Text('Mon profil'),
                ),
              ),
              PopupMenuItem(
                value: 'settings',
                child: ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(Icons.settings_outlined),
                  title: Text('Paramètres'),
                ),
              ),
              PopupMenuDivider(),
              PopupMenuItem(
                value: 'logout',
                child: ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(Icons.logout),
                  title: Text('Déconnexion'),
                ),
              ),
            ],
          ),
        ],
      ),
      body: IndexedStack(
        index: _tab,
        children: [
          _ConversationsTab(service: service, userId: user.id, onNewChat: _newChat, onContacts: () => setState(() => _tab = 3)),
          const StatusPage(showAppBar: false),
          CallHistoryPage(showAppBar: false, onStartCall: _newChat),
          const ContactsPage(showAppBar: false),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tab,
        onDestinationSelected: (index) => setState(() => _tab = index),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.chat_bubble_outline),
            selectedIcon: Icon(Icons.chat_bubble),
            label: 'Discussions',
          ),
          NavigationDestination(
            icon: Icon(Icons.donut_large_outlined),
            selectedIcon: Icon(Icons.donut_large),
            label: 'Statuts',
          ),
          NavigationDestination(
            icon: Icon(Icons.call_outlined),
            selectedIcon: Icon(Icons.call),
            label: 'Appels',
          ),
          NavigationDestination(
            icon: Icon(Icons.contacts_outlined),
            selectedIcon: Icon(Icons.contacts),
            label: 'Contacts',
          ),
        ],
      ),
    );
  }
}

class _ConversationsTab extends StatelessWidget {
  const _ConversationsTab({
    required this.service,
    required this.userId,
    required this.onNewChat,
    required this.onContacts,
  });

  final ConversationService service;
  final String userId;
  final VoidCallback onNewChat;
  final VoidCallback onContacts;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: service.getUserConversations(userId),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text('Impossible de charger les discussions : ${snapshot.error}'),
            ),
          );
        }
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final conversations = snapshot.data!;
        if (conversations.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const BiicAvatar(label: 'B', radius: 38),
                  const SizedBox(height: 16),
                  const Text(
                    'Aucune discussion',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 7),
                  const Text(
                    'Démarrez une discussion avec un membre de BIIC CHAT ou recherchez une personne dans vos contacts.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Color(0xFF777777)),
                  ),
                  const SizedBox(height: 18),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    alignment: WrapAlignment.center,
                    children: [
                      FilledButton.icon(
                        onPressed: onNewChat,
                        icon: const Icon(Icons.chat_rounded),
                        label: const Text('Nouvelle discussion'),
                      ),
                      OutlinedButton.icon(
                        onPressed: onContacts,
                        icon: const Icon(Icons.contacts_outlined),
                        label: const Text('Mes contacts'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.only(top: 8, bottom: 12),
          itemCount: conversations.length,
          separatorBuilder: (_, __) => const Divider(height: 1, indent: 78),
          itemBuilder: (context, index) {
            final conversation = conversations[index];
            return FutureBuilder<List<Map<String, dynamic>>>(
              future: service.getConversationMembers(conversation['id'] as String),
              builder: (context, membersSnapshot) {
                final members = membersSnapshot.data ?? const [];
                final names = members
                    .where((row) => row['user_id'] != userId)
                    .map((row) => (row['display_name'] as String? ?? '').trim())
                    .where((name) => name.isNotEmpty)
                    .toList();
                final storedName = (conversation['name'] as String? ?? '').trim();
                final title = storedName.isNotEmpty
                    ? storedName
                    : (names.isNotEmpty ? names.join(', ') : 'Discussion');
                return ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
                  leading: BiicAvatar(label: title, radius: 27),
                  title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
                  subtitle: Text(conversation['is_group'] == true ? 'Groupe' : 'Discussion privée'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => ChatPage(
                        conversationId: conversation['id'] as String,
                        title: title,
                      ),
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}

