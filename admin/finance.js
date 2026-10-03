let financeCache={recharges:[],withdrawals:[],rechargeMethods:[],withdrawalMethods:[],svip:[],audit:[]};

async function loadFinance(){
  const root=$('financeRoot');
  if(!root)return;
  root.innerHTML='<div class="panel"><p>جاري تحميل الشحن والسحب...</p></div>';
  try{
    const results=await Promise.all([
      db.from('recharge_methods').select('*').order('sort_order').order('created_at',{ascending:false}),
      db.from('withdrawal_methods').select('*').order('sort_order').order('created_at',{ascending:false}),
      db.from('recharge_requests').select('id,user_id,method_id,agent_id,amount,coins,points,details,status,admin_note,created_at').order('created_at',{ascending:false}).limit(100),
      db.from('withdrawal_requests').select('id,user_id,method_id,amount,fee,details,status,admin_note,created_at').order('created_at',{ascending:false}).limit(100),
      db.from('svip_levels').select('*').order('level'),
      db.from('audit_logs').select('*').order('created_at',{ascending:false}).limit(100)
    ]);
    const [rm,wm,rr,wr,sv,audit]=results;
    const fatal=[rm,wm].find(x=>x.error);
    if(fatal)throw fatal.error;
    financeCache={
      rechargeMethods:rm.data||[],withdrawalMethods:wm.data||[],
      recharges:rr.error?[]:(rr.data||[]),withdrawals:wr.error?[]:(wr.data||[]),
      svip:sv.error?[]:(sv.data||[]),audit:audit.error?[]:(audit.data||[])
    };
    renderFinance();
  }catch(e){
    root.innerHTML='<div class="panel"><h3>⚠️ تعذر تحميل الشحن والسحب</h3><p>'+esc(e?.message||String(e))+'</p><button onclick="loadFinance()">إعادة المحاولة</button></div>';
  }
}

function financeName(id){const p=(allUsers||[]).find(x=>x.id===id);return p?(p.display_name||p.username||p.public_id):id||'—'}

function renderFinance(){
  const root=$('financeRoot');if(!root)return;
  root.innerHTML=`
    <div class="module-grid">
      <div class="card"><h3>💳 طرق الشحن</h3><p>إضافة وإدارة طرق الشحن الفعلية.</p><button class="primary" onclick="openRechargeMethodForm()">＋ إضافة طريقة شحن</button><div id="rechargeMethodsList"></div></div>
      <div class="card"><h3>💸 طرق السحب</h3><p>إضافة وإدارة طرق السحب الفعلية.</p><button class="primary" onclick="openWithdrawalMethodForm()">＋ إضافة طريقة سحب</button><div id="withdrawalMethodsList"></div></div>
      <div class="card"><h3>👑 SVIP 1—10</h3><p>حسب نقاط الشحن المعتمدة.</p><div id="svipLevelsList"></div></div>
    </div>
    <div id="financeMethodForm" class="panel hidden"></div>
    <div class="panel"><h3>🪙 طلبات الشحن</h3><div id="rechargeRequestsList"></div></div>
    <div class="panel"><h3>💸 طلبات السحب</h3><div id="withdrawalRequestsList"></div></div>
    <div class="panel"><h3>🧾 سجل العمليات</h3><div id="auditList"></div></div>`;
  renderMethodLists();renderRequests();renderAudit();
}

function renderMethodLists(){
  const r=financeCache.rechargeMethods,w=financeCache.withdrawalMethods;
  $('rechargeMethodsList').innerHTML=r.length?r.map(x=>`<div class="card"><b>${esc(x.name)}</b><small>${esc(x.currency||'USD')} · ${Number(x.coins_per_unit||0).toLocaleString()} كوين/وحدة</small><div>${esc(x.instructions||'')}</div><button onclick="openRechargeMethodForm('${x.id}')">تعديل</button> ${x.is_active?'🟢 فعال':'🔴 متوقف'}</div>`).join(''):'<p>لا توجد طرق شحن.</p>';
  $('withdrawalMethodsList').innerHTML=w.length?w.map(x=>`<div class="card"><b>${esc(x.name)}</b><small>${esc(x.currency||'USD')} · حد ${Number(x.min_amount||0).toLocaleString()}—${Number(x.max_amount||0).toLocaleString()} · رسم ${Number(x.fee||0)}</small><button onclick="openWithdrawalMethodForm('${x.id}')">تعديل</button> ${x.is_active?'🟢 فعال':'🔴 متوقف'}</div>`).join(''):'<p>لا توجد طرق سحب.</p>';
  $('svipLevelsList').innerHTML=financeCache.svip.length?financeCache.svip.map(x=>`<div class="card"><b>SVIP ${x.level}</b><input id="sv_${x.level}" type="number" min="0" value="${Number(x.min_recharge_points||0)}" placeholder="الحد الأدنى لنقاط الشحن"><label><input id="sva_${x.level}" type="checkbox" ${x.is_active?'checked':''}> فعال</label><button onclick="saveSvipThreshold(${x.level})">حفظ</button></div>`).join(''):'<p>لا توجد إعدادات SVIP.</p>';
}

function showFinanceForm(html){const f=$('financeMethodForm');f.classList.remove('hidden');f.innerHTML=html;f.scrollIntoView({behavior:'smooth',block:'start'});}
function openRechargeMethodForm(id){
  const x=financeCache.rechargeMethods.find(v=>v.id===id)||{};
  showFinanceForm(`<h3>💳 ${id?'تعديل':'إضافة'} طريقة شحن</h3><div class="promo-grid">
    <input id="fm_name" placeholder="اسم الطريقة" value="${esc(x.name||'')}">
    <input id="fm_currency" placeholder="العملة" value="${esc(x.currency||'USD')}">
    <input id="fm_min" type="number" min="0" step="0.01" placeholder="أقل مبلغ" value="${Number(x.min_amount||0)}">
    <input id="fm_max" type="number" min="0" step="0.01" placeholder="أقصى مبلغ" value="${Number(x.max_amount||0)}">
    <input id="fm_rate" type="number" min="1" placeholder="كوين لكل وحدة" value="${Number(x.coins_per_unit||10000)}">
    <input id="fm_fields" placeholder='الحقول JSON مثل [{"name":"رقم الحساب"}]' value='${esc(JSON.stringify(x.fields||[]))}'>
    <input id="fm_instructions" placeholder="تعليمات الدفع" value="${esc(x.instructions||'')}">
    <label><input id="fm_active" type="checkbox" ${x.id?(x.is_active?'checked':''): 'checked'}> فعال</label>
  </div><button class="primary" onclick="saveRechargeMethod('${id||''}')">حفظ طريقة الشحن</button> <button class="ghost" onclick="closeFinanceForm()">إلغاء</button>`);
}
function openWithdrawalMethodForm(id){
  const x=financeCache.withdrawalMethods.find(v=>v.id===id)||{};
  showFinanceForm(`<h3>💸 ${id?'تعديل':'إضافة'} طريقة سحب</h3><div class="promo-grid">
    <input id="wm_name" placeholder="اسم الطريقة" value="${esc(x.name||'')}">
    <input id="wm_currency" placeholder="العملة" value="${esc(x.currency||'USD')}">
    <input id="wm_min" type="number" min="0" placeholder="أقل كوين" value="${Number(x.min_amount||0)}">
    <input id="wm_max" type="number" min="0" placeholder="أقصى كوين" value="${Number(x.max_amount||0)}">
    <input id="wm_fee" type="number" min="0" step="0.01" placeholder="الرسم" value="${Number(x.fee||0)}">
    <input id="wm_fields" placeholder='الحقول JSON مثل [{"name":"رقم المحفظة"}]' value='${esc(JSON.stringify(x.fields||[]))}'>
    <label><input id="wm_active" type="checkbox" ${x.id?(x.is_active?'checked':''): 'checked'}> فعال</label>
  </div><button class="primary" onclick="saveWithdrawalMethod('${id||''}')">حفظ طريقة السحب</button> <button class="ghost" onclick="closeFinanceForm()">إلغاء</button>`);
}
function closeFinanceForm(){$('financeMethodForm').classList.add('hidden');}

async function saveRechargeMethod(id){
  const name=$('fm_name').value.trim();if(!name){alert('أدخل اسم طريقة الشحن');return;}
  let fields=[];try{fields=JSON.parse($('fm_fields').value||'[]');if(!Array.isArray(fields))throw new Error('يجب أن تكون الحقول مصفوفة');}catch(e){alert('الحقول JSON غير صحيحة');return;}
  const payload={p_id:id||null,p_name:name,p_currency:$('fm_currency').value.trim()||'USD',p_min:Number($('fm_min').value||0),p_max:Number($('fm_max').value||0),p_coins_per_unit:Math.trunc(Number($('fm_rate').value||0)),p_fields:fields,p_instructions:$('fm_instructions').value.trim()||null,p_active:$('fm_active').checked};
  const {error}=await db.rpc('admin_set_recharge_method',payload);
  if(error){alert('تعذر حفظ طريقة الشحن: '+error.message);return;}
  alert('تم حفظ طريقة الشحن بنجاح');await loadFinance();
}
async function saveWithdrawalMethod(id){
  const name=$('wm_name').value.trim();if(!name){alert('أدخل اسم طريقة السحب');return;}
  let fields=[];try{fields=JSON.parse($('wm_fields').value||'[]');if(!Array.isArray(fields))throw new Error('يجب أن تكون الحقول مصفوفة');}catch(e){alert('الحقول JSON غير صحيحة');return;}
  const payload={p_id:id||null,p_name:name,p_currency:$('wm_currency').value.trim()||'USD',p_min:Math.trunc(Number($('wm_min').value||0)),p_max:Math.trunc(Number($('wm_max').value||0)),p_fee:Number($('wm_fee').value||0),p_fields:fields,p_active:$('wm_active').checked};
  const {error}=await db.rpc('admin_set_withdrawal_method',payload);
  if(error){alert('تعذر حفظ طريقة السحب: '+error.message);return;}
  alert('تم حفظ طريقة السحب بنجاح');await loadFinance();
}
async function saveSvipThreshold(level){
  const n=Math.trunc(Number($('sv_'+level).value));if(!Number.isFinite(n)||n<0){alert('أدخل نقاط صحيحة');return;}
  const {error}=await db.rpc('admin_set_svip_level_config',{p_level:level,p_min_points:n,p_active:$('sva_'+level).checked});
  if(error){alert(error.message);return;}await loadFinance();
}

function renderRequests(){
  const names=id=>esc(financeName(id));
  $('rechargeRequestsList').innerHTML=financeCache.recharges.length?financeCache.recharges.map(r=>`<div class="card"><b>${names(r.user_id)}</b> · ${esc(r.status)}<br>مبلغ: ${r.amount} · كوين: ${Number(r.coins||0).toLocaleString()} · نقاط: ${Number(r.points||0).toLocaleString()}<br><small>${esc(r.created_at||'')}</small> ${r.status==='pending'?`<button onclick="approveRecharge('${r.id}',true)">موافقة</button> <button onclick="approveRecharge('${r.id}',false)">رفض</button>`:''}</div>`).join(''):'<p>لا توجد طلبات شحن.</p>';
  $('withdrawalRequestsList').innerHTML=financeCache.withdrawals.length?financeCache.withdrawals.map(r=>`<div class="card"><b>${names(r.user_id)}</b> · ${esc(r.status)}<br>كوين: ${Number(r.amount||0).toLocaleString()} · رسم: ${r.fee}<br><small>${esc(r.created_at||'')}</small> ${r.status==='pending'?`<button onclick="setWithdrawalStatus('${r.id}','approved')">موافقة</button> <button onclick="setWithdrawalStatus('${r.id}','rejected')">رفض</button>`:''}${r.status==='approved'?`<button onclick="setWithdrawalStatus('${r.id}','paid')">تم الدفع</button>`:''}</div>`).join(''):'<p>لا توجد طلبات سحب.</p>';
}
async function approveRecharge(id,ok){const note=prompt(ok?'ملاحظة الموافقة (اختياري)':'سبب الرفض (اختياري)')||null;const {error}=await db.rpc('admin_approve_recharge',{p_request_id:id,p_approve:ok,p_note:note});if(error){alert(error.message);return;}await loadFinance();await loadAll();}
async function setWithdrawalStatus(id,status){const note=prompt('ملاحظة (اختياري)')||null;const {error}=await db.rpc('admin_set_withdrawal_status',{p_request_id:id,p_status:status,p_note:note});if(error){alert(error.message);return;}await loadFinance();await loadAll();}
function renderAudit(){$('auditList').innerHTML=financeCache.audit.length?financeCache.audit.map(a=>`<div class="card"><b>${esc(a.action||'—')}</b> · ${esc(financeName(a.target_user_id||a.target_id))}<br><small>${esc(a.created_at||'')}</small><br><small>${esc(JSON.stringify(a.metadata||{}))}</small></div>`).join(''):'<p>لا يوجد سجل عمليات.</p>';}
