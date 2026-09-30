import 'package:flutter/material.dart';
import '../services/members_service.dart';
import '../services/conversation_service.dart';
import '../services/auth_service.dart';
import 'chat_page.dart';
import '../services/block_report_service.dart';

class MembersPage extends StatefulWidget {
  const MembersPage({super.key});
  @override State<MembersPage> createState() => _MembersPageState();
}

class _MembersPageState extends State<MembersPage> {
  final _service = MembersService();
  final _conversation = ConversationService();
  final _safety = BlockReportService();
  final _search = TextEditingController();
  late Future<List<Map<String, dynamic>>> _future;
  Set<String> _blockedIds = <String>{};

  @override
  void initState() {
    super.initState();
    _future = _service.getMembers();
    _loadBlocked();
  }

  Future<void> _loadBlocked() async {
    try {
      final ids = await _safety.getBlockedUserIds();
      if (mounted) setState(() => _blockedIds = ids);
    } catch (_) {}
  }

  void _reload() {
    setState(() => _future = _service.getMembers());
    _loadBlocked();
  }

  String _memberLabel(Map<String, dynamic> member) {
    final name = (member['display_name'] as String?)?.trim();
    return name?.isNotEmpty == true ? name! : 'Utilisateur';
  }

  Future<void> _createGroup() async {
    final me = _conversation.client.auth.currentUser;
    if (me == null) return;
    final members = await _future;
    final selected = <String>{};
    final nameController = TextEditingController();
    if (!mounted) return;
    final candidates = members.where((m) {
      final id = m['id'] as String?;
      return id != null && id != me.id && !_blockedIds.contains(id);
    }).toList();

    final ok = await showDialog<bool>(
      context: context,
      builder: (dialog) => StatefulBuilder(
        builder: (context, setDialog) => AlertDialog(
          title: const Text('Nouveau groupe'),
          content: SizedBox(
            width: 420,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameController,
                    maxLength: 60,
                    decoration: const InputDecoration(labelText: 'Nom du groupe'),
                  ),
                  ...candidates.map((m) {
                    final id = m['id'] as String;
                    return CheckboxListTile(
                      value: selected.contains(id),
                      onChanged: (v) => setDialog(() {
                        v == true ? selected.add(id) : selected.remove(id);
                      }),
                      title: Text(_memberLabel(m)),
                    );
                  }),
                  if (candidates.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(12),
                      child: Text('Aucun membre disponible.'),
                    ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialog, false),
              child: const Text('Annuler'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(
                dialog,
                nameController.text.trim().isNotEmpty && selected.isNotEmpty,
              ),
              child: const Text('Créer'),
            ),
          ],
        ),
      ),
    );

    if (ok != true) {
      nameController.dispose();
      return;
    }

    try {
      final groupName = nameController.text.trim();
      final id = await _conversation.createConversation(
        name: groupName,
        createdBy: me.id,
        memberIds: [me.id, ...selected],
        isGroup: true,
      );
      if (mounted) {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => ChatPage(conversationId: id, title: groupName),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    }
    nameController.dispose();
  }

  Future<void> _manageMember(Map<String, dynamic> member) async {
    final id = member['id'] as String?;
    if (id == null) return;
    final name = _memberLabel(member);
    await showModalBottomSheet<void>(
      context: context,
      builder: (sheet) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.block),
              title: const Text('Bloquer'),
              onTap: () async {
                Navigator.pop(sheet);
                try {
                  await _safety.blockUser(id);
                  if (mounted) {
                    setState(() => _blockedIds = {..._blockedIds, id});
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('$name a été bloqué.')),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(e.toString())),
                    );
                  }
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.flag_outlined),
              title: const Text('Signaler'),
              onTap: () async {
                Navigator.pop(sheet);
                final reason = await showDialog<String>(
                  context: context,
                  builder: (dialog) {
                    final controller = TextEditingController();
                    return AlertDialog(
                      title: const Text('Signaler cet utilisateur'),
                      content: TextField(
                        controller: controller,
                        maxLength: 200,
                        decoration: const InputDecoration(
                          hintText: 'Motif du signalement',
                        ),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(dialog),
                          child: const Text('Annuler'),
                        ),
                        FilledButton(
                          onPressed: () =>
                              Navigator.pop(dialog, controller.text.trim()),
                          child: const Text('Envoyer'),
                        ),
                      ],
                    );
                  },
                );
                if (reason == null || reason.isEmpty) return;
                try {
                  await _safety.reportUser(userId: id, reason: reason);
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Signalement envoyé.')),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(e.toString())),
                    );
                  }
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openMember(Map<String, dynamic> member) async {
    final me = _conversation.client.auth.currentUser;
    final otherId = member['id'] as String?;
    if (me == null || otherId == null) return;
    if (_blockedIds.contains(otherId)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cet utilisateur est bloqué.')),
      );
      return;
    }

    try {
      final id = await _conversation.getOrCreateDirectConversation(
        currentUserId: me.id,
        otherUserId: otherId,
        otherName: _memberLabel(member),
      );
      if (mounted) {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => ChatPage(
              conversationId: id,
              title: _memberLabel(member),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('BIIC CHAT'),
        actions: [
          IconButton(
            onPressed: _createGroup,
            icon: const Icon(Icons.group_add),
            tooltip: 'Créer un groupe',
          ),
          IconButton(
            onPressed: _reload,
            icon: const Icon(Icons.refresh),
            tooltip: 'Actualiser',
          ),
          IconButton(
            onPressed: () => AuthService().signOut(),
            icon: const Icon(Icons.logout),
            tooltip: 'Déconnexion',
          ),
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
                suffixIcon: _search.text.isEmpty
                    ? null
                    : IconButton(
                        onPressed: () {
                          _search.clear();
                          setState(() {});
                        },
                        icon: const Icon(Icons.clear),
                      ),
                border: const OutlineInputBorder(),
              ),
            ),
          ),
          Expanded(
            child: FutureBuilder<List<Map<String, dynamic>>>(
              future: _future,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        'Impossible de charger les membres : ' +
                            snapshot.error.toString(),
                      ),
                    ),
                  );
                }

                final me = _conversation.client.auth.currentUser?.id;
                final query = _search.text.trim().toLowerCase();
                final members = (snapshot.data ?? const []).where((m) {
                  final id = m['id'] as String?;
                  if (id == null || id == me || _blockedIds.contains(id)) {
                    return false;
                  }
                  final name =
                      (m['display_name'] as String? ?? '').toLowerCase();
                  return query.isEmpty || name.contains(query);
                }).toList();

                if (members.isEmpty) {
                  return const Center(child: Text('Aucun membre correspondant.'));
                }

                return ListView.separated(
                  itemCount: members.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final member = members[index];
                    final name = _memberLabel(member);
                    final status = member['status'] as String? ?? 'offline';
                    final avatar = member['avatar_url'] as String?;
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundImage:
                            avatar == null ? null : NetworkImage(avatar),
                        child: avatar == null
                            ? Text(name.substring(0, 1).toUpperCase())
                            : null,
                      ),
                      title: Text(name),
                      subtitle: Text('$status • Appuyer pour discuter'),
                      trailing: PopupMenuButton<String>(
                        tooltip: 'Options',
                        onSelected: (_) => _manageMember(member),
                        itemBuilder: (_) => const [
                          PopupMenuItem(
                            value: 'safety',
                            child: Text('Bloquer / Signaler'),
                          ),
                        ],
                      ),
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

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }
}
