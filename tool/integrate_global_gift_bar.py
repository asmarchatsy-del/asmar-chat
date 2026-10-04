from pathlib import Path


def warn(message: str) -> None:
    print(f"WARNING: {message}")


def first_marker(text: str, markers: list[str]) -> str | None:
    for marker in markers:
        if marker in text:
            return marker
    return None


def main() -> int:
    try:
        room = Path('lib/room.dart')
        if not room.exists():
            warn('lib/room.dart not found; skipping room integration')
        else:
            s = room.read_text(encoding='utf-8')
            if "import 'gift_banner.dart';" not in s:
                marker = first_marker(s, [
                    "import 'asmar_keyboard.dart';",
                    "import 'package:flutter/material.dart';",
                ])
                if marker is None:
                    warn('room import marker not found; skipping import injection')
                else:
                    import_line = "\nimport 'gift_banner.dart';"
                    s = s.replace(marker, marker + import_line, 1)

            if 'GlobalGiftBanner(' not in s:
                scaffold_marker = first_marker(s, [
                    '      child: Scaffold(\n        backgroundColor: bg,',
                    'child: Scaffold(\n        backgroundColor: bg,',
                    'child: Scaffold(',
                ])
                if scaffold_marker is None:
                    warn('room Scaffold marker not found; skipping banner wrapper')
                else:
                    new = """      child: GlobalGiftBanner(
        onRoomTap: (roomId, roomName) {
          Navigator.of(context).push(MaterialPageRoute(builder: (_) => Room(name: roomName, roomId: roomId)));
        },
        child: Scaffold(
        backgroundColor: bg,"""
                    s = s.replace(scaffold_marker, new, 1)

                    end_marker = first_marker(s, [
                        '      ),\n    );\n  }\n\n  Widget _message',
                        '    );\n  }\n\n  Widget _message',
                    ])
                    if end_marker is None:
                        warn('room Scaffold closing marker not found; leaving wrapper unchanged')
                    else:
                        s = s.replace(end_marker, '        )),\n    );\n  }\n\n  Widget _message', 1)
            room.write_text(s, encoding='utf-8')

        admin = Path('lib/super_admin_panel.dart')
        if not admin.exists():
            warn('lib/super_admin_panel.dart not found; skipping admin threshold integration')
            return 0

        a = admin.read_text(encoding='utf-8')
        already_integrated = (
            'Future<void> _editGlobalGiftThreshold()' in a
            or 'min_gift_value_for_banner' in a
            or 'إعداد شريط الهدايا العالمي' in a
        )

        if already_integrated:
            print('Global gift threshold already integrated; skipping.')
            return 0

        markers = [
            '  Widget _stat(String title, num value, IconData icon)',
            'Widget _stat(String title, num value, IconData icon)',
            'ADMIN STATS MARKER',
            'admin stat marker',
            'buildStats',
            'AdminStats',
        ]
        marker = first_marker(a, markers)

        if marker is None:
            warn('admin stat marker not found; threshold integration skipped (non-fatal)')
            return 0

        method = '''  Future<void> _editGlobalGiftThreshold() async {
    try {
      final row = await db.from('app_settings').select('int_value').eq('key','min_gift_value_for_banner').maybeSingle();
      final controller = TextEditingController(text: '${(row?['int_value'] as num?)?.toInt() ?? 10000}');
      final save = await showDialog<bool>(context: context, builder: (ctx) => AlertDialog(
        backgroundColor: _card,
        title: const Text('شريط الهدايا العالمي', style: TextStyle(color: _gold)),
        content: TextField(controller: controller, keyboardType: TextInputType.number, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(labelText: 'الحد الأدنى لقيمة الهدية', suffixText: 'ذهب')),
        actions: [TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('إلغاء')), FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('حفظ'))],
      ));
      if (save != true) return;
      final value = int.tryParse(controller.text.trim());
      if (value == null || value < 0) { _message('قيمة غير صحيحة'); return; }
      await db.from('app_settings').upsert({'key':'min_gift_value_for_banner','int_value':value,'updated_at':DateTime.now().toIso8601String()});
      _message('تم حفظ حد شريط الهدايا: $value ذهب');
    } catch (e) { _message('تعذر حفظ الإعداد: $e'); }
  }

'''
        a = a.replace(marker, method + marker, 1)

        if 'onPressed: _editGlobalGiftThreshold' not in a:
            dashboard_markers = [
                '  Widget _dashboard() => ListView(children: [',
                'Widget _dashboard() => ListView(children: [',
                'buildStats',
                'AdminStats',
            ]
            dashboard_marker = first_marker(a, dashboard_markers)
            if dashboard_marker is None:
                warn('admin dashboard marker not found; threshold button skipped (non-fatal)')
            else:
                button = "const SizedBox(height: 14), FilledButton.icon(onPressed: _editGlobalGiftThreshold, icon: const Icon(Icons.campaign), label: const Text('إعداد شريط الهدايا العالمي')), "
                a = a.replace(dashboard_marker, dashboard_marker + button, 1)

        admin.write_text(a, encoding='utf-8')
        return 0
    except Exception as exc:
        warn(f'global gift integration encountered a non-fatal error: {exc}')
        return 0


if __name__ == '__main__':
    raise SystemExit(main())
