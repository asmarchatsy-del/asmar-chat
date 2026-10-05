import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../asmar/asmar_theme.dart';

class GamesCenterScreen extends StatefulWidget {
  const GamesCenterScreen({super.key});
  @override State<GamesCenterScreen> createState() => _GamesCenterScreenState();
}

class _GamesCenterScreenState extends State<GamesCenterScreen> {
  // The backend currently exposes only these two real game types.
  // Keep the UI aligned with the authoritative RPC instead of showing fake buttons.
  static const games = [
    ('Dice', Icons.filter_1, 'نرد سريع'),
    ('RPS', Icons.style, 'حجر ورق مقص'),
  ];

  Future<void> _startGame(BuildContext context, String type) async {
    final db = Supabase.instance.client;
    if (db.auth.currentUser == null) return;
    try {
      final room = await db.from('rooms').select('id,name').eq('is_active', true).order('created_at').limit(1).maybeSingle();
      if (room == null) throw StateError('لا توجد غرفة نشطة لبدء اللعبة');
      final result = await db.rpc('asmar_start_game', params: {'p_room_id': room['id'], 'p_game_type': type});
      if (!mounted) return;
      showDialog(context: context, builder: (_) => AlertDialog(title: Text('تم بدء ' + type.toUpperCase()), content: Text(result.toString()), actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('حسناً'))]));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('تعذر بدء اللعبة: ' + e.toString())));
    }
  }

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
                onTap: () => _startGame(context, game.$1.toLowerCase()),
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
