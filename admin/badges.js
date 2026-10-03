let badgeCatalog=[];
async function loadBadges(){
 const root=document.getElementById('badgesTable');if(!root)return;
 const [b,u]=await Promise.all([
  db.from('role_badges').select('id,name,role,style_key,is_active').order('created_at'),
  db.from('user_badges').select('user_id,badge_id,is_equipped')
 ]);
 const err=[b,u].find(x=>x.error);if(err){root.innerHTML='<div class="panel">خطأ: '+badgeEsc(err.error.message)+'</div>';return}
 badgeCatalog=b.data||[];const assignments=u.data||[];
 const assigned=(uid,bid)=>assignments.some(x=>x.user_id===uid&&x.badge_id===bid&&x.is_equipped);
 const {data:{user}}=await db.auth.getUser();
 root.innerHTML='<div class="panel"><h3>🏅 كتالوج الشارات</h3><p>الـCEO يستطيع إضافة شارات جديدة ومنح/سحب أي شارة. ويمكنه إعطاء نفسه كل الشارات.</p>'+
 '<div class="promo-grid"><input id="newBadgeName" placeholder="اسم الشارة"><input id="newBadgeRole" placeholder="الدور/التصنيف"><input id="newBadgeStyle" placeholder="style_key"><button onclick="createBadge()">＋ إضافة شارة</button><button onclick="grantAllBadgesToMe()">👑 أعطني كل الشارات</button></div></div>'+
 '<table><tr><th>المستخدم</th><th>ID</th><th>الدور</th>'+badgeCatalog.map(x=>'<th>'+badgeEsc(x.name)+'</th>').join('')+'</tr>'+
 (allUsers||[]).map(p=>'<tr><td>'+badgeEsc(p.display_name||p.username||'مستخدم')+'</td><td>'+badgeEsc(p.public_id||'—')+'</td><td>'+badgeEsc(p.role||'USER')+'</td>'+
 badgeCatalog.map(b=>'<td><input type="checkbox" '+(assigned(p.id,b.id)?'checked':'')+' onchange="toggleRoleBadge(\''+p.id+'\',\''+b.id+'\',this.checked)"></td>').join('')+'</tr>').join('')+'</table>';
 if(user) window.badgeCurrentUserId=user.id;
}
async function toggleRoleBadge(userId,badgeId,granted){
 const {error}=await db.rpc('admin_grant_badge',{p_user_id:userId,p_badge_id:badgeId,p_granted:granted});
 if(error){alert(error.message);await loadBadges();return}
}
async function createBadge(){
 const name=$('newBadgeName').value.trim(),role=$('newBadgeRole').value.trim()||'CUSTOM',style=$('newBadgeStyle').value.trim()||('custom_'+Date.now());
 if(!name){alert('اكتب اسم الشارة');return}
 const {error}=await db.rpc('admin_create_role_badge',{p_name:name,p_role:role,p_style_key:style});
 if(error){alert(error.message);return}
 $('newBadgeName').value='';$('newBadgeRole').value='';$('newBadgeStyle').value='';await loadBadges();
}
async function grantAllBadgesToMe(){
 if(!window.badgeCurrentUserId){alert('لم يتم تحديد حسابك');return}
 if(!confirm('تأكيد منح جميع الشارات الموجودة لحساب CEO الحالي؟'))return;
 for(const b of badgeCatalog){
  const {error}=await db.rpc('admin_grant_badge',{p_user_id:window.badgeCurrentUserId,p_badge_id:b.id,p_granted:true});
  if(error){alert(error.message);return}
 }
 alert('تم منح كل الشارات لحسابك');await loadBadges();
}
function badgeEsc(v){return String(v??'').replace(/[&<>"']/g,m=>({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&#039;'}[m]));}
loadBadges();