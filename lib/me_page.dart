import 'package:flutter/material.dart';
import 'wallet_page.dart';
import 'store_page.dart';

class MePage extends StatelessWidget {
  // Me avatar RankFrame
  const MePage({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Me')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: ListTile(
              title: const Text('Wallet'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const WalletPage()),
                );
              },
            ),
          ),
          Card(
            child: ListTile(
              title: const Text('Store'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const StorePage()),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
