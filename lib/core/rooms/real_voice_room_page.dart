import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../gifts.dart';
import '../../games_page.dart';

import '../voice/livekit_room_service.dart';
import 'room_repository.dart';
import 'room_social_repository.dart';

class RealVoiceRoomPage extends StatefulWidget {
  const RealVoiceRoomPage({super.key, required this.room});

  final VoiceRoomRecord room;

  @override
  State<RealVoiceRoomPage> createState() => _RealVoiceRoomPageState();
}

class _RealVoiceRoomPageState extends State<RealVoiceRoomPage> {
  final _roomRepository = RoomRepository();
  final _socialRepository = RoomSocialRepository();
  final _voice = LiveKitRoomService();
  final _messageController = TextEditingController();
  bool _joining = true;
  bool _muted = true;
  int? _mySeat;
  bool _canManage = false;
  bool _micRequested = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadRoomPermissions();
    _connect();
  }

  String _friendlyError(Object error) {
    final text = error.toString().toLowerCase();
    if (text.contains('not in room') || text.contains('room_members')) return 'تعذر الانضمام للغرفة. حاول الدخول مرة أخرى.';
    if (text.contains('seat_number_check') || text.contains('room_seats')) return 'تعذر تجهيز مقاعد الغرفة. حاول مرة أخرى.';
    if (text.contains('permission denied') || text.contains('42501')) return 'لا توجد صلاحية كافية لهذه العملية.';
    return 'تعذر الاتصال بالغرفة. حاول مرة أخرى.';
  }

  Future<void> _loadRoomPermissions() async {
    try {
      final value = await Supabase.instance.client.rpc('can_manage_room', params: {'p_room_id': widget.room.id});
      if (mounted) setState(() => _canManage = value == true);
    } catch (_) {}
  }

  Future<void> _connect() async {
    try {
      await _roomRepository.joinRoom(widget.room.id);
      final liveKitRoom = widget.room.liveKitRoomName;
      if (liveKitRoom == null || liveKitRoom.isEmpty) {
        throw StateError('LiveKit room name is missing.');
      }
      await _voice.join(roomName: liveKitRoom);
      await _voice.setMicrophoneEnabled(false);
      final uid = Supabase.instance.client.auth.currentUser?.id;
      if (uid != null) {
        final own = await Supabase.instance.client.from('room_seats').select('seat_index').eq('room_id', widget.room.id).eq('occupant_id', uid).maybeSingle();
        if (mounted && own != null) setState(() => _mySeat = ((own['seat_index'] as num).toInt() - 1));
      }
    } catch (e) {
      if (mounted) setState(() => _error = _friendlyError(e));
    } finally {
      if (mounted) setState(() => _joining = false);
    }
  }

  Future<void> _claimSeat(int seatIndex) async {
    if (_mySeat != null) return;
    try {
      await _socialRepository.claimSeat(widget.room.id, seatIndex + 1);
      if (mounted) setState(() => _mySeat = seatIndex);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    }
  }

  Future<void> _toggleMute() async {
    if (_mySeat == null) return;
    final nextMuted = !_muted;
    try {
      await _voice.setMicrophoneEnabled(!nextMuted);
      await _socialRepository.setMuted(widget.room.id, nextMuted);
      if (mounted) setState(() => _muted = nextMuted);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    }
  }

  Future<void> _leave() async {
    try {
      if (_mySeat != null) {
        await _socialRepository.leaveSeat(widget.room.id, _mySeat! + 1);
      }
      await _roomRepository.leaveRoom(widget.room.id);
      await _voice.disconnect();
    } finally {
      if (mounted) Navigator.of(context).pop();
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    _voice.disconnect();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const bg = Color(0xFF0A0A0A);
    const panel2 = Color(0xFF1A1A1A);
    const purple = Color(0xFFD4AF37);
    const pink = Color(0xFFD4AF37);
    const cyan = Color(0xFFD4AF37);
    const muted = Color(0xFF888888);

    return Scaffold(
      backgroundColor: bg,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF1A1A1A), bg, bg],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
                child: Row(
                  children: [
                    IconButton(onPressed: _leave, icon: const Icon(Icons.close_rounded)),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(widget.room.name, maxLines: 1, overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
                          Text(_joining ? 'جاري الاتصال...' : 'غرفة مباشرة',
                              style: const TextStyle(color: muted, fontSize: 11)),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => RoomGamesPage(room: widget.room))),
                      icon: const Icon(Icons.sports_esports_rounded, color: const Color(0xFFD4AF37)),
                    ),
                    IconButton(
                      onPressed: () => _openTreasureSheet(context),
                      icon: const Icon(Icons.card_giftcard_rounded, color: const Color(0xFFD4AF37)),
                    ),
                    IconButton(
                      onPressed: () => _openPeopleSheet(context),
                      icon: const Icon(Icons.people_alt_rounded, color: cyan),
                    ),
                    if (_canManage)
                      IconButton(
                        onPressed: () => _openManagementSheet(context),
                        icon: const Icon(Icons.settings_rounded, color: cyan),
                      ),
                    IconButton(
                      onPressed: () => _shareRoom(context),
                      icon: const Icon(Icons.share_rounded),
                    ),
                    IconButton(
                      onPressed: () => _openRoomInfoSheet(context),
                      icon: const Icon(Icons.info_outline_rounded),
                    ),
                  ],
                ),
              ),
              if (_joining) const LinearProgressIndicator(minHeight: 2),
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                  child: Text(_error!, maxLines: 2, overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: Colors.redAccent, fontSize: 11)),
                ),
              Expanded(
                child: StreamBuilder<List<Map<String, dynamic>>>(
                  stream: _socialRepository.watchSeats(widget.room.id),
                  builder: (context, snapshot) {
                    final seats = snapshot.data ?? const <Map<String, dynamic>>[];
                    final byIndex = <int, Map<String, dynamic>>{
                      for (final seat in seats)
                        if (seat['seat_index'] is num)
                          (seat['seat_index'] as num).toInt() - 1: seat,
                    };
                    final occupiedCount = seats.where((x) => x['occupant_id'] != null).length;
                    return Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 2, 16, 7),
                          child: Row(
                            children: [
                              const Icon(Icons.mic_rounded, size: 17, color: cyan),
                              const SizedBox(width: 5),
                              Text(occupiedCount.toString() + '/' + widget.room.seatCount.toString(),
                                  style: const TextStyle(color: Colors.white70)),
                              const Spacer(),
                              FilledButton.icon(
                                onPressed: () => _openGiftSheet(context),
                                icon: const Icon(Icons.card_giftcard_rounded, size: 18),
                                label: const Text('هدايا'),
                                style: FilledButton.styleFrom(backgroundColor: purple),
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          child: GridView.builder(
                            padding: const EdgeInsets.fromLTRB(14, 8, 14, 8),
                            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 4, crossAxisSpacing: 10, mainAxisSpacing: 16, childAspectRatio: .82,
                            ),
                            itemCount: widget.room.seatCount,
                            itemBuilder: (_, index) {
                              final seat = byIndex[index];
                              final occupied = seat?['occupant_id'] != null;
                              final mine = _mySeat == index;
                              return InkWell(
                                onTap: occupied ? null : () => _claimSeat(index),
                                borderRadius: BorderRadius.circular(18),
                                child: Column(
                                  children: [
                                    Container(
                                      width: 62, height: 62,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        gradient: occupied || mine
                                            ? const LinearGradient(colors: [pink, purple])
                                            : const LinearGradient(colors: [panel2, Color(0xFF0D1027)]),
                                        border: Border.all(
                                          color: mine ? cyan : Colors.white.withOpacity(.08),
                                          width: mine ? 2 : 1,
                                        ),
                                      ),
                                      child: Icon(
                                        occupied ? Icons.person_rounded : Icons.add_rounded,
                                        color: occupied || mine ? Colors.white : muted,
                                        size: 28,
                                      ),
                                    ),
                                    const SizedBox(height: 5),
                                    Text(
                                      occupied ? (mine ? 'أنت' : 'مستخدم ' + (index + 1).toString()) : (index + 1).toString(),
                                      style: TextStyle(color: mine ? cyan : Colors.white70, fontSize: 10, fontWeight: FontWeight.w700),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
                        StreamBuilder<List<Map<String, dynamic>>>(
                          stream: _socialRepository.watchMessages(widget.room.id),
                          builder: (context, msgSnapshot) {
                            final messages = msgSnapshot.data ?? const <Map<String, dynamic>>[];
                            return Container(
                              height: 92,
                              margin: const EdgeInsets.fromLTRB(14, 0, 14, 8),
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(.18),
                                borderRadius: BorderRadius.circular(18),
                              ),
                              child: messages.isEmpty
                                  ? const Align(
                                      alignment: Alignment.centerRight,
                                      child: Text('ابدأ المحادثة داخل الغرفة 👋', style: TextStyle(color: muted)),
                                    )
                                  : ListView.builder(
                                      reverse: true,
                                      itemCount: messages.length > 8 ? 8 : messages.length,
                                      itemBuilder: (_, i) {
                                        final row = messages[messages.length - 1 - i];
                                        return Text(
                                          '• ' + (row['message']?.toString() ?? ''),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(color: Colors.white70, fontSize: 12),
                                        );
                                      },
                                    ),
                            );
                          },
                        ),
                      ],
                    );
                  },
                ),
              ),
              SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(10, 2, 10, 8),
                  child: Row(
                    children: [
                      IconButton.filledTonal(
                        onPressed: _mySeat == null ? (_micRequested ? null : () => _requestMic(context)) : _toggleMute,
                        icon: Icon(_mySeat == null ? (_micRequested ? Icons.hourglass_top_rounded : Icons.back_hand_rounded) : (_muted ? Icons.mic_off_rounded : Icons.mic_rounded)),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: widget.room.chatEnabled
                            ? TextField(
                                controller: _messageController,
                                decoration: InputDecoration(
                                  hintText: 'اكتب رسالة...',
                                  filled: true,
                                  fillColor: panel2,
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(22), borderSide: BorderSide.none),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 14),
                                ),
                                onSubmitted: (_) => _sendRoomMessage(),
                              )
                            : const Center(child: Text('الدردشة متوقفة', style: TextStyle(color: muted))),
                      ),
                      IconButton(onPressed: () => _openGiftSheet(context), icon: const Icon(Icons.card_giftcard_rounded, color: pink)),
                      IconButton(onPressed: () => _inviteUser(context), icon: const Icon(Icons.person_add_alt_1_rounded)),
                      IconButton(onPressed: _leave, icon: const Icon(Icons.logout_rounded)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _openTreasureSheet(BuildContext context) async {
    final db = Supabase.instance.client;
    final rows = await db.rpc('asmar_list_room_treasure_boxes', params: {'p_room_id': widget.room.id});
    if (!mounted) return;
    final boxes = List<Map<String, dynamic>>.from(rows as List);
    final isOwner = db.auth.currentUser?.id == widget.room.ownerId;
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: const Color(0xFF0A0A0A),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (_) => Directionality(
        textDirection: TextDirection.rtl,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 16, 14, 22),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Row(children: [
                const Icon(Icons.card_giftcard_rounded, color: Color(0xFFFFC94A)),
                const SizedBox(width: 8),
                const Expanded(child: Text('صناديق الكنز', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900))),
                if (isOwner) IconButton(onPressed: () { Navigator.pop(context); _createTreasureBox(context); }, icon: const Icon(Icons.add_circle, color: Color(0xFFFFC94A))),
              ]),
              const SizedBox(height: 8),
              if (boxes.isEmpty)
                const Padding(padding: EdgeInsets.all(24), child: Text('لا يوجد صندوق نشط حالياً', style: TextStyle(color: Color(0xFF9CA2C5))))
              else
                ...boxes.map((box) => Card(
                  color: const Color(0xFF1A1A1A),
                  child: ListTile(
                    leading: const CircleAvatar(backgroundColor: Color(0xFFFFC94A), child: Icon(Icons.redeem, color: Colors.black)),
                    title: Text('متبقي ${box['remaining_coins']} Coins', style: const TextStyle(fontWeight: FontWeight.w900)),
                    subtitle: Text('عدد الجوائز المتبقية: ${box['remaining_claims']}', style: const TextStyle(color: Color(0xFF9CA2C5))),
                    trailing: FilledButton(
                      onPressed: () async {
                        try {
                          final amount = await db.rpc('asmar_claim_room_treasure_box', params: {'p_box_id': box['id']});
                          if (!context.mounted) return;
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('مبروك! حصلت على $amount Coins 🎁')));
                        } catch (e) {
                          if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('تعذر فتح الصندوق: $e')));
                        }
                      },
                      child: const Text('افتح'),
                    ),
                  ),
                )),
            ]),
          ),
        ),
      ),
    );
  }

  Future<void> _createTreasureBox(BuildContext context) async {
    final coins = TextEditingController(text: '1000');
    final claims = TextEditingController(text: '10');
    try {
      final ok = await showDialog<bool>(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('إنشاء صندوق كنز'),
          content: Column(mainAxisSize: MainAxisSize.min, children: [
            TextField(controller: coins, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'إجمالي Coins')),
            TextField(controller: claims, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'عدد الفائزين')),
          ]),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('إلغاء')),
            FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('إنشاء')),
          ],
        ),
      );
      if (ok != true) return;
      final total = int.tryParse(coins.text.trim());
      final count = int.tryParse(claims.text.trim());
      if (total == null || count == null) return;
      try {
        await Supabase.instance.client.rpc('asmar_create_room_treasure_box', params: {'p_room_id': widget.room.id, 'p_total_coins': total, 'p_claims': count, 'p_minutes': 30});
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم إنشاء صندوق الكنز 🎁')));
      } catch (e) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('تعذر إنشاء الصندوق: $e')));
      }
    } finally {
      coins.dispose();
      claims.dispose();
    }
  }
  Future<void> _sendRoomMessage() async {
    final value = _messageController.text.trim();
    if (value.isEmpty) return;
    try {
      await _socialRepository.sendMessage(widget.room.id, value);
      _messageController.clear();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    }
  }

  Future<void> _requestMic(BuildContext context) async {
    try {
      await _roomRepository.requestMic(widget.room.id);
      if (mounted) setState(() => _micRequested = true);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم إرسال طلب المايك إلى إدارة الغرفة')));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('تعذر طلب المايك: $e')));
    }
  }

  Future<void> _inviteUser(BuildContext context) async {
    final controller = TextEditingController();
    final id = await showDialog<String>(
      context: context,
      builder: (d) => AlertDialog(
        title: const Text('دعوة مستخدم'),
        content: TextField(controller: controller, decoration: const InputDecoration(labelText: 'معرّف المستخدم UUID')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(d), child: const Text('إلغاء')),
          FilledButton(onPressed: () => Navigator.pop(d, controller.text.trim()), child: const Text('دعوة')),
        ],
      ),
    );
    controller.dispose();
    if (id == null || id.isEmpty) return;
    try {
      await _roomRepository.inviteUser(widget.room.id, id);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم إرسال الدعوة')));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('تعذر إرسال الدعوة: $e')));
    }
  }

  Future<void> _shareRoom(BuildContext context) async {
    final text = 'انضم إلى غرفة ${widget.room.name} — ID: ${widget.room.id}';
    await showDialog<void>(context: context, builder: (d) => AlertDialog(title: const Text('مشاركة الغرفة'), content: SelectableText(text), actions: [TextButton(onPressed: () => Navigator.pop(d), child: const Text('إغلاق'))]));
  }

  Future<void> _openManagementSheet(BuildContext context) async {
    final db = Supabase.instance.client;
    final requests = await db.from('room_mic_requests').select('id,user_id,created_at').eq('room_id', widget.room.id).eq('status','pending').order('created_at');
    if (!mounted) return;
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: const Color(0xFF120B08),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (sheet) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.all(16),
          children: [
            const Text('إدارة الغرفة', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
            ListTile(leading: const Icon(Icons.volume_off_rounded), title: const Text('كتم جميع المتحدثين'), onTap: () async { await _roomRepository.muteAll(widget.room.id); if (sheet.mounted) Navigator.pop(sheet); }),
            SwitchListTile(value: widget.room.chatEnabled, onChanged: (v) async { await _roomRepository.setChatEnabled(widget.room.id, v); if (sheet.mounted) Navigator.pop(sheet); }, title: const Text('الدردشة')),
            SwitchListTile(value: widget.room.isPrivate, onChanged: (v) async { await _roomRepository.setPrivate(widget.room.id, v); if (sheet.mounted) Navigator.pop(sheet); }, title: const Text('غرفة خاصة')),
            const Divider(),
            const Text('طلبات المايك', style: TextStyle(fontWeight: FontWeight.w900)),
            if ((requests as List).isEmpty) const Padding(padding: EdgeInsets.all(16), child: Text('لا توجد طلبات معلقة')),
            ...List<Map<String,dynamic>>.from(requests).map((r) => ListTile(
              leading: const Icon(Icons.back_hand_rounded),
              title: Text(r['user_id'].toString(), maxLines: 1, overflow: TextOverflow.ellipsis),
              trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                IconButton(onPressed: () async { await db.rpc('resolve_room_mic_request', params: {'p_request_id': r['id'], 'p_approve': true}); if (sheet.mounted) Navigator.pop(sheet); }, icon: const Icon(Icons.check_circle, color: Colors.greenAccent)),
                IconButton(onPressed: () async { await db.rpc('resolve_room_mic_request', params: {'p_request_id': r['id'], 'p_approve': false}); if (sheet.mounted) Navigator.pop(sheet); }, icon: const Icon(Icons.cancel, color: Colors.redAccent)),
              ]),
            )),
          ],
        ),
      ),
    );
  }

  void _openGiftSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => GiftSheet(roomId: widget.room.id),
    );
  }

  void _openPeopleSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: const Color(0xFF120B08),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (_) => StreamBuilder<List<Map<String, dynamic>>>(
        stream: _socialRepository.watchSeats(widget.room.id),
        builder: (context, snapshot) {
          final seats = (snapshot.data ?? const <Map<String, dynamic>>[]).where((x) => x['occupant_id'] != null).toList();
          return SafeArea(
            child: SizedBox(
              height: MediaQuery.of(context).size.height * .58,
              child: Column(
                children: [
                  const Padding(
                    padding: EdgeInsets.all(18),
                    child: Text('الأشخاص في الغرفة', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
                  ),
                  Expanded(
                    child: seats.isEmpty
                        ? const Center(child: Text('لا يوجد أحد على المقاعد حالياً', style: TextStyle(color: Color(0xFF9CA2C5))))
                        : ListView.separated(
                            padding: const EdgeInsets.all(14),
                            itemCount: seats.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 8),
                            itemBuilder: (_, i) => ListTile(
                              tileColor: const Color(0xFF171A3A),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              leading: const CircleAvatar(backgroundColor: Color(0xFF8B4DFF), child: Icon(Icons.person_rounded)),
                              title: Text('مستخدم ' + (i + 1).toString(), style: const TextStyle(fontWeight: FontWeight.w800)),
                              subtitle: Text('المقعد ' + (seats[i]['seat_index'] ?? i + 1).toString(),
                                  style: const TextStyle(color: Color(0xFF9CA2C5))),
                              trailing: const Icon(Icons.mic_none_rounded, color: Color(0xFF4EDCFF)),
                            ),
                          ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _openRoomInfoSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: const Color(0xFF120B08),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.info_outline_rounded, color: Color(0xFF4EDCFF), size: 32),
              const SizedBox(height: 8),
              Text(widget.room.name, style: const TextStyle(fontSize: 21, fontWeight: FontWeight.w900)),
              const SizedBox(height: 8),
              Text('ID: ' + widget.room.id, maxLines: 1, overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Color(0xFF9CA2C5))),
              const SizedBox(height: 12),
              Text('المقاعد: ' + widget.room.seatCount.toString(), style: const TextStyle(color: Colors.white70)),
            ],
          ),
        ),
      ),
    );
  }
}
