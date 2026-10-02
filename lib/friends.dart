import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class FriendsPage extends StatefulWidget {
  const FriendsPage({super.key});
  @override State<FriendsPage> createState() => _FriendsPageState();
}
class _FriendsPageState extends State<FriendsPage> {
  final target = TextEditingController();
  final client = Supabase.instance.client;

  Future<void> _send() async {
    final value = target.text.trim();
    if (value.isEmpty) return;
    try {
      await client.rpc('send_friend_request', params: {'p_receiver': value});
      target.clear();
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم إرسال طلب الصداقة 🤝')));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('تعذر إرسال الطلب: $e')));
    }
  }

  Future<void> _respond(String id, bool accept) async {
    try {
      await client.rpc('respond_friend_request', params: {'p_request': id, 'p_accept': accept});
      if (mounted) setState(() {});
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('تعذر تنفيذ الطلب: $e')));
    }
  }

  @override
  void dispose() { target.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFF090604),
        appBar: AppBar(
          backgroundColor: const Color(0xFF100805),
          foregroundColor: Colors.white,
          title: const Text('الأصدقاء 🤝', style: TextStyle(color: Color(0xFFFFD36A), fontWeight: FontWeight.w900)),
        ),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Row(children: [
              Expanded(child: TextField(controller: target, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(labelText: 'ID أو اسم المستخدم'))),
              IconButton(onPressed: _send, icon: const Icon(Icons.person_add, color: Color(0xFFFFD36A))),
            ]),
            const SizedBox(height: 20),
            const Text('طلبات الصداقة', style: TextStyle(color: Color(0xFFFFD36A), fontSize: 20, fontWeight: FontWeight.w900)),
            const SizedBox(height: 8),
            StreamBuilder<List<Map<String, dynamic>>>(
              stream: client.from('friend_requests').stream(primaryKey: ['id']),
              builder: (context, snap) {
                final uid = client.auth.currentUser?.id;
                final rows = (snap.data ?? []).where((x) => x['receiver_id'] == uid && x['status'] == 'pending').toList();
                if (rows.isEmpty) return const Padding(padding: EdgeInsets.all(20), child: Text('لا توجد طلبات جديدة', style: TextStyle(color: Colors.white54)));
                return Column(children: rows.map((x) => Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: const Color(0xFF1B0E08), borderRadius: BorderRadius.circular(16)),
                  child: Row(children: [
                    const Icon(Icons.person_add, color: Color(0xFFFFD36A)),
                    const SizedBox(width: 8),
                    Expanded(child: Text(x['sender_id'].toString(), style: const TextStyle(color: Colors.white, fontSize: 11))),
                    IconButton(onPressed: () => _respond(x['id'].toString(), true), icon: const Icon(Icons.check, color: Colors.green)),
                    IconButton(onPressed: () => _respond(x['id'].toString(), false), icon: const Icon(Icons.close, color: Colors.red)),
                  ]),
                )).toList());
              },
            ),
            const SizedBox(height: 20),
            const Text('أصدقائي', style: TextStyle(color: Color(0xFFFFD36A), fontSize: 20, fontWeight: FontWeight.w900)),
            StreamBuilder<List<Map<String, dynamic>>>(
              stream: client.from('friendships').stream(primaryKey: ['user_id', 'friend_id']),
              builder: (context, snap) {
                final uid = client.auth.currentUser?.id;
                final rows = (snap.data ?? []).where((x) => x['user_id'] == uid).toList();
                if (rows.isEmpty) return const Padding(padding: EdgeInsets.all(20), child: Text('لا يوجد أصدقاء بعد', style: TextStyle(color: Colors.white54)));
                return Column(children: rows.map((x) => ListTile(
                  leading: const CircleAvatar(child: Icon(Icons.person)),
                  title: Text(x['friend_id'].toString(), style: const TextStyle(color: Colors.white)),
                )).toList());
              },
            ),
          ],
        ),
      ),
    );
  }
}
