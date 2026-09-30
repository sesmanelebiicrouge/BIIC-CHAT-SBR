import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/conversation_service.dart';
import 'members_page.dart';
import 'chat_page.dart';
import 'profile_page.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});
  @override
  Widget build(BuildContext context) {
    final service = ConversationService();
    final user = service.client.auth.currentUser;
    if (user == null) return const MembersPage();
    return Scaffold(
      appBar: AppBar(title: const Text('BIIC CHAT'), actions: [
        IconButton(tooltip:'Mon profil', onPressed:()=>Navigator.of(context).push(MaterialPageRoute(builder:(_)=>const ProfilePage())), icon:const Icon(Icons.account_circle_outlined)),
        IconButton(tooltip:'Nouveau chat', onPressed:()=>Navigator.of(context).push(MaterialPageRoute(builder:(_)=>const MembersPage())), icon:const Icon(Icons.person_add_alt_1)),
        IconButton(tooltip:'Déconnexion', onPressed:()=>AuthService().signOut(), icon:const Icon(Icons.logout)),
      ]),
      body: StreamBuilder<List<Map<String,dynamic>>>(
        stream: service.getUserConversations(user.id),
        builder: (context,snapshot) {
          if(snapshot.hasError) return Center(child:Text('Erreur : '+snapshot.error.toString()));
          final conversations=snapshot.data??const [];
          if(conversations.isEmpty) return Center(child:Column(mainAxisSize:MainAxisSize.min,children:[const Icon(Icons.forum_outlined,size:64),const SizedBox(height:12),const Text('Aucune conversation'),const SizedBox(height:12),FilledButton.icon(onPressed:()=>Navigator.of(context).push(MaterialPageRoute(builder:(_)=>const MembersPage())),icon:const Icon(Icons.add),label:const Text('Démarrer une discussion'))]));
          return ListView.separated(
            itemCount:conversations.length,
            separatorBuilder:(_,__)=>const Divider(height:1),
            itemBuilder:(context,index){
              final c=conversations[index];
              return FutureBuilder<List<Map<String,dynamic>>>(
                future:service.getConversationMembers(c['id'] as String),
                builder:(context,membersSnapshot){
                  final rows=membersSnapshot.data??const [];
                  final names=rows
                      .where((r) => r['user_id'] != user.id)
                      .map((r) => (r['display_name'] as String? ?? '').trim())
                      .where((n) => n.isNotEmpty)
                      .toList();
                  final title=(c['name'] as String? ?? '').trim().isNotEmpty ? c['name'] as String : (names.isNotEmpty?names.join(', '):'Conversation');
                  return ListTile(leading:const CircleAvatar(child:Icon(Icons.person)),title:Text(title),subtitle:Text(c['is_group']==true?'Groupe':'Discussion privée'),trailing:const Icon(Icons.chevron_right),onTap:()=>Navigator.of(context).push(MaterialPageRoute(builder:(_)=>ChatPage(conversationId:c['id'] as String,title:title))));
                },
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(onPressed:()=>Navigator.of(context).push(MaterialPageRoute(builder:(_)=>const MembersPage())),icon:const Icon(Icons.chat),label:const Text('Nouveau chat')),
    );
  }
}