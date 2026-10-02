from pathlib import Path
import base64
import re

root = Path('.')
assets = root / 'assets'
assets.mkdir(exist_ok=True)

# Materialize the user-provided Asmar Chat logo from the repository-safe text asset.
logo = base64.b64decode((assets / 'asmar_logo.b64').read_text().strip())
(assets / 'asmar_logo.jpg').write_bytes(logo)

# Register the logo as a Flutter asset without changing the existing dependency set.
pub = root / 'pubspec.yaml'
s = pub.read_text()
if 'assets/asmar_logo.jpg' not in s:
    marker = 'flutter:\n  uses-material-design: true\n'
    if marker not in s:
        raise SystemExit('Flutter section not found in pubspec.yaml')
    s = s.replace(marker, marker + '  assets:\n    - assets/asmar_logo.jpg\n', 1)
    pub.write_text(s)

# Add the supplied logo to the login screen, clipped into a circle.
main = root / 'lib' / 'main.dart'
s = main.read_text()
login_start = s.find('class LoginPage extends StatefulWidget')
if login_start < 0:
    raise SystemExit('LoginPage not found')
needle = "const Text('ASMAR CHAT'"
pos = s.find(needle, login_start)
if pos < 0:
    raise SystemExit('Login title not found')
if 'assets/asmar_logo.jpg' not in s[login_start:]:
    logo_widget = '''Container(\n                    width: 112,\n                    height: 112,\n                    padding: const EdgeInsets.all(3),\n                    decoration: const BoxDecoration(\n                      shape: BoxShape.circle,\n                      gradient: LinearGradient(\n                        colors: [gold, gold2],\n                        begin: Alignment.topLeft,\n                        end: Alignment.bottomRight,\n                      ),\n                    ),\n                    child: ClipOval(\n                      child: Image.asset(\n                        'assets/asmar_logo.jpg',\n                        fit: BoxFit.cover,\n                      ),\n                    ),\n                  ),\n                  const SizedBox(height: 16),\n                  '''
    s = s[:pos] + logo_widget + s[pos:]
    main.write_text(s)

# Use the same supplied artwork as the Android launcher icon and ensure the
# human-readable application name is Asmar Chat.
manifest = root / 'android' / 'app' / 'src' / 'main' / 'AndroidManifest.xml'
ms = manifest.read_text()
app_match = re.search(r'<application\\b[^>]*>', ms, re.S)
if not app_match:
    raise SystemExit('Android application tag not found')
app = app_match.group(0)
if 'android:icon=' in app:
    app = re.sub(r'android:icon="[^"]*"', 'android:icon="@drawable/asmar_logo"', app, count=1)
else:
    app = app[:-1] + ' android:icon="@drawable/asmar_logo">'
app = re.sub(r'android:label="[^"]*"', 'android:label="Asmar Chat"', app, count=1)
ms = ms[:app_match.start()] + app + ms[app_match.end():]
manifest.write_text(ms)

res = root / 'android' / 'app' / 'src' / 'main' / 'res' / 'drawable'
res.mkdir(parents=True, exist_ok=True)
(res / 'asmar_logo.jpg').write_bytes(logo)
print('Asmar Chat branding applied successfully')
