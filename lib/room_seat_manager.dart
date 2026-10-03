import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

const _gold = Color(0xFFFFD36A);
const _card = Color(0xFF1B0E08);

class RoomSeatManager extends StatefulWidget {
  final String roomId;
  final int initialCount;
  final Future<void> Function(int count)? onChanged;
  const RoomSeatManager({super.key, required this.roomId, required this.initialCount, this.onChanged});
  @override State<RoomSeatManager> createState() => _RoomSeatManagerState();
}

class _RoomSeatManagerState extends State<RoomSeatManager> {
  late int count = widget.initialCount.clamp(4, 30);
  bool busy = false;

  Future<void> save(int value) async {
    if (busy) return;
    setState(() => busy = true);
    try {
      await Supabase.instance.client.rpc('ensure_room_seats', params: {
        'p_room_id': widget.roomId,
        'p_seat_count': value,
      });
      if (mounted) {
        setState(() => count = value);
        await widget.onChanged?.call(value);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('تم ضبط المقاعد إلى $value')));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('تعذر تغيير المقاعد: $e')));
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: _card,
      title: const Text('عدد مقاعد الغرفة', style: TextStyle(color: _gold)),
      content: DropdownButtonFormField<int>(
        value: count,
        dropdownColor: _card,
        style: const TextStyle(color: Colors.white),
        decoration: const InputDecoration(labelText: 'المقاعد', labelStyle: TextStyle(color: Colors.white70)),
        items: const [4,6,8,10,12,15,20,25,30].map((n) => DropdownMenuItem(value: n, child: Text('$n مقعد'))).toList(),
        onChanged: busy ? null : (v) { if (v != null) save(v); },
      ),
      actions: [TextButton(onPressed: busy ? null : () => Navigator.pop(context), child: const Text('إغلاق', style: TextStyle(color: _gold)))],
    );
  }
}
