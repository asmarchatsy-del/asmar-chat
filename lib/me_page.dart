import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'admin_gate.dart';

const Color _meGold = Color(0xFFFFD36A);
const Color _meGoldDark = Color(0xFFB77921);
const Color _meBg = Color(0xFF120A06);
const Color _meCard = Color(0xFF211108);

class MePage extends StatefulWidget {
  const MePage({super.key});

  @override
  State<MePage> createState() => _MePageState();
}

class _MePageState extends State<MePage> {
  late Future<Map<String, dynamic>> _profileFuture;

  SupabaseClient get _db => Supabase.instance.client;

  @override
  void initState() {
    super.initState();
    _profileFuture = _loadProfile();
  }

  Future<Map<String, dynamic>> _loadProfile() async {
    final userId = _db.auth.currentUser?.id;
    if (userId == null) {
      throw Exception('لا توجد جلسة دخول');
    }

    final row = await _db
        .from('profiles')
        .select('id,username,display_name,bio,avatar_url,public_id,vip_level,svip_level,user_level,coins,diamonds,golden_frame,special_frame')
        .eq('id', userId)
        .maybeSingle();

    if (row == null) {
      throw Exception('لم يتم العثور على الملف الشخصي');
    }

    return Map<String, dynamic>.from(row);
  }

  void _reload() {
    setState(() {
      _profileFuture = _loadProfile();
    });
  }

  Future<void> _copyId(String value) async {
    await Clipboard.setData(ClipboardData(text: value));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('تم نسخ الـID')),
    );
  }

  Future<Map<String, int>> _loadStats(String profileId) async {
    final visitors = await _db
        .from('visitors')
        .select('visitor_id')
        .eq('profile_id', profileId);
    final following = await _db
        .from('follows')
        .select('following_id')
        .eq('follower_id', profileId);
    final followers = await _db
        .from('follows')
        .select('follower_id')
        .eq('following_id', profileId);

    return <String, int>{
      'visitors': visitors.length,
      'following': following.length,
      'followers': followers.length,
    };
  }

  Future<void> _openEditProfile(Map<String, dynamic> profile) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => EditProfilePage(profile: profile)),
    );
    if (mounted) _reload();
  }

  Future<void> _openStats(String title, String profileId, String type) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => MeRelationPage(
          title: title,
          profileId: profileId,
          type: type,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: _meBg,
        appBar: AppBar(
          backgroundColor: _meBg,
          title: const Text('أنا', style: TextStyle(fontWeight: FontWeight.w900)),
          actions: [
            IconButton(
              onPressed: _reload,
              icon: const Icon(Icons.refresh),
            ),
          ],
        ),
        body: FutureBuilder<Map<String, dynamic>>(
          future: _profileFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const Center(
                child: CircularProgressIndicator(color: _meGold),
              );
            }
            if (snapshot.hasError || snapshot.data == null) {
              return Center(
                child: Text('تعذر تحميل الملف: ${snapshot.error ?? ''}'),
              );
            }

            final profile = snapshot.data!;
            final profileId = profile['id'].toString();
            final publicId = profile['public_id']?.toString() ?? '---';
            final displayName = profile['display_name']?.toString().trim();
            final username = profile['username']?.toString().trim();
            final name = displayName?.isNotEmpty == true
                ? displayName!
                : (username?.isNotEmpty == true ? username! : 'مستخدم');
            final avatar = profile['avatar_url']?.toString() ?? '';
            final vipLevel = (profile['vip_level'] as num?)?.toInt() ?? 0;
            final specialLevel = (profile['svip_level'] as num?)?.toInt() ?? 0;
            final userLevel = (profile['user_level'] as num?)?.toInt() ?? 1;
            final coins = (profile['coins'] as num?)?.toInt() ?? 0;
            final diamonds = (profile['diamonds'] as num?)?.toInt() ?? 0;

            return RefreshIndicator(
              color: _meGold,
              onRefresh: () async {
                _reload();
                await _profileFuture;
              },
              child: ListView(
                padding: const EdgeInsets.fromLTRB(14, 8, 14, 30),
                children: [
                  InkWell(
                    onTap: () => _openEditProfile(profile),
                    borderRadius: BorderRadius.circular(24),
                    child: _ProfileCard(
                      publicId: publicId,
                      name: name,
                      bio: profile['bio']?.toString() ?? '',
                      avatarUrl: avatar,
                      vipLevel: vipLevel,
                      onAvatarTap: () {},
                    ),
                  ),
                  const SizedBox(height: 12),
                  FutureBuilder<Map<String, int>>(
                    future: _loadStats(profileId),
                    builder: (context, statsSnapshot) {
                      final stats = statsSnapshot.data ?? const <String, int>{};
                      return Row(
                        children: [
                          Expanded(
                            child: _StatButton(
                              label: 'الزوار',
                              value: stats['visitors'] ?? 0,
                              icon: Icons.visibility_outlined,
                              onTap: () => _openStats('الزوار', profileId, 'visitors'),
                            ),
                          ),
                          Expanded(
                            child: _StatButton(
                              label: 'المتابَعون',
                              value: stats['following'] ?? 0,
                              icon: Icons.person_add_alt_1_outlined,
                              onTap: () => _openStats('المتابَعون', profileId, 'following'),
                            ),
                          ),
                          Expanded(
                            child: _StatButton(
                              label: 'المتابعون',
                              value: stats['followers'] ?? 0,
                              icon: Icons.people_outline,
                              onTap: () => _openStats('المتابعون', profileId, 'followers'),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _MembershipCard(
                          title: 'أرستقراطية',
                          subtitle: vipLevel > 0 ? 'المستوى $vipLevel' : 'فتح العضوية',
                          icon: Icons.workspace_premium_outlined,
                          onTap: () => _openPackages(context, false),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _MembershipCard(
                          title: 'أرستقراطية مميزة',
                          subtitle: specialLevel > 0 ? 'المستوى $specialLevel' : 'الدخول المميز',
                          icon: Icons.diamond_outlined,
                          onTap: () => _openPackages(context, true),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _BalanceCard(coins: coins, diamonds: diamonds),
                  const SizedBox(height: 10),
                  _ActionCard(
                    icon: Icons.account_balance_wallet_outlined,
                    title: 'المحفظة',
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const _SimplePage(title: 'المحفظة')),
                    ),
                  ),
                  _ActionCard(
                    icon: Icons.storefront_outlined,
                    title: 'المتجر',
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const _SimplePage(title: 'المتجر')),
                    ),
                  ),
                  _ActionCard(
                    icon: Icons.shopping_bag_outlined,
                    title: 'الشنطة',
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const _SimplePage(title: 'الشنطة')),
                    ),
                  ),
                  _ActionCard(
                    icon: Icons.family_restroom,
                    title: 'العائلة',
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const _SimplePage(title: 'مركز العائلة')),
                    ),
                  ),
                  _ActionCard(
                    icon: Icons.favorite_outline,
                    title: 'CP',
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const _SimplePage(title: 'CP')),
                    ),
                  ),
                  _ActionCard(
                    icon: Icons.people_alt_outlined,
                    title: 'الأخ والأخت',
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const _SimplePage(title: 'الأخ والأخت')),
                    ),
                  ),
                  _ActionCard(
                    icon: Icons.stars_outlined,
                    title: 'المستوى $userLevel',
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const _SimplePage(title: 'مركز المستوى')),
                    ),
                  ),
                  _ActionCard(
                    icon: Icons.mic_external_on_outlined,
                    title: 'مركز المضيف',
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const _SimplePage(title: 'مركز المضيف')),
                    ),
                  ),
                  _ActionCard(
                    icon: Icons.support_agent,
                    title: 'تواصل مع المسؤول الرسمي',
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const _SimplePage(title: 'خدمة العملاء')),
                    ),
                  ),
                  _ActionCard(
                    icon: Icons.settings_outlined,
                    title: 'الإعدادات',
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const _SimplePage(title: 'الإعدادات')),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Future<void> _openPackages(BuildContext context, bool special) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => MembershipPackagesPage(special: special),
      ),
    );
    if (mounted) _reload();
  }
}

class _ProfileCard extends StatelessWidget {
  final String publicId;
  final String name;
  final String bio;
  final String avatarUrl;
  final int vipLevel;
  final VoidCallback onAvatarTap;

  const _ProfileCard({
    required this.publicId,
    required this.name,
    required this.bio,
    required this.avatarUrl,
    required this.vipLevel,
    required this.onAvatarTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF3A1C08), Color(0xFF160B06)],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _meGoldDark),
      ),
      child: Row(
        children: [
          SecretAdminAvatarTrigger(
            publicId: publicId,
            child: GestureDetector(
              onTap: onAvatarTap,
              child: Container(
                width: 96,
                height: 96,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: _meGold, width: 3),
                  boxShadow: const [BoxShadow(color: _meGoldDark, blurRadius: 12)],
                ),
                child: CircleAvatar(
                  backgroundColor: const Color(0xFF100804),
                  backgroundImage: avatarUrl.isEmpty ? null : NetworkImage(avatarUrl),
                  child: avatarUrl.isEmpty
                      ? const Icon(Icons.person, color: _meGold, size: 36)
                      : null,
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
                Row(
                  children: [
                    Text('ID: $publicId', style: const TextStyle(color: _meGold, fontWeight: FontWeight.w800)),
                    IconButton(
                      visualDensity: VisualDensity.compact,
                      onPressed: () async {
                        await Clipboard.setData(ClipboardData(text: publicId));
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('تم نسخ الـID')),
                        );
                      },
                      icon: const Icon(Icons.copy, size: 18, color: _meGold),
                    ),
                  ],
                ),
                if (vipLevel > 0)
                  Text('أرستقراطية $vipLevel', style: const TextStyle(color: _meGold, fontSize: 12, fontWeight: FontWeight.w800)),
                Text(
                  bio,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.white60, fontSize: 12),
                ),
              ],
            ),
          ),
          const Icon(Icons.edit_outlined, color: _meGold),
        ],
      ),
    );
  }
}

class _StatButton extends StatelessWidget {
  final String label;
  final int value;
  final IconData icon;
  final VoidCallback onTap;

  const _StatButton({
    required this.label,
    required this.value,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          children: [
            Text('$value', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
            const SizedBox(height: 3),
            Icon(icon, color: _meGoldDark, size: 20),
            Text(label, style: const TextStyle(color: Colors.white60, fontSize: 11)),
          ],
        ),
      ),
    );
  }
}

class _MembershipCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;

  const _MembershipCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        height: 78,
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [Color(0xFF2E1607), Color(0xFF130904)]),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _meGoldDark),
        ),
        child: Row(
          children: [
            const SizedBox(width: 10),
            Icon(icon, color: _meGold, size: 27),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(color: _meGold, fontWeight: FontWeight.w900)),
                  Text(subtitle, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white60, fontSize: 10)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BalanceCard extends StatelessWidget {
  final int coins;
  final int diamonds;

  const _BalanceCard({required this.coins, required this.diamonds});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: _meCard,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Expanded(child: _BalanceItem(icon: '🪙', title: 'كوينز', value: coins)),
            Expanded(child: _BalanceItem(icon: '💎', title: 'ألماس', value: diamonds)),
          ],
        ),
      ),
    );
  }
}

class _BalanceItem extends StatelessWidget {
  final String icon;
  final String title;
  final int value;

  const _BalanceItem({required this.icon, required this.title, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(icon, style: const TextStyle(fontSize: 25)),
        Text('$value', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: _meGold)),
        Text(title, style: const TextStyle(color: Colors.white60, fontSize: 11)),
      ],
    );
  }
}

class _ActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;

  const _ActionCard({required this.icon, required this.title, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: _meCard,
      margin: const EdgeInsets.only(bottom: 6),
      child: ListTile(
        onTap: onTap,
        leading: Icon(icon, color: _meGold),
        title: Text(title),
        trailing: const Icon(Icons.chevron_left, color: _meGoldDark),
      ),
    );
  }
}

class EditProfilePage extends StatefulWidget {
  final Map<String, dynamic> profile;

  const EditProfilePage({super.key, required this.profile});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  late final TextEditingController nameController;
  late final TextEditingController bioController;
  bool saving = false;

  @override
  void initState() {
    super.initState();
    nameController = TextEditingController(text: widget.profile['display_name']?.toString() ?? widget.profile['username']?.toString() ?? '');
    bioController = TextEditingController(text: widget.profile['bio']?.toString() ?? '');
  }

  @override
  void dispose() {
    nameController.dispose();
    bioController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;
    setState(() => saving = true);
    try {
      await Supabase.instance.client.from('profiles').update({
        'display_name': nameController.text.trim(),
        'username': nameController.text.trim(),
        'bio': bioController.text.trim(),
      }).eq('id', userId);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('تعذر الحفظ: $e')));
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: _meBg,
        appBar: AppBar(title: const Text('تعديل الملف الشخصي')),
        body: ListView(
          padding: const EdgeInsets.all(18),
          children: [
            CircleAvatar(
              radius: 48,
              backgroundImage: (widget.profile['avatar_url']?.toString() ?? '').isEmpty
                  ? null
                  : NetworkImage(widget.profile['avatar_url'].toString()),
              child: (widget.profile['avatar_url']?.toString() ?? '').isEmpty
                  ? const Icon(Icons.person, size: 42, color: _meGold)
                  : null,
            ),
            const SizedBox(height: 20),
            TextField(controller: nameController, decoration: const InputDecoration(labelText: 'الاسم')),
            const SizedBox(height: 12),
            TextField(controller: bioController, minLines: 3, maxLines: 5, decoration: const InputDecoration(labelText: 'النبذة')),
            const SizedBox(height: 22),
            FilledButton.icon(
              onPressed: saving ? null : _save,
              icon: const Icon(Icons.save_outlined),
              label: const Text('حفظ'),
            ),
          ],
        ),
      ),
    );
  }
}

class MeRelationPage extends StatelessWidget {
  final String title;
  final String profileId;
  final String type;

  const MeRelationPage({super.key, required this.title, required this.profileId, required this.type});

  Future<List<Map<String, dynamic>>> _load() async {
    final db = Supabase.instance.client;
    if (type == 'visitors') {
      final rows = await db.from('visitors').select('visitor_id').eq('profile_id', profileId);
      return _profiles(rows, 'visitor_id');
    }
    if (type == 'following') {
      final rows = await db.from('follows').select('following_id').eq('follower_id', profileId);
      return _profiles(rows, 'following_id');
    }
    final rows = await db.from('follows').select('follower_id').eq('following_id', profileId);
    return _profiles(rows, 'follower_id');
  }

  Future<List<Map<String, dynamic>>> _profiles(List rows, String key) async {
    final ids = rows.map((row) => row[key].toString()).toList();
    if (ids.isEmpty) return <Map<String, dynamic>>[];
    final result = await Supabase.instance.client
        .from('profiles')
        .select('id,display_name,username,avatar_url,public_id')
        .inFilter('id', ids);
    return List<Map<String, dynamic>>.from(result);
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: _meBg,
        appBar: AppBar(title: Text(title)),
        body: FutureBuilder<List<Map<String, dynamic>>>(
          future: _load(),
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const Center(child: CircularProgressIndicator(color: _meGold));
            }
            if (snapshot.hasError) return Center(child: Text('تعذر التحميل: ${snapshot.error}'));
            final rows = snapshot.data ?? const <Map<String, dynamic>>[];
            if (rows.isEmpty) return const Center(child: Text('لا توجد بيانات بعد', style: TextStyle(color: Colors.white54)));
            return ListView.separated(
              itemCount: rows.length,
              separatorBuilder: (_, __) => const Divider(color: Colors.white10),
              itemBuilder: (_, index) {
                final row = rows[index];
                final image = row['avatar_url']?.toString() ?? '';
                return ListTile(
                  leading: CircleAvatar(
                    backgroundImage: image.isEmpty ? null : NetworkImage(image),
                    child: image.isEmpty ? const Icon(Icons.person) : null,
                  ),
                  title: Text((row['display_name'] ?? row['username'] ?? 'مستخدم').toString()),
                  subtitle: Text('ID: ${row['public_id'] ?? '---'}'),
                );
              },
            );
          },
        ),
      ),
    );
  }
}

class MembershipPackagesPage extends StatelessWidget {
  final bool special;

  const MembershipPackagesPage({super.key, required this.special});

  Future<List<Map<String, dynamic>>> _load() async {
    final result = await Supabase.instance.client
        .from('vip_packages')
        .select('id,name,tier,billing_period,price_usd,coin_price,is_active')
        .eq('is_active', true)
        .order('price_usd');
    final rows = List<Map<String, dynamic>>.from(result);
    final wantedTier = special ? 'special' : 'normal';
    return rows.where((row) => row['tier']?.toString() == wantedTier || row['tier']?.toString() == (special ? 'svip' : 'vip')).toList();
  }

  Future<void> _buy(BuildContext context, Map<String, dynamic> package) async {
    try {
      await Supabase.instance.client.rpc(
        'purchase_aristocracy_package',
        params: {'p_package_id': package['id']},
      );
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم تنفيذ الشراء')));
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('تعذر تنفيذ الشراء: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: _meBg,
        appBar: AppBar(title: Text(special ? 'أرستقراطية مميزة' : 'أرستقراطية')),
        body: FutureBuilder<List<Map<String, dynamic>>>(
          future: _load(),
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) return const Center(child: CircularProgressIndicator(color: _meGold));
            if (snapshot.hasError) return Center(child: Text('تعذر تحميل الباقات: ${snapshot.error}'));
            final packages = snapshot.data ?? const <Map<String, dynamic>>[];
            if (packages.isEmpty) return const Center(child: Text('لا توجد باقات متاحة حالياً'));
            return ListView.builder(
              padding: const EdgeInsets.all(14),
              itemCount: packages.length,
              itemBuilder: (_, index) {
                final package = packages[index];
                return Card(
                  color: _meCard,
                  child: ListTile(
                    leading: Icon(special ? Icons.diamond : Icons.workspace_premium, color: _meGold),
                    title: Text(package['name']?.toString() ?? 'باقة'),
                    subtitle: Text('${package['billing_period'] ?? ''} • ${package['price_usd'] ?? 0} USD'),
                    trailing: FilledButton(onPressed: () => _buy(context, package), child: const Text('شراء')),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}

class _SimplePage extends StatelessWidget {
  final String title;

  const _SimplePage({required this.title});

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: _meBg,
        appBar: AppBar(title: Text(title)),
        body: Center(child: Text(title, style: const TextStyle(fontSize: 22, color: _meGold))),
      ),
    );
  }
}
