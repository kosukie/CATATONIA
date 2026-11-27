local voiceFont = "CatatoniaVoiceName"
local fallbackFont = "CatatoniaVoiceNameFallback"
local cardColor = Color(10, 10, 10, 220)
local shadowColor = Color(0, 0, 0, 230)

local scale, padding, avatarSize, nameGap

local function Scaled(pixels)
	return math.max(1, math.Round(pixels * scale))
end

local function UpdateVoiceMetrics()
	scale = math.Clamp(1.7 * ScrH() / 1440, 0.6, 3)
	padding = Scaled(7)
	avatarSize = Scaled(26)
	nameGap = Scaled(8)

	local fontSize = Scaled(18)
	surface.CreateFont(voiceFont, {
		font = system.IsLinux() and "AoM.ttf" or "JohnstempW04-Medium",
		size = fontSize,
		weight = 700,
	})
	surface.CreateFont(fallbackFont, {font = "Arial", size = fontSize, extended = true})
end

local function SetNameFont(label, name)
	-- Keep names with Cyrillic and other non-ASCII characters readable.
	label:SetFont(name:find("[\128-\255]") and fallbackFont or voiceFont)
end

local function PaintVoiceCard(panel, w, h)
	local volume = 0
	if IsValid(panel.ply) then
		volume = panel.ply:VoiceVolume()
	elseif panel.plyIndex then
		local talking, level = util.IsPlayerSpeaking(panel.plyIndex)
		if talking then volume = level or 0 end
	end

	local level = Lerp(1 - math.exp(-18 * RealFrameTime()), panel.CatatoniaVoiceLevel or 0, math.Clamp(volume, 0, 1))
	panel.CatatoniaVoiceLevel = level

	surface.SetDrawColor(cardColor)
	surface.DrawRect(0, 0, w, h)
	local inset = Scaled(2)
	hg.WeaponSelector.DrawGrungeFrame(inset, inset, w - 2 * inset, h - 2 * inset, scale, 185 + 70 * level)

	local meterX, meterY = padding + avatarSize + nameGap, h - Scaled(9)
	local meterWidth = w - meterX - Scaled(9)
	local meterHeight = Scaled(1)
	surface.SetDrawColor(255, 255, 255, 42)
	surface.DrawRect(meterX, meterY, meterWidth, meterHeight)
	surface.SetDrawColor(255, 255, 255, 230)
	surface.DrawRect(meterX, meterY, math.Round(meterWidth * level), meterHeight)
end

local function PaintAvatarFrame(panel)
	local x, y = panel.Avatar:GetPos()
	local w, h = panel.Avatar:GetSize()
	surface.SetDrawColor(10, 10, 10, 115)
	surface.DrawRect(x, y, w, h)
	surface.SetDrawColor(255, 255, 255, 185)
	surface.DrawOutlinedRect(x - 1, y - 1, w + 2, h + 2)
end

local function StyleVoiceCard(panel)
	if not IsValid(panel.LabelName) or not IsValid(panel.Avatar) then return end

	panel.Paint = PaintVoiceCard
	panel.PaintOver = PaintAvatarFrame
	local margin = Scaled(2)
	panel:SetTall(avatarSize + 2 * padding)
	panel:DockMargin(margin, margin, margin, margin)
	panel:DockPadding(padding, padding, Scaled(9), padding)
	panel.Avatar:SetWide(avatarSize)
	panel.LabelName:DockMargin(nameGap, 0, 0, padding)
	panel.LabelName:SetTextColor(color_white)
	panel.LabelName:SetExpensiveShadow(Scaled(1), shadowColor)
	SetNameFont(panel.LabelName, panel.LastName or "")

	panel.CatatoniaOriginalSetText = panel.CatatoniaOriginalSetText or panel.SetText
	panel.SetText = function(self, name)
		if self.LastName ~= name then SetNameFont(self.LabelName, name) end
		self:CatatoniaOriginalSetText(name)
	end
end

local function PositionVoiceList()
	local list = g_VoicePanelList
	if not IsValid(list) then return end

	local top = math.Round(ScrH() * 0.13)
	local bottom = hg.GetCatatoniaWatermarkTop() - Scaled(8)
	local right = ScrW() - Scaled(10)
	local width = math.min(Scaled(250), right)
	list:SetSize(width, bottom - top)
	list:SetPos(right - width, top)
end

local function StyleVoiceList()
	local list = g_VoicePanelList
	if not IsValid(list) then return end

	-- The base gamemode still creates and fades the cards, including repeat speakers.
	if list.CatatoniaOriginalOnChildAdded == nil then
		list.CatatoniaOriginalOnChildAdded = list.OnChildAdded or false
	end
	list.OnChildAdded = function(self, child)
		if self.CatatoniaOriginalOnChildAdded then self:CatatoniaOriginalOnChildAdded(child) end
		-- OnChildAdded runs before VoiceNotify has initialized its label and avatar.
		timer.Simple(0, function()
			if IsValid(child) and child:GetParent() == self then StyleVoiceCard(child) end
		end)
	end

	for _, child in ipairs(list:GetChildren()) do
		StyleVoiceCard(child)
	end
	PositionVoiceList()
end

hook.Add("InitPostEntity", "CatatoniaVoicePanels", function()
	timer.Simple(0, StyleVoiceList)
end)
hook.Add("OnScreenSizeChanged", "CatatoniaVoicePanels", function()
	-- Measure after the watermark has rebuilt its font at the new resolution.
	UpdateVoiceMetrics()
	timer.Simple(0, StyleVoiceList)
end)

UpdateVoiceMetrics()
StyleVoiceList()
