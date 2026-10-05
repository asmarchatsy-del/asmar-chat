import 'package:flutter/material.dart';
import '../admin_panel.dart';

class BeelaShell extends StatefulWidget {
  const BeelaShell({super.key});
  @override State<BeelaShell> createState() => _BeelaShellState();
}

class _BeelaShellState extends State<BeelaShell> with SingleTickerProviderStateMixin {
  late TabController _tab;
  int _bottom = 0;
  String _country = 'الكل';
  final _countries = ['الكل','السعودية','مصر','العراق','سوريا','الامارات','تركيا','الجزائر','المغرب','ليبيا'];

  @override
  void initState(){
    super.initState();
    _tab = TabController(length: 4, vsync: this);
  }

  @override
  Widget build(BuildContext context){
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: _bottom==0? AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        title: Row(children:[
          Container(width:34,height:34,decoration:BoxDecoration(gradient: const LinearGradient(colors:[Color(0xFFFF7A00), Color(0xFFFF3D00)]), borderRadius:BorderRadius.circular(10)), child: const Icon(Icons.mic_external_on, color: Colors.white, size:20)),
          const SizedBox(width:10),
          const Text('أسمر شات', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize:18)),
        ]),
        actions:[
          IconButton(onPressed: (){}, icon: const Icon(Icons.search, color: Colors.black87)),
          IconButton(onPressed: (){}, icon: const Icon(Icons.notifications_none_rounded, color: Colors.black87)),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(95),
          child: Column(children:[
            TabBar(
              controller: _tab,
              labelColor: const Color(0xFFFF7A00),
              unselectedLabelColor: Colors.grey,
              indicatorColor: const Color(0xFFFF7A00),
              indicatorWeight: 3,
              tabs: const [
                Tab(text: 'شائع'),
                Tab(text: 'متابع'),
                Tab(text: 'بلدي'),
                Tab(text: 'جديد'),
              ],
            ),
            const SizedBox(height:8),
            SizedBox(height:38, child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal:12),
              itemCount: _countries.length,
              separatorBuilder: (_,__)=>const SizedBox(width:8),
              itemBuilder: (_,i){
                final sel = _countries[i]==_country;
                return ChoiceChip(
                  label: Text(_countries[i], style: TextStyle(fontSize:12, color: sel? const Color(0xFFFF7A00): Colors.black87)),
                  selected: sel,
                  selectedColor: const Color(0xFFFFE9D6),
                  backgroundColor: Colors.white,
                  side: BorderSide(color: sel? const Color(0xFFFF7A00): Colors.grey.shade300),
                  onSelected: (_)=>setState(()=>_country=_countries[i]),
                );
              },
            )),
            const SizedBox(height:8),
          ]),
        ),
      ): null,
      body: _body(),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _bottom,
        onTap: (i)=>setState(()=>_bottom=i),
        type: BottomNavigationBarType.fixed,
        selectedItemColor: const Color(0xFFFF7A00),
        unselectedItemColor: Colors.grey,
        backgroundColor: Colors.white,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_rounded), label: 'الرئيسية'),
          BottomNavigationBarItem(icon: Icon(Icons.slow_motion_video_rounded), label: 'اللحظات'),
          BottomNavigationBarItem(icon: Icon(Icons.chat_bubble_rounded), label: 'الرسائل'),
          BottomNavigationBarItem(icon: Icon(Icons.person_rounded), label: 'أنا'),
        ],
      ),
      floatingActionButton: _bottom==0? FloatingActionButton.extended(
        backgroundColor: const Color(0xFFFF7A00),
        onPressed: (){},
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('انشاء غرفة', style: TextStyle(color: Colors.white)),
      ): null,
    );
  }

  Widget _body(){
    if(_bottom==0){
      return TabBarView(
        controller: _tab,
        children: [
          _yallaGrid('popular'),
          _yallaGrid('following'),
          _yallaGrid('country'),
          _yallaGrid('new'),
        ],
      );
    } else if(_bottom==3){
      return _profileYalla();
    } else {
      return Center(child: Text(_bottom==1?
