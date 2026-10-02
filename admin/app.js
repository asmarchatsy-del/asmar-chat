const SUPABASE_URL='https://jojxsqsgmpaggfnnyuyy.supabase.co';
const SUPABASE_KEY='sb_publishable_mC6rnw-HAwJzNu_2d-0A2g_SrEBWyjL';
const db=supabase.createClient(SUPABASE_URL,SUPABASE_KEY);
const $=id=>document.getElementById(id);

async function login(){
  const {error}=await db.auth.signInWithPassword({email:$('email').value.trim(),password:$('password').value});
  if(error){$('loginMsg').textContent=error.message;return}
  await boot();
}
async function logout(){await db.auth.signOut();location.reload()}
async function boot(){
  const {data:{user}}=await db.auth.getUser();
  if(!user){$('login').classList.remove('hidden');$('app').classList.add('hidden');return}
  const {data:p,error}=await db.from('profiles').select('display_name,role,is_active').eq('id',user.id).maybeSingle();
  if(error||!p||!p.is_active||!['CEO','SUPER_ADMIN'].includes(p.role)){
    await db.auth.signOut();
    $('login').classList.remove('hidden');$('app').classList.add('hidden');
    $('loginMsg').textContent=error?.message||'هذا الحساب ليس لديه صلاحية لوحة الإدارة';
    return;
  }
  $('login').classList.add('hidden');$('app').classList.remove('hidden');
  await loadAll();
}
function showTab(id){document.querySelectorAll('.tab').forEach(x=>x.classList.add('hidden'));$(id).classList.remove('hidden')}

async function loadAll(){
  const [profiles,wallets,rooms,frames,packages,vips,policy,promotions]=await Promise.all([
    db.from('profiles').select('id,display_name,username,public_id,role,is_active,created_at,activity_admin_badge,customer_service_badge,is_verified').order('created_at',{ascending:false}),
    db.from('wallets').select('user_id,balance').order('balance',{ascending:false}),
    db.from('rooms').select('id,name,owner_id,is_active,created_at').order('created_at',{ascending:false}),
    db.from('frame_items').select('id,name,style_key,price,is_active').order('price'),
    db.from('coin_packages').select('id,name,coins,price_usd,is_active').order('price_usd'),
    db.from('vip_levels').select('id,animal,image,price_coins,duration_days,is_active').order('price_coins'),
    db.from('asmar_policy').select('level,target,host_base,agent_base,host_total,agent_total').order('level'),
    db.from('app_promotions').select('*').order('created_at',{ascending:false})
  ]);
  const firstError=[profiles,wallets,rooms,frames,packages,vips,policy,promotions].find(x=>x.error);
  if(firstError){alert(firstError.error.message);return}
  const ps=profiles.data||[],ws=wallets.data||[],rs=rooms.data||[];
  $('stats').innerHTML=[['المستخدمون',ps.length],['الغرف النشطة',rs.filter(r=>r.is_active).length],['إجمالي الكوينز',ws.reduce((a,w)=>a+Number(w.balance||0),0).toLocaleString()],['المضيفون',ps.filter(p=>p.role==='HOST').length]].map(x=>'<div class="stat">'+x[0]+'<strong>'+x[1]+'</strong></div>').join('');
  renderStore(frames.data||[],packages.data||[],vips.data||[]);
  renderPolicy(policy.data||[]);renderUsers(ps);renderRooms(rs);renderWallets(ws,ps);renderPromotions(promotions.data||[]);
}

function renderStore(frames,packages,vips){
  const section=(title,items,render)=>'<h3 class="section-title">'+title+'</h3><div class="cards">'+items.map(render).join('')+'</div>';
  $('storeItems').innerHTML=
    section('🖼️ الإطارات',frames,x=>'<div class="card"><h3>'+esc(x.name)+'</h3><small>'+esc(x.style_key)+'</small><input id="fc_'+x.id+'" type="number" min="0" value="'+Number(x.price||0)+'" placeholder="السعر بالكوين"><label><input id="fa_'+x.id+'" type="checkbox" '+(x.is_active?'checked':'')+'> فعال</label><button onclick="saveFrame(\''+x.id+'\')">حفظ</button></div>')+
    section('🪙 حزم الكوينز',packages,x=>'<div class="card"><h3>'+esc(x.name)+'</h3><input id="cc_'+x.id+'" type="number" min="1" value="'+Number(x.coins||0)+'" placeholder="عدد الكوينز"><input id="cp_'+x.id+'" type="number" min="0" step="0.01" value="'+Number(x.price_usd||0)+'" placeholder="السعر بالدولار"><label><input id="ca_'+x.id+'" type="checkbox" '+(x.is_active?'checked':'')+'> فعال</label><button onclick="savePackage(\''+x.id+'\')">حفظ</button></div>')+
    section('👑 VIP / SVIP',vips,x=>'<div class="card"><h3>'+esc(x.id)+' — '+esc(x.animal)+'</h3><small>'+Number(x.duration_days||0)+' يوم</small><input id="vc_'+x.id+'" type="number" min="0" value="'+Number(x.price_coins||0)+'" placeholder="السعر بالكوين"><label><input id="va_'+x.id+'" type="checkbox" '+(x.is_active?'checked':'')+'> فعال</label><button onclick="saveVip(\''+x.id+'\')">حفظ</button></div>');
}
async function saveFrame(id){const {error}=await db.from('frame_items').update({price:Number($('fc_'+id).value),is_active:$('fa_'+id).checked,updated_at:new Date().toISOString()}).eq('id',id);if(error)alert(error.message);else{alert('تم حفظ الإطار');loadAll()}}
async function savePackage(id){const {error}=await db.from('coin_packages').update({coins:Number($('cc_'+id).value),price_usd:Number($('cp_'+id).value),is_active:$('ca_'+id).checked,updated_at:new Date().toISOString()}).eq('id',id);if(error)alert(error.message);else{alert('تم حفظ الحزمة');loadAll()}}
async function saveVip(id){const {error}=await db.from('vip_levels').update({price_coins:Number($('vc_'+id).value),is_active:$('va_'+id).checked,updated_at:new Date().toISOString()}).eq('id',id);if(error)alert(error.message);else{alert('تم حفظ VIP');loadAll()}}

function renderPolicy(items){$('policyTable').innerHTML='<table><tr><th>المستوى</th><th>الهدف</th><th>أساس المضيف</th><th>أساس الوكيل</th><th>إجمالي المضيف</th><th>إجمالي الوكيل</th></tr>'+items.map(x=>'<tr><td>'+x.level+'</td><td>'+Number(x.target).toLocaleString()+'</td><td>'+x.host_base+'</td><td>'+x.agent_base+'</td><td>'+x.host_total+'</td><td>'+x.agent_total+'</td></tr>').join('')+'</table>'}
function renderUsers(ps){$('usersTable').innerHTML='<table><tr><th>الاسم</th><th>ID</th><th>الدور</th><th>الحالة</th><th>إجراء</th></tr>'+ps.map(p=>'<tr><td>'+esc(p.display_name||p.username||'—')+'</td><td><b>'+esc(p.public_id||'—')+'</b></td><td>'+esc(p.role)+'</td><td>'+(p.is_active?'فعال':'موقوف')+'</td><td><button onclick="changePublicId(\''+p.id+'\')">تغيير ID</button> <button onclick="toggleUserActive(\''+p.id+'\','+(!p.is_active)+')">'+(p.is_active?'إيقاف':'تفعيل')+'</button></td></tr>').join('')+'</table>'}
function renderRooms(rs){$('roomsTable').innerHTML='<table><tr><th>الغرفة</th><th>المالك</th><th>الحالة</th><th>إجراء</th></tr>'+rs.map(r=>'<tr><td>'+esc(r.name)+'</td><td>'+esc(r.owner_id||'—')+'</td><td>'+(r.is_active?'نشطة':'مغلقة')+'</td><td><button onclick="toggleRoomActive(\''+r.id+'\','+(!r.is_active)+')">'+(r.is_active?'إغلاق':'تفعيل')+'</button></td></tr>').join('')+'</table>'}
function renderWallets(ws,ps){const names=Object.fromEntries(ps.map(p=>[p.id,p.display_name||p.username||p.id]));$('walletsTable').innerHTML='<table><tr><th>المستخدم</th><th>الرصيد</th><th>تعديل</th></tr>'+ws.map(w=>'<tr><td>'+esc(names[w.user_id]||w.user_id)+'</td><td>'+Number(w.balance||0).toLocaleString()+'</td><td><input id="wa_'+w.user_id+'" type="number" step="1" placeholder="+/- كوين"><button onclick="adjustWallet(\''+w.user_id+'\')">تطبيق</button></td></tr>').join('')+'</table>'}
function esc(v){return String(v??'').replace(/[&<>"']/g,m=>({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&#039;'}[m]))}
function renderPromotions(items){const x=items[0]||{};$('promotionForm').innerHTML='<div class="promo-grid"><input id="ptitle" placeholder="عنوان الحدث" value="'+esc(x.title||'')+'"><input id="psubtitle" placeholder="الوصف" value="'+esc(x.subtitle||'')+'"><input id="pimage" placeholder="رابط صورة البنر" value="'+esc(x.image_url||'')+'"><input id="pbutton" placeholder="نص الزر" value="'+esc(x.button_text||'شارك الآن')+'"><input id="pfirst" placeholder="المركز الأول" value="'+esc(x.first_place||'المركز الأول')+'"><input id="psecond" placeholder="المركز الثاني" value="'+esc(x.second_place||'المركز الثاني')+'"><input id="pthird" placeholder="المركز الثالث" value="'+esc(x.third_place||'المركز الثالث')+'"><input id="pfirstprize" placeholder="جائزة الأول" value="'+esc(x.first_prize||'')+'"><input id="psecondprize" placeholder="جائزة الثاني" value="'+esc(x.second_prize||'')+'"><input id="pthirdprize" placeholder="جائزة الثالث" value="'+esc(x.third_prize||'')+'"><input id="pstart" type="datetime-local" value="'+toLocalInput(x.starts_at)+'"><input id="pend" type="datetime-local" value="'+toLocalInput(x.ends_at)+'"><label><input id="pactive" type="checkbox" '+(x.is_active?'checked':'')+'> الحدث فعال</label></div><button onclick="savePromotion(\''+(x.id||'')+'\')">حفظ الحدث</button>'}
function toLocalInput(v){if(!v)return '';const d=new Date(v);if(Number.isNaN(d.getTime()))return '';const p=n=>String(n).padStart(2,'0');return d.getFullYear()+'-'+p(d.getMonth()+1)+'-'+p(d.getDate())+'T'+p(d.getHours())+':'+p(d.getMinutes())}
async function savePromotion(id){const payload={title:$('ptitle').value.trim(),subtitle:$('psubtitle').value.trim()||null,image_url:$('pimage').value.trim()||null,button_text:$('pbutton').value.trim()||'شارك الآن',first_place:$('pfirst').value.trim()||'المركز الأول',second_place:$('psecond').value.trim()||'المركز الثاني',third_place:$('pthird').value.trim()||'المركز الثالث',first_prize:$('pfirstprize').value.trim()||null,second_prize:$('psecondprize').value.trim()||null,third_prize:$('pthirdprize').value.trim()||null,starts_at:$('pstart').value?new Date($('pstart').value).toISOString():new Date().toISOString(),ends_at:$('pend').value?new Date($('pend').value).toISOString():null,is_active:$('pactive').checked};if(!payload.title){alert('اكتب عنوان الحدث');return}const q=id?db.from('app_promotions').update(payload).eq('id',id):db.from('app_promotions').insert(payload);const {error}=await q;if(error){alert(error.message);return}alert('تم حفظ الحدث');await loadAll()}
async function changePublicId(id){
  const {data:p,error}=await db.from('profiles').select('display_name,username,public_id').eq('id',id).single();
  if(error){alert(error.message);return}
  const value=prompt('ID الجديد للمستخدم '+(p.display_name||p.username||'')+'\\nمثال: HASSAN أو VIP511 أو محمد',p.public_id||'');
  if(value===null)return;
  const next=value.trim();
  if(!next)return;
  const {error:rpcError}=await db.rpc('admin_set_public_id',{p_user_id:id,p_public_id:next});
  if(rpcError){alert(rpcError.message);return}
  await loadAll();
  alert('تم تغيير ID إلى '+next);
}
async function toggleUserActive(id,active){const {error}=await db.rpc('admin_set_user_active',{p_user_id:id,p_active:active});if(error){alert('تعذر تنفيذ العملية: '+error.message);return}await loadAll()}
async function toggleRoomActive(id,active){const {error}=await db.rpc('admin_set_room_active',{p_room_id:id,p_active:active});if(error){alert('تعذر تنفيذ العملية: '+error.message);return}await loadAll()}
async function adjustWallet(id){const amount=Number($('wa_'+id).value);if(!Number.isFinite(amount)||amount===0){alert('أدخل عدد كوينز موجب أو سالب');return}if(!confirm('تأكيد تعديل رصيد الكوين؟'))return;const {data,error}=await db.rpc('admin_adjust_wallet',{p_user_id:id,p_amount:Math.trunc(amount)});if(error){alert('تعذر تعديل الرصيد: '+error.message);return}alert('تم تحديث الرصيد إلى '+Number(data||0).toLocaleString());await loadAll()}
db.auth.onAuthStateChange((event)=>{if(event==='SIGNED_IN'||event==='SIGNED_OUT')boot()});
boot();
