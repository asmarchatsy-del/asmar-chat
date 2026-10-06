import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/rooms/room_repository.dart';
import 'core/rooms/real_voice_room_page.dart';
import 'core/rooms/room_social_repository.dart';
import 'create_room_page.dart';
import 'daily_tasks_page.dart';
import 'family_page.dart';
import 'blocked_users_page.dart';
import 'badges_page.dart';
import 'accessories_page.dart';
import 'transfer_page.dart';
import 'ranking_page.dart';
import 'global_chat.dart';
import 'games_page.dart';
import 'private_conversations.dart';
import 'store.dart';
import 'svip.dart';
import 'wallet.dart';
import 'wallet_gifts_page.dart';
import 'public_profile_page.dart';

const _bg = Color(0xFF070817);
const _panel = Color(0xFF11152D);
const _panel2 = Color(0xFF171C3A);
const _gold = Color(0xFFFFC94A);
const _orange = Color(0xFFFF9418);
const _purple = Color(0xFF7B3FF2);
const _pink = Color(0xFFE447FF);
const _muted = Color(0xFFA9B0D0);

class AsmarAyomeShell extends StatefulWidget {
  const AsmarAyomeShell({super.key});
  @override State<AsmarAyomeShell> createState() => _AsmarAyomeShellState();
}
class _AsmarAyomeShellState extends State<AsmarAyomeShell> {
  int index = 0;
  final pages = const [_AyomeHomePage(), _AyomeGamesPage(), _AyomeMessagesPage(), _AyomeProfilePage()];
  @override Widget build(BuildContext context) => Directionality(
    textDirection: TextDirection.rtl,
    child: Scaffold(backgroundColor: _bg, body: Stack(children: [IndexedStack(index: index, children: pages), Positioned(left: 14, bottom: 76, child: _TreasureFab(onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const DailyTasksPage()))))]),
      bottomNavigationBar: _Bottom(index: index, onChanged: (v) => setState(() => index = v))),
  );
}
class _Bottom extends StatelessWidget {
  final int index;
  final ValueChanged<int> onChanged;
  const _Bottom({required this.index, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    const items = [
      (Icons.home_rounded, 'القصر'),
      (Icons.sports_esports_rounded, 'الألعاب'),
      (Icons.mail_rounded, 'الرسائل'),
      (Icons.person_rounded, 'أنا'),
    ];
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF0B0D20),
        border: Border(top: BorderSide(color: Color(0xFF2A2F55))),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: List.generate(items.length, (i) {
            final selected = i == index;
            return Expanded(
              child: InkWell(
                onTap: () => onChanged(i),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 9),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(items[i].$1, color: selected ? _gold : _muted, size: 24),
                      const SizedBox(height: 3),
                      Text(
                        items[i].$2,
                        style: TextStyle(
                          color: selected ? Colors.white : _muted,
                          fontSize: 11,
                          fontWeight: selected ? FontWeight.w900 : FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}

class _AyomeHomePage extends StatefulWidget {
  const _AyomeHomePage();
  @override State<_AyomeHomePage> createState() => _AyomeHomePageState();
}
class _AyomeHomePageState extends State<_AyomeHomePage> {
  final repo = RoomRepository();
  String tab = 'شائع'; String filter = 'الكل'; String country = 'Hot';
  Set<String> _followedIds = <String>{};
  Set<String> _verifiedIds = <String>{};
  Set<String> _familyIds = <String>{};

  @override
  void initState() {
    super.initState();
    _loadHomeRelations();
  }

  Future<void> _loadHomeRelations() async {
    final uid = Supabase.instance.client.auth.currentUser?.id;
    if (uid == null) return;
    try {
      final db = Supabase.instance.client;
      final follows = await db.from('follows').select('following_id').eq('follower_id', uid);
      final verified = await db.from('profiles').select('id').eq('is_verified', true).limit(2000);
      final families = await db.from('family_members').select('user_id').eq('user_id', uid);
      final familyIds = <String>{};
      if (families.isNotEmpty) {
        final familyId = families.first['family_id'];
        final members = await db.from('family_members').select('user_id').eq('family_id', familyId);
        familyIds.addAll(members.map((x) => x['user_id'].toString()));
      }
      if (!mounted) return;
      setState(() {
        _followedIds = Set<String>.from(follows.map((x) => x['following_id'].toString()));
        _verifiedIds = Set<String>.from(verified.map((x) => x['id'].toString()));
        _familyIds = familyIds;
      });
    } catch (_) {}
  }
  List<VoiceRoomRecord> _applyFilters(List<VoiceRoomRecord> rooms) {
    Iterable<VoiceRoomRecord> out = rooms;
    if (country != 'Hot') out = out.where((r) => (r.countryCode ?? '').toLowerCase() == _countryCode(country));
    if (filter == 'متابعة') out = out.where((r) => r.ownerId != null && _followedIds.contains(r.ownerId));
    if (filter == 'موثق') out = out.where((r) => r.ownerId != null && _verifiedIds.contains(r.ownerId));
    if (filter == 'عائلة') out = out.where((r) => r.ownerId != null && _familyIds.contains(r.ownerId));
    if (filter == 'غرف') out = out.where((r) => r.isActive);
    if (tab == 'فيديو') out = out.where((r) => r.tags.any((t) => t.toLowerCase().contains('video')));
    return out.toList(growable: false);
  }
  String _countryCode(String name) => switch (name) { 'Syria' => 'SY', 'Germany' => 'DE', 'Netherlands' => 'NL', _ => name.toUpperCase() };
  Future<void> createRoom() async => Navigator.push(context, MaterialPageRoute(builder: (_) => const CreateRoomPage()));
  Future<void> searchRooms() async {
    final c = TextEditingController();
    await showModalBottomSheet<void>(context: context, isScrollControlled: true, backgroundColor: _panel, builder: (sheet) => Padding(
      padding: EdgeInsets.fromLTRB(16, 16, 16, MediaQuery.of(sheet).viewInsets.bottom + 16),
      child: Column(mainAxisSize: MainAxisSize.min, children: [const Text('البحث عن غرفة', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
        const SizedBox(height: 12), TextField(controller: c, autofocus: true, decoration: input('اسم الغرفة أو رقمها')),
        const SizedBox(height: 10),
        FilledButton.icon(onPressed: () async {
          final q = c.text.trim(); if (q.isEmpty) return;
          try {
            final db = Supabase.instance.client;
            List<Map<String, dynamic>> rows = [];
            try {
              rows = List<Map<String, dynamic>>.from(await db.from('rooms').select('id,name,owner_id,livekit_room_name,is_active,seat_count,country_code,tags,cover_url').eq('is_active', true).ilike('name', '%$q%').limit(20));
              if (rows.isEmpty) {
                try {
                  final byId = await db.from('rooms').select('id,name,owner_id,livekit_room_name,is_active,seat_count,country_code,tags,cover_url').eq('id', q).eq('is_active', true).maybeSingle();
                  if (byId != null) rows = [Map<String, dynamic>.from(byId)];
                } catch (_) {}
              }
            } catch (_) {}
            final users = List<Map<String, dynamic>>.from(await db.from('profiles').select('id,display_name,username,public_id,avatar_url,is_verified').or('username.ilike.%$q%,display_name.ilike.%$q%,public_id.eq.$q').limit(20));
            if (!sheet.mounted) return;
            Navigator.pop(sheet);
            final rooms = rows.map(VoiceRoomRecord.fromMap).toList();
            if (!mounted) return;
            await showModalBottomSheet<void>(
              context: context,
              backgroundColor: _bg,
              isScrollControlled: true,
              builder: (_) => Directionality(
                textDirection: TextDirection.rtl,
                child: SafeArea(
                  child: ListView(
                    padding: const EdgeInsets.all(14),
                    shrinkWrap: true,
                    children: [
                      const Text('نتائج البحث', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
                      const SizedBox(height: 10),
                      if (rooms.isEmpty && users.isEmpty) const _Empty('لم نجد غرفة أو مستخدماً بهذا البحث'),
                      if (rooms.isNotEmpty) ...[
                        const Text('الغرف', style: TextStyle(color: _gold, fontWeight: FontWeight.w900)),
                        const SizedBox(height: 6),
                        ...rooms.map((room) => _Room(room: room, onTap: () { Navigator.pop(context); Navigator.push(context, MaterialPageRoute(builder: (_) => RealVoiceRoomPage(room: room))); })),
                      ],
                      if (users.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        const Text('المستخدمون', style: TextStyle(color: _gold, fontWeight: FontWeight.w900)),
                        const SizedBox(height: 6),
                        ...users.map((u) => ListTile(
                          tileColor: _panel,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          leading: CircleAvatar(backgroundImage: (u['avatar_url']?.toString() ?? '').isNotEmpty ? NetworkImage(u['avatar_url'].toString()) : null, child: (u['avatar_url']?.toString() ?? '').isEmpty ? const Icon(Icons.person) : null),
                          title: Text(u['display_name']?.toString() ?? u['username']?.toString() ?? 'Asmar'),
                          subtitle: Text('ID ' + (u['public_id']?.toString() ?? u['id'].toString()), style: const TextStyle(color: _muted)),
                          trailing: u['is_verified'] == true ? const Icon(Icons.verified, color: _gold) : null,
                          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => AsmarPublicProfilePage(userId: u['id'].toString()))),
                        )),
                      ],
                    ],
                  ),
                ),
              ),
            );
          } catch (e) { if (sheet.mounted) Navigator.pop(sheet); _showHomeMessage('تعذر تنفيذ البحث'); }
        }, icon: const Icon(Icons.search), label: const Text('بحث'))])));
    c.dispose();
  }
  void _showHomeMessage(String message) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message))); }
  @override Widget build(BuildContext context) => CustomScrollView(slivers: [
    SliverToBoxAdapter(child: _HomeHeader(onSearch: searchRooms, onCreate: createRoom, onNotifications: () { _notifications(context); })),
    SliverToBoxAdapter(child: _Tabs(selected: tab, onChanged: (v) => setState(() => tab = v))),
    SliverToBoxAdapter(child: _CreateRoom(onTap: createRoom)),
    SliverToBoxAdapter(child: _Filters(selected: filter, onChanged: (v) => setState(() => filter = v))),
    const SliverToBoxAdapter(child: _Banners()),
    SliverToBoxAdapter(child: _Countries(selected: country, onChanged: (v) => setState(() => country = v))),
    SliverToBoxAdapter(child: _TitleRow(filter == 'مستخدمون' ? 'المستخدمون' : 'قائمة الغرف', 'مباشر الآن')),
    if (filter == 'مستخدمون')
      const _UserDirectorySliver()
    else
      StreamBuilder<List<Map<String,dynamic>>>(stream: repo.watchActiveRooms(), builder: (context, snap) {
        if (snap.hasError) return SliverToBoxAdapter(child: _Empty('تعذر تحميل الغرف'));
        final rooms = _applyFilters((snap.data ?? const <Map<String,dynamic>>[]).map(VoiceRoomRecord.fromMap).toList());
        if (rooms.isEmpty) return const SliverToBoxAdapter(child: _Empty('لا توجد غرف مباشرة الآن. أنشئ غرفتك الأولى.'));
        return SliverList.builder(itemCount: rooms.length, itemBuilder: (_, i) => _Room(room: rooms[i], onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => RealVoiceRoomPage(room: rooms[i])))));
      }),
    SliverToBoxAdapter(child: _DailyTreasure(onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const DailyTasksPage())))),
    const SliverToBoxAdapter(child: SizedBox(height: 25)),
  ]);
}
class _HomeHeader extends StatelessWidget {
  final VoidCallback onSearch, onCreate, onNotifications;
  const _HomeHeader({required this.onSearch, required this.onCreate, required this.onNotifications});
  @override Widget build(BuildContext context) => SafeArea(bottom: false, child: Padding(padding: const EdgeInsets.fromLTRB(14,12,14,7), child: Row(children: [
    const Text('Asmar', style: TextStyle(fontSize: 27, fontWeight: FontWeight.w900)), const Spacer(),
    _IconButton(Icons.search_rounded, onSearch), const SizedBox(width: 7), _IconButton(Icons.notifications_none_rounded, onNotifications), const SizedBox(width: 7), _IconButton(Icons.add_rounded, onCreate),
  ])));
}
class _TreasureFab extends StatelessWidget { final VoidCallback onTap; const _TreasureFab({required this.onTap}); @override Widget build(BuildContext c)=>Material(color:Colors.transparent,child:InkWell(onTap:onTap,borderRadius:BorderRadius.circular(30),child:Container(width:56,height:56,decoration:BoxDecoration(shape:BoxShape.circle,gradient:const LinearGradient(colors:[_gold,_orange]),boxShadow:[BoxShadow(color:_orange.withOpacity(.35),blurRadius:16,spreadRadius:2)]),child:const Icon(Icons.card_giftcard_rounded,color:Color(0xFF4A2100),size:29)))); }
class _IconButton extends StatelessWidget { final IconData icon; final VoidCallback onTap; const _IconButton(this.icon,this.onTap); @override Widget build(BuildContext c)=>InkWell(onTap:onTap,borderRadius:BorderRadius.circular(14),child:Container(width:40,height:40,decoration:BoxDecoration(color:_panel,borderRadius:BorderRadius.circular(14)),child:Icon(icon,color:Colors.white,size:21))); }
class _Tabs extends StatelessWidget { final String selected; final ValueChanged<String> onChanged; const _Tabs({required this.selected,required this.onChanged}); @override Widget build(BuildContext c)=>SizedBox(height:45,child:ListView(padding:const EdgeInsets.symmetric(horizontal:14),scrollDirection:Axis.horizontal,children:['لي','شائع','جديد','فيديو'].map((x)=>_Chip(x,selected==x,()=>onChanged(x))).toList())); }
class _CreateRoom extends StatelessWidget { final VoidCallback onTap; const _CreateRoom({required this.onTap}); @override Widget build(BuildContext c)=>Padding(padding:const EdgeInsets.fromLTRB(14,8,14,8),child:InkWell(onTap:onTap,borderRadius:BorderRadius.circular(18),child:Container(height:78,padding:const EdgeInsets.all(15),decoration:BoxDecoration(borderRadius:BorderRadius.circular(18),gradient:const LinearGradient(colors:[_gold,_orange])),child:const Row(children:[Icon(Icons.auto_awesome_rounded,color:Color(0xFF542300),size:31),SizedBox(width:10),Expanded(child:Column(mainAxisAlignment:MainAxisAlignment.center,crossAxisAlignment:CrossAxisAlignment.start,children:[Text('إنشاء غرفتي',style:TextStyle(color:Color(0xFF4C2000),fontSize:20,fontWeight:FontWeight.w900)),Text('غرفة صوتية بـ 8 كراسي',style:TextStyle(color:Color(0xFF633000),fontSize:11))])),Icon(Icons.add_circle_outline_rounded,color:Color(0xFF4C2000),size:31)])))); }
class _Filters extends StatelessWidget { final String selected; final ValueChanged<String> onChanged; const _Filters({required this.selected,required this.onChanged}); @override Widget build(BuildContext c)=>SizedBox(height:44,child:ListView(padding:const EdgeInsets.symmetric(horizontal:14),scrollDirection:Axis.horizontal,children:['الكل','متابعة','موثق','العائلة','غرف','مستخدمون'].map((x)=>_Chip(x,selected==x,()=>onChanged(x))).toList())); }
class _Banners extends StatelessWidget {
  const _Banners();
  @override
  Widget build(BuildContext c) => SizedBox(
    height: 76,
    child: ListView(
      padding: const EdgeInsets.fromLTRB(14, 8, 14, 6),
      scrollDirection: Axis.horizontal,
      children: [
        _Banner(Icons.workspace_premium_rounded, 'الثروة', 'ترتيب الأغنياء', () => Navigator.push(c, MaterialPageRoute(builder: (_) => const AsmarRankingPage(type: 'wealth')))),
        _Banner(Icons.bolt_rounded, 'CP', 'ترتيب CP', () => Navigator.push(c, MaterialPageRoute(builder: (_) => const AsmarRankingPage(type: 'cp')))),
        _Banner(Icons.groups_rounded, 'العائلة', 'ترتيب العائلة', () => Navigator.push(c, MaterialPageRoute(builder: (_) => const AsmarRankingPage(type: 'family')))),
      ],
    ),
  );
}
class _Banner extends StatelessWidget {
  final IconData icon;
  final String title, sub;
  final VoidCallback onTap;
  const _Banner(this.icon, this.title, this.sub, this.onTap);
  @override
  Widget build(BuildContext c) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(15),
    child: Container(
      width: 150,
      margin: const EdgeInsets.only(left: 8),
      padding: const EdgeInsets.all(9),
      decoration: BoxDecoration(color: _panel, borderRadius: BorderRadius.circular(15), border: Border.all(color: _gold.withOpacity(.35))),
      child: Row(children: [
        Icon(icon, color: _gold, size: 25),
        const SizedBox(width: 7),
        Expanded(child: Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.w900)),
          Text(sub, style: const TextStyle(color: _muted, fontSize: 9)),
        ])),
      ]),
    ),
  );
}
class _Countries extends StatelessWidget { final String selected; final ValueChanged<String> onChanged; const _Countries({required this.selected,required this.onChanged}); @override Widget build(BuildContext c)=>SizedBox(height:43,child:ListView(padding:const EdgeInsets.symmetric(horizontal:14),scrollDirection:Axis.horizontal,children:['Hot','Syria','Germany','Netherlands'].map((x)=>_Chip(x,selected==x,()=>onChanged(x))).toList())); }
class _DailyTreasure extends StatelessWidget { final VoidCallback onTap; const _DailyTreasure({required this.onTap}); @override Widget build(BuildContext c)=>Padding(padding:const EdgeInsets.fromLTRB(14,10,14,4),child:InkWell(onTap:onTap,borderRadius:BorderRadius.circular(18),child:Container(padding:const EdgeInsets.all(13),decoration:BoxDecoration(borderRadius:BorderRadius.circular(18),gradient:const LinearGradient(colors:[Color(0xFF5B2C09),Color(0xFF24110A)]),border:Border.all(color:_orange.withOpacity(.55))),child:const Row(children:[Icon(Icons.card_giftcard_rounded,color:_gold,size:31),SizedBox(width:10),Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text('الهدية اليومية',style:TextStyle(fontWeight:FontWeight.w900,fontSize:15)),Text('افتح صندوق الكنز وخذ مكافأتك اليوم',style:TextStyle(color:_muted,fontSize:10))])),Icon(Icons.chevron_left_rounded,color:_gold)])))); }

class _UserDirectorySliver extends StatelessWidget {
  const _UserDirectorySliver();
  @override
  Widget build(BuildContext context) {
    final future = Supabase.instance.client.from('profiles').select('id,display_name,username,public_id,avatar_url,is_verified,user_level').order('user_level', ascending: false).limit(100);
    return FutureBuilder(
      future: future,
      builder: (context, snapshot) {
        if (snapshot.hasError) return SliverToBoxAdapter(child: _Empty('تعذر تحميل المستخدمين'));
        if (snapshot.connectionState != ConnectionState.done) return const SliverToBoxAdapter(child: Center(child: Padding(padding: EdgeInsets.all(30), child: CircularProgressIndicator())));
        final rows = List<Map<String, dynamic>>.from(snapshot.data ?? const []);
        if (rows.isEmpty) return const SliverToBoxAdapter(child: _Empty('لا يوجد مستخدمون'));
        return SliverList.builder(
          itemCount: rows.length,
          itemBuilder: (_, i) {
            final u = rows[i];
            final avatar = u['avatar_url']?.toString() ?? '';
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
              child: Container(
                decoration: BoxDecoration(color: _panel, borderRadius: BorderRadius.circular(16)),
                child: ListTile(
                  leading: CircleAvatar(backgroundImage: avatar.isNotEmpty ? NetworkImage(avatar) : null, child: avatar.isEmpty ? const Icon(Icons.person) : null),
                  title: Row(children: [
                    Expanded(child: Text(u['display_name']?.toString() ?? u['username']?.toString() ?? 'Asmar', style: const TextStyle(fontWeight: FontWeight.w900))),
                    if (u['is_verified'] == true) const Icon(Icons.verified, color: _gold, size: 17),
                  ]),
                  subtitle: Text('ID ' + (u['public_id']?.toString() ?? u['id'].toString()) + ' • Lv.' + (u['user_level']?.toString() ?? '1'), style: const TextStyle(color: _muted, fontSize: 10)),
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => AsmarPublicProfilePage(userId: u['id'].toString()))),
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _Room extends StatelessWidget {
  final VoiceRoomRecord room;
  final VoidCallback onTap;
  const _Room({required this.room, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: RoomSocialRepository().watchSeats(room.id),
      builder: (context, snapshot) {
        final count = (snapshot.data ?? const <Map<String, dynamic>>[])
            .where((x) => x['occupant_id'] != null)
            .length;
        final cover = room.coverUrl ?? '';
        return Padding(
          padding: const EdgeInsets.fromLTRB(14, 5, 14, 5),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(17),
            child: Container(
              padding: const EdgeInsets.all(11),
              decoration: BoxDecoration(
                color: _panel,
                borderRadius: BorderRadius.circular(17),
                border: Border.all(color: const Color(0xFF2B315A)),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 27,
                    backgroundColor: _purple,
                    backgroundImage: cover.isNotEmpty ? NetworkImage(cover) : null,
                    child: cover.isEmpty ? const Icon(Icons.mic, color: Colors.white) : null,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          room.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15),
                        ),
                        const SizedBox(height: 5),
                        Row(
                          children: [
                            const Icon(Icons.circle, color: Colors.redAccent, size: 8),
                            const SizedBox(width: 5),
                            const Text('LIVE', style: TextStyle(color: _muted, fontSize: 10)),
                            const SizedBox(width: 12),
                            const Icon(Icons.people_alt_rounded, color: _muted, size: 14),
                            const SizedBox(width: 4),
                            Text(count.toString() + '/' + room.seatCount.toString(), style: const TextStyle(color: _muted, fontSize: 10)),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_left_rounded, color: _gold),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _AyomeGamesPage extends StatelessWidget {
  const _AyomeGamesPage();
  @override
  Widget build(BuildContext context) => const AsmarGamesPage();
}

class _AyomeMessagesPage extends StatelessWidget {
  const _AyomeMessagesPage();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(14, 18, 14, 28),
      children: [
        const SafeArea(
          bottom: false,
          child: Text('الرسائل', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900)),
        ),
        const SizedBox(height: 15),
        _Message(
          'Asmar Team',
          'الدردشة الرسمية والدعم',
          Icons.verified_user_rounded,
          () => Navigator.push(context, MaterialPageRoute(builder: (_) => const GlobalChatPage())),
        ),
        _Message(
          'المحادثات الخاصة',
          'رسائلك مع المستخدمين والأصدقاء',
          Icons.chat_rounded,
          () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PrivateConversationsPage())),
        ),
        _Message(
          'الإشعارات',
          'التنبيهات والتحديثات',
          Icons.notifications_rounded,
          () => _notifications(context),
        ),
      ],
    );
  }
}

class _Message extends StatelessWidget {
  final String title;
  final String sub;
  final IconData icon;
  final VoidCallback tap;

  const _Message(this.title, this.sub, this.icon, this.tap);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        onTap: tap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            color: _panel,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFF2B315A)),
          ),
          child: Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(colors: [_purple, _pink]),
                ),
                child: Icon(icon, color: Colors.white),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(fontWeight: FontWeight.w900)),
                    const SizedBox(height: 4),
                    Text(sub, style: const TextStyle(color: _muted, fontSize: 11)),
                  ],
                ),
              ),
              const Icon(Icons.chevron_left_rounded, color: _gold),
            ],
          ),
        ),
      ),
    );
  }
}

Future<void> _notifications(BuildContext context) async { final db=Supabase.instance.client; final uid=db.auth.currentUser?.id; if(uid==null)return; await showModalBottomSheet<void>(context:context,isScrollControlled:true,backgroundColor:_bg,builder:(_)=>SizedBox(height:MediaQuery.of(context).size.height*.72,child:StreamBuilder<List<Map<String,dynamic>>>(stream:db.from('notifications').stream(primaryKey:['id']).order('created_at',ascending:false),builder:(c,s){final rows=(s.data??const <Map<String,dynamic>>[]).where((x)=>x['user_id']==uid).toList();if(rows.isEmpty)return const Center(child:Text('لا توجد إشعارات حالياً',style:TextStyle(color:_muted)));return ListView.separated(padding:const EdgeInsets.all(16),itemCount:rows.length,separatorBuilder:(_,__)=>const SizedBox(height:8),itemBuilder:(_,i)=>ListTile(tileColor:_panel,shape:RoundedRectangleBorder(borderRadius:BorderRadius.circular(16)),leading:const Icon(Icons.notifications_active_rounded,color:_gold),title:Text(rows[i]['title']?.toString()??'إشعار'),subtitle:Text(rows[i]['body']?.toString()??'',style:const TextStyle(color:_muted))));}))); }

class _AyomeProfilePage extends StatefulWidget {
  const _AyomeProfilePage();

  @override
  State<_AyomeProfilePage> createState() => _AyomeProfilePageState();
}

class _AyomeProfilePageState extends State<_AyomeProfilePage> {
  Map<String, dynamic> p = {};
  int followers = 0;
  int following = 0;
  int friends = 0;
  int visitors = 0;

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;
    try {
      final db = Supabase.instance.client;
      final profile = await db
          .from('profiles')
          .select('display_name,username,public_id,coins,diamonds,user_level,svip_level,is_verified,avatar_url,language')
          .eq('id', user.id)
          .maybeSingle();
      final followersRows = List<Map<String, dynamic>>.from(await db.from('follows').select('follower_id').eq('following_id', user.id));
      final followingRows = List<Map<String, dynamic>>.from(await db.from('follows').select('following_id').eq('follower_id', user.id));
      final followerIds = followersRows.map((x) => x['follower_id'].toString()).toSet();
      final followingIds = followingRows.map((x) => x['following_id'].toString()).toSet();
      final visitorRows = await db.from('visitors').select('visitor_id').eq('profile_id', user.id);
      if (!mounted) return;
      setState(() {
        p = Map<String, dynamic>.from(profile ?? {});
        followers = followerIds.length;
        following = followingIds.length;
        friends = followerIds.intersection(followingIds).length;
        visitors = (visitorRows as List).length;
      });
    } catch (_) {}
  }

  void _message(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  void _openSettings() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: _panel,
      builder: (sheet) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const ListTile(title: Text('الإعدادات', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900))),
            ListTile(
              leading: const Icon(Icons.language, color: _gold),
              title: const Text('اللغة'),
              subtitle: Text((p['language'] ?? 'ar').toString()),
              onTap: () async {
                final lang = await showDialog<String>(context: sheet, builder: (d) => SimpleDialog(
                  title: const Text('اختر اللغة'),
                  children: [
                    SimpleDialogOption(onPressed: () => Navigator.pop(d, 'ar'), child: const Text('العربية')),
                    SimpleDialogOption(onPressed: () => Navigator.pop(d, 'en'), child: const Text('English')),
                    SimpleDialogOption(onPressed: () => Navigator.pop(d, 'de'), child: const Text('Deutsch')),
                    SimpleDialogOption(onPressed: () => Navigator.pop(d, 'nl'), child: const Text('Nederlands')),
                  ],
                ));
                if (lang == null) return;
                await Supabase.instance.client.from('profiles').update({'language': lang}).eq('id', Supabase.instance.client.auth.currentUser!.id);
                if (mounted) { Navigator.pop(sheet); await load(); }
              },
            ),
            ListTile(
              leading: const Icon(Icons.lock_outline, color: _gold),
              title: const Text('الخصوصية'),
              onTap: () {
                Navigator.pop(sheet);
                _message('إعدادات الخصوصية الأساسية مرتبطة بسياسات قاعدة البيانات. الحظر متاح من قسم الحظر.');
              },
            ),
            ListTile(
              leading: const Icon(Icons.block, color: _gold),
              title: const Text('الحظر'),
              onTap: () {
                Navigator.pop(sheet);
                Navigator.push(context, MaterialPageRoute(builder: (_) => const AsmarBlockedUsersPage()));
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline, color: Colors.redAccent),
              title: const Text('حذف الحساب'),
              onTap: () async {
                Navigator.pop(sheet);
                final ok = await showDialog<bool>(context: context, builder: (d) => AlertDialog(
                  title: const Text('حذف الحساب'),
                  content: const Text('سيتم تعطيل حسابك فوراً ولا يمكن استخدامه حتى تعيد تفعيله من الإدارة. هل تريد المتابعة؟'),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(d, false), child: const Text('إلغاء')),
                    FilledButton(onPressed: () => Navigator.pop(d, true), child: const Text('تعطيل الحساب')),
                  ],
                ));
                if (ok == true) {
                  try {
                    await Supabase.instance.client.rpc('deactivate_my_account');
                    await Supabase.instance.client.auth.signOut();
                  } catch (e) {
                    if (mounted) _message('تعذر تعطيل الحساب: ' + e.toString());
                  }
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final name = (p['display_name'] ?? p['username'] ?? 'Asmar User').toString();
    final publicId = (p['public_id'] ?? '—').toString();
    final avatar = (p['avatar_url'] ?? '').toString();
    final level = (p['user_level'] ?? 0).toString();

    return RefreshIndicator(
      onRefresh: load,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(14, 18, 14, 30),
        children: [
          const SafeArea(
            bottom: false,
            child: Text('أنا', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900)),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(22),
              gradient: const LinearGradient(
                colors: [Color(0xFF2A155F), Color(0xFF10152E)],
              ),
              border: Border.all(color: Color(0xFF4B3972)),
            ),
            child: Column(
              children: [
                CircleAvatar(
                  radius: 43,
                  backgroundColor: _purple,
                  backgroundImage: avatar.isNotEmpty ? NetworkImage(avatar) : null,
                  child: avatar.isEmpty
                      ? Text(
                          name.isEmpty ? 'A' : name.characters.first.toUpperCase(),
                          style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w900),
                        )
                      : null,
                ),
                const SizedBox(height: 10),
                Text(name, style: const TextStyle(fontSize: 21, fontWeight: FontWeight.w900)),
                const SizedBox(height: 2),
                Text('ID $publicId', style: const TextStyle(color: _muted, fontSize: 11)),
                const SizedBox(height: 15),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _Stat(followers.toString(), 'المتابعون'),
                    _Stat(following.toString(), 'المتابَعون'),
                    _Stat(friends.toString(), 'الأصدقاء'),
                    _Stat(visitors.toString(), 'الزائرون'),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          _Action(
            'رصيدي',
            'الشحن والسحب والتحويل',
            Icons.account_balance_wallet_rounded,
            () => Navigator.push(context, MaterialPageRoute(builder: (_) => const WalletPage())),
          ),
          _Action(
            'تحويل Coins',
            'تحويل آمن من رصيدك إلى مستخدم آخر',
            Icons.swap_horiz_rounded,
            () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AsmarTransferPage())),
          ),
          _Action(
            'SVIP',
            'الاشتراك والمزايا',
            Icons.workspace_premium_rounded,
            () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SvipPage())),
          ),
          _Action(
            'معرض الشارة',
            'الشارات والإنجازات الفعلية',
            Icons.military_tech_rounded,
            () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AsmarBadgesPage())),
          ),
          _Action(
            'المتجر',
            'الإطارات والعناصر',
            Icons.storefront_rounded,
            () => Navigator.push(context, MaterialPageRoute(builder: (_) => const StorePage())),
          ),
          _Action(
            'إكسسواراتي',
            'العناصر المملوكة فعلياً',
            Icons.auto_awesome_rounded,
            () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AsmarAccessoriesPage())),
          ),
          _Action('العائلة', 'العائلة والترتيب', Icons.groups_rounded, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AsmarFamilyPage()))),
          _Action('المستوى', 'Lv.$level', Icons.star_rounded, () => () async { final row = await Supabase.instance.client.from('user_exp').select('exp').eq('user_id', Supabase.instance.client.auth.currentUser!.id).maybeSingle(); if (mounted) _message('المستوى الحالي: $level • XP: ${row?['exp'] ?? 0}'); }),
          _Action(
            'الهدايا',
            'الهدايا والجوائز',
            Icons.card_giftcard_rounded,
            () => Navigator.push(context, MaterialPageRoute(builder: (_) => const WalletGiftsPage())),
          ),
          _Action(
            'المهام اليومية',
            'المكافآت اليومية',
            Icons.task_alt_rounded,
            () => Navigator.push(context, MaterialPageRoute(builder: (_) => const DailyTasksPage())),
          ),
          _Action('مركز المساعدة', 'الدعم والمساعدة', Icons.help_outline_rounded, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const GlobalChatPage()))),
          _Action('الإعدادات', 'الخصوصية واللغة والحساب', Icons.settings_rounded, _openSettings),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: () => Supabase.instance.client.auth.signOut(),
            icon: const Icon(Icons.logout_rounded),
            label: const Text('تسجيل الخروج'),
          ),
        ],
      ),
    );
  }
}

class _Action extends StatelessWidget { final String title,sub; final IconData icon; final VoidCallback tap; const _Action(this.title,this.sub,this.icon,this.tap); @override Widget build(BuildContext c)=>Padding(padding:const EdgeInsets.only(bottom:8),child:InkWell(onTap:tap,borderRadius:BorderRadius.circular(16),child:Container(padding:const EdgeInsets.symmetric(horizontal:14,vertical:12),decoration:BoxDecoration(color:_panel,borderRadius:BorderRadius.circular(16)),child:Row(children:[Icon(icon,color:_gold,size:25),const SizedBox(width:12),Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text(title,style:const TextStyle(fontWeight:FontWeight.w900)),const SizedBox(height:2),Text(sub,style:const TextStyle(color:_muted,fontSize:10))])),const Icon(Icons.chevron_left_rounded,color:_muted)])))); }
class _Stat extends StatelessWidget { final String value,label; const _Stat(this.value,this.label); @override Widget build(BuildContext c)=>Column(children:[Text(value,style:const TextStyle(fontSize:17,fontWeight:FontWeight.w900)),const SizedBox(height:3),Text(label,style:const TextStyle(color:_muted,fontSize:9))]); }
class _Chip extends StatelessWidget { final String label; final bool selected; final VoidCallback tap; const _Chip(this.label,this.selected,this.tap); @override Widget build(BuildContext c)=>Padding(padding:const EdgeInsets.only(left:7),child:ChoiceChip(label:Text(label,style:TextStyle(fontSize:11,fontWeight:selected?FontWeight.w900:FontWeight.w500)),selected:selected,onSelected:(_)=>tap(),selectedColor:_gold,backgroundColor:_panel,side:BorderSide(color:selected?_gold:const Color(0xFF2B315A)))); }
class _TitleRow extends StatelessWidget { final String a,b; const _TitleRow(this.a,this.b); @override Widget build(BuildContext c)=>Padding(padding:const EdgeInsets.fromLTRB(14,10,14,4),child:Row(children:[Text(a,style:const TextStyle(fontSize:18,fontWeight:FontWeight.w900)),const Spacer(),Text(b,style:const TextStyle(color:_gold,fontSize:11,fontWeight:FontWeight.w800))])); }
class _Empty extends StatelessWidget { final String text; const _Empty(this.text); @override Widget build(BuildContext c)=>Container(margin:const EdgeInsets.all(14),padding:const EdgeInsets.all(28),decoration:BoxDecoration(color:_panel,borderRadius:BorderRadius.circular(18)),child:Center(child:Text(text,textAlign:TextAlign.center,style:const TextStyle(color:_muted)))); }
InputDecoration input(String label)=>InputDecoration(labelText:label,filled:true,fillColor:_panel2,border:OutlineInputBorder(borderRadius:BorderRadius.circular(16),borderSide:BorderSide.none));