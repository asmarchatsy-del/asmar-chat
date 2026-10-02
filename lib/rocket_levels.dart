import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class RocketLevels extends StatefulWidget {
  const RocketLevels({super.key});
  @override State<RocketLevels> createState() => _RocketLevelsState();
}
class _RocketLevelsState extends State<RocketLevels> {
  int lv = 1; bool loading = true;
  List<Map<String,dynamic>> data = [];

  @override void initState(){super.initState();_load();}

  Color _color(dynamic v, Color fallback){
    final raw=v?.toString().replaceFirst('#','');
    if(raw==null||raw.length!=6)return fallback;
    final n=int.tryParse('FF'+raw,radix:16);
    return n==null?fallback:Color(n);
  }
  Future<void> _load() async {
    try {
      final rows=await Supabase.instance.client.from('rocket_levels').select('id,name,bg1,bg2,line,coins').order('id');
      if(!mounted)return;
      setState((){data=List<Map<String,dynamic>>.from(rows);loading=false;});
    } catch(_){if(mounted)setState(()=>loading=false);}
  }
  @override Widget build(BuildContext context){
    if(loading)return const Scaffold(backgroundColor:Color(0xFF0A0602),body:Center(child:CircularProgressIndicator()));
    if(data.isEmpty)return const Scaffold(backgroundColor:Color(0xFF0A0602),body:Center(child:Text('لا توجد مستويات صاروخ',style:TextStyle(color:Colors.white70))));
    final c=data.firstWhere((x)=>(x['id'] as num).toInt()==lv,orElse:()=>data.first);
    final line=_color(c['line'],const Color(0xFFFFD700));
    final bg1=_color(c['bg1'],const Color(0xFF2A1E0F));
    final bg2=_color(c['bg2'],const Color(0xFF1A1109));
    final id=(c['id'] as num).toInt();
    final coins=(c['coins'] as num?)?.toInt()??0;
    return Scaffold(
      backgroundColor:const Color(0xFF0A0602),
      body:SafeArea(child:Container(
        margin:const EdgeInsets.all(10),
        decoration:BoxDecoration(borderRadius:BorderRadius.circular(24),border:Border.all(color:line,width:2),gradient:LinearGradient(begin:Alignment.topCenter,end:Alignment.bottomCenter,colors:[bg1,bg2])),
        child:Stack(children:[
          Positioned(left:0,top:0,bottom:0,child:Container(width:20,decoration:BoxDecoration(gradient:LinearGradient(colors:[line.withOpacity(.3),Colors.transparent])))),
          Positioned(right:0,top:0,bottom:0,child:Container(width:20,decoration:BoxDecoration(gradient:LinearGradient(colors:[Colors.transparent,line.withOpacity(.3)])))),
          Column(children:[
            Padding(padding:const EdgeInsets.all(10),child:Row(children:[
              _circleBtn(Icons.question_mark),const Spacer(),
              Container(padding:const EdgeInsets.symmetric(horizontal:12,vertical:6),decoration:BoxDecoration(color:Colors.black54,borderRadius:BorderRadius.circular(20),border:Border.all(color:line)),child:const Text('سوريا العز 110470',style:TextStyle(color:Colors.white,fontSize:11))),
              const Spacer(),_circleBtn(Icons.close),
            ])),
            Expanded(child:Center(child:Column(mainAxisAlignment:MainAxisAlignment.center,children:[
              Container(width:130,height:280,decoration:BoxDecoration(borderRadius:BorderRadius.circular(70),boxShadow:[BoxShadow(color:line.withOpacity(.7),blurRadius:40,spreadRadius:5)],gradient:LinearGradient(colors:[Colors.white,line])),child:Center(child:Text(c['name'].toString(),style:const TextStyle(fontSize:14,fontWeight:FontWeight.bold),textAlign:TextAlign.center))),
              const SizedBox(height:12),Text('0/'+id.toString()+'000000',style:const TextStyle(color:Colors.white54,fontSize:12)),
            ]))),
            Padding(padding:const EdgeInsets.symmetric(horizontal:12),child:Column(children:[
              Row(children:[_topBox('TOP 3','days 1',null),const SizedBox(width:6),_topBox('TOP 2','days 1',Icons.emoji_events),const SizedBox(width:6),_topBox('TOP 1',coins.toString(),Icons.monetization_on)]),
              const SizedBox(height:6),
              Row(children:[_topBox('days 1','',null),const SizedBox(width:6),_topBox('100','',Icons.monetization_on,small:true),const SizedBox(width:6),_topBox('TOP 5','days 1',null),const SizedBox(width:6),_topBox('TOP 4','days 1',null)]),
            ])),
            const SizedBox(height:14),
          ]),
          Positioned(right:8,top:80,child:Column(children:data.map((item){
            final n=(item['id'] as num).toInt(); final active=lv==n;
            return GestureDetector(onTap:()=>setState(()=>lv=n),child:Container(margin:const EdgeInsets.only(bottom:8),padding:const EdgeInsets.symmetric(horizontal:12,vertical:8),decoration:BoxDecoration(color:active?line:Colors.black54,borderRadius:BorderRadius.circular(10),border:Border.all(color:line)),child:Text('Lv.$n',style:TextStyle(color:active?Colors.black:Colors.white,fontWeight:FontWeight.bold,fontSize:12))));
          }).toList())),
        ]),
      )),
    );
  }
  Widget _circleBtn(IconData icon)=>Container(width:28,height:28,decoration:const BoxDecoration(color:Colors.black54,shape:BoxShape.circle),child:Icon(icon,size:16,color:Colors.white));
  Widget _topBox(String a,String b,IconData? icon,{bool small=false})=>Expanded(child:Container(height:small?50:62,decoration:BoxDecoration(color:Colors.black.withOpacity(.5),borderRadius:BorderRadius.circular(10),border:Border.all(color:Colors.white12)),child:Column(mainAxisAlignment:MainAxisAlignment.center,children:[
    Text(a,style:const TextStyle(color:Colors.white70,fontSize:9),textAlign:TextAlign.center),
    if(icon!=null)Icon(icon,color:a.contains('TOP 1')||icon==Icons.monetization_on?Colors.amber:Colors.white54,size:20),
    if(b.isNotEmpty)Text(b,style:const TextStyle(color:Colors.white38,fontSize:8)),
  ]));
}
