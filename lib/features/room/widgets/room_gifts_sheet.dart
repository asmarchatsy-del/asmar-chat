import 'package:flutter/material.dart';

class RoomGiftsSheet extends StatelessWidget {
  final String roomId;
  final List members;

  const RoomGiftsSheet({
    super.key,
    required this.roomId,
    this.members = const [],
  });

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      height: 100,
      child: Center(child: Text('Gifts OK - Real system kept')),
    );
  }
}
