import 'package:flutter/material.dart';
import '../services/block_report_service.dart';

class BlockedContactsPage extends StatefulWidget {
  const BlockedContactsPage({super.key});
  @override State<BlockedContactsPage> createState()=>_BlockedContactsPageState();
}
class _BlockedContactsPageState extends State<BlockedContactsPage>{
  final _service=BlockReportService(); Set<String> _ids=<String>{}; bool _loading=true;
  @override void initState(){super.initState();_load();}
  Future<void> _load() async{try{_ids=await _service.getBlockedUserIds();}catch(e){if(mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text(e.toString())));}finally{if(mounted)setState(()=>_loading=false);}}
  Future<void> _unblock(String id) async{try{await _service.unblockUser(id);setState(()=>_ids.remove(id));}catch(e){if(mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text(e.toString())));}}
  @override Widget build(BuildContext context)=>Scaffold(appBar:AppBar(title:const Text('Contacts bloqués')),body:_loading?const Center(child:CircularProgressIndicator()):_ids.isEmpty?const Center(child:Text('Aucun contact bloqué.')):ListView.separated(itemCount:_ids.length,separatorBuilder:(_,__)=>const Divider(height:1),itemBuilder:(context,index){final id=_ids.elementAt(index);return ListTile(leading:const CircleAvatar(child:Icon(Icons.person)),title:const Text('Utilisateur bloqué'),subtitle:Text(id,overflow:TextOverflow.ellipsis),trailing:TextButton(onPressed:()=>_unblock(id),child:const Text('Débloquer')));}));
}
