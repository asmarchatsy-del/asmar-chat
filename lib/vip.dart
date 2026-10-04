import 'package:flutter/material.dart';
import 'svip.dart';

/// Legacy compatibility entry point.
/// VIP has been retired; existing navigation now lands on SVIP instead of
/// exposing a dead VIP purchase screen.
class VipPage extends StatelessWidget {
  const VipPage({super.key});

  @override
  Widget build(BuildContext context) => const SvipPage();
}
