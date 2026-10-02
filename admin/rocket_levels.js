async function loadRocketLevels(){
  const {data,error}=await db.from('rocket_levels').select('id,name,coins,is_active').order('id');
  if(error){$('rocketLevelsTable').innerHTML='<p>'+esc(error.message)+'</p>';return;}
  $('rocketLevelsTable').innerHTML='<table><tr><th>LV</th><th>الاسم</th><th>كوين TOP 1</th><th>فعال</th><th>حفظ</th></tr>'+data.map(x=>'<tr><td>'+x.id+'</td><td>'+esc(x.name)+'</td><td><input id="rocket_'+x.id+'" type="number" min="0" value="'+Number(x.coins||0)+'"></td><td>'+(x.is_active?'نعم':'لا')+'</td><td><button onclick="saveRocketLevel('+x.id+')">حفظ</button></td></tr>').join('')+'</table>';
}
async function saveRocketLevel(id){
  const coins=Number($('rocket_'+id).value);
  if(!Number.isFinite(coins)||coins<0){alert('قيمة الكوين غير صحيحة');return;}
  const {error}=await db.from('rocket_levels').update({coins,updated_at:new Date().toISOString()}).eq('id',id);
  if(error){alert(error.message);return;}
  alert('تم حفظ كوين LV.'+id);loadRocketLevels();
}
