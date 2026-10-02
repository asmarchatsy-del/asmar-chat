async function loadBadges(){
  const root=document.getElementById('badgesTable');
  if(!root)return;
  root.innerHTML='<div class="panel">جاري تحميل المستخدمين...</div>';
  const {data,error}=await db.from('profiles')
    .select('id,display_name,username,public_id,role,activity_admin_badge,customer_service_badge,is_verified')
    .order('created_at',{ascending:false});
  if(error){root.innerHTML='<div class="panel">خطأ: '+badgeEsc(error.message)+'</div>';return;}
  const rows=data||[];
  root.innerHTML='<table><tr><th>المستخدم</th><th>ID</th><th>الدور</th><th>ادمن النشاط</th><th>CS</th><th>موثق</th><th>حفظ</th></tr>'+
    rows.map(p=>{
      const name=p.display_name||p.username||'مستخدم';
      return '<tr>'+
        '<td>'+badgeEsc(name)+'</td>'+
        '<td>'+badgeEsc(p.public_id||'—')+'</td>'+
        '<td>'+badgeEsc(p.role||'USER')+'</td>'+
        '<td><input id="ba_'+p.id+'" type="checkbox" '+(p.activity_admin_badge?'checked':'')+'></td>'+
        '<td><input id="bc_'+p.id+'" type="checkbox" '+(p.customer_service_badge?'checked':'')+'></td>'+
        '<td><input id="bv_'+p.id+'" type="checkbox" '+(p.is_verified?'checked':'')+'></td>'+
        '<td><button onclick="saveBadges(\''+p.id+'\')">حفظ</button></td>'+
      '</tr>';
    }).join('')+'</table>';
}
async function saveBadges(id){
  const payload={
    activity_admin_badge:document.getElementById('ba_'+id).checked,
    customer_service_badge:document.getElementById('bc_'+id).checked,
    is_verified:document.getElementById('bv_'+id).checked
  };
  const {error}=await db.from('profiles').update(payload).eq('id',id);
  if(error){alert(error.message);return;}
  alert('تم حفظ الشارات والتوثيق');
}
function badgeEsc(v){
  return String(v??'').replace(/[&<>"']/g,m=>({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&#039;'}[m]));
}
