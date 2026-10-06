import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/rooms/room_repository.dart';
import 'core/rooms/real_voice_room_page.dart';
import 'global_chat.dart';
import 'private_conversations.dart';
import 'wallet.dart';

const _bg = Color(0xFF070817);
const _panel = Color(0xFF10132B);
const _panel2 = Color(0xFF151936);
const _purple = Color(0xFF8B4DFF);
const _pink = Color(0xFFE33DFF);
const _cyan = Color(0xFF4EDCFF);
const _text2 = Color(0xFF9EA6C7);

class NewAsmarShell extends StatefulWidget {
  const NewAsmarShell({super.key});
  @override State<NewAsmarShell> createState() => _NewAsmarShellState();
}

class _NewAsmarShellState extends State<NewAsmarShell> {
  int index = 0;
  late final pages = const [
    _NewHomePage(), _NewDiscoverPage(), _NewMessagesPage(),
    _NewWalletPage(), _NewProfilePage(),
  ];

  @override
  Widget build(BuildContext context) => Directionality(
    textDirection: TextDirection.rtl,
    child: Scaffold(
      backgroundColor: _bg,
      body: IndexedStack(index: index, children: pages),
      bottomNavigationBar: _BottomBar(index: index, onChanged: (v) => setState(() => index = v)),
    ),
  );
}

class _BottomBar extends StatelessWidget {
  final int index;
  final ValueChanged<int> onChanged;
  const _BottomBar({required this.index, required this.onChanged});
  @override
  Widget build(BuildContext context) {
    const items = [
      (Icons.home_rounded, 'الرئيسية'), (Icons.explore_rounded, 'اكتشف'),
      (Icons.chat_bubble_rounded, 'الرسائل'), (Icons.account_balance_wallet_rounded, 'المحفظة'),
      (Icons.person_rounded, 'ملفي'),
    ];
    return Container(
      decoration: const BoxDecoration(color: Color(0xFF0B0D20), border: Border(top: BorderSide(color: Color(0xFF25294A)))),
      child: SafeArea(top: false, child: Row(
        children: List.generate(items.length, (i) {
          final selected = i == index;
          return Expanded(child: InkWell(
            onTap: () => onChanged(i),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Icon(items[i].$1, size: 23, color: selected ? _pink : _text2),
                const SizedBox(height: 4),
                Text(items[i].$2, style: TextStyle(fontSize: 11, fontWeight: selected ? FontWeight.w800 : FontWeight.w500, color: selected ? Colors.white : _text2)),
              ]),
            ),
          ));
        }),
      )),
    );
  }
}

class _NewHomePage extends StatefulWidget {
  const _NewHomePage();
  @override State<_NewHomePage> createState() => _NewHomePageState();
}

class _NewHomePageState extends State<_NewHomePage> {
  final repo = RoomRepository();

  Future<void> _createRoom() async {
    final c = TextEditingController();
    final name = await showModalBottomSheet<String>(
      context: context, isScrollControlled: true, backgroundColor: _panel,
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(ctx).viewInsets.bottom + 20),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          const Text('إنشاء غرفة صوتية', style: TextStyle(fontSize: 21, fontWeight: FontWeight.w900)),
          const SizedBox(height: 14),
          TextField(controller: c, autofocus: true, style: const TextStyle(color: Colors.white), decoration: _input('اسم الغرفة')),
          const SizedBox(height: 14),
          FilledButton.icon(onPressed: () => Navigator.pop(ctx, c.text.trim()), icon: const Icon(Icons.mic_rounded), label: const Text('إنشاء الغرفة')),
        ]),
      ),
    );
    c.dispose();
    if (name == null || name.isEmpty) return;
    try {
      final room = await repo.createRoom(name: name, liveKitRoomName: 'asmar-\${DateTime.now().millisecondsSinceEpoch}');
      if (!mounted) return;
      Navigator.push(context, MaterialPageRoute(builder: (_) => RealVoiceRoomPage(room: room)));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('تعذر إنشاء الغرفة: \$e')));
    }
  }

  @override
  Widget build(BuildContext context) => CustomScrollView(slivers: [
    SliverToBoxAdapter(child: _HomeHeader(onCreate: _createRoom)),
    SliverToBoxAdapter(child: Padding(padding: const EdgeInsets.fromLTRB(16, 12, 16, 8), child: _HeroBanner(onCreate: _createRoom))),
    const SliverToBoxAdapter(child: _SectionTitle('الغرف الحية الآن', 'مشاهدة الكل')),
    StreamBuilder<List<Map<String, dynamic>>>(
      stream: repo.watchActiveRooms(),
      builder: (context, snap) {
        if (snap.hasError) return SliverToBoxAdapter(child: _EmptyCard('تعذر تحميل الغرف: \${snap.error}'));
        final rooms = (snap.data ?? const <Map<String, dynamic>>[]).map(VoiceRoomRecord.fromMap).toList();
        if (rooms.isEmpty) return const SliverToBoxAdapter(child: _EmptyCard('لا توجد غرف مباشرة. أنشئ أول غرفة الآن.'));
        return SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          sliver: SliverGrid(
            delegate: SliverChildBuilderDelegate(
              (context, i) => _RoomCard(room: rooms[i], onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => RealVoiceRoomPage(room: rooms[i])))),
              childCount: rooms.length,
            ),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, crossAxisSpacing: 12, mainAxisSpacing: 12, childAspectRatio: .92),
          ),
        );
      },
    ),
    const SliverToBoxAdapter(child: _SectionTitle('التصنيفات', 'اكتشف')),
    SliverToBoxAdapter(child: SizedBox(height: 76, child: ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16), scrollDirection: Axis.horizontal,
      children: const [_Category('🎵', 'موسيقى'), _Category('💬', 'دردشة'), _Category('🎙️', 'سهرات'), _Category('💜', 'أصدقاء'), _Category('🔥', 'الأكثر نشاطاً')],
    ))),
    const SliverToBoxAdapter(child: SizedBox(height: 18)),
  ]);
}

class _HomeHeader extends StatelessWidget {
  final VoidCallback onCreate;
  const _HomeHeader({required this.onCreate});
  @override
  Widget build(BuildContext context) => SafeArea(bottom: false, child: Padding(
    padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
    child: Row(children: [
      const Text('Asmar', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic)),
      const Spacer(),
      _CircleButton(icon: Icons.search_rounded, onTap: () {}),
      const SizedBox(width: 8),
      _CircleButton(icon: Icons.notifications_none_rounded, onTap: () {}),
      const SizedBox(width: 8),
      _CircleButton(icon: Icons.add_rounded, onTap: onCreate),
    ]),
  ));
}

class _HeroBanner extends StatelessWidget {
  final VoidCallback onCreate;
  const _HeroBanner({required this.onCreate});
  @override
  Widget build(BuildContext context) => Container(
    height: 170, padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(28),
      gradient: const LinearGradient(begin: Alignment.topRight, end: Alignment.bottomLeft, colors: [Color(0xFF6528D8), Color(0xFF22104D), Color(0xFF0F1736)]),
      boxShadow: const [BoxShadow(color: Color(0x553D18A5), blurRadius: 24, spreadRadius: 2)],
    ),
    child: Stack(children: [
      const Positioned(left: -8, bottom: -18, child: Icon(Icons.graphic_eq_rounded, size: 150, color: Color(0x2236D9FF))),
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('أهلاً بك في Asmar', style: TextStyle(fontSize: 23, fontWeight: FontWeight.w900)),
        const SizedBox(height: 8),
        const Text('صوتك. أصدقاءك. عالمك.', style: TextStyle(color: Color(0xFFD9D5FF), fontSize: 14)),
        const Spacer(),
        FilledButton.icon(
          onPressed: onCreate,
          style: FilledButton.styleFrom(backgroundColor: Colors.white, foregroundColor: _purple, padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11)),
          icon: const Icon(Icons.add_rounded), label: const Text('إنشاء غرفة'),
        ),
      ]),
    ]),
  );
}

class _RoomCard extends StatelessWidget {
  final VoiceRoomRecord room;
  final VoidCallback onTap;
  const _RoomCard({required this.room, required this.onTap});
  @override
  Widget build(BuildContext context) {
    final seed = room.name.codeUnits.fold<int>(0, (a, b) => a + b);
    final gradients = [
      const [Color(0xFF7C2DFF), Color(0xFF25104D)], const [Color(0xFFE32EFF), Color(0xFF35104A)],
      const [Color(0xFF176CFF), Color(0xFF102548)], const [Color(0xFF00A9A5), Color(0xFF102F38)],
    ];
    final g = gradients[seed % gradients.length];
    return InkWell(
      onTap: onTap, borderRadius: BorderRadius.circular(22),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(22), gradient: LinearGradient(begin: Alignment.topRight, end: Alignment.bottomLeft, colors: g), border: Border.all(color: Colors.white.withOpacity(.08))),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            const _Avatar(initial: 'A', size: 48),
            const SizedBox(width: 8),
            Expanded(child: Text(room.name, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900))),
            const Icon(Icons.more_horiz_rounded, color: Colors.white70),
          ]),
          const Spacer(),
          Row(children: [
            const Icon(Icons.mic_rounded, size: 16, color: _cyan), const SizedBox(width: 4),
            Text(room.isActive ? 'مباشر الآن' : 'متوقف', style: const TextStyle(color: Colors.white70, fontSize: 11)),
            const Spacer(),
            const Icon(Icons.people_alt_rounded, size: 15, color: Colors.white70), const SizedBox(width: 4),
            Text('\${room.seatCount}', style: const TextStyle(color: Colors.white70, fontSize: 11)),
          ]),
        ]),
      ),
    );
  }
}

class _NewDiscoverPage extends StatefulWidget {
  const _NewDiscoverPage();
  @override State<_NewDiscoverPage> createState() => _NewDiscoverPageState();
}

class _NewDiscoverPageState extends State<_NewDiscoverPage> {
  final repo = RoomRepository();
  String category = 'الكل';
  @override
  Widget build(BuildContext context) => CustomScrollView(slivers: [
    SliverToBoxAdapter(child: SafeArea(bottom: false, child: Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('اكتشف', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900)),
        const SizedBox(height: 14),
        TextField(style: const TextStyle(color: Colors.white), decoration: _input('ابحث عن غرفة أو مستخدم...').copyWith(prefixIcon: const Icon(Icons.search))),
        const SizedBox(height: 14),
        SizedBox(height: 42, child: ListView(
          scrollDirection: Axis.horizontal,
          children: ['الكل', 'موسيقى', 'دردشة', 'أصدقاء', 'مميز'].map((x) => Padding(
            padding: const EdgeInsets.only(left: 8),
            child: ChoiceChip(label: Text(x), selected: category == x, onSelected: (_) => setState(() => category = x), selectedColor: _purple, backgroundColor: _panel, labelStyle: TextStyle(color: category == x ? Colors.white : _text2)),
          )).toList(),
        )),
      ]),
    ))),
    StreamBuilder<List<Map<String, dynamic>>>(
      stream: repo.watchActiveRooms(),
      builder: (context, snap) {
        final rooms = (snap.data ?? const <Map<String, dynamic>>[]).map(VoiceRoomRecord.fromMap).toList();
        if (rooms.isEmpty) return const SliverToBoxAdapter(child: _EmptyCard('لا توجد غرف مطابقة الآن.'));
        return SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          sliver: SliverList.builder(
            itemCount: rooms.length,
            itemBuilder: (_, i) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _DiscoverRoomTile(room: rooms[i], onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => RealVoiceRoomPage(room: rooms[i])))),
            ),
          ),
        );
      },
    ),
  ]);
}

class _DiscoverRoomTile extends StatelessWidget {
  final VoiceRoomRecord room;
  final VoidCallback onTap;
  const _DiscoverRoomTile({required this.room, required this.onTap});
  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap, borderRadius: BorderRadius.circular(20),
    child: Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: _panel, borderRadius: BorderRadius.circular(20), border: Border.all(color: const Color(0xFF262B50))),
      child: Row(children: [
        const _Avatar(initial: 'A', size: 58), const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(room.name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900)),
          const SizedBox(height: 5),
          Text('غرفة صوتية • \${room.seatCount} مقعد', style: const TextStyle(color: _text2, fontSize: 12)),
        ])),
        FilledButton(onPressed: onTap, style: FilledButton.styleFrom(backgroundColor: _purple), child: const Text('دخول')),
      ]),
    ),
  );
}

class _NewMessagesPage extends StatelessWidget {
  const _NewMessagesPage();
  @override
  Widget build(BuildContext context) => CustomScrollView(slivers: [
    const SliverToBoxAdapter(child: SafeArea(bottom: false, child: Padding(
      padding: EdgeInsets.fromLTRB(16, 18, 16, 8),
      child: Text('الرسائل', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900)),
    ))),
    SliverToBoxAdapter(child: Padding(padding: const EdgeInsets.all(16), child: Column(children: [
      _MessageTile(icon: Icons.public_rounded, title: 'الدردشة العامة', subtitle: 'تحدث مع مجتمع Asmar', onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const GlobalChatPage()))),
      const SizedBox(height: 10),
      _MessageTile(icon: Icons.chat_rounded, title: 'المحادثات الخاصة', subtitle: 'رسائلك ومحادثاتك الخاصة', onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PrivateConversationsPage()))),
      const SizedBox(height: 10),
      const _MessageTile(icon: Icons.notifications_rounded, title: 'الإشعارات', subtitle: 'آخر التحديثات والتنبيهات'),
    ]))),
  ]);
}

class _NewWalletPage extends StatefulWidget {
  const _NewWalletPage();
  @override State<_NewWalletPage> createState() => _NewWalletPageState();
}

class _NewWalletPageState extends State<_NewWalletPage> {
  int coins = 0, diamonds = 0;
  Future<void> load() async {
    final u = Supabase.instance.client.auth.currentUser;
    if (u == null) return;
    try {
      final r = await Supabase.instance.client.from('profiles').select('coins,diamonds').eq('id', u.id).maybeSingle();
      if (mounted) setState(() { coins = (r?['coins'] as num?)?.toInt() ?? 0; diamonds = (r?['diamonds'] as num?)?.toInt() ?? 0; });
    } catch (_) {}
  }
  @override void initState() { super.initState(); load(); }
  @override
  Widget build(BuildContext context) => RefreshIndicator(
    onRefresh: load,
    child: ListView(padding: const EdgeInsets.fromLTRB(16, 18, 16, 24), children: [
      const SafeArea(bottom: false, child: Text('المحفظة', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900))),
      const SizedBox(height: 16),
      Row(children: [
        Expanded(child: _BalanceCard('الكوينز', '\$coins', Icons.monetization_on_rounded, _purple)),
        const SizedBox(width: 10),
        Expanded(child: _BalanceCard('الماس', '\$diamonds', Icons.diamond_rounded, _cyan)),
      ]),
      const SizedBox(height: 16),
      _ActionCard(icon: Icons.add_circle_rounded, title: 'شحن الكوينز', subtitle: 'اختر طريقة الشحن المتاحة', onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RechargeAgentsPage()))),
      const SizedBox(height: 10),
      _ActionCard(icon: Icons.account_balance_rounded, title: 'السحب', subtitle: 'إدارة طلبات السحب', onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const WithdrawalMethodsPage()))),
      const SizedBox(height: 10),
      const _ActionCard(icon: Icons.history_rounded, title: 'سجل العمليات', subtitle: 'راجع حركة محفظتك'),
    ]),
  );
}

class _NewProfilePage extends StatefulWidget {
  const _NewProfilePage();
  @override State<_NewProfilePage> createState() => _NewProfilePageState();
}

class _NewProfilePageState extends State<_NewProfilePage> {
  Map<String, dynamic> p = {};
  Future<void> load() async {
    final u = Supabase.instance.client.auth.currentUser;
    if (u == null) return;
    try {
      final r = await Supabase.instance.client.from('profiles').select('display_name,username,public_id,coins,diamonds,user_level,svip_level,is_verified').eq('id', u.id).maybeSingle();
      if (mounted) setState(() => p = Map<String, dynamic>.from(r ?? {}));
    } catch (_) {}
  }
  @override void initState() { super.initState(); load(); }
  @override
  Widget build(BuildContext context) {
    final name = (p['display_name'] ?? p['username'] ?? 'Asmar User').toString();
    final username = (p['username'] ?? 'user').toString();
    return RefreshIndicator(
      onRefresh: load,
      child: ListView(padding: const EdgeInsets.fromLTRB(16, 18, 16, 30), children: [
        const SafeArea(bottom: false, child: Align(alignment: Alignment.centerRight, child: Text('ملفي', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900)))),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(28), gradient: const LinearGradient(colors: [Color(0xFF2A155F), Color(0xFF11162F)]), border: Border.all(color: Color(0xFF49327B))),
          child: Column(children: [
            const _Avatar(initial: 'A', size: 86), const SizedBox(height: 12),
            Text(name, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
            const SizedBox(height: 4),
            Text('@\$username • ID \${p['public_id'] ?? '—'}', style: const TextStyle(color: _text2, fontSize: 12)),
            const SizedBox(height: 16),
            Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
              _Stat('\${p['user_level'] ?? 1}', 'المستوى'),
              _Stat('\${p['svip_level'] ?? 0}', 'SVIP'),
              _Stat('\${p['coins'] ?? 0}', 'Coins'),
              _Stat('\${p['diamonds'] ?? 0}', 'Diamonds'),
            ]),
          ]),
        ),
        const SizedBox(height: 14),
        const _ActionCard(icon: Icons.workspace_premium_rounded, title: 'VIP / SVIP', subtitle: 'المزايا والمستويات'),
        const SizedBox(height: 10),
        const _ActionCard(icon: Icons.auto_awesome_rounded, title: 'الإطارات والشارات', subtitle: 'تخصيص مظهرك داخل Asmar'),
        const SizedBox(height: 10),
        _ActionCard(icon: Icons.logout_rounded, title: 'تسجيل الخروج', subtitle: 'الخروج من الحساب', onTap: () => Supabase.instance.client.auth.signOut()),
      ]),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title, action;
  const _SectionTitle(this.title, this.action);
  @override Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
    child: Row(children: [
      Text(title, style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w900)),
      const Spacer(), Text(action, style: const TextStyle(color: _pink, fontSize: 12, fontWeight: FontWeight.w800)),
    ]),
  );
}

class _Category extends StatelessWidget {
  final String emoji, label;
  const _Category(this.emoji, this.label);
  @override Widget build(BuildContext context) => Container(
    width: 92, margin: const EdgeInsets.only(left: 10),
    decoration: BoxDecoration(color: _panel, borderRadius: BorderRadius.circular(18)),
    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Text(emoji, style: const TextStyle(fontSize: 23)), const SizedBox(height: 5),
      Text(label, style: const TextStyle(fontSize: 11, color: _text2)),
    ]),
  );
}

class _Avatar extends StatelessWidget {
  final String initial; final double size;
  const _Avatar({required this.initial, required this.size});
  @override Widget build(BuildContext context) => Container(
    width: size, height: size,
    decoration: const BoxDecoration(shape: BoxShape.circle, gradient: LinearGradient(colors: [_pink, _purple, _cyan]), boxShadow: [BoxShadow(color: Color(0x553D18A5), blurRadius: 12)]),
    padding: const EdgeInsets.all(3),
    child: Container(decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0xFF0E1027)), child: Center(child: Text(initial, style: TextStyle(fontSize: 30, fontWeight: FontWeight.w900)))),
  );
}

class _CircleButton extends StatelessWidget {
  final IconData icon; final VoidCallback onTap;
  const _CircleButton({required this.icon, required this.onTap});
  @override Widget build(BuildContext context) => InkWell(
    onTap: onTap, borderRadius: BorderRadius.circular(18),
    child: Container(width: 42, height: 42, decoration: BoxDecoration(color: _panel, borderRadius: BorderRadius.circular(15)), child: Icon(icon, color: Colors.white)),
  );
}

class _MessageTile extends StatelessWidget {
  final IconData icon; final String title, subtitle; final VoidCallback? onTap;
  const _MessageTile({required this.icon, required this.title, required this.subtitle, this.onTap});
  @override Widget build(BuildContext context) => InkWell(
    onTap: onTap, borderRadius: BorderRadius.circular(20),
    child: Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(color: _panel, borderRadius: BorderRadius.circular(20)),
      child: Row(children: [
        Container(width: 52, height: 52, decoration: BoxDecoration(borderRadius: BorderRadius.circular(17), gradient: const LinearGradient(colors: [_purple, _pink])), child: Icon(icon, color: Colors.white)),
        const SizedBox(width: 13),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.w900)), const SizedBox(height: 4),
          Text(subtitle, style: const TextStyle(color: _text2, fontSize: 12)),
        ])),
        if (onTap != null) const Icon(Icons.chevron_left_rounded, color: _text2),
      ]),
    ),
  );
}

class _BalanceCard extends StatelessWidget {
  final String title, value; final IconData icon; final Color color;
  const _BalanceCard(this.title, this.value, this.icon, this.color);
  @override Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(color: _panel, borderRadius: BorderRadius.circular(23), border: Border.all(color: color.withOpacity(.35))),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Icon(icon, color: color, size: 28), const SizedBox(height: 12),
      Text(title, style: const TextStyle(color: _text2, fontSize: 12)), const SizedBox(height: 4),
      Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
    ]),
  );
}

class _ActionCard extends StatelessWidget {
  final IconData icon; final String title, subtitle; final VoidCallback? onTap;
  const _ActionCard({required this.icon, required this.title, required this.subtitle, this.onTap});
  @override Widget build(BuildContext context) => InkWell(
    onTap: onTap, borderRadius: BorderRadius.circular(20),
    child: Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: _panel, borderRadius: BorderRadius.circular(20)),
      child: Row(children: [
        Icon(icon, color: _pink, size: 27), const SizedBox(width: 13),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.w900)), const SizedBox(height: 3),
          Text(subtitle, style: const TextStyle(color: _text2, fontSize: 12)),
        ])),
        if (onTap != null) const Icon(Icons.chevron_left_rounded, color: _text2),
      ]),
    ),
  );
}

class _Stat extends StatelessWidget {
  final String value, label;
  const _Stat(this.value, this.label);
  @override Widget build(BuildContext context) => Column(children: [
    Text(value, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900)),
    const SizedBox(height: 3), Text(label, style: const TextStyle(color: _text2, fontSize: 10)),
  ]);
}

class _EmptyCard extends StatelessWidget {
  final String text;
  const _EmptyCard(this.text);
  @override Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
    padding: const EdgeInsets.all(28),
    decoration: BoxDecoration(color: _panel, borderRadius: BorderRadius.circular(22)),
    child: Center(child: Text(text, textAlign: TextAlign.center, style: const TextStyle(color: _text2))),
  );
}

InputDecoration _input(String hint) => InputDecoration(
  hintText: hint, hintStyle: const TextStyle(color: _text2), filled: true, fillColor: _panel2,
  border: OutlineInputBorder(borderRadius: BorderRadius.circular(17), borderSide: BorderSide.none),
);
