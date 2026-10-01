const SUPABASE_URL='https://jojxsqsgmpaggfnnyuyy.supabase.co';
const SUPABASE_KEY='sb_publishable_mC6rnw-HAwJzNu_2d-0A2g_SrEBWyjL';
const db=supabase.createClient(SUPABASE_URL,SUPABASE_KEY);
const $=id=>document.getElementById(id);
async function login(){const {error}=await db.auth.signInWithPassword({email:$('email').value,password:$('password').value});if(error){$('loginMsg').textContent=error.message;return}await boot()}
async function logout(){await db.auth.signOut();location.reload()}
async function boot(){const {data:{user}}=await db.auth.getUser();if(!user){$('login').classList.remove('hidden');$('app').classList.add('hidden');return}const {data:p}=await db.from('profiles').select('display_name,role').eq('id',user.id).maybeSingle();if(!p||!['CEO','SUPER_ADMIN'].includes(p.role)){await db.auth.signOut();$('loginMsg').textContent='هذا الحساب ليس لديه صلاحية لوحة الإدارة';return}$('login').classList.add('hidden');$('app').classList.remove('hidden');await loadAll()}
function showTab(id){document.querySelectorAll('.tab').forEach(x=>x.classList.add('hidden'));$(id).classList.remove('hidden')}
async function loadAll(){const [profiles, wallets, rooms, frames, packages]=await Promise.all([
 db.from('profiles').select('id,display_name,username,role,is_active,created_at').order('created_at',{ascending:false}),
 db.from('wallets').select('user_id,balance').order('balance',{ascending:false}),
 db.from('rooms').select('id,name,owner_id,is_active,created_at').order('created_at',{ascending:false}),
 db.from('frame_items').select('id,name,price,style_key,is_active').order('price'),
 db.from('coin_packages').select('id,name,coins,price_usd,is_active').order('coins')]);
if(profiles.error||wallets.error||rooms.error||frames.error||packages.error){alert((profiles.error||wallets.error||rooms.error||frames.error||packages.error).message);return}
const ps=profiles.data||[], ws=wallets.data||[], rs=rooms.data||[];
$('stats').innerHTML=[['المستخدمون',ps.length],['الغرف',rs.filter(r=>r.is_active).length],['إجمالي الكوينز',ws.reduce((a,w)=>a+Number(w.balance||0),0)],['المضيفون',ps.filter(p=>p.role==='HOST').length]].map(x=>'<div class="stat">'+x[0]+'<strong>'+x[1]+'</strong></div>').join('');
renderFrames(frames.data||[]);renderPackages(packages.data||[]);renderUsers(ps);renderRooms(rs);renderWallets(ws,ps)}
function renderFrames(items){$('frames').innerHTML=items.map(x=>'<div class="card"><h3>'+esc(x.name)+'</h3><small>'+esc(x.style_key)+'</small><input id="f_'+x.id+'" type="number" min="0" value="'+x.price+'"><label><input id="fa_'+x.id+'" type="checkbox" '+(x.is_active?'checked':'')+'> فعال</label><button onclick="saveFrame(\''+x.id+'\')">حفظ السعر</button></div>').join('')}
async function saveFrame(id){const price=Number($('f_'+id).value);const active=$('fa_'+id).checked;const {error}=await db.from('frame_items').update({price,is_active:active}).eq('id',id);if(error)alert(error.message);else alert('تم حفظ السعر')}
function renderPackages(items){$('packages').innerHTML=items.map(x=>'<div class="card"><h3>'+esc(x.name)+'</h3><input id="c_'+x.id+'" type="number" min="1" value="'+x.coins+'"><input id="p_'+x.id+'" type="number" min="0" step="0.01" value="'+x.price_usd+'"><label><input id="ca_'+x.id+'" type="checkbox" '+(x.is_active?'checked':'')+'> فعال</label><button onclick="savePackage(\''+x.id+'\')">حفظ الحزمة</button></div>').join('')}
async function savePackage(id){const coins=Number($('c_'+id).value),price_usd=Number($('p_'+id).value),is_active=$('ca_'+id).checked;const {error}=await db.from('coin_packages').update({coins,price_usd,is_active}).eq('id',id);if(error)alert(error.message);else alert('تم حفظ الحزمة')}
function renderUsers(ps){$('usersTable').innerHTML='<table><tr><th>الاسم</th><th>الدور</th><th>الحالة</th></tr>'+ps.map(p=>'<tr><td>'+esc(p.display_name||p.username||'—')+'</td><td>'+p.role+'</td><td>'+(p.is_active?'فعال':'موقوف')+'</td></tr>').join('')+'</table>'}
function renderRooms(rs){$('roomsTable').innerHTML='<table><tr><th>الغرفة</th><th>المالك</th><th>الحالة</th></tr>'+rs.map(r=>'<tr><td>'+esc(r.name)+'</td><td>'+esc(r.owner_id||'—')+'</td><td>'+(r.is_active?'نشطة':'مغلقة')+'</td></tr>').join('')+'</table>'}
function renderWallets(ws,ps){const names=Object.fromEntries(ps.map(p=>[p.id,p.display_name||p.username||p.id]));$('walletsTable').innerHTML='<table><tr><th>المستخدم</th><th>الرصيد</th></tr>'+ws.map(w=>'<tr><td>'+esc(names[w.user_id]||w.user_id)+'</td><td>'+Number(w.balance).toLocaleString()+'</td></tr>').join('')+'</table>'}
function esc(v){return String(v??'').replace(/[&<>"']/g,m=>({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&#039;'}[m]))}
db.auth.onAuthStateChange(()=>boot());boot();