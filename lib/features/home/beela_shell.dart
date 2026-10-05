import 'package:flutter/material.dart';

class BeelaShell extends StatelessWidget {
  const BeelaShell({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F1A),
      body: Column(
        children: [
          Container(
            height: 200,
            decoration: const BoxDecoration(
              gradient: LinearGradient(colors: [Color(0xFFFFD700), Color(0xFFFF9800)]),
              borderRadius: BorderRadius.only(bottomLeft: Radius.circular(24), bottomRight: Radius.circular(24)),
            ),
            child: const Center(
              child: Text('أسمر شات 🔥', style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
            ),
          ),
          const SizedBox(height: 20),
          const Center(child: Text('التصميم الجديد شغال ✅', style: TextStyle(color: Colors.white))),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('زر إنشاء الغرفة شغال')));
        },
        backgroundColor: Colors.amber,
        child: const Icon(Icons.add, color: Colors.black),
      ),
    );
  }
}
