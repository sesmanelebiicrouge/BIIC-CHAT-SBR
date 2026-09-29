import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:image_picker/image_picker.dart';
import 'services/device_access_service.dart';

void main() {
  runApp(const BIICChatApp());
}

class BIICChatApp extends StatelessWidget {
  const BIICChatApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'BIIC CHAT',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF1D4ED8)),
        useMaterial3: true,
      ),
      home: const ChatHomePage(),
    );
  }
}

class ChatHomePage extends StatefulWidget {
  const ChatHomePage({super.key});

  @override
  State<ChatHomePage> createState() => _ChatHomePageState();
}

class _ChatHomePageState extends State<ChatHomePage> {
  final _messageController = TextEditingController();
  final _deviceAccess = DeviceAccessService();
  final List<_ChatMessage> _messages = [
    const _ChatMessage(
      sender: 'BIIC Bot',
      text: 'Bienvenue sur BIIC CHAT. Dites bonjour à votre communauté.',
      isMe: false,
    ),
  ];

  void _sendMessage([String? content]) {
    final text = (content ?? _messageController.text).trim();
    if (text.isEmpty) return;

    setState(() {
      _messages.add(_ChatMessage(sender: 'Vous', text: text, isMe: true));
      _messageController.clear();
    });
  }

  Future<void> _showAttachmentMenu() async {
    final action = await showModalBottomSheet<_AttachmentAction>(
      context: context,
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Galerie photo/vidéo'),
              onTap: () => Navigator.pop(context, _AttachmentAction.gallery),
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Prendre une photo'),
              onTap: () => Navigator.pop(context, _AttachmentAction.camera),
            ),
            ListTile(
              leading: const Icon(Icons.attach_file),
              title: const Text('Fichiers'),
              onTap: () => Navigator.pop(context, _AttachmentAction.file),
            ),
            ListTile(
              leading: const Icon(Icons.contacts),
              title: const Text('Répertoire / contacts'),
              onTap: () => Navigator.pop(context, _AttachmentAction.contacts),
            ),
          ],
        ),
      ),
    );

    if (!mounted || action == null) return;

    try {
      switch (action) {
        case _AttachmentAction.gallery:
          final image = await _deviceAccess.pickImageFromGallery();
          if (image != null) _sendMessage('📷 Image sélectionnée : ${image.name}');
        case _AttachmentAction.camera:
          final photo = await _deviceAccess.takePhoto();
          if (photo != null) _sendMessage('📷 Photo prise : ${photo.name}');
        case _AttachmentAction.file:
          final result = await _deviceAccess.pickFiles();
          if (result != null) {
            final names = result.files.map((file) => file.name).join(', ');
            _sendMessage('📎 Fichier(s) sélectionné(s) : $names');
          }
        case _AttachmentAction.contacts:
          final contacts = await _deviceAccess.pickContacts();
          if (contacts.isEmpty) {
            _showInfo('Aucun contact trouvé');
          } else if (mounted) {
            await _showContacts(contacts);
          }
      }
    } catch (error) {
      if (mounted) _showInfo(error.toString());
    }
  }

  Future<void> _showContacts(List<Contact> contacts) async {
    await showModalBottomSheet<void>(
      context: context,
      builder: (context) => SafeArea(
        child: ListView.builder(
          shrinkWrap: true,
          itemCount: contacts.length,
          itemBuilder: (context, index) {
            final contact = contacts[index];
            final phone = contact.phones.isEmpty ? null : contact.phones.first.number;
            return ListTile(
              leading: const CircleAvatar(child: Icon(Icons.person)),
              title: Text(contact.displayName),
              subtitle: Text(phone ?? 'Aucun numéro'),
              trailing: phone == null
                  ? null
                  : IconButton(
                      icon: const Icon(Icons.phone),
                      onPressed: () async {
                        try {
                          await _deviceAccess.callNumber(phone);
                        } catch (error) {
                          if (mounted) _showInfo(error.toString());
                        }
                      },
                    ),
              onTap: phone == null ? null : () => _sendMessage('👤 ${contact.displayName} : $phone'),
            );
          },
        ),
      ),
    );
  }

  void _showInfo(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('BIIC CHAT'),
        backgroundColor: const Color(0xFF1D4ED8),
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final message = _messages[index];
                return Align(
                  alignment: message.isMe ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: message.isMe ? const Color(0xFF2563EB) : Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Text(
                      message.text,
                      style: TextStyle(color: message.isMe ? Colors.white : Colors.black),
                    ),
                  ),
                );
              },
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                children: [
                  IconButton(onPressed: _showAttachmentMenu, icon: const Icon(Icons.add_circle)),
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      decoration: InputDecoration(
                        hintText: 'Écrire un message...',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(24)),
                      ),
                      minLines: 1,
                      maxLines: 3,
                      onSubmitted: (_) => _sendMessage(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  FloatingActionButton(
                    onPressed: _sendMessage,
                    backgroundColor: const Color(0xFF1D4ED8),
                    child: const Icon(Icons.send),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }
}

enum _AttachmentAction { gallery, camera, file, contacts }

class _ChatMessage {
  final String sender;
  final String text;
  final bool isMe;

  const _ChatMessage({required this.sender, required this.text, required this.isMe});
}
