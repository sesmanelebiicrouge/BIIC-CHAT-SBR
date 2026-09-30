import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/conversation_service.dart';
import '../widgets/biic_brand.dart';
import 'members_page.dart';
import 'chat_page.dart';
import 'profile_page.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});
  @override Widget build(BuildContext context){
    final service=ConversationService(); final user=service.client.auth.currentUser;
    if(user==null)return const MembersPage();
    return Scaffold(
      appBar:AppBar(
        title:const BiicBrand(iconSize:36,showSubtitle:false),
        actions:[
          IconButton(tooltip:'Mon profil',onPressed:()=>Navigator.of(context).push(MaterialPageRoute(builder:(_)=>const ProfilePage())),icon:const Icon(Icons.account_circle_outlined)),
          IconButton(tooltip:'Nouveau chat',onPressed:()=>Navigator.of(context).push(MaterialPageRoute(builder:(_)=>const MembersPage())),icon:const Icon(Icons.person_add_alt_1)),
          IconButton(tooltip:'Déconnexion',onPressed:()=>AuthService().signOut(),icon:const Icon(Icons.logout)),
        ],
      ),
      body:StreamBuilder<List<Map<String,dynamic>>>(
        stream:service.getUserConversations(user.id),
        builder:(context,snapshot){
          if(snapshot.hasError)return Center(child:Padding(padding:const EdgeInsets.all(24),child:Text('Erreur : ${snapshot.error}')));
          final conversations=snapshot.data??const [];
          if(conversations.isEmpty)return Center(child:Padding(padding:const EdgeInsets.all(24),child:Column(mainAxisSize:MainAxisSize.min,children:[
            const BiicAvatar(label:'B',radius:38),
            const SizedBox(height:16),
            const Text('Aucune conversation',style:TextStyle(fontSize:20,fontWeight:FontWeight.w800)),
            const SizedBox(height:7),
            const Text('Commencez une nouvelle discussion avec un membre de BIIC CHAT.',textAlign:TextAlign.center,style:TextStyle(color:Color(0xFF777777))),
            const SizedBox(height:18),
            FilledButton.icon(onPressed:()=>Navigator.of(context).push(MaterialPageRoute(builder:(_)=>const MembersPage())),icon:const Icon(Icons.chat_rounded),label:const Text('Démarrer une discussion')),
          ])));
          return ListView.separated(
            padding:const EdgeInsets.only(top:8),
            itemCount:conversations.length,
            separatorBuilder:(_,__)=>const Divider(height:1,indent:78),
            itemBuilder:(context,index){
              final c=conversations[index];
              return FutureBuilder<List<Map<String,dynamic>>>(
                future:service.getConversationMembers(c['id'] as String),
                builder:(context,membersSnapshot){
                  final rows=membersSnapshot.data??const [];
                  final names=rows.where((r)=>r['user_id']!=user.id).map((r)=>(r['display_name'] as String???'').trim()).where((n)=>n.isNotEmpty).toList();
                  final title=(c['name'] as String???'').trim().isNotEmpty?c['name'] as String:(names.isNotEmpty?names.join(', '):'Conversation');
                  return ListTile(contentPadding:const EdgeInsets.symmetric(horizontal:16,vertical:7),leading:BiicAvatar(label:title,radius:27),title:Text(title,style:const TextStyle(fontWeight:FontWeight.w700)),subtitle:Text(c['is_group']==true?'Groupe':'Discussion privée'),trailing:const Icon(Icons.chevron_right),onTap:()=>Navigator.of(context).push(MaterialPageRoute(builder:(_)=>ChatPage(conversationId:c['id'] as String,title:title))));
                },
              );
            },
          );
        },
      ),
      floatingActionButton:FloatingActionButton.extended(onPressed:()=>Navigator.of(context).push(MaterialPageRoute(builder:(_)=>const MembersPage())),backgroundColor:const Color(0xFFD71920),foregroundColor:Colors.white,icon:const Icon(Icons.chat_rounded),label:const Text('Nouveau chat')),
    );
  }
}
