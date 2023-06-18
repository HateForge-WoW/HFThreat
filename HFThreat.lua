local _G, _ = _G or getfenv()

-- todo tankmode messages to send if guid is target, for tankmode highlight
-- todo save HFT_SPEC per sender so it caches from other people's inspects

local __lower = string.lower
local __repeat = string.rep
local __strlen = string.len
local __find = string.find
local __substr = string.sub
local __parseint = tonumber
local __parsestring = tostring
local __getn = table.getn
local __tinsert = table.insert
local __tsort = table.sort
local __pairs = pairs
local __floor = math.floor
local __abs = abs
local __char = string.char

local HFT = CreateFrame("Frame")

HFT.addonVer = '1.2.3'

HFT.threatApi = 'HFTv4=';
HFT.tankModeApi = 'TMTv1=';
HFT.UDTS = 'HFT_UDTSv4';

HFT.showedUpdateNotification = false
HFT.addonName = '|cffabd473HF|cff11cc11 |cffcdfe00Threatmeter'

HFT.prefix = 'HFT'
HFT.channel = 'RAID'

HFT.name = UnitName('player')
local _, cl = UnitClass('player')
HFT.class = __lower(cl)

HFT.lastAggroWarningSoundTime = 0
HFT.lastAggroWarningGlowTime = 0

HFT.AGRO = '-Pull Aggro at-'
HFT.threatsFrames = {}

HFT.threats = {}

HFT.targetName = ''
HFT.relayTo = {}
HFT.shouldRelay = false
HFT.healerMasterTarget = ''

HFT.updateSpeed = 1

HFT.targetFrameVisible = false
HFT.PFUItargetFrameVisible = false

HFT.nameLimit = 30
HFT.windowStartWidth = 300
HFT.windowWidth = 300
HFT.minBars = 5
HFT.maxBars = 11

HFT.roles = {}
HFT.spec = {}

HFT.tankModeThreats = {}

HFT.custom = {
    ['The Prophet Skeram'] = 0
}

HFT.withAddon = 0
HFT.addonStatus = {}

HFT.classColors = {
    ["warrior"] = { r = 0.78, g = 0.61, b = 0.43, c = "|cffc79c6e" },
    ["mage"] = { r = 0.41, g = 0.8, b = 0.94, c = "|cff69ccf0" },
    ["rogue"] = { r = 1, g = 0.96, b = 0.41, c = "|cfffff569" },
    ["druid"] = { r = 1, g = 0.49, b = 0.04, c = "|cffff7d0a" },
    ["hunter"] = { r = 0.67, g = 0.83, b = 0.45, c = "|cffabd473" },
    ["shaman"] = { r = 0.14, g = 0.35, b = 1.0, c = "|cff0070de" },
    ["priest"] = { r = 1, g = 1, b = 1, c = "|cffffffff" },
    ["warlock"] = { r = 0.58, g = 0.51, b = 0.79, c = "|cff9482c9" },
    ["paladin"] = { r = 0.96, g = 0.55, b = 0.73, c = "|cfff58cba" },
    ["agro"] = { r = 0.96, g = 0.1, b = 0.1, c = "|cffff1111" }
}

HFT.classCoords = {
    ["priest"] = { 0.52, 0.73, 0.27, 0.48 },
    ["mage"] = { 0.23, 0.48, 0.02, 0.23 },
    ["warlock"] = { 0.77, 0.98, 0.27, 0.48 },
    ["rogue"] = { 0.48, 0.73, 0.02, 0.23 },
    ["druid"] = { 0.77, 0.98, 0.02, 0.23 },
    ["hunter"] = { 0.02, 0.23, 0.27, 0.48 },
    ["shaman"] = { 0.27, 0.48, 0.27, 0.48 },
    ["warrior"] = { 0.02, 0.23, 0.02, 0.23 },
    ["paladin"] = { 0.02, 0.23, 0.52, 0.73 },
}

HFT.fonts = {
    'BalooBhaina', 'BigNoodleTitling',
    'Expressway', 'Homespun', 'Hooge', 'LondrinaSolid',
    'Myriad-Pro', 'PT-Sans-Narrow-Bold', 'PT-Sans-Narrow-Regular',
    'Roboto', 'Share', 'ShareBold',
    'Sniglet', 'SquadaOne',
}

HFT.updateSpeeds = {
    ['warrior'] = { 0.7, 0.5, 0.5 },
    ['paladin'] = { 1, 0.5, 0.7 },
    ['hunter'] = { 0.7, 0.7, 0.7 },
    ['rogue'] = { 0.5, 0.5, 0.5 },
    ['priest'] = { 1, 1, 0.6 },
    ['shaman'] = { 0.7, 0.5, 1 },
    ['mage'] = { 1, 0.5, 0.7 },
    ['warlock'] = { 0.8, 1, 0.6 },
    ['druid'] = { 0.8, 0.5, 1 },
}

function HFTprint(a)
    if a == nil then
        DEFAULT_CHAT_FRAME:AddMessage('[HFT]|cff0070de:' .. GetTime() .. '|cffffffff attempt to print a nil value.')
        return false
    end
    DEFAULT_CHAT_FRAME:AddMessage(HFT.classColors[HFT.class].c .. "[HFT] |cffffffff" .. a)
end

function HFTdebug(a)
    local time = GetTime() + 0.0001
    if not HFT_CONFIG.debug then
        return false
    end
    if a == nil then
        HFTprint('|cff0070de[HFTDEBUG:' .. time .. ']|cffffffff attempt to print a nil value.')
        return
    end
    if type(a) == 'boolean' then
        if a then
            HFTprint('|cff0070de[HFTDEBUG:' .. time .. ']|cffffffff[true]')
        else
            HFTprint('|cff0070de[HFTDEBUG:' .. time .. ']|cffffffff[false]')
        end
        return true
    end
    HFTprint('|cff0070de[D:' .. time .. ']|cffffffff[' .. a .. ']')
end

SLASH_HFT1 = "/HFT"
SlashCmdList["HFT"] = function(cmd)
    if cmd then
        if __substr(cmd, 1, 4) == 'show' then
            _G['HFTMain']:Show()
            HFT_CONFIG.visible = true
            return true
        end
        if __substr(cmd, 1, 8) == 'tankmode' then
            if HFT_CONFIG.tankMode then
                HFTprint('Tank Mode is already enabled.')
                return false
            else
                HFT_CONFIG.tankMode = true
                HFTprint('Tank Mode enabled.')
            end
            return true
        end
        if __substr(cmd, 1, 6) == 'skeram' then
            if HFT_CONFIG.skeram then
                HFT_CONFIG.skeram = false
                HFTprint('Skeram module disabled.')
                return true
            end
            HFT_CONFIG.skeram = true
            HFTprint('Skeram module enabled.')
            return true
        end
        if __substr(cmd, 1, 5) == 'debug' then
            if HFT_CONFIG.debug then
                HFT_CONFIG.debug = false
                _G['pps']:Hide()
                HFTprint('Debugging disabled')
                return true
            end
            HFT_CONFIG.debug = true
            _G['pps']:Show()
            HFTdebug('Debugging enabled')
            return true
        end

        if __substr(cmd, 1, 3) == 'who' then
            HFT.queryWho()
            return true
        end

        HFTprint(HFT.addonName .. ' |cffabd473v' .. HFT.addonVer .. '|cffffffff available commands:')
        HFTprint('/HFT show - shows the main window (also /HFTshow)')
    end
end

SLASH_HFTSHOW1 = "/HFTshow"
SlashCmdList["HFTSHOW"] = function(cmd)
    if cmd then
        _G['HFTMain']:Show()
        HFT_CONFIG.visible = true
    end
end

SLASH_HFTDEBUG1 = "/HFTdebug"
SlashCmdList["HFTDEBUG"] = function(cmd)
    if cmd then
        if HFT_CONFIG.debug then
            HFT_CONFIG.debug = false
            HFTprint('Debugging disabled')
            return true
        end
        HFT_CONFIG.debug = true
        HFTdebug('Debugging enabled')
        return true
    end
end

HFT:RegisterEvent("ADDON_LOADED")
HFT:RegisterEvent("CHAT_MSG_ADDON")
HFT:RegisterEvent("PLAYER_REGEN_DISABLED")
HFT:RegisterEvent("PLAYER_REGEN_ENABLED")
HFT:RegisterEvent("PLAYER_TARGET_CHANGED")
HFT:RegisterEvent("PLAYER_ENTERING_WORLD")
HFT:RegisterEvent("PARTY_MEMBERS_CHANGED")

HFT.threatQuery = CreateFrame("Frame")
HFT.threatQuery:Hide()

local timeStart = GetTime()
local totalPackets = 0
local totalData = 0
local uiUpdates = 0

HFT:SetScript("OnEvent", function()
    if event then
        if event == 'ADDON_LOADED' and arg1 == 'HFThreat' then
            return HFT.init()
        end
        if event == "PARTY_MEMBERS_CHANGED" then
            return HFT.getClasses()
        end
        if event == "PLAYER_ENTERING_WORLD" then
            HFT.sendMyVersion()
            HFT.combatEnd()
            if UnitAffectingCombat('player') then
                HFT.combatStart()
            end
            return true
        end
        if event == 'CHAT_MSG_ADDON' and __find(arg2, HFT.threatApi, 1, true) then

            totalPackets = totalPackets + 1
            totalData = totalData + __strlen(arg2)

            local threatData = arg2
            if __find(threatData, '#') and __find(threatData, HFT.tankModeApi) then
                local packetEx = __explode(threatData, '#')
                if packetEx[1] and packetEx[2] then
                    threatData = packetEx[1]
                    HFT.handleTankModePacket(packetEx[2])
                end
            end

            return HFT.handleThreatPacket(threatData)
        end
        if event == 'CHAT_MSG_ADDON' and arg1 == HFT.prefix then

            if __substr(arg2, 1, 11) == 'HFTVersion:' and arg4 ~= HFT.name then
                if not HFT.showedUpdateNotification then
                    local verEx = __explode(arg2, ':')
                    if HFT.version(verEx[2]) > HFT.version(HFT.addonVer) then
                        HFTprint('New version available ' ..
                                HFT.classColors[HFT.class].c .. 'v' .. verEx[2] .. ' |cffffffff(current version ' ..
                                HFT.classColors['paladin'].c .. 'v' .. HFT.addonVer .. '|cffffffff)')
                        HFTprint('Update at ' .. HFT.classColors[HFT.class].c .. 'https://github.com/CosminPOP/HFThreat')
                        HFT.showedUpdateNotification = true
                    end
                end
                return true
            end

            if __substr(arg2, 1, 7) == 'HFT_WHO' then
                HFT.send('HFT_ME:' .. HFT.addonVer)
                return true
            end

            if __substr(arg2, 1, 15) == 'HFTRoleTexture:' then
                local tex = __explode(arg2, ':')[2] or ''
                HFT.roles[arg4] = tex
                return true
            end

            if __substr(arg2, 1, 7) == 'HFT_ME:' then

                if HFT.addonStatus[arg4] then

                    local msg = __explode(arg2, ':')[2]
                    local verColor = ""
                    if HFT.version(msg) == HFT.version(HFT.addonVer) then
                        verColor = HFT.classColors['hunter'].c
                    end
                    if HFT.version(msg) < HFT.version(HFT.addonVer) then
                        verColor = '|cffff1111'
                    end
                    if HFT.version(msg) + 1 == HFT.version(HFT.addonVer) then
                        verColor = '|cffff8810'
                    end

                    HFT.addonStatus[arg4]['v'] = '    ' .. verColor .. msg
                    HFT.withAddon = HFT.withAddon + 1

                    HFT.updateWithAddon()

                    return true
                end

                return false
            end

            return false

        end
        if event == "PLAYER_REGEN_DISABLED" then
            return HFT.combatStart()
        end
        if event == "PLAYER_REGEN_ENABLED" then
            return HFT.combatEnd()
        end
        if event == "PLAYER_TARGET_CHANGED" then

            if not HFT.targetChanged() then
                HFT.hideThreatFrames(true)
            end

            return true

        end
    end
end)

function QueryWho_OnClick()
    HFT.queryWho()
end

function HFT.queryWho()
    HFT.withAddon = 0
    HFT.addonStatus = {}
    for i = 0, GetNumRaidMembers() do
        if GetRaidRosterInfo(i) then
            local n, _, _, _, _, _, z = GetRaidRosterInfo(i);
            local _, class = UnitClass('raid' .. i)

            HFT.addonStatus[n] = {
                ['class'] = __lower(class),
                ['v'] = '|cff888888   -   '
            }
            if z == 'Offline' then
                HFT.addonStatus[n]['v'] = '|cffff0000offline'
            end
        end
    end
    HFTprint('Sending who query...')
    _G['HFTWithAddonList']:Show()
    HFT.send('HFT_WHO')
end

function HFT.updateWithAddon()

    local rosterList = ''
    local i = 0
    for n, data in next, HFT.addonStatus do
        i = i + 1
        rosterList = rosterList .. HFT.classColors[data['class']].c .. n .. __repeat(' ', 12 - __strlen(n)) .. ' ' .. data['v'] .. ' |cff888888'
        if i < 4 then
            rosterList = rosterList .. '| '
        end
        if i == 4 then
            rosterList = rosterList .. '\n'
            i = 0
        end
    end
    _G['HFTWithAddonListText']:SetText(rosterList)
    _G['HFTWithAddonListTitle']:SetText('Addon Raid Status ' .. HFT.withAddon .. '/' .. GetNumRaidMembers())
end

HFT.glowFader = CreateFrame('Frame')
HFT.glowFader:Hide()

HFT.glowFader:SetScript("OnShow", function()
    this.startTime = GetTime() - 1
    this.dir = 10
    _G['HFTFullScreenGlow']:SetAlpha(0.01)
    _G['HFTFullScreenGlow']:Show()
end)
HFT.glowFader:SetScript("OnHide", function()
    this.startTime = GetTime()
end)
HFT.glowFader:SetScript("OnUpdate", function()
    local plus = 0.04
    local gt = GetTime() * 1000
    local st = (this.startTime + plus) * 1000
    if gt >= st then
        this.startTime = GetTime()

        if _G['HFTFullScreenGlow']:GetAlpha() >= 0.6 then
            this.dir = -1
        end

        _G['HFTFullScreenGlow']:SetAlpha(_G['HFTFullScreenGlow']:GetAlpha() + 0.03 * this.dir)

        if _G['HFTFullScreenGlow']:GetAlpha() <= 0 then
            HFT.glowFader:Hide()
        end


    end
end)

function HFT.init()

    if not HFT_CONFIG then
        HFT_CONFIG = {
            visible = true,
            colTPS = true,
            colThreat = true,
            colPerc = true,
            labelRow = true,
        }
    end

    HFT_CONFIG.windowScale = HFT_CONFIG.windowScale or 1
    HFT_CONFIG.glow = HFT_CONFIG.glow or false
    HFT_CONFIG.perc = HFT_CONFIG.perc or false
    HFT_CONFIG.glowPFUI = HFT_CONFIG.glowPFUI or false
    HFT_CONFIG.percPFUI = HFT_CONFIG.percPFUI or false
    HFT_CONFIG.percPFUItop = HFT_CONFIG.percPFUItop or false
    HFT_CONFIG.percPFUIbottom = HFT_CONFIG.percPFUIbottom or false
    HFT_CONFIG.showInCombat = HFT_CONFIG.showInCombat or false
    HFT_CONFIG.hideOOC = HFT_CONFIG.hideOOC or false
    HFT_CONFIG.font = HFT_CONFIG.font or 'Roboto'
    HFT_CONFIG.barHeight = HFT_CONFIG.barHeight or 20
    HFT_CONFIG.visibleBars = HFT_CONFIG.visibleBars or HFT.minBars
    HFT_CONFIG.fullScreenGlow = HFT_CONFIG.fullScreenGlow or false
    HFT_CONFIG.aggroSound = HFT_CONFIG.aggroSound or false
    HFT_CONFIG.aggroThreshold = HFT_CONFIG.aggroThreshold or 85
    HFT_CONFIG.tankMode = HFT_CONFIG.tankMode or false
    HFT_CONFIG.tankModeStick = HFT_CONFIG.tankModeStick or 'Free' -- Top, Right, Left, Right, Free
    HFT_CONFIG.lock = HFT_CONFIG.lock or false
    HFT_CONFIG.visible = HFT_CONFIG.visible or false
    HFT_CONFIG.colTPS = HFT_CONFIG.colTPS or false
    HFT_CONFIG.colThreat = HFT_CONFIG.colThreat or false
    HFT_CONFIG.colPerc = HFT_CONFIG.colPerc or false
    HFT_CONFIG.labelRow = HFT_CONFIG.labelRow or false
    HFT_CONFIG.skeram = HFT_CONFIG.skeram or false

    HFT_CONFIG.combatAlpha = HFT_CONFIG.combatAlpha or 1
    HFT_CONFIG.oocAlpha = HFT_CONFIG.oocAlpha or 1

    if HFT.class ~= 'paladin' and HFT.class ~= 'warrior' and HFT.class ~= 'druid' then
        _G['HFTMainSettingsTankMode']:Disable()
        HFT_CONFIG.tankMode = false
    end

    HFT_CONFIG.debug = HFT_CONFIG.debug or false

    if HFT_CONFIG.visible then
        _G['HFTMain']:Show()
    else
        _G['HFTMain']:Hide()
    end

    if HFT_CONFIG.tankMode then
        _G['HFTMainSettingsFullScreenGlow']:SetChecked(HFT_CONFIG.fullScreenGlow)
        _G['HFTMainSettingsFullScreenGlow']:Disable()
        _G['HFTMainSettingsAggroSound']:SetChecked(HFT_CONFIG.fullScreenGlow)
        _G['HFTMainSettingsAggroSound']:Disable()
    end

    if HFT_CONFIG.lock then
        _G['HFTMainLockButton']:SetNormalTexture('Interface\\addons\\HFThreat\\images\\icon_locked')
    else
        _G['HFTMainLockButton']:SetNormalTexture('Interface\\addons\\HFThreat\\images\\icon_unlocked')
    end

    _G['HFTFullScreenGlowTexture']:SetWidth(GetScreenWidth())
    _G['HFTFullScreenGlowTexture']:SetHeight(GetScreenHeight())

    _G['HFTMain']:SetHeight(HFT_CONFIG.barHeight * HFT_CONFIG.visibleBars + (HFT_CONFIG.labelRow and 40 or 20))

    _G['HFTMainSettingsFrameHeightSlider']:SetValue(HFT_CONFIG.barHeight) -- calls FrameHeightSlider_OnValueChanged()
    _G['HFTMainSettingsWindowScaleSlider']:SetValue(HFT_CONFIG.windowScale) -- calls FrameHeightSlider_OnValueChanged()

    _G['HFTMainSettingsCombatAlphaSlider']:SetValue(HFT_CONFIG.combatAlpha) -- calls CombatOpacitySlider_OnValueChanged()
    _G['HFTMainSettingsOOCAlphaSlider']:SetValue(HFT_CONFIG.oocAlpha) -- calls OOCombatSlider_OnValueChanged()

    _G['HFTMainSettingsAggroThresholdSlider']:SetValue(HFT_CONFIG.aggroThreshold) -- calls AggroThresholdSlider_OnValueChanged()

    _G['HFTMainSettingsFontButton']:SetText(HFT_CONFIG.font)

    _G['HFTMainSettingsTargetFrameGlow']:SetChecked(HFT_CONFIG.glow)
    _G['HFTMainSettingsTargetFrameGlowPFUI']:SetChecked(HFT_CONFIG.glowPFUI)
    _G['HFTMainSettingsPercNumbers']:SetChecked(HFT_CONFIG.perc)
    _G['HFTMainSettingsPercNumbersPFUI']:SetChecked(HFT_CONFIG.percPFUI)
    _G['HFTMainSettingsPercNumbersPFUItop']:SetChecked(HFT_CONFIG.percPFUItop)
    _G['HFTMainSettingsPercNumbersPFUIbottom']:SetChecked(HFT_CONFIG.percPFUIbottom)
    _G['HFTMainSettingsShowInCombat']:SetChecked(HFT_CONFIG.showInCombat)
    _G['HFTMainSettingsHideOOC']:SetChecked(HFT_CONFIG.hideOOC)
    _G['HFTMainSettingsFullScreenGlow']:SetChecked(HFT_CONFIG.fullScreenGlow)
    _G['HFTMainSettingsAggroSound']:SetChecked(HFT_CONFIG.aggroSound)
    _G['HFTMainSettingsTankMode']:SetChecked(HFT_CONFIG.tankMode)

    _G['HFTMainSettingsColumnsTPS']:SetChecked(HFT_CONFIG.colTPS)
    _G['HFTMainSettingsColumnsThreat']:SetChecked(HFT_CONFIG.colThreat)
    _G['HFTMainSettingsColumnsPercent']:SetChecked(HFT_CONFIG.colPerc)

    _G['HFTMainSettingsLabelRow']:SetChecked(HFT_CONFIG.labelRow)

    HFT.setColumnLabels()

    if HFT_CONFIG.labelRow then
        _G['HFTMainBarsBG']:SetPoint('TOPLEFT', 1, -40)
        _G['HFTMainNameLabel']:Show()
    else
        _G['HFTMainBarsBG']:SetPoint('TOPLEFT', 1, -20)
        _G['HFTMainNameLabel']:Hide()
        _G['HFTMainTPSLabel']:Hide()
        _G['HFTMainThreatLabel']:Hide()
        _G['HFTMainPercLabel']:Hide()
    end

    _G['HFTMainSettingsFontButtonNT']:SetVertexColor(0.4, 0.4, 0.4)

    local color = HFT.classColors[HFT.class]

    _G['HFTMainTitleBG']:SetVertexColor(color.r, color.g, color.b)
    _G['HFTMainSettingsTitleBG']:SetVertexColor(color.r, color.g, color.b)
    _G['HFTMainTankModeWindowTitleBG']:SetVertexColor(color.r, color.g, color.b)

    _G['HFThreatDisplayTarget']:SetScale(UIParent:GetScale())

    -- fonts
    local fontFrames = {}

    for i, font in HFT.fonts do
        fontFrames[i] = CreateFrame('Button', 'Font_' .. font, _G['HFTMainSettingsFontList'], 'HFTFontFrameTemplate')

        fontFrames[i]:SetPoint("TOPLEFT", _G["HFTMainSettingsFontList"], "TOPLEFT", 0, 17 - i * 17)

        _G['Font_' .. font]:SetID(i)
        _G['Font_' .. font .. 'Name']:SetFont("Interface\\addons\\HFThreat\\fonts\\" .. font .. ".ttf", 15)
        _G['Font_' .. font .. 'Name']:SetText(font)
        _G['Font_' .. font .. 'HT']:SetVertexColor(1, 1, 1, 0.5)

        fontFrames[i]:Show()
    end

    --UnitPopupButtons["INSPECT_TALENTS"] = { text = 'Inspect Talents', dist = 0 }
    --
    --HFT.addInspectMenu("PARTY")
    --HFT.addInspectMenu("PLAYER")
    --HFT.addInspectMenu("RAID")
    --
    --HFT.hooksecurefunc("UnitPopup_OnClick", function()
    --    local button = this.value
    --    if button == "INSPECT_TALENTS" then
    --
    --        _G['HFTTalentFrame']:Hide()
    --
    --        HFT_SPEC = {
    --            class = UnitClass('target'),
    --            {
    --                name = 'Arms',
    --                iconTexture = 'interface\\icons\\ability_warrior_cleave',
    --                pointsSpent = 27,
    --                numTalents = 18
    --            },
    --            {
    --                name = 'Fury',
    --                iconTexture = 'interface\\icons\\ability_warrior_cleave',
    --                pointsSpent = 24,
    --                numTalents = 17
    --            },
    --            {
    --                name = 'Protection',
    --                iconTexture = 'interface\\icons\\ability_warrior_cleave',
    --                pointsSpent = 0,
    --                numTalents = 17
    --            }
    --        }
    --
    --        HFT.send('HFTShowTalents:' .. UnitName('target'))
    --
    --    end
    --end)
    --
    --UIParentLoadAddOn("Blizzard_TalentUI")

    HFT.updateTitleBarText()
    HFT.updateSettingsTabs(1)

    HFT.checkTargetFrames()

    HFTprint(HFT.addonName .. ' |cffabd473v' .. HFT.addonVer .. '|cffffffff loaded.')
    return true
end

function HFT.updateSettingsTabs(tab)
    local color = HFT.classColors[HFT.class]
    _G['HFTMainSettingsTabsUnderline']:SetVertexColor(color.r, color.g, color.b)

    for i = 1, 3 do
        _G['HFTMainSettingsTab' .. i]:Hide()
        _G['HFTMainSettingsTab' .. i .. 'ButtonNT']:SetVertexColor(color.r, color.g, color.b, 0.4)
        _G['HFTMainSettingsTab' .. i .. 'ButtonHT']:SetVertexColor(color.r, color.g, color.b, 0.4)
        _G['HFTMainSettingsTab' .. i .. 'ButtonPT']:SetVertexColor(color.r, color.g, color.b, 0.4)
        _G['HFTMainSettingsTab' .. i .. 'ButtonText']:SetTextColor(0.4, 0.4, 0.4)
    end

    _G['HFTMainSettingsTab' .. tab .. 'ButtonNT']:SetVertexColor(color.r, color.g, color.b, 1)
    _G['HFTMainSettingsTab' .. tab .. 'ButtonText']:SetTextColor(1, 1, 1)

    _G['HFTMainSettingsTab' .. tab]:Show()

end

function HFTSettingsTab_OnClick(tab)
    HFT.updateSettingsTabs(tab)
end

function HFTHealerMasterTarget_OnClick()

    HFT.getClasses()

    if not UnitExists('target') or not UnitIsPlayer('target')
            or UnitName('target') == HFT.name then

        if HFT.healerMasterTarget == '' then
            HFTprint('Please target a tank.')
        else
            HFT.removeHealerMasterTarget()
        end

        return false
    end

    if UnitName('target') == HFT.healerMasterTarget then
        return HFT.removeHealerMasterTarget()
    end

    HFT.send('HFT_HMT:' .. UnitName('target'))

    local color = HFT.classColors[HFT.getClass(UnitName('target'))]

    HFTprint('Trying to set Healer Master Target to ' .. color.c .. UnitName('target'))

end

function HFT.removeHealerMasterTarget()
    HFT.send('HFT_HMT_REM:' .. HFT.healerMasterTarget)

    HFTprint('Healer Master Target cleared.')

    HFT.healerMasterTarget = ''
    HFT.targetName = ''

    HFT.threats = HFT.wipe(HFT.threats)

    _G['HFTMainSettingsHealerMasterTargetButton']:SetText('From Target')
    _G['HFTMainSettingsHealerMasterTargetButtonNT']:SetVertexColor(1, 1, 1, 1)

    HFT.updateUI('removeHealerMasterTarget')

    return true
end

function HFT.addInspectMenu(to)
    local found = 0
    for i, j in UnitPopupMenus[to] do
        if j == "TRADE" then
            found = i
        end
    end
    if found ~= 0 then
        UnitPopupMenus[to][__getn(UnitPopupMenus[to]) + 1] = UnitPopupMenus[to][__getn(UnitPopupMenus[to])]
        for i = __getn(UnitPopupMenus[to]) - 1, found, -1 do
            UnitPopupMenus[to][i] = UnitPopupMenus[to][i - 1]
        end
    end
    UnitPopupMenus[to][found] = "INSPECT_TALENTS"
end

HFT.classes = {}

function HFT.getClass(name)
    return HFT.classes[name] or 'priest'
end

function HFT.getClasses()
    if HFT.channel == 'RAID' then
        for i = 0, GetNumRaidMembers() do
            if GetRaidRosterInfo(i) then
                local name = GetRaidRosterInfo(i)
                local _, raidCls = UnitClass('raid' .. i)
                HFT.classes[name] = __lower(raidCls)
            end
        end
    end
    if HFT.channel == 'PARTY' then
        if GetNumPartyMembers() > 0 then
            for i = 1, GetNumPartyMembers() do
                if UnitName('party' .. i) and UnitClass('party' .. i) then
                    local name = UnitName('party' .. i)
                    local _, raidCls = UnitClass('party' .. i)
                    HFT.classes[name] = __lower(raidCls)
                end
            end
        end
    end
    HFTdebug('classes saved')
    return true
end

HFT.history = {}

HFT.tankName = ''

function HFT.handleThreatPacket(packet)

    --HFTdebug(packet)

    local playersString = __substr(packet, __find(packet, HFT.threatApi) + __strlen(HFT.threatApi), __strlen(packet))

    HFT.threats = HFT.wipe(HFT.threats)
    HFT.tankName = ''

    local players = __explode(playersString, ';')

    for _, tData in players do

        local msgEx = __explode(tData, ':')

        -- udts handling
        if msgEx[1] and msgEx[2] and msgEx[3] and msgEx[4] and msgEx[5] then

            local player = msgEx[1]
            local tank = msgEx[2] == '1'
            local threat = __parseint(msgEx[3])
            local perc = __parseint(msgEx[4])
            local melee = msgEx[5] == '1'

            if UnitName('target') and not UnitIsPlayer('target') and HFT.shouldRelay then
                --relay
                for i, name in HFT.relayTo do
                    HFTdebug('relaying to ' .. i .. ' ' .. name)
                end
                HFT.send('HFTRelayV1' ..
                        ':' .. UnitName('target') ..
                        ':' .. player ..
                        ':' .. msgEx[3] ..
                        ':' .. threat ..
                        ':' .. perc ..
                        ':' .. msgEx[6]);
            end

            local time = time()

            if HFT.history[player] then
                HFT.history[player][time] = threat
            else
                HFT.history[player] = {}
            end

            HFT.threats[player] = {
                threat = threat,
                tank = tank,
                perc = perc,
                melee = melee,
                tps = HFT.calcTPS(player),
                class = HFT.getClass(player)
            }

            if tank then
                HFT.tankName = player
            end
        end
    end

    HFT.calcAGROPerc()

    HFT.updateUI()

end

function HFT.handleTankModePacket(packet)

    --HFTdebug(msg)

    local playersString = __substr(packet, __find(packet, HFT.tankModeApi) + __strlen(HFT.tankModeApi), __strlen(packet))

    HFT.tankModeThreats = HFT.wipe(HFT.tankModeThreats)

    local players = __explode(playersString, ';')

    for _, tData in players do

        local msgEx = __explode(tData, ':')

        if msgEx[1] and msgEx[2] and msgEx[3] and msgEx[4] then

            local creature = msgEx[1]
            local guid = msgEx[2] --keep it string
            local name = msgEx[3]
            local perc = __parseint(msgEx[4])

            HFT.tankModeThreats[guid] = {
                creature = creature,
                name = name,
                perc = perc
            }

            --HFT.updateUI('handleTMServerMSG')

        end

    end

end

function HFT.calcAGROPerc()

    local tankThreat = 0
    for _, data in next, HFT.threats do
        if data.tank then
            tankThreat = data.threat
            break
        end
    end

    HFT.threats[HFT.AGRO] = {
        class = 'agro',
        threat = 0,
        perc = 100,
        tps = '',
        history = {},
        tank = false,
        melee = false
    }

    if not HFT.threats[HFT.name] then
        HFTdebug('threats de name is bad')
        return false
    end

    HFT.threats[HFT.AGRO].threat = tankThreat * (HFT.threats[HFT.name].melee and 1.1 or 1.3)
    if HFT.threats[HFT.AGRO].threat == 0 then
        HFT.threats[HFT.AGRO].threat = 1
    end
    HFT.threats[HFT.AGRO].perc = HFT.threats[HFT.name].melee and 110 or 130

end

function HFT.combatStart()

    HFT.updateTargetFrameThreatIndicators(-1, '')
    timeStart = GetTime()
    totalPackets = 0
    totalData = 0

    --HFTdebug('wipe threats combatstart')
    --HFT.threats = HFT.wipe(HFT.threats)
    --HFT.tankModeThreats = HFT.wipe(HFT.tankModeThreats)
    HFT.hideThreatFrames(true)
    HFT.shouldRelay = HFT.checkRelay()

    if GetNumRaidMembers() == 0 and GetNumPartyMembers() == 0 then
        return false
    end

    if HFT_CONFIG.showInCombat then
        _G['HFTMain']:Show()
    end

    HFT.spec = {}
    for t = 1, GetNumTalentTabs() do
        HFT.spec[t] = {
            talents = 0,
            texture = ''
        }
        for i = 1, GetNumTalents(t) do
            local _, _, _, _, currRank = GetTalentInfo(t, i);
            HFT.spec[t].talents = HFT.spec[t].talents + currRank
        end
    end

    local specIndex = 1
    for i = 2, 4 do
        local name, texture = GetSpellTabInfo(i);
        if name and texture then
            HFT.spec[specIndex].name = name
            texture = __explode(texture, '\\')
            texture = texture[__getn(texture)]
            HFT.spec[specIndex].texture = texture
            specIndex = specIndex + 1
        end
    end

    local sendTex = HFT.spec[1].texture
    HFT.updateSpeed = HFT.updateSpeeds[HFT.class][1]
    if HFT.spec[2].talents > HFT.spec[1].talents and HFT.spec[2].talents > HFT.spec[3].talents then
        sendTex = HFT.spec[2].texture
        HFT.updateSpeed = HFT.updateSpeeds[HFT.class][2]
    end
    if HFT.spec[3].talents > HFT.spec[1].talents and HFT.spec[3].talents > HFT.spec[2].talents then
        sendTex = HFT.spec[3].texture
        HFT.updateSpeed = HFT.updateSpeeds[HFT.class][3]
    end

    if HFT.class == 'warrior' and __lower(sendTex) == 'ability_rogue_eviscerate' then
        sendTex = 'ability_warrior_savageblow' --ms
    end

    HFT.send('HFTRoleTexture:' .. sendTex)

    HFT.getClasses()

    HFT.updateUI('combatStart')

    HFT.threatQuery:Show()
    HFT.barAnimator:Show()

    HFTTankModeWindowChangeStick_OnClick()

    _G['HFTMain']:SetAlpha(HFT_CONFIG.combatAlpha)

    return true
end

function HFT.combatEnd()

    HFT.updateTargetFrameThreatIndicators(-1, '')

    HFTdebug('time = ' .. (HFT.round(GetTime() - timeStart)) .. 's packets = ' .. totalPackets .. ' ' ..
            totalPackets / (GetTime() - timeStart) .. ' packets/s')

    timeStart = GetTime()
    totalPackets = 0
    totalData = 0

    HFTdebug('wipe threats combat end')

    HFT.threats = HFT.wipe(HFT.threats)
    HFT.tankModeThreats = HFT.wipe(HFT.tankModeThreats)
    HFT.history = HFT.wipe(HFT.history)

    if HFT_CONFIG.hideOOC then
        _G['HFTMain']:Hide()
    end

    HFT.updateUI('combatEnd')

    HFT.threatQuery:Hide()
    HFT.barAnimator:Hide()

    if HFT_CONFIG.tankMode then
        _G['HFTMainTankModeWindow']:Hide()
    end

    _G['HFTWarning']:Hide()

    HFT.updateTitleBarText()

    _G['HFTMain']:SetAlpha(HFT_CONFIG.oocAlpha)

    HFT.hideThreatFrames(true)

    return true

end

function HFT.checkRelay()

    if GetNumRaidMembers() == 0 and GetNumPartyMembers() == 0 then
        return false
    end

    if __getn(HFT.relayTo) == 0 then
        return false
    end

    -- in raid
    if HFT.channel == 'RAID' and GetNumRaidMembers() > 0 then
        for index, name in HFT.relayTo do
            local found = false
            for i = 0, GetNumRaidMembers() do
                if GetRaidRosterInfo(i) and UnitName('raid' .. i) == name then
                    found = true
                end
            end
            if not found then
                HFT.relayTo[index] = nil
                HFTdebug(name .. ' removed from relay')
            end
        end
    end
    if HFT.channel == 'PARTY' and GetNumPartyMembers() > 0 then
        for index, name in HFT.relayTo do
            local found = false
            for i = 1, GetNumPartyMembers() do
                if UnitName('party' .. i) == name then
                    found = true
                end
            end
            if not found then
                HFT.relayTo[index] = nil
                HFTdebug(name .. ' removed from relay')
            end
        end
    end

    if __getn(HFT.relayTo) == 0 then
        return false
    end

    return true
end

function HFT.checkTargetFrames()
    if _G['TargetFrame']:IsVisible() ~= nil then
        HFT.targetFrameVisible = true
    else
        HFT.targetFrameVisible = false
    end

    if _G['pfTarget'] and _G['pfTarget']:IsVisible() ~= nil then
        HFT.PFUItargetFrameVisible = true
    else
        HFT.PFUItargetFrameVisible = false
    end
end

function HFT.hideThreatFrames(force)
    if HFT.tableSize(HFT.threats) > 0 or force then
        for name in next, HFT.threatsFrames do
            HFT.threatsFrames[name]:Hide()
        end
    end
end

function HFT.targetChanged()

    if not UnitAffectingCombat('player') and _G['HFTMainSettings']:IsVisible() == 1 then
        return true
    end

    HFT.channel = (GetNumRaidMembers() > 0) and 'RAID' or 'PARTY'

    if UIParent:GetScale() ~= _G['HFThreatDisplayTarget']:GetScale() then
        _G['HFThreatDisplayTarget']:SetScale(UIParent:GetScale())
    end

    if HFT.healerMasterTarget ~= '' then
        return true
    end

    HFT.targetName = ''
    HFT.updateTargetFrameThreatIndicators(-1)

    -- lost target
    if not UnitExists('target') then
        return false
    end

    -- target is dead, dont show anything
    if UnitIsDead('target') then
        return false
    end

    -- dont show anything
    if UnitIsPlayer('target') then
        return false
    end

    -- non interesting target
    if UnitClassification('target') ~= 'worldboss' and UnitClassification('target') ~= 'elite' then
        return false
    end

    -- no raid or party
    if GetNumRaidMembers() == 0 and GetNumPartyMembers() == 0 then
        return false
    end

    -- not in combat
    if not UnitAffectingCombat('player') or not UnitAffectingCombat('target') then
        return false
    end

    HFTdebug('wipe target changed')
    HFT.threats = HFT.wipe(HFT.threats)
    HFT.history = HFT.wipe(HFT.history)

    if HFT_CONFIG.skeram then
        -- skeram hax
        --The Prophet Skeram
        --_G['HFTWarning']:Hide()
        --if UnitAffectingCombat('player') then
        --    if UnitName('target') == 'The Prophet Skeram' and HFT.custom['The Prophet Skeram'] ~= 0 then

        --            _G['HFTWarningText']:SetText("|cff00ff00- REAL -");
        --            _G['HFTWarning']:Show()
        --        else
        --            _G['HFTWarningText']:SetText("- CLONE -");
        --            _G['HFTWarning']:Show()
        --        end
        --    end
        --end
    end

    HFT.targetName = HFT.unitNameForTitle(UnitName('target'))

    HFT.updateTitleBarText(HFT.targetName)

    return true
end

function HFT.send(msg)
    SendAddonMessage(HFT.prefix, msg, HFT.channel)
end

function HFT.UnitDetailedThreatSituation(limit)
    SendAddonMessage(HFT.UDTS .. (HFT_CONFIG.tankMode and '_TM' or ''), "limit=" .. limit, HFT.channel)
end

function HFT.updateUI(from)

    --HFTdebug('update ui call from [' .. (from or '') .. ']')

    HFT.checkTargetFrames()

    if HFT_CONFIG.debug then
        _G['pps']:SetText('Traffic: ' .. HFT.round((totalPackets / (GetTime() - timeStart)) * 10) / 10
                .. 'packets/s (' .. HFT.round(totalData / (GetTime() - timeStart)) .. ' cps)'
                .. HFT.round(uiUpdates / (GetTime() - timeStart)) .. ' ups ')
        _G['pps']:Show()
    else
        _G['pps']:Hide()
    end

    uiUpdates = uiUpdates + 1

    if not HFT.barAnimator:IsVisible() then
        HFT.barAnimator:Show()
    end

    HFT.hideThreatFrames()

    if not UnitAffectingCombat('player') and not _G['HFTMainSettings']:IsVisible() then
        HFT.updateTargetFrameThreatIndicators(-1)
        return false
    end

    if HFT.targetName == '' then
        return false
    end

    if _G['HFTMainSettings']:IsVisible() and not UnitAffectingCombat('player') then
        HFT.tankName = 'Tenk'
    end

    local index = 0

    for name, data in HFT.ohShitHereWeSortAgain(HFT.threats, true) do

        if data and HFT.threats[HFT.name] and index < HFT_CONFIG.visibleBars then

            index = index + 1
            if not HFT.threatsFrames[index] then
                HFT.threatsFrames[index] = CreateFrame('Frame', 'HFThreat' .. index, _G["HFTMain"], 'HFThreat')
            end

            _G['HFThreat' .. index]:SetAlpha(HFT_CONFIG.combatAlpha)
            _G['HFThreat' .. index]:SetWidth(HFT.windowWidth - 2)

            _G['HFThreat' .. index .. 'Name']:SetFont("Interface\\addons\\HFThreat\\fonts\\" .. HFT_CONFIG.font .. ".ttf", 15, "OUTLINE")
            _G['HFThreat' .. index .. 'TPS']:SetFont("Interface\\addons\\HFThreat\\fonts\\" .. HFT_CONFIG.font .. ".ttf", 15, "OUTLINE")
            _G['HFThreat' .. index .. 'Threat']:SetFont("Interface\\addons\\HFThreat\\fonts\\" .. HFT_CONFIG.font .. ".ttf", 15, "OUTLINE")
            _G['HFThreat' .. index .. 'Perc']:SetFont("Interface\\addons\\HFThreat\\fonts\\" .. HFT_CONFIG.font .. ".ttf", 15, "OUTLINE")

            _G['HFThreat' .. index]:SetHeight(HFT_CONFIG.barHeight - 1)
            _G['HFThreat' .. index .. 'BG']:SetHeight(HFT_CONFIG.barHeight - 2)

            HFT.threatsFrames[index]:ClearAllPoints()
            HFT.threatsFrames[index]:SetPoint("TOPLEFT", _G["HFTMain"], "TOPLEFT", 0,
                    (HFT_CONFIG.labelRow and -40 or -20) +
                            HFT_CONFIG.barHeight - 1 - index * HFT_CONFIG.barHeight)


            -- icons
            _G['HFThreat' .. index .. 'AGRO']:Hide()
            _G['HFThreat' .. index .. 'Role']:Show()
            if name ~= HFT.AGRO then

                _G['HFThreat' .. index .. 'Role']:SetWidth(HFT_CONFIG.barHeight - 2)
                _G['HFThreat' .. index .. 'Role']:SetHeight(HFT_CONFIG.barHeight - 2)
                _G['HFThreat' .. index .. 'Name']:SetPoint('LEFT', _G['HFThreat' .. index .. 'Role'], 'RIGHT', 1 + (HFT_CONFIG.barHeight / 15), -1)
                if HFT.roles[name] then
                    _G['HFThreat' .. index .. 'Role']:SetTexture('Interface\\Icons\\' .. HFT.roles[name])
                    _G['HFThreat' .. index .. 'Role']:SetTexCoord(0.08, 0.92, 0.08, 0.92)
                    _G['HFThreat' .. index .. 'Role']:Show()
                else
                    _G['HFThreat' .. index .. 'Role']:SetTexture('Interface\\Glues\\CharacterCreate\\UI-CharacterCreate-Classes')
                    _G['HFThreat' .. index .. 'Role']:SetTexCoord(unpack(HFT.classCoords[data.class]))
                end

            else
                _G['HFThreat' .. index .. 'AGRO']:Show()
                _G['HFThreat' .. index .. 'Role']:Hide()
            end


            -- tps
            _G['HFThreat' .. index .. 'TPS']:SetText(data.tps)

            -- labels
            HFT.setBarLabels(_G['HFThreat' .. index .. 'Perc'], _G['HFThreat' .. index .. 'Threat'], _G['HFThreat' .. index .. 'TPS'])

            -- perc
            _G['HFThreat' .. index .. 'Perc']:SetText(HFT.round(data.perc) .. '%')

            if HFT.name ~= HFT.tankName and name == HFT.AGRO then
                _G['HFThreat' .. index .. 'Perc']:SetText(100 - HFT.round(HFT.threats[HFT.name].perc) .. '%')
            end

            -- name
            _G['HFThreat' .. index .. 'Name']:SetText(HFT.classColors['priest'].c .. name)

            -- bar width and color
            local color = HFT.classColors[data.class]

            if name == HFT.name then

                if UnitName('target') ~= 'The Prophet Skeram' then
                    if name == __char(77) .. __lower(__char(79, 77, 79)) and data.perc >= 95 then
                        _G['HFTWarningText']:SetText("- STOP DPS " .. __char(77) .. __lower(__char(79, 77, 79)) .. " -");
                        _G['HFTWarning']:Show()
                    else
                        _G['HFTWarning']:Hide()
                    end
                end

                if HFT_CONFIG.aggroSound and data.perc >= HFT_CONFIG.aggroThreshold and time() - HFT.lastAggroWarningSoundTime > 5
                        and not HFT_CONFIG.fullScreenGlow then
                    PlaySoundFile('Interface\\addons\\HFThreat\\sounds\\warn.ogg')
                    HFT.lastAggroWarningSoundTime = time()
                end

                if HFT_CONFIG.fullScreenGlow and data.perc >= HFT_CONFIG.aggroThreshold and time() - HFT.lastAggroWarningGlowTime > 5 then
                    HFT.glowFader:Show()
                    HFT.lastAggroWarningGlowTime = time()
                    if HFT_CONFIG.aggroSound then
                        PlaySoundFile('Interface\\addons\\HFThreat\\sounds\\warn.ogg')
                    end
                end

                HFT.updateTitleBarText(HFT.targetName .. ' (' .. HFT.round(data.perc) .. '%)')

                _G['HFThreat' .. index .. 'Threat']:SetText(HFT.formatNumber(data.threat))

                HFT.barAnimator:animateTo(index, data.perc)

            elseif name == HFT.AGRO then

                HFT.barAnimator:animateTo(index, nil)

                _G['HFThreat' .. index .. 'BG']:SetWidth(HFT.windowWidth - 2)
                _G['HFThreat' .. index .. 'Threat']:SetText('+' .. HFT.formatNumber(data.threat - HFT.threats[HFT.name].threat))

                local colorLimit = 50

                if HFT.threats[HFT.name].perc >= 0 and HFT.threats[HFT.name].perc < colorLimit then
                    _G['HFThreat' .. index .. 'BG']:SetVertexColor(HFT.threats[HFT.name].perc / colorLimit, 1, 0, 0.9)
                elseif HFT.threats[HFT.name].perc >= colorLimit then
                    _G['HFThreat' .. index .. 'BG']:SetVertexColor(1, 1 - (HFT.threats[HFT.name].perc - colorLimit) / colorLimit, 0, 0.9)
                end

                if HFT.tankName == HFT.name then
                    _G['HFThreat' .. index .. 'BG']:SetVertexColor(1, 0, 0, 1)
                    _G['HFThreat' .. index .. 'Perc']:SetText('')
                end

            else

                HFT.barAnimator:animateTo(index, data.perc)

                _G['HFThreat' .. index .. 'Threat']:SetText(HFT.formatNumber(data.threat))
                _G['HFThreat' .. index .. 'BG']:SetVertexColor(color.r, color.g, color.b, 0.9)
            end

            if data.tank then

                HFT.barAnimator:animateTo(index, 100, true)

            end

            if name == HFT.name then
                _G['HFThreat' .. index .. 'BG']:SetVertexColor(1, 0.2, 0.2, 1)
                HFT.updateTargetFrameThreatIndicators(data.perc)
            end

            HFT.threatsFrames[index]:Show()

        end

    end

    if HFT_CONFIG.tankMode then

        _G['TMEF1']:Hide()
        _G['TMEF2']:Hide()
        _G['TMEF3']:Hide()
        _G['TMEF4']:Hide()
        _G['TMEF5']:Hide()

        _G['HFTMainTankModeWindow']:SetHeight(0)

        if HFT.tableSize(HFT.tankModeThreats) > 1 then

            local i = 0
            for guid, data in next, HFT.tankModeThreats do

                i = i + 1
                if i > 5 then
                    break
                end
                _G['HFTMainTankModeWindow']:SetHeight(i * 25 + 23)

                _G['TMEF' .. i .. 'Target']:SetText(data.creature)
                _G['TMEF' .. i .. 'Player']:SetText(HFT.classColors[HFT.getClass(data.name)].c .. data.name)
                _G['TMEF' .. i .. 'Perc']:SetText(HFT.round(data.perc) .. '%')
                _G['TMEF' .. i .. 'TargetButton']:SetID(guid)
                _G['TMEF' .. i]:SetPoint("TOPLEFT", _G["HFTMainTankModeWindow"], "TOPLEFT", 0, -21 + 24 - i * 25)

                _G['TMEF' .. i .. 'RaidTargetIcon']:Hide()

                if data.perc >= 0 and data.perc < 50 then
                    _G['TMEF' .. i .. 'BG']:SetVertexColor(data.perc / 50, 1, 0, 0.5)
                else
                    _G['TMEF' .. i .. 'BG']:SetVertexColor(1, 1 - (data.perc - 50) / 50, 0, 0.5)
                end

                _G['TMEF' .. i]:Show()

                _G['HFTMainTankModeWindow']:Show()

            end

        else
            _G['HFTMainTankModeWindow']:Hide()
        end
    else
        _G['HFTMainTankModeWindow']:Hide()
    end

end

HFT.barAnimator = CreateFrame('Frame')
HFT.barAnimator:Hide()
HFT.barAnimator.frames = {}

function HFT.barAnimator:animateTo(index, perc, instant)

    if perc == nil then
        HFT.barAnimator.frames['HFThreat' .. index .. 'BG'] = perc
        return false
    end

    perc = HFT.round(perc)
    perc = perc > 100 and 100 or perc

    local width = HFT.round((HFT.windowWidth - 2) * perc / 100)
    if instant then
        _G['HFThreat' .. index .. 'BG']:SetWidth(width)
        return true
    end
    HFT.barAnimator.frames['HFThreat' .. index .. 'BG'] = width
end

HFT.barAnimator:SetScript("OnShow", function()
    this.startTime = GetTime()
    HFT.barAnimator.frames = {}
end)
HFT.barAnimator:SetScript("OnUpdate", function()
    local currentW, step, diff
    for frame, w in HFT.barAnimator.frames do
        currentW = HFT.round(_G[frame]:GetWidth())

        diff = currentW - w

        if diff ~= 0 then

            step = 12
            --if __abs(diff) > 50 then
            --    step = 9
            --elseif __abs(diff) > 100 then
            --    step = 12
            --elseif __abs(diff) > 200 then
            --    step = 15
            --end

            -- grow
            if diff < 0 then
                if __abs(diff) < step then
                    step = __abs(diff)
                end
                _G[frame]:SetWidth(currentW + step)
            else
                if diff < step then
                    step = diff
                end
                _G[frame]:SetWidth(currentW - step)
            end
        end
    end
end)

HFT.threatQuery:SetScript("OnShow", function()
    this.startTime = GetTime()
end)
HFT.threatQuery:SetScript("OnHide", function()
end)
HFT.threatQuery:SetScript("OnUpdate", function()
    local plus = HFT.updateSpeed
    local gt = GetTime() * 1000
    local st = (this.startTime + plus) * 1000
    if gt >= st then
        this.startTime = GetTime()
        if GetNumRaidMembers() == 0 and GetNumPartyMembers() == 0 then
            return false
        end
        if UnitAffectingCombat('player') and UnitAffectingCombat('target') then

            if HFT.targetName == '' then
                HFTdebug('threatQuery target = blank ')
                -- try to re-get target
                HFT.targetChanged()
                return false
            end

            if HFT_CONFIG.glow or HFT_CONFIG.perc or
                    HFT_CONFIG.glowPFUI or HFT_CONFIG.percPFUI or
                    HFT_CONFIG.fullScreenGlow or HFT_CONFIG.tankmode or
                    HFT_CONFIG.visible then
                if HFT.healerMasterTarget == '' then
                    HFT.UnitDetailedThreatSituation(HFT_CONFIG.visibleBars - 1)
                end
            else
                HFTdebug('not asking threat situation')
            end

        end
    end
end)

function HFT.calcTPS(name)

    local data = HFT.history[name]

    if not data then
        return 0
    end

    local older = time()
    for t in next, data do
        if t < older then
            older = t
        end
    end

    if HFT.tableSize(data) > 10 then
        HFT.history[name][older] = nil
    end

    local tps = 0
    local mean = 0

    local time = time()

    for i = 0, HFT.tableSize(data) - 1 do
        if HFT.history[name][time - i] and HFT.history[name][time - i - 1] then
            tps = tps + HFT.history[name][time - i] - HFT.history[name][time - i - 1]
            mean = mean + 1
        end
    end

    if mean > 0 and tps > 0 then
        return HFT.round(tps / mean)
    end

    return 0

end

function HFT.updateTargetFrameThreatIndicators(perc)

    if HFT_CONFIG.fullScreenGlow then
        _G['HFTFullScreenGlow']:Show()
    else
        _G['HFTFullScreenGlow']:Hide()
    end

    if perc == -1 then
        HFT.updateTitleBarText()
        _G['HFThreatDisplayTarget']:Hide()
        _G['HFThreatDisplayTargetPFUI']:Hide()

        --HFT.hideThreatFrames()

        return false
    end

    if not HFT_CONFIG.glow and not HFT_CONFIG.perc and not HFT.targetFrameVisible then
        _G['HFThreatDisplayTarget']:Hide()
    end

    if not HFT_CONFIG.glowPFUI and not HFT_CONFIG.percPFUI and not HFT.PFUItargetFrameVisible then
        _G['HFThreatDisplayTargetPFUI']:Hide()
    end

    if not HFT.targetFrameVisible and not HFT.PFUItargetFrameVisible then
        return false
    end

    if HFT.targetFrameVisible then
        _G['HFThreatDisplayTarget']:Show()
    end
    if HFT.PFUItargetFrameVisible then
        _G['HFThreatDisplayTargetPFUI']:Show()
    end

    perc = HFT.round(perc)

    if HFT_CONFIG.glow then

        local unitClassification = UnitClassification('target')
        if unitClassification == 'worldboss' then
            unitClassification = 'elite'
        end

        _G['HFThreatDisplayTargetGlow']:SetTexture('Interface\\addons\\HFThreat\\images\\' .. unitClassification)

        if perc >= 0 and perc < 50 then
            _G['HFThreatDisplayTargetGlow']:SetVertexColor(perc / 50, 1, 0, perc / 50)
        elseif perc >= 50 then
            _G['HFThreatDisplayTargetGlow']:SetVertexColor(1, 1 - (perc - 50) / 50, 0, 1)
        end

        _G['HFThreatDisplayTargetGlow']:Show()
    else
        _G['HFThreatDisplayTargetGlow']:Hide()
    end

    if HFT_CONFIG.glowPFUI and _G['pfTarget'] then

        if perc >= 0 and perc < 50 then
            _G['HFThreatDisplayTargetPFUIGlow']:SetVertexColor(perc / 50, 1, 0, perc / 50)
        elseif perc >= 50 then
            _G['HFThreatDisplayTargetPFUIGlow']:SetVertexColor(1, 1 - (perc - 50) / 50, 0, 1)
        end

        _G['HFThreatDisplayTargetPFUIGlow']:Show()
    else
        _G['HFThreatDisplayTargetPFUIGlow']:Hide()
    end

    if HFT_CONFIG.perc then

        if HFT_CONFIG.tankMode then
            _G['HFThreatDisplayTargetNumericBG']:SetPoint('TOPLEFT', 24, -7)
            _G['HFThreatDisplayTargetNumericBG']:SetWidth(79)
            _G['HFThreatDisplayTargetNumericBorder']:SetPoint('TOPLEFT', 20, -3)
            _G['HFThreatDisplayTargetNumericBorder']:SetWidth(128)
            _G['HFThreatDisplayTargetNumericBorder']:SetTexture('Interface\\addons\\HFThreat\\images\\numericthreatborder_wide')
            _G['HFThreatDisplayTargetNumericPerc']:SetPoint('TOPLEFT', -1, 3)
            _G['HFThreatDisplayTargetNumericPerc']:SetWidth(128)
        else
            _G['HFThreatDisplayTargetNumericBG']:SetPoint('TOPLEFT', 44, -7)
            _G['HFThreatDisplayTargetNumericBG']:SetWidth(36)
            _G['HFThreatDisplayTargetNumericBorder']:SetPoint('TOPLEFT', 38, -3)
            _G['HFThreatDisplayTargetNumericBorder']:SetWidth(64)
            _G['HFThreatDisplayTargetNumericBorder']:SetTexture('Interface\\addons\\HFThreat\\images\\numericthreatborder')
            _G['HFThreatDisplayTargetNumericPerc']:SetPoint('TOPLEFT', 31, 3)
            _G['HFThreatDisplayTargetNumericPerc']:SetWidth(64)
        end

        local tankModePerc = 0

        if HFT_CONFIG.tankMode then
            local second = ''
            local index = 0
            for name, data in HFT.ohShitHereWeSortAgain(HFT.threats, true) do
                index = index + 1
                if index == 3 then
                    tankModePerc = HFT.round(data.perc)
                    second = HFT.unitNameForTitle(name, 6) .. ' ' .. tankModePerc .. '%'
                    break
                    --HFT.classColors[HFT.getClass(name)].c ..
                end
            end
            if second ~= '' then
                _G['HFThreatDisplayTargetNumericPerc']:SetText(second)
            else
                _G['HFThreatDisplayTargetNumericPerc']:SetText(perc .. '%')
            end
        else
            _G['HFThreatDisplayTargetNumericPerc']:SetText(perc .. '%')
        end

        if tankModePerc ~= 0 then
            perc = tankModePerc
        end

        if perc >= 0 and perc < 50 then
            _G['HFThreatDisplayTargetNumericBG']:SetVertexColor(perc / 50, 1, 0, 1)
        elseif perc >= 50 then
            _G['HFThreatDisplayTargetNumericBG']:SetVertexColor(1, 1 - (perc - 50) / 50, 0)
        end

        _G['HFThreatDisplayTargetNumericPerc']:Show()
        _G['HFThreatDisplayTargetNumericBG']:Show()
        _G['HFThreatDisplayTargetNumericBorder']:Show()
    else
        _G['HFThreatDisplayTargetNumericPerc']:Hide()
        _G['HFThreatDisplayTargetNumericBG']:Hide()
        _G['HFThreatDisplayTargetNumericBorder']:Hide()
    end

    if HFT_CONFIG.percPFUI and _G['pfTarget'] then

        local offset = 0
        if HFT_CONFIG.percPFUIbottom then
            offset = -_G['pfTarget']:GetHeight() - 32 / 2
        end

        if HFT_CONFIG.tankMode then
            _G['HFThreatDisplayTargetPFUINumericBG']:SetPoint('TOPLEFT', 0, 18 + offset)
            _G['HFThreatDisplayTargetPFUINumericBG']:SetWidth(76)
            _G['HFThreatDisplayTargetPFUINumericBorder']:SetPoint('TOPLEFT', -6, 19 + offset)
            _G['HFThreatDisplayTargetPFUINumericBorder']:SetTexture('Interface\\addons\\HFThreat\\images\\numericthreatborder_pfui_wide')
            _G['HFThreatDisplayTargetPFUINumericPerc']:SetPoint('TOPLEFT', -26, 25 + offset)
            _G['HFThreatDisplayTargetPFUINumericPerc']:SetWidth(128)
        else
            _G['HFThreatDisplayTargetPFUINumericBG']:SetPoint('TOPLEFT', 0, 18 + offset)
            _G['HFThreatDisplayTargetPFUINumericBG']:SetWidth(37)
            _G['HFThreatDisplayTargetPFUINumericBorder']:SetPoint('TOPLEFT', -6, 19 + offset)
            _G['HFThreatDisplayTargetPFUINumericBorder']:SetTexture('Interface\\addons\\HFThreat\\images\\numericthreatborder_pfui')
            _G['HFThreatDisplayTargetPFUINumericPerc']:SetPoint('TOPLEFT', -12, 25 + offset)
            _G['HFThreatDisplayTargetPFUINumericPerc']:SetWidth(64)
        end

        local tankModePerc = 0

        if HFT_CONFIG.tankMode then
            local second = ''
            local index = 0
            for name, data in HFT.ohShitHereWeSortAgain(HFT.threats, true) do
                index = index + 1
                if index == 3 then
                    tankModePerc = HFT.round(data.perc)
                    second = HFT.unitNameForTitle(name, 6) .. ' ' .. tankModePerc .. '%'
                    break
                end
            end
            if second ~= '' then
                _G['HFThreatDisplayTargetPFUINumericPerc']:SetText(second)
            else
                _G['HFThreatDisplayTargetPFUINumericPerc']:SetText(perc .. '%')
            end
        else
            _G['HFThreatDisplayTargetPFUINumericPerc']:SetText(perc .. '%')
        end

        if tankModePerc ~= 0 then
            perc = tankModePerc
        end

        if perc >= 0 and perc < 50 then
            _G['HFThreatDisplayTargetPFUINumericBG']:SetVertexColor(perc / 50, 1, 0, 1)
        elseif perc >= 50 then
            _G['HFThreatDisplayTargetPFUINumericBG']:SetVertexColor(1, 1 - (perc - 50) / 50, 0)
        end

        _G['HFThreatDisplayTargetPFUINumericPerc']:Show()
        _G['HFThreatDisplayTargetPFUINumericBG']:Show()
        _G['HFThreatDisplayTargetPFUINumericBorder']:Show()
    else
        _G['HFThreatDisplayTargetPFUINumericPerc']:Hide()
        _G['HFThreatDisplayTargetPFUINumericBG']:Hide()
        _G['HFThreatDisplayTargetPFUINumericBorder']:Hide()
    end

end

function HFTMainWindow_Resizing()
    _G['HFTMain']:SetAlpha(0.4)
end

function HFTMainMainWindow_Resized()
    _G['HFTMain']:SetAlpha(UnitAffectingCombat('player') and HFT_CONFIG.combatAlpha or HFT_CONFIG.oocAlpha)

    HFT_CONFIG.visibleBars = HFT.round((_G['HFTMain']:GetHeight() - (HFT_CONFIG.labelRow and 40 or 20)) / HFT_CONFIG.barHeight)
    HFT_CONFIG.visibleBars = HFT_CONFIG.visibleBars < 4 and 4 or HFT_CONFIG.visibleBars

    FrameHeightSlider_OnValueChanged()
end

function FrameHeightSlider_OnValueChanged()
    HFT_CONFIG.barHeight = _G['HFTMainSettingsFrameHeightSlider']:GetValue()

    _G['HFTMain']:SetHeight(HFT_CONFIG.barHeight * HFT_CONFIG.visibleBars + (HFT_CONFIG.labelRow and 40 or 20))

    HFT.setMinMaxResize()
    HFT.updateUI('FrameHeightSlider_OnValueChanged')
end

function WindowScaleSlider_OnValueChanged()
    HFT_CONFIG.windowScale = _G['HFTMainSettingsWindowScaleSlider']:GetValue()

    local x, y = _G['HFTMain']:GetLeft(), _G['HFTMain']:GetTop()
    local sx, sy = _G['HFTMainTankModeWindow']:GetLeft(), _G['HFTMainTankModeWindow']:GetTop()
    local s = _G['HFTMain']:GetEffectiveScale()
    local ss = _G['HFTMainTankModeWindow']:GetEffectiveScale()
    local posX, posY
    local sposX, sposY

    if x and y and s then
        x, y = x * s, y * s
        posX = x
        posY = y
    end
    if sx and sy and ss then
        sx, sy = sx * ss, sy * ss
        sposX = sx
        sposY = sy
    end

    _G['HFTMain']:SetScale(HFT_CONFIG.windowScale)
    _G['HFTMainTankModeWindow']:SetScale(HFT_CONFIG.windowScale)

    s = _G['HFTMain']:GetEffectiveScale()
    ss = _G['HFTMainTankModeWindow']:GetEffectiveScale()
    posX, posY = posX / s, posY / s
    sposX, sposY = sposX / ss, sposY / ss
    _G['HFTMain']:ClearAllPoints()
    _G['HFTMainTankModeWindow']:ClearAllPoints()
    _G['HFTMain']:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", posX, posY)
    _G['HFTMainTankModeWindow']:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", sposX, sposY)

    if HFT_CONFIG.tankModeStick ~= 'Free' then
        HFTTankModeWindowChangeStick_OnClick(HFT_CONFIG.tankModeStick)
    end
end

function CombatOpacitySlider_OnValueChanged()
    HFT_CONFIG.combatAlpha = _G['HFTMainSettingsCombatAlphaSlider']:GetValue()
    _G['HFTMain']:SetAlpha(UnitAffectingCombat('player') and HFT_CONFIG.combatAlpha or HFT_CONFIG.oocAlpha)
end

function OOCombatSlider_OnValueChanged()
    HFT_CONFIG.oocAlpha = _G['HFTMainSettingsOOCAlphaSlider']:GetValue()
    _G['HFTMain']:SetAlpha(UnitAffectingCombat('player') and HFT_CONFIG.combatAlpha or HFT_CONFIG.oocAlpha)
end

function AggroThresholdSlider_OnValueChanged()
    HFT_CONFIG.aggroThreshold = _G['HFTMainSettingsAggroThresholdSlider']:GetValue()
end

function HFTChangeSetting_OnClick(checked, code)
    if code == 'lock' then
        checked = not HFT_CONFIG[code]
        if checked then
            _G['HFTMainLockButton']:SetNormalTexture('Interface\\addons\\HFThreat\\images\\icon_locked')
        else
            _G['HFTMainLockButton']:SetNormalTexture('Interface\\addons\\HFThreat\\images\\icon_unlocked')
        end
    end
    HFT_CONFIG[code] = checked
    if code == 'tankMode' then
        if checked then
            HFT.testBars(true)
            HFT_CONFIG.fullScreenGlow = false
            HFT_CONFIG.aggroSound = false
            _G['HFTMainSettingsFullScreenGlow']:SetChecked(HFT_CONFIG.fullScreenGlow)
            _G['HFTMainSettingsFullScreenGlow']:Disable()
            _G['HFTMainSettingsAggroSound']:SetChecked(HFT_CONFIG.fullScreenGlow)
            _G['HFTMainSettingsAggroSound']:Disable()

            _G['HFTMainTankModeWindowStickTopButton']:Show()
            _G['HFTMainTankModeWindowStickRightButton']:Show()
            _G['HFTMainTankModeWindowStickBottomButton']:Show()
            _G['HFTMainTankModeWindowStickLeftButton']:Show()

            _G['HFTMainTankModeWindow']:Show()
        else
            _G['HFTMainSettingsFullScreenGlow']:Enable()
            _G['HFTMainSettingsAggroSound']:Enable()
            _G['HFTMainTankModeWindow']:Hide()
        end
    end
    if code == 'aggroSound' and checked and not UnitAffectingCombat('player') then
        PlaySoundFile('Interface\\addons\\HFThreat\\sounds\\warn.ogg')
    end

    if code == 'fullScreenGlow' and checked and not UnitAffectingCombat('player') then
        HFT.glowFader:Show()
    end

    if code == 'percPFUItop' then
        HFT_CONFIG.percPFUIbottom = false
        _G['HFTMainSettingsPercNumbersPFUIbottom']:SetChecked(HFT_CONFIG.percPFUIbottom)
    end
    if code == 'percPFUIbottom' then
        HFT_CONFIG.percPFUItop = false
        _G['HFTMainSettingsPercNumbersPFUItop']:SetChecked(HFT_CONFIG.percPFUItop)
    end

    HFT.setColumnLabels()

    if HFT_CONFIG.labelRow then
        _G['HFTMainBarsBG']:SetPoint('TOPLEFT', 1, -40)
        _G['HFTMainNameLabel']:Show()
    else
        _G['HFTMainBarsBG']:SetPoint('TOPLEFT', 1, -20)
        _G['HFTMainNameLabel']:Hide()
        _G['HFTMainTPSLabel']:Hide()
        _G['HFTMainThreatLabel']:Hide()
        _G['HFTMainPercLabel']:Hide()
    end

    FrameHeightSlider_OnValueChanged()

    HFT.updateUI('HFTChangeSetting_OnClick')
end

function HFT.setColumnLabels()
    _G['HFTMain']:SetWidth(HFT.windowStartWidth - 70 - 70 - 70)

    HFT.nameLimit = 5

    if HFT_CONFIG.colPerc then
        _G['HFTMainPercLabel']:Show()
        _G['HFTMain']:SetWidth(_G['HFTMain']:GetWidth() + 70)
        HFT.nameLimit = HFT.nameLimit + 8
    else
        _G['HFTMainPercLabel']:Hide()
    end

    if HFT_CONFIG.colThreat then
        _G['HFTMain']:SetWidth(_G['HFTMain']:GetWidth() + 70)
        HFT.nameLimit = HFT.nameLimit + 8

        if HFT_CONFIG.colPerc then
            _G['HFTMainThreatLabel']:SetPoint('TOPRIGHT', _G['HFTMain'], -10 - 70 - 5, -21)
        else
            _G['HFTMainThreatLabel']:SetPoint('TOPRIGHT', _G['HFTMain'], -10, -21)
        end

        _G['HFTMainThreatLabel']:Show()
    else
        _G['HFTMainThreatLabel']:Hide()
    end

    if HFT_CONFIG.colTPS then
        _G['HFTMain']:SetWidth(_G['HFTMain']:GetWidth() + 70)
        HFT.nameLimit = HFT.nameLimit + 8

        if HFT_CONFIG.colThreat then
            if HFT_CONFIG.colPerc then
                _G['HFTMainTPSLabel']:SetPoint('TOPRIGHT', _G['HFTMain'], -10 - 70 - 70, -21)
            else
                _G['HFTMainTPSLabel']:SetPoint('TOPRIGHT', _G['HFTMain'], -10 - 70, -21)
            end
        elseif HFT_CONFIG.colPerc then
            _G['HFTMainTPSLabel']:SetPoint('TOPRIGHT', _G['HFTMain'], -10 - 70, -21)
        else
            _G['HFTMainTPSLabel']:SetPoint('TOPRIGHT', _G['HFTMain'], 'TOPRIGHT', -10, -21)
        end

        _G['HFTMainTPSLabel']:Show()
    else
        _G['HFTMainTPSLabel']:Hide()
    end

    if HFT.nameLimit < 14 then
        HFT.nameLimit = 14
    end

    if _G['HFTMain']:GetWidth() < 190 then
        _G['HFTMain']:SetWidth(190)
    end

    HFT.windowWidth = _G['HFTMain']:GetWidth()

    HFT.setMinMaxResize()
end

function HFT.setMinMaxResize()
    _G['HFTMain']:SetMinResize(HFT.windowWidth, HFT_CONFIG.barHeight * HFT.minBars + (HFT_CONFIG.labelRow and 40 or 20))
    _G['HFTMain']:SetMaxResize(HFT.windowWidth, HFT_CONFIG.barHeight * HFT.maxBars + (HFT_CONFIG.labelRow and 40 or 20))
end

function HFT.setBarLabels(perc, threat, tps)

    if HFT_CONFIG.colPerc then
        perc:Show()
    else
        perc:Hide()
    end

    if HFT_CONFIG.colThreat then

        if HFT_CONFIG.colPerc then
            threat:SetPoint('RIGHT', -10 - 70 + 4, 0)
        else
            threat:SetPoint('RIGHT', -10 + 4, 0)
        end

        threat:Show()
    else
        threat:Hide()
    end

    if HFT_CONFIG.colTPS then

        if HFT_CONFIG.colThreat then
            if HFT_CONFIG.colPerc then
                tps:SetPoint('RIGHT', -10 - 70 - 70 + 4, 0)
            else
                tps:SetPoint('RIGHT', -10 - 70 + 4, 0)
            end
        elseif HFT_CONFIG.colPerc then
            tps:SetPoint('RIGHT', -10 - 70 + 4, 0)
        else
            tps:SetPoint('RIGHT', -10 + 4, 0)
        end

        tps:Show()
    else
        tps:Hide()
    end

end

function HFT.testBars(show)

    if UnitAffectingCombat('player') then
        return false
    end

    if show then
        HFT.roles['Tenk'] = 'ability_warrior_defensivestance'
        HFT.roles['Chad'] = 'spell_holy_auraoflight'
        HFT.roles[HFT.name] = 'ability_hunter_pet_turtle'
        HFT.roles['Olaf'] = 'ability_racial_bearform'
        HFT.roles['Jimmy'] = 'ability_backstab'
        HFT.roles['Miranda'] = 'spell_shadow_shadowwordpain'
        HFT.roles['Karen'] = 'spell_holy_powerinfusion'
        HFT.roles['Felix'] = 'spell_fire_sealoffire'
        HFT.roles['Tom'] = 'spell_shadow_shadowbolt'
        HFT.roles['Bill'] = 'ability_marksmanship'
        HFT.threats = {
            [HFT.AGRO] = {
                class = 'agro', threat = 1100, perc = 110, tps = '',
                history = {}, melee = true, tank = false
            },
            ['Tenk'] = {
                class = 'warrior', threat = 1000, perc = 100, tps = 100,
                history = {}, melee = true, tank = true },
            ['Chad'] = {
                class = 'paladin', threat = 990, perc = 99, tps = 99,
                history = {}, melee = true, tank = false },
            [HFT.name] = {
                class = HFT.class, threat = 750, perc = 75, tps = 75,
                history = {}, melee = false, tank = false
            },
            ['Olaf'] = {
                class = 'druid', threat = 700, perc = 70, tps = 70,
                history = {}, melee = true, tank = false
            },
            ['Jimmy'] = {
                class = 'rogue', threat = 500, perc = 50, tps = 50,
                history = {}, melee = true, tank = false
            },
            ['Miranda'] = {
                class = 'priest', threat = 450, perc = 45, tps = 45,
                history = {}, melee = false, tank = false
            },
            ['Karen'] = {
                class = 'priest', threat = 400, perc = 40, tps = 40,
                history = {}, melee = true, tank = false
            },
            ['Felix'] = {
                class = 'mage', threat = 350, perc = 35, tps = 35,
                history = {}, melee = false, tank = false
            },
            ['Tom'] = {
                class = 'warlock', threat = 250, perc = 25, tps = 25,
                history = {}, melee = false, tank = false
            },
            ['Bill'] = {
                class = 'hunter', threat = 100, perc = 10, tps = 10,
                history = {}, melee = false, tank = false
            }
        }

        HFT.tankModeThreats = {
            [1] = {
                creature = 'Infectious Ghoul',
                name = 'Bob',
                perc = 78
            },
            [2] = {
                creature = 'Venom Stalker',
                name = 'Alice',
                perc = 95
            },
            [3] = {
                creature = 'Living Monstrosity',
                name = 'Chad',
                perc = 52
            },
            [4] = {
                creature = 'Deathknight Captain',
                name = 'Olaf',
                perc = 81
            },
            [5] = {
                creature = 'Patchwerk TEST',
                name = 'Jimmy',
                perc = 12
            },
        }

        HFT.targetChanged()

        HFT.targetName = "Patchwerk TEST"

        HFT.updateUI('testBars')
    else
        HFT.combatEnd()
    end
end
function HFTCloseButton_OnClick()
    _G['HFTMain']:Hide()
    HFTprint('Window closed. Type |cff69ccf0/HFT show|cffffffff or |cff69ccf0/HFTshow|cffffffff to restore it.')
    HFT_CONFIG.visible = false
end

function HFTTankModeWindowCloseButton_OnClick()
    HFTprint('Tank Mode disabled. Type |cff69ccf0/HFT tankmode|cffffffff to enable it or go into settings.')
    HFTChangeSetting_OnClick(false, 'tankMode')
    _G['HFTMainSettingsTankMode']:SetChecked(false)
end

function HFTTankModeWindowChangeStick_OnClick(to)
    if to then
        HFT_CONFIG.tankModeStick = to
    end
    if HFT_CONFIG.tankModeStick == 'Top' then
        _G['HFTMainTankModeWindow']:ClearAllPoints()
        _G['HFTMainTankModeWindow']:SetPoint('BOTTOMLEFT', _G['HFTMain'], 'TOPLEFT', 0, 1)
    elseif HFT_CONFIG.tankModeStick == 'Right' then
        _G['HFTMainTankModeWindow']:ClearAllPoints()
        _G['HFTMainTankModeWindow']:SetPoint('TOPLEFT', _G['HFTMain'], 'TOPRIGHT', 1, 0)
    elseif HFT_CONFIG.tankModeStick == 'Bottom' then
        _G['HFTMainTankModeWindow']:ClearAllPoints()
        _G['HFTMainTankModeWindow']:SetPoint('TOPLEFT', _G['HFTMain'], 'BOTTOMLEFT', 0, -1)
    elseif HFT_CONFIG.tankModeStick == 'Left' then
        _G['HFTMainTankModeWindow']:ClearAllPoints()
        _G['HFTMainTankModeWindow']:SetPoint('TOPRIGHT', _G['HFTMain'], 'TOPLEFT', -1, 0)
    end
end

function HFTSettingsToggle_OnClick()
    if _G['HFTMainSettings']:IsVisible() == 1 then
        _G['HFTMainSettings']:Hide()
        HFT.testBars(false)

        _G['HFTMainTankModeWindowStickTopButton']:Hide()
        _G['HFTMainTankModeWindowStickRightButton']:Hide()
        _G['HFTMainTankModeWindowStickBottomButton']:Hide()
        _G['HFTMainTankModeWindowStickLeftButton']:Hide()

    else
        _G['HFTMainSettings']:Show()

        if HFT_CONFIG.tankMode then
            HFTTankModeWindowChangeStick_OnClick()
            _G['HFTMainTankModeWindowStickTopButton']:Show()
            _G['HFTMainTankModeWindowStickRightButton']:Show()
            _G['HFTMainTankModeWindowStickBottomButton']:Show()
            _G['HFTMainTankModeWindowStickLeftButton']:Show()
        end

        HFT.testBars(true)
    end
end

function HFTFontButton_OnClick()
    if _G['HFTMainSettingsFontList']:IsVisible() then
        _G['HFTMainSettingsFontList']:Hide()
    else
        _G['HFTMainSettingsFontList']:Show()
    end
end

function HFTFontSelect(id)
    HFT_CONFIG.font = HFT.fonts[id]
    _G['HFTMainSettingsFontButton']:SetText(HFT_CONFIG.font)
    HFT.updateUI('HFTFontSelect')
end

function HFTTargetButton_OnClick(index)

    if HFT.tankModeThreats[__parsestring(index)] then
        AssistByName(HFT.tankModeThreats[__parsestring(index)].name)
        return true
    end

    HFTprint('Cannot target tankmode target.')

    return false
end

function __explode(str, delimiter)
    local result = {}
    local from = 1
    local delim_from, delim_to = __find(str, delimiter, from, 1, true)
    while delim_from do
        __tinsert(result, __substr(str, from, delim_from - 1))
        from = delim_to + 1
        delim_from, delim_to = __find(str, delimiter, from, true)
    end
    __tinsert(result, __substr(str, from))
    return result
end

function HFT.ohShitHereWeSortAgain(t, reverse)
    local a = {}
    for n, l in __pairs(t) do
        __tinsert(a, { ['threat'] = l.threat, ['perc'] = l.perc, ['tps'] = l.tps, ['name'] = n })
    end
    if reverse then
        __tsort(a, function(b, c)
            return b['perc'] > c['perc']
        end)
    else
        __tsort(a, function(b, c)
            return b['perc'] < c['perc']
        end)
    end

    local i = 0 -- iterator variable
    local iter = function()
        -- iterator function
        i = i + 1
        if a[i] == nil then
            return nil
        else
            return a[i]['name'], t[a[i]['name']]
        end
    end
    return iter
end

function HFT.formatNumber(n)

    if n < 0 then
        n = 0
    end

    if n < 999 then
        return HFT.round(n)
    end
    if n < 999999 then
        return HFT.round(n / 10) / 100 .. 'K' or 0
    end
    --1,000,000
    return HFT.round(n / 10000) / 100 .. 'M' or 0
end

function HFT.tableSize(t)
    local size = 0
    for _, _ in next, t do
        size = size + 1
    end
    return size
end

function HFT.targetFromName(name)
    if name == HFT.name then
        return 'target'
    end
    if HFT.channel == 'RAID' then
        for i = 0, GetNumRaidMembers() do
            if GetRaidRosterInfo(i) then
                local n = GetRaidRosterInfo(i)
                if n == name then
                    return 'raid' .. i
                end
            end
        end
    end
    if HFT.channel == 'PARTY' then
        if GetNumPartyMembers() > 0 then
            for i = 1, GetNumPartyMembers() do
                if UnitName('party' .. i) then
                    if name == UnitName('party' .. i) then
                        return 'party' .. i
                    end
                end
            end
        end
    end

    return 'target'
end

function HFT.unitNameForTitle(name, limit)
    limit = limit or HFT.nameLimit
    if __strlen(name) > limit then
        return __substr(name, 1, limit) .. ' '
    end
    return name
end

function HFT.targetRaidIcon(iconIndex)

    for i = 1, GetNumRaidMembers() do
        if HFT.targetRaidSymbolFromUnit("raid" .. i, iconIndex) then
            return true
        end
    end
    for i = 1, GetNumPartyMembers() do
        if HFT.targetRaidSymbolFromUnit("party" .. i, iconIndex) then
            return true
        end
    end
    if HFT.targetRaidSymbolFromUnit("player", iconIndex) then
        return true
    end
    return false
end

function HFT.updateTitleBarText(text)
    if not text then
        _G['HFTMainTitle']:SetText(HFT.addonName .. ' |cffabd473v' .. HFT.addonVer)
        return true
    end
    _G['HFTMainTitle']:SetText(text)
end


-- https://github.com/shagu/pfUI/blob/master/api/api.lua#L596
function HFT.wipe(src)
    -- notes: table.insert, table.remove will have undefined behavior
    -- when used on tables emptied this way because Lua removes nil
    -- entries from tables after an indeterminate time.
    -- Instead of table.insert(t,v) use t[table.getn(t)+1]=v as table.getn collapses nil entries.
    -- There are no issues with hash tables, t[k]=v where k is not a number behaves as expected.
    local mt = getmetatable(src) or {}
    if mt.__mode == nil or mt.__mode ~= "kv" then
        mt.__mode = "kv"
        src = setmetatable(src, mt)
    end
    for k in __pairs(src) do
        src[k] = nil
    end
    return src
end

HFT.hooks = {}
--https://github.com/shagu/pfUI/blob/master/compat/vanilla.lua#L37
function HFT.hooksecurefunc(name, func, append)
    if not _G[name] then
        return
    end

    HFT.hooks[__parsestring(func)] = {}
    HFT.hooks[__parsestring(func)]["old"] = _G[name]
    HFT.hooks[__parsestring(func)]["new"] = func

    if append then
        HFT.hooks[__parsestring(func)]["function"] = function(a1, a2, a3, a4, a5, a6, a7, a8, a9, a10)
            HFT.hooks[__parsestring(func)]["old"](a1, a2, a3, a4, a5, a6, a7, a8, a9, a10)
            HFT.hooks[__parsestring(func)]["new"](a1, a2, a3, a4, a5, a6, a7, a8, a9, a10)
        end
    else
        HFT.hooks[__parsestring(func)]["function"] = function(a1, a2, a3, a4, a5, a6, a7, a8, a9, a10)
            HFT.hooks[__parsestring(func)]["new"](a1, a2, a3, a4, a5, a6, a7, a8, a9, a10)
            HFT.hooks[__parsestring(func)]["old"](a1, a2, a3, a4, a5, a6, a7, a8, a9, a10)
        end
    end

    _G[name] = HFT.hooks[__parsestring(func)]["function"]
end

function HFT.pairsByKeys(t, f)
    local a = {}
    for n in __pairs(t) do
        __tinsert(a, n)
    end
    __tsort(a, function(a, b)
        return a < b
    end)
    local i = 0 -- iterator variable
    local iter = function()
        -- iterator function
        i = i + 1
        if a[i] == nil then
            return nil
        else
            return a[i], t[a[i]]
        end
    end
    return iter
end

function HFT.round(num, numDecimalPlaces)
    local mult = 10 ^ (numDecimalPlaces or 0)
    return __floor(num * mult + 0.5) / mult
end

function HFT.version(ver)
    local verEx = __explode(ver, '.')

    if verEx[3] then
        -- new versioning with 3 numbers
        return __parseint(verEx[1]) * 100 +
                __parseint(verEx[2]) * 10 +
                __parseint(verEx[3]) * 1
    end

    -- old versioning
    return __parseint(verEx[1]) * 10 +
            __parseint(verEx[2]) * 1

end

function HFT.sendMyVersion()
    SendAddonMessage(HFT.prefix, "HFTVersion:" .. HFT.addonVer, "PARTY")
    SendAddonMessage(HFT.prefix, "HFTVersion:" .. HFT.addonVer, "GUILD")
    SendAddonMessage(HFT.prefix, "HFTVersion:" .. HFT.addonVer, "RAID")
    SendAddonMessage(HFT.prefix, "HFTVersion:" .. HFT.addonVer, "BATTLEGROUND")
end
