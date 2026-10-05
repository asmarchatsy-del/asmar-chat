import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../asmar/asmar_theme.dart';
import '../../room.dart';
import '../room/widgets/create_room_sheet.dart';
import '../room/presentation/room_page.dart';

class BeelaShell extends StatefulWidget { const BeelaShell({super.key}); @override State<BeelaShell> createState()=>_BeelaShellState(); }
class _BeelaShellState extends State<BeelaShell> {
String filter='الكل', query=''; bool loading=false;
static const countries=<Map<String,String>>[{'code':'SY','name':'سوريا','flag':'🇸🇾'}];

@override void initState(){super.initState(); _loadRooms();}
Future<void> _loadRooms() async { if(mounted) setState(()=>loading=true); await Future.delayed(Duration(milliseconds: 300)); if(mounted) setState(()=>loading=false); }
List<Map<String,dynamic>> get visibleRooms=>[];

Future<void> _createRoom() async {
  final count = await showModalBottomSheet<int>(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (_)=>CreateRoomSheet()
  );
  if(count==null) return;
  try{
    final user = Supabase.instance.client.auth.currentUser;
    final res = await Supabase.instance.client.from('rooms').insert({
      'name':'غرفة أسمر $count',
      'seat_count':count,
      'owner_id':user?.id,
      'created_at':DateTime.now().toIso8601String()
    }).select().single();
    
    final seats = List.generate(count, (i)=>{'room_id':res['id'],'seat_no':i,'user_id':null});
    await Supabase.instance.client.from('seats').insert(seats);
    
    if(!mounted) return;
    Navigator.push(context, MaterialPageRoute(builder: (_)=>RoomPage(roomId: res['id'], seatCount: count)));
  }catch(e){
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('خطأ: $e')));
  }
}

@override Widget build(BuildContext context){
 return Scaffold(
   backgroundColor: Color(0xFF0F0F1A),
   body: Column(children: [_header(), _filters(), Expanded(child: Center(child: loading?CircularProgressIndicator():Text('لا يوجد غرف - اضغط +', style: TextStyle(color: Colors.white54))))]),
   floatingActionButton: FloatingActionButton(onPressed: _createRoom, backgroundColor: Colors.amber, child: Icon(Icons.add)),
 );
}
Widget _header()=>Container(height:255,decoration: BoxDecoration(gradient: LinearGradient(colors: [Color(0xFFFFD700), Color(0xFFFF9800)])), child: Center(child: Text('أسمر شات', style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold))));
Widget _filters()=>SizedBox(height:58,child: ListView(scrollDirection: Axis.horizontal, children: filters.map((f)=>Padding(padding: EdgeInsets.all(6), child: ChoiceChip(label: Text(f), selected: filter==f, onSelected: (_)=>setState(()=>filter=f)))).toList()));
List<String> get filters=>['الكل','Hot 🔥','سوريا','مصر','السعودية'];
Widget _room(Map<String,dynamic> room){return Container();}
}
