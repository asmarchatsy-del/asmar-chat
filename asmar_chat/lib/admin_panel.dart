import 'package:flutter/material.dart';

const gold = Color(0xFFFFD36A);
const gold2 = Color(0xFFB77921);
const bg = Color(0xFF090604);
const card = Color(0xFF1B0E08);

class AdminPanel extends StatefulWidget {
  const AdminPanel({super.key});

  @override
  State<AdminPanel> createState() => _AdminPanelState();
}

class _AdminPanelState extends State<AdminPanel> {
  int selected = 0;

  final List<Map<String, dynamic>> rooms = [
    {
      'name': 'سهرات أسمر',
      'host': 'مضيف أسمر',
      'users': 24,
      'active': true,
    },
    {
      'name': 'لمة الأصدقاء',
      'host': 'محمد',
      'users': 18,
      'active': true,
    },
    {
      'name': 'VIP Lounge',
      'host': 'VIP',
      'users': 12,
      'active': false,
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: bg,
        appBar: AppBar(
          backgroundColor: const Color(0xFF100805),
          foregroundColor: Colors.white,
          title: const Text(
            'لوحة الإدارة',
            style: TextStyle(
              color: gold,
              fontWeight: FontWeight.w900,
            ),
          ),
          actions: [
            IconButton(
              onPressed: () {
                setState(() {});
              },
              icon: const Icon(Icons.refresh),
            ),
          ],
        ),
        body: Column(
          children: [
            _header(),
            const SizedBox(height: 12),
            _tabs(),
            const SizedBox(height: 12),
            Expanded(
              child: selected == 0
                  ? _dashboard()
                  : selected == 1
                      ? _rooms()
                      : _settings(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _header() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          gradient: const LinearGradient(
            colors: [
              Color(0xFF6B2C0B),
              Color(0xFF160A06),
            ],
          ),
          border: Border.all(color: gold2),
        ),
        child: const Row(
          children: [
            CircleAvatar(
              radius: 28,
              backgroundColor: Color(0xFF422511),
              child: Icon(
                Icons.admin_panel_settings,
                color: gold,
                size: 32,
              ),
            ),
            SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'ASMAR CHAT',
                    style: TextStyle(
                      color: gold,
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'لوحة تحكم الإدارة',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.verified,
              color: gold,
              size: 28,
            ),
          ],
        ),
      ),
    );
  }

  Widget _tabs() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          _tabButton(0, 'الرئيسية', Icons.dashboard),
          _tabButton(1, 'الغرف', Icons.meeting_room),
          _tabButton(2, 'الإعدادات', Icons.settings),
        ],
      ),
    );
  }

  Widget _tabButton(int index, String title, IconData icon) {
    final active = selected == index;

    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: InkWell(
          onTap: () => setState(() => selected = index),
          borderRadius: BorderRadius.circular(14),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 13),
            decoration: BoxDecoration(
              color: active ? const Color(0xFF4A2C12) : card,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: active ? gold2 : Colors.white12,
              ),
            ),
            child: Column(
              children: [
                Icon(
                  icon,
                  color: active ? gold : Colors.white60,
                ),
                const SizedBox(height: 5),
                Text(
                  title,
                  style: TextStyle(
                    color: active ? gold : Colors.white70,
                    fontWeight: FontWeight.bold,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _dashboard() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          children: [
            Expanded(
              child: _statCard(
                'المستخدمون',
                '128',
                Icons.people,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _statCard(
                'الغرف',
                '${rooms.length}',
                Icons.meeting_room,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _statCard(
                'المضيفون',
                '32',
                Icons.mic,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _statCard(
                'VIP',
                '17',
                Icons.workspace_premium,
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        const Text(
          'إجراءات سريعة',
          style: TextStyle(
            color: gold,
            fontSize: 19,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 10),
        _action(
          'إضافة غرفة',
          Icons.add_home_work,
          () => _message('تم فتح إضافة غرفة'),
        ),
        _action(
          'إدارة المضيفين',
          Icons.mic_external_on,
          () => _message('إدارة المضيفين'),
        ),
        _action(
          'إدارة الوكالات',
          Icons.business,
          () => _message('إدارة الوكالات'),
        ),
      ],
    );
  }

  Widget _rooms() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: rooms.length,
      itemBuilder: (context, index) {
        final room = rooms[index];

        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: card,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFF4C3019)),
          ),
          child: Row(
            children: [
              const CircleAvatar(
                radius: 26,
                backgroundColor: Color(0xFF422511),
                child: Icon(
                  Icons.mic,
                  color: gold,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      room['name'],
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      '${room['host']} • ${room['users']} مستخدم',
                      style: const TextStyle(
                        color: Colors.white54,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              Switch(
                value: room['active'],
                activeColor: gold,
                onChanged: (value) {
                  setState(() {
                    room['active'] = value;
                  });
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _settings() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _setting(
          'الإشعارات',
          Icons.notifications,
          true,
        ),
        _setting(
          'وضع المشرف',
          Icons.admin_panel_settings,
          true,
        ),
        _setting(
          'السماح بالغرف العامة',
          Icons.public,
          true,
        ),
        _setting(
          'الحماية',
          Icons.security,
          true,
        ),
      ],
    );
  }

  Widget _statCard(String title, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFF4C3019)),
      ),
      child: Column(
        children: [
          Icon(icon, color: gold, size: 30),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.w900,
            ),
          ),
          Text(
            title,
            style: const TextStyle(
              color: Colors.white54,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  Widget _action(
    String title,
    IconData icon,
    VoidCallback onTap,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        onTap: onTap,
        tileColor: card,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Color(0xFF4C3019)),
        ),
        leading: CircleAvatar(
          backgroundColor: const Color(0xFF422511),
          child: Icon(icon, color: gold),
        ),
        title: Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        trailing: const Icon(
          Icons.arrow_back_ios,
          color: Colors.white54,
          size: 16,
        ),
      ),
    );
  }

  Widget _setting(
    String title,
    IconData icon,
    bool value,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF4C3019)),
      ),
      child: SwitchListTile(
        value: value,
        onChanged: (_) {},
        activeColor: gold,
        secondary: Icon(icon, color: gold),
        title: Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  void _message(String text) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(text),
        backgroundColor: gold2,
      ),
    );
  }
}
