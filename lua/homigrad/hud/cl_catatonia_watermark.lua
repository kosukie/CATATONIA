local watermarkText = "CATATONIA | OPEN BETA | by kosuke_ (github.com/kosukie/CATATONIA)"
local watermarkColor = Color(255, 255, 255, 45)
local drawHUD = GetConVar("cl_drawhud")

local function CreateWatermarkFont()
	surface.CreateFont("CatatoniaWatermark", {
		font = system.IsLinux() and "AoM.ttf" or "JohnstempW04-Medium",
		size = math.max(16, math.Round(ScrH() * 0.018)),
	})
end

CreateWatermarkFont()
hook.Add("OnScreenSizeChanged", "CatatoniaWatermark", CreateWatermarkFont)

hook.Add("HUDPaint", "CatatoniaWatermark", function()
	if not drawHUD:GetBool() then return end
	if IsValid(MainMenu) and MainMenu:IsVisible() then return end

	draw.SimpleText(watermarkText, "CatatoniaWatermark", ScrW() - 12, ScrH() - 10,
		watermarkColor, TEXT_ALIGN_RIGHT, TEXT_ALIGN_BOTTOM)
end)
