-- OctoWoW Raid Poker 1.4.11 | Classic UI, visual timer, presets, recovery
-- Kept separate from Core.lua to respect the legacy Lua chunk local limit.
local G=OctoPokerGame
local main=getglobal('OctoPokerFrame')
if not G or not main then return end
local addon=CreateFrame('Frame',nil,UIParent)
local function makeLabel(parent,x,y,width,size)
 local f=parent:CreateFontString(nil,'OVERLAY','GameFontNormal')
 f:SetPoint('TOPLEFT',parent,'TOPLEFT',x,y);f:SetWidth(width)
 f:SetFont('Fonts\\FRIZQT__.TTF',size,'OUTLINE')
 f:SetJustifyH('LEFT')
 return f
end
-- Timer is in the main frame, directly below the phase and turn text.
local timerTitle=makeLabel(main,19,-115,360,12)
local timerSeconds=makeLabel(main,455,-115,58,14)
timerSeconds:SetJustifyH('RIGHT')
local barBg=main:CreateTexture(nil,'ARTWORK')
barBg:SetTexture('Interface\\Buttons\\WHITE8X8')
barBg:SetVertexColor(0.12,0.10,0.08,0.85)
barBg:SetPoint('TOPLEFT',main,'TOPLEFT',19,-135);barBg:SetWidth(490);barBg:SetHeight(7)
local bar=main:CreateTexture(nil,'OVERLAY')
bar:SetTexture('Interface\\Buttons\\WHITE8X8')
bar:SetPoint('LEFT',barBg,'LEFT',0,0);bar:SetHeight(7);bar:SetWidth(490)
local turnKey='';local deadline=0;local timerLimit=30
local lastPhase='';local lastSession='';local lastRecovery=0;local recoveryPending=false
local status=makeLabel(main,205,-45,115,10)
status:Hide() -- Status is available through recovery logic; no overlapping HOST text.
status:SetJustifyH('RIGHT')
-- Presets sit in the narrow gap between the Raise amount field and betting buttons.
-- They populate the raise amount only, never change the player's balance.
local presets={{'+10s',10},{'+50s',50},{'+100s',100},{'1/4 Pot','QUARTER'},{'1/2 Pot','HALF'},{'Pot','POT'}}
local presetButtons={}
for i,item in ipairs(presets) do
 -- Capture each preset separately: legacy Lua loop variables are not safe in callbacks.
 local presetLabel=item[1]
 local presetAmount=item[2]
 local b=CreateFrame('Button',nil,main,'UIPanelButtonTemplate')
 b:SetWidth(58);b:SetHeight(20)
 b:SetPoint('TOPLEFT',main,'TOPLEFT',125+(i-1)*62,-380)
 b:SetText(presetLabel)
 local t=b:GetNormalTexture()
 if t then t:SetVertexColor(0.85,0.73,0.47) end
 b:SetScript('OnClick',function()
  local pot,bet,balance,owing=G.GetBetInfo()
  local amount=presetAmount
  if amount=='QUARTER' then amount=math.floor(pot/4) end
  if amount=='HALF' then amount=math.floor(pot/2) end
  if amount=='POT' then amount=pot end
  amount=math.max(1,amount)
  -- A raise amount is an increment; reserve the amount needed to call.
  local maximum=math.max(0,balance-owing)
  if maximum<=0 then
   DEFAULT_CHAT_FRAME:AddMessage('|cffff7777Poker: Not enough Silver to raise.|r')
   return
  end
  amount=math.min(amount,maximum)
  if G.raiseInput then G.raiseInput:SetText(tostring(amount)) end
 end)
 b:SetScript('OnEnter',function()
  GameTooltip:SetOwner(this,'ANCHOR_TOP')
  GameTooltip:SetText('Set raise amount: '..presetLabel)
  GameTooltip:AddLine('Sets the raise increment, not an All-In.',0.9,0.8,0.55)
  GameTooltip:AddLine('The amount is capped by your available Silver.',0.7,0.8,0.9)
  GameTooltip:Show()
 end)
 b:SetScript('OnLeave',function()GameTooltip:Hide()end)
 presetButtons[i]=b
end
-- Native WoW icons on the action buttons; no new artwork assets required.
local iconPaths={
 'Interface\\Icons\\Spell_Holy_GreaterHeal',
 'Interface\\Icons\\INV_Misc_Coin_01',
 'Interface\\Icons\\INV_Misc_Coin_02',
 'Interface\\Icons\\Ability_Rogue_FeignDeath',
 'Interface\\Icons\\INV_Misc_Gem_Diamond_01'
}
local iconButtons={}
local positions={24,112,200,288,400}
local widths={82,82,82,100,94}
for i=1,5 do
 local b=CreateFrame('Button',nil,main)
 b:SetWidth(19);b:SetHeight(19)
 b:SetPoint('TOPLEFT',main,'TOPLEFT',positions[i]+7,-441)
 local t=b:CreateTexture(nil,'ARTWORK');t:SetAllPoints(b);t:SetTexture(iconPaths[i]);t:SetTexCoord(0.08,0.92,0.08,0.92)
 b:EnableMouse(false)
 iconButtons[i]=b
end
-- Decorate the existing buttons rather than replacing their event handlers.
local function updateTimer()
 local phase,session,turn,players,actor=G.AdminState()
 local key=tostring(session)..':'..tostring(phase)..':'..tostring(turn)
 if key~=turnKey then
  turnKey=key;deadline=GetTime()+timerLimit
 end
 local betting=phase=='BET1' or phase=='BET2'
 if not betting then
  timerTitle:SetText('');timerSeconds:SetText('');barBg:Hide();bar:Hide()
 else
  barBg:Show();bar:Show()
  local remaining=math.max(0,math.ceil(deadline-GetTime()))
  local myTurn=tostring(actor or '')==UnitName('player')
  local c
  if not myTurn then c='|cffaaaaaa'
  elseif remaining<=5 then c='|cffff5555'
  elseif remaining<=10 then c='|cffffd45a'
  else c='|cff55ee88' end
  local label=myTurn and 'YOUR TURN - PLACE YOUR BET' or (tostring(actor or '-').."'S TURN - WAITING")
  timerTitle:SetText(c..label..'|r')
  timerSeconds:SetText(timerLimit==0 and '|cffaaaaaaOFF|r' or c..remaining..'s|r')
  local fraction=timerLimit>0 and math.max(0,math.min(1,(deadline-GetTime())/timerLimit)) or 1
  bar:SetWidth(math.max(1,490*fraction))
  if not myTurn then bar:SetVertexColor(0.52,0.52,0.52,1)
  elseif remaining<=5 then bar:SetVertexColor(0.95,0.22,0.18,1)
  elseif remaining<=10 then bar:SetVertexColor(0.98,0.73,0.19,1)
  else bar:SetVertexColor(0.25,0.80,0.40,1) end
 end
 for _,b in ipairs(presetButtons) do if betting and tostring(actor)==UnitName('player') then b:Enable() else b:Disable() end end
 -- Lightweight connection recovery: request the host's authoritative state
 -- on login and after a missing hand, with a cooldown to avoid addon spam.
 local now=GetTime()
 if G.GetRecoveryInfo then
  local id,p,host,hostSelf,cards=G.GetRecoveryInfo()
  if hostSelf then status:SetText('|cff55dd77HOST|r')
  elseif GetNumRaidMembers()<1 then status:SetText('|cffaaaaaaNO RAID|r')
  elseif recoveryPending then status:SetText('|cffffd16aSYNCING...|r')
  else status:SetText('|cff55dd77CONNECTED|r') end
  if not hostSelf and GetNumRaidMembers()>0 and host and now-lastRecovery>12 then
   if (p=='BET1' or p=='BET2' or p=='DRAW') and cards~=5 then
    lastRecovery=now;recoveryPending=true;G.RequestRecovery()
   elseif p=='SHOWDOWN' and not G.remoteResult then
    lastRecovery=now;recoveryPending=true;G.AdminSend('GETRESULT',id)
   elseif p=='IDLE' and id=='' then
    lastRecovery=now;recoveryPending=true;G.RequestRecovery()
   end
  end
  if cards==5 or G.remoteResult then recoveryPending=false end
 end
end
local tick=0
addon:SetScript('OnUpdate',function()
 tick=tick+arg1
 if tick<0.2 then return end
 tick=0
 updateTimer()
end)
local listener=CreateFrame('Frame',nil,UIParent)
listener:RegisterEvent('PLAYER_LOGIN')
listener:SetScript('OnEvent',function()
 if OctoPokerDB and OctoPokerDB.turnTimer~=nil then timerLimit=tonumber(OctoPokerDB.turnTimer) or 30 end
 lastRecovery=-20
end)
-- Sync the main timer from the authoritative host's existing ADMINTURN packet.
local previousPacket=OctoPoker152_onPokerPacket
OctoPoker152_onPokerPacket=function(kind,data,sender)
 if kind=='ADMINTURN' then
  local _,_,limit,remaining=string.find(data or '','^(%d+):(%d+)$')
  if limit then
   timerLimit=tonumber(limit) or 30
   deadline=GetTime()+(tonumber(remaining) or timerLimit)
  end
 elseif kind=='ADMINTIMER' then
  timerLimit=tonumber(data) or 30
 end
 previousPacket(kind,data,sender)
end
