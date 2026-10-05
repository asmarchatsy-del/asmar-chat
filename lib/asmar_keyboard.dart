import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

const _gold = Color(0xFFFFD36A);
const _bg = Color(0xFF100805);

class AsmarKeyboard extends StatefulWidget {
  final TextEditingController controller;
  final Future<void> Function() onSend;
  final String roomId;
  final void Function(Map<String, dynamic> gift)? onGiftSent;

  const AsmarKeyboard({
    super.key,
    required this.controller,
    required this.onSend,
    required this.roomId,
    this.onGiftSent,
  });

  @override
  State<AsmarKeyboard> createState() => _AsmarKeyboardState();
}

class _AsmarKeyboardState extends State<AsmarKeyboard> {
  String category = 'Popular';
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
          .select('id,name,emoji,price,category,asset_url,preview_url,animation_url,is_active')
          .eq('is_active', true)
          .order('price');
      if (mounted) {
        setState(() => gifts = List<Map<String, dynamic>>.from(result));
      }
    } catch (_) {}
  }

  List<Map<String, dynamic>> get shown {
    return gifts.where((g) {
      final c = g['category']?.toString().toLowerCase() ?? '';
      switch (category) {
        case 'Lucky':
          return c.contains('luck');
        case 'Couple':
          return c == 'cp' || c == 'love' || c.contains('couple');
        case 'RelationShip':
          return c == 'brotherhood' || c == 'relation';
        case 'VIP':
          return c.contains('luxury') || c.contains('vip') || c.contains('3d');
        default:
          return true;
      }
    }).toList();
  }

  Future<void> _sendGift(Map<String, dynamic> gift) async {
    final recipientId = recipient.text.trim();
    if (recipientId.isEmpty || sending) return;
    setState(() => sending = true);
    try {
      await Supabase.instance.client.rpc(
        'send_gift',
        params: {
          'p_room_id': widget.roomId,
          'p_recipient_id': recipientId,
          'p_gift_id': gift['id'],
        },
      );
      widget.onGiftSent?.call(gift);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('تعذر إرسال الهدية: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => sending = false);
    }
  }

  Widget _giftVisual(Map<String, dynamic> gift) {
    final url = (gift['animation_url'] ?? gift['asset_url'] ?? gift['preview_url'] ?? '').toString();
    if (url.isNotEmpty) {
      return Image.network(
        url,
        width: 48,
        height: 48,
        fit: BoxFit.contain,
        errorBuilder: (_, __, ___) => Text(
          gift['emoji']?.toString() ?? '🎁',
          style: const TextStyle(fontSize: 32),
        ),
      );
    }
    return Text(
      gift['emoji']?.toString() ?? '🎁',
      style: const TextStyle(fontSize: 32),
    );
  }

  Widget _content() {
    final rows = shown;
    return GridView.builder(
      itemCount: rows.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        childAspectRatio: .82,
      ),
      itemBuilder: (_, i) {
        final gift = rows[i];
        return InkWell(
          onTap: sending ? null : () => _sendGift(gift),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _giftVisual(gift),
              Text(
                gift['name']?.toString() ?? '',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                '${gift['price'] ?? 0} 🪙',
                style: const TextStyle(color: _gold, fontSize: 9),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: _bg,
      child: SafeArea(
        top: false,
        child: Container(
          height: 300,
          padding: const EdgeInsets.fromLTRB(10, 6, 10, 8),
          decoration: const BoxDecoration(
            color: _bg,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: widget.controller,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        hintText: 'اكتب رسالة...',
                        prefixIcon: Icon(Icons.message, color: _gold),
                      ),
                      onSubmitted: (_) => widget.onSend(),
                    ),
                  ),
                  IconButton(
                    onPressed: widget.onSend,
                    icon: const Icon(Icons.send, color: _gold),
                  ),
                ],
              ),
              const Divider(color: Colors.white12),
              SizedBox(
                height: 42,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: ['Popular', 'Lucky', 'Couple', 'RelationShip', 'VIP']
                      .map(
                        (c) => Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 3),
                          child: ChoiceChip(
                            label: Text(c),
                            selected: category == c,
                            onSelected: (_) => setState(() => category = c),
                            selectedColor: _gold,
                            labelStyle: TextStyle(
                              color: category == c ? Colors.black : Colors.white70,
                            ),
                          ),
                        ),
                      )
                      .toList(),
                ),
              ),
              const SizedBox(height: 4),
              Expanded(child: _content()),
            ],
          ),
        ),
      ),
    );
  }
}
