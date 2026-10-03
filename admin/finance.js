let financeCache={recharges:[],withdrawals:[],rechargeMethods:[],withdrawalMethods:[],svip:[]};
async function loadFinance(){
  const [rm,wm,rr,wr,sv,audit]=await Promise.all([
    db.from('recharge_methods').select('*').order('sort_order').order('created_at',{ascending:false}),
    db.from('withdrawal_methods').select('*').order('sort_order').order('created_at',{ascending:false}),
    db.from('recharge_requests').select('id,user_id,method_id,agent_id,amount,coins,points,details,status,admin_note,created_at').order('created_at',{ascending:false}).limit(100),
    db.from('withdrawal_requests').select('id,user_id,method_id,amount,fee,details,status,admin_note,created_at').order('created_at',{ascending:false}).limit(100),
    db.from('svip_levels').select('*').order('level'),
    db.from('audit_logs').select('*').order('created_at',{ascending:false}).limit(100)
  ]);
  const root=$('financeRoot');
  const errors=[rm,wm,rr,wr,sv,audit].filter(x=>x&&x.error);
  if(errors.length) console.warn('loadFinance partial errors',errors.map(x=>x.error));
  if(root && rm.error && wm.error){
    root.innerHTML='<div class="panel"><h3>⚠️ تعذر تحميل طرق الشحن والسحب</h3><p>'+esc(rm.error?.message||wm.error?.message||'خطأ غير معروف')+'</p><button onclick="loadFinance()">إعادة المحاولة</button></div>';
    return;
  }
  financeCache={
    rechargeMethods:rm.error?[]:(rm.data||[]),
    withdrawalMethods:wm.error?[]:(wm.data||[]),
    recharges:rr.error?[]:(rr.data||[]),
    withdrawals:wr.error?[]:(wr.data||[]),
    svip:sv.error?[]:(sv.data||[]),
    audit:audit.error?[]:(audit.data||[])
  };
  renderFinance();
}
function financeName(id){const p=allUsers.find(x=>x.id===id);return p?(p.display_name||p.username||p.public_id):id||'—'}
function renderFinance(){
  const root=$('financeRoot');if(!root)return;
  const f=financeCache;
  root.innerHTML=
  '<div class="module-grid">'+
  '<div class="card"><h3>💳 طرق الشحن</h3><p>هذه أصبحت مرتبطة بقاعدة البيانات.</p><button onclick="openRechargeMethodForm()">＋ إضافة طريقة شحن</button><div id="rechargeMethodsList"></div></div>'+
  '<div class="card"><h3>💸 طرق السحب</h3><p>إضافة الطريقة والعملة والحدود والحقول.</p><button onclick="openWithdrawalMethodForm()">＋ إضافة طريقة سحب</button><div id="withdrawalMethodsList"></div></div>'+
  '<div class="card"><h3>👑 SVIP 1—10</h3><p>المستوى يتحدد تلقائياً من نقاط الشحن المعتمدة.</p><div id="svipLevelsList"></div></div>'+
  '</div>'+
  '<div id="financeMethodForm" class="panel hidden"></div>'+
  '<div class="panel"><h3>🪙 طلبات الشحن</h3><div id="rechargeRequestsList"></div></div>'+
  '<div class="panel"><h3>💸 طلبات السحب</h3><div id="withdrawalRequestsList"></div></div>'+
  '<div class="panel"><h3>🧾 سجل العمليات</h3><div id="auditList"></div></div>';
  renderMethodLists();renderRequests();renderAudit();renderGlobalAuditTab(financeCache.audit||[]);
}
function renderMethodLists(){
 const r=financeCache.rechargeMethods,w=financeCache.withdrawalMethods;
 $('rechargeMethodsList').innerHTML=r.map(x=>'<div class="card"><b>'+esc(x.name)+'</b><small>'+esc(x.currency)+' · '+Number(x.coins_per_unit).toLocaleString()+' كوين/وحدة</small><div>'+esc(x.instructions||'')+'</div><button onclick="editRechargeMethod(\''+x.id+'\')">تعديل</button> '+(x.is_active?'🟢':'🔴')+'</div>').join('')||'<p>لا توجد طرق شحن.</p>';
 $('withdrawalMethodsList').innerHTML=w.map(x=>'<div class="card"><b>'+esc(x.name)+'</b><small>'+esc(x.currency)+' · حد '+Number(x.min_amount).toLocaleString()+'—'+Number(x.max_amount).toLocaleString()+' · رسم '+x.fee+'</small><button onclick="editWithdrawalMethod(\''+x.id+'\')">تعديل</button> '+(x.is_active?'🟢':'🔴')+'</div>').join('')||'<p>لا توجد طرق سحب.</p>';
 $('svipLevelsList').innerHTML=financeCache.svip.map(x=>'<div class="card"><b>SVIP '+x.level+'</b><input id="sv_'+x.level+'" type="number" min="0" value="'+Number(x.min_recharge_points||0)+'" placeholder="الحد الأدنى لنقاط الشحن"><label><input id="sva_'+x.level+'" type="checkbox" '+(x.is_active?'checked':'')+'> فعال</label><button onclick="saveSvipThreshold('+x.level+')">حفظ</button></div>').join('');
}
function openRechargeMethodForm(id){
 const x=financeCache.rechargeMethods.find(v=>v.id===id)||{};
 $('financeMethodForm').classList.remove('hidden');
 $('financeMethodForm').innerHTML='<h3>💳 '+(id?'تعديل':'إضافة')+' طريقة شحن</h3><div class="promo-grid">'+
 '<input id="fm_name" placeholder="اسم الطريقة" value="'+esc(x.name||'')+'"><input id="fm_currency" placeholder="العملة" value="'+esc(x.currency||'USD')+'">'+
 '<input id="fm_min" type="number" min="0" step="0.01" placeholder="أقل مبلغ" value="'+Number(x.min_amount||0)+'"><input id="fm_max" type="number" min="0" step="0.01" placeholder="أقصى مبلغ" value="'+Number(x.max_amount||0)+'">'+
 '<input id="fm_rate" type="number" min="1" placeholder="كوين لكل وحدة" value="'+Number(x.coins_per_unit||10000)+'"><input id="fm_fields" placeholder="الحقول JSON" value="'+esc(JSON.stringify(x.fields||[]))+'">'+
 '<input id="fm_instructions" placeholder="تعليمات الدفع" value="'+esc(x.instructions||'')+'"><label><input id="fm_active" type="checkbox" '+(x.id?(x.is_active?'checked':''):'checked')+'> فعال</label></div>'+
 '<button onclick="saveRechargeMethod(\''+(id||'')+'\')">حفظ</button> <button class="ghost" onclick="document.getElementById('financeMethodForm').classList.add('hidden')">إلغاء</button>';
}
function editRechargeMethod(id){openRechargeMethodForm(id)}
async function saveRechargeMethod(id){
 let fields=[];try{fields=JSON.parse($('fm_fields').value||'[]')}catch(e){alert('حقول JSON غير صحيحة');return}
 const {error}=await db.rpc('admin_set_recharge_method',{p_id:id||null,p_name:$('fm_name').value.trim(),p_currency:$('fm_currency').value.trim()||'USD',p_min:Number($('fm_min').value||0),p_max:Number($('fm_max').value||0),p_coins_per_unit:Math.trunc(Number($('fm_rate').value||0)),p_fields:fields,p_instructions:$('fm_instructions').value.trim()||null,p_active:$('fm_active').checked});
 if(error){alert(error.message);return}await loadFinance();
}
function openWithdrawalMethodForm(id){
 const x=financeCache.withdrawalMethods.find(v=>v.id===id)||{};
 $('financeMethodForm').classList.remove('hidden');
 $('financeMethodForm').innerHTML='<h3>💸 '+(id?'تعديل':'إضافة')+' طريقة سحب</h3><div class="promo-grid">'+
 '<input id="wm_name" placeholder="اسم الطريقة" value="'+esc(x.name||'')+'"><input id="wm_currency" placeholder="العملة" value="'+esc(x.currency||'USD')+'">'+
 '<input id="wm_min" type="number" min="0" value="'+Number(x.min_amount||0)+'" placeholder="أقل كوين"><input id="wm_max" type="number" min="0" value="'+Number(x.max_amount||0)+'" placeholder="أقصى كوين">'+
 '<input id="wm_fee" type="number" min="0" step="0.01" value="'+Number(x.fee||0)+'" placeholder="الرسم"><input id="wm_fields" placeholder="الحقول JSON" value="'+esc(JSON.stringify(x.fields||[]))+'">'+
 '<label><input id="wm_active" type="checkbox" '+(x.id?(x.is_active?'checked':''):'checked')+'> فعال</label></div>'+
 '<button onclick="saveWithdrawalMethod(\''+(id||'')+'\')">حفظ</button> <button class="ghost" onclick="document.getElementById('financeMethodForm').classList.add('hidden')">إلغاء</button>';
}
function editWithdrawalMethod(id){openWithdrawalMethodForm(id)}
async function saveWithdrawalMethod(id){
 let fields=[];try{fields=JSON.parse($('wm_fields').value||'[]')}catch(e){alert('حقول JSON غير صحيحة');return}
 const {error}=await db.rpc('admin_set_withdrawal_method',{p_id:id||null,p_name:$('wm_name').value.trim(),p_currency:$('wm_currency').value.trim()||'USD',p_min:Math.trunc(Number($('wm_min').value||0)),p_max:Math.trunc(Number($('wm_max').value||0)),p_fee:Number($('wm_fee').value||0),p_fields:fields,p_active:$('wm_active').checked});
 if(error){alert(error.message);return}await loadFinance();
}
async function saveSvipThreshold(level){
 const n=Math.trunc(Number($('sv_'+level).value));if(!Number.isFinite(n)||n<0){alert('أدخل نقاط صحيحة');return}
 const {error}=await db.rpc('admin_set_svip_level_config',{p_level:level,p_min_points:n,p_active:$('sva_'+level).checked});if(error){alert(error.message);return}await loadFinance();
}
function renderRequests(){
 const names=id=>esc(financeName(id));
 $('rechargeRequestsList').innerHTML=financeCache.recharges.map(r=>'<div class="card"><b>'+names(r.user_id)+'</b> · '+r.status+'<br>مبلغ: '+r.amount+' · كوين: '+Number(r.coins).toLocaleString()+' · نقاط: '+Number(r.points).toLocaleString()+'<br><small>'+esc(r.created_at)+'</small> '+(r.status==='pending'?'<button onclick="approveRecharge(\''+r.id+'\',true)">موافقة</button> <button onclick="approveRecharge(\''+r.id+'\',false)">رفض</button>':'')+'</div>').join('')||'<p>لا توجد طلبات شحن.</p>';
 $('withdrawalRequestsList').innerHTML=financeCache.withdrawals.map(r=>'<div class="card"><b>'+names(r.user_id)+'</b> · '+r.status+'<br>كوين: '+Number(r.amount).toLocaleString()+' · رسم: '+r.fee+'<br><small>'+esc(r.created_at)+'</small> '+(r.status==='pending'?'<button onclick="setWithdrawalStatus(\''+r.id+'\',\'approved\')">موافقة</button> <button onclick="setWithdrawalStatus(\''+r.id+'\',\'rejected\')">رفض</button>':'')+(r.status==='approved'?'<button onclick="setWithdrawalStatus(\''+r.id+'\',\'paid\')">تم الدفع</button>':'')+'</div>').join('')||'<p>لا توجد طلبات سحب.</p>';
}
async function approveRecharge(id,ok){
 const note=prompt(ok?'ملاحظة الموافقة (اختياري)':'سبب الرفض (اختياري)')||null;
 const {error}=await db.rpc('admin_approve_recharge',{p_request_id:id,p_approve:ok,p_note:note});if(error){alert(error.message);return}await loadFinance();await loadAll();
}
async function setWithdrawalStatus(id,status){
 const note=prompt('ملاحظة (اختياري)')||null;
 const {error}=await db.rpc('admin_set_withdrawal_status',{p_request_id:id,p_status:status,p_note:note});if(error){alert(error.message);return}await loadFinance();await loadAll();
}
function renderGlobalAuditTab(items){
 const root=document.getElementById('audit');
 if(!root)return;
 root.innerHTML='<div class="panel"><h3>🧾 سجل العمليات الفعلي</h3>'+
 (items||[]).map(a=>'<div class="card"><b>'+esc(a.action||'—')+'</b> · '+esc(financeName(a.target_user_id))+
 '<br><small>'+esc(a.created_at||'')+'</small><br><small>'+esc(JSON.stringify(a.metadata||{}))+'</small></div>').join('')+
 ((items||[]).length?'':'<p>لا يوجد سجل عمليات.</p>')+'</div>';
}
function renderAudit(){
 $('auditList').innerHTML=financeCache.audit.map(a=>'<div class="card"><b>'+esc(a.action)+'</b> · '+esc(financeName(a.target_user_id))+' · '+esc(a.created_at)+'<br><small>'+esc(JSON.stringify(a.metadata||{}))+'</small></div>').join('')||'<p>لا يوجد سجل.</p>';
}