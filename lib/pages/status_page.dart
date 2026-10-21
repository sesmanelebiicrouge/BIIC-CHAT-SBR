import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../services/members_service.dart';
import '../services/status_service.dart';

class StatusPage extends StatefulWidget {
  const StatusPage({super.key, this.showAppBar = true});
  final bool showAppBar;

  @override
  State<StatusPage> createState() => _StatusPageState();
}

class _StatusPageState extends State<StatusPage> {
  final _service = StatusService();
  final _members = MembersService();
  List<Map<String, dynamic>> _statuses = const [];
  Map<String, String> _names = const {};
  bool _loading = true;
  bool _publishing = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final results = await Future.wait([
        _service.getVisibleStatuses(),
        _members.getMembers(),
      ]);
      final statuses = List<Map<String, dynamic>>.from(results[0] as List);
      final members = List<Map<String, dynamic>>.from(results[1] as List);
      final names = <String, String>{};
      for (final member in members) {
        final id = member['id']?.toString();
        final name = (member['display_name'] as String? ?? '').trim();
        if (id != null && name.isNotEmpty) names[id] = name;
      }
      if (!mounted) return;
      setState(() {
        _statuses = statuses;
        _names = names;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Impossible de charger les statuts : $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<String?> _chooseAudience() async {
    return showModalBottomSheet<String>(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const ListTile(title: Text('Qui peut voir ce statut ?')),
            ListTile(
              leading: const Icon(Icons.contacts_outlined),
              title: const Text('Mes contacts BIIC CHAT'),
              subtitle: const Text('Personnes qui vous ont dans leurs contacts synchronisés'),
              onTap: () => Navigator.pop(sheetContext, 'contacts'),
            ),
            ListTile(
              leading: const Icon(Icons.public),
              title: const Text('Tous les utilisateurs BIIC CHAT'),
              onTap: () => Navigator.pop(sheetContext, 'everyone'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _publishText() async {
    final audience = await _chooseAudience();
    if (audience == null || !mounted) return;
    final controller = TextEditingController();
    final text = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Nouveau statut texte'),
        content: TextField(
          controller: controller,
          autofocus: true,
          minLines: 3,
          maxLines: 6,
          maxLength: 700,
          decoration: const InputDecoration(
            hintText: 'Quoi de neuf ?',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, controller.text.trim()),
            child: const Text('Publier'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (text == null || text.trim().isEmpty) return;
    await _runPublish(() => _service.publishText(content: text, audience: audience));
  }

  Future<void> _publishMedia({required bool video}) async {
    final audience = await _chooseAudience();
    if (audience == null || !mounted) return;
    try {
      final picker = ImagePicker();
      final file = video
          ? await picker.pickVideo(
              source: ImageSource.gallery,
              maxDuration: const Duration(seconds: 60),
            )
          : await picker.pickImage(
              source: ImageSource.gallery,
              maxWidth: 1920,
              maxHeight: 1920,
              imageQuality: 85,
            );
      if (file == null) return;
      final bytes = await file.readAsBytes();
      await _runPublish(() => _service.publishMedia(
            bytes: bytes,
            fileName: file.name,
            mediaType: video ? 'video' : 'image',
            audience: audience,
          ));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Impossible de sélectionner le média : $e')),
        );
      }
    }
  }

  Future<void> _runPublish(Future<void> Function() action) async {
    setState(() => _publishing = true);
    try {
      await action();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Statut publié. Il expirera dans 24 heures.')),
      );
      await _load();
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

  Future<void> _openStatus(Map<String, dynamic> status) async {
    final id = status['id'] as String?;
    final mediaPath = status['media_path'] as String?;
    final mediaType = status['media_type'] as String? ?? 'text';
    try {
      if (id != null) await _service.markViewed(id);
      if (mediaPath != null && mediaPath.isNotEmpty) {
        final url = await _service.createMediaUrl(mediaPath);
        if (!mounted) return;
        if (mediaType == 'video') {
          final opened = await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
          if (!opened && mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Impossible d’ouvrir cette vidéo.')),
            );
          }
        } else {
          await showDialog<void>(
            context: context,
            builder: (dialogContext) => Dialog(
              child: InteractiveViewer(
                child: Image.network(
                  url,
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => const Padding(
                    padding: EdgeInsets.all(24),
                    child: Text('Impossible de charger cette photo.'),
                  ),
                ),
              ),
            ),
          );
        }
      } else if (mounted) {
        await showDialog<void>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: Text(_names[status['user_id']] ?? 'Statut'),
            content: Text(status['content'] as String? ?? ''),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text('Fermer'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Impossible d’ouvrir le statut : $e')),
        );
      }
    }
  }

  Future<void> _showStatusViews(Map<String, dynamic> status) async {
    final id = status['id'] as String?;
    if (id == null) return;
    try {
      final views = await _service.getStatusViews(id);
      if (!mounted) return;
      await showModalBottomSheet<void>(
        context: context,
        showDragHandle: true,
        builder: (sheetContext) => SafeArea(
          child: SizedBox(
            height: MediaQuery.of(sheetContext).size.height * 0.55,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
                  child: Row(
                    children: [
                      const Icon(Icons.visibility_outlined),
                      const SizedBox(width: 10),
                      Text('Vues du statut (${views.length})', style: Theme.of(sheetContext).textTheme.titleMedium),
                    ],
                  ),
                ),
                const Divider(height: 1),
                Expanded(
                  child: views.isEmpty
                      ? const Center(child: Text('Personne n’a encore vu ce statut.'))
                      : ListView.separated(
                          itemCount: views.length,
                          separatorBuilder: (_, __) => const Divider(height: 1, indent: 72),
                          itemBuilder: (context, index) {
                            final view = views[index];
                            final viewerId = view['viewer_id']?.toString() ?? '';
                            return ListTile(
                              leading: const CircleAvatar(child: Icon(Icons.person_outline)),
                              title: Text(_names[viewerId] ?? 'Utilisateur BIIC CHAT'),
                              subtitle: Text(_timeLabel(view['viewed_at'])),
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Impossible de charger les vues : $e')),
        );
      }
    }
  }

  Future<void> _deleteStatus(Map<String, dynamic> status) async {
    final id = status['id'] as String?;
    if (id == null) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Supprimer ce statut ?'),
        content: const Text('Cette action est définitive.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await _service.deleteStatus(id);
      await _load();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Suppression impossible : $e')),
        );
      }
    }
  }

  String _timeLabel(dynamic raw) {
    final date = DateTime.tryParse(raw?.toString() ?? '')?.toLocal();
    if (date == null) return '';
    final diff = DateTime.now().difference(date);
    if (diff.inMinutes < 1) return 'À l’instant';
    if (diff.inHours < 1) return 'Il y a ${diff.inMinutes} min';
    if (diff.inDays < 1) return 'Il y a ${diff.inHours} h';
    return 'Il y a ${diff.inDays} j';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: widget.showAppBar ? AppBar(title: const Text('Statuts')) : null,
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
            child: Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: _publishing ? null : _publishText,
                    icon: const Icon(Icons.text_fields),
                    label: const Text('Texte'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _publishing ? null : () => _publishMedia(video: false),
                    icon: const Icon(Icons.photo_outlined),
                    label: const Text('Photo'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _publishing ? null : () => _publishMedia(video: true),
                    icon: const Icon(Icons.videocam_outlined),
                    label: const Text('Vidéo'),
                  ),
                ),
              ],
            ),
          ),
          if (_publishing) const LinearProgressIndicator(),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _statuses.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.donut_large_outlined, size: 58),
                              const SizedBox(height: 14),
                              const Text(
                                'Aucun statut récent',
                                style: TextStyle(fontSize: 19, fontWeight: FontWeight.w700),
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                'Publiez une photo, une vidéo ou un texte. Les statuts expirent après 24 heures.',
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 16),
                              OutlinedButton.icon(
                                onPressed: _load,
                                icon: const Icon(Icons.refresh),
                                label: const Text('Actualiser'),
                              ),
                            ],
                          ),
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _load,
                        child: ListView.separated(
                          itemCount: _statuses.length,
                          separatorBuilder: (_, __) => const Divider(height: 1, indent: 72),
                          itemBuilder: (context, index) {
                            final status = _statuses[index];
                            final userId = status['user_id']?.toString() ?? '';
                            final name = _names[userId] ?? 'Utilisateur BIIC CHAT';
                            final mediaType = status['media_type'] as String? ?? 'text';
                            final content = (status['content'] as String? ?? '').trim();
                            final isOwn = userId == _serviceUserId;
                            return ListTile(
                              leading: CircleAvatar(
                                child: Icon(mediaType == 'video'
                                    ? Icons.play_arrow
                                    : mediaType == 'image'
                                        ? Icons.photo_outlined
                                        : Icons.donut_large),
                              ),
                              title: Text(name, style: const TextStyle(fontWeight: FontWeight.w700)),
                              subtitle: Text([
                                if (content.isNotEmpty) content,
                                if (mediaType != 'text') mediaType == 'video' ? 'Vidéo' : 'Photo',
                                _timeLabel(status['created_at']),
                              ].where((part) => part.isNotEmpty).join(' • '), maxLines: 2, overflow: TextOverflow.ellipsis),
                              trailing: isOwn
                                  ? PopupMenuButton<String>(
                                      onSelected: (action) {
                                        if (action == 'views') _showStatusViews(status);
                                        if (action == 'delete') _deleteStatus(status);
                                      },
                                      itemBuilder: (_) => const [
                                        PopupMenuItem(
                                          value: 'views',
                                          child: ListTile(
                                            contentPadding: EdgeInsets.zero,
                                            leading: Icon(Icons.visibility_outlined),
                                            title: Text('Voir les vues'),
                                          ),
                                        ),
                                        PopupMenuItem(
                                          value: 'delete',
                                          child: ListTile(
                                            contentPadding: EdgeInsets.zero,
                                            leading: Icon(Icons.delete_outline),
                                            title: Text('Supprimer'),
                                          ),
                                        ),
                                      ],
                                    )
                                  : const Icon(Icons.chevron_right),
                              onTap: () => _openStatus(status),
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  String get _serviceUserId =>
      Supabase.instance.client.auth.currentUser?.id ?? '';
}
