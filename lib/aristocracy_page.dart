import 'package:flutter/material.dart';
import 'dart:math' as math;

class AristocracyPage extends StatelessWidget {
  const AristocracyPage({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Aristocracy')),
      body: Stack(
        children: [
          Positioned(
            top: 50,
            left: 50,
            child: Transform.rotate(
              angle: math.pi / 4,
              child: Container(
                width: 100,
                height: 100,
                color: Colors.amber,
                child: const Center(
                  child: Text('VIP'),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
