import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'backend_config.dart';
import 'features/home/beela_shell.dart';

const gold = Color(0xFFFFD36A);
const gold2 = Color(0xFFB77921);
const bg = Color(0xFF090604);

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
    url: BackendConfig.supabaseUrl,
    publishableKey: BackendConfig.supabasePublishableKey,
    authOptions: FlutterAuthClientOptions(
      authFlowType: kIsWeb ? AuthFlowType.implicit : AuthFlowType.pkce,
    ),
  );
  runApp(const AsmarApp());
}

class AsmarApp extends StatelessWidget {
  const AsmarApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Asmar Chat',
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: bg,
        colorScheme: ColorScheme.fromSeed(seedColor: gold, brightness: Brightness.dark),
      ),
      home: const AuthGate(),
    );
  }
}

class LaunchPromotion extends StatefulWidget {
  const LaunchPromotion({super.key});
  @override
  State<LaunchPromotion> createState() => _LaunchPromotionState();
}

class _LaunchPromotionState extends State<LaunchPromotion> {
  void _enter(){
    Navigator.pushReplacement(context,MaterialPageRoute(builder:(_)=>const BeelaShell()));
  }
  @override Widget build(BuildContext context){
    return Scaffold(
      backgroundColor: bg,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('ASMAR CHAT', style: TextStyle(color: gold, fontSize: 30, fontWeight: FontWeight.w900)),
            const SizedBox(height: 30),
            FilledButton(onPressed: _enter, style: FilledButton.styleFrom(backgroundColor: gold), child: const Text('دخول إلى أسمر شات 🔥', style: TextStyle(color: Colors.black))),
          ],
        ),
      ),
    );
  }
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});
  @override Widget build(BuildContext context){
    final supabase=Supabase.instance.client;
    return StreamBuilder<AuthState>(
      stream:supabase.auth.onAuthStateChange,
      builder:(context,snapshot){
        if(supabase.auth.currentSession!=null) return const LaunchPromotion();
        return const LoginPage();
      }
    );
  }
}

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});
  @override State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final email = TextEditingController();
  final password = TextEditingController();
  bool loading = false;
  String? error;

  Future<void> _login() async {
    setState(() { loading = true; error = null; });
    try {
      await Supabase.instance.client.auth.signInWithPassword(email: email.text.trim(), password: password.text);
    } catch (e) {
      setState(() => error = 'خطأ بالدخول');
    } finally {
      setState(() => loading = false);
    }
  }

  @override Widget build(BuildContext context){
    return Scaffold(
      backgroundColor: bg,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('ASMAR CHAT', style: TextStyle(color: gold, fontSize: 28, fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
              TextField(controller: email, decoration: const InputDecoration(labelText: 'البريد')),
              const SizedBox(height: 10),
              TextField(controller: password, obscureText: true, decoration: const InputDecoration(labelText: 'كلمة المرور')),
              if(error!=null) Text(error!, style: const TextStyle(color: Colors.red)),
              const SizedBox(height: 20),
              FilledButton(onPressed: loading?null:_login, child: Text(loading?'...':'دخول')),
            ],
          ),
        ),
      ),
    );
  }
}
