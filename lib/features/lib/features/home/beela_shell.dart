import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../room/widgets/create_room_sheet.dart';
import '../room/presentation/room_page.dart';

class BeelaShell extends StatefulWidget {
  const BeelaShell({super.key});
  @override
  State<BeelaShell> createState() => _BeelaShellState();
}

class _BeelaShellState extends State<BeelaShell> {
  String filter = 'الكل';

  Future<void> createRoom() async {
    final count = await showModalBottomSheet<int>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => const CreateRoomSheet(),
    );
    if (count == null) return;
    try {
      final user = Supabase.instance.client.auth.currentUser;
      final room = await Supabase.instance.client.from('rooms').insert({
        'name': 'غرفة $count',
        'seat_count': count,
        'owner_id': user?.id,
      }).select().single();
      final seats = List.generate(count, (i) => {
        'room_id': room['id'],
        'seat_no': i,
      });
      await Supabase.instance.client.from('seats').insert(seats);
      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => RoomPage(roomId: room['id'], seatCount: count),
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F1A),
      body: Column(
        children: [
          Container(
            height: 200,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFFFFD700), Color(0xFFFF9800)],
              ),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(24),
                bottomRight: Radius.circular(24),
              ),
            ),
            child: const Center(
              child: Text(
                'أسمر شات 🔥',
                style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
              ),
            ),
          ),
          SizedBox(
            height: 50,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: ['الكل', 'Hot 🔥', 'سوريا'].map((f) => Padding(
                padding: const EdgeInsets.all(6),
                child: ChoiceChip(
                  label: Text(f),
                  selected: filter == f,
                  onSelected: (_) => setState(() => filter = f),
                ),
              )).toList(),
            ),
          ),
          const Expanded(
            child: Center(
              child: Text(
                'لا يوجد غرف - اضغط +',
                style: TextStyle(color: Colors.white54),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: createRoom,
        backgroundColor: Colors.amber,
        child: const Icon(Icons.add, color: Colors.black),
      ),
    );
  }
}
