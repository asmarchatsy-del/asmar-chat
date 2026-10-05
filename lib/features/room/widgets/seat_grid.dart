import 'package:flutter/material.dart';
class SeatGrid extends StatelessWidget {
  final int seatCount; final List<Map<String,dynamic>> seats; final Function(int) onSeatTap;
  const SeatGrid({super.key, required this.seatCount, required this.seats, required this.onSeatTap});
  @override Widget build(BuildContext context) {
    return GridView.builder(
      padding: EdgeInsets.all(12),
      physics: seatCount > 15? const BouncingScrollPhysics() : const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 5, childAspectRatio: seatCount>=20?0.75:0.85, crossAxisSpacing: 8, mainAxisSpacing: 8),
      itemCount: seatCount,
      itemBuilder: (c,i){
        final seat = seats.firstWhere((s)=>s['seat_no']==i, orElse: ()=>{});
        final hasUser = seat['user_id']!=null;
        return GestureDetector(onTap: ()=>onSeatTap(i), child: Column(children:[
          CircleAvatar(radius: seatCount>=20?26:32, backgroundColor: Colors.grey[800], child:!hasUser? Icon(Icons.mic, color: Colors.white30) : null),
          SizedBox(height:4), Text(seat['profiles']?['name']??'فارغ', style: TextStyle(fontSize: 10, color: Colors.white), overflow: TextOverflow.ellipsis)
        ]));
      },
    );
  }
}
