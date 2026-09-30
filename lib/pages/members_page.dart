import 'package:flutter/material.dart';
import '../services/members_service.dart';
import '../services/conversation_service.dart';
import '../services/auth_service.dart';
import 'chat_page.dart';

class MembersPage extends StatefulWidget {
  const MembersPage({super.key});
  @override State<MembersPage> createState() => _MembersPageState();
}

class _MembersPageState extends State<MembersPage> {
  final _service = MembersService();
  final _conversation = ConversationService();
  final _search = TextEditingController();
  late Future<List<Map<String, dynamic>>> _future;

  @override void initState() { super.initState(); _future = _service.getMembers(); }
  void _reload() => setState(() => _future = _service.getMembers());

  Future<void> _openMember(Map<String, dynamic> member) async {
    final me = _conversation.client.auth.currentUser;
    final otherId = member['id'] as String?;
    if (me == null || otherId == null) return;
    try {
      final id = await _conversation.getOrCreateDirectConversation(
        currentUserId: me.id,
        otherUserId: otherId,
        otherName: member['display_name'] as String? ?? '',
      );
      if (mounted) {
        Navigator.of(context).push(MaterialPageRoute(
          builder: (_) => ChatPage(
            conversationId: id,
            title: member['display_name'] as String? ?? 'Conversation',
          ),
        ));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('BIIC CHAT'),
        actions: [
          IconButton(onPressed: _reload, icon: const Icon(Icons.refresh), tooltip: 'Actualiser'),
          IconButton(onPressed: () => AuthService().signOut(), icon: const Icon(Icons.logout), tooltip: 'Déconnexion'),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
            child: TextField(
              controller: _search,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                hintText: 'Rechercher un membre...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _search.text.isEmpty ? null : IconButton(onPressed: () { _search.clear(); setState(() {}); }, icon: const Icon(Icons.clear)),
                border: const OutlineInputBorder(),
              ),
            ),
          ),
          Expanded(
            child: FutureBuilder<List<Map<String, dynamic>>>(
              future: _future,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
                if (snapshot.hasError) return Center(child: Padding(padding: const EdgeInsets.all(24), child: Text('Impossible de charger les membres : ' + snapshot.error.toString())));
                final me = _conversation.client.auth.currentUser?.id;
                final query = _search.text.trim().toLowerCase();
                final members = (snapshot.data ?? const []).where((m) {
                  if (m['id'] == me) return false;
                  final name = (m['display_name'] as String? ?? '').toLowerCase();
                  final email = (m['email'] as String? ?? '').toLowerCase();
                  return query.isEmpty || name.contains(query) || email.contains(query);
                }).toList();
                if (members.isEmpty) return const Center(child: Text('Aucun membre correspondant.'));
                return ListView.separated(
                  itemCount: members.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final member = members[index];
                    final name = (member['display_name'] as String?)?.trim();
                    final email = member['email'] as String? ?? '';
                    final status = member['status'] as String? ?? 'offline';
                    final label = name?.isNotEmpty == true ? name! : email;
                    return ListTile(
                      leading: CircleAvatar(child: Text((label.isNotEmpty ? label.substring(0, 1) : '?').toUpperCase())),
                      title: Text(label),
                      subtitle: Text('$status • Appuyer pour discuter'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => _openMember(member),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  @override void dispose() { _search.dispose(); super.dispose(); }
}
