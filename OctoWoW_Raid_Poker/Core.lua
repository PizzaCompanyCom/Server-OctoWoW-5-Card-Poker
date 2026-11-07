-- OctoWoW Raid Poker 1.4.13 | WoW 1.17.1 / legacy Lua 5.1
local PREFIX='OCTOPOKER1'
local PROBE_PREFIX='OCTOPROBE1'
local frame=CreateFrame('Frame','OctoPokerFrame',UIParent)
-- Enlarge the complete main window and all anchored controls by 25%.
-- Scaling the parent preserves card positions and the four aligned footer buttons.
local DEFAULT_UI_SCALE=1.25
local MIN_UI_SCALE=0.75
local MAX_UI_SCALE=1.50
local function applyUIScale(value)
 value=tonumber(value) or DEFAULT_UI_SCALE
 if value<MIN_UI_SCALE then value=MIN_UI_SCALE end
 if value>MAX_UI_SCALE then value=MAX_UI_SCALE end
 frame:SetScale(value)
 OctoPokerDB=OctoPokerDB or {}
 OctoPokerDB.uiScale=value
 return value
end
frame:SetScale(DEFAULT_UI_SCALE)
frame:SetWidth(530);frame:SetHeight(745);frame:SetPoint('CENTER',UIParent,'CENTER',0,0);frame:SetMovable(true);frame:EnableMouse(true)
frame:RegisterForDrag('LeftButton');frame:SetScript('OnDragStart',function()this:StartMoving()end)
frame:SetScript('OnDragStop',function()this:StopMovingOrSizing();if OctoPokerDock then OctoPokerDock.Refresh() end end)
frame:SetBackdrop({bgFile='Interface\\DialogFrame\\UI-DialogBox-Background',edgeFile='Interface\\DialogFrame\\UI-DialogBox-Border',tile=true,tileSize=32,edgeSize=32,insets={left=8,right=8,top=8,bottom=8}})
frame:Hide()
-- Optional poker-table artwork. Kept on the BACKGROUND layer so cards, text and buttons remain readable.
local tableArt=frame:CreateTexture(nil,'BACKGROUND')
tableArt:SetPoint('TOPLEFT',frame,'TOPLEFT',12,-12)
tableArt:SetPoint('BOTTOMRIGHT',frame,'BOTTOMRIGHT',-12,12)
tableArt:Hide()
local TABLE_TEXTURES={Tavern='Tavern',Classic='Classic',Dwarven='Dwarven',Horde='Horde',Alliance='Alliance',NightElf='NightElf',Forsaken='Forsaken',Tauren='Tauren'}
local SOLID_TABLE_COLORS={['Solid Black']={0.04,0.04,0.05},['Solid Charcoal']={0.16,0.17,0.19},['Solid Green']={0.06,0.30,0.16},['Solid Blue']={0.07,0.17,0.38},['Solid Burgundy']={0.34,0.07,0.12},['Solid Brown']={0.30,0.18,0.10},['Solid Purple']={0.24,0.13,0.34},['Solid Beige']={0.60,0.49,0.34}}
local tableStyle='None'
local tableOpacity=0.60
local function applyTableBackground(style,opacity)
 if not TABLE_TEXTURES[style] and not SOLID_TABLE_COLORS[style] then style='None' end
 opacity=tonumber(opacity) or 0.60
 if opacity<0 then opacity=0 elseif opacity>1 then opacity=1 end
 tableStyle=style;tableOpacity=opacity
 if style=='None' then tableArt:Hide()
 elseif SOLID_TABLE_COLORS[style] then
  local rgb=SOLID_TABLE_COLORS[style]
  tableArt:SetTexture(rgb[1],rgb[2],rgb[3])
  tableArt:SetAlpha(opacity)
  tableArt:Show()
 else
  tableArt:SetTexture('Interface\\AddOns\\OctoWoW_Raid_Poker\\Tables\\'..TABLE_TEXTURES[style])
  tableArt:SetAlpha(opacity)
  tableArt:Show()
 end
 OctoPokerDB=OctoPokerDB or {}
 OctoPokerDB.tableStyle=style;OctoPokerDB.tableOpacity=opacity
end
-- Addon-only font themes. Original template font sizes and colours are preserved.
local FONT_THEMES={
 {name='WoW Classic (Friz Quadrata)',path='Fonts\\FRIZQT__.TTF'},
 {name='Arial Narrow',path='Fonts\\ARIALN.TTF'},
 {name='Morpheus',path='Fonts\\MORPHEUS.TTF'},
 {name='Skurri',path='Fonts\\SKURRI.TTF'},
}
local fontThemeIndex=1
local fontOriginals=setmetatable({},{__mode='k'})
local function fontRegion(region,path)
 if not region or not region.IsObjectType or not region:IsObjectType('FontString') then return end
 if not fontOriginals[region] then
  local original,size,flags=region:GetFont()
  if original and size and size>0 then fontOriginals[region]={original,size,flags or ''} end
 end
 local original=fontOriginals[region]
 if original then
  local ok=pcall(region.SetFont,region,path or original[1],original[2],original[3])
  if not ok then pcall(region.SetFont,region,original[1],original[2],original[3]) end
 end
end
local function fontTree(root,path,visited)
 if not root or visited[root] then return end
 visited[root]=true
 if root.IsObjectType and root:IsObjectType('FontString') then fontRegion(root,path) end
 if root.GetRegions then
  local regions={root:GetRegions()}
  for i=1,table.getn(regions) do fontRegion(regions[i],path) end
 end
 if root.GetChildren then
  local children={root:GetChildren()}
  for i=1,table.getn(children) do fontTree(children[i],path,visited) end
 end
end
local function applyFontTheme(index)
 index=tonumber(index) or 1
 if index<1 or index>table.getn(FONT_THEMES) then index=1 end
 fontThemeIndex=index
 local path=FONT_THEMES[index].path
 local visited={}
 -- Limit font changes to addon windows, never alter shared GameFont objects.
 local roots={'OctoPokerFrame','OctoPokerSettingsFrame','OctoPokerVictoryFrame','OctoPokerSoundSettings','OctoPokerBankFrame','OctoPokerHistoryFrame','OctoPokerRankingsFrame','OctoPokerRulesFrame','OctoPokerDebugFrame'}
 for i=1,table.getn(roots) do
  local f=getglobal(roots[i])
  if f then fontTree(f,path,visited) end
 end
 OctoPokerDB=OctoPokerDB or {}
 OctoPokerDB.fontTheme=index
end
local function label(template,x,y)
 local t=frame:CreateFontString(nil,'OVERLAY',template);t:SetPoint('TOPLEFT',frame,'TOPLEFT',x,y);return t
end
local title=label('GameFontNormalLarge',24,-20);title:SetText('OctoWoW Raid Poker  v1.4.13')
local status=label('GameFontHighlight',24,-55);status:SetWidth(485);status:SetJustifyH('LEFT')
local phaseLabel=label('GameFontNormal',24,-85)
local playersLabel=label('GameFontHighlightSmall',24,-111);playersLabel:Hide()
-- High-contrast turn banner, placed in the clear space above the hand.
local turnPanel=CreateFrame('Frame',nil,frame)
turnPanel:SetPoint('TOPLEFT',frame,'TOPLEFT',24,-126)
turnPanel:SetWidth(480);turnPanel:SetHeight(27)
turnPanel:SetBackdrop({bgFile='Interface\\DialogFrame\\UI-DialogBox-Background',edgeFile='Interface\\Tooltips\\UI-Tooltip-Border',tile=true,tileSize=16,edgeSize=12,insets={left=3,right=3,top=3,bottom=3}})
local turnText=turnPanel:CreateFontString(nil,'OVERLAY','GameFontNormalLarge')
turnText:SetPoint('CENTER',turnPanel,'CENTER',0,0)
turnText:SetWidth(465)
turnText:SetJustifyH('CENTER')
local handLabel=label('GameFontNormalLarge',24,-157)
local combinationPanel=CreateFrame('Frame',nil,frame)
combinationPanel:SetPoint('TOPRIGHT',frame,'TOPRIGHT',-15,-155)
combinationPanel:SetWidth(275);combinationPanel:SetHeight(27)
combinationPanel:SetBackdrop({bgFile='Interface\\Buttons\\WHITE8X8',edgeFile='Interface\\Tooltips\\UI-Tooltip-Border',tile=false,edgeSize=10,insets={left=3,right=3,top=3,bottom=3}})
combinationPanel:SetBackdropColor(0.08,0.07,0.04,0.95)
combinationPanel:SetBackdropBorderColor(0.95,0.73,0.20,1)
local combinationLabel=combinationPanel:CreateFontString(nil,'OVERLAY','GameFontNormalLarge')
combinationLabel:SetPoint('CENTER',combinationPanel,'CENTER',0,0)
combinationLabel:SetWidth(263)
combinationLabel:SetJustifyH('CENTER')
local selectionLabel=label('GameFontHighlightSmall',24,-185)
local bettingLabel=label('GameFontNormalLarge',24,-351);bettingLabel:SetWidth(495);bettingLabel:SetHeight(22);bettingLabel:SetJustifyH('LEFT')
bettingLabel:SetFont('Fonts\\FRIZQT__.TTF',12,'OUTLINE')
local logLabel=label('GameFontHighlightSmall',24,-438);logLabel:SetWidth(475);logLabel:SetHeight(18);logLabel:SetJustifyH('LEFT');logLabel:SetJustifyV('TOP');logLabel:Hide() -- results remain in History
local close=CreateFrame('Button',nil,frame,'UIPanelCloseButton');close:SetPoint('TOPRIGHT',frame,'TOPRIGHT',-6,-6)
local function button(text,x,y,w,fn)
 if y<=-389 then y=y-45 end
 local b=CreateFrame('Button',nil,frame,'UIPanelButtonTemplate');b:SetWidth(w);b:SetHeight(25);b:SetPoint('TOPLEFT',frame,'TOPLEFT',x,y);b:SetText(text);b:SetScript('OnClick',fn);return b
end
local function me() return UnitName('player') or '' end
local function short(n) return string.gsub(n or '', '%-.*$', '') end
local function same(a,b) return short(a)==short(b) end

-- Original generated WAV sounds. Pre-rendered gain levels work around legacy
-- PlaySoundFile lacking a per-effect volume argument.
local soundOptions={deal=true,turn=true,exchange=true,victory=true,coins=true,volume=70}
local soundTasks={}
local function soundPlay(kind)
 if not soundOptions[kind] or (soundOptions.volume or 0)<=0 then return end
 local vol=math.floor((soundOptions.volume or 70)/10+0.5)*10
 if vol<10 then vol=10 elseif vol>100 then vol=100 end
 local path='Interface\\AddOns\\OctoWoW_Raid_Poker\\Sounds\\'..kind..'_'..vol..'.wav'
 if PlaySoundFile then pcall(PlaySoundFile,path) end
end
local soundTicker=CreateFrame('Frame',nil,UIParent)
soundTicker:SetScript('OnUpdate',function()
 if table.getn(soundTasks)==0 then return end
 local now=GetTime()
 for i=table.getn(soundTasks),1,-1 do
  local task=soundTasks[i]
  if now>=task[1] then soundPlay(task[2]);table.remove(soundTasks,i) end
 end
end)
local function dealSound()
 soundPlay('deal')
 local now=GetTime()
 for i=1,4 do soundTasks[table.getn(soundTasks)+1]={now+i*0.15,'deal'} end
end
local soundWindow=CreateFrame('Frame','OctoPokerSoundSettings',UIParent)
soundWindow:SetWidth(350);soundWindow:SetHeight(290)
soundWindow:SetPoint('CENTER',UIParent,'CENTER',90,30)
soundWindow:SetMovable(true);soundWindow:EnableMouse(true);soundWindow:RegisterForDrag('LeftButton')
soundWindow:SetScript('OnDragStart',function()this:StartMoving()end)
soundWindow:SetScript('OnDragStop',function()this:StopMovingOrSizing()end)
soundWindow:SetBackdrop({bgFile='Interface\\DialogFrame\\UI-DialogBox-Background',edgeFile='Interface\\DialogFrame\\UI-DialogBox-Border',tile=true,tileSize=32,edgeSize=32,insets={left=8,right=8,top=8,bottom=8}})
soundWindow:SetFrameStrata('DIALOG')
local soundTitle=soundWindow:CreateFontString(nil,'OVERLAY','GameFontNormalLarge')
soundTitle:SetPoint('TOPLEFT',soundWindow,'TOPLEFT',22,-24);soundTitle:SetText('Poker Sound Settings')
local soundClose=CreateFrame('Button',nil,soundWindow,'UIPanelCloseButton')
soundClose:SetPoint('TOPRIGHT',soundWindow,'TOPRIGHT',-5,-5)
local soundChecks={}
local function saveSounds()
 OctoPokerDB=OctoPokerDB or {};OctoPokerDB.sounds=soundOptions
end
local soundNames={{'deal','Card Dealing Sound'},{'turn','Your Turn Notification'},{'exchange','Card Exchange Sound'},{'victory','Victory Sound'},{'coins','Betting Coin Sound'}}
for i,v in ipairs(soundNames) do
 local kind=v[1]
 local c=CreateFrame('CheckButton',nil,soundWindow,'UICheckButtonTemplate')
 c:SetPoint('TOPLEFT',soundWindow,'TOPLEFT',20,-45-i*32)
 c:SetWidth(24);c:SetHeight(24)
 local t=soundWindow:CreateFontString(nil,'OVERLAY','GameFontHighlight')
 t:SetPoint('LEFT',c,'RIGHT',4,0);t:SetText(v[2])
 c:SetScript('OnClick',function()soundOptions[kind]=this:GetChecked() and true or false;saveSounds()end)
 soundChecks[kind]=c
end
local soundVolumeText=soundWindow:CreateFontString(nil,'OVERLAY','GameFontNormal')
soundVolumeText:SetPoint('TOPLEFT',soundWindow,'TOPLEFT',25,-230)
local soundSlider=CreateFrame('Slider','OctoPokerSoundVolume',soundWindow,'OptionsSliderTemplate')
soundSlider:SetPoint('TOPLEFT',soundWindow,'TOPLEFT',30,-258)
soundSlider:SetWidth(270);soundSlider:SetHeight(16);soundSlider:SetMinMaxValues(0,100);soundSlider:SetValueStep(10)
_G['OctoPokerSoundVolumeLow']:SetText('0%')
_G['OctoPokerSoundVolumeHigh']:SetText('100%')
_G['OctoPokerSoundVolumeText']:SetText('')
soundSlider:SetScript('OnValueChanged',function()
 local v=math.floor(this:GetValue()/10+0.5)*10
 soundOptions.volume=v;soundVolumeText:SetText('Sound Volume: '..v..'%');saveSounds()
end)
local function refreshSoundSettings()
 for k,c in pairs(soundChecks) do c:SetChecked(soundOptions[k]) end
 soundSlider:SetValue(soundOptions.volume)
 soundVolumeText:SetText('Sound Volume: '..soundOptions.volume..'%')
end
soundWindow:Hide()
-- Winner announcement with miniature cards for every winning player.
local victoryFrame=CreateFrame('Frame','OctoPokerVictoryFrame',UIParent)
victoryFrame:SetWidth(530);victoryFrame:SetHeight(225)
victoryFrame:SetPoint('CENTER',UIParent,'CENTER',0,60)
victoryFrame:SetMovable(true);victoryFrame:EnableMouse(true)
victoryFrame:RegisterForDrag('LeftButton')
victoryFrame:SetScript('OnDragStart',function()this:StartMoving()end)
victoryFrame:SetScript('OnDragStop',function()this:StopMovingOrSizing()end)
victoryFrame:SetFrameStrata('FULLSCREEN_DIALOG')
victoryFrame:SetBackdrop({bgFile='Interface\\DialogFrame\\UI-DialogBox-Background',edgeFile='Interface\\DialogFrame\\UI-DialogBox-Border',tile=true,tileSize=32,edgeSize=32,insets={left=8,right=8,top=8,bottom=8}})
victoryFrame:SetBackdropBorderColor(1,0.72,0.15,1)
local victoryTitle=victoryFrame:CreateFontString(nil,'OVERLAY','GameFontNormalHuge')
victoryTitle:SetPoint('TOP',victoryFrame,'TOP',0,-24)
victoryTitle:SetTextColor(1,0.83,0.2)
local victoryPot=victoryFrame:CreateFontString(nil,'OVERLAY','GameFontNormalLarge')
victoryPot:SetPoint('TOP',victoryFrame,'TOP',0,-63)
local victoryScroll=CreateFrame('ScrollFrame','OctoPokerVictoryScroll',victoryFrame,'UIPanelScrollFrameTemplate')
victoryScroll:SetPoint('TOPLEFT',victoryFrame,'TOPLEFT',20,-92)
victoryScroll:SetWidth(466);victoryScroll:SetHeight(80)
local victoryContent=CreateFrame('Frame',nil,victoryScroll)
victoryContent:SetWidth(454);victoryContent:SetHeight(80)
victoryScroll:SetScrollChild(victoryContent)
local victoryRows={}
for i=1,40 do
 local row=CreateFrame('Frame',nil,victoryContent)
 row:SetWidth(450);row:SetHeight(34)
 row:SetPoint('TOPLEFT',victoryContent,'TOPLEFT',0,-(i-1)*35)
 local name=row:CreateFontString(nil,'OVERLAY','GameFontNormal')
 name:SetPoint('TOPLEFT',row,'TOPLEFT',6,-3)
 name:SetWidth(435);name:SetJustifyH('LEFT')
 local cards={}
 for j=1,5 do
  local tex=row:CreateTexture(nil,'ARTWORK')
  tex:SetWidth(46);tex:SetHeight(58)
  tex:SetPoint('TOPLEFT',row,'TOPLEFT',8+(j-1)*55,-29)
  local tag=row:CreateFontString(nil,'OVERLAY','GameFontNormalSmall')
  tag:SetPoint('BOTTOM',tex,'BOTTOM',0,2)
  cards[j]={tex=tex,tag=tag}
 end
 victoryRows[i]={frame=row,name=name,cards=cards}
 row:Hide()
end
local victoryClose=CreateFrame('Button',nil,victoryFrame,'UIPanelButtonTemplate')
victoryClose:SetWidth(90);victoryClose:SetHeight(23)
victoryClose:SetPoint('BOTTOM',victoryFrame,'BOTTOM',0,15);victoryClose:SetText('Close')
victoryClose:SetScript('OnClick',function()victoryFrame:Hide()end)
victoryFrame:Hide()
local function announceVictory(result,details,refreshOnly)
 local _,_,winnerList=string.find(result or '','^Winner: (.-) | Pot:')
 local _,_,gold=string.find(result or '','Pot: ([^|]+)')
 local winners={}
 for n in string.gfind(winnerList or '','[^,]+') do
  n=string.gsub(n,'^%s+','');n=string.gsub(n,'%s+$','')
  if n~='' and n~='none' then winners[table.getn(winners)+1]=n end
 end
 victoryTitle:SetText(table.getn(winners)>1 and 'SPLIT BANK!' or 'WINNER!')
 victoryPot:SetText('BANK: '..(gold or '0'))
  local found={}
  for name,desc in string.gfind(details or '','([^/]+): ([^%[]+) %[') do
   name=string.gsub(name,'^%s+','');name=string.gsub(name,'%s+$','')
   desc=string.gsub(desc,'%s+$','')
   found[name]={desc=desc}
  end
  -- Compact WINCOMBO messages are also cached by the receiving client.
  if OctoPokerGame and OctoPokerGame.winnerCombos then
   for name,desc in pairs(OctoPokerGame.winnerCombos) do found[name]={desc=desc} end
  end
 for i=1,40 do victoryRows[i].frame:Hide() end
 local count=math.min(table.getn(winners),40)
 local byFold=string.find(result or '',' | By Fold',1,true)~=nil
 for i=1,count do
  local n=winners[i];local row=victoryRows[i]
  local info=found[n] or {}
  if byFold then
   row.name:SetText(n..'  -  Winner (all other players folded)')
  else
   row.name:SetText(n..'  -  '..(info.desc or (OctoPokerGame and OctoPokerGame.inferredResult and 'Payout detected' or 'Winning combination pending')))
  end
  for j=1,5 do
   row.cards[j].tex:Hide()
   row.cards[j].tag:SetText('')
  end
  row.frame:Show()
 end
 victoryContent:SetHeight(math.max(80,count*35))
 victoryScroll:SetVerticalScroll(0)
 if not (OctoPokerDB and OctoPokerDB.hideVictoryPopup) then victoryFrame:Show() end
  if not refreshOnly then soundPlay('victory') end
end

local function raidCount() return GetNumRaidMembers and GetNumRaidMembers() or 0 end
local function leader()
 if raidCount()<1 then return nil end
 for i=1,raidCount() do local name,rank=GetRaidRosterInfo(i);if rank==2 then return name end end
 return nil
end
local function isLeader() return same(leader(),me()) and leader()~=nil end
local function inRaid(name)
 for i=1,raidCount() do local n=GetRaidRosterInfo(i);if same(n,name) then return true end end
 return false
end
-- OctoWoW transport: WHISPER addon messages fail with "Unknown addon chat type".
-- RAID addon messages were confirmed delivered on both clients.
-- IMPORTANT: targeted messages are recipient-tagged, NOT encrypted.
-- Anyone running a modified addon can inspect every hand on the RAID channel.
local TRANSPORT='RAID'
local warnedTransport=false
local transportUnavailable=false
-- Dedicated in-game diagnostics window. Logs are persisted by SavedVariables
-- to WTF/Account/<account>/SavedVariables/OctoWoW_Raid_Poker.lua on normal logout.
local debugLines={}
local debugOffset=0
local debugFrame=CreateFrame('Frame','OctoPokerDebugFrame',UIParent)
debugFrame:SetWidth(830);debugFrame:SetHeight(540)
debugFrame:SetPoint('CENTER',UIParent,'CENTER',0,0)
debugFrame:SetMovable(true);debugFrame:EnableMouse(true)
debugFrame:RegisterForDrag('LeftButton')
debugFrame:SetScript('OnDragStart',function() this:StartMoving() end)
debugFrame:SetScript('OnDragStop',function() this:StopMovingOrSizing() end)
debugFrame:SetBackdrop({bgFile='Interface\\DialogFrame\\UI-DialogBox-Background',edgeFile='Interface\\DialogFrame\\UI-DialogBox-Border',tile=true,tileSize=32,edgeSize=32,insets={left=8,right=8,top=8,bottom=8}})
debugFrame:SetFrameStrata('DIALOG')
local debugTitle=debugFrame:CreateFontString(nil,'OVERLAY','GameFontNormalLarge')
debugTitle:SetPoint('TOPLEFT',debugFrame,'TOPLEFT',24,-22)
debugTitle:SetText('OctoWoW Raid Poker - Network Diagnostics')
local debugText=debugFrame:CreateFontString(nil,'OVERLAY','GameFontHighlightSmall')
debugText:SetPoint('TOPLEFT',debugFrame,'TOPLEFT',22,-65)
debugText:SetWidth(780);debugText:SetHeight(398)
debugText:SetJustifyH('LEFT');debugText:SetJustifyV('TOP')
local debugClose=CreateFrame('Button',nil,debugFrame,'UIPanelCloseButton')
debugClose:SetPoint('TOPRIGHT',debugFrame,'TOPRIGHT',-5,-5)
local function refreshDebug()
 local count=table.getn(debugLines)
 local visible=20
 local maxOffset=math.max(0,count-visible)
 if debugOffset>maxOffset then debugOffset=maxOffset end
 local first=math.max(1,count-visible-debugOffset+1)
 local last=math.min(count,first+visible-1)
 local lines={}
 for i=first,last do lines[table.getn(lines)+1]=debugLines[i] end
 debugText:SetText(table.getn(lines)>0 and table.concat(lines,'\n') or 'No diagnostics yet. Start a hand and press Sync Cards on the other client.')
end
local function debugButton(text,x,callback)
 local b=CreateFrame('Button',nil,debugFrame,'UIPanelButtonTemplate')
 b:SetWidth(110);b:SetHeight(24)
 b:SetPoint('BOTTOMLEFT',debugFrame,'BOTTOMLEFT',x,21)
 b:SetText(text);b:SetScript('OnClick',callback)
 return b
end
debugButton('Older',22,function() debugOffset=math.min(math.max(0,table.getn(debugLines)-20),debugOffset+15);refreshDebug() end)
debugButton('Newer',139,function() debugOffset=math.max(0,debugOffset-15);refreshDebug() end)
debugButton('Latest',256,function() debugOffset=0;refreshDebug() end)
debugButton('Net Test',490,function()runProbes();refreshDebug()end)
debugButton('Clear Log',373,function()
 debugLines={};debugOffset=0
 OctoPokerDB=OctoPokerDB or {};OctoPokerDB.debugLog={}
 refreshDebug()
end)
debugFrame:Hide()
local function debugLog(line)
 local entry=string.sub(tostring(GetTime())..' '..tostring(line),1,260)
 table.insert(debugLines,entry)
 if table.getn(debugLines)>400 then table.remove(debugLines,1) end
 OctoPokerDB=OctoPokerDB or {}
 OctoPokerDB.debugLog=debugLines
 if debugFrame:IsShown() then debugOffset=0;refreshDebug() end
end
-- Compatibility probe never contains poker hands or other private game state.
-- A successful API call means only that the client accepted the call.
local function probeChannel(channel,target)
 if not SendAddonMessage then debugLog('PROBE '..channel..' unavailable: no API');return end
 local payload='PING:'..short(me())..':'..tostring(math.floor(GetTime()))
 local ok,err=pcall(SendAddonMessage,PROBE_PREFIX,payload,channel,target)
 debugLog('PROBE TX '..channel..' target='..tostring(target or '-')..' '..(ok and 'API_OK (not delivery)' or tostring(err)))
end
local function runProbes()
 local host=leader()
 transportUnavailable=false
 debugLog('PROBE BEGIN me='..me()..' leader='..tostring(host)..' raid='..tostring(raidCount()))
 if host and not same(host,me()) then probeChannel('WHISPER',host) end
 probeChannel('RAID')
 probeChannel('PARTY')
 -- Guild channel is diagnostic only; game messages use RAID.
 if IsInGuild and IsInGuild() then probeChannel('GUILD') end
 debugLog('PROBE END: compare RX on both clients. API_OK is NOT delivery.')
end
local function sendOne(message,target)
 if not SendAddonMessage or transportUnavailable then
  debugLog('TX BLOCKED no addon transport');return false
 end
 -- Target tags only prevent accidental UI display by other clients.
 -- They DO NOT provide card confidentiality on the wire.
 local packet=target and ('TO:'..short(target)..':'..message) or message
 local ok,err=pcall(SendAddonMessage,PREFIX,packet,TRANSPORT)
 debugLog('TX '..(target and short(target) or 'ALL')..' '..string.sub(message,1,18)..' '..(ok and 'API_OK (not delivery)' or tostring(err)))
 if not ok and not warnedTransport then warnedTransport=true;debugLog('RAID transport error: '..tostring(err)) end
 if not ok and string.find(tostring(err),'Unknown addon chat type',1,true) then transportUnavailable=true end
 return ok
end
local function send(kind,payload,channel,target)
 if raidCount()<1 then debugLog('SEND BLOCKED: raidCount=0');return end
 local message=kind..'~'..(payload or '')
 if channel=='WHISPER' then
  if target and not same(target,me()) then sendOne(message,target) end
 else sendOne(message,nil) end
end
local function notice(t) status:SetText(t) end
local ranks={'2','3','4','5','6','7','8','9','10','J','Q','K','A'}
local suits={'S','H','D','C'}
local deck,participants,hands,folded,drawn,chosen={},{},{},{},{},{}
local receivedHands={};local handAcknowledged={};local syncRequestedAt=0;local lastSyncAt=0
local balances, pot, streetBet, contrib, roundPaid, acted, betStage = {}, 0, 0, {}, {}, {}, 0
OctoPokerGame=OctoPokerGame or {}
local G=OctoPokerGame
G.allin={};G.stats={};G.dealer='';G.rotation=true;G.ante=10
-- All stored amounts are integer Silver units. No currency conversion.
function G.Unit() return 's' end
function G.Display(amount)
 return tostring(math.floor(tonumber(amount) or 0))..'s'
end
function G.Entry(amount)
 amount=tonumber(amount)
 if not amount or amount<0 or amount~=math.floor(amount) then return nil end
 return amount
end
function G.Input(amount)
 return tostring(math.floor(tonumber(amount) or 0))
end
function G.RefreshCurrency()
 if G.OctoPoker152_anteEdit then G.OctoPoker152_anteEdit:SetText(G.Input(G.ante)) end
 if G.raiseInput then G.raiseInput:SetText(OctoPokerDB and OctoPokerDB.lastRaise or '') end
 if G.raiseLabel then G.raiseLabel:SetText('Raise') end
 if G.anteLabel then G.anteLabel:SetText('Ante (Silver)') end
 if G.bankAmount then G.bankAmount:SetText('100000') end
 if G.bankInfo then G.bankInfo:SetText('Raid Leader only. All amounts in Silver (s).') end
 if OctoPokerBank and OctoPokerBank.Refresh then OctoPokerBank.Refresh() end
 if OctoPokerBank and OctoPokerBank.Render then OctoPokerBank.Render() end
end
function G.Stat(n)
 local k=short(n)
 G.stats[k]=G.stats[k] or {played=0,wins=0,losses=0,net=0,allins=0}
 return G.stats[k]
end
function G.Save()
 OctoPokerDB=OctoPokerDB or {}
 OctoPokerDB.pokerStats=G.stats
 OctoPokerDB.dealerName=G.dealer
 OctoPokerDB.dealerRotation=G.rotation
 OctoPokerDB.anteAmount=G.ante
end
function G.Payout(list,folds,holdings,invested,evaluator,comparator)
 local levels,seen,payout,winnerSet={},{},{},{}
 for _,n in ipairs(list) do
  local v=invested[n] or 0
  if v>0 and not seen[v] then levels[table.getn(levels)+1]=v;seen[v]=true end
 end
 table.sort(levels)
 local previous=0
 for _,level in ipairs(levels) do
  local count,eligible=0,{}
  for _,n in ipairs(list) do
   if (invested[n] or 0)>=level then
    count=count+1
    if not folds[n] and holdings[n] then eligible[table.getn(eligible)+1]=n end
   end
  end
  local total=(level-previous)*count
  if total>0 and table.getn(eligible)==0 then
   -- Return unmatched chips to their contributor rather than losing virtual gold.
   local owner=nil
   for _,n in ipairs(list) do
    if (invested[n] or 0)>=level then owner=n;break end
   end
   if owner then payout[owner]=(payout[owner] or 0)+total end
  elseif total>0 then
   local best,winners=nil,{}
   for _,n in ipairs(eligible) do
    local score=evaluator(holdings[n]);local cmp=comparator(score,best)
    if cmp>0 then best=score;winners={n}
    elseif cmp==0 then winners[table.getn(winners)+1]=n end
   end
   local share=math.floor(total/table.getn(winners))
   local extra=total-share*table.getn(winners)
   for i,n in ipairs(winners) do
    payout[n]=(payout[n] or 0)+share+(i<=extra and 1 or 0)
    winnerSet[n]=true
   end
  end
  previous=level
 end
 return payout,winnerSet
end
function G.NextDealer(list)
 local i=1
 if G.dealer~='' then
  for index,n in ipairs(list) do
   if same(n,G.dealer) then
    if G.rotation then i=math.mod(index,table.getn(list))+1 else i=index end
    break
   end
  end
 end
 G.dealer=list[i];G.Save();return i
end
function G.SerializeStats()
 local parts={}
 for name,st in pairs(G.stats) do
  parts[table.getn(parts)+1]=name..':'..st.played..':'..st.wins..':'..st.losses..':'..st.net..':'..st.allins
 end
 return table.concat(parts,',')
end
function G.ReadStats(raw)
 for entry in string.gfind(raw or '','[^,]+') do
  local _,_,name,p,w,l,net,a=string.find(entry,'^([^:]+):(%d+):(%d+):(%d+):([%-]?%d+):(%d+)$')
  if name then G.stats[name]={played=tonumber(p),wins=tonumber(w),losses=tonumber(l),net=tonumber(net),allins=tonumber(a)} end
 end
 G.Save()
end
local phase='IDLE';local session='';local current=1;local myCards={};local publicText='';local lastResult='';local history={}
local function nameAt(i) return participants[i] or '' end
local function cardRank(card)
 local r=string.sub(card,1,-2)
 for i,v in ipairs(ranks) do if r==v then return i+1 end end
 return 0
end
local function evaluate(cards)
 if not cards or table.getn(cards)~=5 then return {0},'Invalid hand' end
 local count,values,suit={},{},nil
 for _,c in ipairs(cards) do
  local r=cardRank(c);if r<2 then return {0},'Invalid hand' end
  count[r]=(count[r] or 0)+1;values[table.getn(values)+1]=r
  local s=string.sub(c,-1);if suit==nil then suit=s elseif suit~=s then suit=false end
 end
 table.sort(values,function(a,b)return a>b end)
 local uniq={};for _,v in ipairs(values) do if uniq[table.getn(uniq)]~=v then uniq[table.getn(uniq)+1]=v end end
 local straight=0
 if table.getn(uniq)==5 then
  if uniq[1]-uniq[5]==4 then straight=uniq[1]
  elseif uniq[1]==14 and uniq[2]==5 and uniq[5]==2 then straight=5 end
 end
 local groups={};for r,n in pairs(count) do groups[table.getn(groups)+1]={n,r} end
 table.sort(groups,function(a,b)if a[1]~=b[1]then return a[1]>b[1]end return a[2]>b[2]end)
 local ordered={};for _,g in ipairs(groups)do for j=1,g[1]do ordered[table.getn(ordered)+1]=g[2]end end
 if suit and straight>0 then return {8,straight},'Straight Flush' end
 if groups[1][1]==4 then return {7,groups[1][2],groups[2][2]},'Four of a Kind' end
 if groups[1][1]==3 and groups[2][1]==2 then return {6,groups[1][2],groups[2][2]},'Full House' end
 if suit then return {5,unpack(values)},'Flush' end
 if straight>0 then return {4,straight},'Straight' end
 if groups[1][1]==3 then return {3,unpack(ordered)},'Three of a Kind' end
 if groups[1][1]==2 and groups[2][1]==2 then
  local high=math.max(groups[1][2],groups[2][2]);local low=math.min(groups[1][2],groups[2][2])
  return {2,high,low,groups[3][2]},'Two Pair'
 end
 if groups[1][1]==2 then return {1,unpack(ordered)},'One Pair' end
 return {0,unpack(values)},'High Card'
end
local function compare(a,b)
 if not b then return 1 end
 for i=1,math.max(table.getn(a),table.getn(b)) do local x,y=a[i] or 0,b[i] or 0;if x>y then return 1 elseif x<y then return -1 end end
 return 0
end
local function shuffle()
 deck={};for _,s in ipairs(suits)do for _,r in ipairs(ranks)do deck[table.getn(deck)+1]=r..s end end
 for i=table.getn(deck),2,-1 do local j=math.random(i);deck[i],deck[j]=deck[j],deck[i] end
end
local function drawCard() return table.remove(deck) end
local function joinNames() return table.concat(participants,',') end
local cardsButtons={}
local actionButtons={}
local historyFrame=CreateFrame('Frame','OctoPokerHistoryFrame',UIParent)
historyFrame:SetWidth(520);historyFrame:SetHeight(360)
historyFrame:SetPoint('CENTER',UIParent,'CENTER',35,15)
historyFrame:SetMovable(true);historyFrame:EnableMouse(true)
historyFrame:RegisterForDrag('LeftButton')
historyFrame:SetScript('OnDragStart',function() this:StartMoving() end)
historyFrame:SetScript('OnDragStop',function() this:StopMovingOrSizing() end)
historyFrame:SetBackdrop({bgFile='Interface\\DialogFrame\\UI-DialogBox-Background',edgeFile='Interface\\DialogFrame\\UI-DialogBox-Border',tile=true,tileSize=32,edgeSize=32,insets={left=8,right=8,top=8,bottom=8}})
historyFrame:SetFrameStrata('DIALOG')
local historyTitle=historyFrame:CreateFontString(nil,'OVERLAY','GameFontNormalLarge')
historyTitle:SetPoint('TOPLEFT',historyFrame,'TOPLEFT',24,-24)
historyTitle:SetText('Poker Hand History')
local historyText=historyFrame:CreateFontString(nil,'OVERLAY','GameFontHighlightSmall')
historyText:SetPoint('TOPLEFT',historyFrame,'TOPLEFT',24,-65)
historyText:SetWidth(470);historyText:SetHeight(265)
historyText:SetJustifyH('LEFT');historyText:SetJustifyV('TOP')
local historyClose=CreateFrame('Button',nil,historyFrame,'UIPanelCloseButton')
historyClose:SetPoint('TOPRIGHT',historyFrame,'TOPRIGHT',-5,-5)
historyFrame:Hide()
local function updateHistory()
 local lines={}
 for i=math.max(1,table.getn(history)-9),table.getn(history) do
  lines[table.getn(lines)+1]=tostring(i)..'. '..history[i]
 end
 historyText:SetText(table.getn(lines)>0 and table.concat(lines,'\n') or 'No completed hands yet.')
end
local function balanceOf(n) return balances[short(n)] or 100000 end
-- Raid bank management uses a single module table to minimize Lua 5.0 upvalues.
OctoPokerBank = OctoPokerBank or {}
G.disabledPlayers=G.disabledPlayers or {}
function OctoPokerBank.IsEnabled(name)
 return not G.disabledPlayers[short(name)]
end
function OctoPokerBank.SyncEnabled()
 if not isLeader() then return end
 local names={}
 for i=1,raidCount() do
  local n=GetRaidRosterInfo(i)
  if n and G.disabledPlayers[short(n)] then names[table.getn(names)+1]=short(n) end
 end
 send('ELIG',table.concat(names,','))
end
function OctoPokerBank.SetEnabled(name,enabled)
 if not isLeader() then notice('Only Raid Leader can manage table eligibility.');return end
 if phase=='DRAW' or phase=='BET1' or phase=='BET2' then notice('Change participation between hands.');return end
 if not inRaid(name) then notice('Player must be in the raid.');return end
 name=short(name)
 G.disabledPlayers[name]=enabled and nil or true
 OctoPokerDB=OctoPokerDB or {}
 OctoPokerDB.disabledPlayers=G.disabledPlayers
 if not enabled then G.joined[name]=nil end
 OctoPokerBank.SyncEnabled()
 send('LOBBY',table.concat(G.JoinedNames(),','))
 if OctoPokerBank.Refresh then OctoPokerBank.Refresh() end
 if OctoPokerBank.Render then OctoPokerBank.Render() end
 notice(name..(enabled and ' enabled for future hands.' or ' excluded from future hands.'))
end

function OctoPokerBank.List()
 local rows={}
 for i=1,raidCount() do
  local n=GetRaidRosterInfo(i)
  if n then rows[table.getn(rows)+1]=short(n)..'  -  '..G.Display(balanceOf(n))..(OctoPokerBank.IsEnabled(n) and '  [ENABLED]' or '  [DISABLED]') end
 end
 return table.concat(rows,'\n')
end
function OctoPokerBank.Broadcast()
 if not isLeader() then return end
 local entries={}
 for i=1,raidCount() do
  local n=GetRaidRosterInfo(i)
  if n then entries[table.getn(entries)+1]=short(n)..':'..tostring(balanceOf(n)) end
 end
 send('BALALL',table.concat(entries,','))
end
function OctoPokerBank.Set(name,amount)
 if not isLeader() then notice('Only Raid Leader can edit balances.');return false end
 if phase=='DRAW' or phase=='BET1' or phase=='BET2' then notice('Balances can only be edited between hands.');return false end
 amount=G.Entry(amount)
 if not amount or amount>10000000000 then notice('Enter a valid Silver amount.');return false end
 if name=='ALL' then
  for i=1,raidCount() do local n=GetRaidRosterInfo(i);if n then balances[short(n)]=amount end end
 else
  if not inRaid(name) then notice('Player must be in your raid.');return false end
  balances[short(name)]=amount
 end
 OctoPokerDB=OctoPokerDB or {};OctoPokerDB.balances=balances
 OctoPokerBank.Broadcast()
 notice('Raid balances updated: '..name..' = '..G.Display(amount)..'.')
 if OctoPokerBank.Render then OctoPokerBank.Render() end
 if OctoPokerBank.Refresh then OctoPokerBank.Refresh() end
 return true
end
local function aliveCount()
 local count=0;for _,n in ipairs(participants) do if not folded[n] then count=count+1 end end;return count
end
local function bettingPhase() return phase=='BET1' or phase=='BET2' end
local function roundState()
 local parts={}
 for _,n in ipairs(participants) do parts[table.getn(parts)+1]=short(n)..':'..tostring(balanceOf(n))..':'..tostring(roundPaid[n] or 0)..':'..tostring(contrib[n] or 0)..':'..(acted[n] and '1' or '0')..':'..(G.allin[n] and '1' or '0') end
 return tostring(pot)..';'..tostring(streetBet)..';'..table.concat(parts,',')
end
local lastTurnSoundKey=nil
local function updateTurnBanner()
 local active=phase=='DRAW' or phase=='BET1' or phase=='BET2'
 local turnKey=session..':'..phase..':'..tostring(current)
 if active and same(nameAt(current),me()) and turnKey~=lastTurnSoundKey then soundPlay('turn') end
 lastTurnSoundKey=turnKey
 if active then
  local who=nameAt(current) or ''
  local mine=same(who,me())
  if mine then
   turnText:SetText('YOUR TURN  -  '..(phase=='DRAW' and 'EXCHANGE CARDS' or 'PLACE YOUR BET'))
   turnText:SetTextColor(0.35,1,0.30)
   turnPanel:SetBackdropColor(0.02,0.22,0.04,0.98)
   turnPanel:SetBackdropBorderColor(0.30,0.95,0.25,1)
  else
   turnText:SetText('WAITING FOR '..short(who)..'  -  '..(phase=='DRAW' and 'CARD EXCHANGE' or 'BETTING'))
   turnText:SetTextColor(1,0.78,0.24)
   turnPanel:SetBackdropColor(0.25,0.13,0.02,0.98)
   turnPanel:SetBackdropBorderColor(0.95,0.65,0.18,1)
  end
 else
  turnText:SetText(phase=='IDLE' and 'WAITING FOR RAID LEADER TO START' or 'HAND FINISHED  -  READY FOR NEXT HAND')
  turnText:SetTextColor(0.75,0.78,0.83)
  turnPanel:SetBackdropColor(0.08,0.08,0.10,0.95)
  turnPanel:SetBackdropBorderColor(0.45,0.45,0.50,1)
 end
end
-- Shared public betting feed: each client receives the same dealer-approved event.
OctoPokerBets=OctoPokerBets or {}
local B=OctoPokerBets
B.entries={};B.last='';B.highlightUntil=0
betFeed=CreateFrame('Frame',nil,frame)
betFeed:SetWidth(480);betFeed:SetHeight(103)
betFeed:SetPoint('TOPLEFT',frame,'TOPLEFT',24,-470)
betFeed:SetBackdrop({bgFile='Interface\\Buttons\\WHITE8X8',edgeFile='Interface\\Tooltips\\UI-Tooltip-Border',tile=false,edgeSize=12,insets={left=4,right=4,top=4,bottom=4}})
betFeed:SetBackdropColor(0.04,0.03,0.02,0.88)
betFeed:SetBackdropBorderColor(0.75,0.53,0.17,0.9)
betFeedText=betFeed:CreateFontString(nil,'OVERLAY','GameFontHighlight')
betFeedText:SetPoint('TOPLEFT',betFeed,'TOPLEFT',12,-9)
betFeedText:SetWidth(450);betFeedText:SetHeight(89)
local feedFont,_,feedFlags=GameFontHighlight:GetFont()
if feedFont then betFeedText:SetFont(feedFont,14,feedFlags) end
betFeedText:SetJustifyH('LEFT');betFeedText:SetJustifyV('TOP')
betAlert=frame:CreateFontString(nil,'OVERLAY','GameFontNormalLarge')
betAlert:SetPoint('TOP',frame,'TOP',0,-42)
betAlert:SetWidth(490);betAlert:SetHeight(26)
betAlert:SetText('');betAlert:Hide() -- all action messages are shown in Betting Activity only
betAlertClock=CreateFrame('Frame',nil,frame)
betAlertClock:SetScript('OnUpdate',function()
 if B.highlightUntil>0 and GetTime()>B.highlightUntil then
  B.highlightUntil=0;betAlert:SetText('')
 end
end)
function B.Event(name,kind,amount,newpot)
 local line
 amount=tonumber(amount) or 0
 if kind=='ANTE' then line='ANTE  '..G.Display(amount)..' each  |  Starting pot: '..G.Display(newpot)
 elseif kind=='FOLD' then line=short(name)..'  FOLDS'
 elseif kind=='CHECK' then line=short(name)..'  CHECKS'
 elseif kind=='ALLIN' then line=short(name)..'  ALL-IN  '..G.Display(amount)
 elseif kind=='RAISE' then line=short(name)..'  RAISES  '..G.Display(amount)
 else line=short(name)..'  CALLS  '..G.Display(amount) end
 B.last=line
 table.insert(B.entries,1,line)
 while table.getn(B.entries)>5 do table.remove(B.entries) end
 local colors={CHECK='FF72C6FF',CALL='FF65E887',RAISE='FFFFC34D',FOLD='FFFF7777',ALLIN='FFFF963C',ANTE='FFFFDD80'}
 local feedLines={}
 for i=1,table.getn(B.entries) do
  local entry=B.entries[i]
  local action=string.find(entry,'  CHECKS',1,true) and 'CHECK'
   or (string.find(entry,'  CALLS',1,true) and 'CALL')
   or (string.find(entry,'  RAISES',1,true) and 'RAISE')
   or (string.find(entry,'  FOLDS',1,true) and 'FOLD')
   or (string.find(entry,'  ALL-IN',1,true) and 'ALLIN')
   or (string.find(entry,'ANTE  ',1,true) and 'ANTE')
  feedLines[i]=action and ('|c'..colors[action]..entry..'|r') or entry
 end
 betFeedText:SetText('|cFFFFD67A BETTING ACTIVITY  |  BANK: '..G.Display(newpot or pot)..'|r\n'..table.concat(feedLines,'\n'))
 if kind=='ANTE' then
  betAlert:SetText('')
  B.highlightUntil=0
  return
 end
 -- Do not show duplicate floating action alerts.
 if kind=='FOLD' then betAlert:SetTextColor(1,0.42,0.38)
 elseif kind=='CHECK' then betAlert:SetTextColor(0.45,0.80,1)
 else betAlert:SetTextColor(1,0.82,0.28) end
 B.highlightUntil=0
 if amount>0 then soundPlay('coins') end
end
-- Winner lines are independent of the optional popup.
function B.Result(result)
 local line=result or ''
 table.insert(B.entries,1,'RESULT  '..line)
 while table.getn(B.entries)>5 do table.remove(B.entries) end
 local lines={}
 for i=1,table.getn(B.entries) do
  local entry=B.entries[i]
  if string.sub(entry,1,8)=='RESULT  ' then
   lines[i]='|cFFFFD67A'..entry..'|r'
  else lines[i]=entry end
 end
 betFeedText:SetText('|cFFFFD67A BETTING ACTIVITY|r\n'..table.concat(lines,'\n'))
end
local function render()
 if G.RefreshJoinButton then G.RefreshJoinButton() end
 updateTurnBanner()
 phaseLabel:SetText('Phase: '..phase..'     Dealer: '..short(G.dealer~='' and G.dealer or (leader() or 'none'))..'     Turn: '..((phase=='DRAW' or bettingPhase()) and (same(nameAt(current),me()) and 'YOU' or short(nameAt(current))) or '-'))
 -- Player list hidden; membership remains available through Player Balances.
 handLabel:SetText(table.getn(myCards)==5 and 'Your Raid Boss Cards' or 'Waiting for cards')
 if table.getn(myCards)==5 then
  local handScore, handName=evaluate(myCards)
  combinationLabel:SetText('Current Hand: '..handName)
  if handScore[1]>=4 then combinationLabel:SetTextColor(0.35,1,0.35)
  elseif handScore[1]>=1 then combinationLabel:SetTextColor(1,0.83,0.3)
  else combinationLabel:SetTextColor(0.9,0.9,0.9) end
 else
  combinationLabel:SetText('Current Hand: --')
  combinationLabel:SetTextColor(0.6,0.6,0.6)
 end
 for i=1,5 do
  local c=myCards[i]
  if c then
   local r=string.sub(c,1,-2)
   cardsButtons[i]:Show()
   cardsButtons[i].art:SetTexture(OctoPokerCardTheme.Path(c))
   cardsButtons[i].tag:SetText('')
   if chosen[i] then cardsButtons[i].art:SetVertexColor(0.65,0.95,0.65) else cardsButtons[i].art:SetVertexColor(1,1,1) end
  else cardsButtons[i]:Hide() end
 end
 local indexes={};for i=1,5 do if chosen[i] then indexes[table.getn(indexes)+1]=tostring(i) end end
 selectionLabel:SetText('Cards selected for exchange: '..(table.getn(indexes)>0 and table.concat(indexes,', ') or 'none'))
 local myTurn=phase=='DRAW' and same(nameAt(current),me())
 for _,b in ipairs(actionButtons) do if myTurn then b:Enable() else b:Disable() end end
 if actionButtons.start then if isLeader() and phase~='DRAW' and not bettingPhase() then actionButtons.start:Enable() else actionButtons.start:Disable() end end
 for i=1,5 do if myTurn then cardsButtons[i]:Enable() else cardsButtons[i]:Disable() end end
 bettingLabel:SetText('|cFFFFD76ABank:|r |cFFFFFFFF'..G.Display(pot)..'|r   |cFFFFD76ACurrent Bet:|r |cFFFFB347'..G.Display(streetBet)..'|r   |cFFFFD76ABalance:|r |cFF55EE88'..G.Display(balanceOf(me()))..'|r   |cFFFFD76ATo Call:|r |cFFFF7777'..G.Display(math.max(0,streetBet-(roundPaid[me()] or 0)))..'|r')
 if actionButtons.bet then for _,b in ipairs(actionButtons.bet) do if bettingPhase() and same(nameAt(current),me()) and not G.allin[nameAt(current)] then b:Enable() else b:Disable() end end end
 -- Removed redundant message line below the betting buttons; History retains results.
end
OctoPokerBank.Render=render
-- Administrative full reset: shared zero balances, history, pot and active hand.
OctoPokerAdmin = OctoPokerAdmin or {}
function OctoPokerAdmin.ResetLocal()
 phase='IDLE';session='';current=1;myCards={};chosen={}
 participants={};hands={};deck={};folded={};drawn={}
 contrib={};roundPaid={};acted={};betStage=0
 pot=0;streetBet=0;publicText='';lastResult=''
 history={};balances={};G.stats={};G.dealer='';G.allin={};B.entries={};betFeedText:SetText('BETTING ACTIVITY');betAlert:SetText('');G.Save()
 for i=1,raidCount() do
  local n=GetRaidRosterInfo(i)
  if n then balances[short(n)]=0 end
 end
 OctoPokerDB=OctoPokerDB or {}
 OctoPokerDB.history=history;OctoPokerDB.balances=balances
 if victoryFrame then victoryFrame:Hide() end
 updateHistory();render()
 if OctoPokerBank.Refresh then OctoPokerBank.Refresh() end
end
function OctoPokerAdmin.ResetAll()
 if not isLeader() then notice('Only Raid Leader can reset the entire table.');return end
 -- Broadcast before applying the reset locally.
 send('FULLRESET','RESET')
 OctoPokerAdmin.ResetLocal()
 notice('All poker balances, results and hands have been reset to zero.')
end
StaticPopupDialogs['OCTOPOKER_NO_BALANCE']={
 text='Cannot start a new hand.\n\nInsufficient Silver balance: %s\n\nOpen Player Balances to assign Silver or set these players to DISABLED to exclude them from future hands.',
 button1='Player Balances',button2='Close',timeout=0,whileDead=1,hideOnEscape=1,
 OnAccept=function()
  if OctoPokerBank.Refresh then OctoPokerBank.Refresh() end
  if OctoPoker152_bankFrame then OctoPoker152_bankFrame:Show() end
 end,
 preferredIndex=3
}
StaticPopupDialogs['OCTOPOKER_RESET_ALL']={
 text='Reset ALL raid poker balances to 0 Silver, clear all results and cancel the current hand? This cannot be undone.',
 button1='Reset All',button2='Cancel',timeout=0,whileDead=1,hideOnEscape=1,
 OnAccept=function() OctoPokerAdmin.ResetAll() end,
 preferredIndex=3
}
local function pushHistory(msg)
 history[table.getn(history)+1]=msg;if table.getn(history)>30 then table.remove(history,1) end
 OctoPokerDB=OctoPokerDB or {};OctoPokerDB.history=history
 lastResult=msg;updateHistory();render()
end
-- Reliable final settlement: a compact WINEND packet also ends the turn on
-- non-leader clients. The host repeats it briefly to tolerate dropped packets.
function G.ApplyFinal(result)
 if not result or result=='' then return end
 phase='SHOWDOWN'
 G.nextResultRequest=nil
 if G.remoteResult~=result or G.inferredResult then
  G.remoteResult=result;G.remoteDetails='';G.inferredResult=nil
  pushHistory(result);B.Result(result);notice(result)
  announceVictory(result,'')
 end
 render()
end
local function publish()
 local items={};for i,n in ipairs(participants) do
  items[table.getn(items)+1]=short(n)..(folded[n] and '(fold)' or drawn[n] and '(done)' or '')
 end
 publicText=table.concat(items,', ')
 local statePayload=session..';'..phase..';'..tostring(current)..';'..publicText
 if phase=='SHOWDOWN' and G.finalWire then statePayload=statePayload..';FINAL='..G.finalWire end
 send('STATE',statePayload)
 send('BANK',session..';'..roundState())
 render()
end
local function syncTo(n)
 if not isLeader() or not inRaid(n) or session=='' or (phase~='DRAW' and not bettingPhase()) then debugLog('SYNC BLOCKED '..tostring(n)..' leader='..tostring(isLeader())..' inRaid='..tostring(inRaid(n))..' phase='..phase);return end
 debugLog('SYNC TO '..tostring(n)..' hand='..tostring(hands[n]~=nil))
 send('START',session..';'..joinNames(),'WHISPER',n)
 local h=hands[n]
 if h then send('HAND',session..';'..table.concat(h,','),'WHISPER',n) end
 local items={}
 for _,name in ipairs(participants) do
  items[table.getn(items)+1]=short(name)..(folded[name] and '(fold)' or drawn[name] and '(done)' or '')
 end
 send('STATE',session..';'..phase..';'..tostring(current)..';'..table.concat(items,', '),'WHISPER',n)
 send('BANK',session..';'..roundState(),'WHISPER',n)
end
local function requestSync()
 if isLeader() then notice('Raid Leader: use Start Hand to deal to all raid members.');return end
 if transportUnavailable then notice('RAID addon transport unavailable. Run /orp nettest.');return end
 local host=leader()
 if not host then notice('Join a raid with a Raid Leader first.');debugLog('NO LEADER');return end
 debugLog('SYNC REQUEST leader='..tostring(host))
 send('HELLO','REQUEST','WHISPER',host)
 syncRequestedAt=GetTime()
 notice('Requesting cards from Raid Leader...')
end
function G.RequestRecovery() requestSync() end
function G.GetBetInfo() return pot,streetBet,balanceOf(me()),math.max(0,streetBet-(roundPaid[me()] or 0)) end
function G.GetRecoveryInfo() return session,phase,leader(),isLeader(),table.getn(myCards) end
local function privateHand(n)
 local h=hands[n];if not h then return end
 if same(n,me()) then
  local first=not receivedHands[session]
  myCards={unpack(h)};chosen={};receivedHands[session]=true
  if first then dealSound() else soundPlay('exchange') end
 else send('HAND',session..';'..table.concat(h,','),'WHISPER',n) end
end
local function showdown()
 phase='SHOWDOWN'
 local best,winners=nil,{}
 local descriptions={}
 for _,n in ipairs(participants) do
  if not folded[n] and hands[n] then
   local score,desc=evaluate(hands[n])
   descriptions[table.getn(descriptions)+1]=short(n)..': '..desc..' ['..table.concat(hands[n],',')..']'
   local cmp=compare(score,best)
   if cmp>0 then best=score;winners={n} elseif cmp==0 then winners[table.getn(winners)+1]=n end
  end
 end
 local paid,winnerSet=G.Payout(participants,folded,hands,contrib,evaluate,compare)
 local result='Winner: '..(table.getn(winners)>0 and table.concat(winners,', ') or 'none')
 local stillIn=0
 for _,n in ipairs(participants) do if not folded[n] then stillIn=stillIn+1 end end
 local wonByFold=stillIn<=1
 local payouts={}
 for _,n in ipairs(participants) do
  local won=paid[n] or 0
  balances[short(n)]=balanceOf(n)+won
  if won>0 then payouts[table.getn(payouts)+1]=short(n)..' +'..G.Display(won) end
  local st=G.Stat(n)
  st.played=st.played+1;st.net=st.net+won-(contrib[n] or 0)
  if winnerSet[n] or (pot==0 and not folded[n] and hands[n] and compare(evaluate(hands[n]),best)==0) then
   st.wins=st.wins+1
  else st.losses=st.losses+1 end
 end
 G.Save()
 OctoPokerDB=OctoPokerDB or {};OctoPokerDB.balances=balances
 local total=pot;pot=0;streetBet=0
  result=result..' | Pot: '..G.Display(total)
  if wonByFold then result=result..' | By Fold' end
  if table.getn(payouts)>0 then result=result..' | '..table.concat(payouts,', ') end
  -- A bounded summary is always delivered even when full payout text is long.
  local wireResult='Winner: '..(table.getn(winners)>0 and table.concat(winners,', ') or 'none')..' | Pot: '..G.Display(total)
  if wonByFold then wireResult=wireResult..' | By Fold' end
  G.winnerCombos={}
  if not wonByFold then
   for _,n in ipairs(winners) do
    if hands[n] then
     local _,desc=evaluate(hands[n])
     G.winnerCombos[short(n)]=desc
    end
   end
  end
  G.finalWire=wireResult
  send('RESULT',session..';'..wireResult..';')
  for _,n in ipairs(winners) do
   if G.winnerCombos[short(n)] then send('WINCOMBO',session..';'..short(n)..';'..G.winnerCombos[short(n)]) end
  end
  -- Detailed hand history remains local to the dealer, unchanged.
 send('STATS',G.SerializeStats())
 pushHistory(result..' | '..table.concat(descriptions,' / '))
  B.Result(result)
  notice(result);announceVictory(result,table.concat(descriptions,' / '));publish()
  -- Redundant compact result after the final STATE for older clients / missed messages.
  send('RESULT',session..';'..wireResult..';')
   send('WINEND',session..';'..wireResult)
   G.finalResends=3;G.finalNextSend=GetTime()+2
end
local beginSecondBetting
local function nextTurn()
 local active=0
 for _,n in ipairs(participants) do if not folded[n] then active=active+1 end end
 if active<=1 then showdown();return end
 current=current+1
 while current<=table.getn(participants) and folded[nameAt(current)] do current=current+1 end
 if current>table.getn(participants) then beginSecondBetting() else publish() end
end
local function firstActive()
 for i,n in ipairs(participants) do if not folded[n] then return i end end
 return 1
end
local function advanceBetting()
 if aliveCount()<=1 then showdown();return end
 local count=table.getn(participants)
 for offset=1,count do
  local i=math.mod(current - 1 + offset, count) + 1;local n=nameAt(i)
  if not folded[n] and not G.allin[n] and (not acted[n] or (roundPaid[n] or 0)<streetBet) then current=i;publish();return end
 end
 if phase=='BET1' then
  phase='DRAW';current=firstActive();publish();notice('Betting complete. Draw cards.')
 else showdown() end
end
-- Raid Leader Controls 2.0: use public methods to keep the UI in a separate Lua chunk.
function G.LeaderControlInfo()
 local names={}
 for _,n in ipairs(participants) do names[table.getn(names)+1]=short(n) end
 return phase,session,table.concat(names,','),pot,G.finalWire or '',G.winnerCombos or {}
end
function G.LeaderControlBalances()
 local lines={}
 for _,n in ipairs(participants) do
  lines[table.getn(lines)+1]=short(n)..' '..G.Display(balanceOf(n))
 end
 return lines
end
function G.LeaderControlAnnounce(text,channel)
 if not isLeader() then notice('Raid Leader only.');return end
 if channel~='RAID' and channel~='SAY' then return end
 if not text or text=='' then return end
 -- WoW chat parses the pipe as a formatting escape. Result packets contain
 -- literal ' | ' delimiters; never send those raw to RAID or SAY.
 local clean=string.gsub(tostring(text),'|',' - ')
 clean=string.gsub(clean,'[\r\n]',' ')
 if SendChatMessage then SendChatMessage(string.sub('[Raid Poker] '..clean,1,240),channel) end
end
function G.LeaderControlResend()
 if not isLeader() then return false,'Raid Leader only.' end
 if not G.finalWire or phase~='SHOWDOWN' then return false,'No completed hand to resend.' end
 send('WINEND',session..';'..G.finalWire)
 send('RESULT',session..';'..G.finalWire..';')
 for n,desc in pairs(G.winnerCombos or {}) do send('WINCOMBO',session..';'..n..';'..desc) end
 return true,'Last WINNER result sent to raid.'
end
function G.LeaderControlEndBetting()
 if not isLeader() then return false,'Raid Leader only.' end
 if not bettingPhase() then return false,'Not in a betting round.' end
 -- Never skip a live player's required call; use Force Showdown for exceptional situations.
 for _,n in ipairs(participants) do
  if not folded[n] and not G.allin[n] then
   if not acted[n] or (roundPaid[n] or 0)<streetBet then
    return false,'Pending action or call: '..short(n)
   end
  end
 end
 advanceBetting()
 return true,'Betting stage advanced.'
end
function G.LeaderControlForceShowdown()
 if not isLeader() then return false,'Raid Leader only.' end
 if phase~='DRAW' and not bettingPhase() then return false,'No active hand.' end
 showdown()
 return true,'Showdown calculated using the current hands.'
end
function G.LeaderControlCancel()
 if not isLeader() then return false,'Raid Leader only.' end
 if phase~='DRAW' and not bettingPhase() then return false,'No active hand to cancel.' end
 for _,n in ipairs(participants) do
  balances[short(n)]=balanceOf(n)+(contrib[n] or 0)
 end
 OctoPokerDB=OctoPokerDB or {};OctoPokerDB.balances=balances
 pot=0;streetBet=0;phase='ABORTED';G.finalWire=nil;G.finalResends=0
 send('ABORT',session)
 OctoPokerBank.Broadcast()
 notice('Hand cancelled. All contributed Silver refunded.')
 publish()
 return true,'Hand cancelled and contributed Silver refunded.'
end
-- Manual winner is a separate, explicit single-winner settlement. Side pots / all-ins
-- are blocked: they require the automatic evaluator to preserve eligibility.
function G.LeaderControlManualWinner(name)
 if not isLeader() then return false,'Raid Leader only.' end
 if phase~='DRAW' and not bettingPhase() then return false,'No active hand.' end
 local winner=nil
 for _,n in ipairs(participants) do if same(n,name) and not folded[n] then winner=n end end
 if not winner then return false,'Select an active (not folded) player.' end
 for _,n in ipairs(participants) do if G.allin[n] then return false,'All-in hand: use automatic showdown.' end end
 local total=pot
 balances[short(winner)]=balanceOf(winner)+total
 OctoPokerDB=OctoPokerDB or {};OctoPokerDB.balances=balances
 local result='Winner: '..short(winner)..' | Pot: '..G.Display(total)..' | Manual Decision'
 G.finalWire=result;G.winnerCombos={}
 phase='SHOWDOWN';pot=0;streetBet=0
 pushHistory(result);B.Result(result);notice(result);announceVictory(result,'')
 send('WINEND',session..';'..result)
 send('RESULT',session..';'..result..';')
 G.finalResends=3;G.finalNextSend=GetTime()+2
 OctoPokerBank.Broadcast()
 publish()
 return true,'Manual winner settled: '..short(winner)..' +'..G.Display(total)
end

local function applyBet(n,kind,payload)
 if not isLeader() or not bettingPhase() or not same(nameAt(current),n) then return end
 local actual=nameAt(current);G.beforeBetContribution=contrib[actual] or 0;local owing=math.max(0,streetBet-(roundPaid[actual] or 0))
 if kind=='FOLD' then folded[actual]=true;acted[actual]=true;debugLog('BET '..short(actual)..' FOLD')
 else
  local amount=0
  if kind=='CHECK' then if owing~=0 then notice('Cannot check: call required.');return end
  elseif kind=='CALL' then amount=math.min(owing,balanceOf(actual))
  elseif kind=='ALLIN' then amount=balanceOf(actual)
  elseif kind=='RAISE' then
   local raise=tonumber(payload)
   if not raise or raise~=math.floor(raise) or raise<=0 or raise>10000000000 then notice('Enter a positive raise.');return end
   amount=owing+raise
  else return end
  if amount>balanceOf(actual) then notice('Insufficient tracked balance.');return end
  balances[short(actual)]=balanceOf(actual)-amount;OctoPokerDB=OctoPokerDB or {};OctoPokerDB.balances=balances;roundPaid[actual]=(roundPaid[actual] or 0)+amount
  contrib[actual]=(contrib[actual] or 0)+amount;pot=pot+amount
  if balanceOf(actual)==0 and not G.allin[actual] then G.allin[actual]=true;G.Stat(actual).allins=G.Stat(actual).allins+1 end
  if kind=='RAISE' or (kind=='ALLIN' and roundPaid[actual]>streetBet) then
   streetBet=roundPaid[actual]
   for _,other in ipairs(participants) do if not same(other,actual) and not folded[other] and not G.allin[other] then acted[other]=false end end
  end
  acted[actual]=true
  debugLog('BET '..short(actual)..' '..kind..' amount='..tostring(amount)..' pot='..tostring(pot))
 end
 local paid=kind=='FOLD' and 0 or (kind=='CHECK' and 0 or ((contrib[actual] or 0)-(G.beforeBetContribution or 0)))
 B.Event(actual,kind,paid,pot)
 send('BETEVENT',session..';'..short(actual)..';'..kind..';'..tostring(paid)..';'..tostring(pot))
 send('ACTION',session..';'..short(actual)..';'..kind..';'..tostring(payload or ''))
 advanceBetting()
end
beginSecondBetting=function()
 phase='BET2';streetBet=0;roundPaid={};acted={};current=firstActive()
 local canAct=false
 for i,n in ipairs(participants) do
  if not folded[n] and not G.allin[n] then current=i;canAct=true;break end
 end
 if canAct then publish();notice('Second betting round: check, call, raise or fold.')
 else showdown() end
end
function G.PrepareHand()
 if not isLeader() then notice('Only the Raid Leader can start a hand.');return end
 if phase=='DRAW' or bettingPhase() then notice('Finish the current hand first.');return end
 participants={};hands={};folded={};drawn={};chosen={};myCards={};publicText='';handAcknowledged={};pot=0;streetBet=0;roundPaid={};contrib={};acted={};G.allin={}
 -- Report missing Silver balances before the generic participant-count error.
 local unfunded={}
 for i=1,raidCount() do
  local n=GetRaidRosterInfo(i)
  if n and G.joined[short(n)] and OctoPokerBank.IsEnabled(n) and (balanceOf(n)<=0 or balanceOf(n)<G.ante) then
   unfunded[table.getn(unfunded)+1]=short(n)
  end
 end
 if table.getn(unfunded)>0 then
  StaticPopup_Show('OCTOPOKER_NO_BALANCE',table.concat(unfunded,', '))
  notice('Insufficient Silver balance. Open Player Balances to fund or disable players.')
  return
 end
 -- A participant must afford the full ante; no partial ante is collected.
 for i=1,raidCount() do
  local n=GetRaidRosterInfo(i)
  if n and G.joined[short(n)] and OctoPokerBank.IsEnabled(n) and balanceOf(n)>=G.ante and balanceOf(n)>0 then
   participants[table.getn(participants)+1]=n
  end
 end
 if table.getn(participants)<2 or table.getn(participants)>10 then notice('Need 2 to 10 joined players who can afford the Ante ('..G.Display(G.ante)..').');return end
 local dealerIndex=G.NextDealer(participants)
 local order={}
 for j=1,table.getn(participants) do
  order[j]=participants[math.mod(dealerIndex+j-1,table.getn(participants))+1]
 end
 participants=order
 -- Collect the ante from every participant, dealer included, before dealing.
 -- Ante is a contribution to the pot, not a first-round call requirement.
 for _,n in ipairs(participants) do
  if G.ante>0 then
   balances[short(n)]=balanceOf(n)-G.ante
   contrib[n]=G.ante
   pot=pot+G.ante
   if balanceOf(n)==0 then
    G.allin[n]=true
    G.Stat(n).allins=G.Stat(n).allins+1
   end
  end
 end
 OctoPokerDB=OctoPokerDB or {};OctoPokerDB.balances=balances
 return true
end
function G.FinishHand()
 -- Seed once using server time and high-resolution uptime; not cryptographically secure.
 math.randomseed((time and time() or 1)+(GetTime and math.floor(GetTime()*1000) or 0));math.random();math.random();math.random()
 shuffle();G.finalWire=nil;session=tostring(time and time() or 0)..'-'..tostring(math.random(100000,999999))
 for _,n in ipairs(participants) do
  local h={};for j=1,5 do h[j]=drawCard() end;hands[n]=h
 end
 phase='BET1';current=1
 local canBet=false
 for i,n in ipairs(participants) do
  if not G.allin[n] then current=i;canBet=true;break end
 end
 if not canBet then phase='DRAW';current=firstActive() end
 B.entries={};B.Event('TABLE','ANTE',G.ante,pot)
 send('BETEVENT',session..';TABLE;ANTE;'..tostring(G.ante)..';'..tostring(pot))
 send('DEALER',G.dealer);send('ANTE',tostring(G.ante))
 for _,n in ipairs(participants) do
  if same(n,me()) then privateHand(n) else syncTo(n) end
 end
 publish();OctoPokerBank.Broadcast();notice('Hand started. Ante: '..G.Display(G.ante)..' per player. Starting pot: '..G.Display(G.ante*table.getn(participants))..'. RAID transport is not private.')
end
-- Administrative helpers shared with optional Player Management module.
function G.AdminState() return phase,session,current,participants,nameAt(current),pot end
function G.AdminTimeout()
 if not isLeader() or not bettingPhase() then return end
 local n=nameAt(current)
 if n and not G.allin[n] then
  if streetBet-(roundPaid[n] or 0)<=0 then applyBet(n,'CHECK','0')
  else applyBet(n,'FOLD','0') end
 end
end
function G.AdminKick(n)
 if not isLeader() then return false end
 if phase=='DRAW' or bettingPhase() then notice('Kick is available between hands only.');return false end
 n=short(n)
 if not G.joined[n] then return false end
 G.joined[n]=nil
 send('LOBBY',table.concat(G.JoinedNames(),','))
 render()
 return true
end
function G.AdminSend(kind,data) send(kind,data) end
function G.AdminLeader() return isLeader() end
function G.AdminBalance(n) return balanceOf(n) end
local function dealHand()
 if G.PrepareHand() then G.FinishHand() end
end

-- Raid Leader starts a hand immediately; Ante is collected before cards are dealt.
local function startHand()
 dealHand()
end
local function applyAction(n,kind,payload)
 if not isLeader() or phase~='DRAW' or not same(nameAt(current),n) then return end
 local actual=nameAt(current)
 local indices={}
 if kind=='FOLD' then folded[actual]=true;drawn[actual]=true
 elseif kind=='EXCHANGE' then
  local seen={}
  if payload~='' then
   for value in string.gfind(payload,'[^,]+') do
    local k=tonumber(value)
    if not k or k<1 or k>5 or k~=math.floor(k) or seen[k] then return end
    seen[k]=true;indices[table.getn(indices)+1]=k
   end
  end
  if table.getn(indices)>table.getn(deck) then notice('Not enough cards remain in deck.');return end
  for _,k in ipairs(indices) do hands[actual][k]=drawCard() end
  drawn[actual]=true;privateHand(actual)
 else return end
 send('ACTION',session..';'..short(actual)..';'..kind..';'..tostring(indices and table.getn(indices) or 0))
 nextTurn()
end
local function act(kind,payload)
 if bettingPhase() then
  if not same(nameAt(current),me()) then notice('It is not your turn.');return end
  if kind=='RAISE' then
   local silver=G.Entry(payload)
   if not silver or silver<=0 then notice('Enter a valid Silver raise.');return end
   payload=tostring(silver)
  end
  if isLeader() then applyBet(me(),kind,payload or '') else send('MOVE',session..';'..kind..';'..(payload or ''),'WHISPER',leader()) end
  return
 end
 if phase~='DRAW' then notice('No active draw phase.');return end
 if not same(nameAt(current),me()) then notice('It is not your turn.');return end
 if isLeader() then applyAction(me(),kind,payload or '')
 else send('MOVE',session..';'..kind..';'..(payload or ''),'WHISPER',leader()) end
end
for i=1,5 do
 local idx=i
 cardsButtons[i]=CreateFrame('Button',nil,frame)
 cardsButtons[i]:SetWidth(91)
 cardsButtons[i]:SetHeight(112)
 cardsButtons[i]:SetPoint('TOPLEFT',frame,'TOPLEFT',18+(i-1)*102,-198)
 cardsButtons[i]:SetScript('OnClick',function()
  if phase~='DRAW' or table.getn(myCards)~=5 then return end
  chosen[idx]=not chosen[idx];render()
 end)
 cardsButtons[i]:SetHeight(112)
 cardsButtons[i].art=cardsButtons[i]:CreateTexture(nil,'ARTWORK')
 cardsButtons[i].art:SetAllPoints(cardsButtons[i])
 cardsButtons[i]:RegisterForClicks('LeftButtonUp')
 cardsButtons[i].tag=cardsButtons[i]:CreateFontString(nil,'OVERLAY','GameFontNormalSmall')
 cardsButtons[i].tag:SetPoint('BOTTOM',cardsButtons[i],'BOTTOM',0,3)
end
local raiseInput=CreateFrame('EditBox','OctoPokerRaiseAmount',frame,'InputBoxTemplate')
raiseInput:SetWidth(52);raiseInput:SetHeight(24);raiseInput:SetPoint('TOPLEFT',frame,'TOPLEFT',25,-380)
raiseInput:SetAutoFocus(false);raiseInput:SetNumeric(true);raiseInput:SetText('');G.raiseInput=raiseInput
raiseInput:SetScript('OnTextChanged',function()
 OctoPokerDB=OctoPokerDB or {}
 OctoPokerDB.lastRaise=this:GetText()
end)
local raiseLabel=label('GameFontHighlightSmall',84,-386);raiseLabel:SetText('Raise');G.raiseLabel=raiseLabel
actionButtons.bet={}
-- Classic-inspired poker action buttons. Pure WoW textures, no extra dependencies.
local function styleBetButton(b,r,g,bl)
 b:SetHeight(33)
 -- Remove the modern gray panel button texture in favor of an inset dark metal face.
 local normal=b:GetNormalTexture()
 if normal then normal:SetTexture('Interface\\Buttons\\WHITE8X8');normal:SetVertexColor(0.13,0.12,0.10,1) end
 local pushed=b:GetPushedTexture()
 if pushed then pushed:SetTexture('Interface\\Buttons\\WHITE8X8');pushed:SetVertexColor(r*0.32,g*0.32,bl*0.32,1) end
 local disabled=b:GetDisabledTexture()
 if disabled then disabled:SetTexture('Interface\\Buttons\\WHITE8X8');disabled:SetVertexColor(0.09,0.09,0.09,0.8) end
 local highlight=b:GetHighlightTexture()
 if highlight then highlight:SetTexture('Interface\\Buttons\\WHITE8X8');highlight:SetVertexColor(r,g,bl,0.22);highlight:SetBlendMode('ADD') end
 b:SetBackdrop({bgFile='Interface\\Tooltips\\UI-Tooltip-Background',edgeFile='Interface\\Tooltips\\UI-Tooltip-Border',tile=true,tileSize=16,edgeSize=13,insets={left=4,right=4,top=4,bottom=4}})
 b:SetBackdropColor(0.10,0.09,0.08,0.98)
 b:SetBackdropBorderColor(0.68,0.53,0.27,1)
 -- The action icon replaces the old colored stripe.
 local label=b:GetFontString()
 if label then
  label:SetFontObject('GameFontNormal')
  label:SetTextColor(1,0.88,0.60)
  label:ClearAllPoints();label:SetPoint('CENTER',b,'CENTER',3,0)
 end
 b:SetScript('OnEnter',function()
  this:SetBackdropBorderColor(r,g,bl,1)
 end)
 b:SetScript('OnLeave',function()
  this:SetBackdropBorderColor(0.68,0.53,0.27,1)
 end)
end
actionButtons.bet[1]=button('Check',24,-389,82,function()act('CHECK','')end)
actionButtons.bet[2]=button('Call',112,-389,82,function()act('CALL','')end)
actionButtons.bet[3]=button('Raise',200,-389,82,function()act('RAISE',raiseInput:GetText())end)
actionButtons.bet[4]=button('Fold Bet',288,-389,100,function()act('FOLD','')end)
actionButtons.bet[5]=button('All-In',400,-389,94,function()act('ALLIN','')end)
styleBetButton(actionButtons.bet[1],0.29,0.73,0.93) -- Check / blue
styleBetButton(actionButtons.bet[2],0.28,0.82,0.38) -- Call / green
styleBetButton(actionButtons.bet[3],0.98,0.72,0.20) -- Raise / gold
styleBetButton(actionButtons.bet[4],0.84,0.33,0.31) -- Fold / red
styleBetButton(actionButtons.bet[5],0.90,0.32,0.16) -- All-In / fiery red

-- Explicit opt-in lobby: only registered raid members receive a hand.
G.joined=G.joined or {}
G.joinButton=CreateFrame('Button',nil,frame)
G.joinButton:SetWidth(148);G.joinButton:SetHeight(25)
G.joinButton:SetPoint('TOPLEFT',frame,'TOPLEFT',343,-77)
G.joinButton:SetScript('OnClick',function()
 if raidCount()<1 then notice('Join a raid before joining the poker table.');return end
 if not OctoPokerBank.IsEnabled(me()) then notice('Raid Leader disabled your participation. Ask the leader to enable you in Player Balances.');return end
 if phase=='DRAW' or bettingPhase() then notice('Wait for the next hand to join.');return end
 if G.joined[short(me())] then
  G.joined[short(me())]=nil
  if isLeader() then send('LOBBY',table.concat(G.JoinedNames(),',')) else send('LEAVE','TABLE','WHISPER',leader()) end
  notice('You left the poker table.')
 else
  G.joined[short(me())]=true
  if isLeader() then send('LOBBY',table.concat(G.JoinedNames(),',')) else send('JOIN','TABLE','WHISPER',leader()) end
  notice('Joined poker table. Waiting for Raid Leader.')
 end
 render()
end)
local joinText=G.joinButton:CreateFontString(nil,'OVERLAY','GameFontNormal')
joinText:SetPoint('CENTER',G.joinButton,'CENTER',0,0)
G.joinButton:SetFontString(joinText)
G.joinButton:SetHighlightTexture('Interface\\Buttons\\ButtonHilight-Square','ADD')
G.joinButton:SetBackdrop({bgFile='Interface\\Buttons\\WHITE8X8',edgeFile='Interface\\Tooltips\\UI-Tooltip-Border',tile=false,edgeSize=12,insets={left=2,right=2,top=2,bottom=2}})
G.joinButton:SetBackdropColor(0.08,0.40,0.12,0.95)
G.joinButton:SetBackdropBorderColor(0.95,0.8,0.28,1)
function G.RefreshJoinButton()
 if not G.joinButton then return end
 local joined=G.joined and G.joined[short(me())]
 G.joinButton:SetText((not OctoPokerBank.IsEnabled(me())) and 'TABLE DISABLED' or (joined and 'LEAVE TABLE' or 'JOIN TABLE'))
 if not OctoPokerBank.IsEnabled(me()) then
  G.joinButton:SetBackdropColor(0.25,0.25,0.25,0.95)
  G.joinButton:SetBackdropBorderColor(0.55,0.55,0.55,1)
 elseif joined then
  G.joinButton:SetBackdropColor(0.55,0.12,0.10,0.95)
  G.joinButton:SetBackdropBorderColor(1,0.42,0.27,1)
 else
  G.joinButton:SetBackdropColor(0.08,0.40,0.12,0.95)
  G.joinButton:SetBackdropBorderColor(0.95,0.8,0.28,1)
 end
end
G.RefreshJoinButton()

actionButtons.start=button('Start Hand',24,-320,115,startHand)
actionButtons[1]=button('Exchange',148,-320,115,function()
 local values={};for i=1,5 do if chosen[i] then values[table.getn(values)+1]=i end end
 act('EXCHANGE',table.concat(values,','))
end)
actionButtons[2]=button('Stand Pat',272,-320,105,function()act('EXCHANGE','')end)
actionButtons[3]=button('Fold',386,-320,105,function()act('FOLD','')end)
local rankingsFrame, rulesFrame
do
-- Poker hand rankings reference (strongest to weakest).
rankingsFrame=CreateFrame('Frame','OctoPokerRankingsFrame',UIParent)
rankingsFrame:SetWidth(470);rankingsFrame:SetHeight(445)
rankingsFrame:SetPoint('CENTER',UIParent,'CENTER',65,20)
rankingsFrame:SetMovable(true);rankingsFrame:EnableMouse(true)
rankingsFrame:RegisterForDrag('LeftButton')
rankingsFrame:SetScript('OnDragStart',function() this:StartMoving() end)
rankingsFrame:SetScript('OnDragStop',function() this:StopMovingOrSizing() end)
rankingsFrame:SetBackdrop({bgFile='Interface\\DialogFrame\\UI-DialogBox-Background',edgeFile='Interface\\DialogFrame\\UI-DialogBox-Border',tile=true,tileSize=32,edgeSize=32,insets={left=8,right=8,top=8,bottom=8}})
rankingsFrame:SetFrameStrata('DIALOG')
local rankingsTitle=rankingsFrame:CreateFontString(nil,'OVERLAY','GameFontNormalLarge')
rankingsTitle:SetPoint('TOPLEFT',rankingsFrame,'TOPLEFT',24,-25)
rankingsTitle:SetText('Poker Hand Rankings')
local rankingsSubtitle=rankingsFrame:CreateFontString(nil,'OVERLAY','GameFontHighlightSmall')
rankingsSubtitle:SetPoint('TOPLEFT',rankingsFrame,'TOPLEFT',24,-51)
rankingsSubtitle:SetText('Strongest to weakest  |  Five Card Draw')
local rankingsNames={
 '1. Royal Flush',
 '2. Straight Flush',
 '3. Four of a Kind',
 '4. Full House',
 '5. Flush',
 '6. Straight',
 '7. Three of a Kind',
 '8. Two Pair',
 '9. One Pair',
 '10. High Card'
}
local rankingsExamples={
 'A K Q J 10, all the same suit',
 'Five consecutive cards of one suit',
 'Four cards of the same rank',
 'Three of one rank and two of another',
 'Five cards of the same suit',
 'Five consecutive ranks (A can be low)',
 'Three cards of the same rank',
 'Two different pairs',
 'Two cards of the same rank',
 'No other combination'
}
for i=1,10 do
 local y=-80-(i-1)*33
 local rank=rankingsFrame:CreateFontString(nil,'OVERLAY','GameFontNormal')
 rank:SetPoint('TOPLEFT',rankingsFrame,'TOPLEFT',24,y)
 rank:SetText(rankingsNames[i])
 local detail=rankingsFrame:CreateFontString(nil,'OVERLAY','GameFontHighlightSmall')
 detail:SetPoint('TOPLEFT',rankingsFrame,'TOPLEFT',200,y-1)
 detail:SetWidth(245);detail:SetJustifyH('LEFT')
 detail:SetText(rankingsExamples[i])
end
local rankingsClose=CreateFrame('Button',nil,rankingsFrame,'UIPanelCloseButton')
rankingsClose:SetPoint('TOPRIGHT',rankingsFrame,'TOPRIGHT',-5,-5)
rankingsFrame:Hide()
-- In-addon rules for the implemented No Limit Five Card Draw flow.
rulesFrame=CreateFrame('Frame','OctoPokerRulesFrame',UIParent)
rulesFrame:SetWidth(515);rulesFrame:SetHeight(535)
rulesFrame:SetPoint('CENTER',UIParent,'CENTER',85,15)
rulesFrame:SetMovable(true);rulesFrame:EnableMouse(true)
rulesFrame:RegisterForDrag('LeftButton')
rulesFrame:SetScript('OnDragStart',function()this:StartMoving()end)
rulesFrame:SetScript('OnDragStop',function()this:StopMovingOrSizing()end)
rulesFrame:SetBackdrop({bgFile='Interface\\DialogFrame\\UI-DialogBox-Background',edgeFile='Interface\\DialogFrame\\UI-DialogBox-Border',tile=true,tileSize=32,edgeSize=32,insets={left=8,right=8,top=8,bottom=8}})
rulesFrame:SetFrameStrata('DIALOG')
local rulesTitle=rulesFrame:CreateFontString(nil,'OVERLAY','GameFontNormalLarge')
rulesTitle:SetPoint('TOPLEFT',rulesFrame,'TOPLEFT',24,-25)
rulesTitle:SetText('Five Card Draw - Game Rules')
local rulesBody=rulesFrame:CreateFontString(nil,'OVERLAY','GameFontHighlight')
rulesBody:SetPoint('TOPLEFT',rulesFrame,'TOPLEFT',26,-66)
rulesBody:SetWidth(460);rulesBody:SetHeight(430)
rulesBody:SetJustifyH('LEFT');rulesBody:SetJustifyV('TOP')
rulesBody:SetText(
 '1. JOIN: Players must be in the same raid. The Raid Leader hosts and starts each hand. Players with 0 tracked Silver cannot join a new hand.\n\n'..
 '2. DEAL: Each active player receives five private cards from a standard 52-card deck.\n\n'..
 '3. FIRST BETTING ROUND: Check, Call, Raise or Fold. All betting amounts are in Silver (s).\n\n'..
 '4. DRAW: In turn, select cards to replace and press Exchange, or press Stand Pat to keep all five. You may replace 0 to 5 cards.\n\n'..
 '5. SECOND BETTING ROUND: Another round of Check, Call, Raise or Fold follows the draw.\n\n'..
 '6. SHOWDOWN: Remaining players compare their best five-card hands. Highest ranking hand wins the pot. Equal hands split it.\n\n'..
 '7. SILVER: All bets and winnings use virtual tracked Silver only. No real gold is transferred. All-In and Side Pots are supported.\n\n'..
 '8. NEXT HAND: The Raid Leader starts the next hand. Hand history and player balances are available in the main window.'
)
local rulesClose=CreateFrame('Button',nil,rulesFrame,'UIPanelCloseButton')
rulesClose:SetPoint('TOPRIGHT',rulesFrame,'TOPRIGHT',-5,-5)
rulesFrame:Hide()
button('History',24,-537,113,function() updateHistory();if historyFrame:IsShown() then historyFrame:Hide() else historyFrame:Show() end end)
G.SyncCards=requestSync
 G.RankingsFrame=rankingsFrame
 button('Sync Cards',270,-537,113,function()requestSync()end):Hide()
button('Hand Rankings',393,-537,113,function() if rankingsFrame:IsShown() then rankingsFrame:Hide() else rankingsFrame:Show() end end):Hide()

end -- rankings/rules UI construction scope

do -- quick-emote UI construction scope
-- Five quick emotes. Use the client's native emote API for local animations/sounds.
local emoteButtons={
 {label='Laugh',token='LAUGH',icon='Interface\\Icons\\Ability_Rogue_Disguise'},
 {label='Cry',token='CRY',icon='Interface\\Icons\\Spell_Shadow_MindSteal'},
 {label='Chicken',token='CHICKEN',icon='Interface\\Icons\\INV_Misc_Food_59'},
 {label='Train',token='TRAIN',icon='Interface\\Icons\\INV_Misc_EngGizmos_03'},
 {label='Roar',token='ROAR',icon='Interface\\Icons\\Ability_Druid_ChallangingRoar'}
}
local function makeEmoteButton(info,index)
 local x=17+(index-1)*100
 local b=CreateFrame('Button',nil,frame,'UIPanelButtonTemplate')
 b:SetWidth(98);b:SetHeight(43)
 b:SetPoint('TOPLEFT',frame,'TOPLEFT',x,-659)
 local icon=b:CreateTexture(nil,'ARTWORK')
 icon:SetWidth(23);icon:SetHeight(23)
 icon:SetPoint('LEFT',b,'LEFT',7,0)
 icon:SetTexture(info.icon)
 local caption=b:CreateFontString(nil,'OVERLAY','GameFontNormalSmall')
 caption:SetPoint('LEFT',icon,'RIGHT',3,0)
 caption:SetText(info.label)
 b:SetScript('OnClick',function() DoEmote(info.token) end)
 b:SetScript('OnEnter',function()
  GameTooltip:SetOwner(this,'ANCHOR_RIGHT')
  GameTooltip:SetText('/'..string.lower(info.token))
  GameTooltip:Show()
 end)
 b:SetScript('OnLeave',function() GameTooltip:Hide() end)
 return b
end
for i=1,table.getn(emoteButtons) do makeEmoteButton(emoteButtons[i],i) end
end -- quick-emote UI construction scope


 -- Single integrated card image. No legacy TCG/Dark outer frame or theme overlays.
 OctoPokerCardTheme = OctoPokerCardTheme or {}
 function OctoPokerCardTheme.Path(card)
  return 'Interface\\AddOns\\OctoWoW_Raid_Poker\\Cards\\Classic\\'..card
 end
 function OctoPokerCardTheme.Set(style)
  OctoPokerCardTheme.style='Classic'
  if OctoPokerDB then OctoPokerDB.cardTheme='Classic' end
  if render then render() end
 end
-- Unified settings panel. Existing sound controls are now inside this panel.
local settingsFrame=CreateFrame('Frame','OctoPokerSettingsFrame',UIParent)
settingsFrame:SetWidth(430);settingsFrame:SetHeight(930)
settingsFrame:SetPoint('CENTER',UIParent,'CENTER',85,15)
settingsFrame:SetMovable(true);settingsFrame:EnableMouse(true)
settingsFrame:RegisterForDrag('LeftButton')
settingsFrame:SetScript('OnDragStart',function()this:StartMoving()end)
settingsFrame:SetScript('OnDragStop',function()this:StopMovingOrSizing()end)
settingsFrame:SetFrameStrata('DIALOG')
settingsFrame:SetBackdrop({bgFile='Interface\\DialogFrame\\UI-DialogBox-Background',edgeFile='Interface\\DialogFrame\\UI-DialogBox-Border',tile=true,tileSize=32,edgeSize=32,insets={left=8,right=8,top=8,bottom=8}})
local settingsTitle=settingsFrame:CreateFontString(nil,'OVERLAY','GameFontNormalLarge')
settingsTitle:SetPoint('TOPLEFT',settingsFrame,'TOPLEFT',24,-23)
settingsTitle:SetText('Poker Settings')
local settingsClose=CreateFrame('Button',nil,settingsFrame,'UIPanelCloseButton')
settingsClose:SetPoint('TOPRIGHT',settingsFrame,'TOPRIGHT',-5,-5)
soundWindow:SetParent(settingsFrame)
soundWindow:ClearAllPoints();soundWindow:SetPoint('TOPLEFT',settingsFrame,'TOPLEFT',26,-54)
soundWindow:SetFrameStrata('DIALOG')
soundClose:Hide()
soundWindow:Show()
local function settingsButton(text,y,callback)
 local b=CreateFrame('Button',nil,settingsFrame,'UIPanelButtonTemplate')
 b:SetWidth(165);b:SetHeight(26)
 b:SetPoint('TOPLEFT',settingsFrame,'TOPLEFT',28,y)
 b:SetText(text);b:SetScript('OnClick',callback)
 return b
end
-- Scale only the main poker table; settings window stays readable and stationary.
local uiScaleLabel=settingsFrame:CreateFontString(nil,'OVERLAY','GameFontNormal')
uiScaleLabel:SetPoint('TOPLEFT',settingsFrame,'TOPLEFT',30,-363)
uiScaleLabel:SetText('UI Scale')
local uiScaleValue=settingsFrame:CreateFontString(nil,'OVERLAY','GameFontHighlight')
uiScaleValue:SetPoint('TOPRIGHT',settingsFrame,'TOPRIGHT',-33,-363)
local uiScaleSlider=CreateFrame('Slider','OctoPokerUIScaleSlider',settingsFrame,'OptionsSliderTemplate')
uiScaleSlider:SetPoint('TOPLEFT',settingsFrame,'TOPLEFT',40,-394)
uiScaleSlider:SetWidth(345);uiScaleSlider:SetHeight(17)
uiScaleSlider:SetMinMaxValues(75,150);uiScaleSlider:SetValueStep(5)
getglobal(uiScaleSlider:GetName()..'Low'):SetText('75%')
getglobal(uiScaleSlider:GetName()..'High'):SetText('150%')
getglobal(uiScaleSlider:GetName()..'Text'):SetText('')
uiScaleSlider:SetScript('OnValueChanged',function()
 local value=math.floor((this:GetValue()+2.5)/5)*5
 local scale=applyUIScale(value/100)
 uiScaleValue:SetText(math.floor(scale*100+0.5)..'%')
 if OctoPokerDock then OctoPokerDock.Refresh() end
end)
uiScaleSlider:SetValue(DEFAULT_UI_SCALE*100)
-- Table surface selector and independent opacity control.
local tableLabel=settingsFrame:CreateFontString(nil,'OVERLAY','GameFontNormal')
tableLabel:SetPoint('TOPLEFT',settingsFrame,'TOPLEFT',30,-436)
tableLabel:SetText('Table Background')
local tableStyleValue=settingsFrame:CreateFontString(nil,'OVERLAY','GameFontHighlight')
tableStyleValue:SetPoint('TOPRIGHT',settingsFrame,'TOPRIGHT',-35,-436)
local tableStyles={'None','Tavern','Classic','Dwarven','Horde','Alliance','NightElf','Forsaken','Tauren','Solid Black','Solid Charcoal','Solid Green','Solid Blue','Solid Burgundy','Solid Brown','Solid Purple','Solid Beige'}
local tableStyleIndex=1
local tablePrevious=CreateFrame('Button',nil,settingsFrame,'UIPanelButtonTemplate')
tablePrevious:SetWidth(40);tablePrevious:SetHeight(24)
tablePrevious:SetPoint('TOPLEFT',settingsFrame,'TOPLEFT',38,-462);tablePrevious:SetText('<')
local tableNext=CreateFrame('Button',nil,settingsFrame,'UIPanelButtonTemplate')
tableNext:SetWidth(40);tableNext:SetHeight(24)
tableNext:SetPoint('TOPRIGHT',settingsFrame,'TOPRIGHT',-38,-462);tableNext:SetText('>')
local tableStyleHint=settingsFrame:CreateFontString(nil,'OVERLAY','GameFontHighlightSmall')
tableStyleHint:SetPoint('TOP',settingsFrame,'TOP',0,-466)
tableStyleHint:SetWidth(260);tableStyleHint:SetJustifyH('CENTER')
local function selectTableStyle(i)
 if i<1 then i=table.getn(tableStyles) elseif i>table.getn(tableStyles) then i=1 end
 tableStyleIndex=i
 local style=tableStyles[i]
 tableStyleValue:SetText(style=='None' and 'No Background' or (SOLID_TABLE_COLORS[style] and style or style..' Table'))
 tableStyleHint:SetText(style=='None' and 'No Background' or (SOLID_TABLE_COLORS[style] and style or style..' Table'))
 applyTableBackground(style,tableOpacity)
end
tablePrevious:SetScript('OnClick',function()selectTableStyle(tableStyleIndex-1)end)
tableNext:SetScript('OnClick',function()selectTableStyle(tableStyleIndex+1)end)
local tableOpacityLabel=settingsFrame:CreateFontString(nil,'OVERLAY','GameFontNormal')
tableOpacityLabel:SetPoint('TOPLEFT',settingsFrame,'TOPLEFT',30,-510)
tableOpacityLabel:SetText('Background Opacity')
local tableOpacityValue=settingsFrame:CreateFontString(nil,'OVERLAY','GameFontHighlight')
tableOpacityValue:SetPoint('TOPRIGHT',settingsFrame,'TOPRIGHT',-33,-510)
local tableOpacitySlider=CreateFrame('Slider','OctoPokerTableOpacitySlider',settingsFrame,'OptionsSliderTemplate')
tableOpacitySlider:SetPoint('TOPLEFT',settingsFrame,'TOPLEFT',40,-541)
tableOpacitySlider:SetWidth(345);tableOpacitySlider:SetHeight(17)
tableOpacitySlider:SetMinMaxValues(0,100);tableOpacitySlider:SetValueStep(5)
getglobal(tableOpacitySlider:GetName()..'Low'):SetText('0%')
getglobal(tableOpacitySlider:GetName()..'High'):SetText('100%')
getglobal(tableOpacitySlider:GetName()..'Text'):SetText('')
tableOpacitySlider:SetScript('OnValueChanged',function()
 local v=math.floor((this:GetValue()+2.5)/5)*5
 tableOpacityValue:SetText(v..'%')
 applyTableBackground(tableStyle,v/100)
end)
tableOpacitySlider:SetValue(60)
-- Font selection; applies instantly and persists via SavedVariables.
local fontThemeLabel=settingsFrame:CreateFontString(nil,'OVERLAY','GameFontNormal')
fontThemeLabel:SetPoint('TOPLEFT',settingsFrame,'TOPLEFT',30,-591)
fontThemeLabel:SetText('Interface Font')
local fontThemeValue=settingsFrame:CreateFontString(nil,'OVERLAY','GameFontHighlightSmall')
fontThemeValue:SetPoint('TOP',settingsFrame,'TOP',0,-621)
fontThemeValue:SetWidth(280);fontThemeValue:SetJustifyH('CENTER')
local fontPrev=CreateFrame('Button',nil,settingsFrame,'UIPanelButtonTemplate')
fontPrev:SetWidth(40);fontPrev:SetHeight(24)
fontPrev:SetPoint('TOPLEFT',settingsFrame,'TOPLEFT',38,-616);fontPrev:SetText('<')
local fontNext=CreateFrame('Button',nil,settingsFrame,'UIPanelButtonTemplate')
fontNext:SetWidth(40);fontNext:SetHeight(24)
fontNext:SetPoint('TOPRIGHT',settingsFrame,'TOPRIGHT',-38,-616);fontNext:SetText('>')
local function chooseFontTheme(index)
 if index<1 then index=table.getn(FONT_THEMES) end
 if index>table.getn(FONT_THEMES) then index=1 end
 applyFontTheme(index)
 fontThemeValue:SetText(FONT_THEMES[index].name)
end
fontPrev:SetScript('OnClick',function()chooseFontTheme(fontThemeIndex-1)end)
fontNext:SetScript('OnClick',function()chooseFontTheme(fontThemeIndex+1)end)
 -- Classic Poker is the only card style. Portrait, rank, suit and frame
 -- are baked into one texture; no duplicate frame is drawn by the UI.
 local cardDesignLabel=settingsFrame:CreateFontString(nil,'OVERLAY','GameFontNormal')
 cardDesignLabel:SetPoint('TOPLEFT',settingsFrame,'TOPLEFT',30,-653)
 cardDesignLabel:SetText('Card Design')
 local cardDesignValue=settingsFrame:CreateFontString(nil,'OVERLAY','GameFontHighlight')
 cardDesignValue:SetPoint('TOPLEFT',settingsFrame,'TOPLEFT',30,-681)
 cardDesignValue:SetText('Classic Poker - Single Frame')
-- Optional winner popup; saved locally and does not affect raid results.
local hideVictoryCheck=CreateFrame('CheckButton','OctoPokerHideVictoryPopup',settingsFrame,'UICheckButtonTemplate')
hideVictoryCheck:SetWidth(28);hideVictoryCheck:SetHeight(28)
hideVictoryCheck:SetPoint('TOPLEFT',settingsFrame,'TOPLEFT',26,-744)
local hideVictoryLabel=settingsFrame:CreateFontString(nil,'OVERLAY','GameFontHighlight')
hideVictoryLabel:SetPoint('LEFT',hideVictoryCheck,'RIGHT',5,0)
hideVictoryLabel:SetText('Hide Winner / Winning Hand Popup')
hideVictoryCheck:SetScript('OnClick',function()
 OctoPokerDB=OctoPokerDB or {}
 OctoPokerDB.hideVictoryPopup=(this:GetChecked() and true or false)
 if OctoPokerDB.hideVictoryPopup then victoryFrame:Hide() end
end)
settingsFrame:SetScript('OnShow',function()
 hideVictoryCheck:SetChecked(OctoPokerDB and OctoPokerDB.hideVictoryPopup or false)
end)
settingsButton('Reset UI',-714,function()chosen={};render();notice('Card selection cleared.')end)
settingsButton('Reset Window Positions',-792,function()
 OctoPokerDock.Reset()
 notice('Auxiliary window positions reset.')
end)
OctoPoker152_statsFrame=CreateFrame('Frame','OctoPokerStatisticsFrame',UIParent)
OctoPoker152_statsFrame:SetWidth(530);OctoPoker152_statsFrame:SetHeight(410)
OctoPoker152_statsFrame:SetPoint('CENTER',UIParent,'CENTER',80,0)
OctoPoker152_statsFrame:SetMovable(true);OctoPoker152_statsFrame:EnableMouse(true)
OctoPoker152_statsFrame:RegisterForDrag('LeftButton')
OctoPoker152_statsFrame:SetScript('OnDragStart',function()this:StartMoving()end)
OctoPoker152_statsFrame:SetScript('OnDragStop',function()this:StopMovingOrSizing()end)
OctoPoker152_statsFrame:SetBackdrop({bgFile='Interface\\DialogFrame\\UI-DialogBox-Background',edgeFile='Interface\\DialogFrame\\UI-DialogBox-Border',tile=true,tileSize=32,edgeSize=32,insets={left=8,right=8,top=8,bottom=8}})
OctoPoker152_statsTitle=OctoPoker152_statsFrame:CreateFontString(nil,'OVERLAY','GameFontNormalLarge')
OctoPoker152_statsTitle:SetPoint('TOPLEFT',OctoPoker152_statsFrame,'TOPLEFT',25,-26)
OctoPoker152_statsTitle:SetText('Player Statistics')
-- Structured statistics grid: separate column anchors, headers and row separators.
OctoPoker152_statColumns={
 {title='Player',x=24,width=115,align='LEFT'},
 {title='Hands',x=145,width=48,align='CENTER'},
 {title='Wins',x=197,width=43,align='CENTER'},
 {title='Losses',x=244,width=48,align='CENTER'},
 {title='Net',x=297,width=90,align='RIGHT'},
 {title='All-Ins',x=398,width=73,align='CENTER'}
}
OctoPoker152_statRows={}
OctoPoker152_statGrid=CreateFrame('Frame',nil,OctoPoker152_statsFrame)
OctoPoker152_statGrid:SetPoint('TOPLEFT',OctoPoker152_statsFrame,'TOPLEFT',0,-68)
OctoPoker152_statGrid:SetWidth(510);OctoPoker152_statGrid:SetHeight(300)
function OctoPoker152_gridLine(y,r,g,b)
 local line=OctoPoker152_statGrid:CreateTexture(nil,'BACKGROUND')
 line:SetTexture('Interface\\Buttons\\WHITE8X8')
 line:SetVertexColor(r,g,b,0.45)
 line:SetPoint('TOPLEFT',OctoPoker152_statGrid,'TOPLEFT',20,y)
 line:SetWidth(465);line:SetHeight(1)
end
G.statSort='name'
G.statDescending=false
function G.SortStats(key)
 if G.statSort==key then G.statDescending=not G.statDescending
 else G.statSort=key;G.statDescending=(key~='name') end
 G.ShowStats()
end
for i=1,6 do
 local c=OctoPoker152_statColumns[i]
 local key=({'name','played','wins','losses','net','allins'})[i]
 local heading=CreateFrame('Button',nil,OctoPoker152_statGrid)
 heading:SetPoint('TOPLEFT',OctoPoker152_statGrid,'TOPLEFT',c.x,-5)
 heading:SetWidth(c.width);heading:SetHeight(20)
 local textLabel=heading:CreateFontString(nil,'OVERLAY','GameFontNormalSmall')
 textLabel:SetAllPoints(heading)
 textLabel:SetJustifyH(c.align);textLabel:SetText(c.title)
 heading:SetScript('OnClick',function()G.SortStats(key)end)
end
OctoPoker152_gridLine(-27,0.85,0.65,0.30)
for row=1,10 do
 OctoPoker152_statRows[row]={}
 local y=-34-(row-1)*25
 if math.mod(row,2)==0 then
  local bg=OctoPoker152_statGrid:CreateTexture(nil,'BACKGROUND')
  bg:SetTexture('Interface\\Buttons\\WHITE8X8')
  bg:SetVertexColor(0.5,0.4,0.2,0.14)
  bg:SetPoint('TOPLEFT',OctoPoker152_statGrid,'TOPLEFT',20,y+2)
  bg:SetWidth(465);bg:SetHeight(24)
 end
 for col=1,6 do
  local c=OctoPoker152_statColumns[col]
  local cell=OctoPoker152_statGrid:CreateFontString(nil,'OVERLAY','GameFontHighlightSmall')
  cell:SetPoint('TOPLEFT',OctoPoker152_statGrid,'TOPLEFT',c.x,y)
  cell:SetWidth(c.width);cell:SetHeight(20)
  cell:SetJustifyH(c.align)
  OctoPoker152_statRows[row][col]=cell
 end
 OctoPoker152_gridLine(y-23,0.42,0.34,0.22)
end
OctoPoker152_statsClose=CreateFrame('Button',nil,OctoPoker152_statsFrame,'UIPanelCloseButton')
OctoPoker152_statsClose:SetPoint('TOPRIGHT',OctoPoker152_statsFrame,'TOPRIGHT',-5,-5)
OctoPoker152_statsFrame:Hide()
function G.ShowStats()
 local names={}
 for n in pairs(G.stats) do names[table.getn(names)+1]=n end
 table.sort(names,function(a,b)
  if G.statSort=='name' then
   if G.statDescending then return string.lower(a)>string.lower(b) end
   return string.lower(a)<string.lower(b)
  end
  local va=tonumber(G.stats[a][G.statSort]) or 0
  local vb=tonumber(G.stats[b][G.statSort]) or 0
  if va==vb then return string.lower(a)<string.lower(b) end
  if G.statDescending then return va>vb end
  return va<vb
 end)
 for i=1,10 do
  local n=names[i]
  local values={'','','','','',''}
  if n then
   local st=G.stats[n]
   values={n,tostring(st.played),tostring(st.wins),tostring(st.losses),G.Display(st.net),tostring(st.allins)}
  end
  for col=1,6 do OctoPoker152_statRows[i][col]:SetText(values[col]) end
 end
 OctoPoker152_statsFrame:Show()
end
button('Player Statistics',24,-663,220,function()G.ShowStats()end)
-- Configurable ante. Only the Raid Leader can change the amount.
OctoPoker152_anteLabel=frame:CreateFontString(nil,'OVERLAY','GameFontNormal')
OctoPoker152_anteLabel:SetPoint('TOPLEFT',frame,'TOPLEFT',337,-580)
OctoPoker152_anteLabel:SetText('Ante (Silver)');G.anteLabel=OctoPoker152_anteLabel
OctoPoker152_anteEdit=CreateFrame('EditBox','OctoPokerAnteEdit',frame,'InputBoxTemplate')
OctoPoker152_anteEdit:SetWidth(70);OctoPoker152_anteEdit:SetHeight(24)
OctoPoker152_anteEdit:SetPoint('TOPLEFT',frame,'TOPLEFT',431,-574)
OctoPoker152_anteEdit:SetAutoFocus(false);OctoPoker152_anteEdit:SetNumeric(true)
OctoPoker152_anteEdit:SetMaxLetters(9);OctoPoker152_anteEdit:SetText(G.Input(G.ante))
OctoPoker152_anteEdit:SetScript('OnEscapePressed',function()this:ClearFocus();this:SetText(G.Input(G.ante))end)
OctoPoker152_anteEdit:SetScript('OnEnterPressed',function()
 if not isLeader() then
  notice('Only Raid Leader can change Ante.');this:SetText(G.Input(G.ante));this:ClearFocus();return
 end
 if phase=='DRAW' or bettingPhase() then
  notice('Ante can only change between hands.');this:SetText(G.Input(G.ante));this:ClearFocus();return
 end
 local value=G.Entry(this:GetText())
 if not value or value>99999900 then
  notice('Ante must be a valid Silver amount.');this:SetText(G.Input(G.ante));this:ClearFocus();return
 end
 G.ante=value;G.Save();send('ANTE',tostring(value))
 notice('Ante set to '..G.Display(value)..' per player.');this:ClearFocus()
end)
OctoPoker152_anteEdit:SetScript('OnEditFocusLost',function()
 if not isLeader() or phase=='DRAW' or bettingPhase() then
  this:SetText(G.Input(G.ante));return
 end
 local value=G.Entry(this:GetText())
 if value and value<=99999900 and value~=G.ante then
  G.ante=value;G.Save();send('ANTE',tostring(value))
 end
 this:SetText(G.Input(G.ante))
end)
G.OctoPoker152_anteEdit=OctoPoker152_anteEdit
G.rotateButton=button('Dealer Rotation: ON',22,-663,235,function()
 if not isLeader() then notice('Raid Leader controls dealer rotation.');return end
 G.rotation=not G.rotation;G.Save()
 G.rotateButton:SetText(G.rotation and 'Dealer Rotation: ON' or 'Dealer Rotation: OFF')
end)
G.rotateButton:Hide()
local rotationSetting=CreateFrame('CheckButton',nil,settingsFrame,'UICheckButtonTemplate')
rotationSetting:SetWidth(27);rotationSetting:SetHeight(27)
rotationSetting:SetPoint('TOPLEFT',settingsFrame,'TOPLEFT',26,-824)
local rotationSettingLabel=settingsFrame:CreateFontString(nil,'OVERLAY','GameFontHighlight')
rotationSettingLabel:SetPoint('LEFT',rotationSetting,'RIGHT',6,0)
rotationSettingLabel:SetText('Dealer Rotation (Raid Leader)')
rotationSetting:SetScript('OnClick',function()
 if not isLeader() then
  this:SetChecked(G.rotation and true or false)
  notice('Raid Leader controls dealer rotation.')
  return
 end
 G.rotation=this:GetChecked() and true or false
 G.Save()
 G.rotateButton:SetText(G.rotation and 'Dealer Rotation: ON' or 'Dealer Rotation: OFF')
end)
rotationSetting:SetScript('OnShow',function()this:SetChecked(G.rotation and true or false)end)
OctoPoker152_resetAllButton=button('Reset All Poker Data',260,-663,234,function()
 if not isLeader() then notice('Only Raid Leader can reset the entire table.');return end
 StaticPopup_Show('OCTOPOKER_RESET_ALL')
end)
settingsFrame:Hide()
-- Side-window layout and persistence. All saved coordinates use UIParent units.
OctoPokerDock=OctoPokerDock or {}
function OctoPokerDock.Id(panel)
 return panel and panel:GetName()
end
function OctoPokerDock.Save(panel)
 local id=OctoPokerDock.Id(panel)
 if not id or not panel:GetLeft() or not panel:GetTop() then return end
 OctoPokerDB=OctoPokerDB or {}
 OctoPokerDB.windowPositions=OctoPokerDB.windowPositions or {}
 local scale=panel:GetEffectiveScale()/UIParent:GetEffectiveScale()
 OctoPokerDB.windowPositions[id]={x=panel:GetLeft()*scale,y=panel:GetTop()*scale}
end
function OctoPokerDock.Restore(panel)
 local id=OctoPokerDock.Id(panel)
 local positions=OctoPokerDB and OctoPokerDB.windowPositions
 local saved=id and positions and positions[id]
 if not saved or type(saved.x)~='number' or type(saved.y)~='number' then return false end
 local width=panel:GetWidth()*panel:GetEffectiveScale()/UIParent:GetEffectiveScale()
 local height=panel:GetHeight()*panel:GetEffectiveScale()/UIParent:GetEffectiveScale()
 local rootWidth=UIParent:GetWidth()
 local rootHeight=UIParent:GetHeight()
 local x=math.max(0,math.min(saved.x,math.max(0,rootWidth-width)))
 local y=math.max(height,math.min(saved.y,rootHeight))
 panel:ClearAllPoints()
 panel:SetPoint('TOPLEFT',UIParent,'BOTTOMLEFT',x,y)
 return true
end
function OctoPokerDock.Place(panel)
 if not panel or not frame:IsShown() then return end
 if OctoPokerDock.Restore(panel) then return end
 local rootScale=UIParent:GetEffectiveScale()
 local mainScale=frame:GetEffectiveScale()/rootScale
 local panelScale=panel:GetEffectiveScale()/rootScale
 local left=(frame:GetLeft() or 0)*mainScale
 local right=(frame:GetRight() or 0)*mainScale
 local top=(frame:GetTop() or 0)*mainScale
 local width=panel:GetWidth()*panelScale
 local height=panel:GetHeight()*panelScale
 local rootWidth=UIParent:GetWidth()
 local rootHeight=UIParent:GetHeight()
 local gap=12
 local x
 if rootWidth-right>=width+gap then x=right+gap
 elseif left>=width+gap then x=left-width-gap
 else
  -- Narrow displays: maximize visible panel area.
  x=math.max(0,math.min(rootWidth-width,right+gap))
 end
 local y=math.max(height,math.min(rootHeight,top))
 panel:ClearAllPoints()
 panel:SetPoint('TOPLEFT',UIParent,'BOTTOMLEFT',x,y)
end
function OctoPokerDock.Refresh()
 local windows={OctoPokerSettingsFrame,OctoPokerStatisticsFrame,OctoPokerBankFrame,
  OctoPokerHistoryFrame,OctoPokerRankingsFrame,OctoPokerRulesFrame,OctoPokerHelpFrame}
 for _,panel in ipairs(windows) do
  if panel and panel:IsShown() then OctoPokerDock.Place(panel) end
 end
end
function OctoPokerDock.Reset()
 OctoPokerDB=OctoPokerDB or {}
 OctoPokerDB.windowPositions={}
 OctoPokerDock.Refresh()
end
OctoPoker152_gear=CreateFrame('Button',nil,frame)
OctoPoker152_gear:SetWidth(31);OctoPoker152_gear:SetHeight(31)
OctoPoker152_gear:SetPoint('TOPRIGHT',frame,'TOPRIGHT',-38,-23)
OctoPoker152_gearIcon=OctoPoker152_gear:CreateTexture(nil,'ARTWORK')
OctoPoker152_gearIcon:SetAllPoints(OctoPoker152_gear)
OctoPoker152_gearIcon:SetTexture('Interface\\Icons\\INV_Gizmo_02')
OctoPoker152_gearHighlight=OctoPoker152_gear:CreateTexture(nil,'HIGHLIGHT')
OctoPoker152_gearHighlight:SetAllPoints(OctoPoker152_gear)
OctoPoker152_gearHighlight:SetTexture('Interface\\Buttons\\ButtonHilight-Square')
OctoPoker152_gearHighlight:SetBlendMode('ADD')
OctoPoker152_gear:SetScript('OnClick',function()
 if settingsFrame:IsShown() then settingsFrame:Hide()
 else refreshSoundSettings();settingsFrame:Show();applyFontTheme(fontThemeIndex) end
end)
OctoPoker152_gear:SetScript('OnEnter',function()
 GameTooltip:SetOwner(this,'ANCHOR_RIGHT')
 GameTooltip:AddLine('Poker Settings')
 GameTooltip:Show()
end)
OctoPoker152_gear:SetScript('OnLeave',function()GameTooltip:Hide()end)

-- In-game guide, opened from the question-mark beside Settings.
OctoPoker152_helpFrame=CreateFrame('Frame','OctoPokerHelpFrame',UIParent)
OctoPoker152_helpFrame:SetWidth(465);OctoPoker152_helpFrame:SetHeight(575)
OctoPoker152_helpFrame:SetFrameStrata('DIALOG')
OctoPoker152_helpFrame:SetMovable(true)
OctoPoker152_helpFrame:EnableMouse(true)
OctoPoker152_helpFrame:RegisterForDrag('LeftButton')
OctoPoker152_helpFrame:SetScript('OnDragStart',function()this:StartMoving()end)
OctoPoker152_helpFrame:SetScript('OnDragStop',function()this:StopMovingOrSizing()end)
OctoPoker152_helpFrame:SetBackdrop({bgFile='Interface\\DialogFrame\\UI-DialogBox-Background',edgeFile='Interface\\DialogFrame\\UI-DialogBox-Border',tile=true,tileSize=32,edgeSize=32,insets={left=10,right=10,top=10,bottom=10}})
OctoPoker152_helpFrame:SetPoint('CENTER',UIParent,'CENTER',0,0)
local guideTitle=OctoPoker152_helpFrame:CreateFontString(nil,'OVERLAY','GameFontNormalLarge')
guideTitle:SetPoint('TOP',OctoPoker152_helpFrame,'TOP',0,-22)
guideTitle:SetText('Raid Poker - How to Play')
local guideClose=CreateFrame('Button',nil,OctoPoker152_helpFrame,'UIPanelCloseButton')
guideClose:SetPoint('TOPRIGHT',OctoPoker152_helpFrame,'TOPRIGHT',-6,-6)
local guideScroll=CreateFrame('ScrollFrame','OctoPokerGuideScroll',OctoPoker152_helpFrame,'UIPanelScrollFrameTemplate')
guideScroll:SetPoint('TOPLEFT',OctoPoker152_helpFrame,'TOPLEFT',22,-55)
guideScroll:SetPoint('BOTTOMRIGHT',OctoPoker152_helpFrame,'BOTTOMRIGHT',-40,20)
local guideContent=CreateFrame('Frame',nil,guideScroll)
guideContent:SetWidth(380);guideContent:SetHeight(1500)
guideScroll:SetScrollChild(guideContent)
local guideText=guideContent:CreateFontString(nil,'OVERLAY','GameFontHighlightSmall')
guideText:SetPoint('TOPLEFT',guideContent,'TOPLEFT',0,0)
guideText:SetWidth(380)
guideText:SetJustifyH('LEFT')
guideText:SetJustifyV('TOP')
guideText:SetText([[GETTING STARTED
1. Join the same raid and install Raid Poker on each client.
2. The Raid Leader manages the table and virtual Silver balances.
3. Click JOIN TABLE (green). It changes to LEAVE TABLE (red).
4. The Raid Leader clicks Start Hand after at least 2 players join and can pay the Ante.
5. Only registered players are dealt five cards.

GAME BUTTONS
Start Hand - Raid Leader begins a new five-card hand.
Exchange - Select cards to replace, then click Exchange on your turn.
Stand Pat - Keep all five cards during the draw.
Fold - Leave the current hand.
Check - Pass when no additional bet is due.
Call - Match the current bet.
Raise - Increase the current bet by the Silver amount entered.
BETTING PRESETS: +10s, +50s, +100s set an extra raise amount.
1/4 Pot, 1/2 Pot, Pot fill a raise amount based on the current pot.
These presets do not place a bet until Raise is clicked.
Fold Bet - Fold during betting.
All-In - Bet all your remaining virtual Silver.
JOIN TABLE / LEAVE TABLE - Enter or leave the next hand.

INFORMATION BUTTONS
History - Review previous hands and results.
Player Balances - Review balances, manage players, and reset data (leader).
TURN TIMER: choose 15s, 30s (default), 60s, or OFF.
The in-table timer is green on your turn and gray while waiting.
It stops at showdown; only the Raid Leader changes the limit.
Sync Cards - Request game synchronization.
Hand Rankings - See poker hand strengths.
Game Rules - Read the rules.
Player Statistics - Review and sort player results.
Settings (gear) - Customize the interface and sounds.
Help (?) - Open this guide.

PLAY ORDER
1. Players join the table.
2. Leader sets balances and Ante, then starts a hand.
3. Players act in turn during betting and the draw.
4. Select cards to exchange or Stand Pat.
5. Complete the betting rounds; showdown determines winners.
   WINNER popup and BETTING ACTIVITY show the result.
   Fold wins show no poker combination; ties may split the pot.
6. Silver is tracked virtually; no real gold is transferred.

ICON AND COMMANDS
Left-click the small minimap-style icon to open or close poker.
Drag the icon around the minimap border to reposition it.
Use /poker reseticon to restore the icon to the minimap.
Use /poker settings to open Settings.
If cards or a winner result are missing, use Sync Cards to resync.
After /reload, the client attempts to recover the current hand.
Dealer Rotation ON/OFF is in Poker Settings.

RAID LEADER CONTROLS (CROWN ICON)
Only the Raid Leader can open this panel.
End Betting - Advance only when every active player has acted and called.
Force Showdown - Immediately evaluate the current hands and settle the pot.
Declare Winner - Select a player and manually award the pot. This overrides
the poker ranking and is disabled if anyone is All-In (side-pot safety).
Cancel Hand - Refund all virtual Silver invested in the active hand.
Resend WINNER - Broadcast the last confirmed winner popup again.
Announce Winner - Send the last winner and pot to /raid or /say.
Announce Balances - Post each participating player's tracked balance.
Announce Table - Post the phase, pot, and participants.
Use the channel buttons in the Raid Controls panel to choose /raid or /say.
Manual actions require confirmation. Chat reports do not transfer gold.
The controls do not grant actual WoW raid leadership.

IMPORTANT
The game uses RAID addon messages. Hidden cards are not cryptographically private; modified clients may inspect network messages.
]])
OctoPoker152_helpFrame:Hide()
OctoPoker152_help=CreateFrame('Button',nil,frame)
OctoPoker152_help:SetWidth(31);OctoPoker152_help:SetHeight(31)
OctoPoker152_help:SetPoint('TOPRIGHT',frame,'TOPRIGHT',-75,-23)
local helpBackground=OctoPoker152_help:CreateTexture(nil,'ARTWORK')
helpBackground:SetAllPoints(OctoPoker152_help)
helpBackground:SetTexture('Interface\\Icons\\INV_Misc_Book_09')
local helpMark=OctoPoker152_help:CreateFontString(nil,'OVERLAY','GameFontNormalLarge')
helpMark:SetPoint('CENTER',OctoPoker152_help,'CENTER',0,1)
helpMark:SetText('?')
OctoPoker152_help:SetScript('OnClick',function()
 if OctoPoker152_helpFrame:IsShown() then OctoPoker152_helpFrame:Hide() else OctoPoker152_helpFrame:Show() end
end)
OctoPoker152_help:SetScript('OnEnter',function()
 GameTooltip:SetOwner(this,'ANCHOR_RIGHT')
 GameTooltip:AddLine('Poker Help - Buttons and Game Guide')
 GameTooltip:Show()
end)
OctoPoker152_help:SetScript('OnLeave',function()GameTooltip:Hide()end)

-- Game Rules: third icon in the top toolbar, beside Help and Settings.
OctoPoker152_rulesIcon=CreateFrame('Button',nil,frame)
OctoPoker152_rulesIcon:SetWidth(31);OctoPoker152_rulesIcon:SetHeight(31)
OctoPoker152_rulesIcon:SetPoint('TOPRIGHT',frame,'TOPRIGHT',-112,-23)
local rulesIconTexture=OctoPoker152_rulesIcon:CreateTexture(nil,'ARTWORK')
rulesIconTexture:SetAllPoints(OctoPoker152_rulesIcon)
rulesIconTexture:SetTexture('Interface\\Icons\\INV_Misc_Book_11')
local rulesIconHighlight=OctoPoker152_rulesIcon:CreateTexture(nil,'HIGHLIGHT')
rulesIconHighlight:SetAllPoints(OctoPoker152_rulesIcon)
rulesIconHighlight:SetTexture('Interface\\Buttons\\ButtonHilight-Square')
rulesIconHighlight:SetBlendMode('ADD')
OctoPoker152_rulesIcon:SetScript('OnClick',function()
 if rulesFrame:IsShown() then rulesFrame:Hide() else rulesFrame:Show() end
end)
OctoPoker152_rulesIcon:SetScript('OnEnter',function()
 GameTooltip:SetOwner(this,'ANCHOR_RIGHT');GameTooltip:AddLine('Game Rules');GameTooltip:Show()
end)
OctoPoker152_rulesIcon:SetScript('OnLeave',function()GameTooltip:Hide()end)

-- Compact toolbar icons: preserve the existing synchronization and rankings features.
do
 local function toolbarIcon(offset,texture,tooltip,callback)
  local b=CreateFrame('Button',nil,frame)
  b:SetWidth(31);b:SetHeight(31)
  b:SetPoint('TOPRIGHT',frame,'TOPRIGHT',offset,-23)
  local art=b:CreateTexture(nil,'ARTWORK');art:SetAllPoints(b);art:SetTexture(texture)
  local glow=b:CreateTexture(nil,'HIGHLIGHT');glow:SetAllPoints(b)
  glow:SetTexture('Interface\\Buttons\\ButtonHilight-Square');glow:SetBlendMode('ADD')
  b:SetScript('OnClick',callback)
  b:SetScript('OnEnter',function()GameTooltip:SetOwner(this,'ANCHOR_RIGHT');GameTooltip:AddLine(tooltip);GameTooltip:Show()end)
  b:SetScript('OnLeave',function()GameTooltip:Hide()end)
 end
 toolbarIcon(-149,'Interface\\Icons\\INV_Misc_Note_01','Hand Rankings',function()
  if G.RankingsFrame then if G.RankingsFrame:IsShown() then G.RankingsFrame:Hide() else G.RankingsFrame:Show() end end
 end)
 toolbarIcon(-186,'Interface\\Icons\\Spell_Holy_Renew','Sync Cards / Recover State',function()
  if G.SyncCards then G.SyncCards() end
 end)
end


do -- balance-window UI construction scope
OctoPoker152_bankFrame=CreateFrame('Frame','OctoPokerBankFrame',UIParent)
OctoPoker152_bankFrame:SetWidth(565);OctoPoker152_bankFrame:SetHeight(540)
OctoPoker152_bankFrame:SetPoint('CENTER',UIParent,'CENTER',90,0)
OctoPoker152_bankFrame:SetMovable(true);OctoPoker152_bankFrame:EnableMouse(true);OctoPoker152_bankFrame:RegisterForDrag('LeftButton')
OctoPoker152_bankFrame:SetScript('OnDragStart',function()this:StartMoving()end)
OctoPoker152_bankFrame:SetScript('OnDragStop',function()this:StopMovingOrSizing()end)
OctoPoker152_bankFrame:SetBackdrop({bgFile='Interface\\DialogFrame\\UI-DialogBox-Background',edgeFile='Interface\\DialogFrame\\UI-DialogBox-Border',tile=true,tileSize=32,edgeSize=32,insets={left=8,right=8,top=8,bottom=8}})
OctoPoker152_bankFrame:SetFrameStrata('DIALOG')
OctoPoker152_bankTitle=OctoPoker152_bankFrame:CreateFontString(nil,'OVERLAY','GameFontNormalLarge')
OctoPoker152_bankTitle:SetPoint('TOPLEFT',OctoPoker152_bankFrame,'TOPLEFT',22,-24);OctoPoker152_bankTitle:SetText('Raid Player Balances')
-- Scrollable player list, with explicit leader-only enable/disable controls.
OctoPoker152_bankScroll=CreateFrame('ScrollFrame','OctoPokerBankScroll',OctoPoker152_bankFrame,'UIPanelScrollFrameTemplate')
OctoPoker152_bankScroll:SetPoint('TOPLEFT',OctoPoker152_bankFrame,'TOPLEFT',24,-90)
OctoPoker152_bankScroll:SetWidth(495);OctoPoker152_bankScroll:SetHeight(260)
OctoPoker152_bankContent=CreateFrame('Frame',nil,OctoPoker152_bankScroll)
OctoPoker152_bankContent:SetWidth(470);OctoPoker152_bankContent:SetHeight(850)
OctoPoker152_bankScroll:SetScrollChild(OctoPoker152_bankContent)
-- Independent column headers: fixed anchors match each data column.
OctoPoker152_bankHeader=OctoPoker152_bankFrame:CreateFontString(nil,'OVERLAY','GameFontNormalSmall')
OctoPoker152_bankHeader:SetPoint('TOPLEFT',OctoPoker152_bankFrame,'TOPLEFT',26,-65)
OctoPoker152_bankHeader:SetWidth(130)
OctoPoker152_bankHeader:SetJustifyH('LEFT')
OctoPoker152_bankHeader:SetText('PLAYER')
OctoPoker152_bankHeaderBalance=OctoPoker152_bankFrame:CreateFontString(nil,'OVERLAY','GameFontNormalSmall')
OctoPoker152_bankHeaderBalance:SetPoint('TOPLEFT',OctoPoker152_bankFrame,'TOPLEFT',164,-65)
OctoPoker152_bankHeaderBalance:SetWidth(95)
OctoPoker152_bankHeaderBalance:SetJustifyH('LEFT')
OctoPoker152_bankHeaderBalance:SetText('BALANCE')
OctoPoker152_bankHeaderPermission=OctoPoker152_bankFrame:CreateFontString(nil,'OVERLAY','GameFontNormalSmall')
OctoPoker152_bankHeaderPermission:SetPoint('TOPLEFT',OctoPoker152_bankFrame,'TOPLEFT',268,-65)
OctoPoker152_bankHeaderPermission:SetWidth(115)
OctoPoker152_bankHeaderPermission:SetJustifyH('CENTER')
OctoPoker152_bankHeaderPermission:SetText('PERMISSION')
OctoPoker152_bankHeaderSeated=OctoPoker152_bankFrame:CreateFontString(nil,'OVERLAY','GameFontNormalSmall')
OctoPoker152_bankHeaderSeated:SetPoint('TOPLEFT',OctoPoker152_bankFrame,'TOPLEFT',400,-65)
OctoPoker152_bankHeaderSeated:SetWidth(85)
OctoPoker152_bankHeaderSeated:SetJustifyH('CENTER')
OctoPoker152_bankHeaderSeated:SetText('AT TABLE')
OctoPokerBank.rows={}
for i=1,40 do
 local row=CreateFrame('Frame',nil,OctoPoker152_bankContent)
 row:SetWidth(470);row:SetHeight(20)
 row:SetPoint('TOPLEFT',OctoPoker152_bankContent,'TOPLEFT',0,-(i-1)*21)
 row.name=row:CreateFontString(nil,'OVERLAY','GameFontHighlightSmall')
 row.name:SetPoint('LEFT',row,'LEFT',2,0);row.name:SetWidth(130);row.name:SetJustifyH('LEFT')
 row.amount=row:CreateFontString(nil,'OVERLAY','GameFontHighlightSmall')
 row.amount:SetPoint('LEFT',row,'LEFT',140,0);row.amount:SetWidth(95);row.amount:SetJustifyH('LEFT')
 row.toggle=CreateFrame('Button',nil,row,'UIPanelButtonTemplate')
 row.toggle:SetWidth(115);row.toggle:SetHeight(20);row.toggle:SetPoint('LEFT',row,'LEFT',244,0)
 row.seated=row:CreateFontString(nil,'OVERLAY','GameFontHighlightSmall')
 row.seated:SetPoint('LEFT',row,'LEFT',376,0);row.seated:SetWidth(85);row.seated:SetJustifyH('CENTER')
 row.toggle:SetScript('OnClick',function()
  if this.player then OctoPokerBank.SetEnabled(this.player,not OctoPokerBank.IsEnabled(this.player)) end
 end)
 OctoPokerBank.rows[i]=row
end
OctoPoker152_bankInfo=OctoPoker152_bankFrame:CreateFontString(nil,'OVERLAY','GameFontHighlightSmall')
OctoPoker152_bankInfo:SetPoint('TOPLEFT',OctoPoker152_bankFrame,'TOPLEFT',24,-365)
OctoPoker152_bankInfo:SetText('Raid Leader only. Virtual balance in Silver (s).');G.bankInfo=OctoPoker152_bankInfo
OctoPoker152_bankPlayer=CreateFrame('EditBox','OctoPokerBankPlayer',OctoPoker152_bankFrame,'InputBoxTemplate')
OctoPoker152_bankPlayer:SetWidth(130);OctoPoker152_bankPlayer:SetHeight(24);OctoPoker152_bankPlayer:SetPoint('TOPLEFT',OctoPoker152_bankFrame,'TOPLEFT',26,-397)
OctoPoker152_bankPlayer:SetAutoFocus(false);OctoPoker152_bankPlayer:SetText('PlayerName')
OctoPoker152_bankAmount=CreateFrame('EditBox','OctoPokerBankAmount',OctoPoker152_bankFrame,'InputBoxTemplate')
OctoPoker152_bankAmount:SetWidth(90);OctoPoker152_bankAmount:SetHeight(24);OctoPoker152_bankAmount:SetPoint('TOPLEFT',OctoPoker152_bankFrame,'TOPLEFT',177,-397)
OctoPoker152_bankAmount:SetAutoFocus(false);OctoPoker152_bankAmount:SetNumeric(true);OctoPoker152_bankAmount:SetText('1000');G.bankAmount=OctoPoker152_bankAmount
function OctoPoker152_bankButton(txt,x,y,w,handler)
 local b=CreateFrame('Button',nil,OctoPoker152_bankFrame,'UIPanelButtonTemplate')
 b:SetWidth(w);b:SetHeight(25);b:SetPoint('TOPLEFT',OctoPoker152_bankFrame,'TOPLEFT',x,y)
 b:SetText(txt);b:SetScript('OnClick',handler);return b
end
OctoPoker152_bankButton('Set Player',24,-437,110,function()OctoPokerBank.Set(OctoPoker152_bankPlayer:GetText(),OctoPoker152_bankAmount:GetText())end)
OctoPoker152_bankButton('Set All Raid',145,-437,115,function()OctoPokerBank.Set('ALL',OctoPoker152_bankAmount:GetText())end)
OctoPoker152_bankButton('Refresh',272,-437,90,function()OctoPokerBank.Refresh();if isLeader() then OctoPokerBank.Broadcast() else requestSync() end end)
-- Same guarded reset confirmation as the main poker window.
OctoPoker152_bankButton('Reset All Poker Data',370,-437,155,function()
 if not isLeader() then notice('Only Raid Leader can reset the entire table.');return end
 StaticPopup_Show('OCTOPOKER_RESET_ALL')
end)
OctoPoker152_bankClose=CreateFrame('Button',nil,OctoPoker152_bankFrame,'UIPanelCloseButton')
OctoPoker152_bankClose:SetPoint('TOPRIGHT',OctoPoker152_bankFrame,'TOPRIGHT',-5,-5)
function OctoPokerBank.Refresh()
 for i=1,40 do
  local row=OctoPokerBank.rows[i]
  local name=GetRaidRosterInfo(i)
  if name then
   name=short(name)
   row:Show();row.name:SetText(name);row.amount:SetText(G.Display(balanceOf(name)))
   row.toggle.player=name
   row.seated:SetText(G.joined and G.joined[name] and '|cff55dd77YES|r' or '|cffaaaaaaNO|r')
   row.toggle:SetText(OctoPokerBank.IsEnabled(name) and 'ENABLED' or 'DISABLED')
   if isLeader() and phase~='DRAW' and not bettingPhase() then row.toggle:Enable() else row.toggle:Disable() end
  else row:Hide() end
 end
end
-- Refresh live seating status as raid members join/leave the poker table.
OctoPoker152_bankFrame:SetScript('OnUpdate',function()
 this.refreshElapsed=(this.refreshElapsed or 0)+arg1
 if this.refreshElapsed>=0.75 then
  this.refreshElapsed=0
  OctoPokerBank.Refresh()
 end
end)
OctoPoker152_bankFrame:Hide()
button('Player Balances',147,-537,113,function()
 OctoPokerBank.Refresh()
 if OctoPoker152_bankFrame:IsShown() then OctoPoker152_bankFrame:Hide() else OctoPoker152_bankFrame:Show() end
end)
end -- balance-window UI construction scope

OctoPoker152_toggle=CreateFrame('Button','OctoPokerToggle',UIParent)
OctoPoker152_toggle:SetWidth(32);OctoPoker152_toggle:SetHeight(32)
OctoPoker152_toggle:SetFrameStrata('MEDIUM')
-- Standard WoW minimap-button appearance with a built-in icon texture.
-- The button remains independently draggable anywhere on screen.
-- Minimap-only positioning. Store angle rather than screen coordinates.
function OctoPoker152_placeIcon(angle)
 angle=tonumber(angle) or 0
 local radius=80
 if Minimap then
  radius=(Minimap:GetWidth() or 140)/2+10
  OctoPoker152_toggle:ClearAllPoints()
  OctoPoker152_toggle:SetPoint('CENTER',Minimap,'CENTER',radius*math.cos(angle),radius*math.sin(angle))
 else
  OctoPoker152_toggle:ClearAllPoints()
  OctoPoker152_toggle:SetPoint('TOPRIGHT',UIParent,'TOPRIGHT',-185,-170)
 end
end
function OctoPoker152_placeMinimapDefault()
 OctoPoker152_placeIcon(-0.25)
end
OctoPoker152_placeMinimapDefault()
local art=OctoPoker152_toggle:CreateTexture(nil,'ARTWORK')
art:SetWidth(32);art:SetHeight(32)
art:SetPoint('CENTER',OctoPoker152_toggle,'CENTER',0,0)
-- Built-in circular tracking icon, no square inventory texture.
art:SetTexture('Interface\\AddOns\\OctoWoW_Raid_Poker\\PokerIcon')
local border=OctoPoker152_toggle:CreateTexture(nil,'OVERLAY')
border:SetWidth(52);border:SetHeight(52)
border:SetPoint('CENTER',OctoPoker152_toggle,'CENTER',0,0)
border:Hide()
local highlight=OctoPoker152_toggle:CreateTexture(nil,'HIGHLIGHT')
highlight:SetAllPoints(OctoPoker152_toggle)
highlight:SetTexture('Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight')
highlight:SetBlendMode('ADD')
-- Drag around the minimap ring, without StartMoving or screen-edge clamps.
OctoPoker152_toggle:EnableMouse(true)
OctoPoker152_toggle:RegisterForDrag('LeftButton')
OctoPoker152_dragMoved=false
local iconDragging=false
local iconDragAngle=-0.25
local function iconAngleFromCursor()
 if not Minimap then return iconDragAngle end
 local cursorX,cursorY=GetCursorPosition()
 local scale=Minimap:GetEffectiveScale()
 local centerX=((Minimap:GetLeft() or 0)+(Minimap:GetWidth() or 140)/2)*scale
 local centerY=((Minimap:GetBottom() or 0)+(Minimap:GetHeight() or 140)/2)*scale
 local dx,dy=cursorX-centerX,cursorY-centerY
 if dx==0 and dy==0 then return iconDragAngle end
 -- atan2 exists in most WoW Lua builds; explicit fallback for older clients.
 if math.atan2 then return math.atan2(dy,dx) end
 if dx==0 then return dy>0 and math.pi/2 or -math.pi/2 end
 local angle=math.atan(dy/dx)
 if dx<0 then angle=angle+math.pi end
 return angle
end
OctoPoker152_toggle:SetScript('OnDragStart',function()
 iconDragging=true
 OctoPoker152_dragMoved=true
 GameTooltip:Hide()
end)
OctoPoker152_toggle:SetScript('OnUpdate',function()
 if iconDragging then
  iconDragAngle=iconAngleFromCursor()
  OctoPoker152_placeIcon(iconDragAngle)
 end
end)
OctoPoker152_toggle:SetScript('OnDragStop',function()
 if not iconDragging then return end
 iconDragAngle=iconAngleFromCursor()
 iconDragging=false
 OctoPoker152_placeIcon(iconDragAngle)
 OctoPokerDB=OctoPokerDB or {}
 OctoPokerDB.icon={'MINIMAP',iconDragAngle}
end)
OctoPoker152_toggle:SetScript('OnClick',function()
 if OctoPoker152_dragMoved then OctoPoker152_dragMoved=false;return end
 if frame:IsShown() then frame:Hide() else frame:Show() end
end)
OctoPoker152_toggle:SetScript('OnEnter',function()
 GameTooltip:SetOwner(this,'ANCHOR_RIGHT')
 GameTooltip:AddLine('OctoWoW Raid Poker')
 GameTooltip:AddLine('Left-click: Open / Close',1,1,1)
 GameTooltip:AddLine('Drag: Move around minimap',1,1,1)
 GameTooltip:Show()
end)
OctoPoker152_toggle:SetScript('OnLeave',function() GameTooltip:Hide() end)
frame:RegisterEvent('ADDON_LOADED');frame:RegisterEvent('PLAYER_LOGIN');frame:RegisterEvent('CHAT_MSG_ADDON');frame:RegisterEvent('RAID_ROSTER_UPDATE')
-- Lua 5.0 limits each function to 32 captured upvalues. Keep event handlers small.
function OctoPoker152_onHostPacket(kind,data,sender)
  if kind=='WINEND' then
   local _,_,id,result=string.find(data or '','^([^;]+);(.*)$')
   if id and id==session then G.ApplyFinal(result) end
   return
  end
  if kind=='BETEVENT' then
   local _,_,id,name,action,amount,newpot=string.find(data,'^([^;]+);([^;]+);([^;]+);([^;]+);([^;]+)$')
   if id and (id==session or action=='ANTE') then B.Event(name,action,tonumber(amount),tonumber(newpot)) end
   return
  elseif kind=='STATS' then G.ReadStats(data);return
  elseif kind=='DEALER' then G.dealer=data;G.Save();render();return
  elseif kind=='ANTE' then
   local v=tonumber(data)
   if v and v>=0 and v<=99999900 and v==math.floor(v) then
    G.ante=v;G.Save()
    if G.OctoPoker152_anteEdit then G.OctoPoker152_anteEdit:SetText(G.Input(v)) end
    notice('Ante: '..G.Display(v)..' per player.')
   end
   return
  end
  if kind=='FULLRESET' and data=='RESET' then
   OctoPokerAdmin.ResetLocal();notice('Raid Leader reset all poker data to zero.');return
  end
   if kind=='LOBBY' then
    G.joined={}
    for n in string.gfind(data or '','[^,]+') do G.joined[short(n)]=true end
    render();return
   end
  if kind=='ELIG' then
   G.disabledPlayers={}
   for n in string.gfind(data or '','[^,]+') do G.disabledPlayers[short(n)]=true end
   if OctoPokerBank.Refresh then OctoPokerBank.Refresh() end
   if G.RefreshJoinButton then G.RefreshJoinButton() end
   return
  end
  if kind=='BALALL' then
   for entry in string.gfind(data or '','[^,]+') do
    local _,_,name,gold=string.find(entry,'^([^:]+):(%d+)$')
    if name then balances[short(name)]=tonumber(gold) or 0 end
   end
   OctoPokerDB=OctoPokerDB or {};OctoPokerDB.balances=balances
   if OctoPokerBank.Refresh then OctoPokerBank.Refresh() end
   render();return
  elseif kind=='START' then
   local _,_,id,names=string.find(data,'^([^;]+);(.*)$');if not id then return end
   if session~=id then
    session=id;phase='BET1';current=1;myCards={};chosen={};publicText='';lastResult='';G.allin={};G.remoteResult=nil;G.remoteDetails='';G.nextResultRequest=nil;G.inferredResult=nil;G.finalResends=nil
   end
   participants={};for n in string.gfind(names,'[^,]+')do participants[table.getn(participants)+1]=n end
   notice('New hand started by Raid Leader.');render()
  elseif kind=='HAND' then
   local _,_,id,cards=string.find(data,'^([^;]+);(.*)$');if id~=session then
    session=id;phase='BET1';current=1;myCards={};chosen={}
   end
   local h={};for c in string.gfind(cards,'[^,]+') do h[table.getn(h)+1]=c end
   if table.getn(h)==5 then
    local wasNew=not receivedHands[id];myCards=h;chosen={};receivedHands[id]=true;if wasNew then dealSound() else soundPlay('exchange') end;debugLog('HAND RECEIVED: 5 cards')
    send('HANDACK',id,'WHISPER',leader())
    notice('Five cards received. Wait for your turn.');render()
   end
  elseif kind=='STATE' then
   local _,_,id,p,turn,people=string.find(data,'^([^;]+);([^;]+);([^;]+);(.*)$')
   if id~=session then
    session=id;myCards={};chosen={}
   end
   phase=p;current=tonumber(turn) or 1;publicText=people
   if phase=='SHOWDOWN' and not isLeader() and (not G.remoteResult or G.inferredResult) then
    send('GETRESULT',session)
   end
   local _,_,visiblePeople,embeddedResult=string.find(people or '','^(.-);FINAL=(.*)$')
   if embeddedResult then
    publicText=visiblePeople
     G.ApplyFinal(embeddedResult)
   end
   if (phase=='DRAW' or bettingPhase()) and table.getn(myCards)~=5 then
    notice('Waiting for private cards. Click Sync Cards if needed.')
   end
   render()
  elseif kind=='BANK' then
   local _,_,id,newpot,newbet,entries=string.find(data,'^([^;]+);([^;]+);([^;]+);(.*)$')
   if id==session then
    -- Settlement fallback: BANK carries the authoritative balances. A payout
    -- is the positive balance change at SHOWDOWN, not the player's net profit.
    local before={}
    for _,n in ipairs(participants) do before[short(n)]=balances[short(n)] end
    local previousPot=pot
    pot=tonumber(newpot) or pot;streetBet=tonumber(newbet) or streetBet
    for entry in string.gfind(entries or '','[^,]+') do
     local _,_,name,balance,paid,total,done,all=string.find(entry,'^([^:]+):([^:]+):([^:]+):([^:]+):([^:]+):([^:]+)$')
     if name then balances[short(name)]=tonumber(balance) or 100000;roundPaid[name]=tonumber(paid) or 0;contrib[name]=tonumber(total) or 0;acted[name]=done=='1';G.allin[name]=all=='1' end
    end
    if phase=='SHOWDOWN' and not G.remoteResult and previousPot>0 and pot==0 then
     local winners={}
     for _,n in ipairs(participants) do
      local key=short(n)
      if before[key] and balances[key] and balances[key]>before[key] then
       winners[table.getn(winners)+1]=key
      end
     end
     if table.getn(winners)>0 then
      local inferred='Winner: '..table.concat(winners,', ')..' | Pot: '..G.Display(previousPot)
      G.remoteResult=inferred;G.remoteDetails='';G.inferredResult=true
      pushHistory(inferred);B.Result(inferred);notice(inferred)
      announceVictory(inferred,'')
     end
    end
    render()
   end
   elseif kind=='RESULT' then
    local _,_,id,result,details=string.find(data,'^([^;]+);([^;]+);(.*)$');if id~=session then return end
     G.ApplyFinal(result)
     G.remoteDetails=details or ''
   elseif kind=='WINCOMBO' then
    local _,_,id,n,desc=string.find(data,'^([^;]+);([^;]+);(.*)$')
    if id==session and G.remoteResult then
     G.winnerCombos=G.winnerCombos or {}
     G.winnerCombos[short(n)]=desc
     if victoryFrame:IsShown() then announceVictory(G.remoteResult,G.remoteDetails,true) end
    end
  elseif kind=='RESDETAIL' then
    local _,_,id,detail=string.find(data,'^([^;]+);(.*)$')
    if id==session and G.remoteResult then
     G.remoteDetails=(G.remoteDetails~='' and (G.remoteDetails..' / ') or '')..detail
     if victoryFrame:IsShown() then announceVictory(G.remoteResult,G.remoteDetails,true) end
    end
   elseif kind=='ABORT' and data==session then
   phase='ABORTED';notice('Hand aborted: raid roster changed.');render()
  end
end
function G.JoinedNames()
 local names={}
 for i=1,raidCount() do
  local n=GetRaidRosterInfo(i)
  if n and G.joined[short(n)] then names[table.getn(names)+1]=short(n) end
 end
 return names
end
function OctoPoker152_onPokerPacket(kind,data,sender)
  if (kind=='JOIN' or kind=='LEAVE') and isLeader() and inRaid(sender) then
   if phase=='DRAW' or bettingPhase() then return end
   if kind=='JOIN' and not OctoPokerBank.IsEnabled(sender) then
    OctoPokerBank.SyncEnabled();return
   end
   G.joined[short(sender)]=(kind=='JOIN') and true or nil
   send('LOBBY',table.concat(G.JoinedNames(),','))
   notice(short(sender)..(kind=='JOIN' and ' joined the poker table.' or ' left the poker table.'))
   render()
   return
  end
  if kind=='HELLO' and isLeader() then
   if phase=='SHOWDOWN' and G.finalWire then
    send('STATE',session..';'..phase..';'..tostring(current)..';'..publicText..';FINAL='..G.finalWire,'WHISPER',sender)
    send('BANK',session..';'..roundState(),'WHISPER',sender)
    send('RESULT',session..';'..G.finalWire..';','WHISPER',sender)
     send('WINEND',session..';'..G.finalWire,'WHISPER',sender)
    return
   end
   syncTo(sender)
   OctoPokerBank.Broadcast()
   OctoPokerBank.SyncEnabled()
   send('LOBBY',table.concat(G.JoinedNames(),','))
   return
  end
  if kind=='GETRESULT' and isLeader() then
   if data==session and phase=='SHOWDOWN' and G.finalWire then
    send('RESULT',session..';'..G.finalWire..';','WHISPER',sender)
    for name,desc in pairs(G.winnerCombos or {}) do
     send('WINCOMBO',session..';'..name..';'..desc,'WHISPER',sender)
    end
   end
   return
  end
  if kind=='HANDACK' and isLeader() then
   if data==session then handAcknowledged[short(sender)]=true;debugLog('HANDACK from '..short(sender)..' session='..session) end
   return
  end
  if kind=='MOVE' and isLeader() then
   local _,_,id,action,payload=string.find(data,'^([^;]+);([^;]+);(.*)$')
   if id==session then if bettingPhase() then applyBet(sender,action,payload) else applyAction(sender,action,payload) end end
   return
  end
  if not same(sender,leader()) then debugLog('RX FILTERED sender not leader '..tostring(leader()));return end
  -- Host already applied these events locally; ignore its own broadcasts.
  if isLeader() and same(sender,me()) then return end
  OctoPoker152_onHostPacket(kind,data,sender)
end

function OctoPoker152_onAddonMessage(prefix,msg,channel,sender)

  local prefix,msg,channel,sender=arg1,arg2,arg3,arg4
  if prefix==PROBE_PREFIX then
   debugLog('PROBE RX channel='..tostring(channel)..' from='..tostring(sender)..' payload='..tostring(msg))
   if string.sub(msg or '',1,5)=='PING:' and inRaid(sender) then
    local ok,err=pcall(SendAddonMessage,PROBE_PREFIX,'PONG:'..short(me()),channel,(channel=='WHISPER' and sender or nil))
    debugLog('PROBE PONG '..tostring(channel)..' '..(ok and 'API_OK' or tostring(err)))
   end
   return
  end
  if prefix~=PREFIX then return end
  debugLog('RX poker channel='..tostring(channel)..' from='..tostring(sender)..' bytes='..tostring(msg and string.len(msg) or 0))
  if channel~=TRANSPORT or not inRaid(sender) then debugLog('RX FILTERED poker channel/raid');return end
  if same(sender,me()) then return end
  -- Recipient-tagged messages are only processed by their intended client.
  -- The unencrypted payload is still visible to other addons on the raid.
  if string.sub(msg or '',1,3)=='TO:' then
   local _,_,recipient,body=string.find(msg,'^TO:([^:]+):(.*)$')
   if not recipient or not same(recipient,me()) then return end
   msg=body
  end
  local _,_,kind,data=string.find(msg,'^([^~]+)~(.*)$');if not kind then return end
  OctoPoker152_onPokerPacket(kind,data,sender)
end
function OctoPoker152_onPlayerLogin()

  if RegisterAddonMessagePrefix then RegisterAddonMessagePrefix(PREFIX);RegisterAddonMessagePrefix(PROBE_PREFIX) end
  local storedScale=DEFAULT_UI_SCALE
  if OctoPokerDB and OctoPokerDB.uiScale then storedScale=OctoPokerDB.uiScale end
  storedScale=applyUIScale(storedScale)
  uiScaleSlider:SetValue(math.floor(storedScale*100+0.5))
  uiScaleValue:SetText(math.floor(storedScale*100+0.5)..'%')
  local savedTable='None'
  local savedOpacity=0.60
  if OctoPokerDB then
   if OctoPokerDB.tableStyle then savedTable=OctoPokerDB.tableStyle end
   if OctoPokerDB.tableOpacity~=nil then savedOpacity=OctoPokerDB.tableOpacity end
  end
  for i=1,table.getn(tableStyles) do
   if tableStyles[i]==savedTable then tableStyleIndex=i;break end
  end
  tableOpacitySlider:SetValue(math.floor(savedOpacity*100+0.5))
  tableOpacityValue:SetText(math.floor(savedOpacity*100+0.5)..'%')
  selectTableStyle(tableStyleIndex)
  if OctoPokerDB and type(OctoPokerDB.sounds)=='table' then
   for k,v in pairs(OctoPokerDB.sounds) do if soundOptions[k]~=nil then soundOptions[k]=v end end
  end
  refreshSoundSettings();saveSounds()
  chooseFontTheme(OctoPokerDB and OctoPokerDB.fontTheme or 1)
  OctoPokerCardTheme.Set('Classic')
  if OctoPokerDB and type(OctoPokerDB.pokerStats)=='table' then G.stats=OctoPokerDB.pokerStats end
  if OctoPokerDB and OctoPokerDB.dealerRotation~=nil then G.rotation=OctoPokerDB.dealerRotation end
  if OctoPokerDB and OctoPokerDB.dealerName then G.dealer=OctoPokerDB.dealerName end
  if OctoPokerDB and type(OctoPokerDB.anteAmount)=='number' then
   G.ante=math.max(0,math.min(99999900,math.floor(OctoPokerDB.anteAmount)))
  end
  if G.OctoPoker152_anteEdit then G.OctoPoker152_anteEdit:SetText(G.Input(G.ante)) end
  if G.rotateButton then G.rotateButton:SetText(G.rotation and 'Dealer Rotation: ON' or 'Dealer Rotation: OFF') end
  if OctoPokerDB and type(OctoPokerDB.balances)=='table' then balances=OctoPokerDB.balances end
  if OctoPokerDB and type(OctoPokerDB.disabledPlayers)=='table' then G.disabledPlayers=OctoPokerDB.disabledPlayers end
  -- Preserve saved amounts exactly as stored: never multiply or divide balances.
  -- Previous v1.3.54+ saves already stored Silver internally.
  G.RefreshCurrency()
  if OctoPokerDB and type(OctoPokerDB.history)=='table' then history=OctoPokerDB.history;updateHistory() end
     if OctoPokerDB and type(OctoPokerDB.icon)=='table' and OctoPokerDB.icon[1]=='MINIMAP' then
    iconDragAngle=tonumber(OctoPokerDB.icon[2]) or -0.25
   else
    -- Old free-screen coordinates are intentionally replaced with minimap placement.
    iconDragAngle=-0.25
    OctoPokerDB=OctoPokerDB or {}
    OctoPokerDB.icon={'MINIMAP',iconDragAngle}
   end
   OctoPoker152_placeIcon(iconDragAngle)
notice('Ready. RAID transport active; card contents are NOT private on the network.');render();DEFAULT_CHAT_FRAME:AddMessage('|cffd6ac55OctoWoW Raid Poker 1.4.13|r: /orp')

end
function G.OnRosterUpdate()
  if (phase=='DRAW' or bettingPhase()) and isLeader() then
   for _,n in ipairs(participants) do if not inRaid(n) then notice('A player left the raid; hand must be restarted.');phase='ABORTED';send('ABORT',session);publish();break end end
  end
  render()

end
frame:SetScript('OnEvent',function()
 if event=='ADDON_LOADED' then
  local addon=arg1
  if addon=='OctoWoW_Raid_Poker' or addon=='OctoWoWRaidPoker' then OctoPokerDB=OctoPokerDB or {} end
 elseif event=='PLAYER_LOGIN' then OctoPoker152_onPlayerLogin()
 elseif event=='RAID_ROSTER_UPDATE' then G.OnRosterUpdate()
 elseif event=='CHAT_MSG_ADDON' then OctoPoker152_onAddonMessage(arg1,arg2,arg3,arg4)
 end
end)
-- Dock on first opening; save manually dragged positions.
-- Separate function scope avoids the Lua 5.1 limit of 200 locals in a chunk.
function OctoPoker152_SetupWindowDocking()
  local windows={OctoPokerSettingsFrame,OctoPokerStatisticsFrame,OctoPokerBankFrame,
  OctoPokerHistoryFrame,OctoPokerRankingsFrame,OctoPokerRulesFrame,OctoPokerHelpFrame}
 for _,panel in ipairs(windows) do
  if panel then
   local previousShow=panel:GetScript('OnShow')
   panel:SetScript('OnShow',function()
    if previousShow then previousShow() end
    OctoPokerDock.Place(this)
   end)
   local previousStop=panel:GetScript('OnDragStop')
   panel:SetScript('OnDragStop',function()
    if previousStop then previousStop() else this:StopMovingOrSizing() end
    OctoPokerDock.Save(this)
   end)
  end
 end
end
OctoPoker152_SetupWindowDocking()
SLASH_OCTOPOKER1='/orp';SLASH_OCTOPOKER2='/octopoker'
SLASH_POKER1='/poker'
SlashCmdList.OCTOPOKER=function(msg)
 if msg=='debug' then
  debugLog('STATUS me='..me()..' leader='..tostring(leader())..' raid='..tostring(raidCount())..' phase='..phase..' hand='..tostring(table.getn(myCards))..' session='..session)
  debugOffset=0;refreshDebug();debugFrame:Show()
  return
 end
 if msg=='nettest' then runProbes();debugOffset=0;refreshDebug();debugFrame:Show();return end
 local _,_,who,gold=string.find(msg or '', '^balance%s+(%S+)%s+(%d+)$')
 if who and gold then
  if not isLeader() or (phase=='DRAW' or bettingPhase()) then notice('Balance changes require idle Raid Leader.');return end
  local value=tonumber(gold)
  OctoPokerBank.Set(who,value)
  return
 end
 if msg=='stats' then G.ShowStats();return end
 if msg=='balances' then OctoPokerBank.Refresh();OctoPoker152_bankFrame:Show();return end
 if msg=='sync' then requestSync();return end
 if frame:IsShown()then frame:Hide()else frame:Show()end
end
-- /poker is the main entry point for settings and full reset.
SlashCmdList.POKER=function(msg)
 local command=string.lower(string.gsub(msg or '', '^%s*(.-)%s*$', '%1'))
 if command=='reseticon' then
  OctoPokerDB=OctoPokerDB or {}
  OctoPokerDB.icon={'MINIMAP',-0.25}
  iconDragAngle=-0.25
  OctoPoker152_placeMinimapDefault()
  DEFAULT_CHAT_FRAME:AddMessage('OctoPoker: icon reset to minimap.')
  return
 end
 if command=='settings' then refreshSoundSettings();settingsFrame:Show();return end
 if command=='resetall' then
  if isLeader() then StaticPopup_Show('OCTOPOKER_RESET_ALL')
  else notice('Only Raid Leader can reset all data.') end
  return
 end
 SlashCmdList.OCTOPOKER(msg)
end
-- Clients may join or reload after a hand has started. Ask the leader for the
-- current state once after login and on raid roster changes, without spamming.
frame:SetScript('OnUpdate',function()
  if isLeader() and phase=='SHOWDOWN' and G.finalWire and (G.finalResends or 0)>0 and GetTime()>=(G.finalNextSend or 0) then
   send('WINEND',session..';'..G.finalWire)
   G.finalResends=G.finalResends-1;G.finalNextSend=GetTime()+2
  end
  if phase=='SHOWDOWN' and not isLeader() and session~='' and (not G.remoteResult or G.inferredResult) then
  if not G.nextResultRequest or GetTime()>=G.nextResultRequest then
   G.nextResultRequest=GetTime()+3
   send('GETRESULT',session)
  end
 end
 if not isLeader() and raidCount()>1 and GetTime()-lastSyncAt>60 then
  if session=='' or ((phase=='DRAW' or bettingPhase()) and table.getn(myCards)~=5) then
   lastSyncAt=GetTime()
   requestSync()
  end
 end
end)
notice('Loading...');render()
