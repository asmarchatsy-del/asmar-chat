import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

const _gold = Color(0xFFFFD36A);
const _bg = Color(0xFF100805);

class AsmarKeyboard extends StatefulWidget {
  final TextEditingController controller;
  final Future<void> Function() onSend;
  final String roomId;
  final void Function(Map<String, dynamic> gift)? onGiftSent;

  const AsmarKeyboard({super.key, required this.controller, required this.onSend, required this.roomId, this.onGiftSent});

  @override
  State<AsmarKeyboard> createState() => _AsmarKeyboardState();
}

class _AsmarKeyboardState extends State<AsmarKeyboard> {
  int tab = 0;
  bool sending = false;
  List<Map<String, dynamic>> gifts = [];
  final recipient = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadGifts();
  }

  @override
  void dispose() {
    recipient.dispose();
    super.dispose();
  }

  Future<void> _loadGifts() async {
    try {
      final result = await Supabase.instance.client
          .from('gifts')
          .select('id,name,emoji,price_coins,animation_url,is_active')
          .eq('is_active', true)
          .order('price_coins');
      if (mounted) setState(() => gifts = List<Map<String, dynamic>>.from(result));
    } catch (_) {}
  }

  Future<void> _sendGift(Map<String, dynamic> gift) async {
    final recipientId = recipient.text.trim();
    if (recipientId.isEmpty || sending) return;
    setState(() => sending = true);
    try {
      await Supabase.instance.client.rpc('send_gift', params: {
        'p_room_id': widget.roomId,
        'p_recipient_id': recipientId,
        'p_gift_id': gift['id'],
      });
      widget.onGiftSent?.call(gift);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('تعذر إرسال الهدية: $e')));
      }
    } finally {
      if (mounted) setState(() => sending = false);
    }
  }

  Widget _tab(int index, String icon, String label) {
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => tab = index),
        child: Padding(
          padding: const EdgeInsets.all(7),
          child: Column(children: [
            Text(icon, style: const TextStyle(fontSize: 21)),
            Text(label, style: TextStyle(color: tab == index ? _gold : Colors.white60, fontSize: 10, fontWeight: FontWeight.w800)),
          ]),
        ),
      ),
    );
  }

  Widget _emojiGrid(List<String> values) {
    return GridView.count(
      crossAxisCount: 8,
      children: values.map((emoji) => InkWell(
        onTap: () => setState(() => widget.controller.text += emoji),
        child: Center(child: Text(emoji, style: const TextStyle(fontSize: 27))),
      )).toList(),
    );
  }

  Widget _content() {
    if (tab == 1) {
      return Column(children: [
        TextField(controller: recipient, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(prefixIcon: Icon(Icons.person_search, color: _gold), hintText: 'ID المستلم')),
        const SizedBox(height: 4),
        Expanded(
          child: GridView.builder(
            itemCount: gifts.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 4, childAspectRatio: .82),
            itemBuilder: (_, index) {
              final gift = gifts[index];
              return InkWell(
                onTap: sending ? null : () => _sendGift(gift),
                child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Text(gift['emoji']?.toString() ?? '🎁', style: const TextStyle(fontSize: 28)),
                  Text(gift['name']?.toString() ?? '', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontSize: 10)),
                  Text('${gift['price_coins'] ?? 0} 🪙', style: const TextStyle(color: _gold, fontSize: 9)),
                ]),
              );
            },
          ),
        ),
      ]);
    }
    if (tab == 2) {
      return _emojiGrid(['🔥','💖','👑','💎','🎉','🥳','😂','😍','😎','❤️','✨','🌹','🚘','🫶','🤝','🏆']);
    }
    return _emojiGrid(['😀','😃','😂','🤣','😊','😍','🥰','😘','😎','🤩','🥳','😢','😭','😡','🤔','😴','🙈','❤️','💕','💯','🔥','✨','🎉','👏','👍','🙏','💎','👑','🌹','🚘','🫶','🤝']);
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: _bg,
      child: SafeArea(
        top: false,
        child: Container(
          height: 280,
          padding: const EdgeInsets.fromLTRB(10, 6, 10, 8),
          decoration: const BoxDecoration(color: _bg, borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
          child: Column(children: [
            Row(children: [
              Expanded(child: TextField(controller: widget.controller, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(hintText: 'اكتب رسالة…', prefixIcon: Icon(Icons.alternate_email, color: _gold)))),
              IconButton(onPressed: widget.onSend, icon: const Icon(Icons.send, color: _gold)),
            ]),
            const Divider(color: Colors.white12),
            Row(children: [_tab(0, '😊', 'Emoji'), _tab(1, '🎁', 'هدايا'), _tab(2, '✨', 'Stickers')]),
            Expanded(child: _content()),
          ]),
        ),
      ),
    );
  }
}
