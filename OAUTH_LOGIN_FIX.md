# OAuth login fix

Google OAuth must return to the deployed application origin on web and use the Supabase mobile callback on Android/iOS. Do not use localhost in production redirect configuration.

Web redirect: https://hassanalmushakis-lang.github.io/
Mobile redirect: io.supabase.flutter://login-callback/
