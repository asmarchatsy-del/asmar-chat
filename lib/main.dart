import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'backend_config.dart';
import 'admin_panel.dart';
import 'room.dart';
import 'store.dart';
import 'agent_recharge.dart';
import 'rank_frame.dart';
import 'vip.dart';
import 'country_flag.dart';
import 'notifications.dart';
import 'friends.dart';
import 'private_conversations.dart';
import 'avatar_picker.dart';
import 'profile_badges.dart';
import 'gift_banner.dart';
import 'global_chat.dart';
import 'messages.dart';

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



class LaunchPromotion extends StatefulWidget {
  const LaunchPromotion({super.key});
  @override
  State<LaunchPromotion> createState() => _LaunchPromotionState();
}
class _LaunchPromotionState extends State<LaunchPromotion> {
  late Future<Map<String, dynamic>?> _future;
  @override
  void initState(){ super.initState(); _future=_loadPromotion(); }
  Future<Map<String,dynamic>?> _loadPromotion() async {
    final now=DateTime.now().toIso8601String();
    final rows=await Supabase.instance.client.from('app_promotions')
      .select('id,title,subtitle,image_url,first_place,second_place,third_place,first_prize,second_prize,third_prize,button_text')
      .eq('is_active',true).lte('starts_at',now).or('ends_at.is.null,ends_at.gte.$now')
      .order('created_at',ascending:false).limit(1);
    if(rows.isEmpty)return null;
    return Map<String,dynamic>.from(rows.first);
  }
  void _enter(){Navigator.pushReplacement(context,MaterialPageRoute(builder:(_)=>const Shell()));}
  @override Widget build(BuildContext context){
    return Scaffold(backgroundColor:const Color(0xFF050302),body:SafeArea(child:FutureBuilder<Map<String,dynamic>?>(
      future:_future,builder:(context,snapshot){
        if(snapshot.connectionState!=ConnectionState.done)return const Center(child:CircularProgressIndicator(color:gold));
        final p=snapshot.data;
        if(p==null)return Center(child:FilledButton(onPressed:_enter,child:const Text('دخول إلى Asmar Chat')));
        return Stack(children:[
          if((p['image_url']??'').toString().isNotEmpty)Positioned.fill(child:Image.network(p['image_url'].toString(),fit:BoxFit.cover,errorBuilder:(_,__,___)=>const SizedBox.shrink())),
          Positioned.fill(child:DecoratedBox(decoration:BoxDecoration(gradient:LinearGradient(begin:Alignment.topCenter,end:Alignment.bottomCenter,colors:[Colors.black.withOpacity(.12),Colors.black.withOpacity(.76),Colors.black.withOpacity(.97)])))),
          SingleChildScrollView(padding:const EdgeInsets.fromLTRB(20,18,20,28),child:Column(children:[
            Align(alignment:Alignment.topLeft,child:IconButton(onPressed:_enter,icon:const Icon(Icons.close,color:Colors.white70))),
            const SizedBox(height:12),
            const Text('ASMAR CHAT',style:TextStyle(color:gold,fontSize:30,fontWeight:FontWeight.w900,letterSpacing:2)),
            const SizedBox(height:16),
            Text(p['title']?.toString()??'حدث الشحن',textAlign:TextAlign.center,style:const TextStyle(color:Colors.white,fontSize:28,fontWeight:FontWeight.w900)),
            if((p['subtitle']??'').toString().isNotEmpty) ...[const SizedBox(height:8),Text(p['subtitle'].toString(),textAlign:TextAlign.center,style:const TextStyle(color:Colors.white70,fontSize:14))],
            const SizedBox(height:22),
            _PrizeCard(place:p['first_place']?.toString()??'المركز الأول',prize:p['first_prize']?.toString()??'الجائزة الأولى',icon:Icons.emoji_events,large:true),
            const SizedBox(height:10),
            Row(children:[
              Expanded(child:_PrizeCard(place:p['second_place']?.toString()??'المركز الثاني',prize:p['second_prize']?.toString()??'الجائزة الثانية',icon:Icons.workspace_premium)),
              const SizedBox(width:10),
              Expanded(child:_PrizeCard(place:p['third_place']?.toString()??'المركز الثالث',prize:p['third_prize']?.toString()??'الجائزة الثالثة',icon:Icons.military_tech)),
            ]),
            const SizedBox(height:22),
            SizedBox(width:double.infinity,height:52,child:FilledButton.icon(onPressed:_enter,icon:const Icon(Icons.rocket_launch),label:Text(p['button_text']?.toString()??'شارك الآن'),style:const ButtonStyle(backgroundColor:WidgetStatePropertyAll(gold2)))),
          ]))
        ]);
      },
    )));
  }
}
class _PrizeCard extends StatelessWidget{
  final String place,prize; final IconData icon; final bool large;
  const _PrizeCard({required this.place,required this.prize,required this.icon,this.large=false});
  @override Widget build(BuildContext context)=>Container(
    padding:EdgeInsets.all(large?20:14),
    decoration:BoxDecoration(borderRadius:BorderRadius.circular(22),gradient:const LinearGradient(colors:[Color(0xFF2A160A),Color(0xFF0E0704)]),border:Border.all(color:gold2,width:1.2),boxShadow:const[BoxShadow(color:Color(0x55000000),blurRadius:18,offset:Offset(0,8))]),
    child:Row(children:[
      Container(width:large?58:46,height:large?58:46,decoration:const BoxDecoration(shape:BoxShape.circle,gradient:LinearGradient(colors:[gold,gold2])),child:Icon(icon,color:Colors.black,size:large?31:24)),
      const SizedBox(width:12),Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
        Text(place,style:TextStyle(color:gold,fontSize:large?18:14,fontWeight:FontWeight.w900)),
        const SizedBox(height:4),Text(prize,maxLines:2,overflow:TextOverflow.ellipsis,style:TextStyle(color:Colors.white,fontSize:large?15:12,fontWeight:FontWeight.bold))
      ]))
    ])
  );
}
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});
  @override Widget build(BuildContext context){
    final supabase=Supabase.instance.client;
    return StreamBuilder<AuthState>(stream:supabase.auth.onAuthStateChange,builder:(context,snapshot){
      if(supabase.auth.currentSession!=null)return const LaunchPromotion();
      return const LoginPage();
    });
  }
}
class LoginPage extends StatefulWidget {
  const LoginPage({super.key});
  @override State<LoginPage> createState() => _LoginPageState();
}
class _LoginPageState extends State<LoginPage> {
  final email = TextEditingController();
  final password = TextEditingController();
  bool loading = false;
  String? error;
  Future<void> _submit() async {
    final e=email.text.trim(), p=password.text;
    if(e.isEmpty || p.isEmpty){setState(()=>error='أدخل البريد وكلمة المرور');return;}
    setState(()=>loading=true);
    try {
      await Supabase.instance.client.auth.signInWithPassword(email:e,password:p);
    } catch (_) {
      try {
        await Supabase.instance.client.auth.signUp(email:e,password:p);
      } catch (e) {
        if(mounted)setState(()=>error='تعذر تسجيل الدخول: $e');
      }
    } finally { if(mounted)setState(()=>loading=false); }
  }
  @override void dispose(){email.dispose();password.dispose();super.dispose();}
  @override Widget build(BuildContext context)=>Scaffold(
    backgroundColor:bg,
    body:SafeArea(child:Center(child:SingleChildScrollView(padding:const EdgeInsets.all(24),child:Column(mainAxisSize:MainAxisSize.min,children:[
      const Text('ASMAR CHAT',style:TextStyle(color:gold,fontSize:32,fontWeight:FontWeight.w900,letterSpacing:2)),
      const SizedBox(height:8),const Text('تسجيل الدخول',style:TextStyle(color:Colors.white70,fontSize:16)),
      const SizedBox(height:28),
      TextField(controller:email,keyboardType:TextInputType.emailAddress,style:const TextStyle(color:Colors.white),decoration:const InputDecoration(labelText:'البريد الإلكتروني')),
      const SizedBox(height:12),
      TextField(controller:password,obscureText:true,style:const TextStyle(color:Colors.white),decoration:const InputDecoration(labelText:'كلمة المرور')),
      if(error!=null)Padding(padding:const EdgeInsets.only(top:12),child:Text(error!,style:const TextStyle(color:Colors.redAccent))),
      const SizedBox(height:20),
      SizedBox(width:double.infinity,height:50,child:FilledButton(onPressed:loading?null:_submit,child:loading?const SizedBox(width:20,height:20,child:CircularProgressIndicator(strokeWidth:2)):const Text('دخول / إنشاء حساب'))),
    ])))));
}
class Shell extends StatefulWidget {
  const Shell({super.key});
  @override State<Shell> createState()=>_ShellState();
}
class _ShellState extends State<Shell> {
  int index=0;
  final pages=<Widget>[const Home(), const MessagesPage(), const MomentsPage(), const Profile()];
  @override Widget build(BuildContext context)=>Scaffold(
    body:GlobalGiftBanner(child:IndexedStack(index:index,children:pages)),
    bottomNavigationBar:NavigationBar(
      selectedIndex:index,
      onDestinationSelected:(i)=>setState(()=>index=i),
      destinations:const[
        NavigationDestination(icon:Icon(Icons.home_outlined),selectedIcon:Icon(Icons.home),label:'الرئيسية'),
        NavigationDestination(icon:Icon(Icons.forum_outlined),selectedIcon:Icon(Icons.forum),label:'الرسائل'),
        NavigationDestination(icon:Icon(Icons.auto_awesome_outlined),selectedIcon:Icon(Icons.auto_awesome),label:'لحظات'),
        NavigationDestination(icon:Icon(Icons.person_outline),selectedIcon:Icon(Icons.person),label:'أنا'),
      ],
    ),
  );
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

  static const games = <Map<String, String>>[
    {'name': 'CRANK', 'icon': '⚙️'},
    {'name': 'FRANKEN STARS', 'icon': '⭐'},
    {'name': 'DRAGON TIGER', 'icon': '🐉'},
    {'name': 'FOOTBALL', 'icon': '⚽'},
    {'name': 'RACING', 'icon': '🏎️'},
    {'name': 'GREEDY WOLF', 'icon': '🐺'},
    {'name': 'LAVA SLOT', 'icon': '🌋'},
    {'name': 'PLINKO', 'icon': '🎯'},
    {'name': 'SWEET PARTY', 'icon': '🍭'},
    {'name': 'FRUIT BLAST', 'icon': '🍉'},
    {'name': 'ALI BABA', 'icon': '🕌'},
    {'name': 'SPEED WIN', 'icon': '🏁'},
    {'name': 'GOLDEN TEMPLE', 'icon': '🏯'},
    {'name': 'SUPER ELEMENTS', 'icon': '⚡'},
    {'name': 'ROYAL FISHING', 'icon': '🎣'},
    {'name': 'CANDY BURST', 'icon': '🍬'},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('الألعاب', style: TextStyle(color: gold, fontWeight: FontWeight.w900)),
        centerTitle: true,
      ),
      body: GridView.builder(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 4,
          crossAxisSpacing: 8,
          mainAxisSpacing: 10,
          childAspectRatio: .72,
        ),
        itemCount: games.length,
        itemBuilder: (context, i) {
          final game = games[i];
          return InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () => ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(game['name']! + ' — سيتم فتح اللعبة عند ربطها')),
            ),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF3A1D0D), Color(0xFF120805)],
                ),
                border: Border.all(color: Color(0xFF6A421A)),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      color: Color(0xFF241207),
                      border: Border.all(color: Color(0xFFB77921)),
                    ),
                    child: Center(
                      child: Text(game['icon']!, style: const TextStyle(fontSize: 26)),
                    ),
                  ),
                  const SizedBox(height: 7),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 3),
                    child: Text(
                      game['name']!,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w800),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class MomentsPage extends StatelessWidget {
  const MomentsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('لحظات', style: TextStyle(color: gold, fontWeight: FontWeight.w900)),
        centerTitle: true,
      ),
      body: const Center(
        child: Text(
          'لحظات',
          style: TextStyle(color: gold, fontSize: 28, fontWeight: FontWeight.w900),
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

class Profile extends StatefulWidget {
  const Profile({super.key});

  @override
  State<Profile> createState() => _ProfileState();
}

class _ProfileState extends State<Profile> {
  late Future<Map<String, dynamic>> _profileFuture;

  @override
  void initState() {
    super.initState();
    _profileFuture = _loadProfile();
  }

  Future<Map<String, dynamic>> _loadProfile() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return {'role': 'USER', 'username': 'مستخدم'};
    try {
      final row = await Supabase.instance.client
          .from('profiles')
          .select('username,role,country_code,vip_level,public_id,avatar_url,avatar_is_animated,activity_admin_badge,customer_service_badge,is_verified')
          .eq('id', user.id)
          .maybeSingle();
      return Map<String, dynamic>.from(
        row ?? {'role': 'USER', 'username': user.email ?? 'مستخدم'},
      );
    } catch (_) {
      return {'role': 'USER', 'username': user.email ?? 'مستخدم'};
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('حسابي')),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _profileFuture,
        builder: (context, snapshot) {
          final profile = snapshot.data ?? const <String, dynamic>{};
          final role = profile['role']?.toString() ?? 'USER';
          final username = profile['username']?.toString() ?? 'مستخدم';
          final country = profile['country_code']?.toString();
          final vip = profile['vip_level']?.toString();
          final publicId = profile['public_id']?.toString() ?? '---';

          return Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  if (snapshot.connectionState != ConnectionState.done)
                    const Padding(
                      padding: EdgeInsets.only(bottom: 14),
                      child: CircularProgressIndicator(color: gold),
                    ),
                  AvatarPickerButton(
                    avatarUrl: profile['avatar_url']?.toString(),
                    isAnimated: profile['avatar_is_animated'] == true,
                    vipLevel: vip,
                    role: role,
                    publicId: publicId,
                    onSaved: () => setState(() { _profileFuture = _loadProfile(); }),
                  ),
                  const SizedBox(height: 10),
                  RankFrame(
                    role: role,
                    vipLevel: vip,
                    size: 88,
                    child: const CircleAvatar(
                      backgroundColor: Color(0xFF120A06),
                      child: Icon(Icons.person, color: gold, size: 42),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(mainAxisSize: MainAxisSize.min, children: [
                    CountryFlag(code: country, size: 22),
                    const SizedBox(width: 7),
                    Text(
                      username,
                      style: const TextStyle(color: Colors.white,fontSize: 20,fontWeight: FontWeight.w900),
                    ),
                    const SizedBox(width: 8),
                    Text('ID: $publicId',style: const TextStyle(color: gold,fontSize: 11,fontWeight: FontWeight.w800)),
                  ]),
                  const SizedBox(height: 5),
                  DropdownButton<String>(
                    value: countryNames.containsKey(country) ? country : null,
                    hint: const Text('اختر الدولة', style: TextStyle(color: Colors.white54)),
                    dropdownColor: card,
                    items: countryNames.entries.map((e)=>DropdownMenuItem(value:e.key,child:Row(children:[CountryFlag(code:e.key,size:20),const SizedBox(width:8),Text(e.value)]))).toList(),
                    onChanged: (v) async { if(v==null) return; final user=Supabase.instance.client.auth.currentUser; if(user==null)return; await Supabase.instance.client.from('profiles').update({'country_code':v}).eq('id',user.id); if(mounted)setState(()=>_profileFuture=_loadProfile()); },
                  ),
                  const SizedBox(height: 7),
                  ProfileBadges(activityAdmin: profile['activity_admin_badge'] == true, customerService: profile['customer_service_badge'] == true, verified: profile['is_verified'] == true),
                  const SizedBox(height: 5),
                  Text(
                    vip != null && vip.isNotEmpty ? vip : (role == 'AGENT' ? 'COIN SELLER' : role),
                    style: const TextStyle(
                      color: gold,
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1,
                    ),
                  ),
                  StreamBuilder<List<Map<String,dynamic>>>(
                    stream: Supabase.instance.client.from('notifications').stream(primaryKey: ['id']),
                    builder: (context, snap) {
                      final uid=Supabase.instance.client.auth.currentUser?.id;
                      final unread=(snap.data??[]).where((x)=>x['user_id']==uid && x['is_read']!=true).length;
                      return Stack(children:[
                        SizedBox(width:double.infinity,child:OutlinedButton.icon(
                          onPressed:()=>Navigator.push(context,MaterialPageRoute(builder:(_)=>const NotificationsPage())),
                          icon:const Icon(Icons.notifications,color:gold),label:const Text('الإشعارات'),
                        )),
                        if(unread>0) Positioned(left:12,top:6,child:Container(padding:const EdgeInsets.symmetric(horizontal:7,vertical:3),decoration:const BoxDecoration(color:Colors.red,shape:BoxShape.circle),child:Text(unread>99?'99+':unread.toString(),style:const TextStyle(color:Colors.white,fontSize:10,fontWeight:FontWeight.w900)))),
                      ]);
                    },
                  ),
                  SizedBox(width:double.infinity,child:OutlinedButton.icon(
                    onPressed:()=>Navigator.push(context,MaterialPageRoute(builder:(_)=>const FriendsPage())),
                    icon:const Icon(Icons.people_alt,color:gold),label:const Text('الأصدقاء وطلبات الصداقة'),
                  )),
                  const SizedBox(height: 12),
                  SizedBox(width:double.infinity,child:OutlinedButton.icon(
                    onPressed:()=>Navigator.push(context,MaterialPageRoute(builder:(_)=>const MessagesPage())),
                    icon:const Icon(Icons.forum,color:gold),label:const Text('الرسائل'),
                  )),
                  const SizedBox(height: 12),
                  const SizedBox(height: 28),
                  const Text(
                    'الملف الشخصي',
                    style: TextStyle(
                      color: gold,
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                    ),
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
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const AgentRechargePage()),
                      );
                    },
                    icon: const Icon(Icons.currency_exchange),
                    label: const Text('وكيل الشحن'),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
