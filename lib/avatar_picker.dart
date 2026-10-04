import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'rank_frame.dart';

class AvatarPickerButton extends StatefulWidget{
 final String? avatarUrl,vipLevel,role,publicId;
 final int svipLevel;
 final bool isAnimated;
 final VoidCallback onSaved;
 const AvatarPickerButton({super.key,this.avatarUrl,this.isAnimated=false,this.vipLevel,this.svipLevel=0,this.role,this.publicId,required this.onSaved});
 @override State<AvatarPickerButton> createState()=>_AvatarPickerButtonState();
}
class _AvatarPickerButtonState extends State<AvatarPickerButton>{
 bool busy=false;
 Future<void> pick()async{
  final vip=int.tryParse((widget.vipLevel??'').replaceAll(RegExp(r'[^0-9]'),''))??0;
  final admin=['CEO','SUPER_ADMIN','MANAGER','ADMIN'].contains((widget.role??'USER').toUpperCase());
  if(widget.isAnimated && vip<7 && !admin){ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('الصور المتحركة متاحة من VIP7+ فقط')));return;}
  final x=await ImagePicker().pickImage(source:ImageSource.gallery);
  if(x==null)return;
  setState(()=>busy=true);
  try{
   final file=File(x.path); final ext=x.path.split('.').last.toLowerCase(); final animated=ext=='gif';
   if(animated && vip<7 && !admin){if(mounted)ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('GIF/الصورة المتحركة متاحة من VIP7+ فقط')));return;}
   final uid=Supabase.instance.client.auth.currentUser!.id;
   final path='$uid/avatar_${DateTime.now().millisecondsSinceEpoch}.$ext';
   await Supabase.instance.client.storage.from('avatars').upload(path,file,fileOptions:FileOptions(upsert:true,contentType:'image/$ext'));
   final url=Supabase.instance.client.storage.from('avatars').getPublicUrl(path);
   await Supabase.instance.client.from('profiles').update({'avatar_url':url,'avatar_is_animated':animated}).eq('id',uid);
   widget.onSaved();
   if(mounted)ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('تم تحديث الصورة الشخصية ✅')));
  }catch(e){if(mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text('تعذر رفع الصورة: $e')));}
  if(mounted)setState(()=>busy=false);
 }
 @override Widget build(BuildContext context)=>GestureDetector(onTap:busy?null:pick,child:Stack(alignment:Alignment.bottomRight,children:[
  RankFrame(role:widget.role??'USER',vipLevel:widget.vipLevel,svipLevel:widget.svipLevel,size:92,showLabel:false,child:CircleAvatar(backgroundColor:const Color(0xFF120A06),backgroundImage:(widget.avatarUrl??'').isNotEmpty?NetworkImage(widget.avatarUrl!):null,child:(widget.avatarUrl??'').isEmpty?const Icon(Icons.person,color:Color(0xFFFFD36A),size:42):null)),
  Container(padding:const EdgeInsets.all(7),decoration:const BoxDecoration(shape:BoxShape.circle,color:Color(0xFFFFD36A)),child:Icon(busy?Icons.hourglass_top:Icons.camera_alt,color:Colors.black,size:18))
 ]));
}