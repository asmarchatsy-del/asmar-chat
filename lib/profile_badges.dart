import 'package:flutter/material.dart';

class ProfileBadges extends StatelessWidget {
  final bool activityAdmin;
  final bool customerService;
  final bool verified;

  const ProfileBadges({
    super.key,
    this.activityAdmin = false,
    this.customerService = false,
    this.verified = false,
  });

  @override
  Widget build(BuildContext context) {
    final badges = <Widget>[];
    if (activityAdmin) {
      badges.add(_Badge(
        text: 'ادمن النشاط',
        icon: Icons.bolt,
        colors: const [Color(0xFF6B2C0B), Color(0xFFFF9F43)],
      ));
    }
    if (customerService) {
      badges.add(_Badge(
        text: 'CS',
        icon: Icons.support_agent,
        colors: const [Color(0xFF063B5A), Color(0xFF19A9E5)],
      ));
    }
    if (verified) {
      badges.add(const _Badge(
        text: '✓',
        icon: Icons.verified,
        colors: [Color(0xFF075E54), Color(0xFF19C37D)],
      ));
    }
    if (badges.isEmpty) return const SizedBox.shrink();
    return Wrap(
      spacing: 5,
      runSpacing: 5,
      alignment: WrapAlignment.center,
      children: badges,
    );
  }
}

class _Badge extends StatelessWidget {
  final String text;
  final IconData icon;
  final List<Color> colors;

  const _Badge({
    required this.text,
    required this.icon,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        gradient: LinearGradient(colors: colors),
        border: Border.all(color: Colors.white.withOpacity(.45)),
        boxShadow: [
          BoxShadow(
            color: colors.last.withOpacity(.25),
            blurRadius: 7,
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 12),
          const SizedBox(width: 3),
          Text(
            text,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 9,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}
