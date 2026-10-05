import 'package:flutter/material.dart';

void main() => runApp(const AsmarChatApp());

class AsmarChatApp extends StatelessWidget {
  const AsmarChatApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Asmar Chat - Yalla System',
      theme: ThemeData(useMaterial3: true, scaffoldBackgroundColor: const Color(0xFF0F172A), colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF8B5CF6), brightness: Brightness.dark)),
      home: const MainNav(),
    );
  }
}

// MODELS
class UserModel { String name; String bio; int level; int coins; String avatar; UserModel({this.name="Asmar", this.bio="ملك أسمر شات 👑", this.level=12, this.coins=5580, this.avatar="👑"}); }
class RoomModel { String id; String name; String topic; int users; List<String?> seats; RoomModel({required this.id, required this.name, required this.topic, required this.users, required this.seats}); }

// GLOBAL
UserModel currentUser = UserModel();
List<RoomModel> mockRooms = [
  RoomModel(id:"1", name:"غرفة أسمر الملكية 👑", topic:"طرب وسهر", users: 156, seats: ["👑", "🎤", "🎧", null, "😎", null, null, "🎶"]),
  RoomModel(id:"2", name:"غرفة يلا ❤️", topic:"دردشة عامة", users: 89, seats: ["❤️", "💋", null, null, null, null, null, null]),
];

// MAIN NAV - YALLA SYSTEM
class MainNav extends StatefulWidget { const MainNav({super.key}); @override State<MainNav> createState() => _MainNavState(); }
class _MainNavState extends State<MainNav> {
  int index = 0;
  final pages = [const HomeRoomsPage(), const GiftsPage(), const ProfilePage()];
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: pages[index],
      bottomNavigationBar: NavigationBar(selectedIndex: index, onDestinationSelected: (i)=> setState(()=> index=i), backgroundColor: const Color(0xFF1E293B), destinations: const [NavigationDestination(icon: Icon(Icons.mic), label: "الغرف"), NavigationDestination(icon: Icon(Icons.card_giftcard), label: "الهدايا"), NavigationDestination(icon: Icon(Icons.person), label: "البروفايل")]),
    );
  }
}

// HOME
class HomeRoomsPage extends StatefulWidget { const HomeRoomsPage({super.key}); @override State<HomeRoomsPage> createState() => _HomeRoomsPageState(); }
class _HomeRoomsPageState extends State<HomeRoomsPage> {
  @override
  Widget build(BuildContext context) {
    return SafeArea(child: Column(children: [
      Padding(padding: const EdgeInsets.all(16), child: Row(children: [CircleAvatar(backgroundColor: const Color(0xFF8B5CF6), child: Text(currentUser.avatar)), const SizedBox(width: 12), Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(currentUser.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)), Text("Level ${currentUser.level} | ${currentUser.coins} 💰", style: const TextStyle(color: Colors.white70, fontSize: 12))]), const Spacer(), IconButton(onPressed: ()=> Navigator.push(context, MaterialPageRoute(builder: (_)=> const SuperAdminPage())), icon: const Icon(Icons.admin_panel_settings, color: Colors.amber))])),
      Expanded(child: ListView.builder(padding: const EdgeInsets.all(12), itemCount: mockRooms.length, itemBuilder: (c,i){ final r=mockRooms[i]; return Card(color: const Color(0xFF1E293B), child: ListTile(onTap: ()=> Navigator.push(context, MaterialPageRoute(builder: (_)=> RoomInsidePage(room: r))), leading: CircleAvatar(child: Text("${i+1}")), title: Text(r.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)), subtitle: Text("${r.topic} • ${r.users} متصل", style: const TextStyle(color: Colors.white60)), trailing: const Icon(Icons.mic, color: Colors.greenAccent))); })),
      Padding(padding: const EdgeInsets.all(12), child: SizedBox(width: double.infinity, child: ElevatedButton.icon(onPressed: (){ setState(()=> mockRooms.insert(0, RoomModel(id: DateTime.now().toString(), name: "غرفة ${currentUser.name}", topic: "جديدة", users: 1, seats: [currentUser.avatar, null,null,null,null,null,null,null]))); }, icon: const Icon(Icons.add), label: const Text("إنشاء غرفة جديدة"), style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF8B5CF6), padding: const EdgeInsets.all(16))))),
    ]));
  }
}

// ROOM INSIDE - YALLA SYSTEM + GAMES BUTTON BOTTOM LEFT (LIKE YOUR ARROW)
class RoomInsidePage extends StatefulWidget { final RoomModel room; const RoomInsidePage({super.key, required this.room}); @override State<RoomInsidePage> createState() => _RoomInsidePageState(); }
class _RoomInsidePageState extends State<RoomInsidePage> {
  int? mySeat; final chatCtrl = TextEditingController(); final List<String> chat = ["النظام: أهلاً بك 👑", "سارة: هلا والله 😍"];
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.room.name), backgroundColor: const Color(0xFF1E293B)),
      body: Column(children: [
        Container(padding: const EdgeInsets.all(12), color: const Color(0xFF1E293B), child: GridView.builder(shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 4, childAspectRatio: 0.8, crossAxisSpacing: 8, mainAxisSpacing: 8), itemCount: 8, itemBuilder: (c,i){ final occupied = widget.room.seats[i]!= null; final isMe = mySeat==i; return GestureDetector(onTap: (){ if(!occupied){ setState((){ if(mySeat!=null) widget.room.seats[mySeat!]=null; widget.room.seats[i]=currentUser.avatar; mySeat=i; }); } else if(isMe){ setState((){ widget.room.seats[i]=null; mySeat=null; }); } }, child: Container(decoration: BoxDecoration(color: isMe? const Color(0xFF8B5CF6) : const Color(0xFF334155), borderRadius: BorderRadius.circular(12), border: Border.all(color: isMe? Colors.amber: Colors.transparent, width: 2)), child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Text(occupied? widget.room.seats[i]! : "➕", style: const TextStyle(fontSize: 32)), const SizedBox(height: 4), Text(occupied? (isMe? "أنت": "مستخدم ${i+1}") : "فارغ", style: const TextStyle(color: Colors.white70, fontSize: 10)), if(occupied) const Icon(Icons.mic, color: Colors.greenAccent, size: 14)]))); })),
        Padding(padding: const EdgeInsets.all(8), child: Row(children: [Expanded(child: ElevatedButton.icon(onPressed: (){}, icon: Icon(mySeat!=null? Icons.mic_off : Icons.mic), label: Text(mySeat!=null? "ميوت": "اطلب مايك"), style: ElevatedButton.styleFrom(backgroundColor: mySeat!=null? Colors.red: Colors.green))), const SizedBox(width: 8), Expanded(child: ElevatedButton.icon(onPressed: ()=> Navigator.pop(context), icon: const Icon(Icons.exit_to_app), label: const Text("خروج"), style: ElevatedButton.styleFrom(backgroundColor: Colors.grey.shade700)))])),
        const Divider(color: Colors.white10),
        Expanded(child: ListView.builder(itemCount: chat.length, itemBuilder: (c,i)=> Padding(padding: const EdgeInsets.symmetric(horizontal:12, vertical:4), child: Text(chat[i], style: const TextStyle(color: Colors.white70))))),

        // BOTTOM BAR - YALLA STYLE + GAMES BUTTON ON LEFT LIKE YOUR IMAGE
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          color: const Color(0xFF1E293B),
          child: Row(children: [
            // LEFT: GIFT + GAMES (Your arrow place)
            Container(width: 44, height: 44, decoration: const BoxDecoration(shape: BoxShape.circle, gradient: LinearGradient(colors: [Colors.purple, Colors.pink])), child: const Icon(Icons.card_giftcard, color: Colors.white)),
            const SizedBox(width: 10),
            GestureDetector(
              onTap: ()=> Navigator.push(context, MaterialPageRoute(builder: (_)=> const SlotGamesPage())),
              child: Container(width: 48, height: 48, decoration: BoxDecoration(shape: BoxShape.circle, color: const Color(0xFF0F172A), border: Border.all(color: Colors.amber, width: 2)), child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [const Text("🎮", style: TextStyle(fontSize: 18)), const Text("Games", style: TextStyle(color: Colors.amber, fontSize: 7, fontWeight: FontWeight.bold))])),
            ),
            const SizedBox(width: 8),
            Expanded(child: TextField(controller: chatCtrl, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(hintText: "اكتب رسالة...", hintStyle: TextStyle(color: Colors.white30), filled: true, fillColor: Color(0xFF0F172A), border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12)), borderSide: BorderSide.none), contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8)))),
            const SizedBox(width: 8),
            IconButton(onPressed: (){ if(chatCtrl.text.isNotEmpty){ setState(()=> chat.add("${currentUser.name}: ${chatCtrl.text}")); chatCtrl.clear(); } }, icon: const Icon(Icons.send, color: Color(0xFF8B5CF6))),
            const SizedBox(width: 4),
            Container(width: 40, height: 40, decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withOpacity(0.1)), child: const Icon(Icons.more_horiz, color: Colors.white)),
          ]),
        ),
      ]),
    );
  }
}

// GIFTS
class GiftsPage extends StatelessWidget { const GiftsPage({super.key}); @override Widget build(BuildContext context) { final gifts = ["🌹","💎","👑","🚀","🦁","❤️","🎁","🏆"]; return SafeArea(child: GridView.builder(padding: const EdgeInsets.all(16), gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 4, crossAxisSpacing:12, mainAxisSpacing:12), itemCount: gifts.length, itemBuilder: (c,i)=> Card(color: const Color(0xFF1E293B), child: InkWell(onTap: (){ ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("أرسلت ${gifts[i]} 🎉"))); }, child: Center(child: Text(gifts[i], style: const TextStyle(fontSize: 40))))))); } }

// PROFILE - 100% WORKING
class ProfilePage extends StatefulWidget { const ProfilePage({super.key}); @override State<ProfilePage> createState() => _ProfilePageState(); }
class _ProfilePageState extends State<ProfilePage> {
  @override Widget build(BuildContext context) {
    return SafeArea(child: ListView(padding: const EdgeInsets.all(20), children: [
      Center(child: Stack(children: [CircleAvatar(radius: 50, backgroundColor: const Color(0xFF8B5CF6), child: Text(currentUser.avatar, style: const TextStyle(fontSize: 40))), Positioned(bottom: 0, right: 0, child: InkWell(onTap: _editAvatar, child: const CircleAvatar(radius: 16, backgroundColor: Colors.amber, child: Icon(Icons.edit, size: 16, color: Colors.black))))])),
      const SizedBox(height: 12), Center(child: Text(currentUser.name, style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold))), Center(child: Text(currentUser.bio, style: const TextStyle(color: Colors.white60))), const SizedBox(height: 20),
      _tile(Icons.edit, "تعديل الاسم", onTap: _editName), _tile(Icons.text_fields, "تعديل البايو", onTap: _editBio), _tile(Icons.star, "المستوى ${currentUser.level}", onTap: (){}), _tile(Icons.monetization_on, "${currentUser.coins} عملة", onTap: (){ setState(()=> currentUser.coins+=100); }), const Divider(color: Colors.white10), _tile(Icons.settings, "الإعدادات", onTap: ()=> Navigator.push(context, MaterialPageRoute(builder: (_)=> const SettingsPage()))), _tile(Icons.admin_panel_settings, "لوحة السوبر أدمن", isAdmin: true, onTap: ()=> Navigator.push(context, MaterialPageRoute(builder: (_)=> const SuperAdminPage()))),
    ]));
  }
  Widget _tile(IconData icon, String title, {bool isAdmin=false, required VoidCallback onTap}) => Card(color: isAdmin? Colors.amber.withOpacity(0.15): const Color(0xFF1E293B), child: ListTile(leading: Icon(icon, color: isAdmin? Colors.amber: Colors.white70), title: Text(title, style: TextStyle(color: isAdmin? Colors.amber: Colors.white)), trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.white30), onTap: onTap));
  void _editAvatar(){ final avatars = ["👑","😎","🦁","🔥","❤️","😂","👨‍🎤","👩‍🎤"]; showModalBottomSheet(context: context, backgroundColor: const Color(0xFF1E293B), builder: (_)=> GridView.builder(padding: const EdgeInsets.all(20), gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 4), itemCount: avatars.length, itemBuilder: (c,i)=> InkWell(onTap: (){ setState(()=> currentUser.avatar=avatars[i]); Navigator.pop(context); }, child: Center(child: Text(avatars[i], style: const TextStyle(fontSize: 40)))))); }
  void _editName(){ final ctrl = TextEditingController(text: currentUser.name); showDialog(context: context, builder: (_)=> AlertDialog(backgroundColor: const Color(0xFF1E293B), title: const Text("تعديل الاسم", style: TextStyle(color: Colors.white)), content: TextField(controller: ctrl, style: const TextStyle(color: Colors.white)), actions: [TextButton(onPressed: (){ setState(()=> currentUser.name=ctrl.text); Navigator.pop(context); }, child: const Text("حفظ"))])); }
  void _editBio(){ final ctrl = TextEditingController(text: currentUser.bio); showDialog(context: context, builder: (_)=> AlertDialog(backgroundColor: const Color(0xFF1E293B), title: const Text("تعديل البايو", style: TextStyle(color: Colors.white)), content: TextField(controller: ctrl, style: const TextStyle(color: Colors.white)), actions: [TextButton(onPressed: (){ setState(()=> currentUser.bio=ctrl.text); Navigator.pop(context); }, child: const Text("حفظ"))])); }
}

// SETTINGS
class SettingsPage extends StatelessWidget { const SettingsPage({super.key}); @override Widget build(BuildContext context) { return Scaffold(appBar: AppBar(title: const Text("الإعدادات"), backgroundColor: const Color(0xFF1E293B)), body: ListView(children: [SwitchListTile(value: true, onChanged: (_){}, title: const Text("الإشعارات", style: TextStyle(color: Colors.white)), secondary: const Icon(Icons.notifications, color: Colors.white70)), ListTile(leading: const Icon(Icons.logout, color: Colors.red), title: const Text("تسجيل خروج", style: TextStyle(color: Colors.red)), onTap: (){})])); } }

// SUPER ADMIN
class SuperAdminPage extends StatefulWidget { const SuperAdminPage({super.key}); @override State<SuperAdminPage> createState() => _SuperAdminPageState(); }
class _SuperAdminPageState extends State<SuperAdminPage> { @override Widget build(BuildContext context) { return Scaffold(appBar: AppBar(title: const Text("👑 Super Admin"), backgroundColor: Colors.amber, foregroundColor: Colors.black), body: ListView(padding: const EdgeInsets.all(16), children: [Card(color: Colors.amber.withOpacity(0.2), child: const ListTile(title: Text("أهلاً أسمر - سوبر أدمن", style: TextStyle(color: Colors.amber, fontWeight: FontWeight.bold)))), ElevatedButton(onPressed: (){ setState(()=> mockRooms.clear()); }, child: const Text("حذف كل الغرف"))])); } }

// SLOT GAMES HALL - CONTRACT - THIS IS THE GAMES BUTTON YOU POINTED TO
class SlotGamesPage extends StatelessWidget {
  const SlotGamesPage({super.key});
  @override Widget build(BuildContext context) {
    final games = ["🍭 Sweet Bonanza", "⚡ Gates of Olympus", "🐟 Big Bass", "📚 Book of Dead", "💎 Starburst", "🐺 Wolf Gold"];
    return Scaffold(
      appBar: AppBar(title: const Text("🎰 Games - صالة السلوت"), backgroundColor: Colors.amber, foregroundColor: Colors.black),
      body: GridView.builder(padding: const EdgeInsets.all(16), gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, crossAxisSpacing: 12, mainAxisSpacing: 12, childAspectRatio: 0.9), itemCount: games.length, itemBuilder: (c,i)=> Card(color: const Color(0xFF1E293B), child: InkWell(onTap: (){ ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("فتح ${games[i]} - هون بنحط رابط الشركة")) ); }, child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Text(games[i].split(" ")[0], style: const TextStyle(fontSize: 50)), Text(games[i], style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold), textAlign: TextAlign.center), Container(margin: const EdgeInsets.only(top: 8), padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6), decoration: BoxDecoration(color: Colors.amber, borderRadius: BorderRadius.circular(20)), child: const Text("العب", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)))])))),
    );
  }
}
