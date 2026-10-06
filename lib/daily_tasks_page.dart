import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class DailyTasksPage extends StatefulWidget {
  const DailyTasksPage({super.key});
  @override
  State<DailyTasksPage> createState() => _DailyTasksPageState();
}

class _DailyTasksPageState extends State<DailyTasksPage> {
  final _db = Supabase.instance.client;
  bool _loading = true;
  String? _error;
  List<Map<String, dynamic>> _tasks = [];

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final rows = await _db.from('daily_tasks')
          .select('id,title,reward_coins,reward_diamonds,target,is_active')
          .eq('is_active', true).order('id');
      final user = _db.auth.currentUser;
      if (user == null) throw StateError('يجب تسجيل الدخول أولاً');
      final progress = await _db.from('user_daily_tasks')
          .select('task_id,progress,claimed_at')
          .eq('user_id', user.id)
          .eq('task_date', DateTime.now().toIso8601String().substring(0, 10));
      final byId = <String, Map<String, dynamic>>{
        for (final p in progress) p['task_id'].toString(): p,
      };
      _tasks = [
        for (final task in rows) {
          ...task,
          'progress': byId[task['id'].toString()]?['progress'] ?? 0,
          'claimed_at': byId[task['id'].toString()]?['claimed_at'],
        }
      ];
    } catch (e) { _error = e.toString(); }
    finally { if (mounted) setState(() => _loading = false); }
  }

  Future<void> _claim(Map<String, dynamic> task) async {
    try {
      await _db.rpc('asmar_claim_daily_task', params: {'p_task_id': task['id']});
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('تم استلام مكافأة ${task['reward_coins'] ?? 0} كوينز')),
      );
      await _load();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('تعذر استلام المكافأة: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) => Directionality(
    textDirection: TextDirection.rtl,
    child: Scaffold(
      appBar: AppBar(title: const Text('المهام اليومية')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Padding(padding: const EdgeInsets.all(24), child: Text(_error!, textAlign: TextAlign.center)))
              : RefreshIndicator(
                  onRefresh: _load,
                  child: _tasks.isEmpty
                      ? ListView(children: const [SizedBox(height: 180), Center(child: Text('لا توجد مهام متاحة اليوم'))])
                      : ListView.builder(
                          padding: const EdgeInsets.all(12),
                          itemCount: _tasks.length,
                          itemBuilder: (_, i) {
                            final t = _tasks[i];
                            final target = (t['target'] as num?)?.toInt() ?? 1;
                            final progress = (t['progress'] as num?)?.toInt() ?? 0;
                            final claimed = t['claimed_at'] != null;
                            final ratio = target <= 0 ? 1.0 : (progress / target).clamp(0.0, 1.0);
                            return Card(
                              margin: const EdgeInsets.only(bottom: 10),
                              child: Padding(
                                padding: const EdgeInsets.all(14),
                                child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                                  Text(t['title']?.toString() ?? 'مهمة يومية', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
                                  const SizedBox(height: 8),
                                  LinearProgressIndicator(value: ratio),
                                  const SizedBox(height: 6),
                                  Text('$progress / $target'),
                                  const SizedBox(height: 8),
                                  Row(children: [
                                    Text('🪙 ${t['reward_coins'] ?? 0}'),
                                    const SizedBox(width: 16),
                                    Text('💎 ${t['reward_diamonds'] ?? 0}'),
                                    const Spacer(),
                                    FilledButton(
                                      onPressed: claimed || progress < target ? null : () => _claim(t),
                                      child: Text(claimed ? 'تم الاستلام' : 'استلام'),
                                    ),
                                  ]),
                                ]),
                              ),
                            );
                          },
                        ),
                ),
    ),
  );
}
