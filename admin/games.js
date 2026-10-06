async function loadCompanyGames(){
  const {data,error}=await db.from('company_game_links').select('*').order('sort_order').order('created_at',{ascending:false});
  if(error){$('gamesTable').innerHTML='<div class="panel">تعذر تحميل روابط الألعاب: '+esc(error.message)+'</div>';return}
  $('gamesCreate').innerHTML='<div class="promo-grid"><input id="gameName" placeholder="اسم اللعبة"><input id="gameProvider" placeholder="الشركة/المزوّد" value="Asmar"><input id="gameUrl" placeholder="رابط اللعبة https://..."><input id="gameIcon" placeholder="رابط الأيقونة اختياري"><input id="gameDesc" placeholder="وصف مختصر"><input id="gameOrder" type="number" value="0" placeholder="الترتيب"><button class="primary" onclick="saveCompanyGame()">＋ إضافة اللعبة</button></div>';
  $('gamesTable').innerHTML='<table><tr><th>اللعبة</th><th>المزوّد</th><th>الرابط</th><th>الحالة</th><th>إجراء</th></tr>'+((data||[]).map(g=>'<tr><td><b>'+esc(g.name)+'</b><br><small>'+esc(g.description||'')+'</small></td><td>'+esc(g.provider||'Asmar')+'</td><td><a href="'+esc(g.url)+'" target="_blank" rel="noopener">فتح الرابط</a></td><td>'+(g.is_active?'🟢 فعال':'🔴 متوقف')+'</td><td><button onclick="toggleCompanyGame(\''+g.id+'\','+(!g.is_active)+')">'+(g.is_active?'إيقاف':'تفعيل')+'</button> <button onclick="deleteCompanyGame(\''+g.id+'\')">حذف</button></td></tr>').join(''))+'</table>';
}
async function saveCompanyGame(){
  const name=$('gameName').value.trim(), url=$('gameUrl').value.trim();
  if(!name||!/^https:\/\//i.test(url)){alert('أدخل اسم اللعبة ورابط HTTPS صحيح');return}
  const {error}=await db.rpc('admin_upsert_company_game_link',{p_id:null,p_name:name,p_provider:$('gameProvider').value.trim()||'Asmar',p_url:url,p_icon_url:$('gameIcon').value.trim()||null,p_description:$('gameDesc').value.trim()||null,p_is_active:true,p_sort_order:Number($('gameOrder').value||0)});
  if(error){alert('تعذر إضافة اللعبة: '+error.message);return}
  alert('تمت إضافة لعبة الشركة');await loadCompanyGames();
}
async function toggleCompanyGame(id,active){
  const {data:row,error:q}=await db.from('company_game_links').select('*').eq('id',id).single();
  if(q){alert(q.message);return}
  const {error}=await db.rpc('admin_upsert_company_game_link',{p_id:id,p_name:row.name,p_provider:row.provider,p_url:row.url,p_icon_url:row.icon_url,p_description:row.description,p_is_active:active,p_sort_order:row.sort_order});
  if(error){alert(error.message);return} await loadCompanyGames();
}
async function deleteCompanyGame(id){
  if(!confirm('حذف رابط اللعبة؟'))return;
  const {error}=await db.rpc('admin_delete_company_game_link',{p_id:id});
  if(error){alert(error.message);return} await loadCompanyGames();
}
