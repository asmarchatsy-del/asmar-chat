import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

const publicChatGold = Color(0xFFFFD36A);
const publicChatBg = Color(0xFF090604);
const publicChatCard = Color(0xFF1B0E08);

class GlobalChatPage extends StatefulWidget {
  const GlobalChatPage({super.key});
  @override State<GlobalChatPage> createState()=>_GlobalChatPageState();
}

class _GlobalChatPageState extends State<GlobalChatPage> {
  final controller=TextEditingController();
  final scroll=ScrollController();
  bool sending=false;

  Future<void> send() async {
    final text=controller.text.trim();
    final user=Supabase.instance.client.auth.currentUser;
    if(text.isEmpty||user==null||sending)return;
    setState(()=>sending=true);
    try {
      await Supabase.instance.client.from('global_chat_messages').insert({'sender_id':user.id,'message':text});
      controller.clear();
      if(scroll.hasClients)scroll.animateTo(0,duration:const Duration(milliseconds:220),curve:Curves.easeOut);
    } finally { if(mounted)setState(()=>sending=false); }
  }

  @override void dispose(){controller.dispose();scroll.dispose();super.dispose();}

  @override Widget build(BuildContext context){
    final stream=Supabase.instance.client.from('global_chat_messages').stream(primaryKey:['id']).order('created_at',ascending:false).limit(200);
    return Scaffold(
      backgroundColor:publicChatBg,
      appBar:AppBar(title:const Text('الدردشة العامة',style:TextStyle(color:publicChatGold,fontWeight:FontWeight.w900)),centerTitle:true),
      body:StreamBuilder<List<Map<String,dynamic>>>(
        stream:stream,
        builder:(context,snapshot){
          final rows=snapshot.data??[];
          return Column(children:[
            Expanded(child:ListView.builder(controller:scroll,reverse:true,padding:const EdgeInsets.fromLTRB(12,12,12,8),itemCount:rows.length,itemBuilder:(context,i){
              final row=rows[i];
              final mine=row['sender_id']==Supabase.instance.client.auth.currentUser?.id;
              return Align(
                alignment:mine?Alignment.centerRight:Alignment.centerLeft,
                child:Container(
                  constraints:BoxConstraints(maxWidth:MediaQuery.sizeOf(context).width*.82),
                  margin:const EdgeInsets.only(bottom:8),
                  padding:const EdgeInsets.symmetric(horizontal:13,vertical:9),
                  decoration:BoxDecoration(
                    color:mine?const Color(0xFF3A1D0D):publicChatCard,
                    borderRadius:BorderRadius.circular(16),
                    border:Border.all(color:mine?publicChatGold.withOpacity(.45):const Color(0xFF4C3019)),
                  ),
                  child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
                    Text(mine?'أنت':'مستخدم',style:const TextStyle(color:publicChatGold,fontSize:10,fontWeight:FontWeight.bold)),
                    const SizedBox(height:3),
                    Text(row['message'].toString(),style:const TextStyle(color:Colors.white,fontSize:14)),
                  ]),
                ),
              );
            })),
            SafeArea(top:false,child:Padding(
              padding:const EdgeInsets.fromLTRB(10,6,10,10),
              child:Row(children:[
                Expanded(child:TextField(controller:controller,maxLength:1000,onSubmitted:(_)=>send(),style:const TextStyle(color:Colors.white),decoration:InputDecoration(hintText:'اكتب رسالتك...',counterText:'',filled:true,fillColor:publicChatCard,border:OutlineInputBorder(borderRadius:BorderRadius.circular(24),borderSide:BorderSide.none)))),
                const SizedBox(width:8),
                IconButton(onPressed:sending?null:send,style:IconButton.styleFrom(backgroundColor:publicChatGold,foregroundColor:Colors.black),icon:const Icon(Icons.send)),
              ]),
            )),
          ]);
        },
      ),
    );
  }
}
