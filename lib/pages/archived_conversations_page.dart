import 'package:flutter/material.dart';

import '../services/conversation_service.dart';
import 'chat_page.dart';

class ArchivedConversationsPage extends StatefulWidget {
  const ArchivedConversationsPage({super.key});

  @override
  State<ArchivedConversationsPage> createState() => _ArchivedConversationsPageState();
}

class _ArchivedConversationsPageState extends State<ArchivedConversationsPage> {
  final _service = ConversationService();
  late Future<List<Map<String, dynamic>>> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<List<Map<String, dynamic>>> _load() async {
    final archived = await _service.getArchivedConversations();
    final result = <Map<String, dynamic>>[];
    for (final row in archived) {
      final id = row['conversation_id']?.toString();
      if (id == null || id.isEmpty) continue;
      final conversation = await _service.client
          .from('conversations')
          .select('id,name,is_group')
          .eq('id', id)
          .maybeSingle();
      if (conversation == null) continue;
      final members = await _service.getConversationMembers(id);
      final me = _service.client.auth.currentUser?.id;
      final names = members
          .where((member) => member['user_id'] != me)
          .map((member) => (member['display_name'] as String? ?? '').trim())
          .where((name) => name.isNotEmpty)
          .toList();
      final savedName = (conversation['name'] as String? ?? '').trim();
      result.add({
        ...Map<String, dynamic>.from(conversation),
        'conversation_id': id,
        'archived_at': row['archived_at'],
        'display_title': savedName.isNotEmpty
            ? savedName
            : (names.isNotEmpty ? names.join(', ') : 'Discussion'),
      });
    }
    return result;
  }

  Future<void> _unarchive(String id) async {
    try {
      await _service.unarchiveConversation(id);
      if (!mounted) return;
      setState(() => _future = _load());
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Discussion restaurée dans la liste principale.')),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Impossible de restaurer la discussion : $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Discussions archivées')),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text('Impossible de charger les archives : ${snapshot.error}'),
              ),
            );
          }
          final items = snapshot.data ?? const [];
          if (items.isEmpty) {
            return const Center(child: Text('Aucune discussion archivée.'));
          }
          return RefreshIndicator(
            onRefresh: () async => setState(() => _future = _load()),
            child: ListView.separated(
              itemCount: items.length,
              separatorBuilder: (_, __) => const Divider(height: 1, indent: 72),
              itemBuilder: (context, index) {
                final item = items[index];
                final id = item['conversation_id'] as String;
                final title = item['display_title'] as String;
                return ListTile(
                  leading: CircleAvatar(child: Icon(item['is_group'] == true ? Icons.groups_outlined : Icons.person_outline)),
                  title: Text(title),
                  subtitle: Text(item['is_group'] == true ? 'Groupe archivé' : 'Discussion privée archivée'),
                  trailing: IconButton(
                    tooltip: 'Désarchiver',
                    icon: const Icon(Icons.unarchive_outlined),
                    onPressed: () => _unarchive(id),
                  ),
                  onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(
                    builder: (_) => ChatPage(conversationId: id, title: title),
                  )),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
