import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/auth_service.dart';
import '../widgets/biic_brand.dart';

enum _AuthMode { signIn, register, verifySignup, forgotPassword, verifyReset, setNewPassword }

class AuthPage extends StatefulWidget {
  const AuthPage({super.key});
  @override State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  final _phone=TextEditingController(),_password=TextEditingController(),_confirmPassword=TextEditingController(),_name=TextEditingController(),_otp=TextEditingController();
  final _auth=AuthService();
  _AuthMode _mode=_AuthMode.signIn;
  bool _loading=false,_obscurePassword=true;
  String _pendingPhone='';

  bool get _isRegister=>_mode==_AuthMode.register;
  bool get _isVerify=>_mode==_AuthMode.verifySignup||_mode==_AuthMode.verifyReset;

  String _normalizePhone(String value) {
    final raw=value.trim().replaceAll(RegExp(r'[\s().-]'),'');
    if(raw.startsWith('00')) return '+${raw.substring(2)}';
    if(raw.startsWith('+')) return raw;
    if(raw.startsWith('0')) return '+225${raw.substring(1)}';
    return '+225$raw';
  }

  bool _isValidIvorianPhone(String phone) {
    if (!phone.startsWith('+225') || phone.length != 14) return false;
    final national = phone.substring(4);
    final prefixOk = national.startsWith('01') || national.startsWith('05') || national.startsWith('07');
    return prefixOk && int.tryParse(national.substring(2)) != null;
  }

  Future<void> _openLegal(String page) async {
    final uri = Uri.parse('https://sesmanelebiicrouge.github.io/BIIC-CHAT-SBR/$page');
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  void _message(String text){if(mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text(text)));}

  Future<void> _submit() async {
    if(_isVerify){await _verifyCode();return;}
    if(_mode==_AuthMode.setNewPassword){await _saveNewPassword();return;}
    final phone=_normalizePhone(_phone.text);
    if(!_isValidIvorianPhone(phone)){_message('Entrez un numéro ivoirien valide, par exemple 07 00 00 00 00.');return;}
    if(_mode==_AuthMode.forgotPassword){
      setState(()=>_loading=true);
      try{await _auth.requestPasswordReset(phone);_pendingPhone=phone;_otp.clear();setState(()=>_mode=_AuthMode.verifyReset);_message('Le code de validation a été envoyé par SMS.');}
      catch(e){_message(AuthService.readableError(e));}
      finally{if(mounted)setState(()=>_loading=false);}
      return;
    }
    if(_password.text.length<6){_message('Le mot de passe doit contenir au moins 6 caractères.');return;}
    if(_isRegister&&_password.text!=_confirmPassword.text){_message('Les deux mots de passe ne correspondent pas.');return;}
    if(_isRegister&&(_name.text.trim().length<2||_name.text.trim().length>60)){_message('Le nom doit contenir entre 2 et 60 caractères.');return;}
    setState(()=>_loading=true);
    try{
      if(_isRegister){
        final response = await _auth.signUp(phone:phone,password:_password.text,displayName:_name.text);
        if(!mounted)return;
        if(response.session!=null){_message('Compte créé. Bienvenue sur BIIC CHAT.');}
        else{_pendingPhone=phone;_otp.clear();setState(()=>_mode=_AuthMode.verifySignup);_message('Un code à 6 chiffres a été envoyé par SMS.');}
      }else{await _auth.signIn(phone:phone,password:_password.text);}
    }catch(e){_message(AuthService.readableError(e));}
    finally{if(mounted)setState(()=>_loading=false);}
  }

  Future<void> _verifyCode() async {
    final code=_otp.text.trim();
    if(!RegExp(r'^\d{6}$').hasMatch(code)){_message('Entrez le code SMS à 6 chiffres.');return;}
    setState(()=>_loading=true);
    try{
      if (_mode == _AuthMode.verifyReset) {
        await _auth.verifyPasswordResetCode(phone: _pendingPhone, token: code);
      } else {
        await _auth.verifySignupCode(phone: _pendingPhone, token: code);
      }
      if(_mode==_AuthMode.verifyReset){_password.clear();_confirmPassword.clear();setState(()=>_mode=_AuthMode.setNewPassword);_message('Numéro vérifié. Choisissez maintenant votre nouveau mot de passe.');}
      else{_message('Numéro vérifié. Bienvenue sur BIIC CHAT.');}
    }catch(e){_message(AuthService.readableError(e));}
    finally{if(mounted)setState(()=>_loading=false);}
  }

  Future<void> _saveNewPassword() async {
    if(_password.text.length<6||_password.text!=_confirmPassword.text){_message('Choisissez un mot de passe d’au moins 6 caractères et confirmez-le.');return;}
    setState(()=>_loading=true);
    try{await _auth.updatePassword(_password.text);_message('Mot de passe modifié. Vous êtes connecté.');}
    catch(e){_message(AuthService.readableError(e));}
    finally{if(mounted)setState(()=>_loading=false);}
  }

  Future<void> _resendCode() async {
    if(_pendingPhone.isEmpty)return;
    setState(()=>_loading=true);
    try{await _auth.resendSignupCode(_pendingPhone);_message('Un nouveau code a été envoyé.');}
    catch(e){_message(AuthService.readableError(e));}
    finally{if(mounted)setState(()=>_loading=false);}
  }

  void _switchMode(_AuthMode mode){setState((){_mode=mode;_otp.clear();if(mode==_AuthMode.signIn||mode==_AuthMode.register){_password.clear();_confirmPassword.clear();}});}

  String get _title=>switch(_mode){
    _AuthMode.signIn=>'Se connecter',_AuthMode.register=>'Créer votre compte',_AuthMode.verifySignup=>'Vérifier votre numéro',
    _AuthMode.forgotPassword=>'Mot de passe oublié',_AuthMode.verifyReset=>'Code de récupération',_AuthMode.setNewPassword=>'Nouveau mot de passe'};
  String get _subtitle{
    if(_isVerify)return 'Entrez le code à 6 chiffres reçu par SMS.';
    if(_mode==_AuthMode.setNewPassword)return 'Choisissez un nouveau mot de passe pour votre compte.';
    return _isRegister?'Créez votre compte BIIC CHAT avec votre numéro de téléphone.':'Connectez-vous avec votre numéro et votre mot de passe.';
  }
  InputDecoration _decoration(String label,IconData icon)=>InputDecoration(labelText:label,prefixIcon:Icon(icon));

@override
  Widget build(BuildContext context) {
    final content = <Widget>[
      const BiicBrand(iconSize: 72),
      const SizedBox(height: 10),
      Text(_title, style: const TextStyle(fontSize: 23, fontWeight: FontWeight.w800), textAlign: TextAlign.center),
      const SizedBox(height: 7),
      Text(_subtitle, textAlign: TextAlign.center, style: const TextStyle(color: Color(0xFF777777))),
      const SizedBox(height: 24),
      if (_isVerify) ...[
        Text('Numéro : $_pendingPhone', style: const TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 14),
        TextField(
          controller: _otp,
          keyboardType: TextInputType.number,
          maxLength: 6,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 25, fontWeight: FontWeight.w800, letterSpacing: 8),
          decoration: _decoration('Code SMS', Icons.sms_outlined).copyWith(counterText: ''),
        ),
      ] else if (_mode == _AuthMode.setNewPassword) ...[
        TextField(
          controller: _password,
          obscureText: _obscurePassword,
          decoration: _decoration('Nouveau mot de passe', Icons.lock_outline).copyWith(
            suffixIcon: IconButton(
              onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
              icon: Icon(_obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined),
            ),
          ),
        ),
        const SizedBox(height: 12),
        TextField(controller: _confirmPassword, obscureText: true, decoration: _decoration('Confirmer le mot de passe', Icons.lock_reset_outlined)),
      ] else ...[
        if (_isRegister) ...[
          TextField(controller: _name, decoration: _decoration('Nom affiché', Icons.person_outline)),
          const SizedBox(height: 12),
        ],
        TextField(
          controller: _phone,
          keyboardType: TextInputType.phone,
          decoration: _decoration('Numéro de téléphone', Icons.phone_outlined).copyWith(hintText: '+225 07 00 00 00 00'),
        ),
        if (_mode != _AuthMode.forgotPassword) ...[
          const SizedBox(height: 12),
          TextField(
            controller: _password,
            obscureText: _obscurePassword,
            decoration: _decoration('Mot de passe', Icons.lock_outline).copyWith(
              suffixIcon: IconButton(
                onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                icon: Icon(_obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined),
              ),
            ),
          ),
          if (_isRegister) ...[
            const SizedBox(height: 12),
            TextField(controller: _confirmPassword, obscureText: true, decoration: _decoration('Confirmer le mot de passe', Icons.lock_reset_outlined)),
          ],
        ],
      ],
      const SizedBox(height: 18),
      SizedBox(
        width: double.infinity,
        child: FilledButton(
          onPressed: _loading ? null : _submit,
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFFD71920),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 14),
          ),
          child: Text(_loading ? 'Chargement...' : _buttonText),
        ),
      ),
      if (_isVerify) TextButton(onPressed: _loading ? null : _resendCode, child: const Text('Renvoyer le code')),
      if (_mode == _AuthMode.signIn) TextButton(onPressed: _loading ? null : () => _switchMode(_AuthMode.forgotPassword), child: const Text('Mot de passe oublié ?')),
      if (_mode == _AuthMode.signIn || _mode == _AuthMode.register)
        TextButton(onPressed: _loading ? null : () => _switchMode(_isRegister ? _AuthMode.signIn : _AuthMode.register), child: Text(_isRegister ? 'J’ai déjà un compte' : 'Créer un compte')),
      if (_mode == _AuthMode.forgotPassword || _mode == _AuthMode.setNewPassword)
        TextButton(onPressed: _loading ? null : () => _switchMode(_AuthMode.signIn), child: const Text('Retour à la connexion')),
      const SizedBox(height: 8),
      Wrap(
        alignment: WrapAlignment.center,
        children: [
          TextButton(onPressed: () => _openLegal('privacy.html'), child: const Text('Confidentialité')),
          TextButton(onPressed: () => _openLegal('terms.html'), child: const Text('Conditions d’utilisation')),
        ],
      ),
    ];

    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFFFF3F3), Color(0xFFF8F8F8)],
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 430),
              child: Card(
                elevation: 0,
                child: Padding(
                  padding: const EdgeInsets.all(26),
                  child: Column(children: content),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  String get _buttonText=>switch(_mode){
    _AuthMode.signIn=>'Se connecter',_AuthMode.register=>'Créer mon compte',_AuthMode.verifySignup||_AuthMode.verifyReset=>'Vérifier le code',
    _AuthMode.forgotPassword=>'Envoyer le code',_AuthMode.setNewPassword=>'Enregistrer le mot de passe'};

  @override void dispose(){_phone.dispose();_password.dispose();_confirmPassword.dispose();_name.dispose();_otp.dispose();super.dispose();}
}
).hasMatch(phone);

  Future<void> _openLegal(String page) async {
    final uri = Uri.parse('https://sesmanelebiicrouge.github.io/BIIC-CHAT-SBR/$page');
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  void _message(String text){if(mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text(text)));}

  Future<void> _submit() async {
    if(_isVerify){await _verifyCode();return;}
    if(_mode==_AuthMode.setNewPassword){await _saveNewPassword();return;}
    final phone=_normalizePhone(_phone.text);
    if(phone.length<10){_message('Entrez un numéro de téléphone valide.');return;}
    if(_mode==_AuthMode.forgotPassword){
      setState(()=>_loading=true);
      try{await _auth.requestPasswordReset(phone);_pendingPhone=phone;_otp.clear();setState(()=>_mode=_AuthMode.verifyReset);_message('Le code de validation a été envoyé par SMS.');}
      catch(e){_message(AuthService.readableError(e));}
      finally{if(mounted)setState(()=>_loading=false);}
      return;
    }
    if(_password.text.length<6){_message('Le mot de passe doit contenir au moins 6 caractères.');return;}
    if(_isRegister&&_password.text!=_confirmPassword.text){_message('Les deux mots de passe ne correspondent pas.');return;}
    if(_isRegister&&_name.text.trim().isEmpty){_message('Entrez votre nom.');return;}
    setState(()=>_loading=true);
    try{
      if(_isRegister){
        await _auth.signUp(phone:phone,password:_password.text,displayName:_name.text);
        _pendingPhone=phone;_otp.clear();setState(()=>_mode=_AuthMode.verifySignup);_message('Un code à 6 chiffres a été envoyé par SMS.');
      }else{await _auth.signIn(phone:phone,password:_password.text);}
    }catch(e){_message(AuthService.readableError(e));}
    finally{if(mounted)setState(()=>_loading=false);}
  }

  Future<void> _verifyCode() async {
    final code=_otp.text.trim();
    if(!RegExp(r'^\d{6}$').hasMatch(code)){_message('Entrez le code SMS à 6 chiffres.');return;}
    setState(()=>_loading=true);
    try{
      if (_mode == _AuthMode.verifyReset) {
        await _auth.verifyPasswordResetCode(phone: _pendingPhone, token: code);
      } else {
        await _auth.verifyPhone(phone: _pendingPhone, token: code);
      }
      if(_mode==_AuthMode.verifyReset){_password.clear();_confirmPassword.clear();setState(()=>_mode=_AuthMode.setNewPassword);_message('Numéro vérifié. Choisissez maintenant votre nouveau mot de passe.');}
      else{_message('Numéro vérifié. Bienvenue sur BIIC CHAT.');}
    }catch(e){_message(AuthService.readableError(e));}
    finally{if(mounted)setState(()=>_loading=false);}
  }

  Future<void> _saveNewPassword() async {
    if(_password.text.length<6||_password.text!=_confirmPassword.text){_message('Choisissez un mot de passe d’au moins 6 caractères et confirmez-le.');return;}
    setState(()=>_loading=true);
    try{await _auth.updatePassword(_password.text);_message('Mot de passe modifié. Vous êtes connecté.');}
    catch(e){_message(AuthService.readableError(e));}
    finally{if(mounted)setState(()=>_loading=false);}
  }

  Future<void> _resendCode() async {
    if(_pendingPhone.isEmpty)return;
    setState(()=>_loading=true);
    try{await _auth.resendPhoneCode(_pendingPhone);_message('Un nouveau code a été envoyé.');}
    catch(e){_message(AuthService.readableError(e));}
    finally{if(mounted)setState(()=>_loading=false);}
  }

  void _switchMode(_AuthMode mode){setState((){_mode=mode;_otp.clear();if(mode==_AuthMode.signIn||mode==_AuthMode.register){_password.clear();_confirmPassword.clear();}});}

  String get _title=>switch(_mode){
    _AuthMode.signIn=>'Se connecter',_AuthMode.register=>'Créer votre compte',_AuthMode.verifySignup=>'Vérifier votre numéro',
    _AuthMode.forgotPassword=>'Mot de passe oublié',_AuthMode.verifyReset=>'Code de récupération',_AuthMode.setNewPassword=>'Nouveau mot de passe'};
  String get _subtitle{
    if(_isVerify)return 'Entrez le code à 6 chiffres reçu par SMS.';
    if(_mode==_AuthMode.setNewPassword)return 'Choisissez un nouveau mot de passe pour votre compte.';
    return _isRegister?'Créez votre compte BIIC CHAT avec votre numéro de téléphone.':'Connectez-vous avec votre numéro et votre mot de passe.';
  }
  InputDecoration _decoration(String label,IconData icon)=>InputDecoration(labelText:label,prefixIcon:Icon(icon));

@override
  Widget build(BuildContext context) {
    final content = <Widget>[
      const BiicBrand(iconSize: 72),
      const SizedBox(height: 10),
      Text(_title, style: const TextStyle(fontSize: 23, fontWeight: FontWeight.w800), textAlign: TextAlign.center),
      const SizedBox(height: 7),
      Text(_subtitle, textAlign: TextAlign.center, style: const TextStyle(color: Color(0xFF777777))),
      const SizedBox(height: 24),
      if (_isVerify) ...[
        Text('Numéro : $_pendingPhone', style: const TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 14),
        TextField(
          controller: _otp,
          keyboardType: TextInputType.number,
          maxLength: 6,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 25, fontWeight: FontWeight.w800, letterSpacing: 8),
          decoration: _decoration('Code SMS', Icons.sms_outlined).copyWith(counterText: ''),
        ),
      ] else if (_mode == _AuthMode.setNewPassword) ...[
        TextField(
          controller: _password,
          obscureText: _obscurePassword,
          decoration: _decoration('Nouveau mot de passe', Icons.lock_outline).copyWith(
            suffixIcon: IconButton(
              onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
              icon: Icon(_obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined),
            ),
          ),
        ),
        const SizedBox(height: 12),
        TextField(controller: _confirmPassword, obscureText: true, decoration: _decoration('Confirmer le mot de passe', Icons.lock_reset_outlined)),
      ] else ...[
        if (_isRegister) ...[
          TextField(controller: _name, decoration: _decoration('Nom affiché', Icons.person_outline)),
          const SizedBox(height: 12),
        ],
        TextField(
          controller: _phone,
          keyboardType: TextInputType.phone,
          decoration: _decoration('Numéro de téléphone', Icons.phone_outlined).copyWith(hintText: '+225 07 00 00 00 00'),
        ),
        if (_mode != _AuthMode.forgotPassword) ...[
          const SizedBox(height: 12),
          TextField(
            controller: _password,
            obscureText: _obscurePassword,
            decoration: _decoration('Mot de passe', Icons.lock_outline).copyWith(
              suffixIcon: IconButton(
                onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                icon: Icon(_obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined),
              ),
            ),
          ),
          if (_isRegister) ...[
            const SizedBox(height: 12),
            TextField(controller: _confirmPassword, obscureText: true, decoration: _decoration('Confirmer le mot de passe', Icons.lock_reset_outlined)),
          ],
        ],
      ],
      const SizedBox(height: 18),
      SizedBox(
        width: double.infinity,
        child: FilledButton(
          onPressed: _loading ? null : _submit,
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFFD71920),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 14),
          ),
          child: Text(_loading ? 'Chargement...' : _buttonText),
        ),
      ),
      if (_isVerify) TextButton(onPressed: _loading ? null : _resendCode, child: const Text('Renvoyer le code')),
      if (_mode == _AuthMode.signIn) TextButton(onPressed: _loading ? null : () => _switchMode(_AuthMode.forgotPassword), child: const Text('Mot de passe oublié ?')),
      if (_mode == _AuthMode.signIn || _mode == _AuthMode.register)
        TextButton(onPressed: _loading ? null : () => _switchMode(_isRegister ? _AuthMode.signIn : _AuthMode.register), child: Text(_isRegister ? 'J’ai déjà un compte' : 'Créer un compte')),
      if (_mode == _AuthMode.forgotPassword || _mode == _AuthMode.setNewPassword)
        TextButton(onPressed: _loading ? null : () => _switchMode(_AuthMode.signIn), child: const Text('Retour à la connexion')),
      const SizedBox(height: 8),
      Wrap(
        alignment: WrapAlignment.center,
        children: [
          TextButton(onPressed: () => _openLegal('privacy.html'), child: const Text('Confidentialité')),
          TextButton(onPressed: () => _openLegal('terms.html'), child: const Text('Conditions d’utilisation')),
        ],
      ),
    ];

    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFFFF3F3), Color(0xFFF8F8F8)],
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 430),
              child: Card(
                elevation: 0,
                child: Padding(
                  padding: const EdgeInsets.all(26),
                  child: Column(children: content),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  String get _buttonText=>switch(_mode){
    _AuthMode.signIn=>'Se connecter',_AuthMode.register=>'Créer mon compte',_AuthMode.verifySignup||_AuthMode.verifyReset=>'Vérifier le code',
    _AuthMode.forgotPassword=>'Envoyer le code',_AuthMode.setNewPassword=>'Enregistrer le mot de passe'};

  @override void dispose(){_phone.dispose();_password.dispose();_confirmPassword.dispose();_name.dispose();_otp.dispose();super.dispose();}
}
