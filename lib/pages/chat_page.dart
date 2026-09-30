import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/conversation_service.dart';
import '../services/media_service.dart';

class ChatPage extends StatefulWidget {
  final String conversationId;
  final String title;
  const ChatPage({super.key, required this.conversationId, required this.title});
  @override State<ChatPage> createState() => _ChatPageState();
}
class _ChatPageState extends State<ChatPage> {
  final _service = ConversationService();
  final _media = MediaService();
  final _controller = TextEditingController();
  bool _sending = false;
  bool _uploading = false;

  Future<void> _send() async {
    final text = _controller.text.trim();
    final user = _service.client.auth.currentUser;
    if (text.isEmpty || user == null) return;
    setState(() => _sending = true);
    try {
      await _service.sendMessage(conversationId: widget.conversationId, senderId: user.id, content: text);
      _controller.clear();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Envoi impossible : $e')));
    } finally { if (mounted) setState(() => _sending = false); }
  }

  Future<void> _pickImage(ImageSource source) async {
    final file = await ImagePicker().pickImage(source: source, maxWidth: 1920, maxHeight: 1920, imageQuality: 88);
    if (file == null) return;
    await _upload(file.name, await file.readAsBytes(), file.mimeType ?? 'image/jpeg');
  }
  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(withData: true);
    if (result == null || result.files.single.bytes == null) return;
    final file = result.files.single;
    await _upload(file.name, file.bytes!, 'application/octet-stream');
  }
  Future<void> _upload(String name, List<int> bytes, String contentType) async {
    final user = _service.client.auth.currentUser;
    if (user == null || bytes.isEmpty) return;
    if (bytes.length > 20 * 1024 * 1024) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Fichier trop volumineux : 20 Mo maximum.')));
      return;
    }
    setState(() => _uploading = true);
    try {
      final path = await _media.uploadChatFile(conversationId: widget.conversationId, fileName: name, bytes: Uint8List.fromList(bytes), contentType: contentType);
      await _service.sendMessage(conversationId: widget.conversationId, senderId: user.id, content: '', mediaUrl: path, mediaType: contentType);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Fichier non envoyé : $e')));
    } finally { if (mounted) setState(() => _uploading = false); }
  }
  Future<void> _attachments() async {
    if (_uploading) return;
    await showModalBottomSheet<void>(context: context, builder: (context) => SafeArea(child: Wrap(children: [
      ListTile(leading: const Icon(Icons.photo_library), title: const Text('Galerie'), onTap: () { Navigator.pop(context); _pickImage(ImageSource.gallery); }),
      ListTile(leading: const Icon(Icons.photo_camera), title: const Text('Appareil photo'), onTap: () { Navigator.pop(context); _pickImage(ImageSource.camera); }),
      ListTile(leading: const Icon(Icons.attach_file), title: const Text('Fichier'), onTap: () { Navigator.pop(context); _pickFile(); }),
    ])));
  }
  Future<String> _signed(String path) => _media.createSignedUrl(path);

  @override Widget build(BuildContext context) {
    final userId = _service.client.auth.currentUser?.id;
    return Scaffold(appBar: AppBar(title: Text(widget.title)), body: Column(children: [
      if (_uploading) const LinearProgressIndicator(minHeight: 2),
      Expanded(child: StreamBuilder<List<Map<String,dynamic>>>(
        stream: _service.watchMessages(widget.conversationId),
        builder: (context, snapshot) {
          if (snapshot.hasError) return Center(child: Padding(padding: const EdgeInsets.all(20), child: Text('Erreur : \${snapshot.error}')));
          final messages = snapshot.data ?? const [];
          if (messages.isEmpty) return const Center(child: Text('Aucun message. Écrivez le premier !'));
          return ListView.builder(padding: const EdgeInsets.all(16), itemCount: messages.length, itemBuilder: (context,index) {
            final message = messages[index]; final mine = message['sender_id'] == userId;
            final text = message['content'] as String? ?? '';
            final mediaPath = message['media_url'] as String?; final mediaType = message['media_type'] as String? ?? '';
            return Align(alignment: mine ? Alignment.centerRight : Alignment.centerLeft, child: Container(
              margin: const EdgeInsets.only(bottom: 8), padding: const EdgeInsets.all(10),
              constraints: BoxConstraints(maxWidth: MediaQuery.sizeOf(context).width * .82),
              decoration: BoxDecoration(color: mine ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.surfaceContainerHighest, borderRadius: BorderRadius.circular(18)),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                if (mediaPath != null && mediaPath.isNotEmpty) _MediaBubble(path: mediaPath, type: mediaType, signedUrl: _signed, mine: mine),
                if (text.isNotEmpty) Padding(padding: EdgeInsets.only(top: mediaPath != null ? 8 : 0), child: Text(text, style: TextStyle(color: mine ? Theme.of(context).colorScheme.onPrimary : null))),
              ]),
            ));
          });
        },
      )),
      SafeArea(child: Padding(padding: const EdgeInsets.all(8), child: Row(children: [
        IconButton(tooltip: 'Joindre un fichier', onPressed: _uploading ? null : _attachments, icon: const Icon(Icons.add_circle_outline)),
        Expanded(child: TextField(controller: _controller, minLines: 1, maxLines: 4, textInputAction: TextInputAction.send, onSubmitted: (_) => _send(), decoration: const InputDecoration(hintText: 'Écrire un message...', border: OutlineInputBorder()))),
        const SizedBox(width: 8),
        IconButton.filled(tooltip: 'Envoyer', onPressed: _sending || _uploading ? null : _send, icon: _sending ? const SizedBox(width:18,height:18,child:CircularProgressIndicator(strokeWidth:2)) : const Icon(Icons.send)),
      ]))),
    ]));
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
