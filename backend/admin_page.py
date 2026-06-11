from fastapi import APIRouter
from fastapi.responses import HTMLResponse

router = APIRouter()

ADMIN_HTML = r"""<!DOCTYPE html>
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
#right{flex:1;display:flex;flex-direction:column;overflow:hidden}
#right .placeholder{flex:1;display:flex;align-items:center;justify-content:center;color:#444;font-size:15px}
#editPanel{display:none;flex:1;flex-direction:column;overflow:hidden}
#editPanel.show{display:flex}
#editHeader{display:flex;align-items:center;justify-content:space-between;padding:14px 20px;border-bottom:1px solid #2A2A4A}
#editHeader h2{font-size:16px;color:#7C4DFF}
#editBody{flex:1;display:flex;overflow:hidden}

/* Canvas area */
#canvasWrap{flex:1;display:flex;align-items:center;justify-content:center;padding:20px;background:#0D0D1A;position:relative;overflow:hidden}
#canvasContainer{position:relative;width:420px;height:270px;flex-shrink:0;transform-origin:center center}
#postcardCanvas{position:absolute;inset:0;border-radius:8px;overflow:hidden;box-shadow:0 8px 32px rgba(0,0,0,.5)}
#canvasOverlay{position:absolute;inset:0;z-index:2;pointer-events:none}
#canvasOverlay.active{pointer-events:auto}

.canvas-el{position:absolute;cursor:move;z-index:3;user-select:none;white-space:nowrap}
.canvas-el.selected{outline:2px dashed #7C4DFF;outline-offset:2px}
.canvas-el .rotate-handle{position:absolute;top:-22px;left:50%;transform:translateX(-50%);width:16px;height:16px;border-radius:50%;background:#7C4DFF;border:2px solid #fff;cursor:grab;display:none;z-index:5}
.canvas-el.selected .rotate-handle{display:block}
.canvas-el .el-label{position:absolute;top:-18px;left:50%;transform:translateX(-50%);font-size:9px;color:#7C4DFF;background:#1A1A2E;padding:0 4px;border-radius:2px;display:none;pointer-events:none}
.canvas-el.selected .el-label{display:block}

/* Stamp on canvas */
.canvas-stamp{width:52px;height:62px;border-radius:3px;display:flex;align-items:center;justify-content:center;flex-direction:column;position:absolute;cursor:move;z-index:3}
.canvas-placeholder{position:absolute;z-index:3;pointer-events:auto;cursor:move;border:2px dashed rgba(124,77,255,0.5);border-radius:4px;display:flex;align-items:center;justify-content:center;font-size:10px;color:rgba(124,77,255,0.5)}
.canvas-placeholder.selected{outline:2px dashed #7C4DFF;outline-offset:2px}
.canvas-placeholder .rotate-handle{position:absolute;top:-22px;left:50%;transform:translateX(-50%);width:16px;height:16px;border-radius:50%;background:#7C4DFF;border:2px solid #fff;cursor:grab;display:none;z-index:5}
.canvas-placeholder.selected .rotate-handle{display:block}
.canvas-placeholder .el-label{position:absolute;top:-18px;left:50%;transform:translateX(-50%);font-size:9px;color:#7C4DFF;background:#1A1A2E;padding:0 4px;border-radius:2px;display:none;pointer-events:none}
.canvas-placeholder.selected .el-label{display:block}
.canvas-stamp.selected{outline:2px dashed #7C4DFF;outline-offset:2px}
.canvas-stamp .rotate-handle{position:absolute;top:-22px;left:50%;transform:translateX(-50%);width:16px;height:16px;border-radius:50%;background:#7C4DFF;border:2px solid #fff;cursor:grab;display:none;z-index:5}
.canvas-stamp.selected .rotate-handle{display:block}
.canvas-stamp .el-label{position:absolute;top:-18px;left:50%;transform:translateX(-50%);font-size:9px;color:#7C4DFF;background:#1A1A2E;padding:0 4px;border-radius:2px;display:none;pointer-events:none}
.canvas-stamp.selected .el-label{display:block}

/* Postmark on canvas */
.canvas-postmark{position:absolute;cursor:move;z-index:3;pointer-events:auto}
.canvas-postmark.selected{outline:2px dashed #7C4DFF;outline-offset:2px}
.canvas-postmark .rotate-handle{position:absolute;top:-22px;left:50%;transform:translateX(-50%);width:16px;height:16px;border-radius:50%;background:#7C4DFF;border:2px solid #fff;cursor:grab;display:none;z-index:5}
.canvas-postmark.selected .rotate-handle{display:block}
.canvas-postmark .el-label{position:absolute;top:-18px;left:50%;transform:translateX(-50%);font-size:9px;color:#7C4DFF;background:#1A1A2E;padding:0 4px;border-radius:2px;display:none;pointer-events:none}
.canvas-postmark.selected .el-label{display:block}

/* Alignment guides */
.guide-line{position:absolute;background:#7C4DFF;opacity:.6;pointer-events:none;z-index:10}
.guide-h{height:1px;left:0;right:0}
.guide-v{width:1px;top:0;bottom:0}

/* Grid */
.grid-line{position:absolute;background:rgba(124,77,255,0.12);pointer-events:none;z-index:1}
.grid-h{height:1px;left:0;right:0}
.grid-v{width:1px;top:0;bottom:0}

/* Resize handles */
.resize-handle{position:absolute;width:10px;height:10px;background:#7C4DFF;border:2px solid #fff;border-radius:2px;z-index:6;display:none;cursor:nw-resize}
.canvas-placeholder.selected .resize-handle{display:block}

/* Sidebar form */
#formSidebar{width:340px;flex-shrink:0;overflow-y:auto;padding:16px 20px;border-left:1px solid #2A2A4A;background:#141428}
#formSidebar .section{margin-bottom:18px}
#formSidebar .section h4{font-size:12px;color:#7C4DFF;margin-bottom:10px;padding-bottom:4px;border-bottom:1px solid #2A2A4A;display:flex;align-items:center;gap:6px}
#formSidebar .section h4 .icon{font-size:14px}
.form-group{margin-bottom:10px}
.form-group label{display:block;font-size:11px;color:#888;margin-bottom:3px}
.form-group input,.form-group select{width:100%;background:#2A2A4A;border:1px solid #444;color:#fff;padding:7px 9px;border-radius:6px;font-size:12px}
.form-group input:focus,.form-group select:focus{outline:none;border-color:#7C4DFF}
.form-row{display:flex;gap:8px}
.form-row .form-group{flex:1}
.form-row-3{display:flex;gap:6px}
.form-row-3 .form-group{flex:1}
.form-row-3 .form-group.xs{flex:0 0 55px}

.color-row{display:flex;align-items:center;gap:8px}
.color-row input[type="color"]{width:32px;height:32px;padding:2px;border-radius:6px;border:1px solid #555;cursor:pointer;background:transparent;flex-shrink:0}
.color-row input[type="color"]::-webkit-color-swatch-wrapper{padding:0}
.color-row input[type="color"]::-webkit-color-swatch{border-radius:4px;border:none}
.color-row input[type="text"]{flex:1}

.range-row{display:flex;align-items:center;gap:8px}
.range-row input[type="range"]{flex:1}
.range-row .range-val{font-size:11px;color:#888;min-width:32px;text-align:right}

/* Section toggle */
.section-toggle{cursor:pointer;user-select:none}
.section-toggle .arrow{transition:transform .2s;display:inline-block}
.section-toggle.collapsed .arrow{transform:rotate(-90deg)}
.section-content{overflow:hidden;transition:max-height .3s}
.section-content.collapsed{max-height:0!important}

/* Buttons */
.btn{padding:7px 16px;border-radius:6px;border:none;cursor:pointer;font-size:12px;white-space:nowrap}
.btn-primary{background:#7C4DFF;color:#fff}
.btn-primary:hover{background:#6A3DE8}
.btn-danger{background:#C62828;color:#fff}
.btn-outline{background:transparent;border:1px solid #444;color:#aaa}
.btn-outline:hover{border-color:#7C4DFF;color:#fff}
.btn-small{padding:4px 10px;font-size:11px}
.actions{display:flex;gap:8px;margin-top:18px;padding-top:14px;border-top:1px solid #2A2A4A}

/* Alignment buttons */
.align-btns{display:flex;gap:4px;flex-wrap:wrap}
.align-btns button{padding:3px 7px;font-size:10px;border-radius:4px;border:1px solid #444;background:transparent;color:#aaa;cursor:pointer}
.align-btns button:hover{background:#7C4DFF;color:#fff;border-color:#7C4DFF}

/* Toast */
.toast{position:fixed;bottom:24px;right:24px;padding:10px 20px;border-radius:8px;font-size:13px;z-index:999;animation:fadeIn .3s}
.toast.success{background:#2E7D32;color:#fff}
.toast.error{background:#C62828;color:#fff}
@keyframes fadeIn{from{opacity:0;transform:translateY(10px)}to{opacity:1;transform:translateY(0)}}

/* Batch actions bar */
#batchBar{display:none;align-items:center;gap:8px;padding:8px 16px;background:#2D1B3D;border-bottom:1px solid #7C4DFF}
#batchBar.show{display:flex}
#batchBar .count{font-size:12px;color:#7C4DFF;font-weight:600}
#batchBar .btn{margin-left:auto}
.card-check{flex-shrink:0;width:18px;height:18px;accent-color:#7C4DFF;cursor:pointer}
.card-check:not(.show){display:none}
.card-check.show{display:block}

/* Group tabs */
.group-tab{padding:4px 10px;border-radius:12px;cursor:pointer;border:1px solid #444;background:transparent;color:#aaa;font-size:11px;white-space:nowrap}
.group-tab.active{background:#7C4DFF;color:#fff;border-color:#7C4DFF}
.group-tab:hover:not(.active){border-color:#7C4DFF;color:#fff}

/* Scrollbar */
::-webkit-scrollbar{width:6px}
::-webkit-scrollbar-track{background:transparent}
::-webkit-scrollbar-thumb{background:#333;border-radius:3px}

/* responsive font preview */
@import url('https://fonts.googleapis.com/css2?family=Noto+Sans+SC:wght@400;700&family=Noto+Serif+SC:wght@400;700&family=ZCOOL+KuaiLe&family=Ma+Shan+Zheng&family=Long+Cang&family=ZCOOL+XiaoWei&display=swap');
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
      <button class="btn btn-outline" onclick="cloneItem()" title="复制选中素材">📋 复制</button>
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
  <div id="groupBar" style="padding:0 16px 8px;display:flex;align-items:center;gap:6px;flex-wrap:wrap;border-bottom:1px solid #2A2A4A">
    <button class="group-tab active" data-group="" onclick="filterByGroup('')">全部</button>
    <span id="groupTabs"></span>
    <button class="group-tab" style="border-style:dashed;color:#7C4DFF" onclick="createGroup()">+ 新建分组</button>
    <button class="group-tab" style="border-style:dashed;color:#FFB74D" onclick="openGroupSort()">↕ 分组排序</button>
  </div>
  <div id="batchBar">
    <input type="checkbox" class="card-check show" id="selectAllCheck" onchange="toggleSelectAll()" title="全选/取消">
    <span class="count" id="batchCount">已选 0 项</span>
    <button class="btn btn-danger btn-small" onclick="batchDelete()">🗑 批量删除</button>
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
    <div id="editHeader">
      <h2 id="editTitle">编辑素材</h2>
      <div style="display:flex;gap:8px">
        <button class="btn btn-outline btn-small" onclick="zoomCanvas(0.1)">🔍+</button>
        <button class="btn btn-outline btn-small" onclick="zoomCanvas(-0.1)">🔍-</button>
        <button class="btn btn-outline btn-small" onclick="resetZoom()">↺</button>
        <button class="btn btn-outline btn-small" id="gridBtn" onclick="toggleGrid()" title="显示/隐藏网格">📏</button>
      </div>
    </div>
    <div id="editBody">
      <div id="canvasWrap">
        <div id="canvasContainer">
          <div id="postcardCanvas"></div>
          <div id="canvasOverlay"></div>
        </div>
      </div>
      <div id="formSidebar"></div>
    </div>
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
let canvasZoom = 1;
let zoomOffset = 0;
let showGrid = false;
let activeEl = null; // currently selected canvas element
let dragState = null; // { el, type:'move'|'rotate'|'resize', startX, startY, startLeft, startTop, startRot, startScale, corner }
let _defaults = { template: '', stamp: '', postmark: '' };
let allStamps = []; // cached stamps for stamp selector
let allPostmarks = []; // cached postmarks for postmark selector
let selectedIds = new Set(); // batch selection
let currentGroup = ''; // current group filter (empty = all)

// ============== API ==============
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
  if(d.success){token=d.token;localStorage.setItem('token',token);load(1);refreshGroupTabs();}
  else alert('密码错误');
}

async function loadAllMaterials() {
  try {
    const [stamps, postmarks] = await Promise.all([
      api('/api/materials/stamps?limit=2000'),
      api('/api/materials/postmarks?limit=2000')
    ]);
    allStamps = stamps.items || [];
    allPostmarks = postmarks.items || [];
  } catch(e) {}
}

async function loadAllTemplates() {
  // Load all published templates to extract group names
  try {
    const data = await api('/api/materials/templates?limit=2000&status=published_free,published_member');
    return data.items || [];
  } catch(e) { return []; }
}

async function refreshGroupTabs() {
  if (currentTab !== 'templates') {
    document.getElementById('groupBar').style.display = 'none';
    return;
  }
  document.getElementById('groupBar').style.display = 'flex';
  const allTemplates = await loadAllTemplates();
  const groups = new Set();
  allTemplates.forEach(t => { if (t.template_group) groups.add(t.template_group); });
  // Also include templates from cachedItems (which may include drafts)
  cachedItems.forEach(t => { if (t.template_group) groups.add(t.template_group); });
  // Sort by saved group_order
  let sortedGroups = Array.from(groups).sort();
  try {
    const cfg = await api('/api/materials/config');
    if (cfg.group_order && cfg.group_order.length > 0) {
      const ordered = cfg.group_order.filter(g => groups.has(g));
      const remaining = sortedGroups.filter(g => !cfg.group_order.includes(g));
      sortedGroups = [...ordered, ...remaining];
    }
  } catch(e) {}
  const tabsHtml = sortedGroups.map(g =>
    `<button class="group-tab${currentGroup === g ? ' active' : ''}" data-group="${g}" onclick="filterByGroup('${g.replace(/'/g, "\\'")}')">${g}</button>`
  ).join('');
  document.getElementById('groupTabs').innerHTML = tabsHtml;
  // Update "全部" active state
  const allBtn = document.querySelector('#groupBar .group-tab[data-group=""]');
  if (allBtn) allBtn.className = 'group-tab' + (currentGroup === '' ? ' active' : '');
}

function filterByGroup(group) {
  currentGroup = group;
  currentPage = 1;
  load(1);
  refreshGroupTabs();
}

async function createGroup() {
  const name = prompt('请输入新分组名称:');
  if (!name || !name.trim()) return;
  const groupName = name.trim();
  // Create a draft template in this group so it persists immediately
  const newId = 'group_' + Date.now().toString(36);
  try {
    await api('/api/materials/templates', 'POST', {
      id: newId, name: '未命名模板', template_group: groupName, status: 'draft'
    });
  } catch(e) { console.error('Failed to create group template:', e); }
  currentGroup = groupName;
  currentPage = 1;
  await refreshGroupTabs();
  load(1);
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
  if (currentGroup && currentTab === 'templates') url += `&group=${encodeURIComponent(currentGroup)}`;
  try {
    const [data, cfg] = await Promise.all([api(url), api('/api/materials/config').catch(() => ({}))]);
    totalCount = data.total || 0;
    cachedItems = data.items || [];
    _defaults = { template: cfg.default_template || '', stamp: cfg.default_stamp || '', postmark: cfg.default_postmark || '' };
    render(cachedItems);
    renderPagination();
    if (currentTab === 'templates') loadAllMaterials();
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
  if(!items.length){el.innerHTML='<div class="empty">暂无数据</div>';updateBatchBar();return}
  el.innerHTML=items.map(item=>{
    const isChecked = selectedIds.has(item.id);
    let previewHtml, sub;
    const stBadge = `<span class="badge badge-${item.status||'draft'}">${statusLabel(item.status)}</span>`;
    const defaultKey = currentTab === 'templates' ? 'template' : currentTab === 'stamps' ? 'stamp' : 'postmark';
    const isDefault = _defaults[defaultKey] === item.id;
    const defaultStar = `<span title="${isDefault?'取消默认':'设为默认'}" onclick="event.stopPropagation();setDefaultMaterial('${currentTab}','${item.id}')" style="cursor:pointer;font-size:14px;margin-left:4px">${isDefault?'⭐':'☆'}</span>`;
    if(currentTab==='templates'){
      const grad=`linear-gradient(135deg,#${item.gradient_from},#${item.gradient_mid||item.gradient_from},#${item.gradient_to})`;
      const bgImg=item.image_url?`background-image:url(${item.image_url});background-size:cover;`:'';
      previewHtml=`<div class="preview" style="background:${grad};${bgImg}border-radius:${item.corner_radius}px">🎨</div>`;
      sub=`${item.id} · 圆角${item.corner_radius}px · ${item.pattern||'无图案'}`;
    } else if(currentTab==='stamps'){
      const bgImg=item.image_url?`background-image:url(${item.image_url});background-size:cover;`:'';
      previewHtml=`<div class="preview" style="${bgImg}background-color:#2A2A4A">${item.image_url?'':'🏷'}</div>`;
      sub=`${item.id} · ${item.label||''} · #${item.accent_color}`;
    } else {
      const bgImg=item.image_url?`background-image:url(${item.image_url});background-size:cover;`:'';
      previewHtml=`<div class="preview" style="${bgImg}background-color:#2A2A4A">🔘</div>`;
      sub=`${item.id} · ${item.date_text} · #${item.color}`;
    }
    return `<div class="card${selectedItem&&selectedItem.id===item.id?' selected':''}">
      <input type="checkbox" class="card-check show" ${isChecked?'checked':''} onclick="event.stopPropagation();toggleSelect('${item.id}')">
      <div style="display:flex;align-items:center;gap:10px;flex:1;min-width:0" onclick="selectItem('${item.id}')" style="cursor:pointer">
        ${previewHtml}
        <div class="info">
          <div class="title-row"><span class="title">${item.name||item.label}</span>${stBadge}${defaultStar}</div>
          <div class="sub">${sub}</div>
        </div>
      </div>
    </div>`;
  }).join('');
  updateBatchBar();
}

async function selectItem(id){
  await autoSave();
  selectedItem = cachedItems.find(i => i.id === id) || null;
  render(cachedItems);
  if(selectedItem){editingId=id;showEditPanel()}
}

async function addNew(){
  editingId=null;selectedItem=null;
  await loadAllMaterials();
  if(currentTab==='templates'){
    // Try to load TPL_016 as default template base
    try {
      const defaultTpl = await api('/api/materials/templates/TPL_016');
      if (defaultTpl && defaultTpl.id) {
        selectedItem = { ...defaultTpl };
        selectedItem.id = generateAutoId();
        selectedItem.name = '';
        selectedItem.template_group = defaultTpl.template_group || '默认';
        delete selectedItem.created_at;
        delete selectedItem.updated_at;
      } else {
        selectedItem = getDefaultTemplate();
      }
    } catch(e) {
      selectedItem = getDefaultTemplate();
    }
  } else if(currentTab==='stamps'){
    selectedItem = {
      id: generateAutoId(), label: '', accent_color: 'FFB7C5', image_url: null, status: 'published_free'
    };
  } else {
    selectedItem = {
      id: generateAutoId(), label: '', date_text: '2026.05.13', color: '333333', image_url: null, status: 'published_free'
    };
  }
  load(currentPage);
  showEditPanel();
}

function getDefaultTemplate() {
  return {
    id: generateAutoId(), name: '', template_group: '默认',
    gradient_from: 'FFF0F5', gradient_to: 'FFC0CB', gradient_mid: 'FFE4E1',
    corner_radius: 8, pattern: '', image_url: null, image_fit: 'cover', status: 'published_free',
    from_font:'sans-serif',to_font:'sans-serif',message_font:'sans-serif',
    from_color:'333333',to_color:'333333',message_color:'555555',
    from_size:14,to_size:14,message_size:13,
    from_x:18,from_y:88,to_x:60,to_y:88,message_x:8,message_y:40,message_w:82,message_h:70,
    stamp_x:85,stamp_y:14,stamp_rotation:0,stamp_scale:100,
    postmark_x:50,postmark_y:50,postmark_rotation:0,postmark_scale:100,
    from_w:120,from_h:28,to_w:120,to_h:28,
    from_border_color:'CCCCCC',to_border_color:'CCCCCC',
    from_border_width:0,to_border_width:0,
    from_bg_color:'FFFFFF',to_bg_color:'FFFFFF',
    from_bg_opacity:0,to_bg_opacity:0
  };
}

function showEditPanel(){
  document.getElementById('placeholder').style.display='none';
  document.getElementById('editPanel').classList.add('show');
  document.getElementById('editTitle').textContent=editingId?'编辑素材':'新增素材';
  activeEl = null;
  renderForm();
  renderCanvas();
}

async function hideEditPanel(){
  await autoSave();
  document.getElementById('editPanel').classList.remove('show');
  document.getElementById('placeholder').style.display='flex';
}

// ============== FONT LIST ==============
const FONT_LIST = [
  'sans-serif', 'serif', 'monospace', 'cursive',
  'Noto Sans SC', 'Noto Serif SC', 'ZCOOL KuaiLe', 'Ma Shan Zheng',
  'Long Cang', 'ZCOOL XiaoWei',
  'Arial', 'Helvetica', 'Georgia', 'Times New Roman', 'Courier New',
  'Verdana', 'Trebuchet MS', 'Palatino Linotype', 'Comic Sans MS', 'Impact'
];

// ============== AUTO ID ==============
function generateAutoId() {
  const prefixes = { templates: 'TPL', stamps: 'STP', postmarks: 'PMK' };
  const prefix = prefixes[currentTab] || 'ITM';
  let maxNum = 0;
  const pattern = new RegExp('^' + prefix + '[-_]?(\\d+)$', 'i');
  cachedItems.forEach(item => {
    const match = item.id && item.id.match(pattern);
    if (match) {
      const n = parseInt(match[1]);
      if (n > maxNum) maxNum = n;
    }
  });
  return prefix + '-' + String(maxNum + 1).padStart(3, '0');
}

// ============== FORM RENDERING ==============
function renderForm(){
  const f=document.getElementById('formSidebar');
  const item=selectedItem||{};
  let html='';

  if(currentTab==='templates'){
    // Top action buttons
    html+=`<div class="actions" style="margin-top:0;padding-top:0;margin-bottom:14px;border-bottom:1px solid #2A2A4A">
      <button class="btn btn-primary btn-small" onclick="saveItem()">💾 保存</button>
      <button class="btn btn-outline btn-small" onclick="saveAsItem()">📋 另存为</button>
      ${editingId?`<button class="btn btn-danger btn-small" onclick="deleteItem()">🗑 删除</button>`:''}
      <button class="btn btn-outline btn-small" onclick="hideEditPanel()">取消</button>
    </div>`;
    // --- Basic info ---
    html+=`<div class="section">
      <h4>📋 基本信息</h4>
      <div class="form-row">
        <div class="form-group"><label>ID</label><input id="f_id" value="${item.id||''}" ${editingId?'disabled':''} placeholder="自动生成">
          ${!editingId?'<button class="btn btn-outline btn-small" style="margin-top:4px;width:100%" onclick="document.getElementById(\'f_id\').value=generateAutoId()">🔄 自动编号</button>':''}
        </div>
        <div class="form-group"><label>名称</label><input id="f_name" value="${item.name||''}" placeholder="花卉"></div>
        <div class="form-group"><label>分组</label><input id="f_group" value="${item.template_group||'默认'}" placeholder="默认" list="groupList"><datalist id="groupList"></datalist></div>
      </div>
    </div>`;

    // --- Background section ---
    html+=`<div class="section">
      <h4 class="section-toggle" onclick="toggleSection(this)"><span class="arrow">▼</span> 🎨 背景设置</h4>
      <div class="section-content" style="max-height:600px">
      <div class="form-row">
        <div class="form-group"><label>渐变起始</label><div class="color-row"><input type="color" id="f_from_pick" value="#${item.gradient_from||'FFF0F5'}" onchange="syncColor(this,'f_from')"><input id="f_from" value="${item.gradient_from||'FFF0F5'}" oninput="syncPick(this,'f_from_pick')"></div></div>
        <div class="form-group"><label>渐变中间</label><div class="color-row"><input type="color" id="f_mid_pick" value="#${item.gradient_mid||item.gradient_from||'FFE4E1'}" onchange="syncColor(this,'f_mid')"><input id="f_mid" value="${item.gradient_mid||''}" oninput="syncPick(this,'f_mid_pick')" placeholder="可选"></div></div>
        <div class="form-group"><label>渐变结束</label><div class="color-row"><input type="color" id="f_to_pick" value="#${item.gradient_to||'FFC0CB'}" onchange="syncColor(this,'f_to')"><input id="f_to" value="${item.gradient_to||'FFC0CB'}" oninput="syncPick(this,'f_to_pick')"></div></div>
      </div>
      <div class="form-row">
        <div class="form-group"><label>圆角</label><input id="f_radius" type="number" value="${item.corner_radius||8}" min="0" max="40"></div>
        <div class="form-group"><label>装饰图案</label><select id="f_pattern">
          <option value="">无</option>
          <option value="floral" ${item.pattern==='floral'?'selected':''}>🌸 花卉</option>
          <option value="geometric" ${item.pattern==='geometric'?'selected':''}>🔷 几何</option>
          <option value="vintage" ${item.pattern==='vintage'?'selected':''}>📮 复古</option>
          <option value="nature" ${item.pattern==='nature'?'selected':''}>🌿 自然</option>
          <option value="ocean" ${item.pattern==='ocean'?'selected':''}>🌊 海洋</option>
          <option value="minimalist" ${item.pattern==='minimalist'?'selected':''}>✨ 极简</option>
        </select></div>
      </div>
      </div>
    </div>`;

    // --- From text section ---
    html+=`<div class="section">
      <h4 class="section-toggle" onclick="toggleSection(this)"><span class="arrow">▼</span> ✉️ 寄件人</h4>
      <div class="section-content" style="max-height:800px">
      <div class="form-group"><label>字体</label><select id="f_from_font">${FONT_LIST.map(f=>`<option value="${f}" ${(item.from_font||'sans-serif')===f?'selected':''}>${f}</option>`).join('')}</select></div>
      <div class="form-row">
        <div class="form-group"><label>颜色</label><div class="color-row"><input type="color" id="f_from_color_pick" value="#${item.from_color||'333333'}" onchange="syncColor(this,'f_from_color')"><input id="f_from_color" value="${item.from_color||'333333'}" oninput="syncPick(this,'f_from_color_pick')"></div></div>
        <div class="form-group"><label>字号</label><input id="f_from_size" type="number" value="${item.from_size||14}" min="8" max="48"></div>
      </div>
      <div class="form-row-3">
        <div class="form-group"><label>X%</label><input id="f_from_x" type="number" value="${item.from_x||10}" min="0" max="100"></div>
        <div class="form-group"><label>Y%</label><input id="f_from_y" type="number" value="${item.from_y||82}" min="0" max="100"></div>
      </div>
      <div class="form-row-3">
        <div class="form-group"><label>宽(px)</label><input id="f_from_w" type="number" value="${item.from_w||120}" min="50" max="400"></div>
        <div class="form-group"><label>高(px)</label><input id="f_from_h" type="number" value="${item.from_h||28}" min="16" max="200"></div>
      </div>
      <div class="form-row">
        <div class="form-group"><label>边框色</label><div class="color-row"><input type="color" id="f_from_border_color_pick" value="#${item.from_border_color||'CCCCCC'}" onchange="syncColor(this,'f_from_border_color')"><input id="f_from_border_color" value="${item.from_border_color||'CCCCCC'}" oninput="syncPick(this,'f_from_border_color_pick')"></div></div>
        <div class="form-group"><label>边框宽</label><input id="f_from_border_width" type="number" value="${item.from_border_width||0}" min="0" max="10"></div>
      </div>
      <div class="form-row">
        <div class="form-group"><label>背景色</label><div class="color-row"><input type="color" id="f_from_bg_color_pick" value="#${item.from_bg_color||'FFFFFF'}" onchange="syncColor(this,'f_from_bg_color')"><input id="f_from_bg_color" value="${item.from_bg_color||'FFFFFF'}" oninput="syncPick(this,'f_from_bg_color_pick')"></div></div>
        <div class="form-group"><label>背景透明度</label><input id="f_from_bg_opacity" type="number" value="${item.from_bg_opacity||0}" min="0" max="100"></div>
      </div>
      <div class="align-btns" style="padding-top:4px">
        <button title="左对齐" onclick="alignEl('from','left')">⬅</button>
        <button title="居中" onclick="alignEl('from','center')">⬛</button>
        <button title="右对齐" onclick="alignEl('from','right')">➡</button>
      </div>
      </div>
    </div>`;

    // --- To text section ---
    html+=`<div class="section">
      <h4 class="section-toggle" onclick="toggleSection(this)"><span class="arrow">▼</span> 📬 收件人</h4>
      <div class="section-content" style="max-height:800px">
      <div class="form-group"><label>字体</label><select id="f_to_font">${FONT_LIST.map(f=>`<option value="${f}" ${(item.to_font||'sans-serif')===f?'selected':''}>${f}</option>`).join('')}</select></div>
      <div class="form-row">
        <div class="form-group"><label>颜色</label><div class="color-row"><input type="color" id="f_to_color_pick" value="#${item.to_color||'333333'}" onchange="syncColor(this,'f_to_color')"><input id="f_to_color" value="${item.to_color||'333333'}" oninput="syncPick(this,'f_to_color_pick')"></div></div>
        <div class="form-group"><label>字号</label><input id="f_to_size" type="number" value="${item.to_size||14}" min="8" max="48"></div>
      </div>
      <div class="form-row-3">
        <div class="form-group"><label>X%</label><input id="f_to_x" type="number" value="${item.to_x||55}" min="0" max="100"></div>
        <div class="form-group"><label>Y%</label><input id="f_to_y" type="number" value="${item.to_y||82}" min="0" max="100"></div>
      </div>
      <div class="form-row-3">
        <div class="form-group"><label>宽(px)</label><input id="f_to_w" type="number" value="${item.to_w||120}" min="50" max="400"></div>
        <div class="form-group"><label>高(px)</label><input id="f_to_h" type="number" value="${item.to_h||28}" min="16" max="200"></div>
      </div>
      <div class="form-row">
        <div class="form-group"><label>边框色</label><div class="color-row"><input type="color" id="f_to_border_color_pick" value="#${item.to_border_color||'CCCCCC'}" onchange="syncColor(this,'f_to_border_color')"><input id="f_to_border_color" value="${item.to_border_color||'CCCCCC'}" oninput="syncPick(this,'f_to_border_color_pick')"></div></div>
        <div class="form-group"><label>边框宽</label><input id="f_to_border_width" type="number" value="${item.to_border_width||0}" min="0" max="10"></div>
      </div>
      <div class="form-row">
        <div class="form-group"><label>背景色</label><div class="color-row"><input type="color" id="f_to_bg_color_pick" value="#${item.to_bg_color||'FFFFFF'}" onchange="syncColor(this,'f_to_bg_color')"><input id="f_to_bg_color" value="${item.to_bg_color||'FFFFFF'}" oninput="syncPick(this,'f_to_bg_color_pick')"></div></div>
        <div class="form-group"><label>背景透明度</label><input id="f_to_bg_opacity" type="number" value="${item.to_bg_opacity||0}" min="0" max="100"></div>
      </div>
      <div class="align-btns" style="padding-top:4px">
        <button title="左对齐" onclick="alignEl('to','left')">⬅</button>
        <button title="居中" onclick="alignEl('to','center')">⬛</button>
        <button title="右对齐" onclick="alignEl('to','right')">➡</button>
      </div>
      </div>
    </div>`;

    // --- Message text section ---
    html+=`<div class="section">
      <h4 class="section-toggle" onclick="toggleSection(this)"><span class="arrow">▼</span> 💬 祝福语</h4>
      <div class="section-content" style="max-height:500px">
      <div class="form-group"><label>字体</label><select id="f_message_font">${FONT_LIST.map(f=>`<option value="${f}" ${(item.message_font||'sans-serif')===f?'selected':''}>${f}</option>`).join('')}</select></div>
      <div class="form-row">
        <div class="form-group"><label>颜色</label><div class="color-row"><input type="color" id="f_message_color_pick" value="#${item.message_color||'555555'}" onchange="syncColor(this,'f_message_color')"><input id="f_message_color" value="${item.message_color||'555555'}" oninput="syncPick(this,'f_message_color_pick')"></div></div>
        <div class="form-group"><label>字号</label><input id="f_message_size" type="number" value="${item.message_size||13}" min="8" max="48"></div>
      </div>
      <div class="form-row-3">
        <div class="form-group"><label>X%</label><input id="f_message_x" type="number" value="${item.message_x||10}" min="0" max="100"></div>
        <div class="form-group"><label>Y%</label><input id="f_message_y" type="number" value="${item.message_y||60}" min="0" max="100"></div>
        <div class="form-group xs"><label>宽%</label><input id="f_message_w" type="number" value="${item.message_w||80}" min="10" max="100"></div>
      </div>
      <div class="form-row-3" style="margin-top:6px">
        <div class="form-group xs"><label>高(px)</label><input id="f_message_h" type="number" value="${item.message_h||80}" min="30" max="300"></div>
      </div>
      </div>
    </div>`;

    // --- Stamp position section ---
    html+=`<div class="section">
      <h4 class="section-toggle" onclick="toggleSection(this)"><span class="arrow">▼</span> 🏷 邮票占位</h4>
      <div class="section-content" style="max-height:500px">
      <p style="font-size:10px;color:#888;margin-bottom:8px">虚线框表示邮票默认位置与大小</p>
      <div class="form-row-3">
        <div class="form-group"><label>X%</label><input id="f_stamp_x" type="number" value="${item.stamp_x||78}" min="0" max="100"></div>
        <div class="form-group"><label>Y%</label><input id="f_stamp_y" type="number" value="${item.stamp_y||5}" min="0" max="100"></div>
        <div class="form-group xs"><label>旋转°</label><input id="f_stamp_rotation" type="number" value="${item.stamp_rotation||0}" min="-180" max="180"></div>
      </div>
      <div class="form-group"><label>缩放</label><div class="range-row"><input type="range" id="f_stamp_scale" min="50" max="500" value="${item.stamp_scale||100}" oninput="document.getElementById('f_stamp_scale_val').textContent=this.value+'%'"><span class="range-val" id="f_stamp_scale_val">${item.stamp_scale||100}%</span></div></div>
      </div>
    </div>`;

    // --- Postmark position section ---
    html+=`<div class="section">
      <h4 class="section-toggle" onclick="toggleSection(this)"><span class="arrow">▼</span> 🔵 邮戳占位</h4>
      <div class="section-content" style="max-height:500px">
      <p style="font-size:10px;color:#888;margin-bottom:8px">虚线圆表示邮戳默认位置</p>
      <div class="form-row-3">
        <div class="form-group"><label>X%</label><input id="f_postmark_x" type="number" value="${item.postmark_x||45}" min="0" max="100"></div>
        <div class="form-group"><label>Y%</label><input id="f_postmark_y" type="number" value="${item.postmark_y||45}" min="0" max="100"></div>
        <div class="form-group xs"><label>旋转°</label><input id="f_postmark_rotation" type="number" value="${item.postmark_rotation||0}" min="-180" max="180"></div>
      </div>
      <div class="form-group"><label>缩放</label><div class="range-row"><input type="range" id="f_postmark_scale" min="50" max="500" value="${item.postmark_scale||100}" oninput="document.getElementById('f_pmk_scale_val').textContent=this.value+'%'"><span class="range-val" id="f_pmk_scale_val">${item.postmark_scale||100}%</span></div></div>
      </div>
    </div>`;

    // --- Quick alignment ---
    html+=`<div class="section">
      <h4>📐 快速对齐</h4>
      <div class="align-btns">
        <button onclick="alignAll('left')">全部左对齐</button>
        <button onclick="alignAll('center')">全部居中</button>
        <button onclick="alignAll('right')">全部右对齐</button>
        <button onclick="alignAll('distribute-v')">垂直等距</button>
      </div>
    </div>`;

  } else if(currentTab==='stamps'){
    html+=`<div class="actions" style="margin-top:0;padding-top:0;margin-bottom:14px;border-bottom:1px solid #2A2A4A">
      <button class="btn btn-primary btn-small" onclick="saveItem()">💾 保存</button>
      <button class="btn btn-outline btn-small" onclick="saveAsItem()">📋 另存为</button>
      ${editingId?`<button class="btn btn-danger btn-small" onclick="deleteItem()">🗑 删除</button>`:''}
      <button class="btn btn-outline btn-small" onclick="hideEditPanel()">取消</button>
    </div>`;
    html+=`<div class="section">
      <h4>🏷 邮票信息</h4>
      <div class="form-row">
        <div class="form-group"><label>ID</label><input id="f_id" value="${item.id||''}" ${editingId?'disabled':''} placeholder="自动生成">
          ${!editingId?'<button class="btn btn-outline btn-small" style="margin-top:4px;width:100%" onclick="document.getElementById(\'f_id\').value=generateAutoId()">🔄 自动编号</button>':''}
        </div>
        <div class="form-group"><label>标签</label><input id="f_label" value="${item.label||''}" placeholder="樱花"></div>
      </div>
      <div class="form-group"><label>强调色</label><div class="color-row"><input type="color" id="f_color_pick" value="#${item.accent_color||'FFB7C5'}" onchange="syncColor(this,'f_color')"><input id="f_color" value="${item.accent_color||'FFB7C5'}" oninput="syncPick(this,'f_color_pick')"></div></div>
    </div>`;

  } else {
    html+=`<div class="actions" style="margin-top:0;padding-top:0;margin-bottom:14px;border-bottom:1px solid #2A2A4A">
      <button class="btn btn-primary btn-small" onclick="saveItem()">💾 保存</button>
      <button class="btn btn-outline btn-small" onclick="saveAsItem()">📋 另存为</button>
      ${editingId?`<button class="btn btn-danger btn-small" onclick="deleteItem()">🗑 删除</button>`:''}
      <button class="btn btn-outline btn-small" onclick="hideEditPanel()">取消</button>
    </div>`;
    html+=`<div class="section">
      <h4>🔵 邮戳信息</h4>
      <div class="form-row">
        <div class="form-group"><label>ID</label><input id="f_id" value="${item.id||''}" ${editingId?'disabled':''} placeholder="自动生成">
          ${!editingId?'<button class="btn btn-outline btn-small" style="margin-top:4px;width:100%" onclick="document.getElementById(\'f_id\').value=generateAutoId()">🔄 自动编号</button>':''}
        </div>
        <div class="form-group"><label>标签</label><input id="f_label" value="${item.label||''}" placeholder="经典圆形"></div>
      </div>
      <div class="form-row">
        <div class="form-group"><label>日期文字</label><input id="f_date" value="${item.date_text||'2026.05.13'}"></div>
        <div class="form-group"><label>颜色</label><div class="color-row"><input type="color" id="f_color_pick" value="#${item.color||'333333'}" onchange="syncColor(this,'f_color')"><input id="f_color" value="${item.color||'333333'}" oninput="syncPick(this,'f_color_pick')"></div></div>
      </div>
    </div>`;
  }

  // --- Status ---
  html+=`<div class="section">
    <h4>📋 发布状态</h4>
    <div class="form-group"><select id="f_status">
      <option value="draft" ${item.status==='draft'?'selected':''}>待发布</option>
      <option value="published_free" ${(item.status||'published_free')==='published_free'?'selected':''}>发布-免费</option>
      <option value="published_member" ${item.status==='published_member'?'selected':''}>发布-会员</option>
    </select></div>
  </div>`;

  // --- Image section ---
  const imgUrl = item.image_url || '';
  html+=`<div class="section">
    <h4>🖼 图片设置（可选）</h4>
    <div class="img-preview-wrap" style="display:flex;align-items:center;gap:10px;margin-bottom:10px">
      <div class="img-thumb" id="imgThumb" style="width:60px;height:45px;border-radius:6px;background:#2A2A4A;background-size:cover;background-position:center;border:1px solid #444;display:flex;align-items:center;justify-content:center;font-size:20px;color:#555;${imgUrl?`background-image:url(${imgUrl})`:''}">${imgUrl?'':'📷'}</div>
      <div style="flex:1;font-size:11px;color:#888">${imgUrl?'已设置图片':'上传图片或输入URL'}<br>${imgUrl?`<a href="#" onclick="clearImage()" style="color:#C62828;font-size:10px">清除图片</a>`:''}</div>
    </div>
    <div style="margin-bottom:8px">
      <input type="file" accept="image/*" onchange="pickImage(this)" style="display:none" id="fileInput">
      <button class="btn btn-outline btn-small" onclick="document.getElementById('fileInput').click()">📁 上传图片文件</button>
    </div>
    <div class="img-url-row" style="display:flex;gap:6px">
      <input id="f_image_url" value="${imgUrl}" placeholder="或输入图片URL" style="flex:1">
      <button class="btn btn-outline btn-small" onclick="applyUrl()">应用</button>
    </div>
    <div style="margin-top:8px">
      <label style="font-size:11px;color:#888;display:block;margin-bottom:4px">图片布局</label>
      <select id="f_image_fit" style="width:100%">
        <option value="cover" ${(item.image_fit||'cover')==='cover'?'selected':''}>平铺填满</option>
        <option value="contain" ${item.image_fit==='contain'?'selected':''}>居中完整</option>
        <option value="fill" ${item.image_fit==='fill'?'selected':''}>拉伸填满</option>
        <option value="fitWidth" ${item.image_fit==='fitWidth'?'selected':''}>适配宽度</option>
        <option value="fitHeight" ${item.image_fit==='fitHeight'?'selected':''}>适配高度</option>
      </select>
    </div>
  </div>`;

  // --- Actions ---
  html+=`<div class="actions">
    <button class="btn btn-primary" onclick="saveItem()">💾 保存</button>
    <button class="btn btn-outline" onclick="saveAsItem()">📋 另存为</button>
    ${editingId?`<button class="btn btn-danger" onclick="deleteItem()">🗑 删除</button>`:''}
    <button class="btn btn-outline" onclick="hideEditPanel()">取消</button>
  </div>`;

  f.innerHTML=html;

  // Populate group datalist for templates
  if (currentTab === 'templates') {
    const groupList = document.getElementById('groupList');
    if (groupList) {
      const allGroups = new Set();
      cachedItems.forEach(t => { if (t.template_group) allGroups.add(t.template_group); });
      groupList.innerHTML = Array.from(allGroups).sort().map(g => `<option value="${g}">`).join('');
    }
  }

  // Live update on form changes
  f.querySelectorAll('input,select').forEach(el=>{
    el.addEventListener('input', () => { renderCanvas(); });
    el.addEventListener('change', () => { renderCanvas(); });
  });
}

// ============== COLOR SYNC ==============
function syncColor(picker, textId) {
  const hex = picker.value.replace('#','');
  document.getElementById(textId).value = hex;
  renderCanvas();
}
function syncPick(textInput, pickerId) {
  const picker = document.getElementById(pickerId);
  if (!picker) return;
  const v = textInput.value.replace('#','');
  if (v.length === 6) picker.value = '#' + v;
  renderCanvas();
}

// ============== SECTION TOGGLE ==============
function toggleSection(h4) {
  h4.classList.toggle('collapsed');
  h4.nextElementSibling.classList.toggle('collapsed');
}

// ============== CANVAS RENDERING ==============
function getFormData(){
  const data={};
  if(currentTab==='templates'){
    data.id=document.getElementById('f_id')?.value||'';
    data.name=document.getElementById('f_name')?.value||'';
    data.template_group=document.getElementById('f_group')?.value||'默认';
    data.gradient_from=document.getElementById('f_from')?.value||'FFF0F5';
    data.gradient_mid=document.getElementById('f_mid')?.value||null;
    data.gradient_to=document.getElementById('f_to')?.value||'FFC0CB';
    data.corner_radius=parseInt(document.getElementById('f_radius')?.value)||8;
    data.pattern=document.getElementById('f_pattern')?.value||null;
    data.from_font=document.getElementById('f_from_font')?.value||'sans-serif';
    data.to_font=document.getElementById('f_to_font')?.value||'sans-serif';
    data.message_font=document.getElementById('f_message_font')?.value||'sans-serif';
    data.from_color=document.getElementById('f_from_color')?.value||'333333';
    data.to_color=document.getElementById('f_to_color')?.value||'333333';
    data.message_color=document.getElementById('f_message_color')?.value||'555555';
    data.from_size=parseInt(document.getElementById('f_from_size')?.value)||14;
    data.to_size=parseInt(document.getElementById('f_to_size')?.value)||14;
    data.message_size=parseInt(document.getElementById('f_message_size')?.value)||13;
    data.from_x=parseInt(document.getElementById('f_from_x')?.value)||18;
    data.from_y=parseInt(document.getElementById('f_from_y')?.value)||88;
    data.to_x=parseInt(document.getElementById('f_to_x')?.value)||60;
    data.to_y=parseInt(document.getElementById('f_to_y')?.value)||88;
    data.message_x=parseInt(document.getElementById('f_message_x')?.value)||8;
    data.message_y=parseInt(document.getElementById('f_message_y')?.value)||40;
    data.message_w=parseInt(document.getElementById('f_message_w')?.value)||82;
    data.message_h=parseInt(document.getElementById('f_message_h')?.value)||70;
    data.stamp_x=parseInt(document.getElementById('f_stamp_x')?.value)||85;
    data.stamp_y=parseInt(document.getElementById('f_stamp_y')?.value)||14;
    data.stamp_rotation=parseInt(document.getElementById('f_stamp_rotation')?.value)||0;
    data.stamp_scale=parseInt(document.getElementById('f_stamp_scale')?.value)||100;
    data.postmark_x=parseInt(document.getElementById('f_postmark_x')?.value)||50;
    data.postmark_y=parseInt(document.getElementById('f_postmark_y')?.value)||50;
    data.postmark_rotation=parseInt(document.getElementById('f_postmark_rotation')?.value)||0;
    data.postmark_scale=parseInt(document.getElementById('f_postmark_scale')?.value)||100;
    data.from_w=parseInt(document.getElementById('f_from_w')?.value)||120;
    data.from_h=parseInt(document.getElementById('f_from_h')?.value)||28;
    data.to_w=parseInt(document.getElementById('f_to_w')?.value)||120;
    data.to_h=parseInt(document.getElementById('f_to_h')?.value)||28;
    data.from_border_color=document.getElementById('f_from_border_color')?.value||'CCCCCC';
    data.to_border_color=document.getElementById('f_to_border_color')?.value||'CCCCCC';
    data.from_border_width=parseInt(document.getElementById('f_from_border_width')?.value)||0;
    data.to_border_width=parseInt(document.getElementById('f_to_border_width')?.value)||0;
    data.from_bg_color=document.getElementById('f_from_bg_color')?.value||'FFFFFF';
    data.to_bg_color=document.getElementById('f_to_bg_color')?.value||'FFFFFF';
    data.from_bg_opacity=parseInt(document.getElementById('f_from_bg_opacity')?.value)||0;
    data.to_bg_opacity=parseInt(document.getElementById('f_to_bg_opacity')?.value)||0;
  } else if(currentTab==='stamps'){
    data.id=document.getElementById('f_id')?.value||'';
    data.label=document.getElementById('f_label')?.value||'';
    data.emoji='📮';
    data.accent_color=document.getElementById('f_color')?.value||'FFB7C5';
  } else {
    data.id=document.getElementById('f_id')?.value||'';
    data.label=document.getElementById('f_label')?.value||'';
    data.date_text=document.getElementById('f_date')?.value||'2026.05.13';
    data.color=document.getElementById('f_color')?.value||'333333';
  }
  data.status=document.getElementById('f_status')?.value||'published_free';
  data.image_url=document.getElementById('f_image_url')?.value||null;
  data.image_fit=document.getElementById('f_image_fit')?.value||'cover';
  return data;
}

function renderCanvas(){
  const canvas = document.getElementById('postcardCanvas');
  const overlay = document.getElementById('canvasOverlay');
  const data = getFormData();

  if(currentTab==='templates'){
    const grad=`linear-gradient(135deg,#${data.gradient_from||'FFF0F5'},#${data.gradient_mid||data.gradient_from||'FFF0F5'},#${data.gradient_to||'FFC0CB'})`;
    const fitMap={cover:'cover',contain:'contain',fill:'100% 100%',fitWidth:'100% auto',fitHeight:'auto 100%'};
    const bgSize=fitMap[data.image_fit]||'cover';
    const bgImg=data.image_url?`background-image:url(${data.image_url});background-size:${bgSize};background-position:center;background-repeat:no-repeat;background-blend-mode:overlay;`:'';
    const patternEmoji = data.pattern==='floral'?'🌸':data.pattern==='geometric'?'🔷':data.pattern==='vintage'?'📮':data.pattern==='nature'?'🌿':data.pattern==='ocean'?'🌊':data.pattern==='minimalist'?'✨':'';

    canvas.innerHTML = ''; // clear any leftover from other tabs
    canvas.style.cssText = `position:absolute;inset:0;background:${grad};${bgImg}border-radius:${data.corner_radius||8}px;overflow:hidden`;

    // Grid lines
    if (showGrid) {
      let gridHTML = '';
      for (let i = 10; i < 100; i += 10) {
        gridHTML += `<div class="grid-line grid-v" style="left:${i}%"></div>`;
        gridHTML += `<div class="grid-line grid-h" style="top:${i}%"></div>`;
      }
      canvas.innerHTML += gridHTML;
    }

    let overlayHTML = '';
    if(patternEmoji){
      overlayHTML += `<div style="position:absolute;top:10px;right:14px;font-size:22px;opacity:0.25;pointer-events:none">${patternEmoji}</div>`;
    }
    // From text element
    const fromW = data.from_w || 120;
    const fromH = data.from_h || 28;
    const fromBorderW = data.from_border_width || 0;
    const fromBorderC = data.from_border_color || 'CCCCCC';
    const fromBgC = data.from_bg_color || 'FFFFFF';
    const fromBgO = (data.from_bg_opacity || 0) / 100;
    overlayHTML += `<div class="canvas-placeholder${activeEl==='from'?' selected':''}" id="el-from"
      style="left:${data.from_x||10}%;top:${data.from_y||82}%;width:${fromW}px;height:${fromH}px;transform:translate(-50%,-50%);font-family:'${data.from_font||'sans-serif'}',sans-serif;font-size:${data.from_size||14}px;color:#${data.from_color||'333333'};border:${fromBorderW}px solid #${fromBorderC};background:rgba(${parseInt(fromBgC.substr(0,2),16)},${parseInt(fromBgC.substr(2,2),16)},${parseInt(fromBgC.substr(4,2),16)},${fromBgO});border-radius:4px;display:flex;align-items:center;justify-content:flex-start;padding:2px 8px;white-space:nowrap;overflow:hidden"
      onmousedown="startDrag(event,'from')">
      <div class="rotate-handle" onmousedown="startRotate(event,'from')"></div>
      <div class="el-label">寄件人</div>
      <div class="resize-handle" style="bottom:-4px;right:-4px;cursor:se-resize" onmousedown="startResize(event,'from','br')"></div>
      寄件人
    </div>`;

    // To text element
    const toW = data.to_w || 120;
    const toH = data.to_h || 28;
    const toBorderW = data.to_border_width || 0;
    const toBorderC = data.to_border_color || 'CCCCCC';
    const toBgC = data.to_bg_color || 'FFFFFF';
    const toBgO = (data.to_bg_opacity || 0) / 100;
    overlayHTML += `<div class="canvas-placeholder${activeEl==='to'?' selected':''}" id="el-to"
      style="left:${data.to_x||55}%;top:${data.to_y||82}%;width:${toW}px;height:${toH}px;transform:translate(-50%,-50%);font-family:'${data.to_font||'sans-serif'}',sans-serif;font-size:${data.to_size||14}px;color:#${data.to_color||'333333'};border:${toBorderW}px solid #${toBorderC};background:rgba(${parseInt(toBgC.substr(0,2),16)},${parseInt(toBgC.substr(2,2),16)},${parseInt(toBgC.substr(4,2),16)},${toBgO});border-radius:4px;display:flex;align-items:center;justify-content:flex-start;padding:2px 8px;white-space:nowrap;overflow:hidden"
      onmousedown="startDrag(event,'to')">
      <div class="rotate-handle" onmousedown="startRotate(event,'to')"></div>
      <div class="el-label">收件人</div>
      <div class="resize-handle" style="bottom:-4px;right:-4px;cursor:se-resize" onmousedown="startResize(event,'to','br')"></div>
      收件人
    </div>`;

    // Message placeholder (dashed outline, multi-line text area)
    const msgW = data.message_w || 80;
    const msgH = data.message_h || 80;
    const msgSize = data.message_size || 13;
    const msgColor = data.message_color || '555555';
    const msgFont = data.message_font || 'sans-serif';
    overlayHTML += `<div class="canvas-placeholder${activeEl==='message'?' selected':''}" id="el-message"
      style="left:${data.message_x||10}%;top:${data.message_y||60}%;width:${msgW}%;height:${msgH}px;transform:translate(0,0);border-radius:4px;display:flex;align-items:flex-start;padding:6px 8px;text-align:left;overflow:hidden;font-family:'${msgFont}',sans-serif;font-size:${msgSize}px;color:#${msgColor};font-style:italic;line-height:1.5;white-space:normal;word-wrap:break-word"
      onmousedown="startDrag(event,'message')">
      <div class="rotate-handle" onmousedown="startRotate(event,'message')"></div>
      <div class="el-label">祝福语区域</div>
      <div class="resize-handle" style="bottom:-4px;right:-4px;cursor:se-resize" onmousedown="startResize(event,'message','br')"></div>
      思念随风飘向远方，愿这份心意跨越山海抵达你的身边。
    </div>`;

    // Stamp placeholder (dashed outline)
    const stScl = (data.stamp_scale||100)/100;
    const stRot = data.stamp_rotation||0;
    overlayHTML += `<div class="canvas-placeholder${activeEl==='stamp'?' selected':''}" id="el-stamp"
      style="left:${data.stamp_x||78}%;top:${data.stamp_y||5}%;width:${Math.round(52*stScl)}px;height:${Math.round(62*stScl)}px;transform:translate(-50%,-50%) rotate(${stRot}deg)"
      onmousedown="startDrag(event,'stamp')">
      <div class="rotate-handle" onmousedown="startRotate(event,'stamp')"></div>
      <div class="el-label">邮票位置</div>
      <div class="resize-handle" style="bottom:-4px;right:-4px;cursor:se-resize" onmousedown="startResize(event,'stamp','br')"></div>
      🏷
    </div>`;

    // Postmark placeholder (dashed circle)
    const pmkRot = data.postmark_rotation||0;
    const pmkScl = (data.postmark_scale||100)/100;
    overlayHTML += `<div class="canvas-placeholder${activeEl==='postmark'?' selected':''}" id="el-postmark"
      style="left:${data.postmark_x||45}%;top:${data.postmark_y||45}%;width:${Math.round(72*pmkScl)}px;height:${Math.round(72*pmkScl)}px;border-radius:50%;transform:translate(-50%,-50%) rotate(${pmkRot}deg)"
      onmousedown="startDrag(event,'postmark')">
      <div class="rotate-handle" onmousedown="startRotate(event,'postmark')"></div>
      <div class="el-label">邮戳位置</div>
      <div class="resize-handle" style="bottom:-4px;right:-4px;cursor:se-resize" onmousedown="startResize(event,'postmark','br')"></div>
      🔵
    </div>`;
    overlay.innerHTML = overlayHTML;
    overlay.classList.add('active');
  } else if(currentTab==='stamps'){
    const bgImg=data.image_url?`background-image:url(${data.image_url});background-size:cover;`:'';
    canvas.style.cssText = `position:absolute;inset:0;display:flex;align-items:center;justify-content:center;background:#1A1A2E;border-radius:8px`;
    canvas.innerHTML = `<div style="width:80px;height:96px;border-radius:4px;display:flex;align-items:center;justify-content:center;${bgImg}flex-direction:column">
      ${data.image_url?'':`<span style="font-size:36px">🏷</span>`}
    </div>`;
    document.getElementById('canvasOverlay').innerHTML = '';
    document.getElementById('canvasOverlay').classList.remove('active');
  } else {
    canvas.style.cssText = `position:absolute;inset:0;display:flex;align-items:center;justify-content:center;background:#1A1A2E;border-radius:8px`;
    if (data.image_url) {
      canvas.innerHTML = `<img src="${data.image_url}" style="max-width:130px;max-height:130px;object-fit:contain" />`;
    } else {
      canvas.innerHTML = `<svg width="110" height="110" viewBox="0 0 90 90">
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
      </svg>`;
    }
    document.getElementById('canvasOverlay').innerHTML = '';
    document.getElementById('canvasOverlay').classList.remove('active');
  }

  // Apply zoom
  applyCanvasZoom();
}

// ============== DRAG & ROTATE ==============
function startDrag(e, elName) {
  e.preventDefault();
  e.stopPropagation();
  activeEl = elName;

  const xKey = elName === 'stamp' ? 'f_stamp_x' : elName === 'postmark' ? 'f_postmark_x' : `f_${elName}_x`;
  const yKey = elName === 'stamp' ? 'f_stamp_y' : elName === 'postmark' ? 'f_postmark_y' : `f_${elName}_y`;
  const startValX = parseFloat(document.getElementById(xKey)?.value) || 0;
  const startValY = parseFloat(document.getElementById(yKey)?.value) || 0;

  dragState = {
    el: elName,
    type: 'move',
    startMouseX: e.clientX,
    startMouseY: e.clientY,
    startValX: startValX,
    startValY: startValY,
    rafId: null
  };

  renderCanvas();
  document.addEventListener('mousemove', onDrag);
  document.addEventListener('mouseup', stopDrag);
}

function startRotate(e, elName) {
  e.preventDefault();
  e.stopPropagation();
  activeEl = elName;
  const rotKey = elName === 'stamp' ? 'f_stamp_rotation' : elName === 'postmark' ? 'f_postmark_rotation' : null;
  dragState = {
    el: elName,
    type: 'rotate',
    startMouseX: e.clientX,
    startVal: parseInt(document.getElementById(rotKey)?.value) || 0,
    rotKey: rotKey,
    rafId: null
  };
  renderCanvas();
  document.addEventListener('mousemove', onDrag);
  document.addEventListener('mouseup', stopDrag);
}

function startResize(e, elName, corner) {
  e.preventDefault();
  e.stopPropagation();
  activeEl = elName;
  if (elName === 'stamp' || elName === 'postmark') {
    const scaleKey = elName === 'stamp' ? 'f_stamp_scale' : 'f_postmark_scale';
    const curScale = parseInt(document.getElementById(scaleKey)?.value) || 100;
    dragState = {
      el: elName,
      type: 'resize',
      startMouseX: e.clientX,
      startMouseY: e.clientY,
      startVal: curScale,
      isStamp: true,
      rafId: null
    };
  } else if (elName === 'message') {
    const curW = parseInt(document.getElementById('f_message_w')?.value) || 80;
    const curH = parseInt(document.getElementById('f_message_h')?.value) || 80;
    dragState = {
      el: elName,
      type: 'resize',
      startMouseX: e.clientX,
      startMouseY: e.clientY,
      startW: curW,
      startH: curH,
      isMsg: true,
      rafId: null
    };
  } else {
    const wKey = `f_${elName}_w`;
    const hKey = `f_${elName}_h`;
    const curW = parseInt(document.getElementById(wKey)?.value) || 120;
    const curH = parseInt(document.getElementById(hKey)?.value) || 28;
    dragState = {
      el: elName,
      type: 'resize',
      startMouseX: e.clientX,
      startMouseY: e.clientY,
      startW: curW,
      startH: curH,
      isBox: true,
      rafId: null
    };
  }
  renderCanvas();
  document.addEventListener('mousemove', onDrag);
  document.addEventListener('mouseup', stopDrag);
}

function onDrag(e) {
  if (!dragState) return;
  const overlay = document.getElementById('canvasOverlay');
  const rect = overlay.getBoundingClientRect();

  const elName = dragState.el;
  const xKey = elName === 'stamp' ? 'f_stamp_x' : elName === 'postmark' ? 'f_postmark_x' : `f_${elName}_x`;
  const yKey = elName === 'stamp' ? 'f_stamp_y' : elName === 'postmark' ? 'f_postmark_y' : `f_${elName}_y`;
  const rotKey = elName === 'stamp' ? 'f_stamp_rotation' : elName === 'postmark' ? 'f_postmark_rotation' : null;

  if (dragState.type === 'move') {
    const totalDx = e.clientX - dragState.startMouseX;
    const totalDy = e.clientY - dragState.startMouseY;
    const pctX = totalDx / rect.width * 100;
    const pctY = totalDy / rect.height * 100;
    let newX = dragState.startValX + pctX;
    let newY = dragState.startValY + pctY;

    const SNAP = 3;
    if (showGrid) {
      for (let g = 0; g <= 100; g += 10) {
        if (Math.abs(newX - g) < SNAP) newX = g;
        if (Math.abs(newY - g) < SNAP) newY = g;
      }
    }
    const others = ['from','to','message','stamp','postmark'].filter(e => e !== elName);
    for (const other of others) {
      const oxKey = other === 'stamp' ? 'f_stamp_x' : other === 'postmark' ? 'f_postmark_x' : `f_${other}_x`;
      const oyKey = other === 'stamp' ? 'f_stamp_y' : other === 'postmark' ? 'f_postmark_y' : `f_${other}_y`;
      const ox = parseFloat(document.getElementById(oxKey)?.value);
      const oy = parseFloat(document.getElementById(oyKey)?.value);
      if (!isNaN(ox) && Math.abs(newX - ox) < SNAP) newX = ox;
      if (!isNaN(oy) && Math.abs(newY - oy) < SNAP) newY = oy;
    }

    newX = Math.round(Math.max(0, Math.min(100, newX)));
    newY = Math.round(Math.max(0, Math.min(100, newY)));
    if (document.getElementById(xKey)) document.getElementById(xKey).value = newX;
    if (document.getElementById(yKey)) document.getElementById(yKey).value = newY;

  } else if (dragState.type === 'rotate' && rotKey) {
    const totalDx = e.clientX - dragState.startMouseX;
    let newRot = Math.round(dragState.startVal + totalDx * 0.3);
    newRot = Math.max(-180, Math.min(180, newRot));
    if (document.getElementById(rotKey)) document.getElementById(rotKey).value = newRot;

  } else if (dragState.type === 'resize') {
    if (dragState.isMsg) {
      const overlay = document.getElementById('canvasOverlay');
      const rect = overlay.getBoundingClientRect();
      const deltaX = e.clientX - dragState.startMouseX;
      const deltaY = e.clientY - dragState.startMouseY;
      const pctDelta = deltaX / rect.width * 100;
      let newW = Math.round(dragState.startW + pctDelta);
      newW = Math.max(15, Math.min(100, newW));
      let newH = Math.round(dragState.startH + deltaY);
      newH = Math.max(30, Math.min(270, newH));
      const wEl = document.getElementById('f_message_w');
      const hEl = document.getElementById('f_message_h');
      if (wEl) wEl.value = newW;
      if (hEl) hEl.value = newH;
    } else if (dragState.isBox) {
      const deltaX = (e.clientX - dragState.startMouseX) / canvasZoom;
      const deltaY = (e.clientY - dragState.startMouseY) / canvasZoom;
      const newW = Math.max(50, Math.min(400, Math.round(dragState.startW + deltaX)));
      const newH = Math.max(16, Math.min(200, Math.round(dragState.startH + deltaY)));
      const wEl = document.getElementById(`f_${dragState.el}_w`);
      const hEl = document.getElementById(`f_${dragState.el}_h`);
      if (wEl) wEl.value = newW;
      if (hEl) hEl.value = newH;
    } else {
      const scaleKey = dragState.el === 'stamp' ? 'f_stamp_scale' : 'f_postmark_scale';
      const deltaX = (e.clientX - dragState.startMouseX) / canvasZoom;
      const deltaY = (e.clientY - dragState.startMouseY) / canvasZoom;
      const delta = Math.max(deltaX, deltaY) * 0.5;
      let newScale = Math.round(dragState.startVal + delta);
      newScale = Math.max(50, Math.min(500, newScale));
      const el = document.getElementById(scaleKey);
      if (el) { el.value = newScale;
        const valEl = document.getElementById(scaleKey === 'f_stamp_scale' ? 'f_stamp_scale_val' : 'f_pmk_scale_val');
        if (valEl) valEl.textContent = newScale + '%';
      }
    }
  }

  // Throttle render with requestAnimationFrame
  if (!dragState.rafId) {
    dragState.rafId = requestAnimationFrame(() => {
      dragState.rafId = null;
      renderCanvas();
    });
  }
}

function stopDrag() {
  dragState = null;
  document.removeEventListener('mousemove', onDrag);
  document.removeEventListener('mouseup', stopDrag);
  renderCanvas();
}

// ============== ALIGNMENT ==============
function alignEl(elName, direction) {
  const xKey = elName === 'stamp' ? 'f_stamp_x' : elName === 'postmark' ? 'f_postmark_x' : `f_${elName}_x`;
  const el = document.getElementById(xKey);
  if (!el) return;
  if (direction === 'left') el.value = 10;
  else if (direction === 'center') el.value = 50;
  else if (direction === 'right') el.value = 90;
  renderCanvas();
}

function alignAll(mode) {
  const elements = ['from', 'to', 'message'];
  if (mode === 'left') {
    elements.forEach(e => {
      const el = document.getElementById(`f_${e}_x`);
      if (el) el.value = 10;
    });
  } else if (mode === 'center') {
    elements.forEach(e => {
      const el = document.getElementById(`f_${e}_x`);
      if (el) el.value = 50;
    });
  } else if (mode === 'right') {
    elements.forEach(e => {
      const el = document.getElementById(`f_${e}_x`);
      if (el) el.value = 85;
    });
  } else if (mode === 'distribute-v') {
    ['from', 'message', 'to'].forEach((e, i) => {
      const el = document.getElementById(`f_${e}_y`);
      if (el) el.value = 30 + i * 26;
    });
  }
  renderCanvas();
}

// ============== ZOOM ==============
function computeFitScale() {
  const wrap = document.getElementById('canvasWrap');
  if (!wrap) return 1;
  const cw = wrap.clientWidth - 40;
  const ch = wrap.clientHeight - 40;
  return Math.min(cw / 420, ch / 270, 2.5);
}

function applyCanvasZoom() {
  canvasZoom = computeFitScale() + zoomOffset;
  canvasZoom = Math.max(0.3, Math.min(3.0, canvasZoom));
  const container = document.getElementById('canvasContainer');
  if (container) container.style.transform = `scale(${canvasZoom})`;
}

function zoomCanvas(delta) {
  zoomOffset += delta;
  applyCanvasZoom();
}

function resetZoom() {
  zoomOffset = 0;
  applyCanvasZoom();
}

function toggleGrid() {
  showGrid = !showGrid;
  const btn = document.getElementById('gridBtn');
  if (btn) { btn.classList.toggle('btn-primary', showGrid); btn.classList.toggle('btn-outline', !showGrid); }
  renderCanvas();
}

// ============== BATCH SELECT & DELETE ==============
function toggleSelect(id) {
  if (selectedIds.has(id)) { selectedIds.delete(id); }
  else { selectedIds.add(id); }
  render(cachedItems);
}

function toggleSelectAll() {
  const check = document.getElementById('selectAllCheck');
  if (check.checked) {
    cachedItems.forEach(item => selectedIds.add(item.id));
  } else {
    selectedIds.clear();
  }
  render(cachedItems);
}

function updateBatchBar() {
  const bar = document.getElementById('batchBar');
  const countEl = document.getElementById('batchCount');
  const allCheck = document.getElementById('selectAllCheck');
  if (!bar || !countEl) return;
  if (selectedIds.size > 0) {
    bar.classList.add('show');
    countEl.textContent = `已选 ${selectedIds.size} 项`;
    if (allCheck) allCheck.checked = cachedItems.length > 0 && cachedItems.every(item => selectedIds.has(item.id));
  } else {
    bar.classList.remove('show');
    if (allCheck) allCheck.checked = false;
  }
}

async function batchDelete() {
  const ids = Array.from(selectedIds);
  if (!ids.length) return;
  if (!confirm(`确定要删除选中的 ${ids.length} 项吗？此操作不可撤销。`)) return;
  try {
    const resp = await api(`/api/materials/${currentTab}/batch-delete`, 'POST', { ids });
    if (resp.success) {
      toast(`已删除 ${resp.deleted} 项`, 'success');
      selectedIds.clear();
      await load(currentPage);
    } else {
      toast(resp.message || '删除失败', 'error');
    }
  } catch (e) { toast('删除失败: ' + e.message, 'error'); }
}

// ============== CLONE & SAVE AS ==============
async function cloneItem() {
  if (!selectedItem) { toast('请先在左侧选择要复制的素材', 'error'); return; }
  const newId = generateAutoId();
  const data = { ...selectedItem };
  data.id = newId;
  if (currentTab === 'templates') {
    data.name = (data.name || '') + ' (副本)';
  } else {
    data.label = (data.label || '') + ' (副本)';
  }
  const path = currentTab==='templates'?'templates':currentTab==='stamps'?'stamps':'postmarks';
  try {
    await api(`/api/materials/${path}`, 'POST', data);
    toast('复制成功: ' + newId, 'success');
    await load(currentPage);
    const newItem = cachedItems.find(i => i.id === newId);
    if (newItem) {
      selectedItem = newItem;
      editingId = newId;
      render(cachedItems);
      showEditPanel();
    }
  } catch(e) { toast('复制失败: ' + e.message, 'error'); }
}

async function saveAsItem() {
  const data = getFormData();
  const newId = generateAutoId();
  data.id = newId;
  if (currentTab === 'templates') {
    data.name = (data.name || '') + ' (副本)';
  } else {
    data.label = (data.label || '') + ' (副本)';
  }
  const path = currentTab==='templates'?'templates':currentTab==='stamps'?'stamps':'postmarks';
  try {
    await api(`/api/materials/${path}`, 'POST', data);
    editingId = newId;
    document.getElementById('f_id').value = newId;
    if (currentTab === 'templates') {
      document.getElementById('f_name').value = data.name || '';
    } else {
      document.getElementById('f_label').value = data.label || '';
    }
    document.getElementById('editTitle').textContent = '编辑素材';
    toast('另存为成功: ' + newId, 'success');
    load(currentPage);
  } catch(e) { toast('另存为失败: ' + e.message, 'error'); }
}

// ============== IMAGE HANDLING ==============
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
      input.value = ''; // reset so same file can be re-selected
      renderCanvas();
      toast('图片上传成功','success');
    }
  }catch(e){toast('上传失败: '+e.message,'error')}
}

function applyUrl(){
  const url=document.getElementById('f_image_url').value.trim();
  if(url){
    document.getElementById('imgThumb').style.backgroundImage=`url(${url})`;
    document.getElementById('imgThumb').innerHTML='';
    renderCanvas();
  }
}

function clearImage(){
  document.getElementById('f_image_url').value='';
  document.getElementById('imgThumb').style.backgroundImage='';
  document.getElementById('imgThumb').innerHTML='📷';
  renderCanvas();
}

// ============== AUTO SAVE ==============
async function autoSave(){
  if (!editingId && !selectedItem) return;
  const data = getFormData();
  if (!data.id) return; // no id set yet, skip
  const path = currentTab==='templates'?'templates':currentTab==='stamps'?'stamps':'postmarks';
  try {
    if (editingId) { await api(`/api/materials/${path}/${editingId}`,'PUT',data); }
    else { await api(`/api/materials/${path}`,'POST',data); editingId = data.id; }
    // silently refresh the list
    try { load(currentPage); } catch(e) {}
  } catch(e) { /* silent */ }
}

// ============== SAVE / DELETE ==============
async function saveItem(){
  const data=getFormData();
  if(!data.id){toast('请输入ID或点击自动编号','error');return}
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

async function switchTab(tab){
  await autoSave();
  currentTab=tab;editingId=null;selectedItem=null;currentPage=1;canvasZoom=1;currentGroup='';
  selectedIds.clear();
  hideEditPanel();
  document.querySelectorAll('.tab').forEach((t,i)=>{const tabs=['templates','stamps','postmarks'];t.classList.toggle('active',tabs[i]===tab)});
  load(1);
  if (tab === 'templates') refreshGroupTabs();
  else document.getElementById('groupBar').style.display = 'none';
}

function toast(msg,type){
  const t=document.getElementById('toast');
  t.className='toast '+type;t.textContent=msg;
  setTimeout(()=>t.className='',2500);
}

// Click on canvas overlay to deselect
document.getElementById('canvasOverlay').addEventListener('mousedown', function(e) {
  if (e.target === this) {
    activeEl = null;
    renderCanvas();
  }
});

// Scroll wheel zoom on canvas
document.getElementById('canvasWrap').addEventListener('wheel', function(e) {
  e.preventDefault();
  const delta = e.deltaY > 0 ? -0.05 : 0.05;
  zoomCanvas(delta);
}, { passive: false });

// Keyboard arrow keys to nudge selected element
document.addEventListener('keydown', function(e) {
  if (!activeEl || currentTab !== 'templates') return;
  if (!['ArrowUp','ArrowDown','ArrowLeft','ArrowRight'].includes(e.key)) return;
  const tag = document.activeElement && document.activeElement.tagName;
  if (tag === 'INPUT' || tag === 'SELECT' || tag === 'TEXTAREA') return;

  e.preventDefault();
  const step = e.shiftKey ? 5 : 1;
  const elName = activeEl;
  const xKey = elName === 'stamp' ? 'f_stamp_x' : elName === 'postmark' ? 'f_postmark_x' : `f_${elName}_x`;
  const yKey = elName === 'stamp' ? 'f_stamp_y' : elName === 'postmark' ? 'f_postmark_y' : `f_${elName}_y`;

  const xEl = document.getElementById(xKey);
  const yEl = document.getElementById(yKey);
  let x = parseFloat(xEl?.value) || 0;
  let y = parseFloat(yEl?.value) || 0;

  if (e.key === 'ArrowLeft')  x = Math.max(0, x - step);
  if (e.key === 'ArrowRight') x = Math.min(100, x + step);
  if (e.key === 'ArrowUp')    y = Math.max(0, y - step);
  if (e.key === 'ArrowDown')  y = Math.min(100, y + step);

  if (xEl) xEl.value = Math.round(x * 10) / 10;
  if (yEl) yEl.value = Math.round(y * 10) / 10;
  renderCanvas();
});

// Resize observer to update fit scale
window.addEventListener('resize', () => {
  applyCanvasZoom();
});

// ======== Group Sort Dialog ========

let _sortGroups = [];

async function openGroupSort() {
  const allTemplates = await loadAllTemplates();
  const groups = new Set();
  allTemplates.forEach(t => { if (t.template_group) groups.add(t.template_group); });
  cachedItems.forEach(t => { if (t.template_group) groups.add(t.template_group); });
  _sortGroups = Array.from(groups).sort();

  // Load current order from config
  try {
    const cfg = await api('/api/materials/config');
    if (cfg.group_order && cfg.group_order.length > 0) {
      // Merge: ordered first, then any new groups not in the order
      const ordered = cfg.group_order.filter(g => groups.has(g));
      const remaining = _sortGroups.filter(g => !cfg.group_order.includes(g));
      _sortGroups = [...ordered, ...remaining];
    }
  } catch(e) {}

  _renderSortDialog();
}

function _renderSortDialog() {
  let dlg = document.getElementById('groupSortDlg');
  if (!dlg) {
    dlg = document.createElement('div');
    dlg.id = 'groupSortDlg';
    dlg.style.cssText = 'position:fixed;inset:0;background:rgba(0,0,0,0.6);z-index:1000;display:flex;align-items:center;justify-content:center';
    document.body.appendChild(dlg);
  }
  const rows = _sortGroups.map((g, i) => `
    <div style="display:flex;align-items:center;gap:8px;padding:6px 10px;background:#1E1E3A;border-radius:6px;margin:4px 0">
      <span style="color:#888;width:20px;text-align:center;font-size:11px">${i+1}</span>
      <span style="flex:1;font-size:13px">${g}</span>
      <button class="btn btn-outline btn-small" onclick="moveGroup(${i},-1)" ${i===0?'disabled':''}  style="padding:2px 8px">↑</button>
      <button class="btn btn-outline btn-small" onclick="moveGroup(${i},1)" ${i===_sortGroups.length-1?'disabled':''} style="padding:2px 8px">↓</button>
    </div>
  `).join('');
  dlg.innerHTML = `
    <div style="background:#13132B;border-radius:12px;padding:20px;min-width:280px;max-height:70vh;overflow-y:auto;border:1px solid #333">
      <h3 style="margin:0 0 12px;font-size:15px;color:#fff">分组排序</h3>
      <div style="font-size:11px;color:#888;margin-bottom:8px">拖拽或使用箭头调整分组显示顺序</div>
      <div id="groupSortList">${rows}</div>
      <div style="display:flex;gap:8px;margin-top:14px;justify-content:flex-end">
        <button class="btn btn-outline" onclick="closeGroupSort()">取消</button>
        <button class="btn btn-primary" onclick="saveGroupSort()">保存</button>
      </div>
    </div>
  `;
}

function moveGroup(idx, dir) {
  const newIdx = idx + dir;
  if (newIdx < 0 || newIdx >= _sortGroups.length) return;
  const tmp = _sortGroups[idx];
  _sortGroups[idx] = _sortGroups[newIdx];
  _sortGroups[newIdx] = tmp;
  _renderSortDialog();
}

function closeGroupSort() {
  const dlg = document.getElementById('groupSortDlg');
  if (dlg) dlg.remove();
}

async function saveGroupSort() {
  try {
    await api('/api/materials/config', 'PUT', { group_order: _sortGroups });
    closeGroupSort();
    refreshGroupTabs();
  } catch(e) { alert('保存失败: ' + e.message); }
}

// ======== Set Default Material ========

async function setDefaultMaterial(type, id) {
  const keyMap = { templates: 'default_template', stamps: 'default_stamp', postmarks: 'default_postmark' };
  const key = keyMap[type];
  if (!key) return;
  // Toggle: if already default, clear it
  try {
    const cfg = await api('/api/materials/config');
    const newVal = (cfg[key] === id) ? '' : id;
    await api('/api/materials/config', 'PUT', { [key]: newVal });
    alert(newVal ? `已设为默认${type === 'templates' ? '模板' : type === 'stamps' ? '邮票' : '邮戳'}` : '已取消默认');
    load(currentPage);
  } catch(e) { alert('设置失败: ' + e.message); }
}

// Initialize
applyCanvasZoom();
load(1);
</script>
</body>
</html>"""

@router.get("/admin", response_class=HTMLResponse)
def admin_page():
    return HTMLResponse(content=ADMIN_HTML)
