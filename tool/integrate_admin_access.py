from pathlib import Path
import re

me=Path('lib/me_page.dart')
s=me.read_text()
if "import 'admin_gate.dart';" not in s:
    s=s.replace("import 'private_chat.dart';", "import 'private_chat.dart';\nimport 'admin_gate.dart';")
if 'SecretAdminAvatarTrigger' not in s:
    pattern=r"RankFrame\(role:'USER',vipLevel:aristocracy\.isEmpty\?null:aristocracy,size:96,child:CircleAvatar\((.*?)\)\),const SizedBox"
    m=re.search(pattern,s,re.S)
    if not m:
        raise SystemExit('Could not locate Me avatar RankFrame')
    replacement="SecretAdminAvatarTrigger(publicId:publicId,child:RankFrame(role:'USER',vipLevel:aristocracy.isEmpty?null:aristocracy,size:96,child:CircleAvatar("+m.group(1)+")),const SizedBox"
    s=s[:m.start()]+replacement+s[m.end():]
    me.write_text(s)

entry=Path('lib/asmar_entry.dart')
e=entry.read_text()
if "import 'admin_gate.dart';" not in e:
    e=e.replace("import 'me_page.dart';", "import 'me_page.dart';\nimport 'admin_gate.dart';")
if "'/admin'" not in e:
    old="home:const _AuthGate(),"
    new="initialRoute:kIsWeb?(Uri.base.path.isEmpty?'/':Uri.base.path):'/',routes:{'/':(_)=>const _AuthGate(),'/admin':(_)=>const SuperAdminGate()},"
    if old not in e: raise SystemExit('Could not locate MaterialApp home')
    e=e.replace(old,new,1)
    entry.write_text(e)
