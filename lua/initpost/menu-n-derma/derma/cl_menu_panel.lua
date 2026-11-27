local PANEL = {}

local title = "CATATONIA"
local titleFont = "CatatoniaMenuTitle"
local titleBlurFont = "CatatoniaMenuTitleBlur"
local buttonFont = "CatatoniaMenuButton"
local fontFamily = system.IsLinux() and "AoM.ttf" or "JohnstempW04-Medium"
local titleSize = math.Clamp(math.floor(math.min(ScreenScale(40), ScreenScaleH(65))), 4, 255)
local buttonSize = math.Clamp(math.floor(math.min(ScreenScale(15), ScreenScaleH(24))), 4, 255)

surface.CreateFont(titleFont, {
    font = fontFamily,
    size = titleSize,
    weight = 500,
    antialias = true
})

surface.CreateFont(titleBlurFont, {
    font = fontFamily,
    size = titleSize,
    weight = 500,
    antialias = true,
    blursize = math.Clamp(math.floor(titleSize * 0.08), 3, 18)
})

surface.CreateFont(buttonFont, {
    font = fontFamily,
    size = buttonSize,
    weight = 500,
    antialias = true
})

local buttonIdle = Color(170, 170, 170)
local footerText = Color(195, 195, 195)
local leftGradient = Material("vgui/gradient-l")
local titleGlow = Color(255, 255, 255, 0)
local shakeDuration = 2
local flashFrameCount = 2

local function CreateMenuButton(parent, text)
    local button = vgui.Create("DLabel", parent)
    local label = string.upper(text)
    local padding = math.max(4, math.ceil(buttonSize * 0.16))
    surface.SetFont(buttonFont)
    local textWidth = surface.GetTextSize(label)

    button:SetText("")
    button:SetMouseInputEnabled(true)
    button:SetCursor("hand")
    button:Dock(LEFT)
    button:SetWide(textWidth + padding * 2)

    function button:OnCursorEntered()
        self.ShakeStart = RealTime()
        surface.PlaySound("shitty/tap-resonant.wav")
    end

    function button:Paint(w, h)
        local x, y = padding, h / 2
        local elapsed = RealTime() - (self.ShakeStart or -shakeDuration)
        if elapsed < shakeDuration then
            local amplitude = padding * 0.375 * (1 - elapsed / shakeDuration) ^ 2
            x = x + math.sin(elapsed * 117) * amplitude
            y = y + math.sin(elapsed * 151 + 0.7) * amplitude
        end

        draw.SimpleText(label, buttonFont, x, y, self:IsHovered() and color_white or buttonIdle,
            TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
    end

    return button
end

local footerLines = {
    {text = "Authors: Z-City Team (i think we can call them like that?), kosuke_, Codex"},
    {text = "Open Beta"},
    {text = "Z-City Github: github.com/uzelezz123/Z-City", url = "https://github.com/uzelezz123/Z-City"},
    {text = "CATATONIA Github: github.com/kosukie/CATATONIA", url = "https://github.com/kosukie/CATATONIA"}
}

local function CreateMenuFooter(parent)
    local footer = vgui.Create("DPanel", parent)
    footer.Paint = function() end

    local y = 0
    for _, line in ipairs(footerLines) do
        local label = vgui.Create("DLabel", footer)
        label:SetFont("ZCity_SuperTiny")
        label:SetTextColor(footerText)
        label:SetText(line.text)
        label:SetContentAlignment(4)
        label:SetExpensiveShadow(1, color_black)
        label:SizeToContents()
        label:SetSize(label:GetWide() + 2, label:GetTall() + 2)
        label:SetPos(0, y)
        y = y + label:GetTall()

        local url = line.url
        if url then
            label:SetMouseInputEnabled(true)
            label:SetCursor("hand")
            function label:DoClick()
                gui.OpenURL(url)
            end
        end
    end

    footer:SizeToChildren(true, true)
    footer:SetPos(ScreenScale(11), parent:GetTall() - footer:GetTall() - ScreenScaleH(6))
end

local clothingSlots = {"main", "pants", "boots", "hands"}
local cameraDirection = Vector(1, 0.30, 0.03):GetNormalized()

local function RemovePreviewModels(models)
    for _, model in pairs(models or {}) do
        if IsValid(model) then model:Remove() end
    end
end

local function CreateCharacterPreview(parent, menuWidth)
    local preview = vgui.Create("DModelPanel", parent)
    local horizontalMargin = parent:GetWide() * 0.035
    local verticalMargin = parent:GetTall() * 0.045
    local width = math.min(parent:GetWide() * 0.39, parent:GetWide() - menuWidth - horizontalMargin)
    preview:SetSize(math.max(width, 1), parent:GetTall() - verticalMargin * 2)
    preview:SetPos(parent:GetWide() - preview:GetWide() - horizontalMargin, verticalMargin)
    preview:SetMouseInputEnabled(false)
    preview:SetKeyboardInputEnabled(false)
    preview:SetFOV(35)
    preview:SetAmbientLight(Color(28, 28, 28))
    preview:SetDirectionalLight(BOX_TOP, Color(105, 105, 105))
    preview:SetDirectionalLight(BOX_FRONT, Color(112, 112, 112))
    preview:SetDirectionalLight(BOX_RIGHT, Color(155, 155, 155))
    preview:SetDirectionalLight(BOX_LEFT, Color(24, 24, 24))
    preview:SetDirectionalLight(BOX_BACK, Color(65, 65, 65))
    preview:SetDirectionalLight(BOX_BOTTOM, Color(8, 8, 8))

    function preview:Think()
        local ply = LocalPlayer()
        self.SourceCharacter = nil
        if not IsValid(ply) then return end

        local character = hg.GetCurrentCharacter and hg.GetCurrentCharacter(ply) or ply
        local corpse = not ply:Alive() and ply:GetNWEntity("RagdollDeath")
        if IsValid(corpse) then character = corpse end
        if not IsValid(character) then return end

        local model = character:GetModel()
        if not model or model == "" or model == "models/error.mdl" then return end
        self.SourceCharacter = character
        self.SourcePlayer = ply

        local entity = self:GetEntity()
        local newModel = self.SourceModel ~= model or not IsValid(entity)
        if newModel then
            local now = RealTime()
            if self.SourceModel == model and now < self.NextModelAttempt then return end
            self.SourceModel = model
            self.NextModelAttempt = now + 1
            self:SetModel(model)
            entity = self:GetEntity()
            if not IsValid(entity) then return end

            local equipmentModels, armorModels = {}, {}
            entity.PreviewEquipmentModels = equipmentModels
            entity.modelArmor = armorModels
            entity:CallOnRemove("CatatoniaPreviewEquipment", function()
                RemovePreviewModels(equipmentModels)
                RemovePreviewModels(armorModels)
            end)
            function entity:GetPlayerColor()
                return self.PreviewPlayerColor
            end

            local sequence = entity:LookupSequence("idle_suitcase")
            if sequence < 0 then sequence = entity:SelectWeightedSequence(ACT_IDLE) end
            if sequence >= 0 then entity:ResetSequence(sequence) end
            self:SetAnimated(sequence >= 0)
        end

        local scale = character:GetModelScale()
        if newModel or entity:GetModelScale() ~= scale then
            entity:SetModelScale(scale, 0)
            local mins, maxs = entity:GetModelRenderBounds()
            local center = (mins + maxs) * (scale * 0.5)
            local size = (maxs - mins) * scale
            local aspect = self:GetWide() / self:GetTall()
            local halfWidth = math.max((size.z * 0.55 + 8) * aspect, math.max(size.x, size.y) * 0.56 + 6)
            local distance = halfWidth / math.tan(math.rad(self:GetFOV() * 0.5)) + size.x / 2
            self:SetLookAt(center)
            self:SetCamPos(center + cameraDirection * distance)
        end

        entity.PreviewPlayerColor = character:GetNWVector("PlayerColor", ply:GetPlayerColor())
        local skin, material = character:GetSkin(), character:GetMaterial()
        if entity:GetSkin() ~= skin then entity:SetSkin(skin) end
        if entity:GetMaterial() ~= material then entity:SetMaterial(material) end
        for _, group in ipairs(character:GetBodyGroups()) do
            local bodygroup = character:GetBodygroup(group.id)
            if entity:GetBodygroup(group.id) ~= bodygroup then entity:SetBodygroup(group.id, bodygroup) end
        end
        for index = 0, 31 do
            local material = character:GetSubMaterial(index)
            if entity:GetSubMaterial(index) ~= material then
                entity:SetSubMaterial(index, material ~= "" and material or nil)
            end
        end
        for _, slot in ipairs(clothingSlots) do
            local key = "Colthes" .. slot
            local style = character:GetNWString(key, ply:GetNWString(key, "normal"))
            if entity:GetNWString(key) ~= style then entity:SetNWString(key, style) end
        end
    end

    function preview:LayoutEntity()
        if self:GetAnimated() then self:RunAnimation() end
    end

    function preview:PreDrawModel()
        return IsValid(self.SourceCharacter) and IsValid(self.SourcePlayer)
    end

    function preview:PostDrawModel(entity)
        local character, ply = self.SourceCharacter, self.SourcePlayer
        local accessoryList = character:GetNetVar("Accessories") or character.PredictedAccessories or ply:GetNetVar("Accessories")
        if isstring(accessoryList) then accessoryList = {accessoryList} end
        local armors = character:GetNetVar("Armor") or character.PredictedArmor
        local armorOwner = armors and character or ply
        armors = armors or ply:GetNetVar("Armor", {})
        local equipmentOwner = character:GetNetVar("zc_equipment") and character or ply
        local equipment = equipmentOwner:GetEquipments()

        entity.PredictedAccessories = accessoryList
        entity.armors = armors
        entity:SetupBones()
        for _, name in ipairs(accessoryList or {}) do
            local data = hg.Accessories[name]
            local slot = data and hg.EquipmentAppearanceSlots[data.placement]
            if data and not (slot and IsValid(equipmentOwner:GetEquipmentBySlot(slot))) then
                DrawAccesories(entity, entity, name, data, false, true, nil, accessoryList)
            end
        end

        local hideArmor = ply:GetNetVar("HideArmorRender", false) or character.PredictedHideArmorRender
        if not hideArmor and next(armors) then DrawArmors(armorOwner, armors, entity, true) end

        local equipmentModels = entity.PreviewEquipmentModels
        for item, model in pairs(equipmentModels) do
            if not IsValid(item) or not table.HasValue(equipment, item:EntIndex()) then
                if IsValid(model) then model:Remove() end
                equipmentModels[item] = nil
            end
        end
        for _, index in ipairs(equipment) do
            local item = Entity(index)
            if IsValid(item) and item.RenderOnBody then item:RenderOnBody(entity, equipmentModels) end
        end
    end

    preview:Think()
    return preview
end

DISCORD_URL = "https://discord.gg/475EmEdTgH"

local Selects = {
    {Title = "Disconnect", Func = function(luaMenu) RunConsoleCommand("disconnect") end},
    {Title = "Main Menu", Func = function(luaMenu) gui.ActivateGameUI() luaMenu:Close() end},
    {Title = "Discord", Func = function(luaMenu) luaMenu:Close() gui.OpenURL(DISCORD_URL)  end},
    {Title = "Traitor Role",
    GamemodeOnly = true,
    CreatedFunc = function(row, luaMenu)
        local soe = CreateMenuButton(row, "SOE")
        function soe:DoClick()
            luaMenu:Close()
            hg.SelectPlayerRole(nil, "soe")
        end

        local std = CreateMenuButton(row, "STD")
        function std:DoClick()
            luaMenu:Close()
            hg.SelectPlayerRole(nil, "standard")
        end
    end,
    Func = function(luaMenu)
        
    end,
    },
    {Title = "Achievements", Tab = true, Func = function(luaMenu,pp) 
        hg.DrawAchievmentsMenu(pp)
    end},
    {Title = "Settings", Tab = true, Func = function(luaMenu,pp) 
        hg.DrawSettings(pp) 
    end},
    {Title = "Appearance", Tab = true, Func = function(luaMenu,pp) hg.CreateApperanceMenu(pp) end},
    {Title = "Return", Func = function(luaMenu) luaMenu:Close() end},
}

function PANEL:PaintTitle(x, y)
    local now = RealTime()
    local frame = FrameNumber()
    if now >= self.NextTitleFlash then
        self.TitleFlashFrame = frame
        self.TitleFlashDirection = math.random(0, 1) == 0 and -1 or 1
        self.NextTitleFlash = now + math.Rand(4, 9)
    end

    local drift = math.sin(now * 2.1) * titleSize * 0.085
    local stretch = 1.04 + math.sin(now * 1.6 + 0.9) * 0.075
    local opacity = 118 + math.sin(now * 3.3) * 44
    local flashAge = frame - (self.TitleFlashFrame or -flashFrameCount)
    if flashAge < flashFrameCount then
        local strength = 1 - flashAge * 0.4
        drift = self.TitleFlashDirection * titleSize * 0.32 * strength
        stretch = stretch + 0.1 * strength
        opacity = Lerp(strength, opacity, 240)
    end

    local centerX = self:LocalToScreen(x + self.TitleWidth / 2, y)
    local matrix = self.TitleGlowMatrix
    matrix:SetScale(Vector(stretch, 1, 1))
    matrix:SetTranslation(Vector(drift + centerX * (1 - stretch), 0, 0))
    titleGlow.a = opacity
    cam.PushModelMatrix(matrix, true)
    draw.SimpleText(title, titleBlurFont, x, y, titleGlow, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
    cam.PopModelMatrix()
    draw.SimpleText(title, titleFont, x, y, color_white, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
end

function PANEL:Init()
    self:SetAlpha(0)
    self:SetSize(ScrW(), ScrH())
    self:Center()
    self:SetTitle("")
    self:SetDraggable(false)
    self:SetBorder(false)
    self:ShowCloseButton(false)
    self.NextTitleFlash = RealTime() + math.Rand(4, 9)
    self.TitleGlowMatrix = Matrix()

    timer.Simple(0, function()
        if self.First then
            self:First()
        end
    end)

    local lDock = vgui.Create("DPanel", self)
    lDock:Dock(LEFT)
    lDock:DockMargin(0, ScreenScaleH(36), 0, ScreenScaleH(60))
    lDock.Paint = function() end
    self.TitleDock = lDock

    surface.SetFont(titleFont)
    self.TitleWidth = surface.GetTextSize(title)
    local titleX = ScreenScale(18)
    local menuWidth = math.max(ScreenScale(190), self.TitleWidth + titleX * 2)
    for _, item in ipairs(Selects) do
        if item.GamemodeOnly and engine.ActiveGamemode() != "zcity" then continue end
        menuWidth = math.max(menuWidth, self:AddSelect(lDock, item.Title, item) + titleX * 2)
    end
    lDock:SetWide(menuWidth)

    CreateMenuFooter(self)

    self.panelparrent = vgui.Create("DPanel", self)
    self.panelparrent:SetPos(menuWidth, 0)
    self.panelparrent:SetSize(ScrW() - menuWidth, ScrH())
    self.panelparrent.Paint = function(this, w, h) end
    self.CharacterPreview = CreateCharacterPreview(self, menuWidth)
end

function PANEL:First( ply )
    self:AlphaTo( 255, 0.1, 0, nil )
end

function PANEL:Paint(w, h)
    surface.SetDrawColor(0, 0, 0, 255)
    surface.SetMaterial(leftGradient)
    surface.DrawTexturedRect(0, 0, w * 0.38, h)
    local x, y = self.TitleDock:GetPos()
    self:PaintTitle(x + ScreenScale(18), y + math.ceil(titleSize * 0.12))
end

function PANEL:AddSelect( pParent, strTitle, tbl )
    local row = vgui.Create("DPanel", pParent)
    row:Dock(BOTTOM)
    row:DockMargin(ScreenScale(13), ScreenScaleH(1), 0, 0)
    row:SetTall(math.ceil(buttonSize * 1.3))
    row.Paint = function() end

    local btn = CreateMenuButton(row, strTitle)
    local luaMenu = self
    if tbl.CreatedFunc then tbl.CreatedFunc(row, luaMenu) end

    function btn:DoClick()
        luaMenu:SelectItem(tbl)
    end

    local rowWidth = 0
    for _, button in ipairs(row:GetChildren()) do
        rowWidth = rowWidth + button:GetWide()
    end
    return rowWidth
end

function PANEL:SelectItem(item)
    if self.Closing then return end

    local closingTab = item.Tab and self.ActiveTab == item.Title
    self.ActiveTab = item.Tab and not closingTab and item.Title or nil
    if self.ActiveTab then self.CharacterPreview:SetVisible(false) end

    local previous = self.panelparrent
    previous:Stop()
    previous:AlphaTo(0, 0.2, 0, function()
        if not IsValid(self) or self.Closing or not IsValid(previous) then return end

        local x, y = previous:GetPos()
        local w, h = previous:GetSize()
        previous:Remove()

        local content = vgui.Create("DPanel", self)
        content:SetPos(x, y)
        content:SetSize(w, h)
        content.Paint = function() end
        self.panelparrent = content
        self.CharacterPreview:SetVisible(self.ActiveTab == nil)

        if not closingTab then item.Func(self, content) end
    end)

    local sound = closingTab and "shitty/tap_release.wav" or "shitty/tap_depress.wav"
    for i = 1, 3 do surface.PlaySound(sound) end
end

function PANEL:Close()
    if self.Closing then return end
    self.Closing = true
    self.CharacterPreview:SetVisible(false)
    self:AlphaTo( 0, 0.1, 0, function() self:Remove() end)
    self:SetKeyboardInputEnabled(false)
    self:SetMouseInputEnabled(false)
end

vgui.Register( "ZMainMenu", PANEL, "ZFrame")

hook.Add("OnPauseMenuShow","OpenMainMenu",function()
    local run = hook.Run("OnShowZCityPause")
    if run != nil then
        return run
    end

    if MainMenu and IsValid(MainMenu) then
        MainMenu:Close()
        MainMenu = nil
        return false
    end

    MainMenu = vgui.Create("ZMainMenu")
    MainMenu:MakePopup()
    return false
end)
