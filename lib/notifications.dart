import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});
  @override State<NotificationsPage> createState()=>_NotificationsPageState();
}
class _NotificationsPageState extends State<NotificationsPage>{
  @override Widget build(BuildContext context)=>Directionality(textDirection:TextDirection.rtl,child:Scaffold(
    backgroundColor:const Color(0xFF090604),
    appBar:AppBar(backgroundColor:const Color(0xFF100805),foregroundColor:Colors.white,title:const Text('الإشعارات 🔔',style:TextStyle(color:Color(0xFFFFD36A),fontWeight:FontWeight.w900))),
    body:StreamBuilder<List<Map<String,dynamic>>>(
      stream:Supabase.instance.client.from('notifications').stream(primaryKey:['id']).order('created_at',ascending:false),
      builder:(context,snap){
        final uid=Supabase.instance.client.auth.currentUser?.id;
        final rows=(snap.data??[]).where((x)=>x['user_id']==uid).toList();
        if(rows.isEmpty)return const Center(child:Text('لا توجد إشعارات حالياً 🔔',style:TextStyle(color:Colors.white70)));
        return ListView.builder(padding:const EdgeInsets.all(14),itemCount:rows.length,itemBuilder:(_,i){
          final x=rows[i]; final read=x['is_read']==true;
          return InkWell(onTap:()async{if(!read){await Supabase.instance.client.rpc('mark_notification_read',params:{'p_id':x['id']});setState((){});}},child:Container(
            margin:const EdgeInsets.only(bottom:10),padding:const EdgeInsets.all(14),
            decoration:BoxDecoration(color:read?const Color(0xFF160B07):const Color(0xFF2A160A),borderRadius:BorderRadius.circular(17),border:Border.all(color:read?const Color(0xFF3A2414):const Color(0xFFFFD36A))),
            child:Row(children:[Icon(read?Icons.notifications_none:Icons.notifications_active,color:const Color(0xFFFFD36A),size:30),const SizedBox(width:12),Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text(x['title']?.toString()??'إشعار',style:const TextStyle(color:Color(0xFFFFD36A),fontWeight:FontWeight.w900)),const SizedBox(height:4),Text(x['body']?.toString()??'',style:const TextStyle(color:Colors.white,fontSize:13))]))])
          ));
        });
      },
    ),
  ));
}
