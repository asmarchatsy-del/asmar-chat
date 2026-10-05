import 'package:flutter/material.dart';

class AdminPanel extends StatefulWidget {
  const AdminPanel({super.key});
  @override State<AdminPanel> createState() => _AdminPanelState();
}

class _AdminPanelState extends State<AdminPanel> with SingleTickerProviderStateMixin {
  late TabController _tab;

  @override
  void initState(){
    super.initState();
    _tab = TabController(length: 6, vsync: this);
  }

  @override
  Widget build(BuildContext context){
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.red.shade700,
        title: const Text('لوحة الإدارة - أسمر شات 🔥', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        bottom: TabBar(
          controller: _tab,
          isScrollable: true,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(icon: Icon(Icons.people), text: 'المستخدمين'),
            Tab(icon: Icon(Icons.meeting_room), text: 'الغرف'),
            Tab(icon: Icon(Icons.monetization_on), text: 'المالية'),
            Tab(icon: Icon(Icons.card_giftcard), text: 'الهدايا'),
            Tab(icon: Icon(Icons.report), text: 'البلاغات'),
            Tab(icon: Icon(Icons.settings), text: 'الإعدادات'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tab,
        children: [
          _usersTab(),
          _roomsTab(),
          _financeTab(),
          _giftsTab(),
          _reportsTab(),
          _settingsTab(),
        ],
      ),
    );
  }

  Widget _usersTab(){
    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: 20,
      itemBuilder: (_,i)=> Card(
        child: ListTile(
          leading: CircleAvatar(backgroundColor: Colors.orange.shade100, child: Text('${i+1}')),
          title: Text('مستخدم ${i+1}'),
          subtitle: Text('ID: 1000${i} • Lv.${5+i} • ${['SA','EG','IQ','SY'][i%4]}'),
          trailing: PopupMenuButton(
            itemBuilder: (_)=>[
              const PopupMenuItem(value: 'vip', child: Text('اعط VIP')),
              const PopupMenuItem(value: 'coins', child: Text('اضافة عملات')),
              const PopupMenuItem(value: 'ban', child: Text('حظر')),
            ],
            onSelected: (v){
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('تم: $v لمستخدم ${i+1}')));
            },
          ),
        ),
      ),
    );
  }

  Widget _roomsTab(){
    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: 15,
      itemBuilder: (_,i)=> Card(
        child: ListTile(
          leading: Container(width:40,height:40, decoration:BoxDecoration(color: Colors.green.shade100, borderRadius:BorderRadius.circular(8)), child: const Icon(Icons.mic, color: Colors.green)),
          title: Text('غرفة ${i+1} - ${['قهوة عرب','سهرة شباب','طرب'][i%3]}'),
          subtitle: Text('${20+i*5} متواجد • ${i%2==0?'مفتوحة':'مقفلة'}'),
          trailing: Row(mainAxisSize: MainAxisSize.min, children:[
            IconButton(icon: const Icon(Icons.push_pin, color: Colors.orange), onPressed: (){}),
            IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: (){}),
          ]),
        ),
      ),
    );
  }

  Widget _financeTab(){
    return ListView(padding: const EdgeInsets.all(16), children:[
      Row(children:[
        Expanded(child: _statCard('اجمالي الشحن', '\$4,320', Colors.green)),
        const SizedBox(width:10),
        Expanded(child: _statCard('العملات المباعة', '1.2M', Colors.blue)),
      ]),
      const SizedBox(height:16),
      const Text('طلبات الشحن الأخيرة', style: TextStyle(fontWeight: FontWeight.bold, fontSize:16)),
     ...List.generate(8, (i)=> Card(child: ListTile(
        leading: const Icon(Icons.payment, color: Colors.green),
        title: Text('شحن ${[100,500,1000,2000][i%4]} عملة'),
        subtitle: Text('المستخدم 1000${i} • ${DateTime.now().day}/${DateTime.now().month}'),
        trailing: ElevatedButton(onPressed: (){}, style: ElevatedButton.styleFrom(backgroundColor: Colors.green), child: const Text('تأكيد', style: TextStyle(color: Colors.white))),
      ))),
    ]);
  }

  Widget _giftsTab(){
    return GridView.builder(
      padding: const EdgeInsets.all(12),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3, childAspectRatio: 0.8, crossAxisSpacing:10, mainAxisSpacing:10),
      itemCount: 18,
      itemBuilder: (_,i)=> Card(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children:[
          Text(['🌹','❤️','🚗','👑','💎','🎤','☕','🦁','🐯','🎸','💍','🏆','✈️','🎁','💰','🔥','⭐','💋'][i], style: const TextStyle(fontSize:32)),
          const SizedBox(height:6),
          Text('هدية ${i+1}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize:12)),
          Text('${[10,50,100,500][i%4]} عملة', style: const TextStyle(color: Colors.orange, fontSize:11)),
        ]),
      ),
    );
  }

  Widget _reportsTab(){
    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: 10,
      itemBuilder: (_,i)=> Card(color
