import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/auth/auth_repository.dart';
import 'core/backend/supabase_runtime.dart';
import 'core/rooms/real_rooms_home_page.dart';
import 'asmar_ayome_ui.dart';
import 'friends.dart';
import 'messages.dart';
import 'store.dart';
import 'wallet.dart';

class AsmarAppShell extends StatefulWidget {
  const AsmarAppShell({super.key});

  @override
  State<AsmarAppShell> createState() => _AsmarAppShellState();
}

class _AsmarAppShellState extends State<AsmarAppShell> {
  int index = 0;

  final pages = const <Widget>[
    RealRoomsHomePage(),
    MessagesPage(),
    FriendsPage(),
    StorePage(),
    WalletPage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        body: IndexedStack(index: index, children: pages),
        bottomNavigationBar: NavigationBar(
          selectedIndex: index,
          onDestinationSelected: (value) => setState(() => index = value),
          destinations: const [
            NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'الرئيسية'),
            NavigationDestination(icon: Icon(Icons.forum_outlined), selectedIcon: Icon(Icons.forum), label: 'الرسائل'),
            NavigationDestination(icon: Icon(Icons.people_outline), selectedIcon: Icon(Icons.people), label: 'الأصدقاء'),
            NavigationDestination(icon: Icon(Icons.storefront_outlined), selectedIcon: Icon(Icons.storefront), label: 'المتجر'),
            NavigationDestination(icon: Icon(Icons.account_balance_wallet_outlined), selectedIcon: Icon(Icons.account_balance_wallet), label: 'المحفظة'),
          ],
        ),
      ),
    );
  }
}

class AsmarAuthGate extends StatefulWidget {
  const AsmarAuthGate({super.key});

  @override
  State<AsmarAuthGate> createState() => _AsmarAuthGateState();
}

class _AsmarAuthGateState extends State<AsmarAuthGate> {
  late final Stream<AuthState> _authStream;
  bool _checkingSession = true;

  @override
  void initState() {
    super.initState();
    final auth = AuthRepository();
    _authStream = auth.authStateChanges;
    _checkingSession = SupabaseRuntime.currentUser == null;
  }

  @override
  Widget build(BuildContext context) {
    if (!SupabaseRuntime.isInitialized) {
      return const _BackendUnavailable();
    }

    return StreamBuilder<AuthState>(
      stream: _authStream,
      initialData: SupabaseRuntime.currentUser == null
          ? null
          : AuthState(AuthChangeEvent.initialSession, Supabase.instance.client.auth.currentSession),
      builder: (context, snapshot) {
        final session = snapshot.data?.session ?? SupabaseRuntime.client?.auth.currentSession;
        final signedIn = session?.user != null || SupabaseRuntime.currentUser != null;

        if (signedIn) {
          if (_checkingSession && mounted) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) setState(() => _checkingSession = false);
            });
          }
          return const AsmarAyomeShell();
        }

        if (_checkingSession && snapshot.connectionState == ConnectionState.waiting) {
          return const _AuthLoading();
        }

        return const AsmarLoginPage();
      },
    );
  }
}

class _AuthLoading extends StatelessWidget {
  const _AuthLoading();

  @override
  Widget build(BuildContext context) => const Scaffold(
    backgroundColor: Color(0xFF070817),
    body: Center(
      child: CircularProgressIndicator(),
    ),
  );
}

class _BackendUnavailable extends StatelessWidget {
  const _BackendUnavailable();

  @override
  Widget build(BuildContext context) => const Scaffold(
    body: Center(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Text(
          'Backend غير مهيأ. يجب تمرير SUPABASE_URL و SUPABASE_ANON_KEY عند بناء التطبيق.',
          textAlign: TextAlign.center,
        ),
      ),
    ),
  );
}

class AsmarLoginPage extends StatefulWidget {
  const AsmarLoginPage({super.key});
  @override State<AsmarLoginPage> createState() => _AsmarLoginPageState();
}

class _AsmarLoginPageState extends State<AsmarLoginPage> {
  final email = TextEditingController();
  final password = TextEditingController();
  bool emailMode = false;
  bool busy = false;

  Future<void> _googleLogin() async {
    if (busy) return;
    setState(() => busy = true);
    try {
      await AuthRepository().signInWithGoogle();
    } on AuthException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('تعذر تسجيل الدخول باستخدام Google: ${e.message}')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('تعذر تسجيل الدخول باستخدام Google: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> _emailLogin() async {
    final mail = email.text.trim();
    final pass = password.text;
    if (mail.isEmpty || pass.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('أدخل البريد الإلكتروني وكلمة المرور بشكل صحيح.')),
      );
      return;
    }
    setState(() => busy = true);
    try {
      await AuthRepository().signInWithEmail(email: mail, password: pass);
    } on AuthApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('تعذر تسجيل الدخول: ${e.message}')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('تعذر تسجيل الدخول: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  void dispose() {
    email.dispose();
    password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Directionality(
    textDirection: TextDirection.rtl,
    child: Scaffold(
      backgroundColor: const Color(0xFF070817),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Column(
                children: [
                  Container(
                    width: 94,
                    height: 94,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(
                        colors: [Color(0xFFFFE26A), Color(0xFFFFC94A), Color(0xFFFF9418)],
                      ),
                      boxShadow: [
                        BoxShadow(color: Color(0x553D18A5), blurRadius: 28, spreadRadius: 3),
                      ],
                    ),
                    child: const Icon(Icons.mic_rounded, size: 48, color: Color(0xFF111111)),
                  ),
                  const SizedBox(height: 18),
                  const Text('Asmar', style: TextStyle(fontSize: 34, fontWeight: FontWeight.w900)),
                  const SizedBox(height: 6),
                  const Text('ادخل إلى عالمك الصوتي', style: TextStyle(color: Color(0xFF9EA6C7), fontSize: 14)),
                  const SizedBox(height: 30),
                  if (!emailMode) ...[
                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: FilledButton.icon(
                        onPressed: busy ? null : _googleLogin,
                        style: FilledButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: Colors.black87,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                        ),
                        icon: const Icon(Icons.g_mobiledata_rounded, size: 30),
                        label: Text(
                          busy ? 'جارٍ تسجيل الدخول...' : 'المتابعة باستخدام Google',
                          style: const TextStyle(fontWeight: FontWeight.w900),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    const Text(
                      'إذا كان لديك حساب Google بالفعل سيتم تسجيل دخولك مباشرة. وإذا كانت هذه أول مرة، سيُنشأ حساب Asmar تلقائياً من بيانات Google بدون نموذج إنشاء حساب منفصل.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Color(0xFF9EA6C7), fontSize: 12, height: 1.5),
                    ),
                    const SizedBox(height: 22),
                    TextButton(
                      onPressed: busy ? null : () => setState(() => emailMode = true),
                      child: const Text('لدي حساب بالفعل بالبريد الإلكتروني'),
                    ),
                  ] else ...[
                    const Align(
                      alignment: Alignment.centerRight,
                      child: Text('تسجيل الدخول بالبريد الإلكتروني', style: TextStyle(fontSize: 19, fontWeight: FontWeight.w900)),
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: email,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(labelText: 'البريد الإلكتروني'),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: password,
                      obscureText: true,
                      decoration: const InputDecoration(labelText: 'كلمة المرور'),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: FilledButton(
                        onPressed: busy ? null : _emailLogin,
                        child: Text(busy ? 'جارٍ الدخول...' : 'تسجيل الدخول'),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: busy ? null : () => setState(() => emailMode = false),
                      child: const Text('العودة إلى تسجيل الدخول باستخدام Google'),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    ),
  );
}
