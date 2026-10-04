import 'package:flutter/material.dart';
import '../../../asmar/asmar_theme.dart';

class RoomGiftsSheet extends StatefulWidget {
  const RoomGiftsSheet({super.key});
  @override State<RoomGiftsSheet> createState() => _RoomGiftsSheetState();
}

class _RoomGiftsSheetState extends State<RoomGiftsSheet> {
  int category = 0;
  int count = 1;
  int selected = 0;
  static const categories = ['Popular','Lucky','Couple','Relationship','Funny','Customize','Flag'];
  static const gifts = [
    ('Lucky clover','30',Icons.eco), ('Starry Glimmer','200',Icons.auto_awesome), ('Lion','600',Icons.pets),
    ('Kiss U','1000',Icons.favorite), ('Rose','50',Icons.local_florist), ('Crown','1500',Icons.workspace_premium),
    ('Rocket','2500',Icons.rocket_launch), ('Diamond','5000',Icons.diamond), ('Castle','9000',Icons.castle),
  ];

  @override
  Widget build(BuildContext context) => Directionality(
    textDirection: TextDirection.rtl,
    child: Container(
      height: MediaQuery.sizeOf(context).height * .78,
      decoration: const BoxDecoration(color: Color(0xFF100A18), borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      child: SafeArea(top: false, child: Column(children: [
        Padding(padding: const EdgeInsets.fromLTRB(18,16,12,6), child: Row(children: [
          const Text('الهدايا', style: TextStyle(color: AsmarTheme.gold, fontSize: 20, fontWeight: FontWeight.w900)), const Spacer(),
          IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close, color: Colors.white54)),
        ])),
        SizedBox(height: 45, child: ListView.separated(scrollDirection: Axis.horizontal, padding: const EdgeInsets.symmetric(horizontal: 12), itemCount: categories.length, separatorBuilder: (_,__) => const SizedBox(width: 6), itemBuilder: (_,i) => ChoiceChip(label: Text(categories[i], style: const TextStyle(fontSize: 11)), selected: i == category, onSelected: (_) => setState(() => category=i), selectedColor: AsmarTheme.gold, backgroundColor: AsmarTheme.surface, labelStyle: TextStyle(color: i==category ? Colors.black : Colors.white70)))),
        Expanded(child: GridView.builder(padding: const EdgeInsets.all(14), itemCount: gifts.length, gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 4, crossAxisSpacing: 8, mainAxisSpacing: 10, childAspectRatio: .78), itemBuilder: (_,i) { final g=gifts[i]; return InkWell(onTap: () => setState(() => selected=i), child: Container(decoration: BoxDecoration(color: i==selected ? const Color(0x553A250F) : AsmarTheme.surface, borderRadius: BorderRadius.circular(14), border: Border.all(color: i==selected ? AsmarTheme.gold : Colors.white10)), child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Container(width:50,height:50,decoration:const BoxDecoration(shape:BoxShape.circle,color:Color(0xFF2A173C)),child:Icon(g.$3,color:AsmarTheme.gold,size:28)),const SizedBox(height:5),Text(g.$1,textAlign:TextAlign.center,maxLines:2,style:const TextStyle(color:Colors.white,fontSize:9)),Text('${g.$2} 🪙',style:const TextStyle(color:AsmarTheme.gold,fontSize:9,fontWeight:FontWeight.bold))]))); })),
        Padding(padding: const EdgeInsets.fromLTRB(12,4,12,12), child: Row(children: [const Text('العدد:',style:TextStyle(color:Colors.white70)),const SizedBox(width:8), ...[1,7,17,77,177].map((n)=>Padding(padding:const EdgeInsets.only(left:4),child:ChoiceChip(label:Text('$n'),selected:n==count,onSelected:(_)=>setState(()=>count=n),selectedColor:AsmarTheme.gold,backgroundColor:AsmarTheme.surface,labelStyle:TextStyle(color:n==count?Colors.black:Colors.white)))),const Spacer(),FilledButton(onPressed:(){Navigator.pop(context);ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text('تم إرسال $count هدية')));},style:FilledButton.styleFrom(backgroundColor:AsmarTheme.gold,foregroundColor:Colors.black),child:const Text('إرسال'))]))
      ]),),
    ),
  );
}
