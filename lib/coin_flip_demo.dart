import 'dart:math';
import 'package:flutter/material.dart';

class CoinFlipDemoPage extends StatefulWidget {
  const CoinFlipDemoPage({super.key});
  @override State<CoinFlipDemoPage> createState() => _CoinFlipDemoPageState();
}

class _CoinFlipDemoPageState extends State<CoinFlipDemoPage> {
  final _random = Random();
  int _demoCoins = 10000;
  String _side = '🪙';
  String _result = 'اقلب العملة للبدء';

  void _flip() {
    if (_demoCoins < 100) return;
    final heads = _random.nextBool();
    setState(() {
      _demoCoins -= 100;
      _side = heads ? '🪙' : '🔵';
      _result = heads ? 'وجه' : 'كتابة';
    });
  }

  @override Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text('🪙 Coin Flip تجريبية • $_demoCoins')),
    body: Padding(
      padding: const EdgeInsets.all(20),
      child: Column(children: [
        const Text('كوينز تجريبية فقط — لا علاقة لها بمحفظة Asmar Chat',
          textAlign: TextAlign.center, style: TextStyle(color: Colors.amber)),
        const SizedBox(height: 45),
        AnimatedSwitcher(duration: const Duration(milliseconds: 250),
          child: Text(_side, key: ValueKey(_side), style: const TextStyle(fontSize: 100))),
        const SizedBox(height: 20),
        Text(_result, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        const Spacer(),
        SizedBox(width: double.infinity, height: 52,
          child: FilledButton.icon(onPressed: _demoCoins >= 100 ? _flip : null,
            icon: const Icon(Icons.sync), label: const Text('قلب 100 كوين تجريبي'))),
      ]),
    ),
  );
}
