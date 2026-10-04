import 'package:flutter/material.dart';
import '../../asmar/asmar_theme.dart';

class WalletScreen extends StatelessWidget {
  const WalletScreen({super.key});
  static const packages = [(700, '\$1'), (2100, '\$3'), (7000, '\$10'), (14000, '\$20'), (35000, '\$50')];

  @override
  Widget build(BuildContext context) => Directionality(
        textDirection: TextDirection.rtl,
        child: Scaffold(
          appBar: AppBar(title: const Text('المحفظة', style: TextStyle(fontWeight: FontWeight.w900))),
          body: ListView(padding: const EdgeInsets.all(14), children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: AsmarTheme.goldCard(radius: 22),
              child: const Column(children: [
                Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
                  _Balance(icon: Icons.circle, value: '12,800', label: 'ذهب'),
                  _Balance(icon: Icons.diamond, value: '3,600', label: 'ألماس'),
                ]),
                SizedBox(height: 17),
                Row(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.inventory_2, color: AsmarTheme.gold, size: 27), SizedBox(width: 8), Text('صندوق الكنز', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 17))]),
              ]),
            ),
            const SizedBox(height: 18),
            const Text('باقات Google Pay', style: TextStyle(color: AsmarTheme.gold, fontSize: 18, fontWeight: FontWeight.w900)),
            const SizedBox(height: 9),
            ...packages.map((p) => Card(
                  color: AsmarTheme.surface,
                  child: ListTile(
                    leading: const CircleAvatar(backgroundColor: Color(0xFF4A3014), child: Icon(Icons.circle, color: AsmarTheme.gold, size: 14)),
                    title: Text('${p.$1} ذهب', style: const TextStyle(fontWeight: FontWeight.w900)),
                    subtitle: const Text('دفع آمن عبر Google Pay'),
                    trailing: Text(p.$2, style: const TextStyle(color: AsmarTheme.gold, fontWeight: FontWeight.w900, fontSize: 16)),
                    onTap: () => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('اختيار باقة ${p.$1} ذهب'))),
                  ),
                )),
            const SizedBox(height: 10),
            const Text('الأسعار أعلاه Mock مؤقتة لبناء 452 ولا تنفذ عملية دفع حقيقية بعد.', style: TextStyle(color: AsmarTheme.muted, fontSize: 11)),
          ]),
        ),
      );
}

class _Balance extends StatelessWidget {
  final IconData icon; final String value, label;
  const _Balance({required this.icon, required this.value, required this.label});
  @override Widget build(BuildContext context) => Column(children: [Icon(icon, color: AsmarTheme.gold, size: 26), const SizedBox(height: 5), Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 20)), Text(label, style: const TextStyle(color: AsmarTheme.muted, fontSize: 11))]);
}
