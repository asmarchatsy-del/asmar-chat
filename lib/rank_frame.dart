import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class RankFrame extends StatefulWidget {
  final String role;
  final double size;
  final Widget child;
  final bool showLabel;
  final String? vipLevel;
  final int svipLevel;

  const RankFrame({
    super.key,
    required this.role,
    required this.child,
    this.size = 86,
    this.showLabel = true,
    this.vipLevel,
    this.svipLevel = 0,
  });

  @override
  State<RankFrame> createState() => _RankFrameState();
}

class _RankFrameState extends State<RankFrame>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  String? _remoteMediaUrl;
  bool _remoteGlow = true;
  bool _remoteMotion = true;

  static const _gold = Color(0xFFFFD36A);

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();
    _loadRemoteStyle();
  }

  Future<void> _loadRemoteStyle() async {
    try {
      final db = Supabase.instance.client;
      if (widget.svipLevel >= 6 && widget.svipLevel <= 8) {
        final row = await db
            .from('svip_levels')
            .select('media_url,glow_enabled,motion_enabled')
            .eq('level', widget.svipLevel)
            .maybeSingle();
        if (!mounted || row == null) return;
        setState(() {
          _remoteMediaUrl = row['media_url']?.toString();
          _remoteGlow = row['glow_enabled'] != false;
          _remoteMotion = row['motion_enabled'] != false;
        });
      } else {
        final vip = int.tryParse(
              (widget.vipLevel ?? '').replaceAll(RegExp(r'[^0-9]'), ''),
            ) ??
            0;
        if (vip >= 7 && vip <= 10) {
          final row = await db
              .from('vip_levels')
              .select('image')
              .eq('id', 'VIP$vip')
              .maybeSingle();
          if (!mounted || row == null) return;
          setState(() {
            _remoteMediaUrl = row['image']?.toString();
            _remoteGlow = true;
            _remoteMotion = true;
          });
        }
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  _RankStyle get _style => _RankStyle.forRole(widget.role, widget.vipLevel);

  @override
  Widget build(BuildContext context) {
    final s = _style;
    final outer = widget.size + 22;
    final moving = _remoteMotion;
    final glow = _remoteGlow;

    return SizedBox(
      width: widget.showLabel ? math.max(outer, 118) : outer,
      height: widget.showLabel ? outer + 30 : outer,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: outer,
            height: outer,
            child: AnimatedBuilder(
              animation: _controller,
              builder: (_, child) {
                return Stack(
                  alignment: Alignment.center,
                  children: [
                    Transform.rotate(
                      angle: moving ? _controller.value * math.pi * 2 : 0,
                      child: Container(
                        width: outer,
                        height: outer,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: SweepGradient(
                            colors: [
                              s.dark,
                              s.primary,
                              s.highlight,
                              s.primary,
                              s.dark,
                            ],
                          ),
                          boxShadow: glow
                              ? [
                                  BoxShadow(
                                    color: s.primary.withOpacity(.65),
                                    blurRadius: 18,
                                    spreadRadius: 2,
                                  ),
                                  BoxShadow(
                                    color: s.highlight.withOpacity(.24),
                                    blurRadius: 30,
                                    spreadRadius: 5,
                                  ),
                                ]
                              : const [],
                        ),
                      ),
                    ),
                    Container(
                      width: outer - 8,
                      height: outer - 8,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [s.highlight, s.dark, s.primary],
                        ),
                      ),
                    ),
                    Container(
                      width: widget.size + 4,
                      height: widget.size + 4,
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.black,
                        border: Border.all(color: _gold, width: 1.3),
                      ),
                      child: ClipOval(child: child),
                    ),
                    if (_remoteMediaUrl != null && _remoteMediaUrl!.isNotEmpty)
                      SizedBox(
                        width: outer,
                        height: outer,
                        child: IgnorePointer(
                          child: Image.network(
                            _remoteMediaUrl!,
                            fit: BoxFit.contain,
                            errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                          ),
                        ),
                      ),
                    Positioned(
                      top: 1,
                      right: 7,
                      child: Transform.rotate(
                        angle: -_controller.value * math.pi * 2,
                        child: Icon(
                          s.icon,
                          color: s.highlight,
                          size: 20,
                        ),
                      ),
                    ),
                  ],
                );
              },
              child: widget.child,
            ),
          ),
          if (widget.showLabel) ...[
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: LinearGradient(colors: [s.primary, s.dark]),
                border: Border.all(color: s.highlight.withOpacity(.8)),
                boxShadow: [
                  BoxShadow(
                    color: s.primary.withOpacity(.35),
                    blurRadius: 10,
                  ),
                ],
              ),
              child: Text(
                s.label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  letterSpacing: .5,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _RankStyle {
  final String label;
  final Color dark;
  final Color primary;
  final Color highlight;
  final IconData icon;

  const _RankStyle({
    required this.label,
    required this.dark,
    required this.primary,
    required this.highlight,
    required this.icon,
  });

  static _RankStyle forRole(String rawRole, String? vipLevel) {
    final vip = vipLevel?.toUpperCase();
    if (vip != null && vip.startsWith('VIP')) {
      final n = int.tryParse(vip.substring(3)) ?? 0;
      final animals = [
        '',
        '🦌',
        '🐺',
        '🐊',
        '🐘',
        '🦅',
        '🐻',
        '🐆',
        '🐯',
        '🐉',
        '🦁'
      ];
      final colors = [
        [
          const Color(0xFF6B3E0B),
          const Color(0xFFFFC107),
          const Color(0xFFFFF0A0)
        ],
        [
          const Color(0xFF073B4C),
          const Color(0xFF00B4D8),
          const Color(0xFFB8F2FF)
        ],
        [
          const Color(0xFF3A0A0A),
          const Color(0xFFE53935),
          const Color(0xFFFFB4B4)
        ],
        [
          const Color(0xFF2E165C),
          const Color(0xFF8E44FF),
          const Color(0xFFE0C7FF)
        ],
        [
          const Color(0xFF064A38),
          const Color(0xFF16C784),
          const Color(0xFFA8FFE0)
        ],
        [
          const Color(0xFF5A2606),
          const Color(0xFFFF8A00),
          const Color(0xFFFFD2A1)
        ],
        [
          const Color(0xFF4A3005),
          const Color(0xFFE5A900),
          const Color(0xFFFFF1A3)
        ],
        [
          const Color(0xFF24105A),
          const Color(0xFF7B2CFF),
          const Color(0xFFE0C7FF)
        ],
        [
          const Color(0xFF071B4D),
          const Color(0xFF1976D2),
          const Color(0xFFB8DDFF)
        ],
        [
          const Color(0xFF5A0808),
          const Color(0xFFD4AF37),
          const Color(0xFFFFF0A0)
        ],
      ];
      if (n >= 1 && n <= 10) {
        return _RankStyle(
          label: 'VIP$n ${animals[n]}',
          dark: colors[n - 1][0],
          primary: colors[n - 1][1],
          highlight: colors[n - 1][2],
          icon: Icons.workspace_premium,
        );
      }
    }
    final role = rawRole.toUpperCase();
    switch (role) {
      case 'CEO':
        return const _RankStyle(
          label: 'CEO',
          dark: Color(0xFF5A0808),
          primary: Color(0xFFD4AF37),
          highlight: Color(0xFFFFF0A0),
          icon: Icons.workspace_premium,
        );
      case 'SUPER_ADMIN':
        return const _RankStyle(
          label: 'SUPER ADMIN',
          dark: Color(0xFF24105A),
          primary: Color(0xFF8D5CFF),
          highlight: Color(0xFFD9C7FF),
          icon: Icons.auto_awesome,
        );
      case 'MANAGER':
        return const _RankStyle(
          label: 'MANAGER',
          dark: Color(0xFF073D5A),
          primary: Color(0xFF18A9D6),
          highlight: Color(0xFFA7EEFF),
          icon: Icons.military_tech,
        );
      case 'ADMIN':
        return const _RankStyle(
          label: 'ADMIN',
          dark: Color(0xFF064A38),
          primary: Color(0xFF19B77A),
          highlight: Color(0xFF9DFFE0),
          icon: Icons.shield,
        );
      case 'HOST':
        return const _RankStyle(
          label: 'HOST',
          dark: Color(0xFF5A2606),
          primary: Color(0xFFE87920),
          highlight: Color(0xFFFFD1A8),
          icon: Icons.mic,
        );
      case 'AGENT':
        return const _RankStyle(
          label: 'COIN SELLER',
          dark: Color(0xFF4A3005),
          primary: Color(0xFFE5A900),
          highlight: Color(0xFFFFF1A3),
          icon: Icons.monetization_on,
        );
      default:
        return const _RankStyle(
          label: 'USER',
          dark: Color(0xFF292929),
          primary: Color(0xFF777777),
          highlight: Color(0xFFE4E4E4),
          icon: Icons.person,
        );
    }
  }
}
