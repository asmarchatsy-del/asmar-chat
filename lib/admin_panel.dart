import 'package:flutter/material.dart';

class AdminPanel extends StatelessWidget {
  const AdminPanel({super.key});
  @override
  Widget build(BuildContext context){
    return Scaffold(
      appBar: AppBar(title: const Text('لوحة الإدارة'), backgroundColor: Colors.red),
      body: const Center(child: Text('لوحة الإدارة - قيد التطوير')),
    );
  }
}
