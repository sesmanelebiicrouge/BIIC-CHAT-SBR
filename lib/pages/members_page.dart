import 'package:flutter/material.dart';
import '../services/members_service.dart';
import '../services/conversation_service.dart';
import 'chat_page.dart';

class MembersPage extends StatefulWidget {
  const MembersPage({super.key});
  @override State<MembersPage> createState() => _MembersPageState();
}

class _MembersPageState extends State<MembersPage> {
  final _service = MembersService();
  final _conversation = ConversationService();
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
      appBar: AppBar(title: const Text('Membres BIIC CHAT'), actions: [IconButton(onPressed: _reload, icon: const Icon(Icons.refresh))]),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
          if (snapshot.hasError) return Center(child: Padding(padding: const EdgeInsets.all(24), child: Text('Impossible de charger les membres : ' + snapshot.error.toString())));
          final members = snapshot.data ?? const [];
          if (members.isEmpty) return const Center(child: Text('Aucun membre pour le moment.'));
          final me = _conversation.client.auth.currentUser?.id;
          final visible = members.where((m) => m['id'] != me).toList();
          if (visible.isEmpty) return const Center(child: Text('Aucun autre membre pour le moment.'));
          return ListView.separated(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: visible.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final member = visible[index];
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
    );
  }
}
