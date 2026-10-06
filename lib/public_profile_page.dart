import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AsmarPublicProfilePage extends StatefulWidget {
  const AsmarPublicProfilePage({super.key, required this.userId});
  final String userId;
  @override State<AsmarPublicProfilePage> createState() => _AsmarPublicProfilePageState();
}

class _AsmarPublicProfilePageState extends State<AsmarPublicProfilePage> {
  final db = Supabase.instance.client;
  Map<String,dynamic> profile = {};
  int followers = 0;
  int following = 0;
  int visitors = 0;
  bool followingMe = false;
  bool busy = true;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    try {
      final p = await db.from('profiles').select('id,display_name,username,public_id,avatar_url,user_level,svip_level,is_verified,bio').eq('id',widget.userId).maybeSingle();
      final f1 = await db.from('follows').select('follower_id').eq('following_id',widget.userId);
      final f2 = await db.from('follows').select('following_id').eq('follower_id',widget.userId);
      final v = await db.from('visitors').select('visitor_id').eq('profile_id',widget.userId);
      final me = db.auth.currentUser?.id;
      final isFollowing = me != null && (await db.from('follows').select('following_id').eq('follower_id',me).eq('following_id',widget.userId).maybeSingle()) != null;
      if (!mounted) return;
      setState(() {
        profile = Map<String,dynamic>.from(p ?? {});
        followers = (f1 as List).length;
        following = (f2 as List).length;
        visitors = (v as List).length;
        followingMe = isFollowing;
        busy = false;
      });
      if (me != null && me != widget.userId) {
        await db.from('visitors').upsert({'profile_id': widget.userId, 'visitor_id': me, 'visited_at': DateTime.now().toUtc().toIso8601String()}, onConflict: 'profile_id,visitor_id');
      }
    } catch (e) {
      if (mounted) {
        setState(() => busy = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('تعذر تحميل الملف: $e')));
      }
    }
  }

  Future<void> _toggleFollow() async {
    final me = db.auth.currentUser?.id;
    if (me == null || me == widget.userId || busy) return;
    setState(() => busy = true);
    try {
      if (followingMe) {
        await db.from('follows').delete().eq('follower_id',me).eq('following_id',widget.userId);
      } else {
        await db.from('follows').insert({'follower_id':me,'following_id':widget.userId});
      }
      await _load();
    } catch (e) {
      if (mounted) {
        setState(() => busy = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('تعذر تحديث المتابعة: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final name = (profile['display_name'] ?? profile['username'] ?? 'Asmar User').toString();
    final avatar = profile['avatar_url']?.toString() ?? '';
    final me = db.auth.currentUser?.id == widget.userId;
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFF070817),
        appBar: AppBar(title: const Text('الملف الشخصي'), backgroundColor: const Color(0xFF070817)),
        body: busy && profile.isEmpty ? const Center(child: CircularProgressIndicator()) : RefreshIndicator(
          onRefresh: _load,
          child: ListView(padding: const EdgeInsets.all(16), children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                gradient: const LinearGradient(colors:[Color(0xFF2A1D08),Color(0xFF11152D)]),
                border: Border.all(color: const Color(0xFF6A4A12)),
              ),
              child: Column(children:[
                CircleAvatar(radius:48, backgroundColor: const Color(0xFFFFC94A), backgroundImage: avatar.isNotEmpty ? NetworkImage(avatar) : null,
                  child: avatar.isEmpty ? const Icon(Icons.person,color:Colors.black,size:42) : null),
                const SizedBox(height:10),
                Row(mainAxisAlignment: MainAxisAlignment.center, children:[
                  Flexible(child: Text(name,style:const TextStyle(fontSize:23,fontWeight:FontWeight.w900),overflow:TextOverflow.ellipsis)),
                  if(profile['is_verified']==true) const Padding(padding:EdgeInsets.only(right:6),child:Icon(Icons.verified,color:Color(0xFFFFC94A),size:19)),
                ]),
                Text('ID ${profile['public_id'] ?? widget.userId}',style:const TextStyle(color:Color(0xFFA9B0D0),fontSize:11)),
                if((profile['bio']?.toString() ?? '').trim().isNotEmpty) ...[
                  const SizedBox(height:8), Text(profile['bio'].toString(),textAlign:TextAlign.center,style:const TextStyle(color:Colors.white70)),
                ],
                const SizedBox(height:15),
                Row(mainAxisAlignment:MainAxisAlignment.spaceAround,children:[
                  _stat(followers,'المتابعون'),_stat(following,'يتابع'),_stat(visitors,'الزائرون'),_stat(profile['user_level'] ?? 1,'المستوى')
                ]),
                if(!me) ...[
                  const SizedBox(height:15),
                  SizedBox(width:double.infinity,child:FilledButton.icon(
                    onPressed: busy ? null : _toggleFollow,
                    style: FilledButton.styleFrom(backgroundColor: const Color(0xFFFFC94A),foregroundColor:Colors.black),
                    icon: Icon(followingMe ? Icons.person_remove : Icons.person_add),
                    label: Text(followingMe ? 'إلغاء المتابعة' : 'متابعة',style:const TextStyle(fontWeight:FontWeight.w900)),
                  )),
                ],
              ]),
            ),
          ]),
        ),
      ),
    );
  }

  Widget _stat(dynamic value,String label)=>Column(children:[
    Text(value.toString(),style:const TextStyle(fontSize:17,fontWeight:FontWeight.w900)),
    const SizedBox(height:2),Text(label,style:const TextStyle(color:Color(0xFFA9B0D0),fontSize:10))
  ]);
}
