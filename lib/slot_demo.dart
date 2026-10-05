// ignore_for_file: unused_field
import 'dart:math';
import 'package:flutter/material.dart';

class SlotDemoPage extends StatefulWidget {
  const SlotDemoPage({super.key});
  @override
  State<SlotDemoPage> createState() => _SlotDemoPageState();
}

class _SlotDemoPageState extends State<SlotDemoPage> {
  final _random = Random();
  final _symbols = const ['🍒', '🍋', '🍊', '⭐', '7️⃣', '💎'];
  final _controller = ScrollController();
  List<String> _reels = const ['🍒', '⭐', '💎'];
  int _demoCoins = 10000;
  int _lastWin = 0;
  bool _spinning = false;

  Future<void> _spin() async {
    if (_spinning || _demoCoins < 100) return;
    setState(() {
      _demoCoins -= 100;
      _lastWin = 0;
      _spinning = true;
    });
    for (var i = 0; i < 12; i++) {
      await Future<void>.delayed(const Duration(milliseconds: 55));
      if (!mounted) return;
      setState(() {
        _reels = List.generate(3, (_) => _symbols[_random.nextInt(_symbols.length)]);
      });
    }
    final a = _symbols[_random.nextInt(_symbols.length)];
    final b = _symbols[_random.nextInt(_symbols.length)];
    final c = _symbols[_random.nextInt(_symbols.length)];
    var win = 0;
    if (a == b && b == c) {
      win = a == '7️⃣' ? 2500 : (a == '💎' ? 1500 : 700);
    } else if (a == b || b == c || a == c) {
      win = 200;
    }
    if (!mounted) return;
    setState(() {
      _reels = [a, b, c];
      _lastWin = win;
      _demoCoins += win;
      _spinning = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('🎰 سلوت تجريبية • $_demoCoins'),
        backgroundColor: const Color(0xFF120805),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF241007), Color(0xFF070403)],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  const Text('🎰 SLOT DEMO',
                      style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: Color(0xFFFFD36A))),
                  const SizedBox(height: 8),
                  const Text('كوينز تجريبية فقط — لا علاقة لها بمحفظة Asmar Chat',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white60)),
                  const SizedBox(height: 28),
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: const Color(0xFF160A06),
                      borderRadius: BorderRadius.circular(26),
                      border: Border.all(color: const Color(0xFFB77921), width: 1.4),
                    ),
                    child: Row(
                      children: _reels.map((s) => Expanded(
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 5),
                          height: 110,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: Colors.black,
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(color: const Color(0xFFFFD36A)),
                          ),
                          child: Text(s, style: const TextStyle(fontSize: 48)),
                        ),
                      )).toList(),
                    ),
                  ),
                  const SizedBox(height: 18),
                  if (_lastWin > 0)
                    Text('ربحت $_lastWin كوين تجريبي 🎉',
                        style: const TextStyle(color: Color(0xFFFFD36A), fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 18),
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: FilledButton.icon(
                      onPressed: _spinning || _demoCoins < 100 ? null : _spin,
                      icon: const Icon(Icons.casino),
                      label: Text(_spinning ? 'جاري الدوران...' : 'لفّ — 100 كوين تجريبي'),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text('الرصيد التجريبي: $_demoCoins',
                      style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
