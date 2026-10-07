
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AsmarAccessoriesPage extends StatelessWidget {
  const AsmarAccessoriesPage({super.key});
  @override
  Widget build(BuildContext context) {
    final uid = Supabase.instance.client.auth.currentUser?.id;
    final future = uid == null ? Future.value(const <Map<String, dynamic>>[]) : Supabase.instance.client.from('user_items').select('id,item_type,item_id,item_name,asset_url,price,purchased_at,is_equipped').eq('user_id', uid).order('purchased_at', ascending: false);
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(title: const Text('إكسسواراتي', style: TextStyle(fontWeight: FontWeight.w900))),
        body: FutureBuilder(
          future: future,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) return const Center(child: CircularProgressIndicator());
            if (snapshot.hasError) return Center(child: Text('تعذر تحميل الإكسسوارات: ' + snapshot.error.toString()));
            final rows = List<Map<String, dynamic>>.from(snapshot.data ?? const []);
            if (rows.isEmpty) return const Center(child: Text('لا توجد إكسسوارات مملوكة بعد.'));
            return ListView.separated(
              padding: const EdgeInsets.all(14),
              itemCount: rows.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (_, i) {
                final r = rows[i];
                final asset = r['asset_url']?.toString() ?? '';
                return ListTile(
                  tileColor: const Color(0xFF1A100B),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  leading: CircleAvatar(backgroundImage: asset.isNotEmpty ? NetworkImage(asset) : null, child: asset.isEmpty ? const Icon(Icons.auto_awesome) : null),
                  title: Text(r['item_name']?.toString() ?? 'عنصر', style: const TextStyle(fontWeight: FontWeight.w900)),
                  subtitle: Text(r['item_type']?.toString() ?? '', style: const TextStyle(color: Color(0xFFB9A995))),
                  trailing: r['is_equipped'] == true ? const Icon(Icons.check_circle, color: Color(0xFFFFD36A)) : null,
                );
              },
            );
          },
        ),
      ),
    );
  }
}
