from pathlib import Path
import re

p = Path('lib/main.dart')
s = p.read_text()

# GoogleSignIn 7.x must be initialized exactly once. Initialize it before runApp.
needle = "  runApp(const AsmarApp());"
init = """  if (!kIsWeb) {\n    const webClientId = String.fromEnvironment('GOOGLE_WEB_CLIENT_ID');\n    if (webClientId.isEmpty) {\n      throw StateError('GOOGLE_WEB_CLIENT_ID is not configured');\n    }\n    await GoogleSignIn.instance.initialize(serverClientId: webClientId);\n  }\n\n  runApp(const AsmarApp());"""
if needle not in s:
    raise SystemExit('Could not find runApp initialization marker')
s = s.replace(needle, init, 1)

# Never block the authenticated app behind the optional promotion query.
s = s.replace(
    "if(supabase.auth.currentSession!=null)return const LaunchPromotion();",
    "if(supabase.auth.currentSession!=null)return const Shell();",
    1,
)

# Native Google account picker + reliable access-token acquisition for google_sign_in 7.x.
pattern = re.compile(r"  Future<void> _loginWithGoogle\(\) async \{.*?\n  \}\n\n  @override\n  void dispose\(\)", re.S)
replacement = '''  Future<void> _loginWithGoogle() async {\n    setState(() { loading = true; error = null; });\n    try {\n      if (kIsWeb) {\n        await Supabase.instance.client.auth.signInWithOAuth(\n          OAuthProvider.google,\n          redirectTo: Uri.base.origin,\n          authScreenLaunchMode: LaunchMode.externalApplication,\n        );\n      } else {\n        final account = await GoogleSignIn.instance.authenticate();\n        final auth = account.authentication;\n        final idToken = auth.idToken;\n        if (idToken == null) {\n          throw StateError('Google did not return an ID token');\n        }\n\n        const scopes = <String>['email', 'profile'];\n        final authorization = await account.authorizationClient.authorizationForScopes(scopes)\n            ?? await account.authorizationClient.authorizeScopes(scopes);\n        final accessToken = authorization.accessToken;\n        if (accessToken.isEmpty) {\n          throw StateError('Google did not return an access token');\n        }\n\n        await Supabase.instance.client.auth.signInWithIdToken(\n          provider: OAuthProvider.google,\n          idToken: idToken,\n          accessToken: accessToken,\n        );\n      }\n    } catch (e) {\n      if (mounted) {\n        setState(() => error = 'تعذر تسجيل الدخول بواسطة Google. تأكد من إعداد Google OAuth وSHA-256 للتطبيق.');\n      }\n    } finally {\n      if (mounted) setState(() => loading = false);\n    }\n  }\n\n  @override\n  void dispose()'''
s2, n = pattern.subn(replacement, s, count=1)
if n != 1:
    raise SystemExit('Could not replace Google sign-in method')
s = s2
p.write_text(s)

# Harden the optional promotion query so a missing/blocked promotions table never crashes navigation.
p2 = Path('lib/main.dart')
s = p2.read_text()
old = """    final rows=await Supabase.instance.client.from('app_promotions')\n      .select('id,title,subtitle,image_url,first_place,second_place,third_place,first_prize,second_prize,third_prize,button_text')\n      .eq('is_active',true).lte('starts_at',now).or('ends_at.is.null,ends_at.gte.$now')\n      .order('created_at',ascending:false).limit(1);\n    if(rows.isEmpty)return null;\n    return Map<String,dynamic>.from(rows.first);"""
new = """    try {\n      final rows=await Supabase.instance.client.from('app_promotions')\n        .select('id,title,subtitle,image_url,first_place,second_place,third_place,first_prize,second_prize,third_prize,button_text')\n        .eq('is_active',true).lte('starts_at',now).or('ends_at.is.null,ends_at.gte.$now')\n        .order('created_at',ascending:false).limit(1);\n      if(rows.isEmpty)return null;\n      return Map<String,dynamic>.from(rows.first);\n    } catch (_) {\n      return null;\n    }"""
if old in s:
    s=s.replace(old,new,1)
p2.write_text(s)
PY
python -m py_compile tool/fix_release_runtime.py
