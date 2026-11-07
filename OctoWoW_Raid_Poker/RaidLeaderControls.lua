-- Raid Leader Controls 2.0. Separate chunk: legacy Lua has a 200-local limit.
local G=OctoPokerGame
local f=CreateFrame('Frame','OctoPokerRaidControls',UIParent)
f:SetWidth(440);f:SetHeight(480);f:SetPoint('CENTER',UIParent,'CENTER',110,20)
f:SetMovable(true);f:EnableMouse(true);f:RegisterForDrag('LeftButton')
f:SetScript('OnDragStart',function()this:StartMoving()end)
f:SetScript('OnDragStop',function()this:StopMovingOrSizing()end)
f:SetBackdrop({bgFile='Interface\\DialogFrame\\UI-DialogBox-Background',edgeFile='Interface\\DialogFrame\\UI-DialogBox-Border',tile=true,tileSize=32,edgeSize=32,insets={left=8,right=8,top=8,bottom=8}})
f:SetFrameStrata('DIALOG')
local title=f:CreateFontString(nil,'OVERLAY','GameFontNormalLarge')
title:SetPoint('TOPLEFT',f,'TOPLEFT',20,-22);title:SetText('Raid Leader Controls')
local close=CreateFrame('Button',nil,f,'UIPanelCloseButton')
close:SetPoint('TOPRIGHT',f,'TOPRIGHT',-4,-4)
local info=f:CreateFontString(nil,'OVERLAY','GameFontHighlightSmall')
info:SetPoint('TOPLEFT',f,'TOPLEFT',20,-56);info:SetWidth(395);info:SetHeight(38)
info:SetJustifyH('LEFT')
local output=f:CreateFontString(nil,'OVERLAY','GameFontNormalSmall')
output:SetPoint('BOTTOMLEFT',f,'BOTTOMLEFT',20,22);output:SetWidth(395);output:SetHeight(42)
output:SetJustifyH('LEFT')
local selected=''
local channel='RAID'
local function showResult(ok,msg)
 output:SetText((ok and '|cFF66FF99' or '|cFFFF7777')..(msg or '')..'|r')
end
local function btn(label,x,y,w,callback)
 local b=CreateFrame('Button',nil,f,'UIPanelButtonTemplate')
 b:SetWidth(w);b:SetHeight(26);b:SetPoint('TOPLEFT',f,'TOPLEFT',x,y)
 b:SetText(label);b:SetScript('OnClick',callback)
 return b
end
local function confirm(label,callback)
 StaticPopupDialogs.OCTOPOKER_LEADER_CONFIRM={
  text=label,button1='Confirm',button2='Cancel',timeout=0,whileDead=1,hideOnEscape=1,
  OnAccept=function()local ok,msg=callback();showResult(ok,msg)end,preferredIndex=3
 }
 StaticPopup_Show('OCTOPOKER_LEADER_CONFIRM')
end
local function refresh()
 local phase,id,names,pot=G.LeaderControlInfo()
 info:SetText('Phase: '..phase..'   Pot: '..G.Display(pot)..'\nPlayers: '..(names~='' and names or 'none'))
end
btn('End Betting',20,-102,190,function()
 confirm('Advance betting? Pending calls will block this action.',G.LeaderControlEndBetting)
end)
btn('Force Showdown',225,-102,190,function()
 confirm('Force showdown now? Current cards will be evaluated and the pot paid.',G.LeaderControlForceShowdown)
end)
btn('Declare Winner',20,-138,190,function()
 if selected=='' then showResult(false,'Select a player first.');return end
 local n=selected
 confirm('Manually award the entire pot to '..n..'? This overrides poker hand ranking.',function()return G.LeaderControlManualWinner(n)end)
end)
btn('Cancel Hand',225,-138,190,function()
 confirm('Cancel this hand and refund every contributed Silver?',G.LeaderControlCancel)
end)
local chooseLabel=f:CreateFontString(nil,'OVERLAY','GameFontNormal')
chooseLabel:SetPoint('TOPLEFT',f,'TOPLEFT',20,-183)
chooseLabel:SetText('Select winner (active raid-table player):')
local playerButton
playerButton=btn('Select Player',20,-204,395,function()
 local _,_,names=G.LeaderControlInfo()
 local entries={}
 for n in string.gfind(names or '','[^,]+') do entries[table.getn(entries)+1]=n end
 if table.getn(entries)==0 then showResult(false,'No active table.');return end
 local current=1
 for i,n in ipairs(entries) do if n==selected then current=i;break end end
 current=math.mod(current,table.getn(entries))+1
 selected=entries[current]
 playerButton:SetText('Winner: '..selected..'  (click to change)')
end)
btn('Resend WINNER',20,-250,190,function()
 local ok,msg=G.LeaderControlResend();showResult(ok,msg)
end)
local raidBtn=btn('/raid',225,-250,91,function()channel='RAID';showResult(true,'Chat channel: /raid')end)
local sayBtn=btn('/say',324,-250,91,function()channel='SAY';showResult(true,'Chat channel: /say')end)
btn('Announce Winner',20,-292,395,function()
 local phase,id,names,pot,result=G.LeaderControlInfo()
 if not result or result=='' then showResult(false,'No completed hand.');return end
 G.LeaderControlAnnounce(result,channel);showResult(true,'Winner announced to '..channel)
end)
btn('Announce Balances',20,-328,395,function()
 local lines=G.LeaderControlBalances()
 if table.getn(lines)==0 then showResult(false,'No table players.');return end
 G.LeaderControlAnnounce('PLAYER BALANCES',channel)
 for _,line in ipairs(lines) do G.LeaderControlAnnounce(line,channel) end
 showResult(true,'Balances announced to '..channel)
end)
btn('Announce Table',20,-364,395,function()
 local phase,id,names,pot=G.LeaderControlInfo()
 G.LeaderControlAnnounce('Phase: '..phase..' | Pot: '..G.Display(pot),channel)
 G.LeaderControlAnnounce('Players: '..(names~='' and names or 'none'),channel)
 showResult(true,'Table status announced to '..channel)
end)
f:SetScript('OnShow',refresh)
f:Hide()
-- Keep the existing toolbar intact. The crown is an additional leader-only icon.
local root=OctoPokerFrame
local icon=CreateFrame('Button',nil,root)
icon:SetWidth(31);icon:SetHeight(31)
icon:SetPoint('TOPRIGHT',root,'TOPRIGHT',-223,-23)
local art=icon:CreateTexture(nil,'ARTWORK');art:SetAllPoints(icon)
art:SetTexture('Interface\\Icons\\INV_Crown_01')
local hl=icon:CreateTexture(nil,'HIGHLIGHT');hl:SetAllPoints(icon)
hl:SetTexture('Interface\\Buttons\\ButtonHilight-Square');hl:SetBlendMode('ADD')
icon:SetScript('OnClick',function()
 if not G.AdminLeader() then return end
 if f:IsShown() then f:Hide() else f:Show() end
end)
icon:SetScript('OnEnter',function()
 GameTooltip:SetOwner(this,'ANCHOR_RIGHT')
 GameTooltip:AddLine('Raid Leader Controls')
 GameTooltip:Show()
end)
icon:SetScript('OnLeave',function()GameTooltip:Hide()end)
icon:SetScript('OnUpdate',function()
 local yes=G.AdminLeader()
 if yes and not icon:IsShown() then icon:Show()
 elseif not yes and icon:IsShown() then icon:Hide();f:Hide() end
end)
