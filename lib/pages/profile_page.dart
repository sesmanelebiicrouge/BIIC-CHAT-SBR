import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/profile_service.dart';

class ProfilePage extends StatefulWidget { const ProfilePage({super.key}); @override State<ProfilePage> createState()=>_ProfilePageState(); }
class _ProfilePageState extends State<ProfilePage> {
  final _service=ProfileService();
  final _name=TextEditingController(); final _bio=TextEditingController();
  String _status='offline'; String? _avatarUrl; bool _loading=true; bool _saving=false;
  @override void initState(){super.initState(); _load();}
  Future<void> _load() async { try { final p=await _service.getMyProfile(); _name.text=p['display_name'] as String? ?? ''; _bio.text=p['bio'] as String? ?? ''; _status=p['status'] as String? ?? 'offline'; _avatarUrl=await _service.createAvatarSignedUrl(p['avatar_url'] as String?); } catch(e){ if(mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text(e.toString()))); } finally { if(mounted)setState(()=>_loading=false); } }
  Future<void> _avatar() async { final file=await ImagePicker().pickImage(source:ImageSource.gallery,maxWidth:1200,maxHeight:1200,imageQuality:85); if(file==null)return; try { final bytes=await file.readAsBytes(); final path=await _service.uploadAvatar(bytes,fileName:file.name); final url=await _service.createAvatarSignedUrl(path); if(mounted)setState(()=>_avatarUrl=url); } catch(e){ if(mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text(e.toString()))); } }
  Future<void> _save() async { setState(()=>_saving=true); try { await _service.updateProfile(displayName:_name.text,bio:_bio.text,status:_status); if(mounted)ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('Profil enregistré.'))); } catch(e){ if(mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text(e.toString()))); } finally { if(mounted)setState(()=>_saving=false); } }
  @override Widget build(BuildContext context){ if(_loading)return const Scaffold(body:Center(child:CircularProgressIndicator())); return Scaffold(appBar:AppBar(title:const Text('Mon profil')),body:ListView(padding:const EdgeInsets.all(20),children:[
    Center(child:Stack(children:[CircleAvatar(radius:52,backgroundImage:_avatarUrl==null?null:NetworkImage(_avatarUrl!),child:_avatarUrl==null?const Icon(Icons.person,size:52):null),Positioned(right:0,bottom:0,child:IconButton.filled(onPressed:_avatar,icon:const Icon(Icons.camera_alt),tooltip:'Changer la photo'))])),
    const SizedBox(height:24), TextField(controller:_name,maxLength:60,decoration:const InputDecoration(labelText:'Nom affiché',prefixIcon:Icon(Icons.person_outline),border:OutlineInputBorder())),
    const SizedBox(height:12), TextField(controller:_bio,maxLength:280,maxLines:4,decoration:const InputDecoration(labelText:'Bio',prefixIcon:Icon(Icons.info_outline),border:OutlineInputBorder())),
    const SizedBox(height:12), DropdownButtonFormField<String>(initialValue:_status,decoration:const InputDecoration(labelText:'Statut',border:OutlineInputBorder()),items:const [DropdownMenuItem(value:'online',child:Text('En ligne')),DropdownMenuItem(value:'away',child:Text('Absent')),DropdownMenuItem(value:'busy',child:Text('Occupé')),DropdownMenuItem(value:'offline',child:Text('Hors ligne'))],onChanged:(v){if(v!=null)setState(()=>_status=v);}),
    const SizedBox(height:24), FilledButton.icon(onPressed:_saving?null:_save,icon:_saving?const SizedBox(width:18,height:18,child:CircularProgressIndicator(strokeWidth:2)):const Icon(Icons.save),label:const Text('Enregistrer'))
  ])); }
  @override void dispose(){_name.dispose();_bio.dispose();super.dispose();}
}