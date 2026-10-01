import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'backend_config.dart';
import 'admin_panel.dart';
import 'room.dart';

const gold = Color(0xFFFFD36A);
const gold2 = Color(0xFFB77921);
const bg = Color(0xFF090604);
const card = Color(0xFF1B0E08);

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
    url: BackendConfig.supabaseUrl,
    publishableKey: BackendConfig.supabasePublishableKey,
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
        colorScheme: ColorScheme.fromSeed(
          seedColor: gold,
          brightness: Brightness.dark,
        ),
      ),
      home: const AuthGate(),
    );
  }
}



class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    final supabase = Supabase.instance.client;
    return StreamBuilder<AuthState>(
      stream: supabase.auth.onAuthStateChange,
      builder: (context, snapshot) {
        if (supabase.auth.currentSession != null) {
          return const Shell();
        }
        return const LoginPage();
      },
    );
  }
}

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final email = TextEditingController();
  final password = TextEditingController();
  final displayName = TextEditingController();
  bool signUp = false;
  bool loading = false;
  String? error;

  Future<void> submit() async {
    setState(() {
      loading = true;
      error = null;
    });
    try {
      final auth = Supabase.instance.client.auth;
      if (signUp) {
        await auth.signUp(
          email: email.text.trim(),
          password: password.text,
          data: {'display_name': displayName.text.trim()},
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('تم إنشاء الحساب. تحقق من بريدك إذا طُلب ذلك.')),
          );
        }
      } else {
        await auth.signInWithPassword(
          email: email.text.trim(),
          password: password.text,
        );
      }
    } on AuthException catch (e) {
      setState(() => error = e.message);
    } catch (e) {
      setState(() => error = e.toString());
    } finally {
      if (mounted) setState(() => loading = false);
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
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 440),
                child: Card(
                  color: card,
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        const CircleAvatar(
                          radius: 38,
                          backgroundColor: Color(0xFF4A2B11),
                          child: Icon(Icons.shield, color: gold, size: 40),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'ASMAR CHAT',
                          style: TextStyle(
                            color: gold,
                            fontSize: 30,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          signUp ? 'إنشاء حساب جديد' : 'تسجيل الدخول',
                          style: const TextStyle(color: Colors.white70),
                        ),
                        if (signUp) ...[
                          const SizedBox(height: 18),
                          TextField(
                            controller: displayName,
                            decoration: const InputDecoration(
                              labelText: 'اسم العرض',
                              prefixIcon: Icon(Icons.person_outline),
                            ),
                          ),
                        ],
                        const SizedBox(height: 12),
                        TextField(
                          controller: email,
                          keyboardType: TextInputType.emailAddress,
                          decoration: const InputDecoration(
                            labelText: 'البريد الإلكتروني',
                            prefixIcon: Icon(Icons.email_outlined),
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: password,
                          obscureText: true,
                          decoration: const InputDecoration(
                            labelText: 'كلمة المرور',
                            prefixIcon: Icon(Icons.lock_outline),
                          ),
                        ),
                        if (error != null) ...[
                          const SizedBox(height: 12),
                          Text(error!, style: const TextStyle(color: Colors.redAccent)),
                        ],
                        const SizedBox(height: 20),
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton(
                            onPressed: loading ? null : submit,
                            style: const ButtonStyle(
                              backgroundColor: WidgetStatePropertyAll(gold2),
                            ),
                            child: loading
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  )
                                : Text(signUp ? 'إنشاء الحساب' : 'دخول'),
                          ),
                        ),
                        TextButton(
                          onPressed: loading ? null : () => setState(() {
                            signUp = !signUp;
                            error = null;
                          }),
                          child: Text(
                            signUp
                                ? 'لدي حساب — تسجيل الدخول'
                                : 'ليس لدي حساب — إنشاء حساب',
                            style: const TextStyle(color: gold),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class Shell extends StatefulWidget {
  const Shell({super.key});

  @override
  State<Shell> createState() => _ShellState();
}

class _ShellState extends State<Shell> {
  int tab = 0;

  final pages = const [
    Home(),
    Discover(),
    Wallet(),
    Profile(),
  ];

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        body: pages[tab],
        bottomNavigationBar: NavigationBar(
          backgroundColor: const Color(0xFF100805),
          indicatorColor: const Color(0xFF4A2C12),
          selectedIndex: tab,
          onDestinationSelected: (value) {
            setState(() {
              tab = value;
            });
          },
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home),
              label: 'الرئيسية',
            ),
            NavigationDestination(
              icon: Icon(Icons.explore_outlined),
              selectedIcon: Icon(Icons.explore),
              label: 'اكتشف',
            ),
            NavigationDestination(
              icon: Icon(Icons.account_balance_wallet_outlined),
              selectedIcon: Icon(Icons.account_balance_wallet),
              label: 'المحفظة',
            ),
            NavigationDestination(
              icon: Icon(Icons.person_outline),
              selectedIcon: Icon(Icons.person),
              label: 'حسابي',
            ),
          ],
        ),
      ),
    );
  }
}

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  late Future<List<Map<String, dynamic>>> _roomsFuture;

  @override
  void initState() {
    super.initState();
    _roomsFuture = _loadRooms();
  }

  Future<List<Map<String, dynamic>>> _loadRooms() async {
    final data = await Supabase.instance.client
        .from('rooms')
        .select('id,name,owner_id,is_active,livekit_room_name')
        .eq('is_active', true)
        .order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(data);
  }

  void _refreshRooms() {
    setState(() => _roomsFuture = _loadRooms());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async => _refreshRooms(),
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      const CircleAvatar(radius: 23, backgroundColor: Color(0xFF4A2B11), child: Icon(Icons.shield, color: gold)),
                      const SizedBox(width: 10),
                      const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text('Asmar Chat', style: TextStyle(color: gold, fontSize: 24, fontWeight: FontWeight.w900)),
                        Text('مجتمع صوتي • غرف • هدايا • VIP', style: TextStyle(color: Colors.white54, fontSize: 11)),
                      ])),
                      IconButton(onPressed: _refreshRooms, icon: const Icon(Icons.refresh)),
                    ],
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Container(
                    height: 175,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(24),
                      gradient: const LinearGradient(colors: [Color(0xFF6B2C0B), Color(0xFF160A06)]),
                      border: Border.all(color: gold2),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(22),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        const Text('أهلاً بك في', style: TextStyle(color: Colors.white70)),
                        const Text('ASMAR CHAT', style: TextStyle(color: gold, fontSize: 32, fontWeight: FontWeight.w900)),
                        const SizedBox(height: 6),
                        const Text('الغرف النشطة من قاعدة البيانات الحقيقية.', style: TextStyle(color: Colors.white60, fontSize: 12)),
                        const Spacer(),
                        FilledButton.icon(
                          onPressed: () async {
                            final rooms = await _roomsFuture;
                            if (!context.mounted || rooms.isEmpty) return;
                            Navigator.push(context, MaterialPageRoute(builder: (_) => Room(name: rooms.first['name'].toString(), roomId: rooms.first['id'].toString())));
                          },
                          icon: const Icon(Icons.mic),
                          label: const Text('دخول أول غرفة'),
                          style: const ButtonStyle(backgroundColor: WidgetStatePropertyAll(gold2)),
                        ),
                      ]),
                    ),
                  ),
                ),
              ),
              const SliverToBoxAdapter(child: Padding(padding: EdgeInsets.fromLTRB(18, 20, 18, 10), child: Text('الغرف النشطة', style: TextStyle(color: gold, fontSize: 21, fontWeight: FontWeight.w900)))),
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                sliver: FutureBuilder<List<Map<String, dynamic>>>(
                  future: _roomsFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState != ConnectionState.done) {
                      return const SliverToBoxAdapter(child: Padding(padding: EdgeInsets.all(30), child: Center(child: CircularProgressIndicator())));
                    }
                    if (snapshot.hasError) {
                      return SliverToBoxAdapter(child: Padding(padding: EdgeInsets.all(20), child: Text('تعذر تحميل الغرف: ${snapshot.error}', style: const TextStyle(color: Colors.redAccent))));
                    }
                    final rooms = snapshot.data ?? [];
                    if (rooms.isEmpty) {
                      return const SliverToBoxAdapter(child: Padding(padding: EdgeInsets.all(30), child: Center(child: Text('لا توجد غرف نشطة حاليًا', style: TextStyle(color: Colors.white54)))));
                    }
                    return SliverList.builder(
                      itemCount: rooms.length,
                      itemBuilder: (context, index) {
                        final room = rooms[index];
                        return RoomCard(
                          name: room['name'].toString(),
                          roomId: room['id'].toString(),
                          index: index,
                        );
                      },
                    );
                  },
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 20)),
            ],
          ),
        ),
      ),
    );
  }
}

class RoomCard extends StatelessWidget {
  final String name;
  final String roomId;
  final int index;
  const RoomCard({super.key, required this.name, required this.roomId, required this.index});

  @override
  Widget build(BuildContext context) {
    final icons = [Icons.local_fire_department, Icons.people, Icons.workspace_premium, Icons.nightlight, Icons.groups];
    return InkWell(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => Room(name: name, roomId: roomId))),
      borderRadius: BorderRadius.circular(18),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: card, borderRadius: BorderRadius.circular(18), border: Border.all(color: const Color(0xFF4C3019))),
        child: Row(children: [
          CircleAvatar(radius: 29, backgroundColor: const Color(0xFF422511), child: Icon(icons[index % icons.length], color: gold)),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(name, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 5),
            const Text('مضيف • هدايا • دردشة صوتية', style: TextStyle(color: Colors.white54, fontSize: 10)),
          ])),
          const Icon(Icons.chevron_left, color: gold),
        ]),
      ),
    );
  }
}


class Discover extends StatelessWidget {
  const Discover({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Text(
          'اكتشف',
          style: TextStyle(
            color: gold,
            fontSize: 28,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}

class Wallet extends StatelessWidget {
  const Wallet({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('المحفظة')),
      body: const Center(
        child: Text(
          'المحفظة',
          style: TextStyle(color: gold, fontSize: 28),
        ),
      ),
    );
  }
}

class Profile extends StatelessWidget {
  const Profile({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('حسابي')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'الملف الشخصي',
              style: TextStyle(color: gold, fontSize: 28, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AdminPanel()),
                );
              },
              icon: const Icon(Icons.admin_panel_settings),
              label: const Text('لوحة الإدارة'),
              style: const ButtonStyle(
                backgroundColor: WidgetStatePropertyAll(gold2),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
