import 'package:flutter/material.dart';
import 'theme/app_colors.dart';

const _qaitbay = 'https://images.unsplash.com/photo-1539768942893-daf53e448371?auto=format&fit=crop&w=1200&q=85';
const _king = 'https://images.unsplash.com/photo-1518895949257-7621c3c786d7?auto=format&fit=crop&w=1200&q=80';
const _egypt = 'https://images.unsplash.com/photo-1503177119275-0aa32b3a9368?auto=format&fit=crop&w=1200&q=80';

class BeelaShell extends StatefulWidget {
  const BeelaShell({super.key});

  @override
  State<BeelaShell> createState() => _BeelaShellState();
}

class _BeelaShellState extends State<BeelaShell> {
  int index = 0;

  final pages = const [
    PopularPage(),
    DiscoveryPage(),
    MessagesPage(),
    MomentsPage(),
    ProfilePage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppColors.page,
        body: IndexedStack(index: index, children: pages),
        bottomNavigationBar: BeelaBottomBar(
          index: index,
          onChanged: (value) => setState(() => index = value),
        ),
      ),
    );
  }
}

class BeelaHeader extends StatelessWidget {
  const BeelaHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 224,
      decoration: const BoxDecoration(
        image: DecorationImage(
          image: NetworkImage(_qaitbay),
          fit: BoxFit.cover,
        ),
      ),
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0x33000000), Color(0xE8000000)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 14),
        child: SafeArea(
          bottom: false,
          child: Column(
            children: [
              Row(
                children: [
                  _pill('الاكتشاف', false),
                  const SizedBox(width: 7),
                  _pill('شائع', true),
                  const SizedBox(width: 7),
                  _pill('غرفتي', false),
                  const Spacer(),
                  const Icon(Icons.notifications_none, color: Colors.white, size: 24),
                  const SizedBox(width: 8),
                  const Text('🇪🇬 🇮🇶', style: TextStyle(fontSize: 18)),
                ],
              ),
              const Spacer(),
              Container(
                height: 44,
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: Colors.white24),
                ),
                child: const TextField(
                  textDirection: TextDirection.rtl,
                  style: TextStyle(color: Colors.white, fontSize: 13),
                  decoration: InputDecoration(
                    prefixIcon: Icon(Icons.search, color: Colors.white60),
                    hintText: 'ابحث عن رمز الغرفة...',
                    hintStyle: TextStyle(color: Colors.white60),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static Widget _pill(String text, bool active) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
      decoration: BoxDecoration(
        color: active ? Colors.white : Colors.black45,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: active ? AppColors.gold : Colors.transparent,
        ),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: active ? Colors.black : Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

class PopularPage extends StatelessWidget {
  const PopularPage({super.key});

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        const SliverToBoxAdapter(child: BeelaHeader()),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(10, 10, 10, 95),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              const BeelaBanner(title: 'Super King 👑', image: _king),
              const SizedBox(height: 9),
              const RoomCardGold(
                top: 1,
                name: 'مملكة الدلع 👑',
                id: '11020',
                users: '10.2k',
                flag: '🇪🇬',
                image: 'https://i.pravatar.cc/150?img=32',
              ),
              const RoomCardGold(
                top: 2,
                name: 'أسياد الحب 💕',
                id: '10100',
                users: '8.1k',
                flag: '🇮🇶',
                image: 'https://i.pravatar.cc/150?img=12',
              ),
              const RoomCardGold(
                top: 3,
                name: 'دردشة حب ورومانسية 🔥',
                id: '09200',
                users: '5.9k',
                flag: '🇸🇾',
                image: 'https://i.pravatar.cc/150?img=5',
              ),
              const BeelaBanner(
                title: 'EGYPT 🇪🇬',
                image: _egypt,
                compact: true,
              ),
              const TextPost(
                name: 'ماريا',
                likes: '60320',
                text: 'السلام عليكم ورحمة الله وبركاته كيف حالكم...',
                image: 'https://i.pravatar.cc/150?img=29',
              ),
              const RoomCardGold(
                top: 0,
                name: 'غرفة سوريا الحرة ❤️',
                id: '12345',
                users: '1.2k',
                flag: '🇸🇾',
                image: 'https://i.pravatar.cc/150?img=20',
              ),
            ]),
          ),
        ),
      ],
    );
  }
}

class BeelaBanner extends StatelessWidget {
  final String title;
  final String image;
  final bool compact;

  const BeelaBanner({
    super.key,
    required this.title,
    required this.image,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: compact ? 58 : 92,
      margin: const EdgeInsets.only(bottom: 7),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.gold, width: 1.5),
        image: DecorationImage(
          image: NetworkImage(image),
          fit: BoxFit.cover,
        ),
      ),
      child: Container(
        padding: const EdgeInsets.all(13),
        alignment: Alignment.centerRight,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(13),
          gradient: const LinearGradient(
            colors: [Color(0xD9000000), Color(0x15000000)],
          ),
        ),
        child: Text(
          title,
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w900,
            fontSize: compact ? 15 : 21,
          ),
        ),
      ),
    );
  }
}

class RoomCardGold extends StatelessWidget {
  final int top;
  final String name;
  final String id;
  final String users;
  final String flag;
  final String image;

  const RoomCardGold({
    super.key,
    required this.top,
    required this.name,
    required this.id,
    required this.users,
    required this.flag,
    required this.image,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 7),
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        gradient: AppColors.goldGradient,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          gradient: AppColors.roomGradient,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Stack(
              children: [
                Container(
                  padding: const EdgeInsets.all(2),
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: AppColors.goldGradient,
                  ),
                  child: CircleAvatar(
                    radius: 28,
                    backgroundImage: NetworkImage(image),
                  ),
                ),
                if (top > 0)
                  Positioned(
                    top: 0,
                    left: 0,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 5,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: top == 1
                            ? AppColors.gold
                            : top == 2
                                ? Colors.grey
                                : Colors.brown,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'TOP$top',
                        style: const TextStyle(
                          fontSize: 8,
                          color: Colors.black,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Row(
                    children: [
                      const Icon(Icons.tag, size: 11, color: Colors.white54),
                      Text(
                        id,
                        style: const TextStyle(
                          color: Colors.white54,
                          fontSize: 10,
                        ),
                      ),
                      const SizedBox(width: 9),
                      const Icon(
                        Icons.person,
                        size: 11,
                        color: Colors.greenAccent,
                      ),
                      Text(
                        users,
                        style: const TextStyle(
                          color: Colors.white54,
                          fontSize: 10,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(flag, style: const TextStyle(fontSize: 13)),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class TextPost extends StatelessWidget {
  final String name;
  final String likes;
  final String text;
  final String image;

  const TextPost({
    super.key,
    required this.name,
    required this.likes,
    required this.text,
    required this.image,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 7),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.room1,
        borderRadius: BorderRadius.circular(13),
      ),
      child: Row(
        children: [
          Column(
            children: [
              const Icon(Icons.favorite, color: Colors.pink, size: 15),
              Text(
                likes,
                style: const TextStyle(color: Colors.white54, fontSize: 9),
              ),
            ],
          ),
          const SizedBox(width: 10),
          CircleAvatar(radius: 19, backgroundImage: NetworkImage(image)),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    color: AppColors.gold,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  text,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class DiscoveryPage extends StatelessWidget {
  const DiscoveryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        const SliverToBoxAdapter(child: BeelaHeader()),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 95),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              const Text(
                'الدول',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 9),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  'السعودية 🇸🇦',
                  'اليمن 🇾🇪',
                  'مصر 🇪🇬',
                  'سوريا 🇸🇾',
                  'أمريكا 🇺🇸',
                  'المغرب 🇲🇦',
                ].map((country) {
                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 7,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.room1,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white12),
                    ),
                    child: Text(
                      country,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 15),
              const BeelaBanner(
                title: 'نشاط الغرفة 🔥',
                image: _king,
                compact: true,
              ),
              const BeelaBanner(title: 'Super King 👑', image: _egypt),
            ]),
          ),
        ),
      ],
    );
  }
}

class MessagesPage extends StatelessWidget {
  const MessagesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return _SimplePage(
      title: 'الرسائل',
      child: Column(
        children: [
          const _Tabs(labels: ['طلبات التعارف', 'المتابعة', 'قبول بعد']),
          const SizedBox(height: 12),
          Container(
            height: 72,
            decoration: BoxDecoration(
              gradient: AppColors.roomGradient,
              borderRadius: BorderRadius.circular(14),
            ),
            child: const ListTile(
              leading: CircleAvatar(child: Icon(Icons.public)),
              title: Text('الدردشة العامة'),
              subtitle: Text('انضم الى الغرفة'),
              trailing: Text(
                '00:54',
                style: TextStyle(color: Colors.white54),
              ),
            ),
          ),
          const SizedBox(height: 8),
          const ListTile(
            leading: CircleAvatar(
              backgroundImage: NetworkImage(
                'https://i.pravatar.cc/100?img=48',
              ),
            ),
            title: Text('رسالة جديدة'),
            subtitle: Text('انضم الى الغرفة'),
            trailing: Text('00:54'),
          ),
        ],
      ),
    );
  }
}

class MomentsPage extends StatelessWidget {
  const MomentsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return _SimplePage(
      title: 'اللحظات',
      child: Column(
        children: [
          const _Tabs(labels: ['الكل', 'الأصدقاء']),
          const SizedBox(height: 12),
          Card(
            color: AppColors.room1,
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: CircleAvatar(
                      backgroundImage: NetworkImage(
                        'https://i.pravatar.cc/100?img=31',
                      ),
                    ),
                    title: Text('ماريا'),
                    subtitle: Text('10:02'),
                  ),
                  Row(
                    children: List.generate(4, (i) {
                      return Expanded(
                        child: Container(
                          height: 82,
                          margin: EdgeInsets.only(left: i == 3 ? 0 : 3),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(7),
                            image: DecorationImage(
                              image: NetworkImage(
                                'https://picsum.photos/seed/beela$i/240/240',
                              ),
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    '❤️ 67    💬 51',
                    style: TextStyle(color: Colors.white70),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return _SimplePage(
      title: 'أنا',
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: AppColors.roomGradient,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppColors.goldDark),
            ),
            child: const Row(
              children: [
                CircleAvatar(
                  radius: 38,
                  backgroundImage: NetworkImage(
                    'https://i.pravatar.cc/150?img=12',
                  ),
                ),
                SizedBox(width: 14),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Asmar User',
                      style: TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    SizedBox(height: 6),
                    Text(
                      'ID: 2016388',
                      style: TextStyle(color: Colors.white70),
                    ),
                    SizedBox(height: 4),
                    Text(
                      '31 زوار   •   0 متابعون',
                      style: TextStyle(
                        color: Colors.white60,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF5D2A91), Color(0xFF2B154D)],
              ),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppColors.goldDark),
            ),
            child: GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 4,
              mainAxisSpacing: 15,
              crossAxisSpacing: 5,
              children: const [
                _ProfileIcon(Icons.store, 'المتجر'),
                _ProfileIcon(Icons.emoji_events, 'الإنجازات'),
                _ProfileIcon(Icons.workspace_premium, 'الأوسمة'),
                _ProfileIcon(Icons.diamond, 'VIP'),
                _ProfileIcon(Icons.groups, 'العائلة'),
                _ProfileIcon(Icons.trending_up, 'المستوى'),
                _ProfileIcon(Icons.location_city, 'المركز'),
                _ProfileIcon(Icons.auto_awesome, 'الأنيقة'),
              ],
            ),
          ),
          const SizedBox(height: 12),
          const ListTile(
            leading: Icon(
              Icons.account_balance_wallet,
              color: AppColors.gold,
            ),
            title: Text('المحفظة'),
            subtitle: Text('6 ذهب   •   0 ألماس'),
          ),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: AppColors.bottomGradient,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Text(
              'وكالة المضيفين',
              style: TextStyle(
                color: AppColors.gold,
                fontWeight: FontWeight.w900,
                fontSize: 17,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileIcon extends StatelessWidget {
  final IconData icon;
  final String label;

  const _ProfileIcon(this.icon, this.label);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        CircleAvatar(
          backgroundColor: Colors.black26,
          child: Icon(icon, color: AppColors.gold),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 10, color: Colors.white70),
        ),
      ],
    );
  }
}

class _Tabs extends StatelessWidget {
  final List<String> labels;

  const _Tabs({required this.labels});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: labels.map((label) {
        return Expanded(
          child: Center(
            child: Text(
              label,
              style: const TextStyle(
                color: AppColors.gold,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _SimplePage extends StatelessWidget {
  final String title;
  final Widget child;

  const _SimplePage({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 100),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 14),
            child,
          ],
        ),
      ),
    );
  }
}

class BeelaBottomBar extends StatelessWidget {
  final int index;
  final ValueChanged<int> onChanged;

  const BeelaBottomBar({
    super.key,
    required this.index,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 78,
      decoration: const BoxDecoration(
        gradient: AppColors.bottomGradient,
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _item(0, Icons.local_fire_department, 'الشائع'),
          _item(1, Icons.public, 'الاكتشاف'),
          _item(2, Icons.chat_bubble, 'الرسائل'),
          _item(3, Icons.auto_awesome, 'اللحظات'),
          _item(4, Icons.person, 'أنا'),
        ],
      ),
    );
  }

  Widget _item(int itemIndex, IconData icon, String label) {
    final active = itemIndex == index;
    return Expanded(
      child: InkWell(
        onTap: () => onChanged(itemIndex),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: active ? AppColors.gold : Colors.white70,
              size: 23,
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(
                color: active ? AppColors.gold : Colors.white70,
                fontSize: 10,
                fontWeight: active ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
