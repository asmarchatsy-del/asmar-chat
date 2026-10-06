import 'package:flutter/material.dart';

import '../backend/supabase_runtime.dart';
import 'real_voice_room_page.dart';
import '../../profile_page.dart';
import '../../features/games/games_center_screen.dart';
import 'room_repository.dart';

class RealRoomsHomePage extends StatefulWidget {
  const RealRoomsHomePage({super.key});

  @override
  State<RealRoomsHomePage> createState() => _RealRoomsHomePageState();
}

class _RealRoomsHomePageState extends State<RealRoomsHomePage> {
  final _rooms = RoomRepository();

  Future<void> _createRoom() async {
    final controller = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('إنشاء غرفة'),
        content: TextField(controller: controller, autofocus: true, decoration: const InputDecoration(hintText: 'اسم الغرفة')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء')),
          FilledButton(onPressed: () => Navigator.pop(context, controller.text.trim()), child: const Text('إنشاء')),
        ],
      ),
    );
    controller.dispose();
    if (name == null || name.isEmpty) return;

    try {
      final roomName = 'asmar-${DateTime.now().millisecondsSinceEpoch}';
      final room = await _rooms.createRoom(name: name, liveKitRoomName: roomName);
      if (!mounted) return;
      Navigator.push(context, MaterialPageRoute(builder: (_) => RealVoiceRoomPage(room: room)));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!SupabaseRuntime.isInitialized) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text('Supabase غير مهيأ بعد. بعد وضع مفاتيح BackendConfig سيظهر نظام الغرف الحقيقي هنا.'),
        ),
      );
    }

    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _rooms.watchActiveRooms(),
      builder: (context, snapshot) {
        if (snapshot.hasError) return Center(child: Text('تعذر تحميل الغرف: ${snapshot.error}'));
        final rows = snapshot.data ?? const <Map<String, dynamic>>[];
        final rooms = rows.map(VoiceRoomRecord.fromMap).toList(growable: false);
        return Scaffold(
          appBar: AppBar(
            title: const Text('Asmar Chat', style: TextStyle(fontWeight: FontWeight.w900)),
            actions: [
              IconButton(
                tooltip: 'الألعاب',
                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const GamesCenterScreen())),
                icon: const Icon(Icons.sports_esports_outlined),
              ),
              IconButton(
                tooltip: 'ملفي',
                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AsmarProfilePage())),
                icon: const Icon(Icons.account_circle_outlined),
              ),
            ],
          ),
          body: SafeArea(
            child: Column(
              children: [
                const Padding(
                  padding: EdgeInsets.all(16),
                  child: Align(alignment: Alignment.centerRight, child: Text('الغرف الصوتية الحقيقية', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold))),
                ),
                Expanded(
                  child: rooms.isEmpty
                      ? const Center(child: Text('لا توجد غرف نشطة حاليًا'))
                      : ListView.builder(
                          padding: const EdgeInsets.all(12),
                          itemCount: rooms.length,
                          itemBuilder: (context, index) {
                            final room = rooms[index];
                            return Card(
                              child: ListTile(
                                leading: const CircleAvatar(child: Icon(Icons.mic)),
                                title: Text(room.name),
                                subtitle: Text('غرفة صوتية LiveKit • ${room.isActive ? 'نشطة' : 'متوقفة'}'),
                                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => RealVoiceRoomPage(room: room))),
                              ),
                            );
                          },
                        ),
                ),
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: SizedBox(width: double.infinity, child: FilledButton.icon(onPressed: _createRoom, icon: const Icon(Icons.add), label: const Text('إنشاء غرفة حقيقية'))),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
