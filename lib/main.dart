import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'backend_config.dart';
import 'admin_panel.dart';
import 'role_centers.dart';
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
import 'rocket_levels.dart';
import 'wallet.dart';
import 'plinko_demo.dart';
import 'slot_demo.dart';
import 'chicken_crossing_demo.dart';

const gold = Color(0xFFFFD36A);
const gold2 = Color(0xFFB77921);
const bg = Color(0xFF090604);
const card = Color(0xFF1B0E08);

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
    url: BackendConfig.supabaseUrl,
    publishableKey: BackendConfig.supabasePublishableKey,
    // On Flutter Web, use the implicit OAuth flow so Supabase handles the
    // Google callback in the browser without leaving a ?code= URL behind.
    // Mobile keeps the more secure PKCE flow.
    authOptions: FlutterAuthClientOptions(
      authFlowType: kIsWeb ? AuthFlowType.implicit : AuthFlowType.pkce,
    ),
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

enum _AuthMode { login, create, idLogin }

class _LoginPageState extends State<LoginPage> {
  _AuthMode mode = _AuthMode.login;
  final email = TextEditingController();
  final password = TextEditingController();
  final publicId = TextEditingController();
  bool loading = false;
  String? error;

  Future<void> _loginWithEmail() async {
    final e = email.text.trim();
    final p = password.text;
    if (e.isEmpty || p.isEmpty) {
      setState(() => error = 'أدخل البريد الإلكتروني وكلمة المرور');
      return;
    }
    setState(() { loading = true; error = null; });
    try {
      await Supabase.instance.client.auth.signInWithPassword(email: e, password: p);
    } catch (e) {
      if (mounted) setState(() => error = 'تعذر تسجيل الدخول. تأكد من البيانات.');
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> _createAccount() async {
    final e = email.text.trim();
    final p = password.text;
    if (e.isEmpty || p.length < 6) {
      setState(() => error = 'أدخل بريدًا صحيحًا وكلمة مرور من 6 أحرف على الأقل');
      return;
    }
    setState(() { loading = true; error = null; });
    try {
      final response = await Supabase.instance.client.auth.signUp(
        email: e,
        password: p,
      );
      if (response.session == null && mounted) {
        setState(() => error = 'تم إنشاء الحساب. تحقق من بريدك الإلكتروني ثم سجّل الدخول.');
      }
    } catch (e) {
      if (mounted) setState(() => error = 'تعذر إنشاء الحساب. جرّب بريدًا آخر.');
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> _loginWithId() async {
    final id = publicId.text.trim();
    final p = password.text;
    if (id.isEmpty || p.isEmpty) {
      setState(() => error = 'أدخل الـID وكلمة المرور');
      return;
    }
    setState(() { loading = true; error = null; });
    try {
      final response = await Supabase.instance.client.functions.invoke(
        'login-by-id',
        body: {'public_id': id, 'password': p},
      );
      final data = response.data;
      if (data is! Map || data['access_token'] == null || data['refresh_token'] == null) {
        throw Exception('Invalid login response');
      }
      await Supabase.instance.client.auth.setSession(
        data['refresh_token'].toString(),
        accessToken: data['access_token'].toString(),
      );
    } catch (e) {
      if (mounted) setState(() => error = 'الـID أو كلمة المرور غير صحيحة');
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> _loginWithGoogle() async {
    setState(() { loading = true; error = null; });
    try {
      if (kIsWeb) {
        await Supabase.instance.client.auth.signInWithOAuth(
          OAuthProvider.google,
          redirectTo: Uri.base.origin,
          authScreenLaunchMode: LaunchMode.externalApplication,
        );
      } else {
        const webClientId = String.fromEnvironment('GOOGLE_WEB_CLIENT_ID');
        if (webClientId.isEmpty) {
          throw Exception('GOOGLE_WEB_CLIENT_ID is not configured');
        }
        final google = GoogleSignIn.instance;
        await google.initialize(serverClientId: webClientId);
        final account = await google.authenticate();
        final auth = account.authentication;
        final authorization = await account.authorizationClient.authorizationForScopes(const <String>[]);
        final idToken = auth.idToken;
        final accessToken = authorization?.accessToken;
        if (idToken == null || accessToken == null) {
          throw Exception('Google tokens were not returned');
        }
        await Supabase.instance.client.auth.signInWithIdToken(
          provider: OAuthProvider.google,
          idToken: idToken,
          accessToken: accessToken,
        );
      }
    } catch (e) {
      if (mounted) setState(() => error = 'تعذر تسجيل الدخول بواسطة Google. تأكد من إعداد Google OAuth وSHA-256 للتطبيق.');
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  void dispose() {
    email.dispose();
    password.dispose();
    publicId.dispose();
    super.dispose();
  }

  Widget _field(TextEditingController controller, String label, {bool password = false, TextInputType? type}) {
    return TextField(
      controller: controller,
      obscureText: password,
      keyboardType: type,
      style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white54),
        filled: true,
        fillColor: const Color(0xFF160B06),
        prefixIcon: Icon(
          password ? Icons.lock_outline_rounded : Icons.alternate_email_rounded,
          color: gold,
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 17),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFF4C2B12)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: gold, width: 1.4),
        ),
      ),
    );
  }

  Widget _mainButton({
    required String label,
    required IconData icon,
    required VoidCallback? onPressed,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: FilledButton.icon(
        onPressed: loading ? null : onPressed,
        icon: Icon(icon, size: 22),
        label: Text(
          label,
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900),
        ),
        style: FilledButton.styleFrom(
          backgroundColor: gold,
          foregroundColor: Colors.black,
          disabledBackgroundColor: const Color(0xFF5A4525),
          disabledForegroundColor: Colors.black54,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
      ),
    );
  }

  Widget _googleButton() {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: OutlinedButton(
        onPressed: loading ? null : _loginWithGoogle,
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.white,
          side: const BorderSide(color: Color(0xFF6A4522), width: 1.2),
          backgroundColor: const Color(0xFF160B06),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 28,
              height: 28,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'G',
                style: TextStyle(
                  color: Color(0xFF4285F4),
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Text(
              mode == _AuthMode.create ? 'إنشاء حساب باستخدام Google' : 'تسجيل الدخول باستخدام Google',
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
            ),
          ],
        ),
      ),
    );
  }

  Widget _modeButton(String label, IconData icon, _AuthMode value) {
    final selected = mode == value;
    return Expanded(
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        height: 44,
        decoration: BoxDecoration(
          color: selected ? gold : const Color(0xFF160B06),
          borderRadius: BorderRadius.circular(13),
          border: Border.all(
            color: selected ? gold : const Color(0xFF4C2B12),
            width: 1,
          ),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(13),
            onTap: loading ? null : () => setState(() {
              mode = value;
              error = null;
            }),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 17, color: selected ? Colors.black : gold),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    label,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: selected ? Colors.black : Colors.white70,
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _orDivider() {
    return Row(
      children: const [
        Expanded(child: Divider(color: Color(0xFF3B2412))),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 12),
          child: Text('أو', style: TextStyle(color: Colors.white38, fontSize: 12)),
        ),
        Expanded(child: Divider(color: Color(0xFF3B2412))),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final isId = mode == _AuthMode.idLogin;
    final isCreate = mode == _AuthMode.create;

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 28, 20, 24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 430),
              child: Container(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 22),
                decoration: BoxDecoration(
                  color: const Color(0xFF0F0804),
                  borderRadius: BorderRadius.circular(26),
                  border: Border.all(color: const Color(0xFF3B2412)),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x66000000),
                      blurRadius: 28,
                      offset: Offset(0, 14),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 66,
                      height: 66,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: const LinearGradient(
                          colors: [gold, gold2],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x445A3610),
                            blurRadius: 18,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: const Center(
                        child: Text(
                          'أسمر',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 13),
                    const Text(
                      'ASMAR CHAT',
                      style: TextStyle(
                        color: gold,
                        fontSize: 25,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 2,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      isCreate
                          ? 'أنشئ حسابك وابدأ الآن'
                          : isId
                              ? 'ادخل بحسابك باستخدام الـID'
                              : 'أهلاً بك، سجّل دخولك للمتابعة',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.white54, fontSize: 12),
                    ),
                    const SizedBox(height: 22),

                    // خيارات الدخول الرئيسية بشكل موحّد.
                    Row(
                      children: [
                        _modeButton('تسجيل الدخول', Icons.login_rounded, _AuthMode.login),
                        const SizedBox(width: 7),
                        _modeButton('إنشاء حساب', Icons.person_add_alt_1_rounded, _AuthMode.create),
                        const SizedBox(width: 7),
                        _modeButton('بالـID', Icons.badge_rounded, _AuthMode.idLogin),
                      ],
                    ),
                    const SizedBox(height: 22),

                    if (isId) ...[
                      _field(publicId, 'ID المستخدم', type: TextInputType.number),
                      const SizedBox(height: 12),
                      _field(password, 'كلمة المرور', password: true),
                      const SizedBox(height: 18),
                      _mainButton(
                        label: 'تسجيل الدخول بالـID',
                        icon: Icons.badge_rounded,
                        onPressed: _loginWithId,
                      ),
                    ] else ...[
                      _field(email, 'البريد الإلكتروني', type: TextInputType.emailAddress),
                      const SizedBox(height: 12),
                      _field(password, 'كلمة المرور', password: true),
                      const SizedBox(height: 18),
                      _mainButton(
                        label: isCreate ? 'إنشاء الحساب' : 'تسجيل الدخول',
                        icon: isCreate ? Icons.person_add_alt_1_rounded : Icons.login_rounded,
                        onPressed: isCreate ? _createAccount : _loginWithEmail,
                      ),
                      const SizedBox(height: 15),
                      _orDivider(),
                      const SizedBox(height: 15),
                      _googleButton(),
                    ],

                    if (error != null) ...[
                      const SizedBox(height: 14),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        decoration: BoxDecoration(
                          color: const Color(0x332A0C08),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0x664A1710)),
                        ),
                        child: Text(
                          error!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Color(0xFFFF8A80),
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],

                    const SizedBox(height: 15),
                    Text(
                      isId
                          ? 'استخدم الـID الظاهر في ملفك الشخصي مع كلمة المرور.'
                          : 'بعد إنشاء الحساب سيظهر لك ID خاص يمكنك استخدامه عند العودة للتطبيق.',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.white30, fontSize: 10.5, height: 1.4),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
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
  late Future<List<Map<String, dynamic>>> _quickActionsFuture;

  @override
  void initState() {
    super.initState();
    _roomsFuture = _loadRooms();
    _quickActionsFuture = _loadQuickActions();
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
  Future<List<Map<String, dynamic>>> _loadQuickActions() async {
    final data = await Supabase.instance.client
        .from('home_quick_actions')
        .select('id,label,icon_name,action_key,sort_order')
        .eq('is_active', true)
        .order('sort_order', ascending: true);
    return List<Map<String, dynamic>>.from(data);
  }

  IconData _quickActionIcon(String name) {
    const icons = <String, IconData>{
      'favorite': Icons.favorite_rounded,
      'favorite_border': Icons.favorite_border_rounded,
      'apps': Icons.apps_rounded,
      'stars': Icons.stars_rounded,
      'groups': Icons.groups_rounded,
      'person': Icons.person_rounded,
      'diamond': Icons.diamond_rounded,
    };
    return icons[name] ?? Icons.apps_rounded;
  }

  void _openQuickAction(Map<String, dynamic> action) {
    final key = action['action_key']?.toString() ?? '';
    if (key == 'more') {
      Navigator.push(context, MaterialPageRoute(builder: (_) => const Discover()));
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(action['label']?.toString() ?? ''),
        backgroundColor: gold2,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showHomeAction(String label) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(label),
        backgroundColor: gold2,
        behavior: SnackBarBehavior.floating,
      ),
    );
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
                  padding: const EdgeInsets.fromLTRB(16, 2, 16, 10),
                  child: SizedBox(
                    height: 58,
                    child: FutureBuilder<List<Map<String, dynamic>>>(
                      future: _quickActionsFuture,
                      builder: (context, snapshot) {
                        final actions = snapshot.data ?? const <Map<String, dynamic>>[];
                        if (snapshot.connectionState != ConnectionState.done && actions.isEmpty) {
                          return const Center(child: SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)));
                        }
                        return ListView(
                          scrollDirection: Axis.horizontal,
                          reverse: true,
                          children: actions.map((action) => _HomeQuickAction(
                            label: action['label']?.toString() ?? '',
                            icon: _quickActionIcon(action['icon_name']?.toString() ?? ''),
                            onTap: () => _openQuickAction(action),
                          )).toList(),
                        );
                      },
                    ),
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

class _HomeQuickAction extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  const _HomeQuickAction({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          child: Container(
            width: 92,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(
              color: const Color(0xFF1B0E08),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: gold2),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: gold, size: 20),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ],
            ),
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
  Widget build(BuildContext context) => const WalletPage();
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
          .select('username,role,country_code,vip_level,svip_level,public_id,avatar_url,avatar_is_animated,activity_admin_badge,customer_service_badge,is_verified')
          .eq('id', user.id)
          .maybeSingle();
      final data = Map<String, dynamic>.from(
        row ?? {'role': 'USER', 'username': user.email ?? 'مستخدم'},
      );
      data['role'] = (data['role'] ?? 'USER').toString().toUpperCase();
      return data;
    } catch (_) {
      return {'role': 'USER', 'username': user.email ?? 'مستخدم'};
    }
  }

  void _info(String title) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(title),
        backgroundColor: gold2,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _openWhatsApp() async {
    const phone = '963997048001';
    const msg = 'السلام عليكم';
    final url = Uri.parse(
      'https://wa.me/$phone?text=${Uri.encodeComponent(msg)}',
    );
    try {
      final opened = await launchUrl(
        url,
        mode: LaunchMode.externalApplication,
      );
      if (!opened && mounted) _info('تعذر فتح واتساب');
    } catch (_) {
      if (mounted) _info('تعذر فتح واتساب');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1109),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _profileFuture,
        builder: (context, snapshot) {
          final p = snapshot.data ?? const <String, dynamic>{};
          final role = p['role']?.toString() ?? 'USER';
          final username = p['username']?.toString() ?? 'مستخدم';
          final country = p['country_code']?.toString();
          final vip = p['vip_level']?.toString();
          final publicId = p['public_id']?.toString() ?? '---';
          final avatarUrl = p['avatar_url']?.toString();
          final animated = p['avatar_is_animated'] == true;

          return Directionality(
            textDirection: TextDirection.rtl,
            child: RefreshIndicator(
              color: gold,
              backgroundColor: card,
              onRefresh: () async {
                setState(() => _profileFuture = _loadProfile());
                await _profileFuture;
              },
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  SliverToBoxAdapter(
                    child: Container(
                      padding: const EdgeInsets.fromLTRB(16, 20, 16, 14),
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Color(0xFF2B1508),
                            Color(0xFF1A1109),
                          ],
                        ),
                      ),
                      child: Row(
                        children: [
                          const Text(
                            'أنا',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const Spacer(),
                          IconButton(
                            onPressed: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const NotificationsPage(),
                              ),
                            ),
                            icon: const Icon(
                              Icons.settings_outlined,
                              color: Colors.white70,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: _ProfileIdentity(
                      username: username,
                      publicId: publicId,
                      country: country,
                      vip: vip,
                      svipLevel: int.tryParse('${p['svip_level'] ?? 0}') ?? 0,
                      role: role,
                      avatarUrl: avatarUrl,
                      animated: animated,
                      activityAdmin: p['activity_admin_badge'] == true,
                      customerService: p['customer_service_badge'] == true,
                      verified: p['is_verified'] == true,
                      onAvatarSaved: () => setState(
                        () => _profileFuture = _loadProfile(),
                      ),
                    ),
                  ),

                  // احصائيات
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: const [
                          _SimpleStat(value: '0', label: 'المتابعون'),
                          _SimpleStat(value: '1', label: 'التالي'),
                          _SimpleStat(value: '5', label: 'الزوار'),
                        ],
                      ),
                    ),
                  ),

                  // بنر X20
                  SliverToBoxAdapter(
                    child: Container(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 8,
                      ),
                      height: 60,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        gradient: const LinearGradient(
                          colors: [Color(0xFF8A1A1A), Color(0xFFFFA000)],
                        ),
                        border: Border.all(
                          color: const Color(0xFFFFD700),
                          width: 1.2,
                        ),
                      ),
                      child: const Row(
                        children: [
                          SizedBox(width: 10),
                          Icon(Icons.card_giftcard, color: Colors.yellow),
                          SizedBox(width: 8),
                          Text(
                            'انتصر',
                            style: TextStyle(color: Colors.white),
                          ),
                          Spacer(),
                          Text(
                            'X20  10000  يرسل',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(width: 10),
                          CircleAvatar(
                            radius: 18,
                            backgroundColor: Colors.white24,
                          ),
                          SizedBox(width: 10),
                        ],
                      ),
                    ),
                  ),

                  // SVIP / VIP
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Row(
                        children: [
                          Expanded(
                            child: _SimpleMembershipCard(
                              title: 'SVIP',
                              subtitle: 'Supreme Membership',
                              icon: Icons.diamond_outlined,
                              onTap: () => _info('SVIP — معلومات العضوية'),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _SimpleMembershipCard(
                              title: vip == null || vip.isEmpty ? 'VIP' : vip,
                              subtitle: 'Growth Privilege',
                              icon: Icons.workspace_premium_outlined,
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const VipPage(),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SliverToBoxAdapter(child: SizedBox(height: 12)),

                  // شنطة / محل / محفظة
                  SliverToBoxAdapter(
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 12),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2C1E10),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: const Color(0xFF8B6A2A),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _MiddleAction(
                            icon: Icons.shopping_bag,
                            label: 'شنطة',
                            onTap: () => _info('الشنطة'),
                          ),
                          _MiddleAction(
                            icon: Icons.account_balance,
                            label: 'محل',
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const StorePage(),
                              ),
                            ),
                          ),
                          _MiddleAction(
                            icon: Icons.wallet,
                            label: 'محفظة',
                            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const WalletPage())),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // القائمة
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(0, 0, 0, 24),
                    sliver: SliverList(
                      delegate: SliverChildListDelegate([
                        _ProfileMenuTile(
                          'عائلة',
                          Icons.family_restroom,
                          () => _info('العائلة'),
                        ),
                        _ProfileMenuTile(
                          'CP',
                          Icons.favorite,
                          () => _info('CP'),
                        ),
                        _ProfileMenuTile(
                          'الأخ والأخت',
                          Icons.military_tech,
                          () => _info('الأخ والأخت'),
                        ),
                        _ProfileMenuTile(
                          'المستوى',
                          Icons.star,
                          () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const VipPage(),
                            ),
                          ),
                        ),
                        _ProfileMenuTile(
                          'مركز المضيف',
                          Icons.badge,
                          () => _info('مركز المضيف'),
                        ),
                        _ProfileMenuTile(
                          'تواصل مع المسؤول الرسمي',
                          Icons.phone,
                          _openWhatsApp,
                        ),
                        _ProfileMenuTile(
                          'جلسة',
                          Icons.settings,
                          () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const NotificationsPage(),
                            ),
                          ),
                        ),
                        _ProfileMenuTile(
                          'الأصدقاء',
                          Icons.people_outline,
                          () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const FriendsPage(),
                            ),
                          ),
                        ),
                        _ProfileMenuTile(
                          'الإشعارات',
                          Icons.notifications_none,
                          () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const NotificationsPage(),
                            ),
                          ),
                        ),
                        if (['CEO', 'SUPER_ADMIN', 'MANAGER', 'BD', 'ADMIN', 'AGENT', 'HOST'].contains(role))
                          _ProfileMenuTile(
                            role == 'CEO'
                                ? '👑 لوحة Chat الرئيسية'
                                : role == 'SUPER_ADMIN'
                                    ? '🛡️ مركز Super Admin'
                                    : role == 'MANAGER'
                                        ? '👨‍💼 مركز Manager'
                                        : role == 'BD'
                                            ? '💼 مركز BD'
                                            : role == 'ADMIN'
                                                ? '🛡️ مركز Admin'
                                                : role == 'AGENT'
                                                    ? '🏢 مركز الوكيل'
                                                    : '🎙️ مركز المضيف',
                            Icons.admin_panel_settings_outlined,
                            () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => RoleCenterPage(role: role),
                              ),
                            ),
                          ),
                        _ProfileMenuTile(
                          '🎮 الألعاب التجريبية',
                          Icons.sports_esports,
                          () => Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const PlinkoDemoPage()),
                          ),
                        ),
                        _ProfileMenuTile(
                          '🐔 عبور الدجاجة تجريبية',
                          Icons.pets,
                          () => Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const ChickenCrossingDemoPage()),
                          ),
                        ),
                        _ProfileMenuTile(
                          '🎰 سلوت تجريبية',
                          Icons.casino,
                          () => Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const SlotDemoPage()),
                          ),
                        ),
                        _ProfileMenuTile(
                          'وكيل الشحن',
                          Icons.currency_exchange,
                          () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const AgentRechargePage(),
                            ),
                          ),
                        ),
                      ]),
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

class _ProfileIdentity extends StatelessWidget {
  final String username;
  final String publicId;
  final String? country;
  final String? vip;
  final int svipLevel;
  final String role;
  final String? avatarUrl;
  final bool animated;
  final bool activityAdmin;
  final bool customerService;
  final bool verified;
  final VoidCallback onAvatarSaved;

  const _ProfileIdentity({
    required this.username,
    required this.publicId,
    required this.country,
    required this.vip,
    required this.svipLevel,
    required this.role,
    required this.avatarUrl,
    required this.animated,
    required this.activityAdmin,
    required this.customerService,
    required this.verified,
    required this.onAvatarSaved,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 14),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF1A1109), Color(0xFF100804)],
        ),
      ),
      child: Column(
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              RankFrame(
                role: role,
                vipLevel: vip,
                svipLevel: svipLevel,
                size: 126,
                child: CircleAvatar(
                  radius: 45,
                  backgroundColor: const Color(0xFF120A06),
                  backgroundImage: avatarUrl != null && avatarUrl!.isNotEmpty
                      ? NetworkImage(avatarUrl!)
                      : null,
                  child: avatarUrl == null || avatarUrl!.isEmpty
                      ? const Icon(Icons.person, color: gold, size: 44)
                      : null,
                ),
              ),
              Positioned(
                bottom: 1,
                right: 3,
                child: Material(
                  color: gold2,
                  shape: const CircleBorder(),
                  child: IconButton(
                    iconSize: 18,
                    onPressed: () => showModalBottomSheet(
                      context: context,
                      backgroundColor: card,
                      builder: (_) => Padding(
                        padding: const EdgeInsets.all(18),
                        child: AvatarPickerButton(
                          avatarUrl: avatarUrl,
                          isAnimated: animated,
                          vipLevel: vip,
                          role: role,
                          publicId: publicId,
                          onSaved: onAvatarSaved,
                        ),
                      ),
                    ),
                    icon: const Icon(Icons.camera_alt, color: Colors.black),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              CountryFlag(code: country, size: 22),
              const SizedBox(width: 7),
              Flexible(
                child: Text(
                  username,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 5),
          Text(
            'ID: $publicId',
            style: const TextStyle(
              color: gold,
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 7),
          ProfileBadges(
            activityAdmin: activityAdmin,
            customerService: customerService,
            verified: verified,
          ),
          const SizedBox(height: 5),
          Text(
            vip != null && vip!.isNotEmpty
                ? vip!
                : (role == 'AGENT' ? 'COIN SELLER' : role),
            style: const TextStyle(
              color: gold,
              fontSize: 12,
              fontWeight: FontWeight.w900,
              letterSpacing: 1,
            ),
          ),
        ],
      ),
    );
  }
}

class _SimpleStat extends StatelessWidget {
  final String value;
  final String label;
  const _SimpleStat({required this.value, required this.label});

  @override
  Widget build(BuildContext context) => Column(
        children: [
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 12,
            ),
          ),
        ],
      );
}

class _SimpleMembershipCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;

  const _SimpleMembershipCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          height: 50,
          decoration: BoxDecoration(
            color: const Color(0xFF1F160B),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFF8B6A2A)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: gold2, size: 20),
              const SizedBox(width: 7),
              Flexible(
                child: Text(
                  subtitle,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white54,
                    fontSize: 8,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
}

class _ProfileMenuTile extends StatelessWidget {
  final String title;
  final IconData icon;
  final VoidCallback onTap;

  const _ProfileMenuTile(this.title, this.icon, this.onTap);

  @override
  Widget build(BuildContext context) => Container(
        decoration: const BoxDecoration(
          border: Border(
            bottom: BorderSide(color: Color(0xFF2C1E10)),
          ),
        ),
        child: ListTile(
          onTap: onTap,
          leading: const Icon(
            Icons.arrow_back_ios,
            size: 16,
            color: Color(0xFFD4A054),
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title,
                style: const TextStyle(color: Colors.white70),
              ),
              const SizedBox(width: 10),
              Icon(
                icon,
                color: const Color(0xFFD4A054),
                size: 24,
              ),
            ],
          ),
        ),
      );
}

class _MiddleAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _MiddleAction({required this.icon, required this.label, required this.onTap});
  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(10),
    child: Column(mainAxisSize: MainAxisSize.min, children: [
      Icon(icon, color: gold2, size: 26),
      const SizedBox(height: 4),
      Text(label, style: const TextStyle(color: Colors.white70, fontSize: 11)),
    ]),
  );
}
