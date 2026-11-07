-- OctoWoW Raid Poker 1.4.09: Player Balances 2.0 / turn timer / connectivity.
-- Separate chunk avoids WoW Lua's 200-local-per-chunk limit.
OctoPokerAdminUI=OctoPokerAdminUI or {}
local M=OctoPokerAdminUI
local G=OctoPokerGame
local F=OctoPokerBankFrame
if not G or not F or not G.AdminState then return end
local list=OctoPokerBank.rows
local content=OctoPokerBankScroll:GetScrollChild()
local headerY=-87
local function label(x,w,title)
 local t=F:CreateFontString(nil,'OVERLAY','GameFontNormalSmall')
 t:SetPoint('TOPLEFT',F,'TOPLEFT',x,headerY);t:SetWidth(w);t:SetJustifyH((title=='PLAYER' or title=='BALANCE') and 'LEFT' or 'CENTER');t:SetText(title)
 return t
end
F:SetWidth(750)
-- The 1.3.90 column labels overlap the 1.3.97 sort buttons.
-- Replace them with a dedicated header row below the sorting controls.
if OctoPoker152_bankHeader then OctoPoker152_bankHeader:Hide() end
if OctoPoker152_bankHeaderBalance then OctoPoker152_bankHeaderBalance:Hide() end
if OctoPoker152_bankHeaderPermission then OctoPoker152_bankHeaderPermission:Hide() end
if OctoPoker152_bankHeaderSeated then OctoPoker152_bankHeaderSeated:Hide() end
OctoPokerBankScroll:ClearAllPoints()
OctoPokerBankScroll:SetPoint('TOPLEFT',F,'TOPLEFT',24,-109)
OctoPokerBankScroll:SetHeight(239)
label(26,130,'PLAYER')
label(164,95,'BALANCE')
label(268,115,'PERMISSION')
label(400,85,'AT TABLE')
OctoPokerBankScroll:SetWidth(678)
content:SetWidth(650)
-- Retain the original row widgets; add columns to their right.
label(504,80,'CONNECTION')
label(589,60,'KICK')
local sortMode='NAME'
local lastSeen={}
local lastPing=0
local timeLimit=30
local turnKey=''
local deadline=0
local timerSyncKey=''
local selectedPlayer=nil
local oldPacket=OctoPoker152_onPokerPacket
OctoPoker152_onPokerPacket=function(kind,data,sender)
 if kind=='ADMINTURN' then
  local _,_,limit,remaining=string.find(data or '','^(%d+):(%d+)$')
  if limit then timeLimit=tonumber(limit) or 30;deadline=GetTime()+(tonumber(remaining) or timeLimit);M.UpdateTimerLabel() end
  return
 elseif kind=='ADMINTIMER' then
  if not G.AdminLeader() then timeLimit=tonumber(data) or 30;deadline=GetTime()+timeLimit;if M.UpdateTimerLabel then M.UpdateTimerLabel() end end
  return
 elseif kind=='ADMINPING' then
  if not G.AdminLeader() then G.AdminSend('ADMINPONG',tostring(GetTime())) end
  return
 elseif kind=='ADMINPONG' then
  if G.AdminLeader() then lastSeen[string.gsub(sender or '','%-.*$','')]=GetTime() end
  return
 end
 oldPacket(kind,data,sender)
end
for i=1,40 do
 local row=list[i]
 row.connection=row:CreateFontString(nil,'OVERLAY','GameFontHighlightSmall')
 row.connection:SetPoint('LEFT',row,'LEFT',480,0)
 row.connection:SetWidth(80);row.connection:SetJustifyH('CENTER')
 row.kick=CreateFrame('Button',nil,row,'UIPanelButtonTemplate')
 row.kick:SetWidth(60);row.kick:SetHeight(19)
 row.kick:SetPoint('LEFT',row,'LEFT',565,0)
 row.kick:SetText('KICK')
 row.kick:SetScript('OnClick',function()
  if this.player and G.AdminKick(this.player) then
   DEFAULT_CHAT_FRAME:AddMessage('Poker: '..this.player..' removed from table.')
   OctoPokerBank.Refresh()
  end
 end)
end
local originalRefresh=OctoPokerBank.Refresh
function OctoPokerBank.Refresh()
 originalRefresh()
 local names={}
 for i=1,GetNumRaidMembers() do
  local n=GetRaidRosterInfo(i)
  if n then names[table.getn(names)+1]=string.gsub(n,'%-.*$','') end
 end
 table.sort(names,function(a,b)
  if sortMode=='BALANCE' then
   local x,y=G.AdminBalance(a),G.AdminBalance(b)
   if x~=y then return x>y end
  elseif sortMode=='TABLE' then
   local x,y=G.joined[a] and 1 or 0,G.joined[b] and 1 or 0
   if x~=y then return x>y end
  elseif sortMode=='PERMISSION' then
   local x,y=OctoPokerBank.IsEnabled(a) and 1 or 0,OctoPokerBank.IsEnabled(b) and 1 or 0
   if x~=y then return x>y end
  end
  return string.lower(a)<string.lower(b)
 end)
 local phase=G.AdminState()
 for i=1,40 do
  local row=list[i];local name=names[i]
  if name then
   row:Show();row.name:SetText(name);row.amount:SetText(G.Display(G.AdminBalance(name)))
   row.amount:SetTextColor(G.AdminBalance(name)<=0 and 1 or 1,G.AdminBalance(name)<=0 and 0.3 or 1,G.AdminBalance(name)<=0 and 0.3 or 1)
   row:SetScript('OnMouseDown',function()
    selectedPlayer=name
    OctoPokerBankPlayer:SetText(name)
   end)
   row.toggle.player=name;row.toggle:SetText(OctoPokerBank.IsEnabled(name) and 'ENABLED' or 'DISABLED')
   row.seated:SetText(G.joined[name] and '|cff55dd77YES|r' or '|cffaaaaaaNO|r')
   if G.AdminLeader() and phase~='BET1' and phase~='BET2' and phase~='DRAW' then row.toggle:Enable() else row.toggle:Disable() end
   row.kick.player=name
   if G.AdminLeader() and G.joined[name] and phase~='BET1' and phase~='BET2' and phase~='DRAW' then row.kick:Enable() else row.kick:Disable() end
   if name==UnitName('player') then row.connection:SetText('|cff55dd77LOCAL|r')
   elseif lastSeen[name] and GetTime()-lastSeen[name]<35 then row.connection:SetText('|cff55dd77ONLINE|r')
   else row.connection:SetText('|cffffbb55UNKNOWN|r') end
  else row:Hide() end
 end
end
local function sortButton(text,x,mode)
 local b=CreateFrame('Button',nil,F,'UIPanelButtonTemplate')
 b:SetWidth(95);b:SetHeight(20);b:SetPoint('TOPLEFT',F,'TOPLEFT',x,-51)
 b:SetText(text);b:SetScript('OnClick',function()sortMode=mode;OctoPokerBank.Refresh()end)
end
sortButton('Name',26,'NAME')
sortButton('Balance',164,'BALANCE')
sortButton('Permission',278,'PERMISSION')
sortButton('At Table',400,'TABLE')
-- Timer controls moved to the main poker frame in v1.4.09.
function M.UpdateTimerLabel()
 if M.RefreshMainTimer then M.RefreshMainTimer() end
end
function M.SetTimer(seconds)
 if not G.AdminLeader() then return end
 seconds=tonumber(seconds) or 30
 if seconds~=0 and seconds~=15 and seconds~=30 and seconds~=60 then return end
 timeLimit=seconds
 deadline=GetTime()+timeLimit
 OctoPokerDB=OctoPokerDB or {};OctoPokerDB.turnTimer=timeLimit
 G.AdminSend('ADMINTIMER',tostring(timeLimit))
 M.UpdateTimerLabel()
end
function M.GetTimer() return timeLimit end
-- v1.4.09: visual timer is integrated into the main poker window.
-- Compact controls above emotes on the main window.
local mainFrame=getglobal('OctoPokerFrame')
if mainFrame then
 local timerCaption=mainFrame:CreateFontString(nil,'OVERLAY','GameFontNormalSmall')
 timerCaption:SetPoint('TOPLEFT',mainFrame,'TOPLEFT',24,-627)
 timerCaption:SetText('TURN TIMER')
 local timerChoices={15,30,60,0}
 local timerButtons={}
 for i,seconds in ipairs(timerChoices) do
  local b=CreateFrame('Button',nil,mainFrame,'UIPanelButtonTemplate')
  b:SetWidth(62);b:SetHeight(22)
  b:SetPoint('TOPLEFT',mainFrame,'TOPLEFT',118+(i-1)*67,-620)
  b:SetText(seconds==0 and 'OFF' or (seconds..'s'))
  b:SetScript('OnClick',function()M.SetTimer(seconds)end)
  timerButtons[i]=b
 end
 function M.RefreshMainTimer()
  for i,seconds in ipairs(timerChoices) do
   local b=timerButtons[i]
   if seconds==timeLimit then b:SetText('|cff55ee88'..(seconds==0 and 'OFF' or seconds..'s')..'|r')
   else b:SetText(seconds==0 and 'OFF' or seconds..'s') end
   if G.AdminLeader() then b:Enable() else b:Disable() end
  end
 end
 M.RefreshMainTimer()
end
local ticker=CreateFrame('Frame',nil,UIParent)
ticker:SetScript('OnUpdate',function()
 this.elapsed=(this.elapsed or 0)+arg1
 if this.elapsed<0.25 then return end
 this.elapsed=0
 local phase,id,turn,players,actor=G.AdminState()
 local key=tostring(id)..':'..tostring(phase)..':'..tostring(turn)
 if key~=turnKey then
  turnKey=key
  deadline=GetTime()+timeLimit
  if G.AdminLeader() then G.AdminSend('ADMINTURN',tostring(timeLimit)..':'..tostring(timeLimit)) end
 end
 if G.AdminLeader() then
  if GetTime()-lastPing>10 then lastPing=GetTime();G.AdminSend('ADMINPING',tostring(GetTime())) end
  if timeLimit>0 and (phase=='BET1' or phase=='BET2') and GetTime()>=deadline then
   deadline=GetTime()+timeLimit
   G.AdminTimeout()
  end
 end
end)
local login=CreateFrame('Frame',nil,UIParent)
login:RegisterEvent('PLAYER_LOGIN')
login:SetScript('OnEvent',function()
 if OctoPokerDB and OctoPokerDB.turnTimer~=nil then timeLimit=OctoPokerDB.turnTimer end
 M.UpdateTimerLabel()
end)
