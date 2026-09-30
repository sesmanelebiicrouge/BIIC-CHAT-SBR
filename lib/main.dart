import 'package:flutter/material.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'config/app_config.dart';
import 'pages/auth_page.dart';
import 'pages/members_page.dart';
import 'services/auth_service.dart';
import 'services/backend_service.dart';
import 'services/device_access_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeBackend();
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
      home: AppConfig.hasSupabaseConfig ? const AuthGate() : const ChatHomePage(),
    );
  }
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = AuthService();
    return StreamBuilder<AuthState>(
      stream: auth.authStateChanges,
      builder: (context, snapshot) {
        final session = snapshot.data?.session ?? auth.currentSession;
        if (session == null) return const AuthPage();
        return const MembersPage();
      },
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
      text: 'Bienvenue sur BIIC CHAT !',
      isMe: false,
    ),
  ];

  void _sendMessage([String? value]) {
    final text = (value ?? _messageController.text).trim();
    if (text.isEmpty) return;
    setState(() {
      _messages.add(_ChatMessage(sender: 'Vous', text: text, isMe: true));
      _messageController.clear();
    });
  }

  Future<void> _openAttachments() async {
    final action = await showModalBottomSheet<_AttachmentAction>(
      context: context,
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Choisir une image'),
              onTap: () => Navigator.pop(context, _AttachmentAction.gallery),
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Prendre une photo'),
              onTap: () => Navigator.pop(context, _AttachmentAction.camera),
            ),
            ListTile(
              leading: const Icon(Icons.attach_file),
              title: const Text('Choisir un fichier'),
              onTap: () => Navigator.pop(context, _AttachmentAction.file),
            ),
            ListTile(
              leading: const Icon(Icons.contacts),
              title: const Text('Partager un contact'),
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
          final file = await _deviceAccess.pickImageFromGallery();
          if (file != null) _sendMessage('Image sélectionnée : ${file.name}');
          break;
        case _AttachmentAction.camera:
          final file = await _deviceAccess.takePhoto();
          if (file != null) _sendMessage('Photo prise : ${file.name}');
          break;
        case _AttachmentAction.file:
          final result = await _deviceAccess.pickFiles();
          if (result != null) {
            final names = result.files.map((file) => file.name).join(', ');
            _sendMessage('Fichier(s) : $names');
          }
          break;
        case _AttachmentAction.contacts:
          final contacts = await _deviceAccess.pickContacts();
          if (contacts.isEmpty) {
            _showMessage('Aucun contact trouvé');
          } else if (mounted) {
            await _showContacts(contacts);
          }
          break;
      }
    } catch (error) {
      if (mounted) _showMessage(error.toString());
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
            final phone =
                contact.phones.isEmpty ? null : contact.phones.first.number;
            return ListTile(
              leading: const CircleAvatar(child: Icon(Icons.person)),
              title: Text(contact.displayName),
              subtitle: Text(phone ?? 'Aucun numéro'),
              trailing: phone == null
                  ? null
                  : IconButton(
                      icon: const Icon(Icons.phone),
                      onPressed: () => _deviceAccess.callNumber(phone),
                    ),
              onTap: phone == null
                  ? null
                  : () {
                      Navigator.pop(context);
                      _sendMessage(
                        'Contact : ${contact.displayName} - $phone',
                      );
                    },
            );
          },
        ),
      ),
    );
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('BIIC CHAT'),
        backgroundColor: const Color(0xFF1D4ED8),
        foregroundColor: Colors.white,
        actions: [
          if (AppConfig.hasSupabaseConfig)
            IconButton(
              tooltip: 'Membres',
              icon: const Icon(Icons.people),
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const MembersPage()),
                );
              },
            ),
          if (AppConfig.hasSupabaseConfig)
            IconButton(
              tooltip: 'Déconnexion',
              icon: const Icon(Icons.logout),
              onPressed: () => AuthService().signOut(),
            ),
        ],
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
                  alignment: message.isMe
                      ? Alignment.centerRight
                      : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    constraints: BoxConstraints(
                      maxWidth: MediaQuery.sizeOf(context).width * .78,
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: message.isMe
                          ? const Color(0xFF2563EB)
                          : Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Text(
                      message.text,
                      style: TextStyle(
                        color: message.isMe ? Colors.white : Colors.black,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(8, 4, 8, 8),
              child: Row(
                children: [
                  IconButton(
                    onPressed: _openAttachments,
                    icon: const Icon(Icons.add_circle),
                    tooltip: 'Pièces jointes',
                  ),
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      decoration: InputDecoration(
                        hintText: 'Écrire un message...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                      ),
                      minLines: 1,
                      maxLines: 3,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _sendMessage(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  FloatingActionButton(
                    onPressed: _sendMessage,
                    tooltip: 'Envoyer',
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

  const _ChatMessage({
    required this.sender,
    required this.text,
    required this.isMe,
  });
}
