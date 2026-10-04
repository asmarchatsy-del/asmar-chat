import 'package:flutter/material.dart';
import '../../asmar/asmar_theme.dart';

class RoomInfoSheet extends StatelessWidget {
  const RoomInfoSheet({super.key});
  @override Widget build(BuildContext context) => Directionality(textDirection: TextDirection.rtl, child: Container(padding: const EdgeInsets.fromLTRB(18,16,18,24), decoration: const BoxDecoration(color: Color(0xFF100A18), borderRadius: BorderRadius.vertical(top: Radius.circular(24))), child: Column(mainAxisSize: MainAxisSize.min, children: [
    Row(children: [const Text('معلومات الغرفة', style: TextStyle(color: AsmarTheme.gold, fontSize: 20, fontWeight: FontWeight.w900)), const Spacer(), IconButton(onPressed:()=>Navigator.pop(context),icon:const Icon(Icons.close,color:Colors.white54))]),
    _row('Room ID','479929'), _row('المستوى','Lv.0  →  Lv.1 يحتاج 20000 charm'), _row('المالك','M1'), _row('الإعلان','مرحبا بالجميع'),
  ]));
  static Widget _row(String a,String b)=>Container(margin:const EdgeInsets.only(bottom:9),padding:const EdgeInsets.all(13),decoration:AsmarTheme.card(radius:14),child:Row(children:[Text(a,style:const TextStyle(color:Colors.white70,fontWeight:FontWeight.bold)),const Spacer(),Flexible(child:Text(b,textAlign:TextAlign.end,style:const TextStyle(color:Colors.white)))]));
}
