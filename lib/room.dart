import 'dart:async';
import 'dart:math' as math;
import 'package:image_picker/image_picker.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:livekit_client/livekit_client.dart' as lk;
import 'country_flag.dart';
import 'rank_frame.dart';
import 'gifts.dart';
import 'profile_badges.dart';
import 'asmar_keyboard.dart';

const gold = Color(0xFFFFD36A);
const gold2 = Color(0xFFB77921);
const bg = Color(0xFF090604);
const card = Color(0xFF1B0E08);

const allowedSeatCounts = <int>[4, 6, 8, 10, 12, 15, 20, 25, 30];

class Room extends StatefulWidget {
  final String name;
  final String roomId;
  const Room({super.key, required this.name, required this.roomId});
  @override State<Room> createState() => _RoomState();
}

class _RoomState extends State<Room> {
  final controller = TextEditingController();
  final messages = <Map<String, dynamic>>[];
  final profiles = <String, Map<String, dynamic>>{};
  final seats = <Map<String, dynamic>>[];
  StreamSubscription<List<Map<String, dynamic>>>? messageSub;
  StreamSubscription<List<Map<String, dynamic>>>? giftSub;
  StreamSubscription<List<Map<String, dynamic>>>? seatSub;
  final seenGifts = <String>{};
  lk.Room? voiceRoom;
  bool microphoneOn = false;
  bool joiningVoice = false;
  Map<String, dynamic>? giftOverlay;
  Map<String, dynamic>? roomInfo;
  final picker = ImagePicker();
  bool changingBackground = false;
  bool loadingSeats = false;
  bool managingSeat = false;
  bool canManageRoom = false;
  bool keyboardOpen = false;

  @override
  void initState() {
    super.initState();
    _loadRoomInfo();
    _loadMessages();
    _loadSeats();
    messageSub = Supabase.instance.client
        .from('room_messages')
        .stream(primaryKey: ['id'])
        .eq('room_id', widget.roomId)
        .order('created_at')
        .listen((rows) {
          if (!mounted) return;
          setState(() {
            messages
              ..clear()
              ..addAll(rows.length > 100 ? rows.sublist(rows.length - 100) : rows);
          });
        });
    giftSub = Supabase.instance.client
        .from('gift_transactions')
        .stream(primaryKey: ['id'])
        .eq('room_id', widget.roomId)
        .order('created_at')
        .listen(_handleGifts);
    seatSub = Supabase.instance.client
        .from('room_seats')
        .stream(primaryKey: ['id'])
        .eq('room_id', widget.roomId)
        .order('seat_index')
        .listen((rows) {
          if (!mounted) return;
          _applySeats(rows);
        });
  }

  Future<void> _loadRoomInfo() async {
    try {
      final row = await Supabase.instance.client
          .from('rooms')
          .select('id,name,owner_id,seat_count,room_background_url,room_background_expires_at,seats_background_url,seats_background_expires_at')
          .eq('id', widget.roomId)
          .maybeSingle();
      if (row != null && mounted) {
        setState(() => roomInfo = Map<String, dynamic>.from(row));
        try {
          final result = await Supabase.instance.client.rpc(
            'can_manage_room',
            params: {'p_room_id': widget.roomId},
          );
          if (mounted) setState(() => canManageRoom = result == true);
        } catch (_) {
          final uid = Supabase.instance.client.auth.currentUser?.id;
          if (mounted) setState(() => canManageRoom = uid != null && row['owner_id']?.toString() == uid);
        }
      }
    } catch (_) {}
  }

  bool _active(String? expires) {
    if (expires == null || expires.isEmpty) return false;
    return DateTime.tryParse(expires)?.isAfter(DateTime.now()) ?? false;
  }

  Future<void> _loadSeats() async {
    if (loadingSeats) return;
    setState(() => loadingSeats = true);
    try {
      await Supabase.instance.client.rpc(
        'ensure_room_seats',
        params: {'p_room_id': widget.roomId},
      );
      final rows = await Supabase.instance.client
          .from('room_seats')
          .select('id,room_id,seat_index,occupant_id,is_locked,updated_at')
          .eq('room_id', widget.roomId)
          .order('seat_index');
      await _applySeats(List<Map<String, dynamic>>.from(rows));
    } catch (_) {
    } finally {
      if (mounted) setState(() => loadingSeats = false);
    }
  }

  Future<void> _applySeats(List<Map<String, dynamic>> rows) async {
    final list = rows.map((r) => Map<String, dynamic>.from(r)).toList()
      ..sort((a, b) => (a['seat_index'] as int).compareTo(b['seat_index'] as int));
    final ids = list
        .map((s) => s['occupant_id']?.toString())
        .whereType<String>()
        .where((id) => id.isNotEmpty)
        .toSet()
        .toList();
    if (ids.isNotEmpty) {
      try {
        final ps = await Supabase.instance.client
            .from('profiles')
            .select('id,username,role,country_code,vip_level,avatar_url,avatar_is_animated,activity_admin_badge,customer_service_badge,is_verified')
            .inFilter('id', ids);
        profiles.addEntries(
          List<Map<String, dynamic>>.from(ps)
              .map((p) => MapEntry(p['id'].toString(), p)),
        );
      } catch (_) {}
    }
    if (mounted) setState(() { seats..clear()..addAll(list); });
  }

  Future<void> _changeBackground(String type) async {
    if (changingBackground || !canManageRoom) return;
    final choice = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: card,
      builder: (_) => SafeArea(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          ListTile(
            leading: const Icon(Icons.calendar_view_week, color: gold),
            title: const Text('أسبوع • 10,000 كوين'),
            onTap: () => Navigator.pop(context, '7'),
          ),
          ListTile(
            leading: const Icon(Icons.calendar_month, color: gold),
            title: const Text('شهر • 35,000 كوين'),
            onTap: () => Navigator.pop(context, '30'),
          ),
        ]),
      ),
    );
    if (choice == null || !mounted) return;
    final image = await picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (image == null || !mounted) return;

    setState(() => changingBackground = true);
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) throw Exception('not authenticated');
      final ext = image.name.split('.').last.toLowerCase();
      final path = '${user.id}/${widget.roomId}/${type}_${DateTime.now().millisecondsSinceEpoch}.$ext';
      final bytes = await image.readAsBytes();
      await Supabase.instance.client.storage.from('room-backgrounds').uploadBinary(
        path,
        bytes,
        fileOptions: const FileOptions(upsert: false),
      );
      final url = Supabase.instance.client.storage.from('room-backgrounds').getPublicUrl(path);
      await Supabase.instance.client.rpc('purchase_room_background', params: {
        'p_room_id': widget.roomId,
        'p_background_type': type,
        'p_background_url': url,
        'p_duration_days': int.parse(choice),
      });
      await _loadRoomInfo();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(type == 'room' ? 'تم تغيير خلفية الروم' : 'تم تغيير خلفية المقاعد')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('تعذر تغيير الخلفية: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => changingBackground = false);
    }
  }

  Future<void> _loadMessages() async {
    try {
      final rows = await Supabase.instance.client
          .from('room_messages')
          .select('id,user_id,message,created_at')
          .eq('room_id', widget.roomId)
          .order('created_at', ascending: false)
          .limit(100);
      final list = List<Map<String, dynamic>>.from(rows).reversed.toList();
      final ids = list.map((m) => m['user_id'].toString()).toSet().toList();
      if (ids.isNotEmpty) {
        final ps = await Supabase.instance.client
            .from('profiles')
            .select('id,username,role,country_code,vip_level,avatar_url,avatar_is_animated,activity_admin_badge,customer_service_badge,is_verified')
            .inFilter('id', ids);
        profiles.addEntries(List<Map<String, dynamic>>.from(ps).map((p) => MapEntry(p['id'].toString(), p)));
      }
      if (mounted) setState(() { messages..clear()..addAll(list); });
    } catch (_) {}
  }

  Future<void> _handleGifts(List<Map<String, dynamic>> rows) async {
    for (final row in rows) {
      final id = row['id']?.toString();
      if (id == null || seenGifts.contains(id)) continue;
      seenGifts.add(id);
      try {
        final gift = await Supabase.instance.client
            .from('gifts')
            .select('name,emoji')
            .eq('id', row['gift_id'])
            .maybeSingle();
        if (gift == null || !mounted) continue;
        setState(() => giftOverlay = {
          'emoji': gift['emoji'],
          'name': gift['name'],
          'amount': row['amount'],
        });
        Future.delayed(const Duration(seconds: 3), () {
          if (mounted) setState(() => giftOverlay = null);
        });
      } catch (_) {}
    }
  }

  Future<void> _joinSeat(int index) async {
    final uid = Supabase.instance.client.auth.currentUser?.id;
    if (uid == null) return;
    if (managingSeat) return;
    setState(() => managingSeat = true);
    try {
      await Supabase.instance.client.rpc('join_room_seat', params: {
        'p_room_id': widget.roomId,
        'p_seat_index': index,
      });
      await _loadSeats();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_seatError(e))),
        );
      }
    } finally {
      if (mounted) setState(() => managingSeat = false);
    }
  }

  Future<void> _leaveSeat(int index) async {
    if (managingSeat) return;
    setState(() => managingSeat = true);
    try {
      await Supabase.instance.client.rpc('leave_room_seat', params: {
        'p_room_id': widget.roomId,
        'p_seat_index': index,
      });
      await _loadSeats();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(_seatError(e))));
    } finally {
      if (mounted) setState(() => managingSeat = false);
    }
  }

  String _seatError(Object e) {
    final s = e.toString();
    if (s.contains('SEAT_LOCKED')) return 'هذا المقعد مقفول';
    if (s.contains('SEAT_OCCUPIED')) return 'المقعد مشغول';
    if (s.contains('NOT_YOUR_SEAT')) return 'هذا ليس مقعدك';
    if (s.contains('FORBIDDEN')) return 'ليس لديك صلاحية';
    return 'تعذر تنفيذ العملية';
  }

  Future<void> _seatManager(int index, Map<String, dynamic> seat) async {
    if (!canManageRoom || managingSeat) return;
    final locked = seat['is_locked'] == true;
    final occupant = seat['occupant_id']?.toString();
    final action = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: card,
      builder: (_) => SafeArea(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          ListTile(
            leading: Icon(locked ? Icons.lock_open : Icons.lock, color: gold),
            title: Text(locked ? 'فتح المقعد' : 'قفل المقعد'),
            onTap: () => Navigator.pop(context, 'lock'),
          ),
          if (occupant != null)
            ListTile(
              leading: const Icon(Icons.person_remove, color: Colors.redAccent),
              title: const Text('إنزال المستخدم من المقعد'),
              onTap: () => Navigator.pop(context, 'remove'),
            ),
        ]),
      ),
    );
    if (action == null) return;
    setState(() => managingSeat = true);
    try {
      if (action == 'lock') {
        await Supabase.instance.client.rpc('set_room_seat_locked', params: {
          'p_room_id': widget.roomId,
          'p_seat_index': index,
          'p_locked': !locked,
        });
      } else {
        await Supabase.instance.client.rpc('remove_room_seat', params: {
          'p_room_id': widget.roomId,
          'p_seat_index': index,
        });
      }
      await _loadSeats();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(_seatError(e))));
    } finally {
      if (mounted) setState(() => managingSeat = false);
    }
  }

  Future<void> _changeSeatCount() async {
    if (!canManageRoom) return;
    final current = (roomInfo?['seat_count'] as num?)?.toInt() ?? 8;
    final selected = await showModalBottomSheet<int>(
      context: context,
      backgroundColor: card,
      builder: (_) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: allowedSeatCounts.map((n) => ListTile(
            leading: Icon(n == current ? Icons.radio_button_checked : Icons.radio_button_off, color: gold),
            title: Text('$n مقاعد', style: const TextStyle(color: Colors.white)),
            onTap: () => Navigator.pop(context, n),
          )).toList(),
        ),
      ),
    );
    if (selected == null || selected == current) return;
    setState(() => managingSeat = true);
    try {
      await Supabase.instance.client.rpc('set_room_seat_count', params: {
        'p_room_id': widget.roomId,
        'p_seat_count': selected,
      });
      await _loadRoomInfo();
      await _loadSeats();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(_seatError(e))));
    } finally {
      if (mounted) setState(() => managingSeat = false);
    }
  }

  Widget _seatGrid() {
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
          for(int i=0;i<visible;i++)Positioned(left:cx-37+r*math.cos(i*2*3.1415926535/visible-1.5707963268),top:cy-37+r*math.sin(i*2*3.1415926535/visible-1.5707963268),child:SizedBox(width:74,height:74,child:_seatTile(i+1,byIndex[i+1]??{'seat_index':i+1,'is_locked':false})))
        ]);}))
      ]),
    );
  }

  Widget _seatTile(int index, Map<String, dynamic> seat) {
    final locked = seat['is_locked'] == true;
    final occupantId = seat['occupant_id']?.toString();
    final uid = Supabase.instance.client.auth.currentUser?.id;
    final mine = occupantId != null && occupantId == uid;
    final profile = occupantId == null ? null : profiles[occupantId];
    return GestureDetector(
      onTap: () {
        if (canManageRoom && !mine) {
          _seatManager(index, seat);
        } else if (mine) {
          _leaveSeat(index);
        } else if (!locked) {
          _joinSeat(index);
        }
      },
      child: Container(
        decoration: BoxDecoration(
          color: locked ? const Color(0xFF241D19) : (mine ? const Color(0xFF5B350E) : card),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: locked ? Colors.white24 : (mine ? gold : const Color(0xFF4C3019))),
        ),
        child: Stack(children: [
          Center(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              if (profile != null)
                CircleAvatar(
                  radius: 17,
                  backgroundColor: const Color(0xFF422511),
                  backgroundImage: (profile['avatar_url']?.toString() ?? '').isNotEmpty
                      ? NetworkImage(profile['avatar_url'].toString())
                      : null,
                  child: (profile['avatar_url']?.toString() ?? '').isEmpty
                      ? const Icon(Icons.person, color: gold, size: 18)
                      : null,
                )
              else
                Icon(locked ? Icons.lock : Icons.event_seat, color: locked ? Colors.white38 : gold, size: 25),
              const SizedBox(height: 4),
              Text(
                profile?['username']?.toString() ?? 'مقعد $index',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: mine ? gold : Colors.white70, fontSize: 10, fontWeight: FontWeight.w700),
              ),
            ]),
          ),
          if (locked)
            const Positioned(top: 5, right: 5, child: Icon(Icons.lock, color: Colors.white38, size: 13)),
          if (mine)
            const Positioned(top: 5, left: 5, child: Icon(Icons.mic, color: gold, size: 13)),
        ]),
      ),
    );
  }

  @override
  void dispose() {
    messageSub?.cancel();
    giftSub?.cancel();
    seatSub?.cancel();
    voiceRoom?.disconnect();
    controller.dispose();
    super.dispose();
  }

  Future<void> _sendMessage() async {
    final text = controller.text.trim();
    final user = Supabase.instance.client.auth.currentUser;
    if (text.isEmpty || user == null) return;
    try {
      await Supabase.instance.client.from('room_messages').insert({
        'room_id': widget.roomId,
        'user_id': user.id,
        'message': text,
      });
      controller.clear();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('فشل إرسال الرسالة: $e')));
    }
  }

  Future<void> _joinVoice() async {
    if (joiningVoice || voiceRoom != null) return;
    setState(() => joiningVoice = true);
    try {
      final roomData = await Supabase.instance.client.from('rooms').select('livekit_room_name').eq('id', widget.roomId).single();
      final livekitName = (roomData['livekit_room_name'] ?? widget.roomId).toString();
      final response = await Supabase.instance.client.functions.invoke('livekit-token', body: {'room': livekitName});
      final data = Map<String, dynamic>.from(response.data as Map);
      final room = lk.Room();
      await room.connect(data['url'].toString(), data['token'].toString());
      await room.localParticipant?.setMicrophoneEnabled(true);
      if (!mounted) {
        await room.disconnect();
        return;
      }
      setState(() {
        voiceRoom = room;
        microphoneOn = true;
        joiningVoice = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() => joiningVoice = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('تعذر دخول الصوت: $e')));
      }
    }
  }

  Future<void> _toggleMicrophone() async {
    if (voiceRoom == null) {
      await _joinVoice();
      return;
    }
    try {
      await voiceRoom!.localParticipant?.setMicrophoneEnabled(!microphoneOn);
      if (mounted) setState(() => microphoneOn = !microphoneOn);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('تعذر تشغيل الميكروفون: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: bg,
        appBar: AppBar(
          backgroundColor: const Color(0xFF100805),
          foregroundColor: Colors.white,
          title: Text(widget.name, style: const TextStyle(color: gold, fontWeight: FontWeight.w900)),
          actions: [
            if (canManageRoom)
              PopupMenuButton<String>(
                onSelected: (v) {
                  if (v == 'room' || v == 'seats') _changeBackground(v);
                  if (v == 'count') _changeSeatCount();
                },
                itemBuilder: (_) => const [
                  PopupMenuItem(value: 'count', child: Text('عدد المقاعد')),
                  PopupMenuItem(value: 'room', child: Text('خلفية الروم • أسبوع/شهر')),
                  PopupMenuItem(value: 'seats', child: Text('خلفية المقاعد • أسبوع/شهر')),
                ],
                icon: const Icon(Icons.settings, color: gold),
              ),
          ],
        ),
        body: Stack(
          children: [
            if (_active(roomInfo?['room_background_expires_at']?.toString()) &&
                (roomInfo?['room_background_url']?.toString() ?? '').isNotEmpty)
              Positioned.fill(
                child: Image.network(
                  roomInfo!['room_background_url'].toString(),
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                ),
              ),
            Positioned.fill(child: Container(color: const Color(0xD9090604))),
            Column(
              children: [
                if (changingBackground)
                  const LinearProgressIndicator(minHeight: 2, color: gold),
                Container(
                  margin: const EdgeInsets.all(16),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    gradient: const LinearGradient(colors: [Color(0xFF6B2C0B), Color(0xFF160A06)]),
                    border: Border.all(color: gold2),
                  ),
                  child: const Row(children: [
                    CircleAvatar(radius: 25, backgroundColor: Color(0xFF422511), child: Icon(Icons.mic, color: gold)),
                    SizedBox(width: 12),
                    Expanded(child: Text('غرفة صوتية • دردشة • هدايا', style: TextStyle(color: gold, fontWeight: FontWeight.w900))),
                    Icon(Icons.people, color: Colors.white70),
                  ]),
                ),
                _seatGrid(),
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      image: _active(roomInfo?['seats_background_expires_at']?.toString()) &&
                              (roomInfo?['seats_background_url']?.toString() ?? '').isNotEmpty
                          ? DecorationImage(
                              image: NetworkImage(roomInfo!['seats_background_url'].toString()),
                              fit: BoxFit.cover,
                              opacity: 0.28,
                            )
                          : null,
                    ),
                    child: ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 6, 16, 16),
                      itemCount: messages.length,
                      itemBuilder: (context, index) {
                        final row = messages[index];
                        return _message(row['message']?.toString() ?? '', profiles[row['user_id']?.toString()]);
                      },
                    ),
                  ),
                ),
                SafeArea(
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(8, 6, 8, 8),
                    color: const Color(0xFF100805),
                    child: Row(children: [
                      IconButton(
                        onPressed: joiningVoice ? null : _toggleMicrophone,
                        icon: Icon(joiningVoice ? Icons.hourglass_top : (microphoneOn ? Icons.mic : Icons.mic_off), color: gold),
                      ),
                      IconButton(
                        onPressed: () => setState(() => keyboardOpen = !keyboardOpen),
                        icon: Icon(keyboardOpen ? Icons.keyboard_hide : Icons.keyboard, color: gold),
                      ),
                      Expanded(
                        child: TextField(
                          controller: controller,
                          onSubmitted: (_) => _sendMessage(),
                          style: const TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            hintText: 'اكتب رسالة...',
                            hintStyle: const TextStyle(color: Colors.white38),
                            filled: true,
                            fillColor: card,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(25), borderSide: BorderSide.none),
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      CircleAvatar(
                        backgroundColor: gold2,
                        child: IconButton(onPressed: _sendMessage, icon: const Icon(Icons.send, color: Colors.white, size: 20)),
                      ),
                    ]),
                  ),
                ),
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
            if (giftOverlay != null)
              Center(
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 45),
                  padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(
                    color: const Color(0xF0150905),
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(color: gold, width: 2),
                  ),
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    Text(giftOverlay!['emoji']?.toString() ?? '🎁', style: const TextStyle(fontSize: 72)),
                    Text('هدية ' + (giftOverlay!['name']?.toString() ?? ''), style: const TextStyle(color: gold, fontSize: 22, fontWeight: FontWeight.w900)),
                    Text((giftOverlay!['amount']?.toString() ?? '0') + ' 🪙', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ]),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _message(String text, Map<String, dynamic>? profile) {
    final avatar = profile?['avatar_url']?.toString() ?? '';
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: card, borderRadius: BorderRadius.circular(15), border: Border.all(color: const Color(0xFF4C3019))),
      child: Row(children: [
        RankFrame(
          role: profile?['role']?.toString() ?? 'USER',
          vipLevel: profile?['vip_level']?.toString(),
          size: 40,
          showLabel: false,
          child: CircleAvatar(
            radius: 18,
            backgroundColor: const Color(0xFF422511),
            backgroundImage: avatar.isNotEmpty ? NetworkImage(avatar) : null,
            child: avatar.isEmpty ? const Icon(Icons.person, color: gold, size: 20) : null,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              CountryFlag(code: profile?['country_code']?.toString(), size: 18),
              const SizedBox(width: 5),
              Flexible(child: Text(profile?['username']?.toString() ?? 'مستخدم', overflow: TextOverflow.ellipsis, style: const TextStyle(color: gold, fontSize: 11, fontWeight: FontWeight.w800))),
              const SizedBox(width: 5),
              ProfileBadges(
                activityAdmin: profile?['activity_admin_badge'] == true,
                customerService: profile?['customer_service_badge'] == true,
                verified: profile?['is_verified'] == true,
              ),
            ]),
            const SizedBox(height: 3),
            Text(text, style: const TextStyle(color: Colors.white, fontSize: 14)),
          ]),
        ),
      ]),
    );
  }
}
