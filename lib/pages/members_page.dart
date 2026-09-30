import 'package:flutter/material.dart';
import '../services/members_service.dart';

class MembersPage extends StatefulWidget {
  const MembersPage({super.key});
  @override State<MembersPage> createState() => _MembersPageState();
}

class _MembersPageState extends State<MembersPage> {
  final _service = MembersService();
  late Future<List<Map<String, dynamic>>> _future;
  @override void initState() { super.initState(); _future = _service.getMembers(); }
  void _reload() => setState(() => _future = _service.getMembers());
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
          return ListView.separated(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: members.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final member = members[index];
              final name = (member['display_name'] as String?)?.trim();
              final email = member['email'] as String? ?? '';
              final status = member['status'] as String? ?? 'offline';
              final label = name?.isNotEmpty == true ? name! : email;
              return ListTile(leading: CircleAvatar(child: Text((label.isNotEmpty ? label.substring(0, 1) : '?').toUpperCase())), title: Text(label), subtitle: Text(email + ' • ' + status));
            },
          );
        },
      ),
    );
  }
}