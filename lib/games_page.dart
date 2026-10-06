
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'core/rooms/room_repository.dart';
import 'core/rooms/real_voice_room_page.dart';
import 'daily_tasks_page.dart';

const _bg = Color(0xFF070817);
const _panel = Color(0xFF11152D);
const _gold = Color(0xFFFFC94A);
const _orange = Color(0xFFFF9418);
const _muted = Color(0xFFA9B0D0);

class AsmarGamesPage extends StatefulWidget {
  const AsmarGamesPage({super.key});
  @override State<AsmarGamesPage> createState() => _AsmarGamesPageState();
}
class _AsmarGamesPageState extends State<AsmarGamesPage> {
  final repo = RoomRepository();
  Future<void> _companyGames() async {
    final rows = await db.from('company_game_links').select('id,name,provider,url,icon_url,description').eq('is_active', true).order('sort_order').order('created_at', ascending: false);
    if (!mounted) return;
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: _bg,
      builder: (_) => SafeArea(
        child: Directionality(
          textDirection: TextDirection.rtl,
          child: ListView(
            padding: const EdgeInsets.all(14),
            shrinkWrap: true,
            children: [
              const Text('ألعاب الشركة', style: TextStyle(fontSize: 21, fontWeight: FontWeight.w900)),
              const SizedBox(height: 8),
              ...List<Map<String, dynamic>>.from(rows).map((g) => ListTile(
                tileColor: _panel,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                leading: const CircleAvatar(backgroundColor: _gold, child: Icon(Icons.sports_esports, color: Colors.black)),
                title: Text(g['name']?.toString() ?? 'لعبة'),
                subtitle: Text(g['provider']?.toString() ?? 'Asmar', style: const TextStyle(color: _muted)),
                trailing: const Icon(Icons.open_in_new, color: _gold),
                onTap: () async {
                  final uri = Uri.tryParse(g['url']?.toString() ?? '');
                  if (uri == null || !await launchUrl(uri, mode: LaunchMode.externalApplication)) {
                    if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تعذر فتح رابط اللعبة')));
                  }
                },
              )),
              if (rows.isEmpty) const Padding(padding: EdgeInsets.all(24), child: Text('لا توجد ألعاب شركة مفعلة حالياً', textAlign: TextAlign.center, style: TextStyle(color: _muted))),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => Directionality(
    textDirection: TextDirection.rtl,
    child: ListView(
      padding: const EdgeInsets.fromLTRB(14, 18, 14, 30),
      children: [
        const SafeArea(bottom: false, child: Text('الألعاب', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900))),
        const SizedBox(height: 6),
        const Text('ألعاب حقيقية مرتبطة بقاعدة البيانات داخل الغرف الصوتية', style: TextStyle(color: _muted)),
        const SizedBox(height: 14),
        _gameCard(context, 'نرد', Icons.casino_rounded, 'رمي نرد فعلي وتسجيل الجولة في Supabase', _openRooms),
        _gameCard(context, 'حجر ورق مقص', Icons.extension_rounded, 'مواجهة فعلية بين لاعبين داخل الغرفة', _openRooms),
        _gameCard(context, 'التحديات اليومية', Icons.emoji_events_rounded, 'تقدم ومكافآت Coins/Diamonds فعلية', () => Navigator.push(context, MaterialPageRoute(builder: (_) => const DailyTasksPage()))),
        const SizedBox(height: 14),
        const Text('حالة المحرك', style: TextStyle(color: _gold, fontWeight: FontWeight.w900)),
        const SizedBox(height: 5),
        const Text('لن أضع Ludo/Domino/طاولة كأزرار وهمية: هذه الأنواع ليست مربوطة بمحرك متعدد اللاعبين في قاعدة البيانات الحالية.', style: TextStyle(color: _muted, fontSize: 11, height: 1.5)),
      ],
    ),
  );

  Widget _gameCard(BuildContext c, String title, IconData icon, String sub, VoidCallback tap) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: InkWell(
      onTap: tap,
      borderRadius: BorderRadius.circular(19),
      child: Container(
        padding: const EdgeInsets.all(17),
        decoration: BoxDecoration(color: _panel, borderRadius: BorderRadius.circular(19), border: Border.all(color: const Color(0xFF2B315A))),
        child: Row(children: [
          Container(width: 56, height: 56, decoration: const BoxDecoration(shape: BoxShape.circle, gradient: LinearGradient(colors: [_orange, _gold])), child: Icon(icon, color: const Color(0xFF4C2000), size: 29)),
          const SizedBox(width: 13),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
            const SizedBox(height: 4),
            Text(sub, style: const TextStyle(color: _muted, fontSize: 11)),
          ])),
          const Icon(Icons.chevron_left_rounded, color: _gold),
        ]),
      ),
    ),
  );

  void _openRooms() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: _bg,
      isScrollControlled: true,
      builder: (_) => Directionality(
        textDirection: TextDirection.rtl,
        child: SafeArea(
          child: SizedBox(
            height: MediaQuery.sizeOf(context).height * .72,
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: repo.watchActiveRooms(),
              builder: (context, snap) {
                final rooms = (snap.data ?? const <Map<String, dynamic>>[]).map(VoiceRoomRecord.fromMap).toList();
                if (rooms.isEmpty) return const Center(child: Text('لا توجد غرف مباشرة للألعاب حالياً', style: TextStyle(color: _muted)));
                return ListView(
                  padding: const EdgeInsets.all(14),
                  children: [
                    const Text('اختر غرفة', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
                    const SizedBox(height: 10),
                    ...rooms.map((room) => ListTile(
                      tileColor: _panel,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                      leading: const CircleAvatar(backgroundColor: Color(0xFF7B3FF2), child: Icon(Icons.mic)),
                      title: Text(room.name, style: const TextStyle(fontWeight: FontWeight.w900)),
                      subtitle: Text(room.id, style: const TextStyle(color: _muted, fontSize: 9)),
                      trailing: const Icon(Icons.play_arrow_rounded, color: _gold),
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(context, MaterialPageRoute(builder: (_) => RoomGamesPage(room: room)));
                      },
                    )),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class RoomGamesPage extends StatefulWidget {
  final VoiceRoomRecord room;
  const RoomGamesPage({super.key, required this.room});
  @override State<RoomGamesPage> createState() => _RoomGamesPageState();
}
class _RoomGamesPageState extends State<RoomGamesPage> {
  final db = Supabase.instance.client;
  bool busy = false;
  String? gameId;
  String gameType = 'dice';
  Timer? timer;

  @override
  void initState() { super.initState(); _loadGames(); timer = Timer.periodic(const Duration(seconds: 3), (_) => _loadGames()); }
  @override
  void dispose() { timer?.cancel(); super.dispose(); }

  Future<void> _loadGames() async {
    try {
      final rows = await db.from('room_games').select('id,game_type,status,created_by,created_at').eq('room_id', widget.room.id).eq('status', 'playing').order('created_at', ascending: false).limit(1);
      if (!mounted) return;
      setState(() {
        if ((rows as List).isNotEmpty) {
          final x = Map<String, dynamic>.from(rows.first);
          gameId = x['id'].toString();
          gameType = x['game_type'].toString();
        }
      });
    } catch (_) {}
  }

  Future<void> _start(String type) async {
    setState(() { busy = true; gameType = type; });
    try {
      final id = await db.rpc('asmar_start_game', params: {'p_room_id': widget.room.id, 'p_game_type': type});
      if (mounted) setState(() => gameId = id.toString());
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('بدء اللعبة يحتاج صلاحية مدير الغرفة: ' + e.toString())));
    } finally { if (mounted) setState(() => busy = false); }
  }

  Future<void> _dice() async {
    final id = gameId;
    if (id == null) return;
    try {
      final result = await db.rpc('asmar_roll_dice', params: {'p_game_id': id});
      if (mounted) showDialog<void>(context: context, builder: (_) => AlertDialog(title: const Text('نتيجة النرد'), content: Text('🎲 ' + result['value'].toString()), actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('حسناً'))]));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('تعذر رمي النرد: ' + e.toString())));
    }
  }

  Future<void> _rps() async {
    final id = gameId;
    if (id == null) return;
    final members = List<Map<String, dynamic>>.from(await db.from('room_members').select('user_id').eq('room_id', widget.room.id).isFilter('left_at', null));
    final me = db.auth.currentUser?.id;
    final opponents = members.where((x) => x['user_id'].toString() != me).toList();
    if (opponents.isEmpty) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تحتاج لاعباً آخر داخل الغرفة.')));
      return;
    }
    final choice = await showModalBottomSheet<String>(context: context, builder: (_) => SafeArea(child: Wrap(children: [
      for (final x in ['rock','paper','scissors']) ListTile(title: Text({'rock':'حجر','paper':'ورق','scissors':'مقص'}[x]!), onTap: () => Navigator.pop(context, x)),
    ])));
    if (choice == null) return;
    try {
      await db.rpc('asmar_play_rps', params: {'p_game_id': id, 'p_opponent': opponents.first['user_id'], 'p_choice': choice});
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم إرسال اختيارك. بانتظار اللاعب الآخر.')));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('تعذر بدء الجولة: ' + e.toString())));
    }
  }

  @override
  Widget build(BuildContext context) => Directionality(
    textDirection: TextDirection.rtl,
    child: Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(title: Text('ألعاب ' + widget.room.name, style: const TextStyle(fontWeight: FontWeight.w900)), actions: [IconButton(onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => RealVoiceRoomPage(room: widget.room))), icon: const Icon(Icons.mic))]),
      body: ListView(
        padding: const EdgeInsets.all(14),
        children: [
          const Text('الألعاب الفعلية', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
          const SizedBox(height: 10),
          FilledButton.icon(onPressed: _companyGames, icon: const Icon(Icons.link), label: const Text('ألعاب الشركة وروابطها')),
          const SizedBox(height: 8),
          if (gameId == null) ...[
            _GameButton('بدء نرد', Icons.casino, () => _start('dice')),
            _GameButton('بدء حجر ورق مقص', Icons.extension, () => _start('rps')),
          ] else ...[
            Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: _panel, borderRadius: BorderRadius.circular(18)), child: Text('اللعبة الحالية: ' + gameType, style: const TextStyle(color: _gold, fontWeight: FontWeight.w900))),
            const SizedBox(height: 10),
            if (gameType == 'dice') _GameButton('ارمِ النرد 🎲', Icons.casino, _dice) else _GameButton('العب الجولة ✊📄✂️', Icons.extension, _rps),
          ],
          const SizedBox(height: 18),
          const Text('كل نتيجة تُحفظ في قاعدة البيانات عبر RPC آمن؛ لا توجد نتيجة وهمية محلية.', style: TextStyle(color: _muted, fontSize: 11)),
        ],
      ),
    ),
  );
}

class _GameButton extends StatelessWidget {
  final String title;
  final IconData icon;
  final VoidCallback tap;
  const _GameButton(this.title, this.icon, this.tap);
  @override Widget build(BuildContext context) => Padding(padding: const EdgeInsets.only(bottom: 10), child: FilledButton.icon(onPressed: tap, icon: Icon(icon), label: Padding(padding: const EdgeInsets.all(13), child: Text(title, style: const TextStyle(fontWeight: FontWeight.w900)))));
}
