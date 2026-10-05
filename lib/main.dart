import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'backend_config.dart';
import 'admin_panel.dart';
import 'role_centers.dart';
import 'room.dart';
import 'store.dart';
import 'agent_recharge.dart';
import 'rank_frame.dart';
import 'vip.dart';
import 'country_flag.dart';
import 'notifications.dart';
import 'friends.dart';
import 'private_conversations.dart';
import 'avatar_picker.dart';
import 'profile_badges.dart';
import 'gift_banner.dart';
import 'global_chat.dart';
import 'messages.dart';
import 'rocket_levels.dart';
import 'wallet.dart';
import 'plinko_demo.dart';
import 'slot_demo.dart';
import 'chicken_crossing_demo.dart';
import 'features/home/beela_shell.dart';

const gold = Color(0xFFFFD36A);
const gold2 = Color(0xFFB77921);
const bg = Color(0xFF090604);
const card = Color(0xFF1B0E08);

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
    url: BackendConfig.supabaseUrl,
    publishableKey: BackendConfig.supabasePublishableKey,
    authOptions: FlutterAuthClientOptions(
      authFlowType: kIsWeb ? AuthFlowType.implicit : AuthFlowType.pkce,
    ),
  );
  runApp(const AsmarApp());
}

class AsmarApp extends StatelessWidget {
  const AsmarApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Asmar Chat',
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness
