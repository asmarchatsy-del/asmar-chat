const SUPABASE_URL='https://jojxsqsgmpaggfnnyuyy.supabase.co';
const SUPABASE_KEY='sb_publishable_mC6rnw-HAwJzNu_2d-0A2g_SrEBWyjL';
let db=null;
function showRuntimeError(message){
  const m=document.getElementById('loginMsg');
  if(m) m.textContent=message;
}
window.addEventListener('error',e=>showRuntimeError('خطأ JavaScript: '+(e.message||'خطأ غير معروف')));
window.addEventListener('unhandledrejection',e=>showRuntimeError('خطأ: '+(e.reason?.message||e.reason||'خطأ غير معروف')));
if(typeof supabase==='undefined' || typeof supabase.createClient!=='function'){
  showRuntimeError('مكتبة Supabase لم تُحمّل. أعد فتح الصفحة بعد لحظات.');
}else{
  db=supabase.createClient(SUPABASE_URL,SUPABASE_KEY);
}
const $=id=>document.getElementById(id);

let booting=false;
async function login(){
  const btn=document.querySelector('button[onclick="login()"]');
  const email=$('email').value.trim(), password=$('password').value;
  if(!db){$('loginMsg').textContent='Supabase غير جاهز — أعد تحميل الصفحة.';return}
  if(!email||!password){$('loginMsg').textContent='أدخل البريد الإلكتروني وكلمة المرور.';return}
  if(btn) btn.disabled=true;
  $('loginMsg').textContent='جاري التحقق من الحساب...';
  try{
    const {data,error}=await db.auth.signInWithPassword({email,password});
    if(error){$('loginMsg').textContent='تعذر تسجيل الدخول: '+error.message;return}
    await boot(data?.user);
  }catch(e){$('loginMsg').textContent='حدث خطأ أثناء تسجيل الدخول: '+(e?.message||e)}
  finally{if(btn) btn.disabled=false}
}
async function logout(){await db.auth.signOut();location.reload()}
async function boot(signedUser=null){
  if(booting)return;
  booting=true;
  try{
    $('loginMsg').textContent='';
    const authResult=signedUser?{data:{user:signedUser},error:null}:await db.auth.getUser();
    const user=authResult.data?.user, authError=authResult.error;
    if(authError){$('loginMsg').textContent='خطأ في جلسة الدخول: '+authError.message;$('login').classList.remove('hidden');$('app').classList.add('hidden');return}
    if(!user){$('login').classList.remove('hidden');$('app').classList.add('hidden');return}
    const {data:canAdmin,error}=await db.rpc('admin_can_manage_dashboard');
    if(error){$('loginMsg').textContent='تعذر التحقق من صلاحية لوحة الإدارة: '+error.message;$('login').classList.remove('hidden');$('app').classList.add('hidden');return}
    if(!canAdmin){
      await db.auth.signOut();
      $('loginMsg').textContent='هذا الحساب ليس لديه صلاحية لوحة الإدارة';
      $('login').classList.remove('hidden');$('app').classList.add('hidden');return;
    }
    $('login').classList.add('hidden');$('app').classList.remove('hidden');
    await loadAll();
  }finally{booting=false}
}
function showTab(id,btn){document.querySelectorAll('.tab').forEach(x=>x.classList.add('hidden'));const target=$(id);if(target)target.classList.remove('hidden');document.querySelectorAll('.nav-btn').forEach(x=>x.classList.remove('active'));if(btn)btn.classList.add('active');if(id==='withdrawals'&&typeof loadFinance==='function')loadFinance();if(id==='badges'&&typeof loadBadges==='function')loadBadges()}

async function loadAll(){
  const [profiles,wallets,rooms,frames,packages,vips,policy,promotions,agencies]=await Promise.all([
    db.from('profiles').select('id,display_name,username,public_id,role,is_active,created_at,activity_admin_badge,customer_service_badge,is_verified,recharge_points,svip_level,user_level').order('created_at',{ascending:false}),
    db.from('wallets').select('user_id,balance').order('balance',{ascending:false}),
    db.from('rooms').select('id,name,owner_id,is_active,created_at').order('created_at',{ascending:false}),
    db.from('frame_items').select('id,name,style_key,price,is_active,media_url,media_type,category,vip_level,svip_level,glow_enabled,motion_enabled').order('price'),
    db.from('coin_packages').select('id,name,coins,price_usd,is_active').order('price_usd'),
    db.from('vip_levels').select('id,animal,image,price_coins,duration_days,is_active').order('price_coins'),
    db.from('asmar_policy').select('level,target,host_base,agent_base,host_total,agent_total').order('level'),
    db.from('app_promotions').select('*').order('created_at',{ascending:false}),
    db.from('agencies').select('id,name,manager_id,is_active,created_at').order('created_at',{ascending:false})
  ]);
  const firstError=[profiles,wallets,rooms,frames,packages,vips,policy,promotions,agencies].find(x=>x.error);
  if(firstError){alert(firstError.error.message);return}
  const ps=profiles.data||[],ws=wallets.data||[],rs=rooms.data||[];
  $('stats').innerHTML=[['المستخدمون',ps.length],['الغرف النشطة',rs.filter(r=>r.is_active).length],['إجمالي الكوينز',ws.reduce((a,w)=>a+Number(w.balance||0),0).toLocaleString()],['المضيفون',ps.filter(p=>p.role==='HOST').length]].map(x=>'<div class="stat">'+x[0]+'<strong>'+x[1]+'</strong></div>').join('');
  renderStore(frames.data||[],packages.data||[],vips.data||[]);
  renderPolicy(policy.data||[]);renderUsers(ps);renderRooms(rs);renderWallets(ws,ps);renderPromotions(promotions.data||[]);renderRoles(ps);renderAgencies(agencies.data||[],ps);
  if(typeof loadFinance==='function') await loadFinance();
}

function renderStore(frames,packages,vips){
  const section=(title,items,render)=>'<h3 class="section-title">'+title+'</h3><div class="cards">'+items.map(render).join('')+'</div>';
  $('storeItems').innerHTML=
    section('🖼️ الإطارات الديناميكية',frames,x=>'<div class="card"><h3>'+esc(x.name)+'</h3><small>'+esc(x.style_key||'standard')+' · '+esc(x.category||'standard')+'</small><input id="fc_'+x.id+'" type="number" min="0" value="'+Number(x.price||0)+'" placeholder="السعر بالكوين"><input id="fv_'+x.id+'" placeholder="رابط GIF/الصورة المتحركة" value="'+esc(x.media_url||'')+'"><input id="ff_'+x.id+'" type="file" accept="image/gif,image/png,image/webp,image/jpeg"><label><input id="fg_'+x.id+'" type="checkbox" '+(x.glow_enabled!==false?'checked':'')+'> لمعان</label><label><input id="fm_'+x.id+'" type="checkbox" '+(x.motion_enabled!==false?'checked':'')+'> حركة</label><label><input id="fa_'+x.id+'" type="checkbox" '+(x.is_active?'checked':'')+'> فعال</label><button onclick="saveFrame(\''+x.id+'\')">حفظ</button></div>')+
    section('🪙 حزم الكوينز',packages,x=>'<div class="card"><h3>'+esc(x.name)+'</h3><input id="cc_'+x.id+'" type="number" min="1" value="'+Number(x.coins||0)+'" placeholder="عدد الكوينز"><input id="cp_'+x.id+'" type="number" min="0" step="0.01" value="'+Number(x.price_usd||0)+'" placeholder="السعر بالدولار"><label><input id="ca_'+x.id+'" type="checkbox" '+(x.is_active?'checked':'')+'> فعال</label><button onclick="savePackage(\''+x.id+'\')">حفظ</button></div>')+
    section('👑 VIP 1—10',vips,x=>'<div class="card"><h3>'+esc(x.id)+' — '+esc(x.animal||'VIP')+'</h3><small>'+Number(x.duration_days||0)+' يوم</small><input id="vc_'+x.id+'" type="number" min="0" value="'+Number(x.price_coins||0)+'" placeholder="السعر بالكوين"><input id="vi_'+x.id+'" placeholder="رابط GIF/تصميم VIP" value="'+esc(x.image||'')+'"><input id="vf_'+x.id+'" type="file" accept="image/gif,image/png,image/webp,image/jpeg"><label><input id="va_'+x.id+'" type="checkbox" '+(x.is_active?'checked':'')+'> فعال</label><button onclick="saveVip(\''+x.id+'\')">حفظ</button></div>');
}
async function saveFrame(id){
  let mediaUrl=$('fv_'+id).value.trim()||null; const file=$('ff_'+id).files[0];
  if(file){try{const ext=(file.name.split('.').pop()||'gif').toLowerCase();const path=`frames/${id}/${Date.now()}_${Math.random().toString(36).slice(2)}.${ext}`;const {error}=await db.storage.from('asmar-media').upload(path,file,{upsert:false,contentType:file.type||'image/gif'});if(error)throw error;mediaUrl=db.storage.from('asmar-media').getPublicUrl(path).data.publicUrl;}catch(e){alert('تعذر رفع الإطار: '+e.message);return;}}
  const {error}=await db.from('frame_items').update({price:Number($('fc_'+id).value),media_url:mediaUrl,media_type:file?.type||'gif',glow_enabled:$('fg_'+id).checked,motion_enabled:$('fm_'+id).checked,is_active:$('fa_'+id).checked,updated_at:new Date().toISOString()}).eq('id',id);
  if(error)alert(error.message);else{alert('تم حفظ الإطار');loadAll()}
}
async function savePackage(id){const {error}=await db.from('coin_packages').update({coins:Number($('cc_'+id).value),price_usd:Number($('cp_'+id).value),is_active:$('ca_'+id).checked,updated_at:new Date().toISOString()}).eq('id',id);if(error)alert(error.message);else{alert('تم حفظ الحزمة');loadAll()}}
async function saveVip(id){
  let image=$('vi_'+id).value.trim()||null; const file=$('vf_'+id).files[0];
  if(file){try{const ext=(file.name.split('.').pop()||'gif').toLowerCase();const path=`vip/${id}/${Date.now()}_${Math.random().toString(36).slice(2)}.${ext}`;const {error}=await db.storage.from('asmar-media').upload(path,file,{upsert:false,contentType:file.type||'image/gif'});if(error)throw error;image=db.storage.from('asmar-media').getPublicUrl(path).data.publicUrl;}catch(e){alert('تعذر رفع تصميم VIP: '+e.message);return;}}
  const {error}=await db.from('vip_levels').update({price_coins:Number($('vc_'+id).value),image,is_active:$('va_'+id).checked,updated_at:new Date().toISOString()}).eq('id',id);
  if(error)alert(error.message);else{alert('تم حفظ VIP');loadAll()}
}

function renderPolicy(items){$('policyTable').innerHTML='<table><tr><th>المستوى</th><th>الهدف</th><th>أساس المضيف</th><th>أساس الوكيل</th><th>إجمالي المضيف</th><th>إجمالي الوكيل</th></tr>'+items.map(x=>'<tr><td>'+x.level+'</td><td>'+Number(x.target).toLocaleString()+'</td><td>'+x.host_base+'</td><td>'+x.agent_base+'</td><td>'+x.host_total+'</td><td>'+x.agent_total+'</td></tr>').join('')+'</table>'}
let allUsers=[];
function renderUsers(ps){allUsers=ps||[]; drawUsers(allUsers);}
function drawUsers(ps){
  $('usersTable').innerHTML='<table><tr><th>المستخدم</th><th>ID</th><th>الدور</th><th>الحالة</th><th>إجراءات</th></tr>'+
  ps.map(p=>'<tr><td>'+esc(p.display_name||p.username||'—')+'<br><small>'+esc(p.username||'')+'</small></td><td><b>'+esc(p.public_id||'—')+'</b></td><td>'+esc(p.role||'USER')+'</td><td>'+(p.is_active?'🟢 فعال':'🔴 موقوف')+'</td><td><button onclick="openUserActions(\''+p.id+'\')">إدارة المستخدم</button></td></tr>').join('')+'</table>';
}
function filterUsers(){
  const q=$('userSearch').value.trim().toLowerCase();
  if(!q){drawUsers(allUsers);return}
  const rows=allUsers.filter(p=>[p.public_id,p.display_name,p.username,p.id,p.role].some(v=>String(v||'').toLowerCase().includes(q)));
  drawUsers(rows);
}
function clearUserSearch(){ $('userSearch').value=''; $('userActions').classList.add('hidden'); drawUsers(allUsers); }
function openUserActions(id){
  const p=allUsers.find(x=>x.id===id); if(!p)return;
  const root=$('userActions'); root.classList.remove('hidden');
  root.innerHTML='<div style="display:flex;justify-content:space-between;gap:12px;align-items:center"><div><h3>إدارة: '+esc(p.display_name||p.username||'مستخدم')+'</h3><p>ID: <b>'+esc(p.public_id||'—')+'</b> · الدور: '+esc(p.role||'USER')+'</p></div><button class="ghost" onclick="$(&quot;userActions&quot;).classList.add(&quot;hidden&quot;)">إغلاق</button></div>'+
  '<div class="module-grid">'+
  '<div class="card"><h3>👑 VIP</h3><select id="uaVip"><option value="">اختر VIP</option>'+['VIP1','VIP2','VIP3','VIP4','VIP5','VIP6','VIP7','VIP8','VIP9','VIP10'].map(v=>'<option value="'+v+'" '+(p.vip_level===v?'selected':'')+'>'+v+'</option>').join('')+'</select><button onclick="grantVipToUser(\''+p.id+'\')">إهداء VIP</button></div>'+
  '<div class="card"><h3>🆔 ID مميز</h3><input id="uaPublicId" value="'+esc(p.public_id||'')+'" placeholder="مثال VIP511"><button onclick="setSpecialId(\''+p.id+'\')">حفظ ID المميز</button></div>'+
  '<div class="card"><h3>🏅 الشارات</h3><label><input id="uaVerified" type="checkbox" '+(p.is_verified?'checked':'')+'> موثق</label><label><input id="uaActivity" type="checkbox" '+(p.activity_admin_badge?'checked':'')+'> أدمن نشاط</label><label><input id="uaCS" type="checkbox" '+(p.customer_service_badge?'checked':'')+'> خدمة عملاء</label><button onclick="saveUserBadges(\''+p.id+'\')">حفظ الشارات</button></div>'+
  '<div class="card"><h3>⚠️ تحذير</h3><input id="uaWarning" placeholder="سبب التحذير"><button onclick="warnUser(\''+p.id+'\')">إضافة تحذير</button></div>'+
  '<div class="card"><h3>🪙 كوينز</h3><input id="uaCoins" type="number" placeholder="+ أو - كوين"><button onclick="adjustUserCoins(\''+p.id+'\')">تطبيق</button></div>'+
  '<div class="card"><h3>🚦 الحساب</h3><button onclick="toggleUserActive(\''+p.id+'\','+(!p.is_active)+')">'+(p.is_active?'إيقاف الحساب':'تفعيل الحساب')+'</button></div>'+
  '<div class="card"><h3>📈 المستوى 1—150</h3><p>الرفع اليدوي متاح للـCEO فقط.</p><button onclick="raiseUserLevel(\''+p.id+'\')">تغيير المستوى</button></div>'+
  '</div>';
}
async function grantVipToUser(id){const v=$('uaVip').value;if(!v){alert('اختر مستوى VIP');return}if(!confirm('تأكيد إهداء '+v+' لهذا المستخدم؟'))return;const {error}=await db.rpc('admin_grant_vip',{p_user_id:id,p_vip_level:v});if(error){alert('تعذر إهداء VIP: '+error.message);return}alert('تم إهداء '+v);await loadAll();openUserActions(id);}
async function setSpecialId(id){const v=$('uaPublicId').value.trim();if(!v){alert('أدخل ID');return}const {error}=await db.rpc('admin_set_public_id',{p_user_id:id,p_public_id:v});if(error){alert('تعذر حفظ ID: '+error.message);return}alert('تم حفظ ID المميز');await loadAll();openUserActions(id);}
async function raiseUserLevel(id){
  const current=(allUsers.find(u=>u.id===id)||{}).user_level||1;
  const value=prompt('أدخل الليفل الجديد للمستخدم:',current);
  if(value===null)return;
  const level=Math.trunc(Number(value));
  if(!Number.isInteger(level)||level<1||level>150){alert('الليفل يجب أن يكون بين 1 و150');return}
  const {error}=await db.rpc('admin_set_user_level',{p_user_id:id,p_level:level});
  if(error){alert(error.message);return}
  alert('تم رفع لفل المستخدم إلى '+level);
  await loadAll();
}
async function saveUserBadges(id){const {error}=await db.from('profiles').update({is_verified:$('uaVerified').checked,activity_admin_badge:$('uaActivity').checked,customer_service_badge:$('uaCS').checked}).eq('id',id);if(error){alert('تعذر حفظ الشارات: '+error.message);return}alert('تم حفظ الشارات');await loadAll();openUserActions(id);}
async function warnUser(id){const reason=$('uaWarning').value.trim();if(!reason){alert('اكتب سبب التحذير');return}const {error}=await db.rpc('admin_warn_user',{p_user_id:id,p_reason:reason});if(error){alert('تعذر إضافة التحذير: '+error.message);return}alert('تم تسجيل التحذير');$('uaWarning').value='';}
async function adjustUserCoins(id){const n=Math.trunc(Number($('uaCoins').value));if(!Number.isFinite(n)||n===0){alert('أدخل قيمة كوين صحيحة');return}if(!confirm('تأكيد تعديل رصيد المستخدم؟'))return;const {error}=await db.rpc('admin_adjust_wallet',{p_user_id:id,p_amount:n});if(error){alert('تعذر تعديل الكوينز: '+error.message);return}alert('تم تعديل الرصيد');$('uaCoins').value='';await loadAll();openUserActions(id);}

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
db.auth.onAuthStateChange((event)=>{if(event==='SIGNED_OUT')boot()});
boot();

function renderRoles(ps){
 $('rolesTable').innerHTML='<table><tr><th>المستخدم</th><th>ID</th><th>الدور</th></tr>'+ps.filter(p=>p.role&&p.role!=='USER').map(p=>'<tr><td>'+esc(p.display_name||p.username||'—')+'</td><td>'+esc(p.public_id||'—')+'</td><td><b>'+esc(p.role)+'</b></td></tr>').join('')+'</table>';
}
function setSelectedRole(){
 const q=$('roleUserSearch').value.trim().toLowerCase(), p=allUsers.find(x=>[x.public_id,x.username,x.display_name,x.id].some(v=>String(v||'').toLowerCase()===q));
 if(!p){alert('لم يتم العثور على المستخدم بالـID أو الاسم المطابق');return}
 const role=$('roleSelect').value;
 if(!confirm('تعيين '+role+' للمستخدم '+(p.display_name||p.username)+'؟'))return;
 db.rpc('admin_set_user_role',{p_user_id:p.id,p_role:role}).then(async ({error})=>{if(error){alert('تعذر تغيير الدور: '+error.message);return}alert('تم تعيين '+role);await loadAll();});
}
function renderAgencies(items,ps){
 const names=Object.fromEntries(ps.map(p=>[p.id,p.display_name||p.username||p.public_id||p.id]));
 $('agenciesTable').innerHTML='<table><tr><th>الوكالة</th><th>المدير</th><th>الحالة</th><th>إضافة عضو</th></tr>'+items.map(a=>'<tr><td><b>'+esc(a.name)+'</b></td><td>'+esc(names[a.manager_id]||a.manager_id||'—')+'</td><td>'+(a.is_active?'🟢 فعالة':'🔴 موقوفة')+'</td><td><input id="am_'+a.id+'" placeholder="ID المستخدم"><select id="ar_'+a.id+'"><option>AGENT</option><option>HOST</option></select><button onclick="addAgencyMember(\''+a.id+'\')">إضافة</button></td></tr>').join('')+'</table>';
}
async function createAgency(){
 const name=$('agencyName').value.trim(), q=$('agencyManager').value.trim().toLowerCase();
 const p=allUsers.find(x=>[x.public_id,x.username,x.display_name,x.id].some(v=>String(v||'').toLowerCase()===q));
 if(!name){alert('اكتب اسم الوكالة');return} if(q&&!p){alert('مدير الوكالة غير موجود');return}
 const {error}=await db.rpc('admin_create_agency',{p_name:name,p_manager_id:p?.id||null});
 if(error){alert('تعذر إنشاء الوكالة: '+error.message);return}
 alert('تم إنشاء وكالة الشحن');$('agencyName').value='';$('agencyManager').value='';await loadAll();
}
async function addAgencyMember(aid){
 const q=$('am_'+aid).value.trim().toLowerCase(), p=allUsers.find(x=>[x.public_id,x.username,x.display_name,x.id].some(v=>String(v||'').toLowerCase()===q));
 if(!p){alert('المستخدم غير موجود');return}
 const role=$('ar_'+aid).value, {error}=await db.rpc('admin_add_agency_member',{p_agency_id:aid,p_user_id:p.id,p_role:role});
 if(error){alert('تعذر إضافة العضو: '+error.message);return}
 alert('تمت إضافة '+(p.display_name||p.username)+' إلى الوكالة');
}
