import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/auth/auth_repository.dart';
import 'core/backend/supabase_runtime.dart';
import 'core/rooms/real_rooms_home_page.dart';
import 'new_asmar_ui.dart';
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

class AsmarAuthGate extends StatelessWidget {
  const AsmarAuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = AuthRepository();
    if (!SupabaseRuntime.isInitialized) {
      return const _BackendUnavailable();
    }
    return StreamBuilder(
      stream: auth.authStateChanges,
      builder: (context, snapshot) {
        if (SupabaseRuntime.currentUser != null) {
          return const NewAsmarShell();
        }
        return const AsmarLoginPage();
      },
    );
  }
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
  bool busy = false;

  Future<void> _googleLogin() async {
    if (busy) return;
    setState(() => busy = true);
    try {
      await AuthRepository().signInWithGoogle();
    } on AuthApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('تعذر تسجيل الدخول بجوجل: ${e.message}')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('تعذر تسجيل الدخول بجوجل: $e')),
      );
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFF070817),
    body: SafeArea(
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 36, 24, 24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: Column(
              children: [
                Container(
                  width: 92,
                  height: 92,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [Color(0xFFE33DFF), Color(0xFF8B4DFF), Color(0xFF4EDCFF)],
                    ),
                  ),
                  child: const Icon(Icons.mic_rounded, size: 48, color: Colors.white),
                ),
                const SizedBox(height: 18),
                const Text('Asmar', style: TextStyle(fontSize: 36, fontWeight: FontWeight.w900)),
                const SizedBox(height: 8),
                const Text('ادخل إلى عالمك الصوتي', style: TextStyle(color: Color(0xFF9EA6C7), fontSize: 15)),
                const SizedBox(height: 44),
                SizedBox(
                  width: double.infinity,
                  height: 58,
                  child: FilledButton.icon(
                    onPressed: busy ? null : _googleLogin,
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: const Color(0xFF17182A),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                    ),
                    icon: busy
                        ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2))
                        : const _GoogleMark(),
                    label: Text(
                      busy ? 'جاري تسجيل الدخول...' : 'المتابعة باستخدام Google',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                const Text(
                  'إذا كان لديك حساب Google فسيتم تسجيل دخولك، وإذا كانت هذه أول مرة فسيتم إنشاء حساب Asmar تلقائياً.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Color(0xFF7F87A8), height: 1.5, fontSize: 12),
                ),
                const SizedBox(height: 28),
                const Text(
                  'بالمتابعة أنت توافق على شروط الاستخدام وسياسة الخصوصية.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Color(0xFF666D8D), fontSize: 11),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

class _GoogleMark extends StatelessWidget {
  const _GoogleMark();

  @override
  Widget build(BuildContext context) => const Text(
    'G',
    style: TextStyle(fontSize: 25, fontWeight: FontWeight.w900, color: Color(0xFF4285F4)),
  );
}
