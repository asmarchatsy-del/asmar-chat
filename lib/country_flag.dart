import 'package:flutter/material.dart';
import 'dart:math' as math;

const countryNames = <String,String>{
  'SY':'سوريا','US':'الولايات المتحدة','TR':'تركيا','LB':'لبنان','JO':'الأردن','IQ':'العراق','SA':'السعودية','AE':'الإمارات','EG':'مصر','DE':'ألمانيا','FR':'فرنسا','GB':'بريطانيا','CA':'كندا','AU':'أستراليا','SE':'السويد','NL':'هولندا','BE':'بلجيكا','IT':'إيطاليا','ES':'إسبانيا','RU':'روسيا','UA':'أوكرانيا','PS':'فلسطين','KW':'الكويت','QA':'قطر','BH':'البحرين','OM':'عُمان','MA':'المغرب','DZ':'الجزائر','TN':'تونس','LY':'ليبيا','SD':'السودان','YE':'اليمن','IN':'الهند','PK':'باكستان','BD':'بنغلاديش','ID':'إندونيسيا','MY':'ماليزيا','BR':'البرازيل','MX':'المكسيك','AR':'الأرجنتين','CL':'تشيلي','CN':'الصين','JP':'اليابان','KR':'كوريا الجنوبية',
};

String flagEmoji(String code){
  final c=code.toUpperCase();
  if(c=='SY') return '🇸🇾';
  if(c.length!=2) return '🌐';
  return String.fromCharCodes(c.codeUnits.map((u)=>0x1F1E6+u-65));
}

class CountryFlag extends StatelessWidget{
  final String? code;
  final double size;
  const CountryFlag({super.key,required this.code,this.size=24});
  @override Widget build(BuildContext context){
    if((code??'').toUpperCase()=='SY'){
      return SizedBox(width:size*1.35,height:size*.9,child:ClipRRect(borderRadius:BorderRadius.circular(size*.12),child:CustomPaint(painter:_SyriaFlagPainter())));
    }
    return Text(flagEmoji(code??''),style:TextStyle(fontSize:size));
  }
}
class _SyriaFlagPainter extends CustomPainter{
  @override void paint(Canvas canvas,Size s){
    final p=Paint();
    p.color=const Color(0xFF007A3D);canvas.drawRect(Rect.fromLTWH(0,0,s.width,s.height/3),p);
    p.color=Colors.white;canvas.drawRect(Rect.fromLTWH(0,s.height/3,s.width,s.height/3),p);
    p.color=const Color(0xFF000000);canvas.drawRect(Rect.fromLTWH(0,s.height*2/3,s.width,s.height/3),p);
    p.color=const Color(0xFFCE1126);
    final cy=s.height/2;final r=s.height*.12;
    _star(canvas,Offset(s.width*.38,cy),r,p);_star(canvas,Offset(s.width*.62,cy),r,p);
  }
  void _star(Canvas c,Offset o,double r,Paint p){
    final path=Path();
    for(int i=0;i<10;i++){final a=-3.14159/2+i*3.14159/5;final rr=i.isEven?r:r*.4;final pt=Offset(o.dx+rr*mathCos(a),o.dy+rr*mathSin(a));if(i==0)path.moveTo(pt.dx,pt.dy);else path.lineTo(pt.dx,pt.dy);}
    path.close();c.drawPath(path,p);
  }
  double mathCos(double a)=>math.cos(a); double mathSin(double a)=>math.sin(a);
  @override bool shouldRepaint(covariant CustomPainter oldDelegate)=>false;
}
