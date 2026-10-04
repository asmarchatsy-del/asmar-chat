from pathlib import Path

room = Path('lib/room.dart')
s = room.read_text()
if "import 'gift_banner.dart';" not in s:
    marker = "import 'asmar_keyboard.dart';"
    if marker not in s: raise SystemExit('room import marker not found')
    s = s.replace(marker, marker + "\nimport 'gift_banner.dart';", 1)
if 'GlobalGiftBanner(' not in s:
    old = '      child: Scaffold(\n        backgroundColor: bg,'
    new = "      child: GlobalGiftBanner(\n        onRoomTap: (roomId, roomName) {\n          Navigator.of(context).push(MaterialPageRoute(builder: (_) => Room(name: roomName, roomId: roomId)));\n        },\n        child: Scaffold(\n        backgroundColor: bg,"
    if old not in s: raise SystemExit('room Scaffold marker not found')
    s = s.replace(old, new, 1)
    old_end = '      ),\n    );\n  }\n\n  Widget _message'
    new_end = '        )),\n    );\n  }\n\n  Widget _message'
    if old_end not in s: raise SystemExit('room Scaffold closing marker not found')
    s = s.replace(old_end, new_end, 1)
room.write_text(s)

admin = Path('lib/super_admin_panel.dart')
a = admin.read_text()
if 'Future<void> _editGlobalGiftThreshold()' not in a:
    marker = '  Widget _stat(String title, num value, IconData icon)'
    method = '''  Future<void> _editGlobalGiftThreshold() async {\n    try {\n      final row = await db.from('app_settings').select('int_value').eq('key','min_gift_value_for_banner').maybeSingle();\n      final controller = TextEditingController(text: '${(row?['int_value'] as num?)?.toInt() ?? 10000}');\n      final save = await showDialog<bool>(context: context, builder: (ctx) => AlertDialog(\n        backgroundColor: _card,\n        title: const Text('شريط الهدايا العالمي', style: TextStyle(color: _gold)),\n        content: TextField(controller: controller, keyboardType: TextInputType.number, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(labelText: 'الحد الأدنى لقيمة الهدية', suffixText: 'ذهب')),\n        actions: [TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('إلغاء')), FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('حفظ'))],\n      ));\n      if (save != true) return;\n      final value = int.tryParse(controller.text.trim());\n      if (value == null || value < 0) { _message('قيمة غير صحيحة'); return; }\n      await db.from('app_settings').upsert({'key':'min_gift_value_for_banner','int_value':value,'updated_at':DateTime.now().toIso8601String()});\n      _message('تم حفظ حد شريط الهدايا: $value ذهب');\n    } catch (e) { _message('تعذر حفظ الإعداد: $e'); }\n  }\n\n'''
    if marker not in a: raise SystemExit('admin stat marker not found')
    a = a.replace(marker, method + marker, 1)
if 'onPressed: _editGlobalGiftThreshold' not in a:
    marker = "  Widget _dashboard() => ListView(children: ["
    if marker not in a: raise SystemExit('admin dashboard marker not found')
    a = a.replace(marker, marker + "const SizedBox(height: 14), FilledButton.icon(onPressed: _editGlobalGiftThreshold, icon: const Icon(Icons.campaign), label: const Text('إعداد شريط الهدايا العالمي')), ", 1)
admin.write_text(a)
