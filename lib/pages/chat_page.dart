import 'package:flutter/material.dart';
import '../services/conversation_service.dart';

class ChatPage extends StatefulWidget {
  final String conversationId;
  final String title;
  const ChatPage({super.key, required this.conversationId, required this.title});
  @override State<ChatPage> createState() => _ChatPageState();
}
class _ChatPageState extends State<ChatPage> {
  final _service = ConversationService();
  final _controller = TextEditingController();
  bool _sending = false;
  Future<void> _send() async {
    final text = _controller.text.trim();
    final user = _service.client.auth.currentUser;
    if (text.isEmpty || user == null) return;
    setState(() => _sending = true);
    try { await _service.sendMessage(conversationId: widget.conversationId, senderId: user.id, content: text); _controller.clear(); }
    catch (e) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString()))); }
    finally { if (mounted) setState(() => _sending = false); }
  }
  @override Widget build(BuildContext context) {
    final userId = _service.client.auth.currentUser?.id;
    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: Column(children: [
        Expanded(child: StreamBuilder<List<Map<String,dynamic>>>(
          stream: _service.watchMessages(widget.conversationId),
          builder: (context, snapshot) {
            if (snapshot.hasError) return Center(child: Text('Erreur : ' + snapshot.error.toString()));
            final messages = snapshot.data ?? const [];
            if (messages.isEmpty) return const Center(child: Text('Aucun message. Écrivez le premier !'));
            return ListView.builder(padding: const EdgeInsets.all(16), itemCount: messages.length, itemBuilder: (context,index) {
              final message=messages[index]; final mine=message['sender_id']==userId;
              return Align(alignment: mine?Alignment.centerRight:Alignment.centerLeft,child:Container(margin:const EdgeInsets.only(bottom:8),padding:const EdgeInsets.symmetric(horizontal:14,vertical:10),constraints:BoxConstraints(maxWidth:MediaQuery.sizeOf(context).width*.78),decoration:BoxDecoration(color:mine?Theme.of(context).colorScheme.primary:Theme.of(context).colorScheme.surfaceContainerHighest,borderRadius:BorderRadius.circular(18)),child:Text(message['content'] as String? ?? '',style:TextStyle(color:mine?Theme.of(context).colorScheme.onPrimary:null)));
            });
          },
        )),
        SafeArea(child: Padding(padding:const EdgeInsets.all(8),child:Row(children:[
          Expanded(child:TextField(controller:_controller,minLines:1,maxLines:4,textInputAction:TextInputAction.send,onSubmitted:(_)=>_send(),decoration:const InputDecoration(hintText:'Écrire un message...',border:OutlineInputBorder()))),
          const SizedBox(width:8),
          IconButton.filled(onPressed:_sending?null:_send,icon:_sending?const SizedBox(width:18,height:18,child:CircularProgressIndicator(strokeWidth:2)):const Icon(Icons.send)),
        ]))),
      ]),
    );
  }
  @override void dispose(){_controller.dispose();super.dispose();}
}