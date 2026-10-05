import 'package:flutter/material.dart';
class CreateRoomSheet extends StatefulWidget { const CreateRoomSheet({super.key}); @override State<CreateRoomSheet> createState()=>_S(); }
class _S extends State<CreateRoomSheet>{
  int selected = 10; final list = [10,15,20,25];
  @override Widget build(BuildContext ctx){
    return Container(padding: EdgeInsets.all(16), decoration: BoxDecoration(color: Color(0xFF1E1E2F), borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      child: Column(mainAxisSize: MainAxisSize.min, children:[
        Text('اختر حجم الغرفة', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
        SizedBox(height: 16),
        Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: list.map((n)=>ChoiceChip(label: Text('$n مقعد'), selected: selected==n, onSelected: (_)=>setState(()=>selected=n), selectedColor: Colors.amber)).toList()),
        SizedBox(height: 16),
        ElevatedButton(onPressed: (){ Navigator.pop(ctx, selected); }, child: Text('إنشاء غرفة $selected')),
      ]),
    );
  }
}
