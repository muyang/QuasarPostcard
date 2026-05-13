from fastapi import APIRouter
from fastapi.responses import HTMLResponse

router = APIRouter()

ADMIN_HTML = """<!DOCTYPE html>
<html lang="zh-CN">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>明信片素材管理</title>
<style>
*{margin:0;padding:0;box-sizing:border-box}
body{font-family:-apple-system,sans-serif;background:#121212;color:#eee;display:flex;height:100vh;overflow:hidden}
/* === Left Panel === */
#left{width:360px;flex-shrink:0;background:#1A1A2E;display:flex;flex-direction:column;border-right:1px solid #2A2A4A}
#left header{padding:14px 16px;border-bottom:1px solid #2A2A4A}
#left header h1{font-size:16px;color:#7C4DFF}
.tabs{display:flex;gap:6px;padding:10px 16px;border-bottom:1px solid #2A2A4A}
.tab{padding:6px 14px;border-radius:6px;cursor:pointer;border:1px solid #444;background:transparent;color:#aaa;font-size:12px}
.tab.active{background:#7C4DFF;color:#fff;border-color:#7C4DFF}
.toolbar{display:flex;flex-direction:column;gap:6px;padding:10px 16px}
.toolbar-row{display:flex;gap:8px}
.search-bar{display:flex;gap:6px}
.search-bar input{flex:1;background:#2A2A4A;border:1px solid #444;color:#fff;padding:6px 10px;border-radius:6px;font-size:12px}
.search-bar input:focus{outline:none;border-color:#7C4DFF}
.search-bar select{background:#2A2A4A;border:1px solid #444;color:#fff;padding:6px 10px;border-radius:6px;font-size:12px;max-width:110px}
#list{flex:1;overflow-y:auto;padding:8px}
.card{background:#1E1E2E;border-radius:8px;padding:10px;margin-bottom:6px;display:flex;align-items:center;gap:10px;cursor:pointer;border:1px solid transparent;transition:border .2s}
.card:hover{border-color:#7C4DFF}
.card.selected{border-color:#7C4DFF;background:#1E1E3E}
.card .preview{width:44px;height:44px;border-radius:6px;display:flex;align-items:center;justify-content:center;font-size:18px;flex-shrink:0;background-size:cover;background-position:center}
.card .info{flex:1;min-width:0}
.card .info .title-row{display:flex;align-items:center;gap:6px}
.card .info .title{font-size:13px;font-weight:600}
.card .info .sub{font-size:10px;color:#888;margin-top:2px;white-space:nowrap;overflow:hidden;text-overflow:ellipsis}
.badge{padding:1px 7px;border-radius:8px;font-size:10px;font-weight:600;display:inline-block;flex-shrink:0}
.badge-draft{background:#333;color:#888}
.badge-published_free{background:#1B3D1B;color:#4CAF50}
.badge-published_member{background:#1B2D4A;color:#2196F3}
.empty{text-align:center;padding:40px 0;color:#444;font-size:13px}
.pagination{display:flex;align-items:center;justify-content:center;gap:6px;padding:8px 16px;border-top:1px solid #2A2A4A;font-size:11px;color:#888}
.pagination button{padding:3px 8px;border-radius:4px;border:1px solid #444;background:transparent;color:#aaa;cursor:pointer;font-size:10px}
.pagination button:disabled{opacity:0.3;cursor:default}
.pagination .page-num{color:#7C4DFF;font-weight:600}

/* === Right Panel === */
#right{flex:1;display:flex;flex-direction:column;overflow-y:auto;padding:20px}
#right .placeholder{flex:1;display:flex;align-items:center;justify-content:center;color:#444;font-size:15px}
#editPanel{display:none;max-width:600px}
#editPanel.show{display:block}
#editPanel h2{font-size:16px;color:#7C4DFF;margin-bottom:16px}

/* Preview Area */
.preview-area{background:#1A1A2E;border-radius:12px;padding:20px;margin-bottom:20px;display:flex;align-items:center;justify-content:center;min-height:180px}
.preview-box{position:relative;overflow:hidden}
.template-preview{width:252px;height:162px;border-radius:6px;position:relative;overflow:hidden}
.stamp-preview{width:64px;height:76px;border-radius:3px;position:relative;background:#fff;display:flex;align-items:center;justify-content:center;border:2px solid #ccc;flex-direction:column}
.postmark-preview{width:90px;height:90px;position:relative}

/* Form */
.form-group{margin-bottom:14px}
.form-group label{display:block;font-size:12px;color:#888;margin-bottom:4px}
.form-group input,.form-group select{width:100%;background:#2A2A4A;border:1px solid #444;color:#fff;padding:8px 10px;border-radius:6px;font-size:13px}
.form-group input:focus{outline:none;border-color:#7C4DFF}
.form-row{display:flex;gap:10px}
.form-row .form-group{flex:1}
.color-row{display:flex;align-items:center;gap:8px}
.color-dot{width:20px;height:20px;border-radius:4px;border:1px solid #555;flex-shrink:0}

/* Image section */
.img-section{background:#1E1E2E;border-radius:8px;padding:14px;margin-bottom:14px}
.img-section h4{font-size:13px;color:#aaa;margin-bottom:10px}
.img-preview-wrap{display:flex;align-items:center;gap:10px;margin-bottom:10px}
.img-thumb{width:80px;height:60px;border-radius:6px;background:#2A2A4A;background-size:cover;background-position:center;border:1px solid #444;flex-shrink:0;display:flex;align-items:center;justify-content:center;font-size:24px;color:#555}
.img-url-row{display:flex;gap:6px}
.img-url-row input{flex:1}

/* Buttons */
.btn{padding:7px 16px;border-radius:6px;border:none;cursor:pointer;font-size:12px;white-space:nowrap}
.btn-primary{background:#7C4DFF;color:#fff}
.btn-danger{background:#C62828;color:#fff}
.btn-outline{background:transparent;border:1px solid #444;color:#aaa}
.btn-small{padding:4px 10px;font-size:11px}
.actions{display:flex;gap:8px;margin-top:18px}

/* Toast */
.toast{position:fixed;bottom:24px;right:24px;padding:10px 20px;border-radius:8px;font-size:13px;z-index:999;animation:fadeIn .3s}
.toast.success{background:#2E7D32;color:#fff}
.toast.error{background:#C62828;color:#fff}
@keyframes fadeIn{from{opacity:0;transform:translateY(10px)}to{opacity:1;transform:translateY(0)}}
</style>
</head>
<body>

<div id="left">
  <header><h1>📮 明信片素材管理</h1></header>
  <div class="tabs">
    <button class="tab active" onclick="switchTab('templates')">模版</button>
    <button class="tab" onclick="switchTab('stamps')">邮票</button>
    <button class="tab" onclick="switchTab('postmarks')">邮戳</button>
  </div>
  <div class="toolbar">
    <div class="toolbar-row">
      <button class="btn btn-primary" style="flex:1" onclick="addNew()">+ 新增</button>
      <button class="btn btn-outline" onclick="seedData()">初始化默认</button>
    </div>
    <div class="search-bar">
      <input id="searchInput" placeholder="搜索名称..." oninput="onSearchInput()">
      <select id="statusFilter" onchange="load(1)">
        <option value="">全部状态</option>
        <option value="draft">待发布</option>
        <option value="published_free">发布-免费</option>
        <option value="published_member">发布-会员</option>
      </select>
    </div>
  </div>
  <div id="list"></div>
  <div class="pagination" id="pagination" style="display:none">
    <button onclick="goPage(currentPage-1)" id="prevBtn" disabled>&lt; 上一页</button>
    <span>第 <span class="page-num" id="pageInfo">1</span> / <span id="totalPages">1</span> 页</span>
    <button onclick="goPage(currentPage+1)" id="nextBtn" disabled>下一页 &gt;</button>
    <span style="margin-left:4px">共 <span id="totalCount">0</span> 条</span>
  </div>
</div>

<div id="right">
  <div class="placeholder" id="placeholder">← 选择左侧素材或点击新增开始编辑</div>
  <div id="editPanel">
    <h2 id="editTitle">编辑素材</h2>
    <div class="preview-area"><div id="previewContainer"></div></div>
    <div id="editForm"></div>
  </div>
</div>

<div id="toast" class="toast"></div>

<script>
const BASE = '';
let currentTab = 'templates';
let editingId = null;
let selectedItem = null;
let token = localStorage.getItem('token') || '';
let cachedItems = [];
let currentPage = 1;
let totalCount = 0;
const PAGE_SIZE = 20;
let searchTimeout = null;

async function api(path, method='GET', body=null, isFile=false) {
  const opts = { method };
  if (!isFile) { opts.headers = {'Content-Type':'application/json', 'Authorization':`Bearer ${token}`}; if(body) opts.body=JSON.stringify(body); }
  else { opts.headers = {'Authorization':`Bearer ${token}`}; opts.body=body; }
  const resp = await fetch(BASE+path, opts);
  if(resp.status===401){login();throw new Error('auth')}
  if(!resp.ok){throw new Error(await resp.text())}
  return resp.json();
}

async function login(){
  const pwd=prompt('管理员密码:');
  if(!pwd)return;
  const resp=await fetch(BASE+'/api/auth/login',{method:'POST',headers:{'Content-Type':'application/json'},body:JSON.stringify({username:'admin',password:pwd})});
  const d=await resp.json();
  if(d.success){token=d.token;localStorage.setItem('token',token);load(1);}
  else alert('密码错误');
}

async function load(page){
  if(!token){login();return}
  currentPage = page;
  const skip = (page - 1) * PAGE_SIZE;
  const status = document.getElementById('statusFilter')?.value || '';
  const search = document.getElementById('searchInput')?.value || '';
  let url = `/api/materials/${currentTab}?skip=${skip}&limit=${PAGE_SIZE}`;
  if (status) url += `&status=${encodeURIComponent(status)}`;
  if (search) url += `&search=${encodeURIComponent(search)}`;
  try {
    const data = await api(url);
    totalCount = data.total || 0;
    cachedItems = data.items || [];
    render(cachedItems);
    renderPagination();
  } catch(e) { if(e.message!=='auth') toast(e.message,'error'); }
}

function onSearchInput() {
  if (searchTimeout) clearTimeout(searchTimeout);
  searchTimeout = setTimeout(() => load(1), 300);
}

function renderPagination() {
  const totalPages = Math.ceil(totalCount / PAGE_SIZE) || 1;
  const pg = document.getElementById('pagination');
  pg.style.display = totalPages > 1 ? 'flex' : 'none';
  document.getElementById('pageInfo').textContent = currentPage;
  document.getElementById('totalPages').textContent = totalPages;
  document.getElementById('totalCount').textContent = totalCount;
  document.getElementById('prevBtn').disabled = currentPage <= 1;
  document.getElementById('nextBtn').disabled = currentPage >= totalPages;
}

async function goPage(n) {
  const totalPages = Math.ceil(totalCount / PAGE_SIZE) || 1;
  if (n < 1 || n > totalPages) return;
  await load(n);
  document.getElementById('list').scrollTop = 0;
}

function statusLabel(s) {
  const labels = { draft: '待发布', published_free: '免费', published_member: '会员' };
  return labels[s] || '待发布';
}

function render(items){
  const el=document.getElementById('list');
  if(!items.length){el.innerHTML='<div class="empty">暂无数据</div>';return}
  el.innerHTML=items.map(item=>{
    let previewHtml, sub;
    const stBadge = `<span class="badge badge-${item.status||'draft'}">${statusLabel(item.status)}</span>`;
    if(currentTab==='templates'){
      const grad=`linear-gradient(135deg,#${item.gradient_from},#${item.gradient_mid||item.gradient_from},#${item.gradient_to})`;
      const bgImg=item.image_url?`background-image:url(${item.image_url});background-size:cover;`:'';
      previewHtml=`<div class="preview" style="background:${grad};${bgImg}border-radius:${item.corner_radius}px">🎨</div>`;
      sub=`${item.id} · 圆角${item.corner_radius}px · ${item.pattern||'无图案'}`;
    } else if(currentTab==='stamps'){
      const bgImg=item.image_url?`background-image:url(${item.image_url});background-size:cover;`:'';
      previewHtml=`<div class="preview" style="${bgImg}background-color:#2A2A4A">${item.image_url?'':item.emoji}</div>`;
      sub=`${item.id} · #${item.accent_color}`;
    } else {
      const bgImg=item.image_url?`background-image:url(${item.image_url});background-size:cover;`:'';
      previewHtml=`<div class="preview" style="${bgImg}background-color:#2A2A4A">🔘</div>`;
      sub=`${item.id} · ${item.date_text} · #${item.color}`;
    }
    return `<div class="card${selectedItem&&selectedItem.id===item.id?' selected':''}" onclick="selectItem('${item.id}')">
      ${previewHtml}
      <div class="info">
        <div class="title-row"><span class="title">${item.name||item.label}</span>${stBadge}</div>
        <div class="sub">${sub}</div>
      </div>
    </div>`;
  }).join('');
}

function selectItem(id){
  selectedItem = cachedItems.find(i => i.id === id) || null;
  render(cachedItems);
  if(selectedItem){editingId=id;showEditPanel()}
}

function addNew(){editingId=null;selectedItem=null;load(currentPage);showEditPanel()}

function showEditPanel(){
  document.getElementById('placeholder').style.display='none';
  document.getElementById('editPanel').classList.add('show');
  document.getElementById('editTitle').textContent=editingId?'编辑素材':'新增素材';
  renderForm();
  renderPreview();
}

function hideEditPanel(){
  document.getElementById('editPanel').classList.remove('show');
  document.getElementById('placeholder').style.display='flex';
}

function renderForm(){
  const f=document.getElementById('editForm');
  const item=selectedItem||{};
  let html='';

  if(currentTab==='templates'){
    html+=`<div class="form-row">
      <div class="form-group"><label>ID</label><input id="f_id" value="${item.id||''}" ${editingId?'disabled':''} placeholder="floral"></div>
      <div class="form-group"><label>名称</label><input id="f_name" value="${item.name||''}" placeholder="花卉"></div>
    </div>
    <div class="form-row">
      <div class="form-group"><label>渐变起始 #</label><div class="color-row"><div class="color-dot" style="background:#${item.gradient_from||'FFF0F5'}"></div><input id="f_from" value="${item.gradient_from||'FFF0F5'}"></div></div>
      <div class="form-group"><label>渐变中间 #</label><div class="color-row"><div class="color-dot" style="background:#${item.gradient_mid||'FFE4E1'}"></div><input id="f_mid" value="${item.gradient_mid||''}" placeholder="可选"></div></div>
      <div class="form-group"><label>渐变结束 #</label><div class="color-row"><div class="color-dot" style="background:#${item.gradient_to||'FFC0CB'}"></div><input id="f_to" value="${item.gradient_to||'FFC0CB'}"></div></div>
    </div>
    <div class="form-row">
      <div class="form-group"><label>圆角</label><input id="f_radius" type="number" value="${item.corner_radius||8}" min="0" max="40"></div>
      <div class="form-group"><label>装饰图案</label><select id="f_pattern">
        <option value="">无</option>
        <option value="floral" ${item.pattern==='floral'?'selected':''}>花卉</option>
        <option value="geometric" ${item.pattern==='geometric'?'selected':''}>几何</option>
        <option value="vintage" ${item.pattern==='vintage'?'selected':''}>复古</option>
        <option value="nature" ${item.pattern==='nature'?'selected':''}>自然</option>
        <option value="ocean" ${item.pattern==='ocean'?'selected':''}>海洋</option>
        <option value="minimalist" ${item.pattern==='minimalist'?'selected':''}>极简</option>
      </select></div>
    </div>`;
  } else if(currentTab==='stamps'){
    html+=`<div class="form-row">
      <div class="form-group"><label>ID</label><input id="f_id" value="${item.id||''}" ${editingId?'disabled':''} placeholder="flower"></div>
      <div class="form-group"><label>Emoji</label><input id="f_emoji" value="${item.emoji||'🌸'}" placeholder="🌸"></div>
      <div class="form-group"><label>标签</label><input id="f_label" value="${item.label||''}" placeholder="樱花"></div>
    </div>
    <div class="form-row">
      <div class="form-group"><label>强调色 #</label><div class="color-row"><div class="color-dot" style="background:#${item.accent_color||'FFB7C5'}"></div><input id="f_color" value="${item.accent_color||'FFB7C5'}"></div></div>
    </div>`;
  } else {
    html+=`<div class="form-row">
      <div class="form-group"><label>ID</label><input id="f_id" value="${item.id||''}" ${editingId?'disabled':''} placeholder="classic"></div>
      <div class="form-group"><label>标签</label><input id="f_label" value="${item.label||''}" placeholder="经典圆形"></div>
    </div>
    <div class="form-row">
      <div class="form-group"><label>日期文字</label><input id="f_date" value="${item.date_text||'2026.05.13'}"></div>
      <div class="form-group"><label>颜色 #</label><div class="color-row"><div class="color-dot" style="background:#${item.color||'333333'}"></div><input id="f_color" value="${item.color||'333333'}"></div></div>
    </div>`;
  }

  // Status dropdown (common to all)
  html+=`<div class="form-row">
    <div class="form-group"><label>发布状态</label><select id="f_status">
      <option value="draft" ${item.status==='draft'?'selected':''}>待发布</option>
      <option value="published_free" ${(item.status||'published_free')==='published_free'?'selected':''}>发布-免费</option>
      <option value="published_member" ${item.status==='published_member'?'selected':''}>发布-会员</option>
    </select></div>
  </div>`;

  // Image section (common to all)
  const imgUrl = item.image_url || '';
  html+=`<div class="img-section">
    <h4>🖼 图片设置（可选）</h4>
    <div class="img-preview-wrap">
      <div class="img-thumb" id="imgThumb" style="${imgUrl?`background-image:url(${imgUrl})`:''}">${imgUrl?'':'📷'}</div>
      <div style="flex:1;font-size:11px;color:#888">${imgUrl?'已设置图片':'上传图片文件或输入URL'}<br><a href="#" onclick="clearImage()" style="color:#C62828;font-size:10px">${imgUrl?'清除图片':''}</a></div>
    </div>
    <div style="margin-bottom:8px">
      <input type="file" accept="image/*" onchange="pickImage(this)" style="display:none" id="fileInput">
      <button class="btn btn-outline btn-small" onclick="document.getElementById('fileInput').click()">📁 上传图片文件</button>
    </div>
    <div class="img-url-row">
      <input id="f_image_url" value="${imgUrl}" placeholder="或输入图片URL https://...">
      <button class="btn btn-outline btn-small" onclick="applyUrl()">应用</button>
    </div>
  </div>`;

  html+=`<div class="actions">
    <button class="btn btn-primary" onclick="saveItem()">保存</button>
    ${editingId?`<button class="btn btn-danger" onclick="deleteItem()">删除</button>`:''}
    <button class="btn btn-outline" onclick="hideEditPanel()">取消</button>
  </div>`;

  f.innerHTML=html;

  // Live update preview on input change
  f.querySelectorAll('input,select').forEach(el=>{
    el.addEventListener('input', renderPreview);
    el.addEventListener('change', renderPreview);
  });
}

function getFormData(){
  const data={};
  if(currentTab==='templates'){
    data.id=document.getElementById('f_id').value;
    data.name=document.getElementById('f_name').value;
    data.gradient_from=document.getElementById('f_from').value;
    data.gradient_mid=document.getElementById('f_mid').value||null;
    data.gradient_to=document.getElementById('f_to').value;
    data.corner_radius=parseInt(document.getElementById('f_radius').value)||8;
    data.pattern=document.getElementById('f_pattern').value||null;
  } else if(currentTab==='stamps'){
    data.id=document.getElementById('f_id').value;
    data.emoji=document.getElementById('f_emoji').value;
    data.label=document.getElementById('f_label').value;
    data.accent_color=document.getElementById('f_color').value;
  } else {
    data.id=document.getElementById('f_id').value;
    data.label=document.getElementById('f_label').value;
    data.date_text=document.getElementById('f_date').value;
    data.color=document.getElementById('f_color').value;
  }
  data.status=document.getElementById('f_status')?.value||'published_free';
  const imgUrl=document.getElementById('f_image_url')?.value||'';
  data.image_url=imgUrl||null;
  return data;
}

function renderPreview(){
  const c=document.getElementById('previewContainer');
  const data=getFormData();

  if(currentTab==='templates'){
    const grad=`linear-gradient(135deg,#${data.gradient_from},#${data.gradient_mid||data.gradient_from},#${data.gradient_to})`;
    const bgImg=data.image_url?`background-image:url(${data.image_url});background-size:cover;background-blend-mode:overlay;`:'';
    c.innerHTML=`<div class="template-preview" style="background:${grad};${bgImg}border-radius:${data.corner_radius}px;border:2px solid #555">
      <div style="position:absolute;top:12px;left:0;right:0;text-align:center;font-size:9px;color:#999;letter-spacing:2px">POSTCARD</div>
      <div style="position:absolute;top:12px;right:16px;font-size:24px;opacity:0.3">${data.pattern==='floral'?'🌸':data.pattern==='vintage'?'📮':data.pattern==='nature'?'🌿':data.pattern==='ocean'?'🌊':data.pattern==='geometric'?'🔷':data.pattern==='minimalist'?'✨':'📬'}</div>
      <div style="position:absolute;bottom:16px;left:16px;font-size:10px;color:#666">To: ______</div>
      <div style="position:absolute;bottom:16px;right:16px;font-size:10px;color:#666">From: ______</div>
    </div>`;
  } else if(currentTab==='stamps'){
    const bgImg=data.image_url?`background-image:url(${data.image_url});background-size:cover;`:'';
    c.innerHTML=`<div class="stamp-preview" style="border-color:#${data.accent_color};${bgImg}">
      ${data.image_url?'':`<span style="font-size:28px">${data.emoji||'🌸'}</span>`}
      <span style="font-size:9px;color:#${data.accent_color};margin-top:2px">${data.label||'标签'}</span>
    </div>`;
  } else {
    c.innerHTML=`<div class="postmark-preview">
      <svg width="90" height="90" viewBox="0 0 90 90">
        <circle cx="45" cy="45" r="38" fill="none" stroke="#${data.color}" stroke-width="2.5" opacity="0.8"/>
        <circle cx="45" cy="45" r="30" fill="none" stroke="#${data.color}" stroke-width="1" opacity="0.5"/>
        ${Array.from({length:24},(_,i)=>{
          const a=i*Math.PI*2/24;
          const r1=33,r2=38;
          const x1=45+Math.cos(a)*r1,y1=45+Math.sin(a)*r1;
          const x2=45+Math.cos(a)*r2,y2=45+Math.sin(a)*r2;
          return `<line x1="${x1}" y1="${y1}" x2="${x2}" y2="${y2}" stroke="#${data.color}" stroke-width="0.5" opacity="0.5"/>`;
        }).join('')}
        <text x="45" y="48" text-anchor="middle" font-size="9" fill="#${data.color}" font-weight="bold" opacity="0.8">${data.date_text||'2026.05.13'}</text>
      </svg>
    </div>`;
  }
}

async function pickImage(input){
  const file=input.files[0];
  if(!file)return;
  try{
    const fd=new FormData();
    fd.append('file',file);
    const resp=await api('/api/upload/image','POST',fd,true);
    if(resp.success){
      document.getElementById('f_image_url').value=resp.url;
      document.getElementById('imgThumb').style.backgroundImage=`url(${resp.url})`;
      document.getElementById('imgThumb').innerHTML='';
      renderPreview();
      toast('图片上传成功','success');
    }
  }catch(e){toast('上传失败: '+e.message,'error')}
}

function applyUrl(){
  const url=document.getElementById('f_image_url').value.trim();
  if(url){
    document.getElementById('imgThumb').style.backgroundImage=`url(${url})`;
    document.getElementById('imgThumb').innerHTML='';
    renderPreview();
  }
}

function clearImage(){
  document.getElementById('f_image_url').value='';
  document.getElementById('imgThumb').style.backgroundImage='';
  document.getElementById('imgThumb').innerHTML='📷';
  renderPreview();
}

async function saveItem(){
  const data=getFormData();
  if(!data.id){toast('请输入ID','error');return}
  const path=currentTab==='templates'?'templates':currentTab==='stamps'?'stamps':'postmarks';
  try{
    if(editingId){await api(`/api/materials/${path}/${editingId}`,'PUT',data)}
    else {await api(`/api/materials/${path}`,'POST',data)}
    editingId=data.id;
    toast('保存成功','success');
    load(currentPage);
    document.getElementById('editTitle').textContent='编辑素材';
  }catch(e){toast(e.message,'error')}
}

async function deleteItem(){
  if(!confirm('确认删除？'))return;
  const path=currentTab==='templates'?'templates':currentTab==='stamps'?'stamps':'postmarks';
  try{
    await api(`/api/materials/${path}/${editingId}`,'DELETE');
    editingId=null;selectedItem=null;
    hideEditPanel();
    load(currentPage);
    toast('已删除','success');
  }catch(e){toast(e.message,'error')}
}

async function seedData(){
  try{await api('/api/materials/seed','POST');load(currentPage);toast('默认数据已初始化','success')}
  catch(e){toast(e.message,'error')}
}

function switchTab(tab){
  currentTab=tab;editingId=null;selectedItem=null;currentPage=1;
  hideEditPanel();
  document.querySelectorAll('.tab').forEach((t,i)=>{const tabs=['templates','stamps','postmarks'];t.classList.toggle('active',tabs[i]===tab)});
  load(1);
}

function toast(msg,type){
  const t=document.getElementById('toast');
  t.className='toast '+type;t.textContent=msg;
  setTimeout(()=>t.className='',2500);
}

load(1);
</script>
</body>
</html>"""

@router.get("/admin", response_class=HTMLResponse)
def admin_page():
    return HTMLResponse(content=ADMIN_HTML)
