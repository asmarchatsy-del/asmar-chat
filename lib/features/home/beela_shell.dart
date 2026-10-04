import 'package:flutter/material.dart';
import '../../asmar/asmar_theme.dart';

class BeelaShell extends StatefulWidget {
  const BeelaShell({super.key});
  @override State<BeelaShell> createState() => _BeelaShellState();
}

class _BeelaShellState extends State<BeelaShell> {
  int tab = 0;
  String filter = 'Jordan 🇯🇴';
  final filters = const ['Jordan 🇯🇴', 'Turkey 🇹🇷', 'Syria 🇸🇾', 'Hot 🔥'];
  final rooms = const [
    ('ليالي الشام', '83420', '🇸🇾', '1,248', 'https://i.pravatar.cc/160?img=12'),
    ('مملكة الأردن', '71019', '🇯🇴', '892', 'https://i.pravatar.cc/160?img=32'),
    ('Istanbul Night', '62188', '🇹🇷', '2,310', 'https://i.pravatar.cc/160?img=45'),
    ('ASMAR HOT 🔥', '55007', '🔥', '4,820', 'https://i.pravatar.cc/160?img=5'),
  ];

  @override
  Widget build(BuildContext context) => Directionality(
        textDirection: TextDirection.rtl,
        child: Scaffold(
          body: CustomScrollView(slivers: [
            SliverToBoxAdapter(child: _header()),
            SliverToBoxAdapter(child: _tabs()),
            SliverToBoxAdapter(child: _filters()),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 28),
              sliver: SliverList.builder(
                itemCount: rooms.length,
                itemBuilder: (_, i) => _room(rooms[i]),
              ),
            ),
          ]),
        ),
      );

  Widget _header() => Container(
        height: 238,
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: NetworkImage('https://images.unsplash.com/photo-1539768942893-daf53e448371?auto=format&fit=crop&w=1200&q=85'),
            fit: BoxFit.cover,
          ),
        ),
        child: Container(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 14),
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0x33000000), Color(0xEE000000)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: SafeArea(
            bottom: false,
            child: Column(children: [
              Row(children: [
                const Icon(Icons.mic, color: AsmarTheme.gold, size: 28),
                const SizedBox(width: 7),
                const Text('ASMAR', style: TextStyle(color: AsmarTheme.gold, fontSize: 22, fontWeight: FontWeight.w900)),
                const Spacer(),
                IconButton(onPressed: () {}, icon: const Icon(Icons.notifications_none, color: Colors.white)),
              ]),
              const Spacer(),
              const Align(
                alignment: Alignment.centerRight,
                child: Text('غرف الصوت', style: TextStyle(color: Colors.white, fontSize: 27, fontWeight: FontWeight.w900)),
              ),
              const SizedBox(height: 12),
              Container(
                height: 44,
                decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(24), border: Border.all(color: Colors.white24)),
                child: const TextField(
                  textDirection: TextDirection.rtl,
                  style: TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'ابحث عن الغرفة أو Room ID...',
                    hintStyle: TextStyle(color: Colors.white60),
                    prefixIcon: Icon(Icons.search, color: AsmarTheme.gold),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(vertical: 11),
                  ),
                ),
              ),
            ]),
          ),
        ),
      );

  Widget _tabs() => Padding(
        padding: const EdgeInsets.fromLTRB(12, 14, 12, 8),
        child: Row(
          children: ['جديد', 'فيديو', 'متألق', 'شات'].asMap().entries.map((e) {
            final active = e.key == tab;
            return Expanded(
              child: GestureDetector(
                onTap: () => setState(() => tab = e.key),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 11),
                  decoration: BoxDecoration(color: active ? AsmarTheme.gold : AsmarTheme.surface, borderRadius: BorderRadius.circular(12)),
                  child: Text(e.value, textAlign: TextAlign.center, style: TextStyle(color: active ? Colors.black : Colors.white70, fontWeight: FontWeight.w800)),
                ),
              ),
            );
          }).toList(),
        ),
      );

  Widget _filters() => SizedBox(
        height: 52,
        child: ListView.separated(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          scrollDirection: Axis.horizontal,
          itemCount: filters.length,
          separatorBuilder: (_, __) => const SizedBox(width: 8),
          itemBuilder: (_, i) => ChoiceChip(
            label: Text(filters[i]),
            selected: filter == filters[i],
            onSelected: (_) => setState(() => filter = filters[i]),
            selectedColor: AsmarTheme.gold,
            labelStyle: TextStyle(color: filter == filters[i] ? Colors.black : Colors.white70, fontWeight: FontWeight.bold),
            backgroundColor: AsmarTheme.surface,
            side: const BorderSide(color: Color(0xFF4B321A)),
          ),
        ),
      );

  Widget _room((String, String, String, String, String) room) => InkWell(
        onTap: () => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('فتح الغرفة ${room.$2}'))),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          margin: const EdgeInsets.only(bottom: 9),
          padding: const EdgeInsets.all(9),
          decoration: AsmarTheme.card(),
          child: Row(children: [
            CircleAvatar(radius: 31, backgroundImage: NetworkImage(room.$5)),
            const SizedBox(width: 11),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(room.$1, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 15)),
              const SizedBox(height: 5),
              Row(children: [Text('Room ID ${room.$2}', style: const TextStyle(color: AsmarTheme.muted, fontSize: 11)), const SizedBox(width: 8), Text(room.$3, style: const TextStyle(fontSize: 15)), const SizedBox(width: 8), const Icon(Icons.people_alt_outlined, color: Colors.greenAccent, size: 14), const SizedBox(width: 3), Text(room.$4, style: const TextStyle(color: AsmarTheme.muted, fontSize: 11))]),
            ])),
            const Icon(Icons.chevron_left, color: AsmarTheme.gold),
          ]),
        ),
      );
}
