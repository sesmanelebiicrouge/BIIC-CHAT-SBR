import 'package:flutter/material.dart';
import '../services/phone_registration_service.dart';

class PhoneRegistrationPage extends StatefulWidget {
 const PhoneRegistrationPage({super.key});
 @override State<PhoneRegistrationPage> createState()=>_PhoneRegistrationPageState();
}
class _PhoneRegistrationPageState extends State<PhoneRegistrationPage> {
 final service=PhoneRegistrationService();
 final phone=TextEditingController();
 final code=TextEditingController();
 bool sent=false, busy=false;
 String? status;
 void message(String s)=>ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text(s)));
 Future<void> request() async { setState(()=>busy=true); try { await service.requestCode(phone.text); setState(()=>sent=true); message('Code envoyé à votre e-mail enregistré.'); } catch(e) { message(e.toString()); } finally { if(mounted)setState(()=>busy=false); } }
 Future<void> verify() async { setState(()=>busy=true); try { await service.verifyCode(code.text); setState(()=>status=phone.text); message('Numéro validé.'); } catch(e) { message(e.toString()); } finally { if(mounted)setState(()=>busy=false); } }
 @override Widget build(BuildContext context)=>Scaffold(appBar:AppBar(title:const Text('Enregistrer mon numéro')),body:Padding(padding:const EdgeInsets.all(20),child:Column(children:[TextField(controller:phone,decoration:const InputDecoration(labelText:'Numéro de téléphone')),if(sent)TextField(controller:code,decoration:const InputDecoration(labelText:'Code reçu par e-mail')),if(status!=null)Text('Numéro validé : $status'),FilledButton(onPressed:busy?null:(sent?verify:request),child:Text(sent?'Valider le code':'Recevoir le code par e-mail'))])));
 @override void dispose(){phone.dispose();code.dispose();super.dispose();}
}
