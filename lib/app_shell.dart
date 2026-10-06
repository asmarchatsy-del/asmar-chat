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
  final email = TextEditingController();
  final password = TextEditingController();
  final displayName = TextEditingController();
  bool signUp = false;
  bool busy = false;
  bool emailNotConfirmed = false;

  Future<void> _resendConfirmation() async {
    final mail = email.text.trim();
    if (mail.isEmpty) return;
    setState(() => busy = true);
    try {
      await AuthRepository().resendSignupConfirmation(mail);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم إرسال رسالة تأكيد جديدة. افحص البريد الوارد والرسائل غير المرغوب فيها.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('تعذر إرسال رسالة التأكيد: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> _submit() async {
    final mail = email.text.trim();
    final pass = password.text;
    if (mail.isEmpty || pass.length < 6 || (signUp && displayName.text.trim().isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('أدخل البيانات المطلوبة وكلمة مرور من 6 أحرف على الأقل.')),
      );
      return;
    }
    setState(() {
      busy = true;
      emailNotConfirmed = false;
    });
    try {
      final auth = AuthRepository();
      if (signUp) {
        final response = await auth.signUpWithEmail(
          email: mail,
          password: pass,
          displayName: displayName.text.trim(),
        );
        if (response.session == null && mounted) {
          setState(() => emailNotConfirmed = true);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('تم إنشاء الحساب. يلزم تأكيد البريد قبل تسجيل الدخول.')),
          );
        }
      } else {
        await auth.signInWithEmail(email: mail, password: pass);
      }
    } on AuthApiException catch (e) {
      if (mounted) {
        final isUnconfirmed = e.code == 'email_not_confirmed';
        setState(() => emailNotConfirmed = isUnconfirmed);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isUnconfirmed
                  ? 'البريد الإلكتروني غير مؤكد. اضغط «إعادة إرسال التأكيد» أدناه.'
                  : 'تعذر تنفيذ العملية: ${e.message}',
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('تعذر تنفيذ العملية: $e')));
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  void dispose() {
    email.dispose();
    password.dispose();
    displayName.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 460),
            child: Column(
              children: [
                const Icon(Icons.mic, size: 72),
                const SizedBox(height: 12),
                const Text('Asmar Chat', style: TextStyle(fontSize: 30, fontWeight: FontWeight.w900)),
                const SizedBox(height: 28),
                if (signUp)
                  TextField(controller: displayName, decoration: const InputDecoration(labelText: 'الاسم الظاهر')),
                const SizedBox(height: 10),
                TextField(
                  controller: email,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(labelText: 'البريد الإلكتروني'),
                  onChanged: (_) {
                    if (emailNotConfirmed) setState(() => emailNotConfirmed = false);
                  },
                ),
                const SizedBox(height: 10),
                TextField(controller: password, obscureText: true, decoration: const InputDecoration(labelText: 'كلمة المرور')),
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: busy ? null : _submit,
                    child: Text(busy ? 'جارٍ التنفيذ...' : (signUp ? 'إنشاء الحساب' : 'تسجيل الدخول')),
                  ),
                ),
                if (emailNotConfirmed && !signUp)
                  TextButton.icon(
                    onPressed: busy ? null : _resendConfirmation,
                    icon: const Icon(Icons.mark_email_read_outlined),
                    label: const Text('إعادة إرسال تأكيد البريد'),
                  ),
                TextButton(
                  onPressed: busy ? null : () => setState(() {
                    signUp = !signUp;
                    emailNotConfirmed = false;
                  }),
                  child: Text(signUp ? 'لدي حساب بالفعل' : 'إنشاء حساب جديد'),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}
