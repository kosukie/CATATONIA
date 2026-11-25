local PANEL = {}
local curent_panel 
local red_select = Color(170,0,0)

DISCORD_URL = "https://discord.gg/475EmEdTgH"

local Selects = {
    {Title = "Disconnect", Func = function(luaMenu) RunConsoleCommand("disconnect") end},
    {Title = "Main Menu", Func = function(luaMenu) gui.ActivateGameUI() luaMenu:Close() end},
    {Title = "Discord", Func = function(luaMenu) luaMenu:Close() gui.OpenURL(DISCORD_URL)  end},
    {Title = "Traitor Role",
    GamemodeOnly = true,
    CreatedFunc = function(self, parent, luaMenu)
        local btn = vgui.Create( "DLabel", self )
        btn:SetText( "SOE" )
        btn:SetMouseInputEnabled( true )
        btn:SizeToContents()
        btn:SetFont( "AoM_MM_Btn" )
        btn:SetTall( ScreenScale( 15 ) )
        btn:Dock(BOTTOM)
        btn:DockMargin(ScreenScale(20),ScreenScale(10),0,0)
        btn:SetTextColor(Color(255,255,255))
        btn:InvalidateParent()
        btn.RColor = Color(225, 225, 225, 0)
        btn.WColor = Color(225, 225, 225, 255)
        btn.x = btn:GetX()

        function btn:DoClick()
            luaMenu:Close()
            hg.SelectPlayerRole(nil, "soe")
        end
    
        local selfa = self
        function btn:Think()
            self.HoverLerp = selfa.HoverLerp
            self.HoverLerp2 = LerpFT(0.2, self.HoverLerp2 or 0, self:IsHovered() and 1 or 0)
                
            self:SetTextColor(self.RColor:Lerp(self.WColor:Lerp(red_select, self.HoverLerp2), self.HoverLerp))
            self:SetX(self.x + ScreenScaleH(40) + self.HoverLerp * ScreenScaleH(50))
            if self:IsHovered() then
                self:SetTextInset(5 + math.random(-3, 3), 5 + math.random(-3, 3))
            else
                self:SetTextInset(5, 5)
            end
        end

        local btn = vgui.Create( "DLabel", btn )
        btn:SetText( "STD" )
        btn:SetMouseInputEnabled( true )
        btn:SizeToContents()
        btn:SetFont( "AoM_MM_Btn" )
        btn:SetTall( ScreenScale( 15 ) )
        btn:Dock(BOTTOM)
        btn:DockMargin(0,ScreenScale(2),0,0)
        btn:SetTextColor(Color(255,255,255))
        btn:InvalidateParent()
        btn.RColor = Color(225, 225, 225, 0)
        btn.WColor = Color(225, 225, 225, 255)
        btn.x = btn:GetX()

        function btn:DoClick()
            luaMenu:Close()
            hg.SelectPlayerRole(nil, "standard")
        end
    
        function btn:Think()
            self.HoverLerp = selfa.HoverLerp
            self.HoverLerp2 = LerpFT(0.2, self.HoverLerp2 or 0, self:IsHovered() and 1 or 0)
    
            self:SetTextColor(self.RColor:Lerp(self.WColor:Lerp(red_select, self.HoverLerp2), self.HoverLerp))
            self:SetX(self.x + ScreenScaleH(35))
            if self:IsHovered() then
                self:SetTextInset(5 + math.random(-3, 3), 5 + math.random(-3, 3))
            else
                self:SetTextInset(5, 5)
            end
        end
    end,
    Func = function(luaMenu)
        
    end,
    },
    {Title = "Achievements", Func = function(luaMenu,pp) 
        hg.DrawAchievmentsMenu(pp)
    end},
    {Title = "Settings", Func = function(luaMenu,pp) 
        hg.DrawSettings(pp) 
    end},
    {Title = "Appearance", Func = function(luaMenu,pp) hg.CreateApperanceMenu(pp) end},
    {Title = "Return", Func = function(luaMenu) luaMenu:Close() end},
}

local splasheh = {
    'LIKE HOMICIDED',
    'PLUV PLUV PLUVISKI',
    'LULU IS NOT DEAD | !PLUV',
    'THE TRAITOR WAS KILLED',
    'NAB HOMICIDE SERVER',
    'ALSO TRY MODDED HOMICIDE 2',
    'HOP ON CATATONIA',
    'JOHN CATATONIA',
    ':pluvrare:',
    'SAW51 IS REAL',
    'MORE SMALLTOWN',
    'MORE CLUE2022',
    'BACKROOMS == CLUE',
    'HELL IS NEAR',
    'I WISH YOU GOOD HEALTH, JASON STATHAM'
}

--print(string.upper('I wish you good health, Jason Statham'))
surface.CreateFont("ZC_MM_Title", {
    font = "Bahnschrift",
    size = ScreenScale(40),
    weight = 800,
    antialias = true
})

-- Afraid of Monsters style fonts (AoM.ttf internal name "AoM")
surface.CreateFont("AoM_MM_Title", {
    font = "AoM",
    size = ScreenScale(48),
    weight = 800,
    antialias = true
})

surface.CreateFont("AoM_MM_Btn", {
    font = "AoM",
    size = ScreenScale(16),
    weight = 600,
    antialias = true
})
-- local Title = markup.Parse("error")

local Pluv = Material("pluv/pluvkid.jpg")

function PANEL:InitializeMarkup()
	local mapname = game.GetMap()
	local prefix = string.find(mapname, "_")
	if prefix then
		mapname = string.sub(mapname, prefix + 1)
	end
	local gm = splasheh[math.random(#splasheh)] .. " | " .. string.NiceName(mapname) 

    if hg.PluvTown and hg.PluvTown.Active then
        local text = "<font=AoM_MM_Title><colour=210,210,210>CATATONIA</colour></font>\n<font=ZCity_Tiny><colour=105,105,105>" .. gm .. "</colour></font>"

        self.SelectedPluv = table.Random(hg.PluvTown.PluvMats)

        return markup.Parse(text)
    end

    local text = "<font=AoM_MM_Title><colour=210,210,210,255>CATATONIA</colour></font>\n<font=ZCity_Tiny><colour=105,105,105>" .. gm .. "</colour></font>"
    return markup.Parse(text)
end

local color_red = Color(255,25,25,45)
local clr_gray = Color(255,255,255,25)
local clr_verygray = Color(10,10,19,235)

function PANEL:Init()
    self:SetAlpha(0)
    self:SetSize(ScrW(), ScrH())
    self:Center()
    self:SetTitle("")
    self:SetDraggable(false)
    self:SetBorder(false)
    self:SetColorBG(clr_verygray)
    self:SetDraggable(false)
    self:ShowCloseButton(false)
    curent_panel = nil
    self.Title, self.TitleShadow = self:InitializeMarkup()

    timer.Simple(0, function()
        if self.First then
            self:First()
        end
    end)

    self.lDock = vgui.Create("DPanel", self)
    local lDock = self.lDock
    lDock:Dock(LEFT)
    lDock:SetSize(ScrW() / 4, ScrH())
    lDock:DockMargin(ScreenScale(0), ScreenScaleH(90), ScreenScale(10), ScreenScaleH(90))
    lDock.Paint = function(this, w, h)
        if hg.PluvTown.Active then
            surface.SetDrawColor(color_white)
            surface.SetMaterial(self.SelectedPluv or Pluv)
            surface.DrawTexturedRect(0, ScreenScale(27), ScreenScale(35), ScreenScale(27))
        end

        self.Title:Draw(ScreenScale(15), ScreenScale(50), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER, 255, TEXT_ALIGN_LEFT)
    end

    self.Buttons = {}
    for k, v in ipairs(Selects) do
        if v.GamemodeOnly and engine.ActiveGamemode() != "zcity" then continue end
        self:AddSelect(lDock, v.Title, v)
    end


    local bottomDock = vgui.Create("DPanel", self)
    bottomDock:SetPos(ScreenScale(1), ScrH() - ScrH()/10)
    bottomDock:SetSize(ScreenScale(190), ScreenScaleH(40))
    bottomDock.Paint = function(this, w, h) end
    self.panelparrent = vgui.Create("DPanel", self)
    -- Исходная ширина и позиция по центру: подменю (Settings/Appearance) рисуются
    -- на всю ширину panelparrent, поэтому не должны сжиматься правой модельной панелью
    self.ModelW = ScrW() * 0.32
    self.panelparrent:SetSize(ScrW(), ScrH())
    self.panelparrent:SetPos(0, 0)
    self.panelparrent:Center()
    self.panelparrent.Paint = function(this, w, h) end
    
    local git = vgui.Create("DLabel", bottomDock)
    git:Dock(BOTTOM)
    git:DockMargin(ScreenScale(10), 0, 0, 0)
    git:SetFont("ZCity_Tiny")
    git:SetTextColor(clr_gray)
    git:SetText("GitHub: github.com/" .. hg.GitHub_ReposOwner .. "/" .. hg.GitHub_ReposName)
    git:SetContentAlignment(4)
    git:SetMouseInputEnabled(true)
    git:SizeToContents()

    function git:DoClick()
        gui.OpenURL("https://github.com/" .. hg.GitHub_ReposOwner .. "/" .. hg.GitHub_ReposName)
    end

    local version = vgui.Create("DLabel", bottomDock)
    version:Dock(BOTTOM)
    version:DockMargin(ScreenScale(10), 0, 0, 0)
    version:SetFont("ZCity_Tiny")
    version:SetTextColor(clr_gray)
    version:SetText(hg.Version)
    version:SetContentAlignment(4)
    version:SizeToContents()

    local zteam = vgui.Create("DLabel", bottomDock)
    zteam:Dock(BOTTOM)
    zteam:DockMargin(ScreenScale(10), 0, 0, 0)
    zteam:SetFont("ZCity_Tiny")
    zteam:SetTextColor(clr_gray)
    zteam:SetText("Authors: uzelezz, Sadsalat, \nMr.Point, Zac90, Deka, Mannytko")
    zteam:SetContentAlignment(4)
    zteam:SizeToContents()

    -- Player character preview on the right (Afraid of Monsters style)
    self:CreateModelPanel()
end

function PANEL:CreateModelPanel()
    local mdlW = self.ModelW or ScrW() * 0.32
    local mp = vgui.Create("DModelPanel", self)
    self.ModelPanel = mp
    mp:SetSize(mdlW, ScrH())
    mp:SetPos(ScrW() - mdlW, 0)
    mp:SetFOV(55)
    -- Closer camera so the model fills ~70% of screen height on the right side
    mp:SetCamPos(Vector(38, 0, 46))
    mp:SetLookAt(Vector(0, 0, 38))
    -- Cold, dim, moody lighting
    mp:SetDirectionalLight(BOX_TOP, Color(110, 120, 150))
    mp:SetDirectionalLight(BOX_FRONT, Color(45, 48, 55))
    mp:SetDirectionalLight(BOX_BACK, Color(75, 0, 0))
    mp:SetDirectionalLight(BOX_BOTTOM, Color(0, 0, 0))
    mp:SetAmbientLight(Color(22, 22, 26, 255))
    mp:SetMouseInputEnabled(false)
    mp.bAnimated = false

    function mp:LayoutEntity(ent)
        if not IsValid(ent) then return end
        local seq = ent:SelectWeightedSequence(ACT_HL2MP_IDLE)
        if seq and seq ~= -1 then
            ent:SetSequence(seq)
        else
            ent:SetSequence(ent:LookupSequence("idle_all_01") or 0)
        end
    end

    function mp:OnMousePressed() end
    function mp:OnMouseWheeled() end
    function mp:DragMousePress() end
    function mp:DragMouseRelease() end

    local parent = self
    function mp:Think()
        self._nextRefresh = (self._nextRefresh or 0)
        if CurTime() >= self._nextRefresh then
            self._nextRefresh = CurTime() + 1
            if IsValid(parent) then parent:RefreshModel() end
        end
    end

    timer.Simple(0, function()
        if IsValid(self) then self:RefreshModel() end
    end)
end

function PANEL:RefreshModel()
    local mp = self.ModelPanel
    if not IsValid(mp) then return end
    local ply = LocalPlayer()
    if not IsValid(ply) then return end

    local AP = hg.Appearance
    local appearance = (AP and AP.LoadAppearanceFile and AP.SelectedAppearance)
        and AP.LoadAppearanceFile(AP.SelectedAppearance:GetString()) or nil

    local model = ply:GetModel()
    local tMdl = nil
    if appearance and appearance.AModel and AP and AP.PlayerModels then
        tMdl = (AP.PlayerModels[1] and AP.PlayerModels[1][appearance.AModel])
            or (AP.PlayerModels[2] and AP.PlayerModels[2][appearance.AModel])
        if tMdl and tMdl.mdl then model = tMdl.mdl end
    end

    mp:SetModel(model)
    local ent = mp.Entity
    if not IsValid(ent) then return end

    -- Skin & bodygroups from the current player
    ent:SetSkin(ply:GetSkin())
    local bgs = ply:GetBodyGroups()
    if bgs then
        for _, bg in ipairs(bgs) do
            ent:SetBodygroup(bg.id, ply:GetBodygroup(bg.id))
        end
    end

    -- Apply appearance: clothes, facemap, player color, bodygroups
    if appearance and tMdl and AP then
        local sex = (tMdl.sex and 2) or 1

        if appearance.AColor then
            ent:SetNWVector("PlayerColor", Vector(
                appearance.AColor.r / 255,
                appearance.AColor.g / 255,
                appearance.AColor.b / 255
            ))
        end
        ent.GetPlayerColor = function() end

        local mats = ent:GetMaterials()

        -- Clothes submaterials
        if tMdl.submatSlots and AP.Clothes and AP.Clothes[sex] then
            for slotName, matName in pairs(tMdl.submatSlots) do
                local slot = 0
                for i = 1, #mats do
                    if mats[i] == matName then slot = i - 1 break end
                end
                local clothName = appearance.AClothes and appearance.AClothes[slotName]
                local clothMat = AP.Clothes[sex][clothName] or AP.Clothes[sex]["normal"]
                if clothMat then ent:SetSubMaterial(slot, clothMat) end
            end
        end

        -- Facemap
        if appearance.AFacemap and AP.FacemapsSlots then
            for i = 1, #mats do
                local faceSlots = AP.FacemapsSlots[mats[i]]
                if faceSlots and faceSlots[appearance.AFacemap] then
                    ent:SetSubMaterial(i - 1, faceSlots[appearance.AFacemap])
                end
            end
        end

        -- Bodygroups from appearance table
        if appearance.ABodygroups and AP.Bodygroups then
            local entBgs = ent:GetBodyGroups()
            if entBgs then
                for _, bg in ipairs(entBgs) do
                    local chosen = appearance.ABodygroups[bg.name]
                    local bgTab = AP.Bodygroups[bg.name]
                    if chosen and bgTab and bgTab[sex] and bgTab[sex][chosen] then
                        for i = 0, #bg.submodels do
                            if bg.submodels[i] == bgTab[sex][chosen][1] then
                                ent:SetBodygroup(bg.id, i)
                                break
                            end
                        end
                    end
                end
            end
        end
    end
end

function PANEL:First( ply )
    self:AlphaTo( 255, 0.1, 0, nil )
end

local gradient_d = surface.GetTextureID("vgui/gradient-d")
local gradient_r = surface.GetTextureID("vgui/gradient-u")
local gradient_l = surface.GetTextureID("vgui/gradient-l")

local clr_1 = Color(15,15,15,40)
function PANEL:Paint(w,h)
    draw.RoundedBox( 0, 0, 0, w, h, self.ColorBG )
    hg.DrawBlur(self, 5)
    surface.SetDrawColor( self.ColorBG )
    surface.SetTexture( gradient_l )
    surface.DrawTexturedRect(0,0,w,h)
    surface.SetDrawColor( clr_1 )
    surface.SetTexture( gradient_d )
    surface.DrawTexturedRect(0,0,w,h)
end

function PANEL:Think()
    -- Hide the character preview while any sub-menu (Settings, Appearance, ...) is open
    if IsValid(self.ModelPanel) then
        self.ModelPanel:SetVisible(curent_panel == nil)
    end
end

function PANEL:AddSelect( pParent, strTitle, tbl )
    local id = #self.Buttons + 1
    self.Buttons[id] = vgui.Create( "DLabel", pParent )
    local btn = self.Buttons[id]
    btn:SetText( strTitle )
    btn:SetMouseInputEnabled( true )
    btn:SizeToContents()
    btn:SetFont( "AoM_MM_Btn" )
    btn:SetTall( ScreenScale( 15 ) )
    btn:Dock(BOTTOM)
    btn:DockMargin(ScreenScale(15),ScreenScale(1.5),0,0)
    btn.Func = tbl.Func
    btn.HoveredFunc = tbl.HoveredFunc
    local luaMenu = self
    if tbl.CreatedFunc then tbl.CreatedFunc(btn, self, luaMenu) end
    btn.RColor = Color(225,225,225)

    -- Восстанавливает panelparrent с исходной шириной и позицией по центру,
    -- чтобы окна Settings/Appearance не сжимались и вёрстка не наезжала друг на друга
    local function ResetPanelParent(menu)
        menu.panelparrent = vgui.Create("DPanel", menu)
        menu.panelparrent:SetSize(ScrW(), ScrH())
        menu.panelparrent:SetPos(0, 0)
        menu.panelparrent:Center()
        menu.panelparrent.Paint = function(this, w, h) end
        return menu.panelparrent
    end

    function btn:DoClick()
        -- ,kz оптимизировать надо, но идёт ошибка(кэшировать бы luaMenu.panelparrent вместо вызова его каждый раз)
        if curent_panel == string.lower(strTitle) then
			for i = 1, 3 do
				surface.PlaySound("shitty/tap_release.wav")
			end
            local old = luaMenu.panelparrent
            if IsValid(old) then
                old:AlphaTo(0,0.2,0,function()
                    if IsValid(old) then old:Remove() end
                    ResetPanelParent(luaMenu)
                    curent_panel = nil
                end)
            else
                ResetPanelParent(luaMenu)
                curent_panel = nil
            end
            return
        end
        local old = luaMenu.panelparrent
        local function OpenSubMenu()
            if IsValid(old) then old:Remove() end
            local pp = ResetPanelParent(luaMenu)
            pp:SetAlpha(0)
            btn.Func(luaMenu,pp)
            pp:AlphaTo(255,0.2,0)
            curent_panel = string.lower(strTitle)
        end
        if IsValid(old) then
            old:AlphaTo(0,0.2,0,OpenSubMenu)
        else
            OpenSubMenu()
        end
		for i = 1, 3 do
			surface.PlaySound("shitty/tap_depress.wav")
		end
    end

    function btn:Think()
        self.HoverLerp = LerpFT(0.2, self.HoverLerp or 0, (self:IsHovered() or (IsValid(self:GetChild(0)) and self:GetChild(0):IsHovered()) or (IsValid(self:GetChild(0)) and IsValid(self:GetChild(0):GetChild(0)) and self:GetChild(0):GetChild(0):IsHovered())) and 1 or 0)

        local v = self.HoverLerp
        self:SetTextColor(self.RColor:Lerp(red_select, v))

        -- Nervous shake on hover: text jitters 1-3px each frame
        if self:IsHovered() then
            self:SetTextInset(5 + math.random(-3, 3), 5 + math.random(-3, 3))
        else
            self:SetTextInset(5, 5)
        end

        local targetText = (self:IsHovered()) and string.upper(strTitle) or strTitle
        local crw = self:GetText()

        if (crw ~= targetText) or (curent_panel == string.lower(strTitle)) then
            local ntxt = ""
            local will_text = (curent_panel == string.lower(strTitle) and not strTitle == 'Traitor Role') and '[ '..string.upper(strTitle)..' ]' or strTitle
            for i = 1, #will_text do
                local char = will_text:sub(i, i)
                if i <= math.ceil(#will_text * v) then
                    ntxt = ntxt .. string.upper(char)
                else
                    ntxt = ntxt .. char
                end
            end
			if self:GetText() ~= ntxt then
				surface.PlaySound("shitty/tap-resonant.wav")
			end
            self:SetText(ntxt)
        end
        self:SizeToContents()
    end
end

function PANEL:Close()
    curent_panel = nil
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
