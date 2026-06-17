// Version: 0.44.0
// Created: Petr Krivan
// Project: android lab manager
async function copyById(id, btn){
  var el=document.getElementById(id);
  if(!el) return false;
  var text=(el.value || el.textContent || '').trim();
  var ok=false;
  try{
    if(window.isSecureContext && navigator.clipboard && navigator.clipboard.writeText){
      await navigator.clipboard.writeText(text);
      ok=true;
    }
  }catch(e){ ok=false; }
  if(!ok){
    try{
      el.focus();
      el.select();
      ok=document.execCommand('copy');
    }catch(e){ ok=false; }
  }
  if(!ok){
    try{ el.focus(); el.select(); }catch(e){}
    window.prompt('Copy this command:', text);
  }
  if(btn){
    var old=btn.textContent;
    btn.textContent=ok ? 'Copied' : 'Selected';
    setTimeout(function(){btn.textContent=old;}, 1600);
  }
  return false;
}

function filterInstances(q){
  q=(q || '').toLowerCase().trim();
  document.querySelectorAll('tr.instance-row,.instance-card').forEach(function(row){
    var text=(row.getAttribute('data-filter') || row.textContent || '').toLowerCase();
    row.classList.toggle('instance-hidden', q && text.indexOf(q) === -1);
  });
}


function filterDocs(q){
  q=(q || '').toLowerCase().trim();
  document.querySelectorAll('.doc-card').forEach(function(card){
    var text=(card.getAttribute('data-filter') || card.textContent || '').toLowerCase();
    card.style.display=(q && text.indexOf(q) === -1) ? 'none' : '';
  });
}

function viewFromLocation(){
  var params = new URLSearchParams(window.location.search || '');
  return params.get('view') || ((location.hash || '#overview').slice(1));
}
function viewUrl(id){ return '/?view=' + encodeURIComponent(id) + '#' + encodeURIComponent(id); }
function showSection(id, push){
  var valid={overview:1,spawn:1,profiles:1,instances:1,frida:1};
  if(!valid[id]) id='overview';
  var target=document.getElementById('view-'+id);
  if(!target) return false;
  document.querySelectorAll('.view').forEach(function(v){v.classList.remove('active');});
  target.classList.add('active');
  document.querySelectorAll('[data-nav-section]').forEach(function(a){a.classList.toggle('active', a.getAttribute('data-nav-section')===id);});
  if(location.pathname==='/' && push) history.pushState(null,'',viewUrl(id));
  else if(location.pathname==='/' && !push) history.replaceState(null,'',viewUrl(id));
  return true;
}
function navSection(id){
  if(location.pathname !== '/') return true;
  if(!document.getElementById('view-'+id)){ window.location.href=viewUrl(id); return false; }
  showSection(id, true);
  return false;
}
window.addEventListener('popstate', function(){ if(document.getElementById('view-overview')) showSection(viewFromLocation(), false); });
window.addEventListener('DOMContentLoaded', function(){
  if(document.getElementById('view-overview')) showSection(viewFromLocation(), false);
});


async function pollJob(){
  var page=document.querySelector('[data-job-page]');
  if(!page) return;
  var jobId=page.getAttribute('data-job-id');
  try{
    const r = await fetch(page.getAttribute('data-job-url') || ('/job_status/' + encodeURIComponent(jobId)));
    const j = await r.json();
    document.getElementById('job-status').textContent = j.status;
    document.getElementById('job-log').textContent = j.log;
    if(j.status === 'running' || j.status === 'queued') setTimeout(pollJob, 1500);
  }catch(e){
    document.getElementById('job-log').textContent += '\n[-] Poll failed: ' + e;
    setTimeout(pollJob, 3000);
  }
}

async function sendKey(key){
  var wrap=document.querySelector('[data-novnc-session]');
  if(!wrap) return false;
  const data = new FormData();
  data.append('csrf', wrap.getAttribute('data-csrf') || '');
  data.append('name', wrap.getAttribute('data-instance-name') || '');
  data.append('key', key);
  const status = document.getElementById('key-status');
  status.textContent = 'sending ' + key + '...';
  try{
    const r = await fetch('/keyevent', {method:'POST', body:data});
    const txt = await r.text();
    status.textContent = r.ok ? ('sent ' + key) : txt;
  }catch(e){ status.textContent = 'failed: ' + e; }
  return false;
}

window.addEventListener('DOMContentLoaded', function(){ pollJob(); });
