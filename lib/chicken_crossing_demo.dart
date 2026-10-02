import 'dart:math';
import 'package:flutter/material.dart';

class ChickenCrossingDemoPage extends StatefulWidget {
  const ChickenCrossingDemoPage({super.key});
  @override
  State<ChickenCrossingDemoPage> createState() => _ChickenCrossingDemoPageState();
}

class _ChickenCrossingDemoPageState extends State<ChickenCrossingDemoPage>
    with SingleTickerProviderStateMixin {
  final _random = Random();
  late final AnimationController _controller;
  int _demoCoins = 10000;
  int _score = 0;
  int _lane = 0;
  bool _playing = false;
  String _message = 'اضغط ابدأ لعب للعب بكوينز تجريبية فقط';

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _start() {
    if (_demoCoins < 100) {
      setState(() => _message = 'انتهت الكوينز التجريبية — أعد الجولة');
      return;
    }
    setState(() {
      _demoCoins -= 100;
      _score = 0;
      _lane = 0;
      _playing = true;
      _message = 'حرّك الدجاجة للأمام وتجنب السيارات';
    });
  }

  void _move(int delta) {
    if (!_playing) return;
    final next = (_lane + delta).clamp(0, 5);
    setState(() => _lane = next);
    if (_lane == 5) {
      final reward = 200 + _score * 50;
      setState(() {
        _demoCoins += reward;
        _score++;
        _playing = false;
        _message = 'وصلت! +$reward كوين تجريبي';
      });
    } else if (_random.nextInt(5) == 0) {
      setState(() {
        _playing = false;
        _message = 'اصطدمت! جرّب جولة جديدة';
      });
    } else {
      setState(() {
        _score++;
        _message = 'ممتاز! تقدمت خطوة';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('🐔 عبور الدجاجة • $_demoCoins'),
        backgroundColor: const Color(0xFF160B06),
      ),
      body: SafeArea(
        child: Column(
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(18, 16, 18, 6),
              child: Text(
                'تجريبي فقط — لا علاقة له بمحفظة Asmar Chat',
                style: TextStyle(color: Colors.amber, fontWeight: FontWeight.w800),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
              child: Text(_message, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white70)),
            ),
            Expanded(
              child: Container(
                margin: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  gradient: const LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0xFF16351B), Color(0xFF121212)],
                  ),
                  border: Border.all(color: Color(0xFF5A3A16)),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    const Text('🏁', style: TextStyle(fontSize: 42)),
                    for (var row = 5; row >= 0; row--)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: List.generate(5, (i) {
                            final road = row > 0 && row < 5;
                            final car = road && ((i + row) % 3 == 0);
                            final chicken = row == _lane && i == 2;
                            return SizedBox(
                              width: 45,
                              height: 42,
                              child: Center(
                                child: Text(
                                  chicken ? '🐔' : car ? '🚗' : row == 0 ? '🌱' : '·',
                                  style: TextStyle(fontSize: chicken || car ? 26 : 24),
                                ),
                              ),
                            );
                          }),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 4, 18, 22),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(child: FilledButton.icon(onPressed: _playing ? null : _start, icon: const Icon(Icons.play_arrow), label: const Text('ابدأ جولة - 100'))),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(child: OutlinedButton.icon(onPressed: _playing ? () => _move(-1) : null, icon: const Icon(Icons.arrow_back), label: const Text('يسار'))),
                      const SizedBox(width: 10),
                      Expanded(child: OutlinedButton.icon(onPressed: _playing ? () => _move(1) : null, icon: const Icon(Icons.arrow_forward), label: const Text('يمين'))),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
