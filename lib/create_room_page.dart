import 'package:flutter/material.dart';
import 'core/rooms/room_repository.dart';
import 'core/rooms/real_voice_room_page.dart';

const _crBg = Color(0xFF0A0A0A);
const _crPanel = Color(0xFF1A1A1A);
const _crPurple = Color(0xFFD4AF37);
const _crPink = Color(0xFFD4AF37);
const _crCyan = Color(0xFFD4AF37);
const _crMuted = Color(0xFF888888);

class CreateRoomPage extends StatefulWidget {
  const CreateRoomPage({super.key});
  @override State<CreateRoomPage> createState() => _CreateRoomPageState();
}

class _CreateRoomPageState extends State<CreateRoomPage> {
  final _name = TextEditingController();
  final _repo = RoomRepository();
  String _category = 'دردشة';
  bool _private = false;
  int _seats = 8;
  bool _busy = false;

  @override
  void dispose() { _name.dispose(); super.dispose(); }

  Future<void> _create() async {
    final name = _name.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('اكتب اسم الغرفة أولاً')));
      return;
    }
    setState(() => _busy = true);
    try {
      final room = await _repo.createRoom(
        name: name,
        liveKitRoomName: 'asmar-${DateTime.now().millisecondsSinceEpoch}',
        tags: [_category],
        roomType: _private ? 'private' : 'party',
        seatCount: _seats,
      );
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => RealVoiceRoomPage(room: room)),
      );
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('تعذر إنشاء الغرفة: $e')));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: _crBg,
        appBar: AppBar(
          backgroundColor: _crBg,
          title: const Text('إنشاء غرفة', style: TextStyle(fontWeight: FontWeight.w900)),
          centerTitle: true,
        ),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 30),
          children: [
            Container(
              height: 170,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(28),
                gradient: const LinearGradient(
                  colors: [Color(0xFFD4AF37), Color(0xFF8A6B1F), Color(0xFF0A0A0A)],
                  begin: Alignment.topRight, end: Alignment.bottomLeft,
                ),
              ),
              child: const Center(
                child: Icon(Icons.mic_external_on_rounded, size: 72, color: Color(0xAAFFFFFF)),
              ),
            ),
            const SizedBox(height: 22),
            const Text('اسم الغرفة', style: TextStyle(fontWeight: FontWeight.w900)),
            const SizedBox(height: 8),
            TextField(
              controller: _name,
              maxLength: 40,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'مثال: سهرة Asmar الليلة',
                filled: true, fillColor: _crPanel,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(18), borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 10),
            const Text('التصنيف', style: TextStyle(fontWeight: FontWeight.w900)),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8, runSpacing: 8,
              children: ['دردشة','موسيقى','سهرات','أصدقاء','تعرف'].map((c) =>
                ChoiceChip(label: Text(c), selected: _category == c, onSelected: (_) => setState(() => _category = c))
              ).toList(),
            ),
            const SizedBox(height: 18),
            Container(
              decoration: BoxDecoration(color: _crPanel, borderRadius: BorderRadius.circular(20)),
              child: SwitchListTile(
                value: _private,
                onChanged: (v) => setState(() => _private = v),
                activeColor: _crPink,
                title: const Text('غرفة خاصة', style: TextStyle(fontWeight: FontWeight.w800)),
                subtitle: Text(_private ? 'الدخول يحتاج دعوة' : 'أي شخص يستطيع الانضمام', style: const TextStyle(color: _crMuted)),
              ),
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: _crPanel, borderRadius: BorderRadius.circular(20)),
              child: Row(
                children: [
                  const Icon(Icons.event_seat_rounded, color: _crCyan),
                  const SizedBox(width: 12),
                  const Expanded(child: Text('عدد المقاعد', style: TextStyle(fontWeight: FontWeight.w800))),
                  DropdownButton<int>(
                    value: _seats,
                    dropdownColor: _crPanel,
                    underline: const SizedBox(),
                    items: [8,12,15,20].map((v) => DropdownMenuItem(value: v, child: Text('$v'))).toList(),
                    onChanged: (v) => setState(() => _seats = v ?? 15),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _busy ? null : _create,
              style: FilledButton.styleFrom(
                backgroundColor: _crPurple, foregroundColor: Colors.black,
                minimumSize: const Size.fromHeight(54),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
              ),
              icon: _busy ? const SizedBox(width: 20,height:20,child:CircularProgressIndicator(strokeWidth:2)) : const Icon(Icons.add_rounded),
              label: Text(_busy ? 'جاري الإنشاء...' : 'إنشاء الغرفة', style: const TextStyle(fontWeight: FontWeight.w900)),
            ),
          ],
        ),
      ),
    );
  }
}
