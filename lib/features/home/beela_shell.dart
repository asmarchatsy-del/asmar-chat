import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../room/widgets/create_room_sheet.dart';
import '../room/presentation/room_page.dart';

class BeelaShell extends StatefulWidget {
  const BeelaShell({super.key});
  @override
  State<BeelaShell> createState() => _BeelaShellState();
}

class _BeelaShellState extends State<BeelaShell> {
  String selectedCategory = 'الكل';
  final searchCtrl = TextEditingController();
  List<Map<String, dynamic>> rooms = [];
  bool loading = true;

  final categories = ['الكل', 'عام', 'موسيقى', 'ألعاب', 'دردشة'];

  @override
  void initState() {
    super.initState();
    _loadRooms();
  }

  Future<void> _loadRooms() async {
    setState(() => loading = true);
    try {
      final data = await Supabase.instance.client
          .from('rooms')
          .select()
          .order('created_at', ascending: false)
          .limit(50);
      setState(() {
        rooms = List<Map<String, dynamic>>.from(data);
        loading = false;
      });
    } catch (e) {
      setState(() => loading = false);
    }
  }

  List<Map<String, dynamic>> get filteredRooms {
    var list = rooms;
    if (selectedCategory != 'الكل') {
      list = list.where((r) => (r['category'] ?? 'عام') == selectedCategory).toList();
