import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

const gold = Color(0xFFFFD36A);
const gold2 = Color(0xFFB77921);
const bg = Color(0xFF090604);
const card = Color(0xFF1B0E08);

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://jojxsqsgmpaggfnnyuyy.supabase.co',
    anonKey: 'sb_publishable_mC6rnw-HAwJzNu_2d-0A2g_SrEBWyjL',
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

  static const rooms = [
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
                          onPressed: () {},
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
    const icons = [
      Icons.local_fire_department,
      Icons.people,
      Icons.workspace_premium,
      Icons.nightlight,
      Icons.groups,
    ];

    return Container(
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
    );
  }
}

class Discover extends StatelessWidget {
  const Discover({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('اكتشف'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: const [
          FeatureCard(
            icon: Icons.local_fire_department,
            title: 'الغرف الرائجة',
            subtitle: 'اكتشف أكثر الغرف نشاطاً',
          ),
          FeatureCard(
            icon: Icons.mic,
            title: 'المضيفون',
            subtitle: 'تعرف على المضيفين',
          ),
          FeatureCard(
            icon: Icons.workspace_premium,
            title: 'VIP',
            subtitle: 'مميزات وتجربة VIP',
          ),
        ],
      ),
    );
  }
}

class FeatureCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const FeatureCard({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(18),
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
            radius: 27,
            backgroundColor: const Color(0xFF422511),
            child: Icon(icon, color: gold),
          ),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 17,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: const TextStyle(
                  color: Colors.white54,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class Wallet extends StatelessWidget {
  const Wallet({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('المحفظة'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(22),
              gradient: const LinearGradient(
                colors: [
                  Color(0xFF6B2C0B),
                  Color(0xFF160A06),
                ],
              ),
              border: Border.all(color: gold2),
            ),
            child: const Column(
              children: [
                Icon(
                  Icons.account_balance_wallet,
                  color: gold,
                  size: 45,
                ),
                SizedBox(height: 10),
                Text(
                  'رصيدك',
                  style: TextStyle(color: Colors.white70),
                ),
                SizedBox(height: 5),
                Text(
                  '0',
                  style: TextStyle(
                    color: gold,
                    fontSize: 34,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  'عملة',
                  style: TextStyle(color: Colors.white54),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          _WalletButton(
            title: 'إرسال هدية',
            icon: Icons.card_giftcard,
          ),
          _WalletButton(
            title: 'شحن الرصيد',
            icon: Icons.add_circle_outline,
          ),
          _WalletButton(
            title: 'سجل العمليات',
            icon: Icons.history,
          ),
        ],
      ),
    );
  }
}

class _WalletButton extends StatelessWidget {
  final String title;
  final IconData icon;

  const _WalletButton({
    required this.title,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        tileColor: card,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(
            color: Color(0xFF4C3019),
          ),
        ),
        leading: Icon(icon, color: gold),
        title: Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        trailing: const Icon(
          Icons.chevron_left,
          color: gold,
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
      appBar: AppBar(
        title: const Text('حسابي'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: const [
          SizedBox(height: 15),
          CircleAvatar(
            radius: 48,
            backgroundColor: Color(0xFF422511),
            child: Icon(
              Icons.person,
              color: gold,
              size: 55,
            ),
          ),
          SizedBox(height: 12),
          Center(
            child: Text(
              'زائر أسمر',
              style: TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          SizedBox(height: 5),
          Center(
            child: Text(
              'حساب جديد',
              style: TextStyle(color: Colors.white54),
            ),
          ),
          SizedBox(height: 25),
          FeatureCard(
            icon: Icons.login,
            title: 'تسجيل الدخول',
            subtitle: 'الدخول إلى حسابك',
          ),
          FeatureCard(
            icon: Icons.edit,
            title: 'الملف الشخصي',
            subtitle: 'تعديل بيانات الحساب',
          ),
          FeatureCard(
            icon: Icons.settings,
            title: 'الإعدادات',
            subtitle: 'إعدادات التطبيق',
          ),
          FeatureCard(
            icon: Icons.admin_panel_settings,
            title: 'لوحة الإدارة',
            subtitle: 'إدارة التطبيق',
          ),
        ],
      ),
    );
  }
}
