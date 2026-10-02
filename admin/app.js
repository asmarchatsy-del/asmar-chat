const SUPABASE_URL='https://jojxsqsgmpaggfnnyuyy.supabase.co';
const SUPABASE_KEY='sb_publishable_mC6rnw-HAwJzNu_2d-0A2g_SrEBWyjL';
const db=supabase.createClient(SUPABASE_URL,SUPABASE_KEY);
const $=id=>document.getElementById(id);
async function login(){const {error}=await db.auth.signInWithPassword({email:$('email').value,password:$('password').value});if(error){$('loginMsg').textContent=error.message;return}await boot()}
async function logout(){await db.auth.signOut();location.reload()}
async function boot(){const {data:{user}}=await db.auth.getUser();if(!user){$('login').classList.remove('hidden');$('app').classList.add('hidden');return}const {data:p,error}=await db.from('profiles').select('display_name,role').eq('id',user.id).maybeSingle();if(error||!p||!['CEO','SUPER_ADMIN'].includes(p.role)){await db.auth.signOut();$('loginMsg').textContent=error?.message||'هذا الحساب ليس لديه صلاحية لوحة الإدارة';return}$('login').classList.add('hidden');$('app').classList.remove('hidden');await loadAll()}
function showTab(id){document.querySelectorAll('.tab').forEach(x=>x.classList.add('hidden'));$(id).classList.remove('hidden')}
async function loadAll(){
 const [profiles,wallets,rooms,store,policy]=await Promise.all([
  db.from('profiles').select('id,display_name,username,role,is_active,created_at').order('created_at',{ascending:false}),
  db.from('wallets').select('user_id,balance').order('balance',{ascending:false}),
  db.from('rooms').select('id,name,owner_id,is_active,created_at').order('created_at',{ascending:false}),
  db.from('store_items').select('id,name,category,price_coins,cash_price,currency,description,duration_days,rarity,is_active').order('category').order('price_coins'),
  db.from('asmar_policy').select('level,target,host_base,agent_base,host_total,agent_total').order('level')
 ]);
 const firstError=profiles.error||wallets.error||rooms.error||store.error||policy.error;
 if(firstError){alert(firstError.message);return}
 const ps=profiles.data||[],ws=wallets.data||[],rs=rooms.data||[];
 $('stats').innerHTML=[['المستخدمون',ps.length],['الغرف',rs.filter(r=>r.is_active).length],['إجمالي الكوينز',ws.reduce((a,w)=>a+Number(w.balance||0),0).toLocaleString()],['المضيفون',ps.filter(p=>p.role==='HOST').length]].map(x=>'<div class="stat">'+x[0]+'<strong>'+x[1]+'</strong></div>').join('');
 renderStore(store.data||[]);renderPolicy(policy.data||[]);renderUsers(ps);renderRooms(rs);renderWallets(ws,ps)
}
const labels={FRAME:'إطارات',ENTRY:'دخوليات',ID:'هويات مميزة',CHAT_BUBBLE:'فقاعات دردشة',VOICE_WAVE:'موجات صوت للمايك',VIP:'VIP',SVIP:'SVIP',COINS:'حزم كوينز'};
function renderStore(items){$('storeItems').innerHTML=items.map(x=>'<div class="card"><h3>'+esc(x.name)+'</h3><small>'+esc(labels[x.category]||x.category)+' · '+esc(x.rarity||'NORMAL')+'</small><input id="sc_'+x.id+'" type="number" min="0" value="'+Number(x.price_coins||0)+'" placeholder="سعر الكوينز"><input id="sp_'+x.id+'" type="number" min="0" step="0.01" value="'+Number(x.cash_price||0)+'" placeholder="السعر النقدي بالدولار"><label><input id="sa_'+x.id+'" type="checkbox" '+(x.is_active?'checked':'')+'> فعال</label><button onclick="saveStoreItem(\''+x.id+'\')">حفظ المنتج</button></div>').join('')}
async function saveStoreItem(id){const price_coins=Number($('sc_'+id).value),cash_price=Number($('sp_'+id).value),is_active=$('sa_'+id).checked;const {error}=await db.from('store_items').update({price_coins,cash_price,is_active}).eq('id',id);if(error)alert(error.message);else alert('تم حفظ المنتج')}
function renderPolicy(items){$('policyTable').innerHTML='<table><tr><th>المستوى</th><th>الهدف</th><th>أساس المضيف</th><th>أساس الوكيل</th><th>إجمالي المضيف</th><th>إجمالي الوكيل</th></tr>'+items.map(x=>'<tr><td>'+x.level+'</td><td>'+Number(x.target).toLocaleString()+'</td><td>'+x.host_base+'</td><td>'+x.agent_base+'</td><td>'+x.host_total+'</td><td>'+x.agent_total+'</td></tr>').join('')+'</table>'}
function renderUsers(ps){$('usersTable').innerHTML='<table><tr><th>الاسم</th><th>الدور</th><th>الحالة</th></tr>'+ps.map(p=>'<tr><td>'+esc(p.display_name||p.username||'—')+'</td><td>'+esc(p.role)+'</td><td>'+(p.is_active?'فعال':'موقوف')+'</td></tr>').join('')+'</table>'}
function renderRooms(rs){$('roomsTable').innerHTML='<table><tr><th>الغرفة</th><th>المالك</th><th>الحالة</th></tr>'+rs.map(r=>'<tr><td>'+esc(r.name)+'</td><td>'+esc(r.owner_id||'—')+'</td><td>'+(r.is_active?'نشطة':'مغلقة')+'</td></tr>').join('')+'</table>'}
function renderWallets(ws,ps){const names=Object.fromEntries(ps.map(p=>[p.id,p.display_name||p.username||p.id]));$('walletsTable').innerHTML='<table><tr><th>المستخدم</th><th>الرصيد</th></tr>'+ws.map(w=>'<tr><td>'+esc(names[w.user_id]||w.user_id)+'</td><td>'+Number(w.balance).toLocaleString()+'</td></tr>').join('')+'</table>'}
function esc(v){return String(v??'').replace(/[&<>"']/g,m=>({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&#039;'}[m]))}
db.auth.onAuthStateChange(()=>boot());boot();