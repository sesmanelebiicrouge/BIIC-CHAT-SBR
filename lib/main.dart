import 'package:flutter/material.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'config/app_config.dart';
import 'pages/auth_page.dart';
import 'pages/members_page.dart';
import 'pages/home_page.dart';
import 'services/auth_service.dart';
import 'services/backend_service.dart';
import 'services/device_access_service.dart';
import 'widgets/biic_brand.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeBackend();
  runApp(const BIICChatApp());
}

class BIICChatApp extends StatelessWidget {
  const BIICChatApp({super.key});
  @override
  Widget build(BuildContext context) {
    const red = Color(0xFFD71920);
    return MaterialApp(
      title: 'BIIC CHAT',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: red),
        scaffoldBackgroundColor: const Color(0xFFF8F8F8),
        appBarTheme: const AppBarTheme(backgroundColor: red, foregroundColor: Colors.white, elevation: 0),
        inputDecorationTheme: const InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(16)), borderSide: BorderSide.none),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(16)), borderSide: BorderSide(color: Color(0xFFE7E7E7))),
        ),
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
        return session == null ? const AuthPage() : const HomePage();
      },
    );
  }
}

class ChatHomePage extends StatefulWidget {
  const ChatHomePage({super.key});
  @override State<ChatHomePage> createState() => _ChatHomePageState();
}

class _ChatHomePageState extends State<ChatHomePage> {
  final _messageController = TextEditingController();
  final _deviceAccess = DeviceAccessService();
  final List<_ChatMessage> _messages = const [
    _ChatMessage(sender: 'BIIC CHAT', text: 'Bienvenue sur BIIC CHAT ! Votre espace de discussion est prêt.', isMe: false),
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
      builder: (context) => SafeArea(child: Wrap(children: [
        const Padding(padding: EdgeInsets.fromLTRB(20,18,20,8), child: Text('Partager', style: TextStyle(fontSize:18,fontWeight:FontWeight.w700))),
        ListTile(leading: const Icon(Icons.photo_library_outlined), title: const Text('Choisir une image'), onTap: ()=>Navigator.pop(context,_AttachmentAction.gallery)),
        ListTile(leading: const Icon(Icons.camera_alt_outlined), title: const Text('Prendre une photo'), onTap: ()=>Navigator.pop(context,_AttachmentAction.camera)),
        ListTile(leading: const Icon(Icons.attach_file), title: const Text('Choisir un fichier'), onTap: ()=>Navigator.pop(context,_AttachmentAction.file)),
        ListTile(leading: const Icon(Icons.contacts_outlined), title: const Text('Partager un contact'), onTap: ()=>Navigator.pop(context,_AttachmentAction.contacts)),
      ])),
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
          final files = await _deviceAccess.pickFiles();
          if (files.isNotEmpty) _sendMessage('Fichier(s) : ${files.map((f)=>f.name).join(', ')}');
          break;
        case _AttachmentAction.contacts:
          final contacts = await _deviceAccess.pickContacts();
          if (contacts.isEmpty) {
            _showMessage('Aucun contact trouvé');
          } else if (mounted) {
            await showModalBottomSheet<void>(
              context: context,
              builder: (context) => SafeArea(child: ListView.builder(
                shrinkWrap: true,
                itemCount: contacts.length,
                itemBuilder: (context,index) {
                  final c=contacts[index];
                  final phone=c.phones.isEmpty?null:c.phones.first.number;
                  return ListTile(
                    leading: BiicAvatar(label:c.displayName,radius:21),
                    title: Text(c.displayName??'Contact sans nom'),
                    subtitle: Text(phone??'Aucun numéro'),
                    onTap: phone==null?null:(){Navigator.pop(context);_sendMessage('Contact : ${c.displayName} - $phone');},
                  );
                },
              )),
            );
          }
          break;
      }
    } catch (e) { if (mounted) _showMessage(e.toString()); }
  }

  void _showMessage(String message) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const BiicBrand(iconSize: 36, showSubtitle: false),
        actions: [IconButton(tooltip:'À propos', icon:const Icon(Icons.info_outline), onPressed:()=>showAboutDialog(context:context,applicationName:'BIIC CHAT',applicationVersion:'1.0.0',applicationLegalese:'SBR'))],
      ),
      body: Column(children: [
        Expanded(child: ListView.builder(
          padding: const EdgeInsets.fromLTRB(12,18,12,12),
          itemCount: _messages.length,
          itemBuilder: (context,index) {
            final m=_messages[index];
            return Align(
              alignment:m.isMe?Alignment.centerRight:Alignment.centerLeft,
              child:Container(
                margin:const EdgeInsets.only(bottom:10),
                constraints:BoxConstraints(maxWidth:MediaQuery.sizeOf(context).width*.82),
                padding:const EdgeInsets.symmetric(horizontal:15,vertical:12),
                decoration:BoxDecoration(
                  color:m.isMe?const Color(0xFFD71920):Colors.white,
                  borderRadius:BorderRadius.only(topLeft:const Radius.circular(18),topRight:const Radius.circular(18),bottomLeft:Radius.circular(m.isMe?18:5),bottomRight:Radius.circular(m.isMe?5:18)),
                  boxShadow:const [BoxShadow(color:Color(0x12000000),blurRadius:8,offset:Offset(0,2))],
                ),
                child:Text(m.text,style:TextStyle(color:m.isMe?Colors.white:const Color(0xFF222222),height:1.35)),
              ),
            );
          },
        )),
        SafeArea(child:Container(
          padding:const EdgeInsets.fromLTRB(8,6,8,8),
          color:Colors.white,
          child:Row(children:[
            IconButton(onPressed:_openAttachments,icon:const Icon(Icons.add_circle_outline),color:const Color(0xFFD71920),tooltip:'Pièces jointes'),
            Expanded(child:TextField(controller:_messageController,minLines:1,maxLines:3,textInputAction:TextInputAction.send,onSubmitted:(_)=>_sendMessage(),decoration:const InputDecoration(hintText:'Écrire un message...',contentPadding:EdgeInsets.symmetric(horizontal:18,vertical:13)))),
            const SizedBox(width:6),
            IconButton.filled(onPressed:_sendMessage,style:IconButton.styleFrom(backgroundColor:const Color(0xFFD71920),foregroundColor:Colors.white),icon:const Icon(Icons.send_rounded)),
          ]),
        )),
      ]),
    );
  }
  @override void dispose(){_messageController.dispose();super.dispose();}
}

enum _AttachmentAction { gallery, camera, file, contacts }
class _ChatMessage {
  final String sender; final String text; final bool isMe;
  const _ChatMessage({required this.sender,required this.text,required this.isMe});
}
