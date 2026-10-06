
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AsmarTransferPage extends StatefulWidget {
  const AsmarTransferPage({super.key});
  @override State<AsmarTransferPage> createState() => _AsmarTransferPageState();
}

class _AsmarTransferPageState extends State<AsmarTransferPage> {
  final db = Supabase.instance.client;
  final target = TextEditingController();
  final amount = TextEditingController();
  bool busy = false;
  int balance = 0;

  @override
  void initState() { super.initState(); _loadBalance(); }
  @override
  void dispose() { target.dispose(); amount.dispose(); super.dispose(); }

  Future<void> _loadBalance() async {
    final uid = db.auth.currentUser?.id;
    if (uid == null) return;
    final row = await db.from('profiles').select('coins').eq('id', uid).maybeSingle();
    if (mounted) setState(() => balance = (row?['coins'] as num?)?.toInt() ?? 0);
  }

  Future<void> _send() async {
    if (busy) return;
    final q = target.text.trim();
    final n = int.tryParse(amount.text.trim());
    if (q.isEmpty || n == null || n <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('أدخل ID والمبلغ بشكل صحيح.')));
      return;
    }
    setState(() => busy = true);
    try {
      final profile = await db.from('profiles').select('id,display_name,username,public_id').or('id.eq.' + q + ',public_id.eq.' + q + ',username.eq.' + q).maybeSingle();
      if (profile == null) throw StateError('المستلم غير موجود');
      await db.rpc('asmar_transfer_coins', params: {'p_to_user_id': profile['id'], 'p_amount': n});
      await _loadBalance();
      if (mounted) {
        target.clear(); amount.clear();
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('تم تحويل ' + n.toString() + ' Coins إلى ' + (profile['display_name']?.toString() ?? profile['username']?.toString() ?? 'المستخدم'))));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('تعذر التحويل: ' + e.toString())));
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Directionality(
    textDirection: TextDirection.rtl,
    child: Scaffold(
      appBar: AppBar(title: const Text('تحويل Coins', style: TextStyle(fontWeight: FontWeight.w900))),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('رصيدك الحالي: ' + balance.toString() + ' Coins', style: const TextStyle(color: Color(0xFFFFC94A), fontSize: 20, fontWeight: FontWeight.w900)),
          const SizedBox(height: 18),
          TextField(controller: target, decoration: const InputDecoration(labelText: 'ID أو Public ID أو اسم المستخدم')),
          const SizedBox(height: 10),
          TextField(controller: amount, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'المبلغ')),
          const SizedBox(height: 16),
          SizedBox(height: 52, child: FilledButton.icon(onPressed: busy ? null : _send, icon: const Icon(Icons.send), label: Text(busy ? 'جارٍ التحويل...' : 'تحويل'))),
        ],
      ),
    ),
  );
}
