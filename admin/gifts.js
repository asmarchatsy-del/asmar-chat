async function loadGifts(){
 const root=document.getElementById('giftsTable'); if(!root)return;
 root.innerHTML='<div class="panel">جاري تحميل الهدايا...</div>';
 const {data,error}=await db.from('gifts').select('id,name,emoji,price,category,banner_enabled,banner_min_price,luck_min_win,is_active').order('price');
 if(error){root.innerHTML='<div class="panel">خطأ: '+escGift(error.message)+'</div>';return;}
 root.innerHTML=(data||[]).map(g=>'<div class="card gift-admin"><h3>'+escGift(g.emoji||'🎁')+' '+escGift(g.name)+'</h3><small>'+escGift(g.category||'normal')+' · ID: '+escGift(g.id)+'</small><input id="gn_'+g.id+'" value="'+escGift(g.name)+'" placeholder="اسم الهدية"><input id="ge_'+g.id+'" value="'+escGift(g.emoji||'🎁')+'" placeholder="الإيموجي"><input id="gp_'+g.id+'" type="number" min="1" value="'+Number(g.price||1)+'" placeholder="السعر بالكوين"><input id="gc_'+g.id+'" value="'+escGift(g.category||'normal')+'" placeholder="الفئة"><label><input id="ga_'+g.id+'" type="checkbox" '+(g.is_active?'checked':'')+'> فعالة</label><label><input id="gb_'+g.id+'" type="checkbox" '+(g.banner_enabled?'checked':'')+'> تظهر في شريط الإهداء</label><input id="gm_'+g.id+'" type="number" min="0" value="'+Number(g.banner_min_price||4000)+'" placeholder="حد الشريط بالكوين"><input id="gl_'+g.id+'" type="number" min="0" value="'+Number(g.luck_min_win||3000)+'" placeholder="حد الحظ بالكوين"><button onclick="saveGiftAdmin(\''+g.id+'\')">حفظ الهدية</button></div>').join('');
}
async function saveGiftAdmin(id){
 const price=Number(document.getElementById('gp_'+id).value);
 const bannerMin=Number(document.getElementById('gm_'+id).value);
 const luckMin=Number(document.getElementById('gl_'+id).value);
 if(!Number.isFinite(price)||price<1||bannerMin<0||luckMin<0){alert('قيم الهدية غير صحيحة');return;}
 const payload={
   p_id:id,
   p_name:document.getElementById('gn_'+id).value.trim(),
   p_emoji:document.getElementById('ge_'+id).value.trim()||'🎁',
   p_price:price,
   p_category:document.getElementById('gc_'+id).value.trim()||'normal',
   p_is_active:document.getElementById('ga_'+id).checked,
   p_banner_enabled:document.getElementById('gb_'+id).checked,
   p_banner_min_price:bannerMin,
   p_luck_min_win:luckMin
 };
 const {error}=await db.rpc('admin_update_gift',payload);
 if(error){alert('تعذر حفظ الهدية: '+error.message);return;}
 alert('تم حفظ الهدية بنجاح'); await loadGifts();
}
function escGift(v){return String(v??'').replace(/[&<>"']/g,m=>({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&#039;'}[m]))}
