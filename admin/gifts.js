async function loadGifts(){
 const root=document.getElementById('giftsTable'); if(!root)return;
 root.innerHTML='<div class="panel">جاري تحميل الهدايا...</div>';
 const {data,error}=await db.from('gifts').select('id,name,emoji,price,category,banner_enabled,banner_min_price,luck_min_win,is_active').order('price');
 if(error){root.innerHTML='<div class="panel">خطأ: '+escGift(error.message)+'</div>';return;}
 root.innerHTML=(data||[]).map(g=>'<div class="card gift-admin"><h3>'+escGift(g.emoji||'🎁')+' '+escGift(g.name)+'</h3><small>'+escGift(g.category||'normal')+' · ID: '+escGift(g.id)+'</small><input id="gn_'+g.id+'" value="'+escGift(g.name)+'" placeholder="اسم الهدية"><input id="ge_'+g.id+'" value="'+escGift(g.emoji||'🎁')+'" placeholder="الإيموجي"><input id="gp_'+g.id+'" type="number" min="1" value="'+Number(g.price||1)+'" placeholder="السعر بالكوين"><input id="gc_'+g.id+'" value="'+escGift(g.category||'normal')+'" placeholder="الفئة"><label><input id="ga_'+g.id+'" type="checkbox" '+(g.is_active?'checked':'')+'> فعالة</label><label><input id="gb_'+g.id+'" type="checkbox" '+(g.banner_enabled?'checked':'')+'> تظهر في شريط الإهداء</label><input id="gm_'+g.id+'" type="number" min="0" value="'+Number(g.banner_min_price||4000)+'" placeholder="حد الشريط بالكوين"><input id="gl_'+g.id+'" type="number" min="0" value="'+Number(g.luck_min_win||3000)+'" placeholder="حد الحظ بالكوين"><button onclick="saveGiftAdmin(\''+g.id+'\')">حفظ الهدية</button></div>').join('');
}
function openGiftCreate(){
 const root=document.getElementById('giftCreate'); if(!root)return;
 root.classList.remove('hidden');
 root.innerHTML='<div class="promo-grid"><input id="newGiftName" placeholder="اسم الهدية"><input id="newGiftEmoji" placeholder="الإيموجي" value="🎁"><input id="newGiftPrice" type="number" min="1" placeholder="السعر بالكوين"><input id="newGiftCategory" placeholder="الفئة" value="normal"><input id="newGiftBannerMin" type="number" min="0" placeholder="حد شريط الإهداء" value="4000"><input id="newGiftLuckMin" type="number" min="0" placeholder="حد الحظ" value="3000"><label><input id="newGiftActive" type="checkbox" checked> فعالة</label><label><input id="newGiftBanner" type="checkbox"> تظهر في شريط الإهداء</label></div><div style="display:flex;gap:8px;margin-top:12px"><button class="primary" onclick="createGiftAdmin()">حفظ الهدية الجديدة</button><button class="ghost" onclick="document.getElementById(\'giftCreate\').classList.add(\'hidden\')">إلغاء</button></div>';
}
async function createGiftAdmin(){
 const name=document.getElementById('newGiftName').value.trim();
 const emoji=document.getElementById('newGiftEmoji').value.trim()||'🎁';
 const price=Number(document.getElementById('newGiftPrice').value);
 const category=document.getElementById('newGiftCategory').value.trim()||'normal';
 const bannerMin=Number(document.getElementById('newGiftBannerMin').value||0);
 const luckMin=Number(document.getElementById('newGiftLuckMin').value||0);
 if(!name||!Number.isFinite(price)||price<1){alert('أدخل اسم الهدية وسعرًا صحيحًا');return;}
 const {data:existing}=await db.from('gifts').select('id').eq('name',name).maybeSingle();
 if(existing){alert('يوجد بالفعل هدية بهذا الاسم');return;}
 const {error}=await db.from('gifts').insert({name,emoji,price,category,is_active:document.getElementById('newGiftActive').checked,banner_enabled:document.getElementById('newGiftBanner').checked,banner_min_price:bannerMin,luck_min_win:luckMin});
 if(error){alert('تعذر إضافة الهدية: '+error.message);return;}
 alert('تمت إضافة الهدية بنجاح');
 document.getElementById('giftCreate').classList.add('hidden');
 await loadGifts();
}
async function saveGiftAdmin(id){
 const price=Number(document.getElementById('gp_'+id).value);
 const bannerMin=Number(document.getElementById('gm_'+id).value);
 const luckMin=Number(document.getElementById('gl_'+id).value);
 if(!Number.isFinite(price)||price<1||bannerMin<0||luckMin<0){alert('قيم الهدية غير صحيحة');return;}
 const payload={p_id:id,p_name:document.getElementById('gn_'+id).value.trim(),p_emoji:document.getElementById('ge_'+id).value.trim()||'🎁',p_price:price,p_category:document.getElementById('gc_'+id).value.trim()||'normal',p_is_active:document.getElementById('ga_'+id).checked,p_banner_enabled:document.getElementById('gb_'+id).checked,p_banner_min_price:bannerMin,p_luck_min_win:luckMin};
 const {error}=await db.rpc('admin_update_gift',payload);
 if(error){alert('تعذر حفظ الهدية: '+error.message);return;}
 alert('تم حفظ الهدية بنجاح'); await loadGifts();
}
function escGift(v){return String(v??'').replace(/[&<>\"']/g,m=>({'&':'&amp;','<':'&lt;','>':'&gt;','\"':'&quot;',"'":'&#039;'}[m]))}
