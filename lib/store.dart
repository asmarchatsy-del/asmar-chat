import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

const _gold = Color(0xFFFFD36A);
const _gold2 = Color(0xFFB77921);
const _bg = Color(0xFF090604);
const _card = Color(0xFF1B0E08);

class StorePage extends StatefulWidget {
  const StorePage({super.key});
  @override
  State<StorePage> createState() => _StorePageState();
}

class _StorePageState extends State<StorePage> {
  late Future<List<Map<String, dynamic>>> _framesFuture;
  int? _balance;
  bool _loadingBalance = true;

  @override
  void initState() {
    super.initState();
    _framesFuture = _loadFrames();
    _loadBalance();
  }

  Future<List<Map<String, dynamic>>> _loadFrames() async {
    final data = await Supabase.instance.client
        .from('frame_items').select('id,name,price,style_key')
        .eq('is_active', true).order('price');
    return List<Map<String, dynamic>>.from(data);
  }

  Future<void> _loadBalance() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;
    final row = await Supabase.instance.client.from('wallets')
        .select('balance').eq('user_id', user.id).maybeSingle();
    if (!mounted) return;
    setState(() { _balance = (row?['balance'] as num?)?.toInt() ?? 0; _loadingBalance = false; });
  }

  Future<void> _buy(Map<String, dynamic> frame) async {
    try {
      await Supabase.instance.client.rpc('purchase_frame', params: {'p_frame_id': frame['id'].toString()});
      await _loadBalance();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('تم شراء ${frame['name']} بنجاح 🔥'), backgroundColor: _gold2),
        );
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('تعذر الشراء: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: _bg,
        appBar: AppBar(
          title: const Text('متجر الإطارات', style: TextStyle(fontWeight: FontWeight.w900)),
          actions: [Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Center(child: Text(_loadingBalance ? '...' : '${_balance ?? 0} 🪙',
              style: const TextStyle(color: _gold, fontWeight: FontWeight.w900))),
          )],
        ),
        body: FutureBuilder<List<Map<String, dynamic>>>(
          future: _framesFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) return const Center(child: CircularProgressIndicator());
            if (snapshot.hasError) return Center(child: Text('تعذر تحميل المتجر: ${snapshot.error}'));
            final frames = snapshot.data ?? [];
            return GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2, crossAxisSpacing: 12, mainAxisSpacing: 12, childAspectRatio: .82),
              itemCount: frames.length,
              itemBuilder: (_, i) => _FrameCard(frame: frames[i], onBuy: () => _buy(frames[i])),
            );
          },
        ),
      ),
    );
  }
}

class _FrameCard extends StatelessWidget {
  final Map<String, dynamic> frame;
  final VoidCallback onBuy;
  const _FrameCard({required this.frame, required this.onBuy});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(color: _card, borderRadius: BorderRadius.circular(20), border: Border.all(color: _gold2)),
      padding: const EdgeInsets.all(12),
      child: Column(children: [
        _FramePreview(style: frame['style_key'].toString()),
        const SizedBox(height: 10),
        Text(frame['name'].toString(), textAlign: TextAlign.center,
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900)),
        const SizedBox(height: 6),
        Text('${frame['price']} Coins', style: const TextStyle(color: _gold, fontWeight: FontWeight.bold)),
        const Spacer(),
        SizedBox(width: double.infinity, child: FilledButton(
          onPressed: onBuy,
          style: const ButtonStyle(backgroundColor: WidgetStatePropertyAll(_gold2)),
          child: const Text('شراء'),
        )),
      ]),
    );
  }
}

class _FramePreview extends StatelessWidget {
  final String style;
  const _FramePreview({required this.style});

  @override
  Widget build(BuildContext context) {
    final colors = switch (style) {
      'diamond' => const [Color(0xFFE9F7FF), Color(0xFF79BFFF)],
      'fire' => const [Color(0xFFFFD36A), Color(0xFFFF3D00)],
      'vip' => const [Color(0xFFE6C66A), Color(0xFF7D3C98)],
      _ => const [Color(0xFFFFE08A), Color(0xFFB77921)],
    };
    return Container(
      width: 112, height: 112, padding: const EdgeInsets.all(7),
      decoration: BoxDecoration(shape: BoxShape.circle,
        gradient: SweepGradient(colors: [...colors, colors.first]),
        boxShadow: [BoxShadow(color: colors.last.withOpacity(.45), blurRadius: 14)]),
      child: Container(
        decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0xFF0D0805)),
        child: const Icon(Icons.person, color: _gold, size: 54),
      ),
    );
  }
}
