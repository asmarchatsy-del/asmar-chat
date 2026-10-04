import 'package:flutter/material.dart';

class SuperAdminPanel extends StatelessWidget {
  const SuperAdminPanel({super.key});

  Widget _users() {
    return Card(
      child: ListTile(
        title: const Text('Users'),
        subtitle: Wrap(
          children: const [
            Chip(label: Text('User1')),
            Chip(label: Text('User2')),
          ],
        ),
      ),
    );
  }

  Widget _table() {
    return Card(
      child: ListTile(
        title: const Text('Table'),
        subtitle: Wrap(
          children: const [
            Chip(label: Text('Item1')),
            Chip(label: Text('Item2')),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Super Admin')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ADMIN_STATS_MARKER
          const Text('Global Gift Active'),
          const SizedBox(height: 16),
          _users(),
          const SizedBox(height: 16),
          _table(),
        ],
      ),
    );
  }
}
