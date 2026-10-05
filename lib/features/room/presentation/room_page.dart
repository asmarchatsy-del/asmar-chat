import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../widgets/seat_grid.dart';

class RoomPage extends StatefulWidget {
  final String roomId;
  final int seatCount;
  const RoomPage({super.key, required this.roomId, required this.seatCount});
  @override
  State<RoomPage> createState() => _RoomPageState();
}

class _RoomPageState extends State<RoomPage> {
  List<Map<String, dynamic>> seats = [];
  @override
  void initState() { super.initState(); fetchSeats(); }
  Future<void> fetchSeats() async {
    final data = await Supabase.instance.client.from('seats').select('*, profiles(name,avatar_url)').eq('room_id', widget.roomId);
    if(mounted) setState(()=> seats = data);
  }
  Future<void> sit(int seatNo) async {
    final user = Supabase.instance.client.auth.currentUser!;
    await Supabase.instance.client.from('seats').update({'user_id': user.id}).eq('room_id', widget.roomId).eq('seat_no', seatNo);
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F1A),
      appBar: AppBar(title: Text('غرفة ${widget.seatCount} - أسمر')),
      body: SeatGrid(seatCount: widget.seatCount, seats: seats, onSeatTap: sit),
    );
  }
}
