import 'package:flutter/material.dart';
import '../../asmar/asmar_theme.dart';
import 'room_info_sheet.dart';
import 'room_settings_screen.dart';
import 'widgets/room_tools_sheet.dart';
import 'widgets/room_games_sheet.dart';
import 'widgets/room_gifts_sheet.dart';

class RoomScreen extends StatelessWidget {
  const RoomScreen({super.key, this.roomName = 'محرم', this.roomId = '479929'});
  final String roomName;
  final String roomId;

  void _sheet(BuildContext context, Widget child) => showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => child,
      );

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: const Color(0xFF1A0A3A),
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF1A0A3A), Color(0xFF4A1A8A)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: SafeArea(
            child: Column(children: [
              _header(context),
              Expanded(child: _stage()),
              _chat(),
              _bottomBar(context),
            ]),
          ),
        ),
      );

  Widget _header(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(10, 8, 10, 4),
        child: Row(children: [
          IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close, color: Colors.white)),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(roomName, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900)),
            Text('Room: $roomId  •  🟢 28 online', style: const TextStyle(color: Colors.white70, fontSize: 11)),
          ])),
          const Icon(Icons.monetization_on, color: AsmarTheme.gold),
          const SizedBox(width: 4),
          const Text('28000', style: TextStyle(color: AsmarTheme.gold, fontWeight: FontWeight.bold)),
          IconButton(onPressed: () => showModalBottomSheet(context: context, builder: (_) => const RoomInfoSheet()), icon: const Icon(Icons.info_outline, color: Colors.white)),
          IconButton(onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RoomSettingsScreen())), icon: const Icon(Icons.settings_outlined, color: Colors.white)),
          IconButton(onPressed: () => _share(context), icon: const Icon(Icons.share_outlined, color: Colors.white)),
        ]),
      );

  void _share(BuildContext context) => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم تجهيز رابط مشاركة الغرفة')));

  Widget _stage() => Stack(children: [
        Positioned(top: 8, left: 25, child: _light()),
        Positioned(top: 8, right: 25, child: _light()),
        GridView.builder(
          padding: const EdgeInsets.fromLTRB(14, 38, 14, 8),
          physics: const BouncingScrollPhysics(),
          itemCount: 15,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3, mainAxisSpacing: 14, crossAxisSpacing: 10, childAspectRatio: .82),
          itemBuilder: (_, i) => _seat(i + 1),
        ),
      ]);

  Widget _light() => Container(width: 90, height: 90, decoration: BoxDecoration(shape: BoxShape.circle, color: const Color(0x2247D7FF), boxShadow: [BoxShadow(color: Colors.purpleAccent.withOpacity(.35), blurRadius: 28, spreadRadius: 8)]));

  Widget _seat(int no) => Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Stack(alignment: Alignment.bottomRight, children: [
          Container(width: 64, height: 64, decoration: BoxDecoration(shape: BoxShape.circle, color: const Color(0xFF28124F), border: Border.all(color: const Color(0xFFB06BFF), width: 2), boxShadow: const [BoxShadow(color: Color(0x552B00FF), blurRadius: 10)]), child: const Icon(Icons.mic_none, color: Colors.white70, size: 30)),
          Container(padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2), decoration: BoxDecoration(color: const Color(0xFF0E071B), borderRadius: BorderRadius.circular(8)), child: Text('NO.$no', style: const TextStyle(color: AsmarTheme.gold, fontSize: 8, fontWeight: FontWeight.bold))),
        ]),
        const SizedBox(height: 5),
        const Text('فارغ', style: TextStyle(color: Colors.white54, fontSize: 10)),
      ]);

  Widget _chat() => Container(margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 5), padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: Colors.black26, borderRadius: BorderRadius.circular(14)), child: const Row(children: [Icon(Icons.campaign_outlined, color: AsmarTheme.gold, size: 18), SizedBox(width: 7), Expanded(child: Text('مرحبا بالجميع في الغرفة، نتمنى لكم وقتاً ممتعاً ❤️', style: TextStyle(color: Colors.white70, fontSize: 12)))]));

  Widget _bottomBar(BuildContext context) => Container(padding: const EdgeInsets.fromLTRB(12, 8, 12, 10), decoration: const BoxDecoration(color: Color(0xDD120822)), child: Row(children: [
    _action(context, Icons.card_giftcard, 'هدايا', () => _sheet(context, const RoomGiftsSheet())),
    _action(context, Icons.rocket_launch, 'ألعاب', () => _sheet(context, const RoomGamesSheet())),
    _action(context, Icons.inventory_2_outlined, 'صندوق', () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('صندوق الحظ جاهز')))),
    _action(context, Icons.build_circle_outlined, 'أدوات', () => _sheet(context, const RoomToolsSheet())),
  ]));

  Widget _action(BuildContext context, IconData icon, String label, VoidCallback onTap) => Expanded(child: InkWell(onTap: onTap, borderRadius: BorderRadius.circular(14), child: Padding(padding: const EdgeInsets.symmetric(vertical: 4), child: Column(children: [Icon(icon, color: AsmarTheme.gold, size: 25), const SizedBox(height: 3), Text(label, style: const TextStyle(color: Colors.white70, fontSize: 10))]))));
}
