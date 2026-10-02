
  Future<void> _showMyHosts() async {
    final uid = Supabase.instance.client.auth.currentUser?.id;
    if (uid == null) return;
    final agencies = await Supabase.instance.client.from('agencies').select('id,name').eq('owner_id', uid).limit(1);
    if ((agencies as List).isEmpty) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('لا توجد وكالة مرتبطة بك'))); return; }
    final agencyId = agencies.first['id'];
    final hosts = await Supabase.instance.client.from('profiles').select('id,display_name,role,agency_joined_at').eq('agency_id', agencyId).eq('role','HOST').order('agency_joined_at', ascending:false);
    if (!mounted) return;
    await showModalBottomSheet(
      context: context,
      backgroundColor: _bg,
      isScrollControlled: true,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: SizedBox(
          height: MediaQuery.of(ctx).size.height * .7,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const Text('🎙️ مضيفو الوكالة', style: TextStyle(color: _gold, fontSize: 22, fontWeight: FontWeight.w900)),
              const SizedBox(height: 10),
              if ((hosts as List).isEmpty)
                const Text('لا يوجد مضيفون مرتبطون حاليًا', style: TextStyle(color: Colors.white70)),
              ...hosts.map((h) => Card(
                color: _card,
                child: ListTile(
                  title: Text((h['display_name'] ?? 'مضيف').toString(), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  subtitle: Text('ID: ${h['id']}', style: const TextStyle(color: Colors.white54, fontSize: 10)),
                ),
              )),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showCommission() async {
    final rows = await Supabase.instance.client.from('agency_commission_ledger')
      .select('agency_id,source_amount,app_share_amount,work_share_amount,owner_amount,super_admin_amount,manager_amount,bd_amount,admin_amount,created_at')
