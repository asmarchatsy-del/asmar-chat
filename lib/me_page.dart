import 'package:flutter/material.dart';

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
              leading: const Icon(Icons.account_balance_wallet),
              title: const Text('Wallet'),
              subtitle: const Text('My wallet and earnings'),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Wallet - use existing route')),
                );
              },
            ),
          ),
          Card(
            child: ListTile(
              leading: const Icon(Icons.store),
              title: const Text('Store'),
              subtitle: const Text('Buy VIP and gifts'),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Store - use existing route')),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
