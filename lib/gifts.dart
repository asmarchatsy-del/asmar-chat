import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class GiftItem {
  final String id;
  final String name;
  final String emoji;
  final int price;
  const GiftItem({required this.id, required this.name, required this.emoji, required this.price});
}

const gifts = <GiftItem>[
  GiftItem(id: 'rose', name: 'وردة', emoji: '🌹', price: 100),
  GiftItem(id: 'heart', name: 'قلب', emoji: '❤️', price: 500),
  GiftItem(id: 'diamond', name: 'ماسة', emoji: '💎', price: 1000),
  GiftItem(id: 'crown', name: 'تاج', emoji: '👑', price: 5000),
  GiftItem(id: 'dragon', name: 'تنين', emoji: '🐉', price: 10000),
  GiftItem(id: 'lion', name: 'أسد', emoji: '🦁', price: 25000),
];

class GiftHistoryPage extends StatelessWidget {
  const GiftHistoryPage({super.key});
  @override
  Widget build(BuildContext context) {
    final user = Supabase.instance.client.auth.currentUser;
    return Scaffold(
      backgroundColor: const Color(0xFF090604),
      appBar: AppBar(title: const Text('سجل الهدايا 🎁')),
      body: user == null
          ? const Center(child: Text('يجب تسجيل الدخول'))
          : StreamBuilder<List<Map<String, dynamic>>>(
              stream: Supabase.instance.client.from('gift_transactions').stream(primaryKey: ['id']).order('created_at', ascending: false),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text('تعذر تحميل السجل: ' + snapshot.error.toString()));
                }
                final rows = (snapshot.data ?? [])
                    .where((x) => x['sender_id'] == user.id || x['recipient_id'] == user.id)
                    .take(100)
                    .toList();
                if (rows.isEmpty) {
                  return const Center(child: Text('لا توجد هدايا بعد 🎁'));
                }
                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: rows.length,
                  itemBuilder: (context, index) {
                    final row = rows[index];
                    final mine = row['sender_id'] == user.id;
                    return Card(
                      color: const Color(0xFF1B0E08),
                      child: ListTile(
                        leading: const Text('🎁', style: TextStyle(fontSize: 30)),
                        title: Text(mine ? 'أرسلت هدية' : 'استلمت هدية'),
                        subtitle: Text('هدية: ' + row['gift_id'].toString()),
                        trailing: Text(row['amount'].toString() + ' 🪙'),
                      ),
                    );
                  },
                );
              },
            ),
    );
  }
}

class GiftSheet extends StatefulWidget {
  final String roomId;
  final void Function(GiftItem gift)? onSent;
  const GiftSheet({super.key, required this.roomId, this.onSent});
  @override State<GiftSheet> createState() => _GiftSheetState();
}

class _GiftSheetState extends State<GiftSheet> {
  String? recipient;
  int balance = 0;
  bool sending = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;
    try {
      final row = await Supabase.instance.client.from('wallets').select('balance').eq('user_id', user.id).maybeSingle();
      if (mounted) setState(() => balance = (row?['balance'] as num?)?.toInt() ?? 0);
    } catch (_) {}
  }

  Future<void> _send(GiftItem gift) async {
    final target = recipient;
    if (target == null || target.isEmpty || sending) return;
    setState(() => sending = true);
    try {
      await Supabase.instance.client.rpc('send_gift', params: {
        'p_room_id': widget.roomId,
        'p_recipient_id': target,
        'p_gift_id': gift.id,
      });
      await _load();
      if (mounted) {
        widget.onSent?.call(gift);
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('تم إرسال ' + gift.emoji + ' ' + gift.name + ' 🔥')));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('تعذر إرسال الهدية: $e')));
    } finally {
      if (mounted) setState(() => sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: const BoxDecoration(
          color: Color(0xFF120805),
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(children: [
              const Text('الهدايا 🎁', style: TextStyle(color: Color(0xFFFFD36A), fontSize: 20, fontWeight: FontWeight.w900)),
              IconButton(onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const GiftHistoryPage())), icon: const Icon(Icons.history, color: Color(0xFFFFD36A))),
              const Spacer(),
              Text(balance.toString() + ' 🪙', style: const TextStyle(color: Color(0xFFFFD36A), fontWeight: FontWeight.bold)),
            ]),
            const SizedBox(height: 10),
            TextField(
              onChanged: (value) => setState(() => recipient = value.trim().isEmpty ? null : value.trim()),
              decoration: const InputDecoration(labelText: 'ID أو اسم المستخدم للمستلم', prefixIcon: Icon(Icons.person_search)),
            ),
            const SizedBox(height: 12),
            GridView.builder(
              shrinkWrap: true,
              itemCount: gifts.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3, childAspectRatio: .9, crossAxisSpacing: 8, mainAxisSpacing: 8),
              itemBuilder: (context, index) {
                final gift = gifts[index];
                return InkWell(
                  onTap: sending ? null : () => _send(gift),
                  child: Container(
                    decoration: BoxDecoration(color: const Color(0xFF241207), borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFF6A421A))),
                    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                      Text(gift.emoji, style: const TextStyle(fontSize: 34)),
                      Text(gift.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11)),
                      Text(gift.price.toString() + ' 🪙', style: const TextStyle(color: Color(0xFFFFD36A), fontSize: 10)),
                    ]),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
