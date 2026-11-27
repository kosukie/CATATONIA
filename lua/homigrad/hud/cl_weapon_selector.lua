--
hg = hg or {}
hg.WeaponSelector = hg.WeaponSelector or {}
local WS = hg.WeaponSelector

function WS.GetPrintName( self )
	local class = self:GetClass()
	local phrase = language.GetPhrase(class)
	return phrase ~= class and phrase or self:GetPrintName()
end

WS.Show = 0
WS.Transparent = 0
WS.LastSelectedSlot = 0
WS.LastSelectedSlotPos = 0

WS.SelectedSlot = 0
WS.SelectedSlotPos = 0

function WS.DrawText(text, font, posX, posY, color, textAlign)
    draw.DrawText( text, font, posX + 2, posY + 2, ColorAlpha(color_black,WS.Transparent*255) ,textAlign )
    draw.DrawText( text, font, posX, posY, ColorAlpha(color,WS.Transparent*255) ,textAlign )
end

function WS.GetSelectedWeapon()
    if not IsValid( LocalPlayer() ) or not LocalPlayer():Alive() then return end
    local Weapons = WS.GetWeaponTable( LocalPlayer() )
    return Weapons[WS.SelectedSlot] and Weapons[WS.SelectedSlot][WS.SelectedSlotPos] or Weapons[WS.LastSelectedSlot][WS.LastSelectedSlotPos] or Weapons[0][0]
end

function WS.GetWeaponTable( ply )
    if not IsValid( ply ) or not ply:Alive() then return end
    local WeaponsGet = ply:GetWeapons()
    local FormatedTable = {
        [0] = {}, [1] = {}, [2] = {}, [3] = {}, [4] = {}, [5] = {},
    }

    table.sort(WeaponsGet, function(a, b) return (a.SlotPos or 0) > (b.SlotPos or 0) end)

    for k,wep in ipairs(WeaponsGet) do
        local tTbl = FormatedTable[wep.Slot or 0]
        local iMinPos = math.min( (wep.SlotPos and wep.SlotPos) or 1, ((#tTbl or 0) + 1)) - 1
        local iPos = tTbl[ iMinPos ] and #tTbl + 1 or iMinPos
        tTbl[ iPos ] = wep
    end
    return FormatedTable
end

local slotFont = "CatatoniaWeaponSlot"
local nameFont = "CatatoniaWeaponName"
local slotFontFamily = system.IsLinux() and "AoM_HUD.ttf" or "Neverwinter"
local nameFontFamily = system.IsLinux() and "AoM.ttf" or "JohnstempW04-Medium"
local cardBaseWidth, cardBaseHeight = 224, 108
local iconMasks = {}
local defaultIcon = Material("weapons/swep")

local previousWeapon
local previousSlot
local nameShakeStart = -math.huge
local shakeDuration = 0.2

if IsValid(WS.PreviewModel) then WS.PreviewModel:Remove() end
WS.PreviewModel = nil

local function SelectorScale()
    return math.Clamp(math.min(ScrH() / 1080, ScrW() / 1280), 0.6, 2)
end

local function CreateSelectorFonts()
    local scale = SelectorScale()
    surface.CreateFont(slotFont, {font = slotFontFamily, size = math.Round(27 * scale), weight = 700})
    surface.CreateFont(nameFont, {font = nameFontFamily, size = math.Round(21 * scale), weight = 500, extended = true})
end

CreateSelectorFonts()
hook.Add("OnScreenSizeChanged", "WeaponSelector_Fonts", CreateSelectorFonts)

local borderStrokes = {}
for edge = 1, 4 do
    local strokes = {}
    borderStrokes[edge] = strokes
    local position = 0
    local length = edge <= 2 and cardBaseWidth or cardBaseHeight

    -- Keep the scratches fixed between frames and off the gameplay RNG.
    while position < length do
        local seed = edge * 1000 + #strokes
        local span = util.SharedRandom("WeaponSelectorBorderSpan", 2, 12, seed)
        strokes[#strokes + 1] = {
            first = position / length,
            last = math.min(position + span, length) / length,
            offset = util.SharedRandom("WeaponSelectorBorderOffset", -1, 2, seed),
            opacity = util.SharedRandom("WeaponSelectorBorderOpacity", 0.18, 0.96, seed)
        }
        position = position + span + util.SharedRandom("WeaponSelectorBorderGap", 0, 3, seed)
    end
end

local function DrawGrungeFrame(x, y, width, height, scale, alpha)
    surface.SetDrawColor(255, 255, 255, alpha * 0.23)
    surface.DrawOutlinedRect(x, y, width, height)
    for edge, strokes in ipairs(borderStrokes) do
        local horizontal = edge <= 2
        local length = horizontal and width or height
        local edgeX = edge == 4 and x + width - 1 or x
        local edgeY = edge == 2 and y + height - 1 or y
        for _, stroke in ipairs(strokes) do
            local first = math.floor(stroke.first * length)
            local last = math.floor(stroke.last * length)
            local offset = math.Round(stroke.offset * scale)
            surface.SetDrawColor(255, 255, 255, alpha * stroke.opacity)
            if horizontal then
                surface.DrawLine(edgeX + first, edgeY + offset, edgeX + last, edgeY + offset)
            else
                surface.DrawLine(edgeX + offset, edgeY + first, edgeX + offset, edgeY + last)
            end
        end
    end
end

local iconScratches = {}
for index = 1, 52 do
    iconScratches[index] = {
        x = util.SharedRandom("WeaponSelectorIconScratchX", 0.02, 0.96, index),
        y = util.SharedRandom("WeaponSelectorIconScratchY", 0.02, 0.96, index),
        length = util.SharedRandom("WeaponSelectorIconScratchLength", 0.008, 0.025, index)
    }
end

local function GetIconTexture(icon)
    if isnumber(icon) then
        local path = surface.GetTextureNameByID(icon)
        icon = path and Material(path)
    end
    if not icon or icon:IsError() or icon:GetName() == "null" then return end

    local texture = icon:GetTexture("$basetexture")
    if texture and not texture:IsError() then return texture end
end

local function DrawWeaponIcon(weapon, x, y, maxWidth, maxHeight, alpha)
    local texture = GetIconTexture(weapon.WepSelectIcon2)
    local aspect = texture and weapon.WepSelectIcon2box and 1 or 2
    texture = texture or GetIconTexture(weapon.WepSelectIcon) or GetIconTexture(defaultIcon)
    if not texture then return end

    local height = math.floor(math.min(maxHeight, maxWidth / aspect))
    local width = height * aspect
    x = x + math.floor((maxWidth - width) * 0.5)
    y = y + math.floor((maxHeight - height) * 0.5)
    local textureName = texture:GetName()
    local mask = iconMasks[textureName]
    if not mask then
        mask = CreateMaterial("catatonia_weapon_selector_mask_" .. util.CRC(textureName), "UnlitGeneric", {
            ["$basetexture"] = textureName,
            ["$alphatest"] = "1",
            ["$alphatestreference"] = "0.18",
            ["$ignorez"] = "1"
        })
        mask:SetTexture("$basetexture", texture)
        iconMasks[textureName] = mask
    end

    -- Use the original icon's alpha to keep its orientation and cutouts.
    render.ClearStencilBufferRectangle(x, y, x + width, y + height, 0)
    render.SetStencilWriteMask(0xFF)
    render.SetStencilTestMask(0xFF)
    render.SetStencilReferenceValue(1)
    render.SetStencilCompareFunction(STENCIL_ALWAYS)
    render.SetStencilPassOperation(STENCIL_REPLACE)
    render.SetStencilFailOperation(STENCIL_KEEP)
    render.SetStencilZFailOperation(STENCIL_REPLACE)
    render.SetStencilEnable(true)

    render.OverrideColorWriteEnable(true, false)
    render.OverrideAlphaWriteEnable(true, false)
    surface.SetDrawColor(255, 255, 255, 255)
    surface.SetMaterial(mask)
    surface.DrawTexturedRect(x, y, width, height)
    render.OverrideAlphaWriteEnable(false, false)
    render.OverrideColorWriteEnable(false, false)

    render.SetStencilCompareFunction(STENCIL_EQUAL)
    render.SetStencilPassOperation(STENCIL_KEEP)
    render.SetStencilZFailOperation(STENCIL_KEEP)
    surface.SetDrawColor(255, 255, 255, alpha)
    surface.DrawRect(x, y, width, height)

    surface.SetDrawColor(30, 30, 30, alpha * 0.18)
    for _, scratch in ipairs(iconScratches) do
        local lineX = x + math.floor(scratch.x * width)
        local lineY = y + math.floor(scratch.y * height)
        surface.DrawLine(lineX, lineY, lineX + math.max(1, math.floor(scratch.length * width)), lineY)
    end

    render.SetStencilEnable(false)
    render.ClearStencilBufferRectangle(x, y, x + width, y + height, 0)
end

function WS.WeaponSelectorDraw(ply)
    if not IsValid(ply) or not ply:Alive() or GetGlobalBool("RadialInventory", false) then return end
    local now = CurTime()
    if WS.Show < now then
        WS.SelectedSlot = WS.LastSelectedSlot
        WS.SelectedSlotPos = -1
        previousWeapon = nil
        return
    end

    local weapons = WS.GetWeaponTable(ply)
    local selected = WS.GetSelectedWeapon()
    if not IsValid(selected) then return end
    WS.Transparent = LerpFT(0.2, WS.Transparent, math.min(WS.Show - now, 1))

    if selected ~= previousWeapon or WS.SelectedSlot ~= previousSlot then
        nameShakeStart = RealTime()
        previousWeapon = selected
        previousSlot = WS.SelectedSlot
    end

    local slots = {}
    local selectedSlot = selected.Slot or 0
    for index = 0, #weapons do
        local items = weapons[index]
        local count = table.Count(items)
        if count > 0 then
            slots[#slots + 1] = {number = index + 1, count = count, active = index == selectedSlot}
        end
    end

    local scale = SelectorScale()
    local alpha = WS.Transparent * 255
    local square = math.Round(36 * scale)
    local gap = math.Round(8 * scale)
    local indicator = math.max(2, math.Round(4 * scale))
    local indicatorGap = math.max(1, math.Round(2 * scale))
    local step = indicator + indicatorGap
    local perRow = math.floor((square + indicatorGap) / step)
    local centerX = ScrW() * 0.5
    local rowY = math.Round(ScrH() * 0.02)
    local rowWidth = #slots * (square + gap) - gap
    local rowX = math.Round(centerX - rowWidth * 0.5)
    local indicatorRows = 1

    for index, slot in ipairs(slots) do
        local x = rowX + (index - 1) * (square + gap)
        if slot.active then
            local glowSize = math.max(2, math.Round(6 * scale))
            for radius = 1, glowSize do
                local opacity = 1 - (radius - 1) / glowSize
                surface.SetDrawColor(255, 255, 255, alpha * 0.26 * opacity * opacity)
                surface.DrawOutlinedRect(x - radius, rowY - radius, square + radius * 2, square + radius * 2)
            end
            surface.SetDrawColor(255, 255, 255, alpha)
        else
            surface.SetDrawColor(12, 12, 12, alpha * 0.8)
        end
        surface.DrawRect(x, rowY, square, square)
        if not slot.active then
            surface.SetDrawColor(255, 255, 255, alpha * 0.72)
            surface.DrawOutlinedRect(x, rowY, square, square)
        end
        local numberColor = slot.active and color_black or color_white
        draw.SimpleText(tostring(slot.number), slotFont, x + square * 0.5, rowY + square * 0.5,
            ColorAlpha(numberColor, alpha), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)

        if slot.count > 1 then
            local rows = math.ceil(slot.count / perRow)
            indicatorRows = math.max(indicatorRows, rows)
            surface.SetDrawColor(255, 255, 255, alpha)
            for row = 0, rows - 1 do
                local count = math.min(perRow, slot.count - row * perRow)
                local startX = math.Round(x + (square - count * step + indicatorGap) * 0.5)
                for item = 0, count - 1 do
                    surface.DrawRect(startX + item * step, rowY + square + gap + row * step, indicator, indicator)
                end
            end
        end
    end

    local cardWidth = math.Round(cardBaseWidth * scale)
    local cardHeight = math.Round(cardBaseHeight * scale)
    local cardX = math.Round(centerX - cardWidth * 0.5)
    local cardY = rowY + square + gap * 2 + indicatorRows * step
    local padding = math.Round(10 * scale)
    local nameY = cardY + math.Round(18 * scale)
    local iconY = cardY + math.Round(33 * scale)
    local iconWidth = cardWidth - padding * 2
    local iconHeight = cardY + cardHeight - padding - iconY

    surface.SetDrawColor(9, 9, 9, alpha * 0.88)
    surface.DrawRect(cardX, cardY, cardWidth, cardHeight)
    DrawGrungeFrame(cardX, cardY, cardWidth, cardHeight, scale, alpha)

    local shakeTime = RealTime() - nameShakeStart
    local shake = math.max(0, 1 - shakeTime / shakeDuration) * scale
    local offsetX = math.sin(shakeTime * 106) * shake * 1.8
    local offsetY = math.sin(shakeTime * 83) * shake
    local name = WS.GetPrintName(selected)
    surface.SetFont(nameFont)
    local nameWidth = surface.GetTextSize(name)
    local nameX = math.max(cardX + padding, centerX - nameWidth * 0.5)
    render.SetScissorRect(cardX + padding, cardY, cardX + cardWidth - padding, iconY, true)
    draw.SimpleText(name, nameFont, nameX + offsetX, nameY + offsetY,
        ColorAlpha(color_white, alpha), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
    render.SetScissorRect(0, 0, 0, 0, false)

    DrawWeaponIcon(selected, cardX + padding, iconY, iconWidth, iconHeight, alpha)
    if selected.DrawWeaponSelection and selected.PrintWeaponInfo then
        selected:PrintWeaponInfo(cardX + cardWidth, iconY + iconHeight, alpha)
    end
end

-- Changer
local tAcceptKeys = {
    ["slot1"] = 1,
    ["slot2"] = 2,
    ["slot3"] = 3,
    ["slot4"] = 4,
    ["slot5"] = 5,
    ["slot6"] = 6,
}

--[[
    Table:
        [1]	=	Weapon [52][weapon_hands_sh]
        [2]	=	Weapon [117][weapon_bigconsumable]
        [3]	=	Weapon [121][weapon_handcuffs_key]
        [4]	=	Weapon [122][weapon_handcuffs]
        [5]	=	Weapon [123][weapon_traitor_poison1]
        [6]	=	Weapon [124][weapon_traitor_suit]
        [7]	=	Weapon [125][weapon_matches]

    TableFormated:
    [0]:
		[0]	=	Weapon [126][weapon_physgun]
		[1]	=	Weapon [52][weapon_hands_sh]
    [1]:
    [2]:
    [3]:
		[1]	=	Weapon [117][weapon_bigconsumable]
		[2]	=	Weapon [121][weapon_handcuffs_key]
		[3]	=	Weapon [122][weapon_handcuffs]
		[4]	=	Weapon [123][weapon_traitor_poison1]
		[5]	=	Weapon [125][weapon_matches]
    [4]:
    [5]:
		[1]	=	Weapon [124][weapon_traitor_suit]
--]]

local function GetUpper(Weapons)
    if #LocalPlayer():GetWeapons() < 1 then return end
    WS.SelectedSlot = WS.SelectedSlot < 0 and #Weapons or WS.SelectedSlot - 1
    WS.SelectedSlotPos = Weapons[WS.SelectedSlot] and #Weapons[WS.SelectedSlot] or 0

    --print(WS.SelectedSlot, WS.SelectedSlotPos)

    if Weapons[WS.SelectedSlot] == nil or Weapons[WS.SelectedSlot][WS.SelectedSlotPos] == nil then
        GetUpper(Weapons)
    end
end

local function GetDown(Weapons)
    if #LocalPlayer():GetWeapons() < 1 then return end
    WS.SelectedSlot = WS.SelectedSlot > #Weapons and 0 or WS.SelectedSlot + 1
    WS.SelectedSlotPos = 0

    --print(WS.SelectedSlot, WS.SelectedSlotPos)

    if Weapons[WS.SelectedSlot] == nil or Weapons[WS.SelectedSlot][WS.SelectedSlotPos] == nil then
        GetDown(Weapons)
    end
end

local LastSelected = 0

local function get_active_tool(ply, tool)
    local activeWep = ply:GetActiveWeapon()
    if not IsValid(activeWep) or activeWep:GetClass() ~= "gmod_tool" or activeWep.Mode ~= tool then return end
    return activeWep:GetToolObject(tool)
end

local function canUseSelector(ply)
    local wep = ply:GetActiveWeapon()
    local tool = get_active_tool(ply, "submaterial")
    if tool and IsValid(ply:GetEyeTraceNoCursor().Entity) then
        return true
    end

    return IsAiming(ply) or (IsValid(wep) and wep:GetClass() == "weapon_physgun" and ply:KeyDown(IN_ATTACK)) or (lply.organism and lply.organism.pain and lply.organism.pain > 100) or GetGlobalBool("RadialInventory", false)
end

function WS.ChangeSelectionWep( ply, key )
    if not IsValid( ply ) or not ply:Alive() or GetGlobalBool("RadialInventory", false) then return end
    if ply.organism and ply.organism.otrub then return end
    if canUseSelector( ply ) then return end
    --print(canUseSelector( ply ))
    --print("Table")
    --PrintTable( WS.GetWeaponTable( ply ) )
    local iPos = tAcceptKeys[ key ]
    if iPos or key == "invnext" or key == "invprev" or key == "lastinv" then

        local Weapons = WS.GetWeaponTable( ply )

        WS.Show = CurTime() + 4
        --print(key)
        surface.PlaySound("arc9_eft_shared/weapon_generic_rifle_spin"..math.random(10)..".ogg")
        if iPos then
            iPos = iPos - 1
            if LastSelected ~= iPos then 
                WS.SelectedSlotPos = -1
            end
            WS.SelectedSlotPos = (Weapons[iPos] and LastSelected == iPos and WS.SelectedSlotPos + 1 > #Weapons[iPos] and 0 or math.min( WS.SelectedSlotPos + 1, #Weapons[iPos] )) or 0
            WS.SelectedSlot = iPos
            LastSelected = iPos
            --print(WS.SelectedSlotPos)
            --print(iPos)
            --print( Weapons[WS.SelectedSlot][WS.SelectedSlotPos] )
        elseif key == "invprev" then
            WS.SelectedSlotPos = WS.SelectedSlotPos - 1
            --print(WS.SelectedSlotPos)
            if Weapons[WS.SelectedSlot] and WS.SelectedSlotPos < 0  then
                GetUpper(Weapons)
            end
            --WS.SelectedSlot = Weapons[WS.SelectedSlot] and #Weapons[WS.SelectedSlot] > (WS.SelectedSlotPos + 1) and WS.SelectedSlot + 1 or WS.SelectedSlot + 1 > #Weapons - 1 and 0 or 0
        elseif key == "invnext" then
            WS.SelectedSlotPos = WS.SelectedSlotPos + 1
            --print(WS.SelectedSlotPos)
            if Weapons[WS.SelectedSlot] and WS.SelectedSlotPos > #Weapons[WS.SelectedSlot] then
                GetDown(Weapons)
            end
        elseif key == "lastinv" and IsValid(WS.LastInv) then
            WS.Show = 0
            WS.LastInv = WS.LastInv or "weapon_hands_sh"
            local oldwep = ply:GetActiveWeapon()
            input.SelectWeapon( WS.LastInv )
            WS.LastInv = oldwep
        end

    end
end

function WS.SetActuallyWeapon( ply, cmd )
    if not IsValid( ply ) or not ply:Alive() or GetGlobalBool("RadialInventory", false) then return end
    if (cmd:KeyDown( IN_ATTACK ) or cmd:KeyDown( IN_ATTACK2 )) and WS.Show > CurTime() then

        if WS.Selected and WS.Selected > CurTime() then 
            cmd:RemoveKey(IN_ATTACK) 
            cmd:RemoveKey(IN_ATTACK2) 
        else
            cmd:RemoveKey(IN_ATTACK)
            cmd:RemoveKey(IN_ATTACK2) 
            --print(WS.GetSelectedWeapon())
            
            if IsValid(WS.GetSelectedWeapon()) then
                WS.LastInv = WS.LastInv ~= ply:GetActiveWeapon() and WS.LastInv or ply:GetActiveWeapon()
                input.SelectWeapon( WS.GetSelectedWeapon() )
            end
            cmd:RemoveKey(IN_ATTACK)
            cmd:RemoveKey(IN_ATTACK2) 

            WS.LastSelectedSlot = WS.SelectedSlot
            WS.LastSelectedSlotPos = WS.SelectedSlotPos
            WS.Selected = CurTime() + 0.2
            WS.Show = CurTime() + 0.2
            surface.PlaySound("arc9_eft_shared/weapon_generic_spin"..math.random(1,10)..".ogg")
        end
    end
end

hook.Add( "PlayerBindPress", "WeaponSelector_PlayerBindPress", WS.ChangeSelectionWep )

hook.Add( "HUDPaint", "WeaponSelector_Draw", function()
    WS.WeaponSelectorDraw( LocalPlayer() )
end)

hook.Add( "StartCommand", "WeaponSelector_StartCommand", WS.SetActuallyWeapon )

local tHideElements = {
    ["CHudWeaponSelection"] = true
}

hook.Add("HUDShouldDraw", "WeaponSelector_HUDShouldDraw", function(sElementName)
    if tHideElements[sElementName] then return false end
end)

-- Я ТАК ЗАДОЛБАЛСЯ ПРОСТО УБЕЙТЕ МЕНЯ ХАХАХАХАХАХАХАХАХАХААХАХАХАХАХАХА
-- ПОЛЧАСА Я ПЫТАЛСЯ СДЕЛАТЬ НОРМЛАЬНОЕ ПЕРЕКЛЮЧЕНИЕ ГОВНА!!!
-- ЗАТО ПОЛУЧИЛОСЬ!!!!
-- УЭЭЭЭЭЭЭЭЭЭЭЭЭЭЭЭЭЭЭЭЭЭЭЭЭЭЭЭЭЭЭЭЭЭЭЭЭЭЭЭЭЭЭЭЭ
--[[
    /\_/\
    |_ _|
    |   |__
   /_|_____\ -- IT'S SO OVER
--]]