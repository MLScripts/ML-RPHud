(function () {
  var DEBUG = false; 

  function $(id){ return document.getElementById(id); }
  var hudEl   = $('hud');
  var elJob   = $('hud-job');
  var elId    = $('hud-id');
  var elCash  = $('hud-cash');
  var elBank  = $('hud-bank');
  var elBlack = $('hud-black');
  var dbgEl = null;
  function dbg(msg, data){
    if(!DEBUG) return;
    if(!dbgEl){
      dbgEl = document.createElement('div');
      dbgEl.style.cssText = 'position:fixed;right:10px;bottom:10px;z-index:999999;background:rgba(0,0,0,.6);color:#fff;font:12px/1.3 monospace;padding:6px 8px;border-radius:8px;max-width:50vw;white-space:pre-wrap;';
      document.body.appendChild(dbgEl);
    }
    var line = '['+new Date().toLocaleTimeString()+'] '+msg+(data?('\n'+(typeof data==='string'?data:JSON.stringify(data))):'');
    dbgEl.textContent = line;
    try{ console.log('[ML-Hud]', msg, data||''); }catch(e){}
  }

  function safeClosest(el, sel) {
    while (el && el.nodeType === 1) {
      if (el.matches && el.matches(sel)) return el;
      el = el.parentElement;
    }
    return null;
  }

  function setText(el, v) {
    if (!el) return;
    var val = (v == null) ? '' : String(v);
    if (el.textContent !== val) {
      el.textContent = val;
      var pill = safeClosest(el, '.pill');
      if (pill) { pill.classList.remove('flash'); void pill.offsetWidth; pill.classList.add('flash'); }
    }
  }

  function setVisible(v) { if (hudEl) hudEl.classList.toggle('hidden', !v); }

  function toObject(payload) {
    if (typeof payload === 'string') {
      try { return JSON.parse(payload); } catch { return {}; }
    }
    return payload || {};
  }

  function pick(d, keys) { for (var i=0;i<keys.length;i++){ var k=keys[i]; if (d[k]!=null) return d[k]; } return null; }

  window.addEventListener('message', function (e) {
    var d = toObject(e.data);
    if (!d || !d.action) return;

    dbg('RX '+d.action, d);

    switch (d.action) {
      case 'show':   setVisible(true); break;
      case 'hide':   setVisible(false); break;
      case 'toggle': setVisible(hudEl ? hudEl.classList.contains('hidden') : false); break;

      case 'set': {
        var job   = pick(d, ['job','jobLabel','job_text']);
        var id    = pick(d, ['id','playerId','serverId']);
        var cash  = pick(d, ['cash','money','cashMoney']);
        var bank  = pick(d, ['bank','bankMoney']);
        var black = pick(d, ['black','black_money','blackMoney','dirty']);

        if (job   != null) setText(elJob,   job);
        if (id    != null) setText(elId,    id);
        if (cash  != null) setText(elCash,  cash);
        if (bank  != null) setText(elBank,  bank);
        if (black != null) setText(elBlack, black);

        setVisible(true);
        break;
      }

      case 'setJob':   setText(elJob,   d.value); break;
      case 'setId':    setText(elId,    d.value); break;
      case 'setCash':  setText(elCash,  d.value); break;
      case 'setBank':  setText(elBank,  d.value); break;
      case 'setBlack': setText(elBlack, d.value); break;
    }
  }, false);

  if (DEBUG) {
    var btn = document.createElement('button');
    btn.textContent = 'NUI Self-Test';
    btn.style.cssText = 'position:fixed;left:10px;bottom:10px;z-index:999999;border:1px solid #555;background:#111;color:#fff;padding:6px 10px;border-radius:8px;opacity:.8';
    btn.onclick = function(){
      var payload = {action:'set', job:'SelfTest – Baan', id:99, cash:'€ 1.234', bank:'€ 56.789', black:'€ 0'};
      dbg('SelfTest send', payload);
      window.postMessage(payload, '*');
    };
    document.body.appendChild(btn);
  }

  setVisible(true);
})();
