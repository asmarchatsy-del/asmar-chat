import 'package:flutter/material.dart';
import '../../asmar/asmar_theme.dart';

class StoreScreen extends StatefulWidget {
  const StoreScreen({super.key});
  @override State<StoreScreen> createState() => _StoreScreenState();
}

class _StoreScreenState extends State<StoreScreen> {
  int tab = 0;
  final tabs = const ['سيارة', 'إطار', 'إطار المعرف', 'موجة الميكروفون', 'خاصة', 'معرف مميز'];
  final products = const ['SpaceShip', 'Golden Lambor', 'Hero Descends', 'Leopard', 'Gold Lion', 'Royal Car', 'Golden Crown', 'Night Frame', 'Phoenix'];
  @override Widget build(BuildContext context) => Directionality(
        textDirection: TextDirection.rtl,
        child: Scaffold(
          appBar: AppBar(title: const Text('المتجر', style: TextStyle(fontWeight: FontWeight.w900))),
          body: Column(children: [
            SizedBox(height: 52, child: ListView.separated(padding: const EdgeInsets.symmetric(horizontal: 10), scrollDirection: Axis.horizontal, itemCount: tabs.length, separatorBuilder: (_, __) => const SizedBox(width: 7), itemBuilder: (_, i) => ChoiceChip(label: Text(tabs[i]), selected: tab == i, onSelected: (_) => setState(() => tab = i), selectedColor: AsmarTheme.gold, labelStyle: TextStyle(color: tab == i ? Colors.black : Colors.white70, fontWeight: FontWeight.bold), backgroundColor: AsmarTheme.surface))),
            Expanded(child: GridView.builder(
              padding: const EdgeInsets.all(12),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3, crossAxisSpacing: 9, mainAxisSpacing: 9, childAspectRatio: .72),
              itemCount: products.length,
              itemBuilder: (_, i) => _product(products[i], 700 + i * 350),
            )),
          ]),
        ),
      );

  Widget _product(String name, int price) => InkWell(
        onTap: () => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('شراء $name مقابل $price ذهب'))),
        borderRadius: BorderRadius.circular(15),
        child: Container(
          decoration: AsmarTheme.card(radius: 15),
          padding: const EdgeInsets.all(7),
          child: Column(children: [
            Expanded(child: Container(width: double.infinity, decoration: BoxDecoration(borderRadius: BorderRadius.circular(11), gradient: const LinearGradient(colors: [Color(0xFF4B2D0F), Color(0xFF120B06)])), child: const Icon(Icons.diamond, color: AsmarTheme.gold, size: 42))),
            const SizedBox(height: 7),
            Text(name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 11)),
            const SizedBox(height: 4),
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [const Icon(Icons.circle, color: AsmarTheme.gold, size: 10), const SizedBox(width: 4), Text('$price', style: const TextStyle(color: AsmarTheme.gold, fontWeight: FontWeight.w900, fontSize: 11))]),
          ]),
        ),
      );
}
