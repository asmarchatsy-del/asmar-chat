import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

const _gold = Color(0xFFFFD36A);
const _gold2 = Color(0xFFB77921);
const _bg = Color(0xFF090604);
const _card = Color(0xFF1B0E08);

class WalletPage extends StatefulWidget {
  const WalletPage({super.key});

  @override
  State<WalletPage> createState() => _WalletPageState();
}

class _WalletPageState extends State<WalletPage> {
  int balance = 0;
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final u = Supabase.instance.client.auth.currentUser;
    if (u != null) {
      try {
        final r = await Supabase.instance.client
            .from('wallets')
            .select('balance')
            .eq('user_id', u.id)
            .maybeSingle();
        balance = (r?['balance'] as num?)?.toInt() ?? 0;
      } catch (_) {}
    }
    if (mounted) {
      setState(() => loading = false);
    }
  }



  @override
  Widget build(BuildContext c) => Directionality(
        textDirection: TextDirection.rtl,
        child: Scaffold(
          backgroundColor: _bg,
          appBar: AppBar(
            title: const Text('المحفظة'),
            backgroundColor: _card,
          ),
          body: loading
              ? const Center(
                  child: CircularProgressIndicator(color: _gold),
                )
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    Container(
                      padding: const EdgeInsets.all(22),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(24),
                        gradient: const LinearGradient(
                          colors: [Color(0xFF6B2C0B), Color(0xFF160A06)],
                        ),
                        border: Border.all(color: _gold2),
                      ),
                      child: Text(
                        'رصيدك: $balance Coins',
                        style: const TextStyle(
                          color: _gold,
                          fontSize: 26,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    FilledButton.icon(
                      onPressed: () => Navigator.push(
                        c,
                        MaterialPageRoute(
                          builder: (_) => const RechargeAgentsPage(),
                        ),
                      ),
                      icon: const Icon(Icons.support_agent),
                      label: const Text('شحن عبر وكيل شحن'),
                    ),
                    const SizedBox(height: 10),
                    FilledButton.icon(
                      onPressed: () => Navigator.push(
                        c,
                        MaterialPageRoute(
                          builder: (_) => const WithdrawalMethodsPage(),
                        ),
                      ),
                      icon: const Icon(Icons.account_balance),
                      label: const Text('طرق السحب'),
                    ),
                  ],
                ),
        ),
      );
}

class RechargeAgentsPage extends StatefulWidget {
  const RechargeAgentsPage({super.key});

  @override
  State<RechargeAgentsPage> createState() => _RechargeAgentsPageState();
}

class _RechargeAgentsPageState extends State<RechargeAgentsPage> {
  List<Map<String, dynamic>> agents = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final r = await Supabase.instance.client
          .from('recharge_agents')
          .select('id,display_name,whatsapp_number,avatar_url')
          .eq('is_active', true)
          .order('sort_order');
      agents = List<Map<String, dynamic>>.from(r);
    } catch (_) {}
    if (mounted) {
      setState(() => loading = false);
    }
  }

  Future<void> _wa(String raw) async {
    final n = raw.replaceAll(RegExp(r'[^0-9]'), '');
    final u = Uri.parse('https://wa.me/$n');
    if (await canLaunchUrl(u)) {
      await launchUrl(u, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext c) => Directionality(
        textDirection: TextDirection.rtl,
        child: Scaffold(
          backgroundColor: _bg,
          appBar: AppBar(title: const Text('وكلاء الشحن')),
          body: loading
              ? const Center(
                  child: CircularProgressIndicator(color: _gold),
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: agents.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (c, i) {
                    final a = agents[i];
                    return ListTile(
                      tileColor: _card,
                      leading: const CircleAvatar(
                        backgroundColor: Color(0xFF422511),
                        child: Icon(Icons.person, color: _gold),
                      ),
                      title: Text(
                        a['display_name'].toString(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      subtitle: InkWell(
                        onTap: () => _wa(a['whatsapp_number'].toString()),
                        child: Text(
                          a['whatsapp_number'].toString(),
                          style: const TextStyle(
                            color: _gold,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                      trailing: IconButton(
                        onPressed: () =>
                            _wa(a['whatsapp_number'].toString()),
                        icon: const Icon(
                          Icons.chat,
                          color: Color(0xFF25D366),
                        ),
                      ),
                    );
                  },
                ),
        ),
      );
}

class WithdrawalMethodsPage extends StatefulWidget {
  const WithdrawalMethodsPage({super.key});

  @override
  State<WithdrawalMethodsPage> createState() => _WithdrawalMethodsPageState();
}

class _WithdrawalMethodsPageState extends State<WithdrawalMethodsPage> {
  List<Map<String, dynamic>> methods = [];
  bool loading = true;
  bool submitting = false;

  Future<void> _requestWithdrawal(Map<String, dynamic> method) async {
    final amountController = TextEditingController();
    final details = <String, TextEditingController>{};
    final rawFields = method['fields'];
    final fields = rawFields is List
        ? rawFields.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList()
        : <Map<String, dynamic>>[];
    for (final field in fields) {
      final key = (field['key'] ?? field['name'] ?? '').toString().trim();
      if (key.isNotEmpty) details[key] = TextEditingController();
    }
    try {
      final ok = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: Text('طلب سحب عبر ${method['name']}'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: amountController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'المبلغ (${method['currency']})',
                    hintText: '${method['min_amount']} - ${method['max_amount']}',
                  ),
                ),
                ...fields.map((field) {
                  final key = (field['key'] ?? field['name'] ?? '').toString().trim();
                  if (key.isEmpty) return const SizedBox.shrink();
                  final label = (field['label'] ?? field['name'] ?? key).toString();
                  final controller = details[key]!;
                  return Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: TextField(
                      controller: controller,
                      keyboardType: field['keyboard_type'] == 'number'
                          ? TextInputType.number
                          : TextInputType.text,
                      decoration: InputDecoration(labelText: label),
                    ),
                  );
                }),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('إلغاء'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('إرسال'),
            ),
          ],
        ),
      );
      if (ok != true || !mounted) return;

      final amount = int.tryParse(amountController.text.trim());
      final min = (method['min_amount'] as num?)?.toInt() ?? 0;
      final max = (method['max_amount'] as num?)?.toInt() ?? 0;
      if (amount == null ||
          amount <= 0 ||
          amount < min ||
          (max > 0 && amount > max)) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('المبلغ يجب أن يكون بين $min و $max.')),
        );
        return;
      }

      final payload = <String, dynamic>{};
      for (final entry in details.entries) {
        final value = entry.value.text.trim();
        if (value.isNotEmpty) payload[entry.key] = value;
      }

      setState(() => submitting = true);
      await Supabase.instance.client.rpc(
        'asmar_create_withdrawal_request',
        params: {
          'p_method_id': method['id'],
          'p_amount': amount,
          'p_details': payload,
        },
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم إرسال طلب السحب بنجاح.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('تعذر إرسال طلب السحب: $e')),
        );
      }
    } finally {
      amountController.dispose();
      for (final controller in details.values) {
        controller.dispose();
      }
      if (mounted) setState(() => submitting = false);
    }
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final r = await Supabase.instance.client
          .from('withdrawal_methods')
          .select('id,name,currency,min_amount,max_amount,fee,fields')
          .eq('is_active', true)
          .order('sort_order');
      methods = List<Map<String, dynamic>>.from(r);
    } catch (_) {}
    if (mounted) {
      setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext c) => Directionality(
        textDirection: TextDirection.rtl,
        child: Scaffold(
          backgroundColor: _bg,
          appBar: AppBar(title: const Text('طرق السحب')),
          body: loading
              ? const Center(
                  child: CircularProgressIndicator(color: _gold),
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: methods.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (c, i) {
                    final m = methods[i];
                    return ListTile(
                      tileColor: _card,
                      title: Text(
                        m['name'].toString(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      subtitle: Text(
                        'الحد: ${m['min_amount']} - ${m['max_amount']} ${m['currency']}',
                        style: const TextStyle(color: Colors.white60),
                      ),
                      onTap: submitting ? null : () => _requestWithdrawal(m),
                    );
                  },
                ),
        ),
      );
}
