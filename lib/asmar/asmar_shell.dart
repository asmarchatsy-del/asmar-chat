import 'package:flutter/material.dart';
import '../asmar/asmar_theme.dart';
import '../features/home/beela_shell.dart';
import '../features/games/games_center_screen.dart';
import '../features/profile/profile_screen.dart';
import '../features/store/store_screen.dart';
import '../features/wallet/wallet_screen.dart';

class AsmarBuild452Shell extends StatefulWidget {
  const AsmarBuild452Shell({super.key});
  @override State<AsmarBuild452Shell> createState() => _AsmarBuild452ShellState();
}

class _AsmarBuild452ShellState extends State<AsmarBuild452Shell> {
  int index = 0;
  final pages = const [
    BeelaShell(),
    GamesCenterScreen(),
    ProfileScreen(),
    StoreScreen(),
    WalletScreen(),
  ];

  @override
  Widget build(BuildContext context) => Theme(
        data: AsmarTheme.theme(),
        child: Directionality(
          textDirection: TextDirection.rtl,
          child: Scaffold(
            backgroundColor: AsmarTheme.background,
            body: IndexedStack(index: index, children: pages),
            bottomNavigationBar: NavigationBar(
              backgroundColor: AsmarTheme.surface,
              indicatorColor: const Color(0x334A3217),
              selectedIndex: index,
              onDestinationSelected: (value) => setState(() => index = value),
              destinations: const [
                NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home, color: AsmarTheme.gold), label: 'الرئيسية'),
                NavigationDestination(icon: Icon(Icons.games_outlined), selectedIcon: Icon(Icons.games, color: AsmarTheme.gold), label: 'الألعاب'),
                NavigationDestination(icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person, color: AsmarTheme.gold), label: 'ملفي'),
                NavigationDestination(icon: Icon(Icons.storefront_outlined), selectedIcon: Icon(Icons.storefront, color: AsmarTheme.gold), label: 'المتجر'),
                NavigationDestination(icon: Icon(Icons.account_balance_wallet_outlined), selectedIcon: Icon(Icons.account_balance_wallet, color: AsmarTheme.gold), label: 'المحفظة'),
              ],
            ),
          ),
        ),
      );
}
