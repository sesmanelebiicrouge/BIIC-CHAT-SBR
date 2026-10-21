import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/conversation_service.dart';
import '../services/media_service.dart';
import '../services/device_permissions_service.dart';
import '../services/location_share_service.dart';
import '../services/call_history_service.dart';

class ChatPage extends StatefulWidget {
  final String conversationId;
  final String title;
  const ChatPage({super.key, required this.conversationId, required this.title});
  @override State<ChatPage> createState() => _ChatPageState();
}
class _ChatPageState extends State<ChatPage> {
  final _service = ConversationService();
  final _media = MediaService();
  final _devicePermissions = DevicePermissionsService();
  final _locationShare = LocationShareService();
  final _controller = TextEditingController();
  bool _sending = false;
  bool _uploading = false;
  Map<String, dynamic>? _replyToMessage;
  String? _editingMessageId;
  final Set<String> _readMarked = <String>{};

  Future<void> _markIncomingAsRead(
      List<Map<String, dynamic>> messages, String? userId) async {
    if (userId == null || userId.isEmpty) return;
    final ids = messages
        .where((message) => message['sender_id'] != userId)
        .map((message) => message['id']?.toString() ?? '')
        .where((id) => id.isNotEmpty && !_readMarked.contains(id))
        .toList();
    if (ids.isEmpty) return;

    _readMarked.addAll(ids);
    try {
      await _service.markMessagesRead(
        userId: userId,
        conversationId: widget.conversationId,
        messageIds: ids,
      );
    } catch (_) {
      _readMarked.removeAll(ids);
    }
  }

  Future<void> _send() async {
    final text = _controller.text.trim();
    final user = _service.client.auth.currentUser;
    if (text.isEmpty || user == null) return;
    setState(() => _sending = true);
    try {
      final editingId = _editingMessageId;
      if (editingId != null) {
        await _service.editMessage(messageId: editingId, content: text);
      } else {
        await _service.sendMessage(
          conversationId: widget.conversationId,
          senderId: user.id,
          content: text,
          replyToMessageId: _replyToMessage?['id']?.toString(),
        );
      }
      _controller.clear();
      if (mounted) {
        setState(() {
          _replyToMessage = null;
          _editingMessageId = null;
        });
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Envoi impossible : $e')));
    } finally { if (mounted) setState(() => _sending = false); }
  }

  void _beginReply(Map<String, dynamic> message) {
    setState(() {
      _editingMessageId = null;
      _replyToMessage = message;
      _controller.clear();
    });
  }

  void _beginEdit(Map<String, dynamic> message) {
    setState(() {
      _replyToMessage = null;
      _editingMessageId = message['id']?.toString();
      _controller.text = message['content'] as String? ?? '';
    });
  }

  Future<void> _deleteMessage(Map<String, dynamic> message) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Supprimer le message ?'),
        content: const Text('Le message sera remplacé par une indication de suppression pour les participants.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('Annuler')),
          FilledButton(onPressed: () => Navigator.pop(dialogContext, true), child: const Text('Supprimer')),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await _service.deleteMessage(message['id'].toString());
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Suppression impossible : $e')));
    }
  }

  Future<void> _chooseReaction(Map<String, dynamic> message) async {
    const reactions = ['👍', '❤️', '😂', '😮', '😢', '🙏', '🔥', '👏'];
    final reaction = await showModalBottomSheet<String>(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Wrap(
            spacing: 12,
            runSpacing: 12,
            children: reactions.map((emoji) => ActionChip(
              label: Text(emoji, style: const TextStyle(fontSize: 24)),
              onPressed: () => Navigator.pop(sheetContext, emoji),
            )).toList(),
          ),
        ),
      ),
    );
    if (reaction == null) return;
    try {
      await _service.setReaction(messageId: message['id'].toString(), reaction: reaction);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Réaction impossible : $e')));
    }
  }

  Future<void> _togglePin(Map<String, dynamic> message) async {
    try {
      await _service.setMessagePinned(
        messageId: message['id'].toString(),
        pinned: message['is_pinned'] != true,
      );
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Épinglage impossible : $e')));
    }
  }

  Future<void> _showMessageActions(Map<String, dynamic> message, bool mine) async {
    if (message['deleted_at'] != null) return;
    await showModalBottomSheet<void>(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.reply),
              title: const Text('Répondre'),
              onTap: () { Navigator.pop(sheetContext); _beginReply(message); },
            ),
            ListTile(
              leading: const Icon(Icons.emoji_emotions_outlined),
              title: const Text('Réagir'),
              onTap: () { Navigator.pop(sheetContext); _chooseReaction(message); },
            ),
            if (mine && (message['media_url'] == null || (message['content'] as String? ?? '').isNotEmpty))
              ListTile(
                leading: const Icon(Icons.edit_outlined),
                title: const Text('Modifier le texte'),
                onTap: () { Navigator.pop(sheetContext); _beginEdit(message); },
              ),
            if (mine)
              ListTile(
                leading: const Icon(Icons.delete_outline, color: Colors.red),
                title: const Text('Supprimer le message'),
                onTap: () { Navigator.pop(sheetContext); _deleteMessage(message); },
              ),
            if (mine)
              ListTile(
                leading: Icon(message['is_pinned'] == true ? Icons.push_pin : Icons.push_pin_outlined),
                title: Text(message['is_pinned'] == true ? 'Désépingler' : 'Épingler'),
                onTap: () { Navigator.pop(sheetContext); _togglePin(message); },
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _archiveConversation() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Archiver cette discussion ?'),
        content: const Text('La discussion sera masquée de la liste principale. Vous pourrez la retrouver dans les discussions archivées.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('Annuler')),
          FilledButton(onPressed: () => Navigator.pop(dialogContext, true), child: const Text('Archiver')),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await _service.archiveConversation(widget.conversationId);
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Archivage impossible : $e')));
    }
  }

  Future<void> _startAudioCall() => _startExternalCall('audio');

  Future<void> _startVideoCall() => _startExternalCall('video');

  Future<void> _startExternalCall(String callType) async {
    // Keep a record of the attempt. Jitsi is still opened externally; this
    // does not implement incoming-call signalling or prove the other person joined.
    try {
      await CallHistoryService().recordOutgoingCall(
        conversationId: widget.conversationId,
        callType: callType,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('L’appel peut être lancé, mais son historique n’a pas pu être enregistré : $e')),
        );
      }
    }
    final room = 'biic-chat-${widget.conversationId}'.replaceAll(RegExp(r'[^a-zA-Z0-9-]'), '-');
    final uri = Uri.parse('https://meet.jit.si/$room');
    try {
      final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!opened && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Impossible de démarrer l’appel ${callType == 'audio' ? 'audio' : 'vidéo'}.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur lors du lancement de l’appel : $e')),
        );
      }
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    if (source == ImageSource.camera) {
      try {
        await _devicePermissions.requestCamera();
      } catch (e) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
        return;
      }
    }
    final file = await ImagePicker().pickImage(source: source, maxWidth: 1920, maxHeight: 1920, imageQuality: 88);
    if (file == null) return;
    await _upload(file.name, await file.readAsBytes(), file.mimeType ?? 'image/jpeg');
  }

  Future<void> _pickMedia() async {
    final file = await ImagePicker().pickMedia();
    if (file == null) return;
    await _upload(file.name, await file.readAsBytes(), file.mimeType ?? 'application/octet-stream');
  }

  Future<void> _shareContact() async {
    if (kIsWeb) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Le partage de contacts de l’appareil est disponible sur Android/iOS.'),
          ),
        );
      }
      return;
    }
    final permission = await FlutterContacts.permissions.request(PermissionType.readWrite);
    if (permission != PermissionStatus.granted) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Accès aux contacts refusé.')));
      return;
    }
    final contacts = await FlutterContacts.getAll(properties: {ContactProperty.name, ContactProperty.phone});
    if (!mounted || contacts.isEmpty) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Aucun contact disponible.')));
      return;
    }
    final contact = await showModalBottomSheet<Contact>(
      context: context,
      isScrollControlled: true,
      builder: (context) => SafeArea(
        child: SizedBox(
          height: MediaQuery.sizeOf(context).height * .7,
          child: ListView.builder(
            itemCount: contacts.length,
            itemBuilder: (_, index) {
              final item = contacts[index];
              final rawName = item.displayName ?? '';
              final name = rawName.isEmpty ? 'Contact' : rawName;
              return ListTile(
                leading: CircleAvatar(child: Text(name.substring(0, 1).toUpperCase())),
                title: Text(name),
                subtitle: Text(item.phones.isEmpty ? 'Aucun numéro' : item.phones.first.number),
                onTap: () => Navigator.pop(context, item),
              );
            },
          ),
        ),
      ),
    );
    if (contact == null) return;
    final user = _service.client.auth.currentUser;
    if (user == null) return;
    final rawName = contact.displayName ?? '';
    final name = rawName.isEmpty ? 'Contact' : rawName;
    final phone = contact.phones.isEmpty ? '' : contact.phones.first.number;
    await _service.sendMessage(
      conversationId: widget.conversationId,
      senderId: user.id,
      content: 'Contact : ' + name + (phone.isEmpty ? '' : ' • ' + phone),
    );
  }
  Future<void> _shareLocation() async {
    final user = _service.client.auth.currentUser;
    if (user == null || _sending || _uploading) return;
    setState(() => _sending = true);
    try {
      final message = await _locationShare.createLocationMessage();
      await _service.sendMessage(
        conversationId: widget.conversationId,
        senderId: user.id,
        content: message,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Position non partagée : $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Widget _buildMessageText(String text, bool mine) {
    const locationPrefix = '📍 Ma position : ';
    final theme = Theme.of(context);
    final textColor = mine ? theme.colorScheme.onPrimary : null;
    if (text.startsWith(locationPrefix)) {
      final uri = Uri.tryParse(text.substring(locationPrefix.length).trim());
      if (uri != null &&
          uri.scheme == 'https' &&
          uri.host == 'www.google.com' &&
          uri.path.startsWith('/maps/')) {
        return InkWell(
          onTap: () async {
            try {
              final opened = await launchUrl(
                uri,
                mode: LaunchMode.externalApplication,
              );
              if (!opened && mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Impossible d’ouvrir la carte.')),
                );
              }
            } catch (_) {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Impossible d’ouvrir la carte.')),
                );
              }
            }
          },
          child: Text(
            '$locationPrefix\nOuvrir la position sur Google Maps',
            style: TextStyle(
              color: mine ? theme.colorScheme.onPrimary : theme.colorScheme.primary,
              decoration: TextDecoration.underline,
            ),
          ),
        );
      }
    }
    return Text(text, style: TextStyle(color: textColor));
  }

  Future<void> _pickFile() async {
    final files = await FilePicker.pickFiles();
    if (files.isEmpty) return;
    final file = files.first;
    final bytes = await file.readAsBytes();
    await _upload(file.name, bytes, 'application/octet-stream');
  }
  Future<void> _upload(String name, List<int> bytes, String contentType) async {
    final user = _service.client.auth.currentUser;
    if (user == null || bytes.isEmpty) return;
    if (bytes.length > 50 * 1024 * 1024) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Fichier trop volumineux : 50 Mo maximum.')));
      return;
    }
    setState(() => _uploading = true);
    try {
      String? uploadedPath;
      try {
        uploadedPath = await _media.uploadChatFile(
          conversationId: widget.conversationId,
          fileName: name,
          bytes: Uint8List.fromList(bytes),
          contentType: contentType,
        );
        await _service.sendMessage(
          conversationId: widget.conversationId,
          senderId: user.id,
          content: '',
          mediaUrl: uploadedPath,
          mediaType: contentType,
        );
        // The object is now referenced by a persisted message.
        uploadedPath = null;
      } catch (_) {
        // If message creation fails after upload, avoid leaving an orphan object.
        if (uploadedPath != null) {
          try {
            await _media.deleteChatFile(uploadedPath);
          } catch (_) {
            // Preserve the original send error; cleanup can be retried separately.
          }
        }
        rethrow;
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Fichier non envoyé : $e')));
    } finally { if (mounted) setState(() => _uploading = false); }
  }
  Future<void> _attachments() async {
    if (_uploading) return;
    await showModalBottomSheet<void>(context: context, builder: (context) => SafeArea(child: Wrap(children: [
      ListTile(leading: const Icon(Icons.photo_library), title: const Text('Photos et vidéos'), onTap: () { Navigator.pop(context); _pickMedia(); }),
      ListTile(leading: const Icon(Icons.photo_camera), title: const Text('Appareil photo'), onTap: () { Navigator.pop(context); _pickImage(ImageSource.camera); }),
      ListTile(leading: const Icon(Icons.attach_file), title: const Text('Fichier / document'), onTap: () { Navigator.pop(context); _pickFile(); }),
      ListTile(leading: const Icon(Icons.contacts_outlined), title: const Text('Partager un contact'), onTap: () { Navigator.pop(context); _shareContact(); }),
      ListTile(leading: const Icon(Icons.location_on_outlined), title: const Text('Partager ma position'), subtitle: const Text('Une position ponctuelle, uniquement après autorisation'), onTap: () { Navigator.pop(context); _shareLocation(); }),
    ])));
  }
  Future<String> _signed(String path) => _media.createSignedUrl(path);

  @override
  Widget build(BuildContext context) {
    final userId = _service.client.auth.currentUser?.id;
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        actions: [
          IconButton(
            tooltip: 'Appel audio',
            icon: const Icon(Icons.call_outlined),
            onPressed: _startAudioCall,
          ),
          IconButton(
            tooltip: 'Appel vidéo',
            icon: const Icon(Icons.videocam_outlined),
            onPressed: _startVideoCall,
          ),
          PopupMenuButton<String>(
            tooltip: 'Options de discussion',
            onSelected: (value) {
              if (value == 'archive') _archiveConversation();
            },
            itemBuilder: (_) => const [
              PopupMenuItem(
                value: 'archive',
                child: ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(Icons.archive_outlined),
                  title: Text('Archiver la discussion'),
                ),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          if (_uploading) const LinearProgressIndicator(minHeight: 2),
          Expanded(
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: _service.watchMessages(widget.conversationId),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(20),
                      child: Text('Impossible de charger les messages.'),
                    ),
                  );
                }
                final messages = snapshot.data ?? const <Map<String, dynamic>>[];
                _markIncomingAsRead(messages, userId);
                if (messages.isEmpty) {
                  return const Center(child: Text('Aucun message. Écrivez le premier !'));
                }
                return StreamBuilder<List<Map<String, dynamic>>>(
                  stream: _service.watchMessageReads(widget.conversationId),
                  builder: (context, readSnapshot) {
                    final reads = readSnapshot.data ?? const <Map<String, dynamic>>[];
                    return StreamBuilder<List<Map<String, dynamic>>>(
                      stream: _service.watchMessageReactions(),
                      builder: (context, reactionSnapshot) {
                        final reactions = reactionSnapshot.data ?? const <Map<String, dynamic>>[];
                        return ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: messages.length,
                          itemBuilder: (context, index) {
                            final message = messages[index];
                            final mine = message['sender_id'] == userId;
                            final deleted = message['deleted_at'] != null;
                            final text = deleted
                                ? 'Ce message a été supprimé'
                                : (message['content'] as String? ?? '');
                            final mediaPath = deleted ? null : message['media_url'] as String?;
                            final mediaType = message['media_type'] as String? ?? '';
                            final messageId = message['id']?.toString() ?? '';
                            final isRead = mine && reads.any((read) =>
                                read['message_id']?.toString() == messageId &&
                                read['user_id']?.toString() != userId);
                            final replyId = message['reply_to_message_id']?.toString();
                            Map<String, dynamic>? reply;
                            if (replyId != null) {
                              for (final candidate in messages) {
                                if (candidate['id']?.toString() == replyId) {
                                  reply = candidate;
                                  break;
                                }
                              }
                            }
                            final messageReactions = reactions
                                .where((reaction) => reaction['message_id']?.toString() == messageId)
                                .toList();
                            final reactionCounts = <String, int>{};
                            for (final reaction in messageReactions) {
                              final emoji = reaction['reaction']?.toString() ?? '';
                              if (emoji.isNotEmpty) {
                                reactionCounts[emoji] = (reactionCounts[emoji] ?? 0) + 1;
                              }
                            }
                            final theme = Theme.of(context);
                            return Align(
                              alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
                              child: GestureDetector(
                                onLongPress: deleted ? null : () => _showMessageActions(message, mine),
                                child: Container(
                                  margin: const EdgeInsets.only(bottom: 8),
                                  padding: const EdgeInsets.all(10),
                                  constraints: BoxConstraints(
                                    maxWidth: MediaQuery.sizeOf(context).width * .82,
                                  ),
                                  decoration: BoxDecoration(
                                    color: mine
                                        ? theme.colorScheme.primary
                                        : theme.colorScheme.surfaceContainerHighest,
                                    borderRadius: BorderRadius.circular(18),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      if (reply != null)
                                        Container(
                                          width: double.infinity,
                                          margin: const EdgeInsets.only(bottom: 6),
                                          padding: const EdgeInsets.all(7),
                                          decoration: BoxDecoration(
                                            color: (mine ? theme.colorScheme.onPrimary : theme.colorScheme.primary)
                                                .withValues(alpha: .10),
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: Text(
                                            'Réponse à : ${reply['deleted_at'] != null ? 'Message supprimé' : ((reply['content'] as String? ?? '').isEmpty ? 'Pièce jointe' : reply['content'])}',
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: mine ? theme.colorScheme.onPrimary : theme.colorScheme.onSurface,
                                            ),
                                          ),
                                        ),
                                      if (message['is_pinned'] == true)
                                        Padding(
                                          padding: const EdgeInsets.only(bottom: 5),
                                          child: Text(
                                            '📌 Épinglé',
                                            style: TextStyle(
                                              fontSize: 11,
                                              color: mine ? theme.colorScheme.onPrimary : theme.colorScheme.primary,
                                            ),
                                          ),
                                        ),
                                      if (!deleted && mediaPath != null && mediaPath.isNotEmpty)
                                        _MediaBubble(
                                          path: mediaPath,
                                          type: mediaType,
                                          signedUrl: _signed,
                                          mine: mine,
                                        ),
                                      if (text.isNotEmpty)
                                        Padding(
                                          padding: EdgeInsets.only(top: mediaPath != null && !deleted ? 8 : 0),
                                          child: deleted
                                              ? Text(text, style: TextStyle(fontStyle: FontStyle.italic, color: mine ? theme.colorScheme.onPrimary.withValues(alpha: .75) : theme.colorScheme.onSurfaceVariant))
                                              : _buildMessageText(text, mine),
                                        ),
                                      if (message['edited_at'] != null && !deleted)
                                        Padding(
                                          padding: const EdgeInsets.only(top: 2),
                                          child: Text(
                                            'Modifié',
                                            style: TextStyle(fontSize: 10, color: mine ? theme.colorScheme.onPrimary.withValues(alpha: .7) : theme.colorScheme.onSurfaceVariant),
                                          ),
                                        ),
                                      if (reactionCounts.isNotEmpty)
                                        Padding(
                                          padding: const EdgeInsets.only(top: 5),
                                          child: Wrap(
                                            spacing: 4,
                                            runSpacing: 4,
                                            children: reactionCounts.entries.map((entry) => InkWell(
                                              onTap: () async {
                                                try {
                                                  await _service.setReaction(messageId: messageId, reaction: entry.key);
                                                } catch (e) {
                                                  if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Réaction impossible : $e')));
                                                }
                                              },
                                              child: Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                                                decoration: BoxDecoration(
                                                  color: theme.colorScheme.surface.withValues(alpha: .18),
                                                  borderRadius: BorderRadius.circular(12),
                                                ),
                                                child: Text('${entry.key} ${entry.value}', style: TextStyle(color: mine ? theme.colorScheme.onPrimary : theme.colorScheme.onSurface)),
                                              ),
                                            )).toList(),
                                          ),
                                        ),
                                      if (mine)
                                        Align(
                                          alignment: Alignment.centerRight,
                                          child: Text(
                                            isRead ? '✓✓ Lu' : '✓ Envoyé',
                                            style: TextStyle(
                                              fontSize: 11,
                                              color: theme.colorScheme.onPrimary.withValues(alpha: .8),
                                            ),
                                          ),
                                        ),
                                    ],
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
              },
            ),
          ),
          if (_replyToMessage != null || _editingMessageId != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(12, 7, 4, 7),
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              child: Row(
                children: [
                  Icon(_editingMessageId != null ? Icons.edit_outlined : Icons.reply, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _editingMessageId != null
                          ? 'Modification du message'
                          : 'Réponse à : ${(_replyToMessage?['content'] as String? ?? '').isEmpty ? 'Pièce jointe' : _replyToMessage?['content']}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    tooltip: 'Annuler',
                    onPressed: () => setState(() {
                      _replyToMessage = null;
                      _editingMessageId = null;
                      _controller.clear();
                    }),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Row(
                children: [
                  IconButton(
                    tooltip: 'Joindre un fichier',
                    onPressed: _uploading || _editingMessageId != null ? null : _attachments,
                    icon: const Icon(Icons.add_circle_outline),
                  ),
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      minLines: 1,
                      maxLines: 4,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _send(),
                      decoration: InputDecoration(
                        hintText: _editingMessageId != null
                            ? 'Modifier le message...'
                            : _replyToMessage != null
                                ? 'Écrire une réponse...'
                                : 'Écrire un message...',
                        border: const OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(
                    tooltip: _editingMessageId != null ? 'Enregistrer' : 'Envoyer',
                    onPressed: _sending || _uploading ? null : _send,
                    icon: _sending
                        ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                        : Icon(_editingMessageId != null ? Icons.check : Icons.send),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
  @override void dispose(){_controller.dispose();super.dispose();}
}
class _MediaBubble extends StatelessWidget {
  final String path; final String type; final Future<String> Function(String) signedUrl; final bool mine;
  const _MediaBubble({required this.path, required this.type, required this.signedUrl, required this.mine});
  @override Widget build(BuildContext context) {
    return FutureBuilder<String>(future: signedUrl(path), builder: (context, snapshot) {
      if (snapshot.connectionState == ConnectionState.waiting) return const SizedBox(width:180,height:120,child:Center(child:CircularProgressIndicator()));
      final url = snapshot.data; if (url == null) return const Text('Pièce jointe indisponible.');
      if (type.startsWith('image/')) return ClipRRect(borderRadius: BorderRadius.circular(12), child: Image.network(url, width: 220, height: 220, fit: BoxFit.cover, errorBuilder: (_,__,___)=>const Text('Image indisponible.')));
      return Row(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.insert_drive_file, color: mine ? Theme.of(context).colorScheme.onPrimary : null), const SizedBox(width: 8), Flexible(child: Text(path.split('/').last, overflow: TextOverflow.ellipsis))]);
    });
  }
}
