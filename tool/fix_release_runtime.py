from pathlib import Path
import re

p = Path('lib/main.dart')
s = p.read_text()

# GoogleSignIn 7.x must be initialized exactly once. Initialize it before runApp.
needle = "  runApp(const AsmarApp());"
init = """  if (!kIsWeb) {
    const webClientId = String.fromEnvironment('GOOGLE_WEB_CLIENT_ID');
    if (webClientId.isEmpty) {
      throw StateError('GOOGLE_WEB_CLIENT_ID is not configured');
    }
    await GoogleSignIn.instance.initialize(serverClientId: webClientId);
  }

  runApp(const AsmarApp());"""
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
replacement = '''  Future<void> _loginWithGoogle() async {
    setState(() { loading = true; error = null; });
    try {
      if (kIsWeb) {
        await Supabase.instance.client.auth.signInWithOAuth(
          OAuthProvider.google,
          redirectTo: Uri.base.origin,
          authScreenLaunchMode: LaunchMode.externalApplication,
        );
      } else {
        final account = await GoogleSignIn.instance.authenticate();
        final auth = account.authentication;
        final idToken = auth.idToken;
        if (idToken == null) {
          throw StateError('Google did not return an ID token');
        }

        const scopes = <String>['email', 'profile'];
        final authorization = await account.authorizationClient.authorizationForScopes(scopes)
            ?? await account.authorizationClient.authorizeScopes(scopes);
        final accessToken = authorization.accessToken;
        if (accessToken.isEmpty) {
          throw StateError('Google did not return an access token');
        }

        await Supabase.instance.client.auth.signInWithIdToken(
          provider: OAuthProvider.google,
          idToken: idToken,
          accessToken: accessToken,
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => error = 'تعذر تسجيل الدخول بواسطة Google. تأكد من إعداد Google OAuth وSHA-256 للتطبيق.');
      }
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  void dispose()'''
s2, n = pattern.subn(replacement, s, count=1)
if n != 1:
    raise SystemExit('Could not replace Google sign-in method')
s = s2
p.write_text(s)

# Harden the optional promotion query so a missing/blocked promotions table never crashes navigation.
p2 = Path('lib/main.dart')
s = p2.read_text()
old = """    final rows=await Supabase.instance.client.from('app_promotions')
      .select('id,title,subtitle,image_url,first_place,second_place,third_place,first_prize,second_prize,third_prize,button_text')
      .eq('is_active',true).lte('starts_at',now).or('ends_at.is.null,ends_at.gte.$now')
      .order('created_at',ascending:false).limit(1);
    if(rows.isEmpty)return null;
    return Map<String,dynamic>.from(rows.first);"""
new = """    try {
      final rows=await Supabase.instance.client.from('app_promotions')
        .select('id,title,subtitle,image_url,first_place,second_place,third_place,first_prize,second_prize,third_prize,button_text')
        .eq('is_active',true).lte('starts_at',now).or('ends_at.is.null,ends_at.gte.$now')
        .order('created_at',ascending:false).limit(1);
      if(rows.isEmpty)return null;
      return Map<String,dynamic>.from(rows.first);
    } catch (_) {
      return null;
    }"""
if old in s:
    s=s.replace(old,new,1)
p2.write_text(s)
