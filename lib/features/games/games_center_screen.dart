import 'package:flutter/material.dart';
import '../../asmar/asmar_theme.dart';

class GamesCenterScreen extends StatelessWidget {
  const GamesCenterScreen({super.key});
  static const games = [
    ('Ludo', Icons.casino, 'لعبة الطاولة'),
    ('Shark', Icons.water, 'تحدي القرش'),
    ('Poker', Icons.style, 'بطاقات Poker'),
    ('Dice', Icons.filter_1, 'نرد سريع'),
    ('Lucky', Icons.stars, 'الحظ الذهبي'),
    ('Cards', Icons.credit_card, 'بطاقات الأصدقاء'),
  ];

  @override
  Widget build(BuildContext context) => Directionality(
        textDirection: TextDirection.rtl,
        child: Scaffold(
          appBar: AppBar(title: const Text('الألعاب', style: TextStyle(fontWeight: FontWeight.w900))),
          body: GridView.builder(
            padding: const EdgeInsets.all(14),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, crossAxisSpacing: 12, mainAxisSpacing: 12, childAspectRatio: .92),
            itemCount: games.length,
            itemBuilder: (_, i) {
              final game = games[i];
              return InkWell(
                onTap: () => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('اختيار ${game.$1}'))),
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  decoration: AsmarTheme.goldCard(radius: 20),
                  padding: const EdgeInsets.all(16),
                  child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Container(width: 76, height: 76, decoration: const BoxDecoration(shape: BoxShape.circle, gradient: LinearGradient(colors: [AsmarTheme.gold, AsmarTheme.goldDark])), child: Icon(game.$2, color: Colors.black, size: 40)),
                    const SizedBox(height: 13),
                    Text(game.$1, style: const TextStyle(color: AsmarTheme.gold, fontSize: 19, fontWeight: FontWeight.w900)),
                    const SizedBox(height: 5),
                    Text(game.$3, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white60, fontSize: 11)),
                  ]),
                ),
              );
            },
          ),
        ),
      );
}
