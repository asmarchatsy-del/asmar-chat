import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../widgets/seat_grid.dart';

class RoomPage extends StatefulWidget {
  final String roomId; final int seatCount;
  const RoomPage({super.key, required this.roomId, required this.seatCount});
  @override State<RoomPage> createState()=> _RoomPageState();
}
class _RoomPageState extends State<RoomPage>{
  List<Map<String,dynamic>> seats=[];
  bool loading=true;

  @override void initState(){ super.initState(); _fetchSeats(); _subscribe(); }
  
  Future<void> _fetchSeats() async {
    final res = await Supabase.instance.client.from('seats').select('*, profiles(name, avatar_url)').eq('room_id', widget.roomId).order('seat_no');
    if(mounted) setState((){ seats = List<Map<String,dynamic>>.from(res); loading=false; });
  }
  void _subscribe(){
    Supabase.instance.client.from('seats').stream(primaryKey: ['id']).eq('room_id', widget.roomId).listen((_)=>_fetchSeats());
  }
  Future<void> _onSeatTap(int index) async {
    final user = Supabase.instance.client.auth.currentUser;
    if(user==null) return;
    // إذا المقعد فاضي احجزو
    final seat = seats.firstWhere((s)=>s['seat_no']==index, orElse: ()=>{});
    if(seat['user_id']==null){
      await Supabase.instance.client.from('seats').update({'user_id':user.id}).eq('room_id', widget.roomId).eq('seat_no', index);
    } else if(seat['user_id']==user.id){
      await Supabase.instance.client.from('seats').update({'user_id':null}).eq('room_id', widget.roomId).eq('seat_no', index);
    }
  }

  @override Widget build(BuildContext context){
    return Scaffold(
      backgroundColor: Color(0xFF0F0F1A),
      appBar: AppBar(title: Text('غرفة ${widget.seatCount} مقعد'), backgroundColor: Color(0xFF1E1E2F)),
      body: loading? Center(child: CircularProgressIndicator(color: Colors.amber))
        : SeatGrid(seatCount: widget.seatCount, seats: seats, onSeatTap: _onSeatTap),
    );
  }
}
