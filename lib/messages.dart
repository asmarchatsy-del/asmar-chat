import 'package:flutter/material.dart';
import 'global_chat.dart';
import 'private_conversations.dart';

class MessagesPage extends StatelessWidget {
  const MessagesPage({super.key});

  @override
  Widget build(BuildContext context) {
    const gold = Color(0xFFFFD36A);
    const bg = Color(0xFF090604);

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
            icon: Icons.campaign_rounded,
            title: 'رسائل النظام',
            subtitle: 'Asmar Chat',
            pinned: true,
            verified: true,
          ),
          const SizedBox(height: 10),
          _MessageCard(
            icon: Icons.verified_rounded,
            title: 'asmar chat officiel',
            subtitle: 'القناة الرسمية لـ Asmar Chat',
            pinned: true,
            verified: true,
          ),
          const SizedBox(height: 10),
          _MessageCard(
            icon: Icons.public_rounded,
            title: 'الدردشة العامة',
            subtitle: 'رسالة واحدة = 200 كوين 🪙',
            pinned: true,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const GlobalChatPage()),
            ),
          ),
          const SizedBox(height: 10),
          _MessageCard(
            icon: Icons.chat_bubble_rounded,
            title: 'الرسائل الخاصة',
            subtitle: 'محادثات خاصة مجانية • نمط Telegram',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const PrivateConversationsPage()),
            ),
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
  final bool pinned;
  final bool verified;
  final VoidCallback? onTap;

  const _MessageCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.pinned = false,
    this.verified = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    const gold = Color(0xFFFFD36A);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF1B0E08),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: pinned ? const Color(0xFF8C5B22) : const Color(0xFF4A2E15),
          ),
        ),
        child: Row(
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                CircleAvatar(
                  radius: 27,
                  backgroundColor: gold,
                  child: Icon(icon, color: Colors.black, size: 27),
                ),
                if (pinned)
                  const Positioned(
                    right: -5,
                    top: -7,
                    child: Icon(Icons.push_pin_rounded, color: gold, size: 18),
                  ),
              ],
            ),
            const SizedBox(width: 13),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: gold,
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                      if (verified) ...[
                        const SizedBox(width: 6),
                        const Icon(Icons.verified_rounded, color: Color(0xFF4DA6FF), size: 18),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Colors.white60, fontSize: 12),
                  ),
                ],
              ),
            ),
            if (onTap != null)
              const Icon(Icons.chevron_left, color: gold),
          ],
        ),
      ),
    );
  }
}
