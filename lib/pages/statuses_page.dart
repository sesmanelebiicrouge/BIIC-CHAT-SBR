import 'package:flutter/material.dart';
import '../services/user_status_service.dart';

class StatusesPage extends StatefulWidget {
  const StatusesPage({super.key});
  @override
  State<StatusesPage> createState() => _StatusesPageState();
}

class _StatusesPageState extends State<StatusesPage> {
  final _service = UserStatusService();
  final _controller = TextEditingController();
  late Future<List<Map<String, dynamic>>> _statuses;
  bool _publishing = false;

  @override
  void initState() {
    super.initState();
    _statuses = _service.getActiveStatuses();
  }

  void _refresh() => setState(() => _statuses = _service.getActiveStatuses());

  Future<void> _publish() async {
    final content = _controller.text.trim();
    if (content.isEmpty || _publishing) return;
    setState(() => _publishing = true);
    try {
      await _service.publish(content);
      _controller.clear();
      if (!mounted) return;
      _refresh();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Statut publié pour 24 heures.')),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Publication impossible : $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _publishing = false);
    }
  }

  String _age(dynamic value) {
    final date = DateTime.tryParse(value?.toString() ?? '')?.toLocal();
    if (date == null) return '';
    final difference = DateTime.now().difference(date);
    if (difference.inMinutes < 1) return 'À l’instant';
    if (difference.inHours < 1) return 'Il y a ${difference.inMinutes} min';
    return 'Il y a ${difference.inHours} h';
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Statuts — 24 heures'),
      actions: [IconButton(onPressed: _refresh, tooltip: 'Actualiser', icon: const Icon(Icons.refresh))],
    ),
    body: ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text('Partager une pensée', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
        const SizedBox(height: 10),
        TextField(
          controller: _controller,
          maxLength: 500,
          maxLines: 3,
          decoration: const InputDecoration(
            hintText: 'Quoi de neuf ? Ce statut disparaîtra après 24 heures.',
            border: OutlineInputBorder(),
          ),
        ),
        Align(
          alignment: Alignment.centerRight,
          child: FilledButton.icon(
            onPressed: _publishing ? null : _publish,
            icon: _publishing
                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.send),
            label: const Text('Publier'),
          ),
        ),
        const Divider(height: 32),
        const Text('Statuts récents', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
        const SizedBox(height: 8),
        FutureBuilder<List<Map<String, dynamic>>>(
          future: _statuses,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Padding(padding: EdgeInsets.all(24), child: Center(child: CircularProgressIndicator()));
            }
            if (snapshot.hasError) {
              return Text('Impossible de charger les statuts. Vérifiez que la migration user_statuses est appliquée. Détail : ${snapshot.error}');
            }
            final items = snapshot.data ?? const [];
            if (items.isEmpty) return const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Text('Aucun statut actif pour le moment.'),
            );
            return Column(
              children: items.map((item) {
                final profile = item['users'] as Map<String, dynamic>? ?? const {};
                final name = (profile['display_name'] as String?)?.trim();
                final content = item['content'] as String? ?? '';
                final isMine = item['user_id'] == _service.currentUserId;
                return Card(
                  child: ListTile(
                    leading: CircleAvatar(child: Text((name?.isNotEmpty == true ? name![0] : 'B').toUpperCase())),
                    title: Text(name?.isNotEmpty == true ? name! : 'Membre BIIC CHAT'),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 4),
                        Text(content),
                        const SizedBox(height: 5),
                        Text(_age(item['created_at']), style: Theme.of(context).textTheme.bodySmall),
                      ],
                    ),
                    isThreeLine: true,
                    trailing: isMine ? IconButton(
                      tooltip: 'Supprimer mon statut',
                      icon: const Icon(Icons.delete_outline),
                      onPressed: () async {
                        try {
                          await _service.delete(item['id'] as String);
                          if (mounted) _refresh();
                        } catch (e) {
                          if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Suppression impossible : $e')));
                        }
                      },
                    ) : null,
                  ),
                );
              }).toList(),
            );
          },
        ),
      ],
    ),
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
