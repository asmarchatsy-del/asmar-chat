import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AgentRechargePage extends StatefulWidget {
  const AgentRechargePage({super.key});
  @override
  State<AgentRechargePage> createState() => _AgentRechargePageState();
}

class _AgentRechargePageState extends State<AgentRechargePage> {
  final recipientController = TextEditingController();
  final amountController = TextEditingController(text: '10000');
  bool loading = true;
  bool submitting = false;
  bool isAgent = false;
  int balance = 0;
  String? error;
  List<Map<String, dynamic>> history = [];

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    try {
      final client = Supabase.instance.client;
      final user = client.auth.currentUser;
      if (user == null) throw Exception('يجب تسجيل الدخول أولًا');
      final profile = await client.from('profiles').select('role').eq('id', user.id).maybeSingle();
      isAgent = profile?['role'] == 'AGENT';
      if (!isAgent) { error = 'هذه الصفحة مخصصة لوكيل الشحن فقط'; return; }
      final wallet = await client.from('wallets').select('balance').eq('user_id', user.id).maybeSingle();
      balance = (wallet?['balance'] as num?)?.toInt() ?? 0;
      final rows = await client.from('agent_recharges')
          .select('id,recipient_id,amount,coins_per_usd,created_at')
          .eq('agent_id', user.id).order('created_at', ascending: false).limit(20);
      history = List<Map<String, dynamic>>.from(rows);
    } catch (e) {
      error = e.toString();
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> _recharge() async {
    final recipient = recipientController.text.trim();
    final amount = int.tryParse(amountController.text.trim());
    if (recipient.isEmpty || amount == null || amount <= 0) {
      setState(() => error = 'أدخل ID المستخدم والكمية بشكل صحيح');
      return;
    }
    setState(() { submitting = true; error = null; });
    try {
      await Supabase.instance.client.rpc('agent_recharge', params: {
        'p_recipient_id': recipient,
        'p_amount': amount,
      });
      recipientController.clear();
      await _load();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم شحن المستخدم بنجاح')),
        );
      }
    } catch (e) {
      if (mounted) setState(() => error = e.toString());
    } finally {
      if (mounted) setState(() => submitting = false);
    }
  }

  @override
  void dispose() { recipientController.dispose(); amountController.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    if (loading) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    if (!isAgent) {
      return Scaffold(
        appBar: AppBar(title: const Text('وكيل الشحن')),
        body: Center(child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(error ?? 'هذه الصفحة مخصصة لوكيل الشحن فقط', textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.redAccent)),
        )),
      );
    }
    return Scaffold(
      appBar: AppBar(title: const Text('شحن المستخدم')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(child: ListTile(
            leading: const Icon(Icons.account_balance_wallet),
            title: const Text('رصيد الوكيل'),
            subtitle: Text('\${balance.toString()} كوين'),
          )),
          const SizedBox(height: 16),
          TextField(
            controller: recipientController,
            decoration: const InputDecoration(
              labelText: 'ID المستخدم',
              hintText: 'أدخل ID المستخدم أو اسم المستخدم',
              prefixIcon: Icon(Icons.person_search),
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: amountController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'عدد الكوينز',
              prefixIcon: Icon(Icons.monetization_on),
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 8),
          const Text('سعر الوكيل: 10,000 كوين = 1 USD',
              style: TextStyle(color: Colors.white60)),
          if (error != null) ...[
            const SizedBox(height: 10),
            Text(error!, style: const TextStyle(color: Colors.redAccent)),
          ],
          const SizedBox(height: 18),
          SizedBox(
            height: 52,
            child: FilledButton.icon(
              onPressed: submitting ? null : _recharge,
              icon: submitting
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.send),
              label: Text(submitting ? 'جارٍ الشحن...' : 'تأكيد الشحن'),
            ),
          ),
          const SizedBox(height: 28),
          const Text('آخر عمليات الشحن', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          ...history.map((row) => ListTile(
            leading: const Icon(Icons.receipt_long),
            title: Text(row['amount'].toString() + ' كوين'),
            subtitle: Text('ID: ' + row['recipient_id'].toString()),
            trailing: Text(row['created_at'].toString().substring(0, 10)),
          )),
        ],
      ),
    );
  }
}
