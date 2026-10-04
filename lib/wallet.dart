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

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final r = await Supabase.instance.client
          .from('withdrawal_methods')
          .select('id,name,currency,min_amount,max_amount,fee')
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
                      onTap: () => showDialog(
                        context: c,
                        builder: (_) => AlertDialog(
                          title: Text('سحب عبر ${m['name']}'),
                          content: const Text('سيتم إرسال طلب السحب من هنا.'),
                        ),
                      ),
                    );
                  },
                ),
        ),
      );
}
