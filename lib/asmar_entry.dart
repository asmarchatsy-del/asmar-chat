import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'backend_config.dart';
import 'app_shell.dart';
import 'me_page.dart';
import 'admin_gate.dart';
import 'messages.dart';
import 'room.dart';
import 'asmar/asmar_shell.dart';

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
  runApp(const AsmarChatApp());
}

class AsmarChatApp extends StatelessWidget {
  const AsmarChatApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
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
        initialRoute: kIsWeb
            ? (Uri.base.path.isEmpty ? '/' : Uri.base.path)
            : '/',
        routes: {
          '/': (_) => const _AuthGate(),
          '/admin': (_) => const SuperAdminGate(),
        },
      );
}

class _AuthGate extends StatelessWidget {
  const _AuthGate();

  @override
  Widget build(BuildContext context) {
    final client = Supabase.instance.client;
    return StreamBuilder<AuthState>(
      stream: client.auth.onAuthStateChange,
      builder: (context, _) {
        if (client.auth.currentSession != null) {
          return const AsmarBuild452Shell();
        }
        return const AsmarLoginPage();
      },
    );
  }
}

class _Shell extends StatefulWidget {
  const _Shell();

  @override
  State<_Shell> createState() => _ShellState();
}

class _ShellState extends State<_Shell> {
  int index = 0;

  late final pages = <Widget>[
    const _RoomHome(),
    const MessagesPage(),
    const _Moments(),
    const MePage(),
  ];

  @override
  Widget build(BuildContext context) => Scaffold(
        body: IndexedStack(index: index, children: pages),
        bottomNavigationBar: NavigationBar(
          selectedIndex: index,
          onDestinationSelected: (i) => setState(() => index = i),
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home),
              label: 'الرئيسية',
            ),
            NavigationDestination(
              icon: Icon(Icons.forum_outlined),
              selectedIcon: Icon(Icons.forum),
              label: 'الرسائل',
            ),
            NavigationDestination(
              icon: Icon(Icons.auto_awesome_outlined),
              selectedIcon: Icon(Icons.auto_awesome),
              label: 'لحظات',
            ),
            NavigationDestination(
              icon: Icon(Icons.person_outline),
              selectedIcon: Icon(Icons.person),
              label: 'أنا',
            ),
          ],
        ),
      );
}

class _RoomHome extends StatefulWidget {
  const _RoomHome();

  @override
  State<_RoomHome> createState() => _RoomHomeState();
}

class _RoomHomeState extends State<_RoomHome> {
  Future<List<Map<String, dynamic>>> _rooms() async =>
      List<Map<String, dynamic>>.from(
        await Supabase.instance.client
            .from('rooms')
            .select('id,name,owner_id,is_active,hot_score,cover_url')
            .eq('is_active', true)
            .order('hot_score', ascending: false),
      );

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: bg,
        appBar: AppBar(
          title: const Text(
            'Asmar Chat',
            style: TextStyle(color: gold, fontWeight: FontWeight.w900),
          ),
          actions: [
            IconButton(
              onPressed: () => setState(() {}),
              icon: const Icon(Icons.refresh),
            ),
          ],
        ),
        body: FutureBuilder<List<Map<String, dynamic>>>(
          future: _rooms(),
          builder: (context, s) {
            if (s.connectionState != ConnectionState.done) {
              return const Center(
                child: CircularProgressIndicator(color: gold),
              );
            }
            if (s.hasError) {
              return Center(child: Text('تعذر تحميل الغرف: ${s.error}'));
            }
            final rows = s.data ?? [];
            if (rows.isEmpty) {
              return const Center(child: Text('لا توجد غرف نشطة'));
            }
            return ListView.separated(
              padding: const EdgeInsets.all(14),
              itemCount: rows.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (_, i) {
                final r = rows[i];
                return ListTile(
                  tileColor: const Color(0xFF1B0E08),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  leading: const CircleAvatar(
                    backgroundColor: Color(0xFF4A2B11),
                    child: Icon(Icons.mic, color: gold),
                  ),
                  title: Text(r['name'].toString()),
                  subtitle: Text('نقاط النشاط: ${r['hot_score'] ?? 0}'),
                  trailing: const Icon(Icons.chevron_left, color: gold),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => Room(
                        name: r['name'].toString(),
                        roomId: r['id'].toString(),
                      ),
                    ),
                  ),
                );
              },
            );
          },
        ),
      );
}

class _Moments extends StatelessWidget {
  const _Moments();

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: bg,
        appBar: AppBar(title: const Text('لحظات')),
        body: Center(
          child: FilledButton.icon(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const legacy.MomentsPage(),
              ),
            ),
            icon: const Icon(Icons.auto_awesome),
            label: const Text('فتح اللحظات'),
          ),
        ),
      );
}
