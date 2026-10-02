import 'dart:math';
import 'package:flutter/material.dart';

class DiceDemoPage extends StatefulWidget {
  const DiceDemoPage({super.key});
  @override State<DiceDemoPage> createState() => _DiceDemoPageState();
}

class _DiceDemoPageState extends State<DiceDemoPage> {
  final _random = Random();
  int _demoCoins = 10000;
  int _a = 1, _b = 1;
  String _result = 'ارمِ النرد للبدء';

  void _roll() {
    if (_demoCoins < 100) return;
    final a = _random.nextInt(6) + 1;
    final b = _random.nextInt(6) + 1;
    setState(() {
      _demoCoins -= 100;
      _a = a; _b = b;
      _result = a == b ? 'تعادل 🎲' : (a > b ? 'النرد الأول فاز' : 'النرد الثاني فاز');
    });
  }

  @override Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text('🎲 نرد تجريبي • $_demoCoins')),
    body: Padding(
      padding: const EdgeInsets.all(20),
      child: Column(children: [
        const Text('كوينز تجريبية فقط — لا علاقة لها بمحفظة Asmar Chat',
          textAlign: TextAlign.center, style: TextStyle(color: Colors.amber)),
        const SizedBox(height: 35),
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          _die(_a), const SizedBox(width: 28), _die(_b),
        ]),
        const SizedBox(height: 24),
        Text(_result, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        const Spacer(),
        SizedBox(width: double.infinity, height: 52,
          child: FilledButton.icon(onPressed: _demoCoins >= 100 ? _roll : null,
            icon: const Icon(Icons.casino), label: const Text('رمي 100 كوين تجريبي'))),
      ]),
    ),
  );

  Widget _die(int n) => Container(
    width: 86, height: 86, alignment: Alignment.center,
    decoration: BoxDecoration(color: const Color(0xFF2A160A),
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: Colors.amber)),
    child: Text('$n', style: const TextStyle(fontSize: 44, fontWeight: FontWeight.w900)),
  );
}
