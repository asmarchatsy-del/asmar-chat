import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

const _gold = Color(0xFFFFD36A);
const _gold2 = Color(0xFFB77921);
const _bg = Color(0xFF080605);

class AristocracyPage extends StatefulWidget {
  const AristocracyPage({super.key});

  @override
  State<AristocracyPage> createState() => _AristocracyPageState();
}

class _AristocracyPageState extends State<AristocracyPage> with SingleTickerProviderStateMixin {
  final db = Supabase.instance.client;
  late Future<List<Map<String, dynamic>>> _levelsFuture;
  int selected = 0;
  bool buying = false;
  late final AnimationController _glow = AnimationController(vsync: this, duration: const Duration(seconds: 3))..repeat(reverse: true);

  @override
  void initState() {
    super.initState();
    _levelsFuture = _loadLevels();
  }

  @override
  void dispose() {
    _glow.dispose();
    super.dispose();
  }

  Future<List<Map<String, dynamic>>> _loadLevels() async {
    final rows = await db.from('aristocracy_levels').select().eq('is_active', true).order('id');
    return List<Map<String, dynamic>>.from(rows);
  }

  Future<void> _buy(Map<String, dynamic> level) async {
    if (buying) return;
    setState(() => buying = true);
    try {
      await db.rpc('purchase_aristocracy', params: {'p_level': level['id']});
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('تم تفعيل ${level['name_ar']} لمدة ${level['duration_days']} يوم')));
      setState(() => _levelsFuture = _loadLevels());
    } catch (e) {
      if (!mounted) return;
      final message = e.toString().contains('insufficient_gold') ? 'رصيد الذهب غير كافٍ' : 'تعذر تفعيل الأرستقراطية';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
    } finally {
      if (mounted) setState(() => buying = false);
    }
  }

  List<Color> _curtain(int id) {
    const palettes = [
      [Color(0xFF14243D), Color(0xFF05080F)],
      [Color(0xFF32184D), Color(0xFF08050D)],
      [Color(0xFF4A1016), Color(0xFF0B0505)],
      [Color(0xFF153C2A), Color(0xFF050A08)],
      [Color(0xFF252025), Color(0xFF050505)],
      [Color(0xFF2C1644), Color(0xFF08050D)],
      [Color(0xFF050505), Color(0xFF1C0905)],
    ];
    return palettes[(id - 1).clamp(0, palettes.length - 1)];
  }

  IconData _crest(int id) => id <= 2 ? (id == 1 ? Icons.shield : Icons.military_tech) : id <= 4 ? Icons.workspace_premium : id == 7 ? Icons.local_fire_department : Icons.auto_awesome;

  String _perkName(String key) {
    const names = {
      'avatarFrame': 'إطار ذهبي',
      'entryEffect': 'دخولية خاصة',
      'chatBubble': 'فقاعة محادثة',
      'car': 'دخولية سيارة',
      'castle': 'قلعة ملكية',
      'antiKick': 'حماية من الطرد',
      'invisibleEntry': 'دخول خفي',
      'dragonCastle': 'تنين فوق القلعة',
    };
    return names[key] ?? key;
  }

  List<Map<String, dynamic>> _rewardCards(Map<String, dynamic> level) {
    final perks = Map<String, dynamic>.from(level['perks'] as Map? ?? {});
    final active = perks.entries.where((e) => e.value == true).map((e) => e.key).toList();
    final defaults = ['avatarFrame', 'entryEffect', 'chatBubble', 'car', 'castle', 'antiKick'];
    final keys = [...active, ...defaults].toSet().take(6).toList();
    return keys.map((key) => {'key': key, 'title': _perkName(key), 'icon': key == 'car' ? Icons.directions_car : key == 'chatBubble' ? Icons.chat_bubble : key == 'entryEffect' ? Icons.login : key == 'castle' ? Icons.castle : Icons.workspace_premium}).toList();
  }

  Widget _tab(Map<String, dynamic> level, int index) {
    final active = selected == index;
    return GestureDetector(
      onTap: () => setState(() => selected = index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        margin: const EdgeInsets.only(left: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          gradient: active ? const LinearGradient(colors: [_gold, _gold2]) : null,
          color: active ? null : Colors.white.withOpacity(.07),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: active ? _gold : Colors.white12),
        ),
        child: Text(level['name_ar'].toString(), style: TextStyle(color: active ? Colors.black : Colors.white70, fontWeight: FontWeight.w800)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: _bg,
        appBar: AppBar(title: const Text('الأرستقراطية'), backgroundColor: Colors.transparent),
        body: FutureBuilder<List<Map<String, dynamic>>>(
          future: _levelsFuture,
          builder: (context, snapshot) {
            if (!snapshot.hasData) return const Center(child: CircularProgressIndicator(color: _gold));
            final levels = snapshot.data!;
            if (levels.isEmpty) return const Center(child: Text('لا توجد مستويات متاحة'));
            final safeIndex = selected.clamp(0, levels.length - 1);
            final level = levels[safeIndex];
            final id = (level['id'] as num).toInt();
            final curtain = _curtain(id);
            final rewards = _rewardCards(level);
            final iconUrl = level['icon_url']?.toString() ?? '';
            return Container(
              decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: curtain)),
              child: ListView(
                padding: const EdgeInsets.only(bottom: 30),
                children: [
                  SizedBox(height: 60, child: ListView(scrollDirection: Axis.horizontal, padding: const EdgeInsets.symmetric(horizontal: 14), children: [for (var i = 0; i < levels.length; i++) _tab(levels[i], i)])),
                  const SizedBox(height: 8),
                  AnimatedBuilder(
                    animation: _glow,
                    builder: (_, __) => Container(
                      height: 285,
                      margin: const EdgeInsets.symmetric(horizontal: 22),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(32),
                        gradient: RadialGradient(center: const Alignment(0, -.25), radius: 1.0, colors: [_gold.withOpacity(.20 + _glow.value * .10), Colors.transparent]),
                      ),
                      child: Stack(alignment: Alignment.center, children: [
                        Positioned(bottom: 28, child: Transform.rotate(angle: -.03, child: Container(width: 230, height: 58, decoration: BoxDecoration(gradient: const LinearGradient(colors: [Color(0xFF6F4212), Color(0xFFFFE18A), Color(0xFF6F4212)]), borderRadius: BorderRadius.circular(70), boxShadow: const [BoxShadow(color: Colors.black54, blurRadius: 18, offset: Offset(0, 12))]), child: const Center(child: Text('ASMAR', style: TextStyle(color: Colors.black, fontWeight: FontWeight.w900, letterSpacing: 5))))),
                        Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                          if (iconUrl.isNotEmpty) Image.network(iconUrl, width: 110, height: 110, errorBuilder: (_, __, ___) => Icon(_crest(id), size: 100, color: _gold)) else Icon(_crest(id), size: 100, color: _gold),
                          const SizedBox(height: 10),
                          Text(level['name_ar'].toString(), style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w900, color: _gold)),
                          Text(level['name_en'].toString(), style: const TextStyle(color: Colors.white54, letterSpacing: 2)),
                        ]),
                      ]),
                    ),
                  ),
                  const Padding(padding: EdgeInsets.fromLTRB(18, 12, 18, 8), child: Text('المميزات', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: _gold))),
                  Padding(padding: const EdgeInsets.symmetric(horizontal: 14), child: GridView.count(crossAxisCount: 2, shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), childAspectRatio: 2.8, children: rewards.take(4).map((r) => Card(color: Colors.white.withOpacity(.07), child: ListTile(leading: Icon(r['icon'] as IconData, color: _gold), title: Text(r['title'].toString(), style: const TextStyle(fontSize: 12)))).toList())),
                  const Padding(padding: EdgeInsets.fromLTRB(18, 16, 18, 8), child: Text('الجوائز', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: _gold))),
                  SizedBox(height: 112, child: ListView(scrollDirection: Axis.horizontal, padding: const EdgeInsets.symmetric(horizontal: 14), children: [for (var i = 0; i < 6 && i < rewards.length; i++) Container(width: 104, margin: const EdgeInsets.only(left: 8), padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: Colors.black26, borderRadius: BorderRadius.circular(18), border: Border.all(color: _gold2)), child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(rewards[i]['icon'] as IconData, color: _gold, size: 28), const SizedBox(height: 7), Text(rewards[i]['title'].toString(), textAlign: TextAlign.center, style: const TextStyle(fontSize: 11))]))]),
                  Padding(padding: const EdgeInsets.fromLTRB(18, 18, 18, 0), child: FilledButton.icon(onPressed: buying ? null : () => _buy(level), icon: buying ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black)) : const Icon(Icons.workspace_premium), label: Text('تفعيل بـ ${level['price']} ذهب / ${level['duration_days']} يوم', style: const TextStyle(fontWeight: FontWeight.w900)), style: FilledButton.styleFrom(backgroundColor: _gold, foregroundColor: Colors.black, padding: const EdgeInsets.symmetric(vertical: 16)))),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
