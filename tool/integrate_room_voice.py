from pathlib import Path
p=Path('lib/room.dart');s=p.read_text()
if "import 'asmar_keyboard.dart';" not in s:s=s.replace("import 'profile_badges.dart';","import 'profile_badges.dart';\nimport 'asmar_keyboard.dart';")
if 'bool keyboardOpen = false;' not in s:s=s.replace('bool canManageRoom = false;','bool canManageRoom = false;\n  bool keyboardOpen = false;')
s=s.replace("final current = (roomInfo?['seat_count'] as num?)?.toInt() ?? 10;","final current = (roomInfo?['seat_count'] as num?)?.toInt() ?? 8;")
old="""  Widget _seatGrid() {
    final count = (roomInfo?['seat_count'] as num?)?.toInt() ?? 10;
    final byIndex = <int, Map<String, dynamic>>{
      for (final s in seats) (s['seat_index'] as int): s,
    };
    final columns = count <= 4 ? 2 : count <= 8 ? 4 : 5;
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 10),
      padding: const EdgeInsets.fromLTRB(10, 10, 10, 12),
      decoration: BoxDecoration(
        color: const Color(0xC9140805),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: gold2),
      ),
      child: Column(children: [
        Row(children: [
          const Icon(Icons.event_seat, color: gold, size: 20),
          const SizedBox(width: 8),
          Text('المقاعد • $count', style: const TextStyle(color: gold, fontWeight: FontWeight.w900)),
          const Spacer(),
          if (loadingSeats) const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: gold)),
          if (canManageRoom)
            IconButton(
              tooltip: 'عدد المقاعد',
              onPressed: managingSeat ? null : _changeSeatCount,
              icon: const Icon(Icons.settings, color: gold, size: 20),
            ),
        ]),
        const SizedBox(height: 4),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: count,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            mainAxisExtent: 74,
            crossAxisSpacing: 6,
            mainAxisSpacing: 6,
          ),
          itemBuilder: (_, i) {
            final index = i + 1;
            final seat = byIndex[index] ?? {'seat_index': index, 'is_locked': false};
            return _seatTile(index, seat);
          },
        ),
      ]),
    );
  }
"""
new="""  Widget _seatGrid() {
    final count = (roomInfo?['seat_count'] as num?)?.toInt() ?? 8;
    final byIndex = <int, Map<String, dynamic>>{for (final s in seats) (s['seat_index'] as int): s};
    final visible = count == 8 ? 8 : count;
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 10),
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 12),
      decoration: BoxDecoration(color: const Color(0xC9140805),borderRadius: BorderRadius.circular(24),border: Border.all(color: gold2)),
      child: Column(children:[
        Row(children:[const Icon(Icons.event_seat,color:gold,size:20),const SizedBox(width:8),Text('المقاعد • $visible',style:const TextStyle(color:gold,fontWeight:FontWeight.w900)),const Spacer(),if(loadingSeats)const SizedBox(width:18,height:18,child:CircularProgressIndicator(strokeWidth:2,color:gold)),if(canManageRoom)IconButton(onPressed:managingSeat?null:_changeSeatCount,icon:const Icon(Icons.settings,color:gold,size:20))]),
        SizedBox(height:310,child:LayoutBuilder(builder:(context,c){final cx=c.maxWidth/2,cy=145.0,r=c.maxWidth<380?112.0:130.0;return Stack(children:[
          Positioned(left:cx-38,top:8,child:Container(width:76,height:40,alignment:Alignment.center,decoration:BoxDecoration(color:const Color(0xFF4A250A),borderRadius:BorderRadius.circular(20),border:Border.all(color:gold,width:2)),child:const Text('المضيف',style:TextStyle(color:gold,fontWeight:FontWeight.w900)))),
          for(int i=0;i<visible;i++)Positioned(left:cx-37+r*__import_math_cos(i*2*3.1415926535/visible-1.5707963268),top:cy-37+r*__import_math_sin(i*2*3.1415926535/visible-1.5707963268),child:SizedBox(width:74,height:74,child:_seatTile(i+1,byIndex[i+1]??{'seat_index':i+1,'is_locked':false})))
        ]);}))
      ]),
    );
  }
"""
# Dart cannot call Python helpers; replace generated math placeholders with dart math.
new=new.replace('__import_math_cos','math.cos').replace('__import_math_sin','math.sin')
if old not in s: raise SystemExit('seat grid pattern not found')
s=s.replace(old,new)
s=s.replace("import 'dart:async';","import 'dart:async';\nimport 'dart:math' as math;")
oldgift="""IconButton(
                        onPressed: () => showModalBottomSheet(
                          context: context,
                          isScrollControlled: true,
                          backgroundColor: Colors.transparent,
                          builder: (_) => GiftSheet(roomId: widget.roomId),
                        ),
                        icon: const Icon(Icons.card_giftcard, color: gold),
                      ),"""
newgift="""IconButton(
                        onPressed: () => setState(() => keyboardOpen = !keyboardOpen),
                        icon: Icon(keyboardOpen ? Icons.keyboard_hide : Icons.keyboard, color: gold),
                      ),"""
if oldgift not in s: raise SystemExit('gift button pattern not found')
s=s.replace(oldgift,newgift)
needle="""                ),
              ],
            ),
            if (giftOverlay != null)"""
insert="""                ),
                if (keyboardOpen)
                  AsmarKeyboard(
                    controller: controller,
                    roomId: widget.roomId,
                    onSend: _sendMessage,
                    onGiftSent: (gift) {
                      setState(() => giftOverlay = {'emoji': gift['emoji'], 'name': gift['name'], 'amount': gift['price_coins']});
                      Future.delayed(const Duration(seconds: 2), () { if (mounted) setState(() => giftOverlay = null); });
                    },
                  ),
              ],
            ),
            if (giftOverlay != null)"""
if needle not in s: raise SystemExit('keyboard insertion point not found')
s=s.replace(needle,insert)
p.write_text(s)
