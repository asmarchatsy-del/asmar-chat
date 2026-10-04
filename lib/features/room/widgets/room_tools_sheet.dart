import 'package:flutter/material.dart';
import '../../../asmar/asmar_theme.dart';

class RoomToolsSheet extends StatelessWidget {
  const RoomToolsSheet({super.key});
  static const items = ['777','مركز البث','لعبة PK','صندوق محظوظ','حبة الحظ','Mora','Dice','مشاركة فيديو','بجمو','وضع الغرفة','ترقية الغرفة','حذف الغرفة','إدارة الغرفة','حظر','طرد'];
  static const icons = [Icons.looks_3,Icons.live_tv,Icons.sports_kabaddi,Icons.inventory_2,Icons.star,Icons.monetization_on,Icons.casino,Icons.video_library,Icons.auto_awesome,Icons.meeting_room,Icons.upgrade,Icons.delete_outline,Icons.manage_accounts,Icons.block,Icons.person_remove];

  @override
  Widget build(BuildContext context) => _SheetFrame(
        title: 'أدوات',
        child: GridView.builder(
          padding: const EdgeInsets.all(16), shrinkWrap: true, itemCount: items.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 4, crossAxisSpacing: 10, mainAxisSpacing: 14, childAspectRatio: .85),
          itemBuilder: (_, i) => InkWell(
            onTap: () { Navigator.pop(context); ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('تم اختيار ${items[i]}'))); },
            child: Column(children: [
              Container(width: 50, height: 50, decoration: AsmarTheme.goldCard(radius: 15), child: Icon(icons[i], color: AsmarTheme.gold)),
              const SizedBox(height: 5), Text(items[i], textAlign: TextAlign.center, maxLines: 2, style: const TextStyle(color: Colors.white70, fontSize: 10)),
            ]),
          ),
        ),
      );
}

class _SheetFrame extends StatelessWidget {
  const _SheetFrame({required this.title, required this.child});
  final String title; final Widget child;
  @override
  Widget build(BuildContext context) => Directionality(
    textDirection: TextDirection.rtl,
    child: Container(
      decoration: const BoxDecoration(color: Color(0xFF100A18), borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SafeArea(top: false, child: Column(mainAxisSize: MainAxisSize.min, children: [
        Padding(padding: const EdgeInsets.fromLTRB(18, 16, 12, 4), child: Row(children: [
          Text(title, style: const TextStyle(color: AsmarTheme.gold, fontSize: 19, fontWeight: FontWeight.w900)), const Spacer(),
          IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close, color: Colors.white54)),
        ])),
        child,
      ])),
    ),
  );
}
