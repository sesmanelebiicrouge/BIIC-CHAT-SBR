import 'package:flutter/material.dart';

import '../services/call_history_service.dart';
import '../services/members_service.dart';
import '../services/conversation_service.dart';
import 'chat_page.dart';

class CallHistoryPage extends StatefulWidget {
  const CallHistoryPage({super.key, this.showAppBar = true, this.onStartCall});
  final bool showAppBar;
  final VoidCallback? onStartCall;

  @override
  State<CallHistoryPage> createState() => _CallHistoryPageState();
}

class _CallHistoryPageState extends State<CallHistoryPage> {
  final _calls = CallHistoryService();
  final _members = MembersService();
  final _conversations = ConversationService();
  late Future<List<Map<String, dynamic>>> _history;
  Map<String, String> _names = const {};
  String? _myId;

  @override
  void initState() {
    super.initState();
    _myId = _conversations.client.auth.currentUser?.id;
    _history = _calls.getHistory();
    _loadNames();
  }

  Future<void> _loadNames() async {
    try {
      final members = await _members.getMembers();
      if (!mounted) return;
      setState(() {
        _names = {
          for (final member in members)
            if (member['id'] != null && (member['display_name'] as String? ?? '').trim().isNotEmpty)
              member['id'].toString(): (member['display_name'] as String).trim(),
        };
      });
    } catch (_) {}
  }

  Future<void> _openConversation(Map<String, dynamic> call) async {
    final id = call['conversation_id'] as String?;
    if (id == null || id.isEmpty) {
      widget.onStartCall?.call();
      return;
    }
    try {
      final rows = await _conversations.getConversationMembers(id);
      final other = rows.where((row) => row['user_id'] != _myId).toList();
      final name = other
          .map((row) => (row['display_name'] as String? ?? '').trim())
          .where((value) => value.isNotEmpty)
          .join(', ');
      if (!mounted) return;
      Navigator.of(context).push(MaterialPageRoute<void>(
        builder: (_) => ChatPage(
          conversationId: id,
          title: name.isEmpty ? 'Conversation' : name,
        ),
      ));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Impossible d’ouvrir la conversation : $e')),
        );
      }
    }
  }

  String _statusLabel(String value) {
    switch (value) {
      case 'completed': return 'Terminé';
      case 'missed': return 'Manqué';
      case 'declined': return 'Refusé';
      case 'failed': return 'Échec';
      default: return 'Tentative lancée';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: widget.showAppBar ? AppBar(title: const Text('Appels')) : null,
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _history,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('Impossible de charger l’historique des appels.'),
                    const SizedBox(height: 8),
                    Text(snapshot.error.toString(), textAlign: TextAlign.center),
                    const SizedBox(height: 12),
                    OutlinedButton(
                      onPressed: () => setState(() => _history = _calls.getHistory()),
                      child: const Text('Réessayer'),
                    ),
                  ],
                ),
              ),
            );
          }
          final calls = snapshot.data ?? const [];
          if (calls.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.call_outlined, size: 56),
                    const SizedBox(height: 12),
                    const Text('Aucun appel enregistré', style: TextStyle(fontSize: 19, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 8),
                    const Text(
                      'Les tentatives d’appel lancées depuis une conversation apparaîtront ici. Les appels entrants et les notifications d’appel nécessitent encore un service de signalisation dédié.',
                      textAlign: TextAlign.center,
                    ),
                    if (widget.onStartCall != null) ...[
                      const SizedBox(height: 16),
                      FilledButton.icon(
                        onPressed: widget.onStartCall,
                        icon: const Icon(Icons.person_search_outlined),
                        label: const Text('Choisir un contact'),
                      ),
                    ],
                  ],
                ),
              ),
            );
          }
          return RefreshIndicator(
            onRefresh: () async {
              setState(() => _history = _calls.getHistory());
              await _history;
            },
            child: ListView.separated(
              itemCount: calls.length,
              separatorBuilder: (_, __) => const Divider(height: 1, indent: 72),
              itemBuilder: (context, index) {
                final call = calls[index];
                final callerId = call['caller_id']?.toString() ?? '';
                final calleeId = call['callee_id']?.toString() ?? '';
                final otherId = callerId == _myId ? calleeId : callerId;
                final outgoing = callerId == _myId;
                final type = call['call_type'] == 'video' ? 'Vidéo' : 'Audio';
                final name = _names[otherId] ?? 'Utilisateur BIIC CHAT';
                final date = DateTime.tryParse(call['started_at']?.toString() ?? '')?.toLocal();
                return ListTile(
                  leading: CircleAvatar(
                    child: Icon(call['call_type'] == 'video' ? Icons.videocam_outlined : Icons.call_outlined),
                  ),
                  title: Text(name, style: const TextStyle(fontWeight: FontWeight.w700)),
                  subtitle: Text('$type • ${outgoing ? 'Sortant' : 'Entrant'} • ${_statusLabel(call['status']?.toString() ?? '')}${date == null ? '' : ' • ${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}'}'),
                  trailing: IconButton(
                    tooltip: 'Ouvrir la conversation',
                    icon: const Icon(Icons.call),
                    onPressed: () => _openConversation(call),
                  ),
                  onTap: () => _openConversation(call),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
