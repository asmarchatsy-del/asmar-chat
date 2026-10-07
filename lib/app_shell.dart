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
import 'asmar_premium_theme.dart';

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
    backgroundColor: Color(0xFF090604),
    body: Center(child: CircularProgressIndicator()),
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

  @override
  State<AsmarLoginPage> createState() => _AsmarLoginPageState();
}

class _AsmarLoginPageState extends State<AsmarLoginPage> {
  final email = TextEditingController();
  final password = TextEditingController();
  bool emailMode = false;
  bool busy = false;
  bool obscurePassword = true;

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
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AsmarPremiumTheme.bg,
        body: Stack(
          children: [
            Positioned(
              top: -110,
              left: -90,
              child: IgnorePointer(
                child: Container(
                  width: 300,
                  height: 300,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        AsmarPremiumTheme.gold.withOpacity(.20),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: -120,
              right: -90,
              child: IgnorePointer(
                child: Container(
                  width: 320,
                  height: 320,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        AsmarPremiumTheme.copper.withOpacity(.16),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
            ),
            SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 430),
                    child: Column(
                      children: [
                        Container(
                          width: 154,
                          height: 154,
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: const LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                Color(0xFFFFF0A8),
                                Color(0xFFFFC107),
                                Color(0xFFE53935),
                              ],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: AsmarPremiumTheme.gold.withOpacity(.24),
                                blurRadius: 34,
                                spreadRadius: 4,
                              ),
                            ],
                          ),
                          child: ClipOval(
                            child: Image.asset(
                              'assets/asmar_login_icon.jpg',
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          'Asmar',
                          style: textTheme.headlineMedium?.copyWith(
                            fontSize: 36,
                            fontWeight: FontWeight.w900,
                            letterSpacing: .2,
                          ),
                        ),
                        const SizedBox(height: 7),
                        Text(
                          'عالمك الصوتي يبدأ من هنا',
                          textAlign: TextAlign.center,
                          style: textTheme.bodyMedium?.copyWith(
                            color: AsmarPremiumTheme.muted,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 30),
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 220),
                          child: emailMode
                              ? _buildEmailLogin()
                              : _buildSocialLogin(),
                        ),
                        const SizedBox(height: 22),
                        Text(
                          'بتسجيل الدخول أنت توافق على شروط الاستخدام وسياسة الخصوصية.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: AsmarPremiumTheme.muted.withOpacity(.72),
                            fontSize: 11,
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSocialLogin() {
    return Column(
      key: const ValueKey('social-login'),
      children: [
        SizedBox(
          width: double.infinity,
          height: 56,
          child: FilledButton(
            onPressed: busy ? null : _googleLogin,
            style: FilledButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: const Color(0xFF17110D),
              disabledBackgroundColor: Colors.white.withOpacity(.65),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
              elevation: 0,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  alignment: Alignment.center,
                  child: const Text(
                    'G',
                    style: TextStyle(
                      color: Color(0xFF4285F4),
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  busy ? 'جارٍ فتح تسجيل الدخول...' : 'المتابعة باستخدام Google',
                  style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(child: Divider(color: AsmarPremiumTheme.muted.withOpacity(.18))),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text(
                'أو',
                style: TextStyle(
                  color: AsmarPremiumTheme.muted.withOpacity(.8),
                  fontSize: 12,
                ),
              ),
            ),
            Expanded(child: Divider(color: AsmarPremiumTheme.muted.withOpacity(.18))),
          ],
        ),
        const SizedBox(height: 14),
        SizedBox(
          width: double.infinity,
          height: 52,
          child: OutlinedButton.icon(
            onPressed: busy ? null : () => setState(() => emailMode = true),
            icon: const Icon(Icons.mail_outline_rounded, size: 20),
            label: const Text(
              'تسجيل الدخول بالبريد الإلكتروني',
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: AsmarPremiumTheme.goldBright,
              side: BorderSide(color: AsmarPremiumTheme.gold.withOpacity(.38)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
            ),
          ),
        ),
        const SizedBox(height: 13),
        Text(
          'لست بحاجة إلى إنشاء حساب منفصل عند استخدام Google.',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: AsmarPremiumTheme.muted.withOpacity(.9),
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildEmailLogin() {
    return Column(
      key: const ValueKey('email-login'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            IconButton(
              onPressed: busy ? null : () => setState(() => emailMode = false),
              icon: const Icon(Icons.arrow_forward_rounded),
              tooltip: 'العودة',
            ),
            const Expanded(
              child: Text(
                'تسجيل الدخول بالبريد الإلكتروني',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 19, fontWeight: FontWeight.w900),
              ),
            ),
            const SizedBox(width: 48),
          ],
        ),
        const SizedBox(height: 12),
        TextField(
          controller: email,
          keyboardType: TextInputType.emailAddress,
          textDirection: TextDirection.ltr,
          decoration: const InputDecoration(
            labelText: 'البريد الإلكتروني',
            prefixIcon: Icon(Icons.mail_outline_rounded),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: password,
          obscureText: obscurePassword,
          textDirection: TextDirection.ltr,
          decoration: InputDecoration(
            labelText: 'كلمة المرور',
            prefixIcon: const Icon(Icons.lock_outline_rounded),
            suffixIcon: IconButton(
              onPressed: () => setState(() => obscurePassword = !obscurePassword),
              icon: Icon(
                obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
              ),
            ),
          ),
        ),
        const SizedBox(height: 18),
        SizedBox(
          height: 54,
          child: FilledButton(
            onPressed: busy ? null : _emailLogin,
            style: FilledButton.styleFrom(
              backgroundColor: AsmarPremiumTheme.gold,
              foregroundColor: const Color(0xFF17100B),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
            ),
            child: Text(
              busy ? 'جارٍ الدخول...' : 'تسجيل الدخول',
              style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15),
            ),
          ),
        ),
        const SizedBox(height: 8),
        TextButton(
          onPressed: busy ? null : () => setState(() => emailMode = false),
          child: const Text('العودة إلى خيارات الدخول'),
        ),
      ],
    );
  }
}
