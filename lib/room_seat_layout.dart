import 'package:flutter/material.dart';

class RoomSeatLayout extends StatelessWidget {
  final int count;
  final Set<int> locked;
  final Map<int, String?> occupants;
  final void Function(int index)? onTap;
  const RoomSeatLayout({super.key, required this.count, this.locked = const {}, this.occupants = const {}, this.onTap});

  @override
  Widget build(BuildContext context) {
    final columns = count <= 8 ? 4 : count <= 15 ? 5 : 6;
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: count,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: columns, mainAxisSpacing: 14, crossAxisSpacing: 12, childAspectRatio: .82),
      itemBuilder: (_, i) {
        final lockedSeat = locked.contains(i + 1);
        final name = occupants[i + 1];
        return InkWell(
          onTap: () => onTap?.call(i + 1),
          borderRadius: BorderRadius.circular(18),
          child: Column(children: [
            Container(
              width: 58, height: 58,
              decoration: BoxDecoration(shape: BoxShape.circle, color: lockedSeat ? const Color(0xFF22140C) : const Color(0xFF3B2112), border: Border.all(color: const Color(0xFFB77921), width: 1.5)),
              child: Icon(lockedSeat ? Icons.lock : (name == null ? Icons.person_outline : Icons.person), color: const Color(0xFFFFD36A)),
            ),
            const SizedBox(height: 5),
            Text(name ?? (lockedSeat ? 'مقفل' : 'مقعد ${i + 1}'), maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white70, fontSize: 11)),
          ]),
        );
      },
    );
  }
}
