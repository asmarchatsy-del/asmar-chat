import 'package:flutter/material.dart';
import 'admin_panel.dart';
import 'room.dart';

const gold = Color(0xFFFFD36A);
const gold2 = Color(0xFFB77921);
const bg = Color(0xFF090604);
const card = Color(0xFF1B0E08);

void main() {
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
      home: const Shell(),
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

class Home extends StatelessWidget {
  const Home({super.key});

  final List<String> rooms = const [
    'سهرات أسمر',
    'لمة الأصدقاء',
    'VIP Lounge',
    'نجوم الليل',
    'مجلس العرب',
    'المضيفين',
    'دردشة عامة',
    'الوكالات',
    'أهل الخير',
    'الاستراحة',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    const CircleAvatar(
                      radius: 23,
                      backgroundColor: Color(0xFF4A2B11),
                      child: Icon(Icons.shield, color: gold),
                    ),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Asmar Chat',
                            style: TextStyle(
                              color: gold,
                              fontSize: 24,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          Text(
                            'مجتمع صوتي • غرف • هدايا • VIP',
                            style: TextStyle(
                              color: Colors.white54,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () {},
                      icon: const Icon(Icons.notifications_none),
                    ),
                    IconButton(
                      onPressed: () {},
                      icon: const Icon(Icons.search),
                    ),
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
                    gradient: const LinearGradient(
                      colors: [
                        Color(0xFF6B2C0B),
                        Color(0xFF160A06),
                      ],
                    ),
                    border: Border.all(color: gold2),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(22),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'أهلاً بك في',
                          style: TextStyle(color: Colors.white70),
                        ),
                        const Text(
                          'ASMAR CHAT',
                          style: TextStyle(
                            color: gold,
                            fontSize: 32,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'ادخل غرفتك المفضلة وتحدث مع الأصدقاء.',
                          style: TextStyle(
                            color: Colors.white60,
                            fontSize: 12,
                          ),
                        ),
                        const Spacer(),
                        FilledButton.icon(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const Room(
                                  name: 'سهرات أسمر',
                                ),
                              ),
                            );
                          },
                          icon: const Icon(Icons.mic),
                          label: const Text('ابدأ الدردشة الصوتية'),
                          style: const ButtonStyle(
                            backgroundColor:
                                WidgetStatePropertyAll(gold2),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(18, 20, 18, 10),
                child: Text(
                  'الغرف النشطة',
                  style: TextStyle(
                    color: gold,
                    fontSize: 21,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),

            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              sliver: SliverList.builder(
                itemCount: rooms.length,
                itemBuilder: (context, index) {
                  return RoomCard(
                    name: rooms[index],
                    index: index,
                  );
                },
              ),
            ),

            const SliverToBoxAdapter(
              child: SizedBox(height: 20),
            ),
          ],
        ),
      ),
    );
  }
}

class RoomCard extends StatelessWidget {
  final String name;
  final int index;

  const RoomCard({
    super.key,
    required this.name,
    required this.index,
  });

  @override
  Widget build(BuildContext context) {
    final icons = [
      Icons.local_fire_department,
      Icons.people,
      Icons.workspace_premium,
      Icons.nightlight,
      Icons.groups,
    ];

    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => Room(name: name),
          ),
        );
      },
      borderRadius: BorderRadius.circular(18),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: card,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: const Color(0xFF4C3019),
          ),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 29,
              backgroundColor: const Color(0xFF422511),
              child: Icon(
                icons[index % icons.length],
                color: gold,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 5),
                  const Text(
                    'مضيف • هدايا • دردشة صوتية',
                    style: TextStyle(
                      color: Colors.white54,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_left,
              color: gold,
            ),
          ],
        ),
      ),
    );
  }
}

class Discover extends StatelessWidget {
  const Discover({super.key
