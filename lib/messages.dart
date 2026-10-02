import 'package:flutter/material.dart';
import 'global_chat.dart';
import 'private_conversations.dart';

class MessagesPage extends StatelessWidget {
  const MessagesPage({super.key});

  @override
  Widget build(BuildContext context) {
    const gold = Color(0xFFFFD36A);
    const bg = Color(0xFF090604);
    const card = Color(0xFF1B0E08);

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: const Color(0xFF100805),
        title: const Text('الرسائل', style: TextStyle(color: gold, fontWeight: FontWeight.w900)),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _MessageCard(
            icon: Icons.public,
            title: 'الدردشة العامة',
            subtitle: 'رسالة واحدة = 200 كوين 🪙',
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const GlobalChatPage())),
          ),
          const SizedBox(height: 12),
          _MessageCard(
            icon: Icons.chat_bubble,
            title: 'المحادثات الخاصة',
            subtitle: 'محادثات خاصة مجانية • نمط Telegram',
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PrivateConversationsPage())),
          ),
        ],
      ),
    );
  }
}

class _MessageCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  const _MessageCard({required this.icon, required this.title, required this.subtitle, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(17),
        decoration: BoxDecoration(
          color: const Color(0xFF1B0E08),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFF6A421A)),
        ),
        child: Row(children: [
          CircleAvatar(
            radius: 27,
            backgroundColor: const Color(0xFFFFD36A),
            child: Icon(icon, color: Colors.black),
          ),
          const SizedBox(width: 13),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: const TextStyle(color: Color(0xFFFFD36A), fontSize: 17, fontWeight: FontWeight.w900)),
            const SizedBox(height: 4),
            Text(subtitle, style: const TextStyle(color: Colors.white60, fontSize: 12)),
          ])),
          const Icon(Icons.chevron_left, color: Color(0xFFFFD36A)),
        ]),
      ),
    );
  }
}
