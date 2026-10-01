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
  int coins = 1000000;

  final List<Map<String, dynamic>> users = [
    {'name': 'Asmar Owner', 'role': 'CEO', 'coins': 500000, 'online': true},
    {'name': 'مضيف أسمر', 'role': 'HOST', 'coins': 12000, 'online': true},
    {'name': 'محمد', 'role': 'AGENT', 'coins': 8500, 'online': false},
    {'name': 'VIP User', 'role': 'USER', 'coins': 3200, 'online': true},
  ];

  final List<Map<String, dynamic>> hosts = [
    {'name': 'مضيف أسمر', 'agency': 'وكالة أسمر', 'status': true, 'coins': 12000},
    {'name': 'ليان', 'agency': 'وكالة سوريا', 'status': true, 'coins': 9800},
    {'name': 'نور', 'agency': 'وكالة النجوم', 'status': false, 'coins': 6500},
  ];

  final List<Map<String, dynamic>> agencies = [
    {'name': 'وكالة أسمر', 'manager': 'MANAGER', 'hosts': 12, 'status': true},
    {'name': 'وكالة سوريا', 'manager': 'AGENT', 'hosts': 8, 'status': true},
    {'name': 'وكالة النجوم', 'manager': 'AGENT', 'hosts': 5, 'status': false},
  ];

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
        _ownerWallet(),
        const SizedBox(height: 16),
        const Text(
          'الأوسمة والصلاحيات',
          style: TextStyle(color: gold, fontSize: 19, fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: const [
            _RoleBadge(title: 'CEO', icon: Icons.workspace_premium),
            _RoleBadge(title: 'SUPER ADMIN', icon: Icons.shield),
            _RoleBadge(title: 'ADMIN', icon: Icons.admin_panel_settings),
            _RoleBadge(title: 'MANAGER', icon: Icons.manage_accounts),
            _RoleBadge(title: 'HOST', icon: Icons.mic),
            _RoleBadge(title: 'AGENT', icon: Icons.business),
          ],
        ),
        const SizedBox(height: 18),
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

  String _roleLabel(String role) {
    switch (role) {
      case 'CEO': return 'CEO';
      case 'SUPER_ADMIN': return 'SUPER ADMIN';
      case 'MANAGER': return 'MANAGER';
      case 'ADMIN': return 'ADMIN';
      case 'HOST': return 'HOST';
      case 'AGENT': return 'AGENT';
      default: return 'USER';
    }
  }

  List<String> _permissionsFor(String role) {
    switch (role) {
      case 'CEO': return ['إدارة كاملة', 'الكوينزات', 'المستخدمون', 'الغرف', 'المضيفون', 'الوكالات', 'الصلاحيات'];
      case 'SUPER_ADMIN': return ['المستخدمون', 'الغرف', 'المضيفون', 'الوكالات', 'الإعدادات'];
      case 'MANAGER': return ['المضيفون', 'الوكالات', 'الغرف'];
      case 'ADMIN': return ['المستخدمون', 'الغرف'];
      case 'HOST': return ['إدارة الغرفة', 'المضيفون'];
      case 'AGENT': return ['الوكالات', 'المضيفون'];
      default: return ['الدردشة'];
    }
  }

  Widget _roleBadge(String role) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
    decoration: BoxDecoration(
      gradient: const LinearGradient(colors: [Color(0xFFFFD36A), Color(0xFF9A5A12)]),
      borderRadius: BorderRadius.circular(20),
    ),
    child: Text(_roleLabel(role), style: const TextStyle(color: Colors.black, fontSize: 10, fontWeight: FontWeight.w900)),
  );

  void _manageRoles() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: bg,
      isScrollControlled: true,
      builder: (_) => Directionality(
        textDirection: TextDirection.rtl,
        child: SizedBox(
          height: MediaQuery.of(context).size.height * .78,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const Text('نظام الرتب والصلاحيات', style: TextStyle(color: gold, fontSize: 22, fontWeight: FontWeight.w900)),
              const SizedBox(height: 6),
              const Text('صلاحيات واجهة الإدارة الحالية — تحتاج حماية Backend عند ربط قاعدة البيانات.', style: TextStyle(color: Colors.white54, fontSize: 12)),
              const SizedBox(height: 16),
              ...['CEO','SUPER_ADMIN','MANAGER','ADMIN','HOST','AGENT','USER'].map((role) => Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(color: card, borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFF4C3019))),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      _roleBadge(role),
                      const Spacer(),
                      Text(role == 'CEO' ? 'صلاحيات كاملة' : _permissionsFor(role).length.toString() + ' صلاحيات', style: const TextStyle(color: Colors.white54, fontSize: 11)),
                    ]),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: _permissionsFor(role).map((p) => Chip(
                        label: Text(p, style: const TextStyle(fontSize: 10)),
                        backgroundColor: const Color(0xFF2A180D),
                        side: BorderSide.none,
                      )).toList(),
                    ),
                  ],
                ),
              )),
            ],
          ),
        ),
      ),
    );
  }

  void _manageHosts() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: bg,
      isScrollControlled: true,
      builder: (_) => Directionality(
        textDirection: TextDirection.rtl,
        child: SizedBox(
          height: MediaQuery.of(context).size.height * .75,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const Text('إدارة المضيفين', style: TextStyle(color: gold, fontSize: 22, fontWeight: FontWeight.w900)),
              const SizedBox(height: 12),
              ...hosts.map((h) => Container(
                margin: const EdgeInsets.only(bottom: 10),
                decoration: BoxDecoration(color: card, borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFF4C3019))),
                child: ListTile(
                  leading: CircleAvatar(backgroundColor: const Color(0xFF422511), child: Icon(h['status'] ? Icons.mic : Icons.mic_off, color: gold)),
                  title: Text(h['name'], style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  subtitle: Text(h['agency'] + ' • ' + h['coins'].toString() + ' Coins', style: const TextStyle(color: Colors.white54, fontSize: 11)),
                  trailing: Switch(
                    value: h['status'],
                    onChanged: (v) { setState(() => h['status'] = v); Navigator.pop(context); _manageHosts(); },
                  ),
                ),
              )),
            ],
          ),
        ),
      ),
    );
  }

  void _manageAgencies() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: bg,
      isScrollControlled: true,
      builder: (_) => Directionality(
        textDirection: TextDirection.rtl,
        child: SizedBox(
          height: MediaQuery.of(context).size.height * .7,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const Text('إدارة الوكالات', style: TextStyle(color: gold, fontSize: 22, fontWeight: FontWeight.w900)),
              const SizedBox(height: 12),
              ...agencies.map((a) => Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(color: card, borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFF4C3019))),
                child: Row(
                  children: [
                    const CircleAvatar(backgroundColor: Color(0xFF422511), child: Icon(Icons.business, color: gold)),
                    const SizedBox(width: 12),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(a['name'], style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      Text(a['manager'] + ' • ' + a['hosts'].toString() + ' مضيف', style: const TextStyle(color: Colors.white54, fontSize: 11)),
                    ])),
                    Switch(value: a['status'], onChanged: (v) => setState(() => a['status'] = v)),
                  ],
                ),
              )),
            ],
          ),
        ),
      ),
    );
  }

  void _manageUsers() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: bg,
      isScrollControlled: true,
      builder: (_) => Directionality(
        textDirection: TextDirection.rtl,
        child: SizedBox(
          height: MediaQuery.of(context).size.height * .72,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const Text('إدارة المستخدمين', style: TextStyle(color: gold, fontSize: 22, fontWeight: FontWeight.w900)),
              const SizedBox(height: 12),
              ...users.map((u) => Container(
                margin: const EdgeInsets.only(bottom: 9),
                decoration: BoxDecoration(color: card, borderRadius: BorderRadius.circular(15), border: Border.all(color: const Color(0xFF4C3019))),
                child: ListTile(
                  leading: CircleAvatar(backgroundColor: const Color(0xFF422511), child: Icon(u['online'] ? Icons.person : Icons.person_off, color: gold)),
                  title: Text(u['name'], style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  subtitle: Text('${u['role']} • ${u['coins']} Coins', style: const TextStyle(color: Colors.white54, fontSize: 11)),
                  trailing: PopupMenuButton<String>(
                    onSelected: (value) => _message(value == 'role' ? 'تغيير صلاحية ${u['name']}' : 'إجراءات الحساب: ${u['name']}'),
                    itemBuilder: (_) => const [
                      PopupMenuItem(value: 'role', child: Text('تغيير الصلاحية')),
                      PopupMenuItem(value: 'account', child: Text('إجراءات الحساب')),
                    ],
                  ),
                ),
              )),
            ],
          ),
        ),
      ),
    );
  }

  void _distributeCoins() {
    final controller = TextEditingController();
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: card,
        title: const Text('توزيع الكوينزات', style: TextStyle(color: gold)),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            labelText: 'عدد الكوينزات',
            labelStyle: TextStyle(color: Colors.white70),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('إلغاء')),
          FilledButton(
            onPressed: () {
              final amount = int.tryParse(controller.text) ?? 0;
              if (amount > 0 && amount <= coins) {
                setState(() => coins -= amount);
                Navigator.pop(dialogContext);
                _message('تم تجهيز توزيع $amount Coins');
              } else {
                _message('أدخل مبلغًا صحيحًا ضمن الرصيد');
              }
            },
            child: const Text('توزيع'),
          ),
        ],
      ),
    );
  }

  Widget _ownerWallet() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          colors: [Color(0xFF7A3A0C), Color(0xFF251006)],
        ),
        border: Border.all(color: gold2),
      ),
      child: const Row(
        children: [
          CircleAvatar(
            radius: 27,
            backgroundColor: Color(0xFF422511),
            child: Icon(Icons.account_balance_wallet, color: gold, size: 29),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('محفظة المالك', style: TextStyle(color: Colors.white70, fontSize: 12)),
                SizedBox(height: 3),
                Text('1,000,000 Coins', style: TextStyle(color: gold, fontSize: 22, fontWeight: FontWeight.w900)),
                SizedBox(height: 2),
                Text('الرصيد الحالي: $coins Coins • مخصص للتوزيع على المستخدمين والوكلاء والمشترين', style: TextStyle(color: Colors.white54, fontSize: 10)),
              ],
            ),
          ),
          Icon(Icons.send, color: gold),
        ],
      ),
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


class _RoleBadge extends StatelessWidget {
  final String title;
  final IconData icon;
  const _RoleBadge({required this.title, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 9),
      decoration: BoxDecoration(
        color: const Color(0xFF241307),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: gold2),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: gold, size: 18),
          const SizedBox(width: 6),
          Text(title, style: const TextStyle(color: gold, fontSize: 11, fontWeight: FontWeight.w900)),
        ],
      ),
    );
  }
}
