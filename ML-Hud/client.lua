local DEBUG = true 

local function dprintf(fmt, ...)
  if not DEBUG then return end
  print(('[ML-Hud] '..fmt):format(...))
end

local function NUI(d) SendNUIMessage(d) end
local function showHUD() NUI({action='show'}) end

local function pushSet(job, id, cash, bank, black)
  local payload = { action='set', job=job, id=id, cash=cash, bank=bank, black=black }
  dprintf('TX NUI: %s', (json and json.encode(payload)) or 'payload')
  SendNUIMessage(payload)
end

local ESX

local function ensureESX()
  if ESX then return true end

  local okExport, obj = pcall(function()
    return exports['es_extended'] and exports['es_extended']:getSharedObject() or nil
  end)
  if okExport and obj then ESX = obj; dprintf('ESX via export'); return true end

  -- fallback oude event
  local got = false
  TriggerEvent('esx:getSharedObject', function(o) ESX = o; got = (o~=nil) end)
  if got then dprintf('ESX via event'); return true end

  dprintf('ESX niet gevonden (nog).')
  return false
end

local function getPD()
  if not ESX then return nil end
  if ESX.GetPlayerData then
    local ok, pd = pcall(ESX.GetPlayerData)
    if ok and pd then return pd end
  end
  return ESX.PlayerData
end

local function euro(n)
  if type(n) ~= 'number' then n = tonumber(n) or 0 end
  local s = tostring(math.floor(n))
  local left = #s % 3
  local out = left>0 and s:sub(1,left) or ''
  for i=left+1,#s,3 do out = out .. (out~='' and '.' or '') .. s:sub(i,i+2) end
  return '€ ' .. (out ~= '' and out or '0')
end

local function accountsToMap(accounts)
  local map = {}
  if type(accounts) ~= 'table' then return map end
  local isArray = false
  for k,_ in pairs(accounts) do if type(k)=='number' then isArray=true break end end
  if isArray then
    for _,a in ipairs(accounts) do
      if a and a.name then map[a.name] = a.money or a.balance or 0 end
    end
  else
    for name,a in pairs(accounts) do
      if type(a) == 'table' then map[name] = a.money or a.balance or 0
      else map[name] = tonumber(a) or 0 end
    end
  end
  return map
end

local ACC = {
  cash  = {'money','cash'},
  bank  = {'bank'},
  black = {'black_money','black','dirty'}
}

local function pick(map, keys)
  for _,k in ipairs(keys) do if map[k] ~= nil then return map[k] end end
  return 0
end

local function buildSnapshot()
  local pd = getPD() or {}

  local job = pd.job or {}
  local jLbl = job.label or job.name or 'Onbekend'
  local gLbl = job.grade_label or job.grade_name or job.grade or ''
  if type(gLbl) == 'number' then gLbl = tostring(gLbl) end
  local jobText = (gLbl ~= '' and (jLbl .. ' - ' .. gLbl) or jLbl)

  local id = GetPlayerServerId(PlayerId())

  local m    = accountsToMap(pd.accounts or {})
  local cash = pick(m, ACC.cash)
  local bank = pick(m, ACC.bank)
  local blk  = pick(m, ACC.black)
  if (cash == 0 or cash == nil) and pd.money then cash = pd.money end

  local cashT, bankT, blkT = euro(cash or 0), euro(bank or 0), euro(blk or 0)

  if DEBUG then
    local dbg = {
      job = job, id = id,
      accounts = pd.accounts, moneyField = pd.money,
      out = { jobText = jobText, cash=cashT, bank=bankT, black=blkT }
    }
    dprintf('SNAP: %s', (json and json.encode(dbg)) or 'snap')
  end

  return jobText, id, cashT, bankT, blkT, (pd.job ~= nil)
end

local last = { job=nil, id=nil, cash=nil, bank=nil, black=nil }
local function pushIfChanged()
  local job, id, cash, bank, black = buildSnapshot()
  if last.job==job and last.id==id and last.cash==cash and last.bank==bank and last.black==black then
    return
  end
  last.job, last.id, last.cash, last.bank, last.black = job, id, cash, bank, black
  pushSet(job, id, cash, bank, black)
end

local function hookEsxEvents()
  RegisterNetEvent('esx:playerLoaded', function(xPlayer)
    if ESX then if ESX.PlayerData then ESX.PlayerData = xPlayer end end
    dprintf('event: esx:playerLoaded')
    pushIfChanged()
  end)

  RegisterNetEvent('esx:setJob', function(job)
    if ESX and ESX.PlayerData then ESX.PlayerData.job = job end
    dprintf('event: esx:setJob')
    pushIfChanged()
  end)

  RegisterNetEvent('esx:setAccountMoney', function()
    dprintf('event: esx:setAccountMoney')
    pushIfChanged()
  end)

  RegisterNetEvent('esx:addAccountMoney',    function() dprintf('event: esx:addAccountMoney');    pushIfChanged() end)
  RegisterNetEvent('esx:removeAccountMoney', function() dprintf('event: esx:removeAccountMoney'); pushIfChanged() end)
  RegisterNetEvent('esx:addMoney',           function() dprintf('event: esx:addMoney');           pushIfChanged() end)
  RegisterNetEvent('esx:removeMoney',        function() dprintf('event: esx:removeMoney');        pushIfChanged() end)

  RegisterNetEvent('esx:setPlayerData',      function(k,v) dprintf('event: esx:setPlayerData %s', tostring(k)); pushIfChanged() end)
end

CreateThread(function()
  showHUD()

  local t0 = GetGameTimer()
  while not ensureESX() do
    if GetGameTimer() - t0 > 8000 then break end
    Wait(200)
  end
  if not ESX then
    dprintf('GEEN ESX → HUD toont enkel ID.')
    pushSet('Onbekend', GetPlayerServerId(PlayerId()), euro(0), euro(0), euro(0))
  else
    if not (ESX.PlayerData and next(ESX.PlayerData)) and ESX.GetPlayerData then
      local ok, pd = pcall(ESX.GetPlayerData)
      if ok then ESX.PlayerData = pd end
    end

    hookEsxEvents()

    local t1 = GetGameTimer()
    while true do
      local pd = getPD()
      if pd and pd.job then break end
      if GetGameTimer() - t1 > 5000 then break end
      Wait(150)
    end
    pushIfChanged()
  end

  while true do
    pushIfChanged()
    Wait(2000)
  end
end)

-- als je wilt testen....
-- RegisterCommand('huduitest', function()
--   SendNUIMessage({
--     action='set',
--     job   ='UITest - Demo',
--     id    = GetPlayerServerId(PlayerId()),
--     cash  = '€ 1.111',
--     bank  = '€ 22.222',
--     black = '€ 0'
--   })
--   showHUD()
-- end, false)

-- hier nog wat extra opties mocht het nodig zijn.... 

-- RegisterCommand('hudpd', function()
--   local pd = getPD() or {}
--   dprintf('PlayerData: %s', (json and json.encode(pd)) or 'no json lib')
-- end, false)


-- RegisterCommand('huddebug', function()
--   DEBUG = not DEBUG
--   print(('[ML-Hud] DEBUG: %s'):format(DEBUG and 'ON' or 'OFF'))
-- end, false)
