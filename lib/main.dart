import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'config/app_config.dart';
import 'pages/auth_page.dart';
import 'pages/home_page.dart';
import 'services/auth_service.dart';
import 'services/backend_service.dart';
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
      home: const BIICSplashGate(),
    );
  }
}

class BIICSplashGate extends StatefulWidget {
  const BIICSplashGate({super.key});

  @override
  State<BIICSplashGate> createState() => _BIICSplashGateState();
}

class _BIICSplashGateState extends State<BIICSplashGate> {
  @override
  void initState() {
    super.initState();
    Future<void>.delayed(const Duration(milliseconds: 1400), () {
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(
          builder: (_) => AppConfig.hasSupabaseConfig
              ? const AuthGate()
              : const ProductionConfigErrorPage(),
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF0175C2),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.all(Radius.circular(30)),
              child: SvgPicture.asset(
                'assets/biic_logo.svg',
                width: 150,
                height: 150,
              ),
            ),
            SizedBox(height: 28),
            Text(
              'BIENVENUE SUR BIIC CHAT',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontSize: 25,
                fontWeight: FontWeight.w800,
                letterSpacing: .4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ProductionConfigErrorPage extends StatelessWidget {
  const ProductionConfigErrorPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.cloud_off_rounded, size: 64, color: Color(0xFFD71920)),
              const SizedBox(height: 16),
              const Text(
                'BIIC CHAT est temporairement indisponible',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 10),
              const Text(
                'La configuration du serveur de production n’est pas disponible. '
                'Aucune donnée de démonstration ne sera affichée à la place du service réel.',
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
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
