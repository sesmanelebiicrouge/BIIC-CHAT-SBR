import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../services/auth_service.dart';
import '../widgets/biic_brand.dart';
import 'profile_page.dart';
import 'blocked_contacts_page.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});
  @override State<SettingsPage> createState()=>_SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final _code=TextEditingController();
  final _auth=AuthService();
  bool _loading=false;
  String? _factorId;
  String? _qrCode;
  String? _secret;
  String? _pendingPhone;

  void _message(String text)=>ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text(text)));

  Future<void> _changePhone() async {
    final controller=TextEditingController();
    final value=await showDialog<String>(context:context,builder:(context)=>AlertDialog(
      title:const Text('Changer de numéro'),
      content:TextField(controller:controller,keyboardType:TextInputType.phone,decoration:const InputDecoration(labelText:'Nouveau numéro',hintText:'+225 07 00 00 00 00')),
      actions:[TextButton(onPressed:()=>Navigator.pop(context),child:const Text('Annuler')),FilledButton(onPressed:()=>Navigator.pop(context,controller.text),child:const Text('Continuer'))],
    ));
    controller.dispose();
    if(value==null||value.trim().isEmpty)return;
    var phone=value.trim().replaceAll(RegExp(r'[\s-]'),'');
    if(phone.startsWith('00'))phone='+${phone.substring(2)}';
    if(phone.startsWith('0'))phone='+225${phone.substring(1)}';
    if(!phone.startsWith('+'))phone='+225$phone';
    setState(()=>_loading=true);
    try{await _auth.changePhone(phone);_message('Un code SMS a été envoyé à '+phone+'. Validez-le pour confirmer le changement.');}
    catch(e){_message('Impossible de changer le numéro : $e');}
    finally{if(mounted)setState(()=>_loading=false);}
  }

  Future<void> _confirmPhoneChange(String phone) async {
    final controller=TextEditingController();
    final value=await showDialog<String>(context:context,builder:(context)=>AlertDialog(
      title:const Text('Valider le nouveau numéro'),
      content:TextField(controller:controller,keyboardType:TextInputType.number,maxLength:6,textAlign:TextAlign.center,decoration:const InputDecoration(labelText:'Code SMS à 6 chiffres')),
      actions:[TextButton(onPressed:()=>Navigator.pop(context),child:const Text('Plus tard')),FilledButton(onPressed:()=>Navigator.pop(context,controller.text),child:const Text('Valider'))],
    ));
    controller.dispose();
    if(value==null||value.trim().isEmpty)return;
    try{await _auth.verifyPhoneChange(phone:phone,token:value);_message('Numéro de téléphone mis à jour.');}
    catch(e){_message('Code incorrect ou expiré : \$e');}
  }

  Future<void> _setup2FA() async {
    setState(()=>_loading=true);
    try{
      final result=await _auth.enrollTotp(friendlyName:'BIIC CHAT');
      _factorId=result.id;_qrCode=result.totp.qrCode;_secret=result.totp.secret;_code.clear();
      if(mounted)showDialog(context:context,builder:(context)=>AlertDialog(
        title:const Text('Sécurité renforcée'),
        content:SingleChildScrollView(child:Column(mainAxisSize:MainAxisSize.min,children:[
          const Text('Scannez ce QR code avec Google Authenticator, Microsoft Authenticator ou une application TOTP.'),
          const SizedBox(height:16),if(_qrCode!=null)QrImageView(data:_qrCode!,size:210),
          const SizedBox(height:8),const Text('Clé secrète de secours :'),const SizedBox(height:6),
          SelectableText(_secret??'',textAlign:TextAlign.center,style:const TextStyle(fontWeight:FontWeight.w700)),
          const SizedBox(height:14),TextField(controller:_code,keyboardType:TextInputType.number,maxLength:6,textAlign:TextAlign.center,decoration:const InputDecoration(labelText:'Code à 6 chiffres')),
        ])),
        actions:[TextButton(onPressed:()=>Navigator.pop(context),child:const Text('Annuler')),FilledButton(onPressed:_verify2FA,child:const Text('Activer'))],
      ));
    }catch(e){_message('Impossible de préparer la double authentification : $e');}
    finally{if(mounted)setState(()=>_loading=false);}
  }

  Future<void> _verify2FA() async {
    if(_factorId==null)return;
    try{await _auth.verifyTotp(factorId:_factorId!,code:_code.text);if(mounted){Navigator.pop(context);_message('Double authentification activée.');}}
    catch(e){_message('Code 2FA incorrect : $e');}
  }

  @override Widget build(BuildContext context){
    final user=_auth.currentSession?.user;
    return Scaffold(appBar:AppBar(title:const Text('Paramètres')),body:ListView(padding:const EdgeInsets.symmetric(vertical:8),children:[
      const ListTile(title:Text('Compte',style:TextStyle(fontSize:18,fontWeight:FontWeight.w800))),
      ListTile(leading:const Icon(Icons.person_outline),title:const Text('Profil'),subtitle:const Text('Photo, nom, bio et statut'),onTap:()=>Navigator.push(context,MaterialPageRoute(builder:(_)=>const ProfilePage()))),
      ListTile(leading:const Icon(Icons.phone_android),title:const Text('Changer de numéro'),subtitle:Text(user?.phone??'Numéro actuel'),onTap:_loading?null:_changePhone),
      const Divider(),
      const ListTile(title:Text('Conversations',style:TextStyle(fontSize:18,fontWeight:FontWeight.w800))),
      const ListTile(leading:Icon(Icons.chat_bubble_outline),title:Text('Paramètres des conversations'),subtitle:Text('Gérez les discussions depuis BIIC CHAT.')),
      const Divider(),
      const ListTile(title:Text('Confidentialité',style:TextStyle(fontSize:18,fontWeight:FontWeight.w800))),
      ListTile(leading:const Icon(Icons.block),title:const Text('Contacts bloqués'),subtitle:const Text('Gérer les personnes que vous avez bloquées'),onTap:()=>Navigator.push(context,MaterialPageRoute(builder:(_)=>const BlockedContactsPage()))),
      const Divider(),
      const ListTile(title:Text('Sécurité',style:TextStyle(fontSize:18,fontWeight:FontWeight.w800))),
      ListTile(leading:const Icon(Icons.qr_code_2),title:const Text('Double authentification'),subtitle:const Text('Configurer un QR code avec une application Authenticator'),onTap:_loading?null:_setup2FA),
      const Padding(padding:EdgeInsets.all(16),child:Text('Pour une connexion sur ordinateur par QR comme WhatsApp Web, il faudra ensuite un système dédié d’appareils liés. Le QR ci-dessus est destiné à la double authentification.',style:TextStyle(color:Color(0xFF777777)))),
      const Center(child:BiicBrand(iconSize:54,showSubtitle:false)),
    ]));
  }
  @override void dispose(){_code.dispose();super.dispose();}
}
