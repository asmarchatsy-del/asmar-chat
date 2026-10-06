import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

const _bg = Color(0xFF070817);
const _panel = Color(0xFF10132B);
const _pink = Color(0xFFE33DFF);
const _cyan = Color(0xFF4EDCFF);
const _text2 = Color(0xFF9EA6C7);

class WalletGiftsPage extends StatelessWidget {
  const WalletGiftsPage({super.key});
  @override
  Widget build(BuildContext context) {
    final uid = Supabase.instance.client.auth.currentUser?.id;
    final db = Supabase.instance.client;
    return Directionality(textDirection: TextDirection.rtl, child: Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(backgroundColor: _bg, title: const Text('الهدايا', style: TextStyle(fontWeight: FontWeight.w900))),
      body: uid == null ? const Center(child: Text('يجب تسجيل الدخول أولاً')) :
        StreamBuilder<List<Map<String, dynamic>>>(
          stream: db.from('gift_transactions').stream(primaryKey: ['id']).order('created_at', ascending: false),
          builder: (context, snap) {
            final rows = (snap.data ?? const <Map<String, dynamic>>[]).where((r) => r['sender_id'] == uid || r['recipient_id'] == uid).toList();
            if (rows.isEmpty) return const Center(child: Text('لا توجد هدايا مرسلة أو مستلمة حتى الآن', style: TextStyle(color: _text2)));
            final sent = rows.where((r) => r['sender_id'] == uid).fold<int>(0, (s, r) => s + ((r['amount'] as num?)?.toInt() ?? 0));
            final received = rows.where((r) => r['recipient_id'] == uid).fold<int>(0, (s, r) => s + ((r['amount'] as num?)?.toInt() ?? 0));
            return ListView(padding: const EdgeInsets.all(16), children: [
              Row(children: [
                Expanded(child: _Balance('مرسل', sent, _pink, Icons.card_giftcard_rounded)),
                const SizedBox(width: 10),
                Expanded(child: _Balance('مستلم', received, _cyan, Icons.redeem_rounded)),
              ]),
              const SizedBox(height: 16),
              ...rows.map((r) {
                final outgoing = r['sender_id'] == uid;
                return Container(
                  margin: const EdgeInsets.only(bottom: 8), padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(color: _panel, borderRadius: BorderRadius.circular(18)),
                  child: Row(children: [
                    Icon(outgoing ? Icons.card_giftcard_rounded : Icons.redeem_rounded, color: outgoing ? _pink : _cyan),
                    const SizedBox(width: 12),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(outgoing ? 'هدية مرسلة' : 'هدية مستلمة', style: const TextStyle(fontWeight: FontWeight.w800)),
                      Text('الهدية: ${r['gift_id'] ?? '—'}', style: const TextStyle(color: _text2, fontSize: 11)),
                    ])),
                    Text('${r['amount'] ?? 0}', style: const TextStyle(fontWeight: FontWeight.w900)),
                  ]),
                );
              }),
            ]);
          },
        ),
    ));
  }
}
class _Balance extends StatelessWidget {
  final String title; final int value; final Color color; final IconData icon;
  const _Balance(this.title, this.value, this.color, this.icon);
  @override Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(color: _panel, borderRadius: BorderRadius.circular(20), border: Border.all(color: color.withOpacity(.35))),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Icon(icon, color: color), const SizedBox(height: 8),
      Text(title, style: const TextStyle(color: _text2, fontSize: 12)),
      Text('$value', style: const TextStyle(fontSize: 21, fontWeight: FontWeight.w900)),
    ]),
  );
}
