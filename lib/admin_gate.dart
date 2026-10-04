import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'super_admin_panel.dart';

class SuperAdminGate extends StatelessWidget {
  const SuperAdminGate({super.key});
  Future<bool> _allowed() async {
    final uid=Supabase.instance.client.auth.currentUser?.id;
    if(uid==null)return false;
    final row=await Supabase.instance.client.from('admin_roles').select('enabled').eq('user_id',uid).eq('role','super_admin').maybeSingle();
    return row?['enabled']==true;
  }
  @override Widget build(BuildContext context)=>FutureBuilder<bool>(future:_allowed(),builder:(context,s){
    if(s.connectionState!=ConnectionState.done)return const Scaffold(body:Center(child:CircularProgressIndicator()));
    if(s.data!=true)return const Scaffold(body:Center(child:Text('غير مصرح بالدخول')));
    return const SuperAdminPanel();
  });
}

class SecretAdminAvatarTrigger extends StatefulWidget {
  final Widget child; final String publicId;
  const SecretAdminAvatarTrigger({super.key,required this.child,required this.publicId});
  @override State<SecretAdminAvatarTrigger> createState()=>_SecretAdminAvatarTriggerState();
}
class _SecretAdminAvatarTriggerState extends State<SecretAdminAvatarTrigger>{int taps=0;DateTime? first;
  Future<void> _tap() async {
    if(widget.publicId!='116470')return;
    final now=DateTime.now();
    if(first==null||now.difference(first!)>const Duration(seconds:5)){first=now;taps=1;}else{taps++;}
    if(taps>=5){taps=0;first=null;if(!mounted)return;Navigator.push(context,MaterialPageRoute(builder:(_)=>const SuperAdminGate()));}
  }
  @override Widget build(BuildContext context)=>GestureDetector(onTap:_tap,child:widget.child);
}
