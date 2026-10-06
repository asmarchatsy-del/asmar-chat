
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AsmarBadgesPage extends StatelessWidget {
  const AsmarBadgesPage({super.key});
  @override
  Widget build(BuildContext context) {
    final uid = Supabase.instance.client.auth.currentUser?.id;
    final future = uid == null
        ? Future.value(const <Map<String, dynamic>>[])
        : Supabase.instance.client.from('user_badges').select('granted_at,is_equipped,badges(id,name,icon_url,description)').eq('user_id', uid).order('granted_at', ascending: false);
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(title: const Text('معرض الشارات', style: TextStyle(fontWeight: FontWeight.w900))),
        body: FutureBuilder(
          future: future,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) return const Center(child: CircularProgressIndicator());
            if (snapshot.hasError) return Center(child: Text('تعذر تحميل الشارات: ' + snapshot.error.toString()));
            final rows = List<Map<String, dynamic>>.from(snapshot.data ?? const []);
            if (rows.isEmpty) return const Center(child: Text('لا توجد شارات ممنوحة لهذا الحساب بعد.'));
            return GridView.builder(
              padding: const EdgeInsets.all(14),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, crossAxisSpacing: 10, mainAxisSpacing: 10, childAspectRatio: .9),
              itemCount: rows.length,
              itemBuilder: (_, i) {
                final b = rows[i]['badges'] is Map ? Map<String, dynamic>.from(rows[i]['badges']) : <String, dynamic>{};
                final icon = b['icon_url']?.toString() ?? '';
                return Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(color: const Color(0xFF11152D), borderRadius: BorderRadius.circular(18), border: Border.all(color: rows[i]['is_equipped'] == true ? const Color(0xFFFFC94A) : const Color(0xFF2B315A))),
                  child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                    CircleAvatar(radius: 35, backgroundImage: icon.isNotEmpty ? NetworkImage(icon) : null, child: icon.isEmpty ? const Icon(Icons.military_tech_rounded, size: 38) : null),
                    const SizedBox(height: 10),
                    Text(b['name']?.toString() ?? 'شارة', textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.w900)),
                    const SizedBox(height: 4),
                    Text(b['description']?.toString() ?? '', textAlign: TextAlign.center, style: const TextStyle(color: Color(0xFFA9B0D0), fontSize: 10)),
                    if (rows[i]['is_equipped'] == true) const Padding(padding: EdgeInsets.only(top: 6), child: Text('مفعّلة', style: TextStyle(color: Color(0xFFFFC94A), fontWeight: FontWeight.w800))),
                  ]),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
