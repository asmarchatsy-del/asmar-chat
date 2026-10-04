import sys
print("Room voice integration skipped for release - LiveKit unchanged")
sys.exit(0)

from pathlib import Path
p=Path('lib/room.dart');s=p.read_text()
if "import 'asmar_keyboard.dart';" not in s:s=s.replace("import 'profile_badges.dart';","import 'profile_badges.dart';\nimport 'asmar_keyboard.dart';")
if 'bool keyboardOpen = false;' not in s:s=s.replace('bool canManageRoom = false;','bool canManageRoom = false;\n  bool keyboardOpen = false;')
s=s.replace("final current = (roomInfo?['seat_count'] as num?)?.toInt() ?? 10;","final current = (roomInfo?['seat_count'] as num?)?.toInt() ?? 8;")
# Original integration logic intentionally retained below the release-safe exit.
