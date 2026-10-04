import 'package:flutter/material.dart';
import '../../asmar/asmar_theme.dart';

class RoomSettingsScreen extends StatefulWidget { const RoomSettingsScreen({super.key}); @override State<RoomSettingsScreen> createState()=>_RoomSettingsScreenState(); }
class _RoomSettingsScreenState extends State<RoomSettingsScreen> {
  bool locked=false, emoji=true, lucky=true;
  @override Widget build(BuildContext context)=>Directionality(textDirection:TextDirection.rtl,child:Scaffold(backgroundColor:AsmarTheme.background,appBar:AppBar(title:const Text('إعداد الغرفة',style:TextStyle(fontWeight:FontWeight.w900))),body:ListView(padding:const EdgeInsets.all(12),children:[
    _tile(Icons.account_circle,'الصورة الرمزية','تغيير صورة الغرفة'), _tile(Icons.edit,'اسم الغرفة','محرم'), _tile(Icons.campaign,'الإعلان','مرحبا بالجميع'), _tile(Icons.flag,'البلد / المنطقة','Syria 🇸🇾'),
    _switch('قفل الغرفة','منع الدخول بدون إذن',locked,(v)=>setState(()=>locked=v)), _tile(Icons.paid,'رسوم العضوية','0 ذهب'), _tile(Icons.face,'وجه الغرفة','الافتراضي'), _tile(Icons.palette,'موضوع الغرفة','Purple Stage'),
    _tile(Icons.speed,'محرك الغرفة','0 / 200'), _tile(Icons.block,'قائمة الكتلة','إدارة المحظورين'),
    _switch('إرسال إيموجي عند ترك الدردشة','إرسال تلقائي',emoji,(v)=>setState(()=>emoji=v)), _switch('رقم الحظ 777 يرسل هدية','تفعيل هدية 777',lucky,(v)=>setState(()=>lucky=v)),
  ]));
  Widget _tile(IconData icon,String title,String value)=>Container(margin:const EdgeInsets.only(bottom:8),decoration:AsmarTheme.card(radius:14),child:ListTile(leading:Icon(icon,color:AsmarTheme.gold),title:Text(title,style:const TextStyle(color:Colors.white,fontWeight:FontWeight.bold)),trailing:SizedBox(width:170,child:Text(value,textAlign:TextAlign.end,style:const TextStyle(color:Colors.white60,fontSize:12)))));
  Widget _switch(String title,String sub,bool value,ValueChanged<bool> onChanged)=>Container(margin:const EdgeInsets.only(bottom:8),decoration:AsmarTheme.card(radius:14),child:SwitchListTile(value:value,onChanged:onChanged,activeColor:AsmarTheme.gold,title:Text(title,style:const TextStyle(color:Colors.white,fontWeight:FontWeight.bold)),subtitle:Text(sub,style:const TextStyle(color:Colors.white54))));
}
