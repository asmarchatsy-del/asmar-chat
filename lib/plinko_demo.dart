import 'dart:math' as math;
import 'package:flutter/material.dart';

const _gold = Color(0xFFFFD36A);
const _bg = Color(0xFF090604);
const _card = Color(0xFF1B0E08);

class PlinkoDemoPage extends StatefulWidget {
  const PlinkoDemoPage({super.key});
  @override
  State<PlinkoDemoPage> createState() => _PlinkoDemoPageState();
}

class _PlinkoDemoPageState extends State<PlinkoDemoPage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  final math.Random _random = math.Random();
  double _progress = 0;
  int _slot = 4;
  bool _dropping = false;
  int _demoCoins = 10000;

  static const multipliers = <double>[2.0, 1.2, 0.8, 0.5, 0.3, 0.5, 0.8, 1.2, 2.0];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..addListener(() {
        if (mounted) setState(() => _progress = _controller.value);
      });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _drop() async {
    if (_dropping || _demoCoins < 100) return;
    setState(() {
      _dropping = true;
      _demoCoins -= 100;
      _slot = 4;
    });
    _slot = 4 + (_random.nextInt(9) - 4);
    await _controller.forward(from: 0);
    if (!mounted) return;
    setState(() {
      _demoCoins += (100 * multipliers[_slot]).round();
      _dropping = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _bg,
        foregroundColor: Colors.white,
        title: const Text('ألعاب تجريبية'),
        actions: [
          Padding(
            padding: const EdgeInsetsDirectional.only(end: 14),
            child: Center(
              child: Text(
                'تجريبي • $_demoCoins',
                style: const TextStyle(color: _gold, fontWeight: FontWeight.w900),
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _card,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFF4C2B12)),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('PLINKO', style: TextStyle(color: _gold, fontSize: 24, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
                  SizedBox(height: 5),
                  Text('نسخة تجريبية داخل Asmar Chat', style: TextStyle(color: Colors.white70)),
                  SizedBox(height: 8),
                  Text('الرصيد هنا تجريبي فقط ولا يلمس محفظة المستخدم.', style: TextStyle(color: Colors.white38, fontSize: 12)),
                ],
              ),
            ),
            const SizedBox(height: 14),
            Container(
              height: 440,
              decoration: BoxDecoration(
                color: const Color(0xFF100804),
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: const Color(0xFF4C2B12)),
              ),
              child: CustomPaint(painter: _PlinkoPainter(progress: _progress, slot: _slot)),
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _dropping ? null : _drop,
                icon: const Icon(Icons.sports_basketball),
                label: Text(_dropping ? 'جاري الإسقاط…' : 'إسقاط 100 كوين تجريبي'),
                style: FilledButton.styleFrom(
                  backgroundColor: _gold,
                  foregroundColor: Colors.black,
                  minimumSize: const Size.fromHeight(54),
                ),
              ),
            ),
            const SizedBox(height: 12),
            const Text('المضاعفات التجريبية', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.w800)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 7,
              runSpacing: 7,
              children: multipliers.map((m) => Chip(
                label: Text('${m}x'),
                backgroundColor: const Color(0xFF24150B),
                labelStyle: const TextStyle(color: _gold),
              )).toList(),
            ),
          ],
        ),
      ),
    );
  }
}

class _PlinkoPainter extends CustomPainter {
  final double progress;
  final int slot;
  const _PlinkoPainter({required this.progress, required this.slot});

  @override
  void paint(Canvas canvas, Size size) {
    final peg = Paint()..color = _gold;
    final ball = Paint()..color = Colors.white;
    final center = size.width / 2;
    const top = 38.0;
    const rows = 9;
    const spacingX = 34.0;
    const spacingY = 38.0;

    for (var row = 0; row < rows; row++) {
      final count = row + 3;
      final startX = center - ((count - 1) * spacingX) / 2;
      for (var i = 0; i < count; i++) {
        canvas.drawCircle(Offset(startX + i * spacingX, top + row * spacingY), 4.2, peg);
      }
    }

    final bottomY = top + rows * spacingY + 18;
    final boxWidth = size.width / 9;
    for (var i = 0; i < 9; i++) {
      final rect = RRect.fromRectAndRadius(
        Rect.fromLTWH(i * boxWidth + 2, bottomY, boxWidth - 4, 42),
        const Radius.circular(7),
      );
      canvas.drawRRect(rect, Paint()..color = const Color(0xFF25160B));
      final tp = TextPainter(
        text: TextSpan(
          text: '${_PlinkoDemoPageState.multipliers[i]}x',
          style: const TextStyle(color: _gold, fontSize: 12, fontWeight: FontWeight.w900),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(i * boxWidth + (boxWidth - tp.width) / 2, bottomY + 14));
    }

    if (progress > 0) {
      final start = Offset(center, top - 20);
      final target = Offset((slot + 0.5) * boxWidth, bottomY + 12);
      final x = start.dx + (target.dx - start.dx) * progress;
      final y = start.dy + (target.dy - start.dy) * progress;
      final wobble = math.sin(progress * math.pi * 12) * (1 - progress) * 12;
      canvas.drawCircle(Offset(x + wobble, y), 9, ball);
      canvas.drawCircle(
        Offset(x + wobble, y),
        9,
        Paint()..style = PaintingStyle.stroke..color = _gold..strokeWidth = 2,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _PlinkoPainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.slot != slot;
}
