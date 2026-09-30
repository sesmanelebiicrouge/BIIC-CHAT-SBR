import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../widgets/biic_brand.dart';

class AuthPage extends StatefulWidget {
  const AuthPage({super.key});
  @override State<AuthPage> createState()=>_AuthPageState();
}
class _AuthPageState extends State<AuthPage> {
  final _email=TextEditingController(),_password=TextEditingController(),_name=TextEditingController();
  final _auth=AuthService();
  bool _register=false,_loading=false;

  Future<void> _submit() async {
    if(_email.text.trim().isEmpty||_password.text.isEmpty||(_register&&_name.text.trim().isEmpty))return;
    setState(()=>_loading=true);
    try{
      if(_register){
        await _auth.signUp(email:_email.text,password:_password.text,displayName:_name.text);
        if(mounted)ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('Compte créé. Vérifiez votre e-mail si nécessaire.')));
      }else{await _auth.signIn(email:_email.text,password:_password.text);}
    }catch(e){if(mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text(e.toString())));}
    finally{if(mounted)setState(()=>_loading=false);}
  }

  Future<void> _resetPassword() async {
    final email=_email.text.trim();
    if(email.isEmpty){ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('Saisissez votre e-mail d’abord.')));return;}
    try{await _auth.resetPassword(email);if(mounted)ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('Un e-mail de récupération a été demandé.')));}
    catch(e){if(mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text(e.toString())));}
  }

  @override Widget build(BuildContext context){
    return Scaffold(
      body:DecoratedBox(
        decoration:const BoxDecoration(gradient:LinearGradient(begin:Alignment.topCenter,end:Alignment.bottomCenter,colors:[Color(0xFFFFF3F3),Color(0xFFF8F8F8)])),
        child:Center(child:SingleChildScrollView(
          padding:const EdgeInsets.all(24),
          child:ConstrainedBox(
            constraints:const BoxConstraints(maxWidth:430),
            child:Card(
              elevation:0,
              child:Padding(
                padding:const EdgeInsets.all(26),
                child:Column(children:[
                  const BiicBrand(iconSize:64),
                  const SizedBox(height:10),
                  Text(_register?'Créer votre compte':'Bienvenue sur BIIC CHAT',style:const TextStyle(fontSize:23,fontWeight:FontWeight.w800),textAlign:TextAlign.center),
                  const SizedBox(height:7),
                  const Text('Discutez, partagez et restez connecté.',textAlign:TextAlign.center,style:TextStyle(color:Color(0xFF777777))),
                  const SizedBox(height:24),
                  if(_register)TextField(controller:_name,decoration:const InputDecoration(labelText:'Nom affiché',prefixIcon:Icon(Icons.person_outline))),
                  if(_register)const SizedBox(height:12),
                  TextField(controller:_email,keyboardType:TextInputType.emailAddress,decoration:const InputDecoration(labelText:'E-mail',prefixIcon:Icon(Icons.email_outlined))),
                  const SizedBox(height:12),
                  TextField(controller:_password,obscureText:true,decoration:const InputDecoration(labelText:'Mot de passe',prefixIcon:Icon(Icons.lock_outline))),
                  const SizedBox(height:18),
                  SizedBox(width:double.infinity,child:FilledButton(onPressed:_loading?null:_submit,style:FilledButton.styleFrom(backgroundColor:const Color(0xFFD71920),foregroundColor:Colors.white,padding:const EdgeInsets.symmetric(vertical:14)),child:Text(_loading?'Chargement...':(_register?'Créer mon compte':'Se connecter')))),
                  if(!_register)TextButton(onPressed:_loading?null:_resetPassword,child:const Text('Mot de passe oublié ?')),
                  TextButton(onPressed:_loading?null:()=>setState(()=>_register=!_register),child:Text(_register?'J’ai déjà un compte':'Créer un compte')),
                ]),
              ),
            ),
          ),
        )),
      ),
    );
  }
  @override void dispose(){_email.dispose();_password.dispose();_name.dispose();super.dispose();}
}
