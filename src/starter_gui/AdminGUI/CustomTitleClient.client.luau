-- ========================================
-- CUSTOM TITLE CLIENT
-- Place in: StarterGui > AdminGUI(ScreenGui) > CustomTitleClient(LocalScript)
-- Inject UI ke CustomTitlePage di admin panel
-- ========================================

local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService  = game:GetService("UserInputService")
local TweenService      = game:GetService("TweenService")

local Modules     = ReplicatedStorage:WaitForChild("Modules")
local AdminConfig = require(Modules:WaitForChild("AdminConfig"))
local ThemeModule = require(Modules:WaitForChild("ThemeModule"))

local player     = Players.LocalPlayer
local TitleEvent = ReplicatedStorage:WaitForChild("TitleEvent", 10)
if not TitleEvent then return end

AdminConfig.WaitForGUIReady()

local page = AdminConfig.GUI.CustomTitlePage
if not page then
	warn("[CustomTitleClient] CustomTitlePage not found")
	return
end

ThemeModule.GradientSystem.Start()

-- ========================================
-- DATA
-- ========================================
local ColorTemplates = {
	Sunset = {
		{ name = "Coral Red", color = Color3.fromRGB(255, 0, 18) },
		{ name = "Magenta",   color = Color3.fromRGB(243, 0, 207) },
		{ name = "Violet",    color = Color3.fromRGB(162, 0, 255) },
		{ name = "Blue",      color = Color3.fromRGB(51, 1, 255) },
	},
	Ocean = {
		{ name = "Gold",        color = Color3.fromRGB(255, 203, 0) },
		{ name = "Orange",      color = Color3.fromRGB(255, 129, 0) },
		{ name = "Light Amber", color = Color3.fromRGB(252, 186, 68) },
		{ name = "Cream",       color = Color3.fromRGB(254, 242, 144) },
	},
	Forest = {
		{ name = "Mint",       color = Color3.fromRGB(0, 253, 150) },
		{ name = "Lime",       color = Color3.fromRGB(9, 222, 63) },
		{ name = "Green",      color = Color3.fromRGB(0, 167, 39) },
		{ name = "Dark Green", color = Color3.fromRGB(1, 95, 43) },
	},
	Purple = {
		{ name = "Sky Blue",  color = Color3.fromRGB(31, 165, 255) },
		{ name = "Cyan",      color = Color3.fromRGB(19, 216, 250) },
		{ name = "Aqua",      color = Color3.fromRGB(100, 238, 224) },
		{ name = "Pale Mint", color = Color3.fromRGB(161, 254, 205) },
	},
	Fire = {
		{ name = "Periwinkle", color = Color3.fromRGB(150, 150, 243) },
		{ name = "Lavender",   color = Color3.fromRGB(204, 146, 250) },
		{ name = "Orchid",     color = Color3.fromRGB(239, 144, 243) },
		{ name = "Hot Pink",   color = Color3.fromRGB(255, 119, 201) },
		{ name = "Rose",       color = Color3.fromRGB(255, 106, 169) },
	},
}

local BasicColors = {
	"Red","DarkRed","Crimson","Coral","Rose","HotPink","Pink",
	"Blue","DarkBlue","SkyBlue","Navy","Cyan","Aqua","Turquoise",
	"Green","DarkGreen","Lime","Mint","Emerald","Olive","Teal",
	"Purple","DarkPurple","Violet","Lavender","Magenta","Indigo",
	"Yellow","Gold","Orange","DarkOrange","Amber","Peach",
	"White","Silver","Gray","Black","Brown","Tan","Beige","Maroon","LightPink",
}

local BasicColorMap = {
	Red=Color3.fromRGB(255,77,77), DarkRed=Color3.fromRGB(180,0,0),
	Crimson=Color3.fromRGB(220,20,60), Coral=Color3.fromRGB(255,127,170),
	Blue=Color3.fromRGB(77,136,255), DarkBlue=Color3.fromRGB(0,0,139),
	SkyBlue=Color3.fromRGB(135,206,235), Navy=Color3.fromRGB(0,0,128),
	Cyan=Color3.fromRGB(0,255,255), Aqua=Color3.fromRGB(127,255,212),
	Green=Color3.fromRGB(77,255,136), DarkGreen=Color3.fromRGB(0,100,0),
	Lime=Color3.fromRGB(50,205,50), Mint=Color3.fromRGB(152,255,152),
	Emerald=Color3.fromRGB(80,200,120), Purple=Color3.fromRGB(191,77,255),
	DarkPurple=Color3.fromRGB(75,0,130), Violet=Color3.fromRGB(138,43,226),
	Lavender=Color3.fromRGB(230,230,250), Magenta=Color3.fromRGB(255,0,255),
	Yellow=Color3.fromRGB(255,214,77), Gold=Color3.fromRGB(255,215,0),
	Orange=Color3.fromRGB(255,165,0), DarkOrange=Color3.fromRGB(255,140,0),
	Amber=Color3.fromRGB(255,191,0), Pink=Color3.fromRGB(255,105,180),
	HotPink=Color3.fromRGB(255,20,147), LightPink=Color3.fromRGB(255,182,193),
	Rose=Color3.fromRGB(255,0,127), Brown=Color3.fromRGB(139,69,19),
	Tan=Color3.fromRGB(210,180,140), Beige=Color3.fromRGB(245,245,220),
	White=Color3.fromRGB(255,255,255), Silver=Color3.fromRGB(192,192,192),
	Gray=Color3.fromRGB(128,128,128), Black=Color3.fromRGB(0,0,0),
	Peach=Color3.fromRGB(255,218,185), Turquoise=Color3.fromRGB(64,224,208),
	Indigo=Color3.fromRGB(75,0,130), Maroon=Color3.fromRGB(128,0,0),
	Olive=Color3.fromRGB(128,128,0), Teal=Color3.fromRGB(0,128,128),
}

local FontMap = {
	Gotham  = Enum.Font.GothamBold,
	Source  = Enum.Font.SourceSansBold,
	Fantasy = Enum.Font.Fantasy,
	Arcade  = Enum.Font.Arcade,
	SciFi   = Enum.Font.SciFi,
	Code    = Enum.Font.Code,
}

-- ========================================
-- STATE
-- ========================================
local currentPlayerList = {}
local selectedPlayer    = ""
local currentMode       = "fixed"
local selectedColor     = "White"
local selectedTemplate  = "Sunset"
local selectedHeight    = 0
local selectedFont      = "Gotham"
local previewThread     = nil

AdminConfig.CustomTitleState = {
	isEditMode   = false,
	editingSlot  = nil,
}

-- ========================================
-- HELPER
-- ========================================
local function makeCorner(parent, radius)
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, radius)
	c.Parent = parent
end

local function makeHeaderLabel(parent, text, size, pos, textSize)
	local lbl = Instance.new("TextLabel")
	lbl.Size                 = size
	lbl.Position             = pos
	lbl.BackgroundTransparency = 1
	lbl.Text                 = text
	lbl.TextColor3           = ThemeModule.Colors.TextWhite
	lbl.TextSize             = textSize or 11
	lbl.Font                 = Enum.Font.GothamBold
	lbl.TextXAlignment       = Enum.TextXAlignment.Left
	lbl.Parent               = parent
	ThemeModule.CreatePrimaryGradient(lbl, 90, 1.5)
	return lbl
end

local function makeInput(parent, placeholder, size, pos)
	local box = Instance.new("TextBox")
	box.Size                 = size
	box.Position             = pos
	box.BackgroundColor3     = ThemeModule.Colors.BackgroundDark
	box.BorderSizePixel      = 0
	box.Text                 = ""
	box.PlaceholderText      = placeholder
	box.PlaceholderColor3    = ThemeModule.Colors.TextMuted
	box.TextColor3           = ThemeModule.Colors.TextWhite
	box.TextSize             = 13
	box.Font                 = Enum.Font.GothamMedium
	box.ClearTextOnFocus     = false
	box.Parent               = parent
	makeCorner(box, 6)
	ThemeModule.CreateGradientStroke(box, 1, "Primary", 90)
	return box
end

-- ========================================
-- BUILD UI
-- ========================================
local scroll = Instance.new("ScrollingFrame")
scroll.Size                = UDim2.new(1, 0, 1, 0)
scroll.BackgroundTransparency = 1
scroll.BorderSizePixel     = 0
scroll.ScrollBarThickness  = 0
scroll.ScrollBarImageTransparency = 1
scroll.ScrollingEnabled    = true
scroll.Active              = true
scroll.VerticalScrollBarInset = Enum.ScrollBarInset.None
scroll.CanvasSize          = UDim2.new(0, 0, 0, 0)
scroll.AutomaticCanvasSize  = Enum.AutomaticSize.Y
scroll.ScrollingDirection   = Enum.ScrollingDirection.Y
scroll.ElasticBehavior      = Enum.ElasticBehavior.Never
scroll.Parent               = page

local scrollLayout = Instance.new("UIListLayout")
scrollLayout.Padding             = UDim.new(0, 8)
scrollLayout.FillDirection       = Enum.FillDirection.Vertical
scrollLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
scrollLayout.SortOrder           = Enum.SortOrder.LayoutOrder
scrollLayout.Parent              = scroll

local scrollPad = Instance.new("UIPadding")
scrollPad.PaddingTop    = UDim.new(0, 10)
scrollPad.PaddingBottom = UDim.new(0, 10)
scrollPad.PaddingLeft   = UDim.new(0, 10)
scrollPad.PaddingRight  = UDim.new(0, 10)
scrollPad.Parent        = scroll

local function makeSection(title, order, height)
	local section = Instance.new("Frame")
	section.Name             = title .. "Section"
	section.Size             = UDim2.new(1, 0, 0, height)
	section.BackgroundColor3 = ThemeModule.Colors.BackgroundDark
	section.BorderSizePixel  = 0
	section.LayoutOrder      = order
	section.ClipsDescendants = false
	section.Parent           = scroll
	makeCorner(section, 8)
	ThemeModule.CreateAnimatedStroke(section, 1, "Primary", 1.2)
	return section
end

-- ──────────────────────────────────────
-- SECTION 1: Player + Slot
-- ──────────────────────────────────────
local sec1 = makeSection("PlayerSlot", 1, 100)

makeHeaderLabel(sec1, "PLAYER NAME", UDim2.new(0.5, -8, 0, 20), UDim2.new(0, 10, 0, 8), 10)
makeHeaderLabel(sec1, "SLOT (1–14)", UDim2.new(0.5, -8, 0, 20), UDim2.new(0.5, 4, 0, 8), 10)

local playerNameBox = makeInput(sec1, "Type player name...", UDim2.new(0.5, -12, 0, 34), UDim2.new(0, 10, 0, 30))

local playerStatus = Instance.new("TextLabel")
playerStatus.Name                 = "PlayerStatus"
playerStatus.Size                 = UDim2.new(0.5, -12, 0, 16)
playerStatus.Position             = UDim2.new(0, 10, 0, 68)
playerStatus.BackgroundTransparency = 1
playerStatus.Text                 = ""
playerStatus.TextColor3           = ThemeModule.Colors.TextMuted
playerStatus.TextSize             = 10
playerStatus.Font                 = Enum.Font.GothamMedium
playerStatus.TextXAlignment       = Enum.TextXAlignment.Left
playerStatus.Parent               = sec1

local autoComplete = Instance.new("Frame")
autoComplete.Name             = "AutoComplete"
autoComplete.Size             = UDim2.new(0.5, -12, 0, 0)
autoComplete.Position         = UDim2.new(0, 10, 0, 66)
autoComplete.BackgroundColor3 = ThemeModule.Colors.BackgroundDark
autoComplete.BorderSizePixel  = 0
autoComplete.ClipsDescendants = true
autoComplete.Visible          = false
autoComplete.ZIndex           = 10
autoComplete.Parent           = sec1
makeCorner(autoComplete, 6)
ThemeModule.CreateGradientStroke(autoComplete, 1, "Primary", 90)

local autoLayout = Instance.new("UIListLayout")
autoLayout.Padding   = UDim.new(0, 2)
autoLayout.SortOrder = Enum.SortOrder.LayoutOrder
autoLayout.Parent    = autoComplete

local autoPad = Instance.new("UIPadding")
autoPad.PaddingTop    = UDim.new(0, 4)
autoPad.PaddingBottom = UDim.new(0, 4)
autoPad.PaddingLeft   = UDim.new(0, 4)
autoPad.PaddingRight  = UDim.new(0, 4)
autoPad.Parent        = autoComplete

local slotBox = makeInput(sec1, "1", UDim2.new(0.5, -12, 0, 34), UDim2.new(0.5, 4, 0, 30))
slotBox.Text = "1"

-- ──────────────────────────────────────
-- SECTION 2: Title Text
-- ──────────────────────────────────────
local sec2 = makeSection("TitleText", 2, 70)
makeHeaderLabel(sec2, "TITLE TEXT", UDim2.new(1, -20, 0, 20), UDim2.new(0, 10, 0, 8), 10)
local titleBox = makeInput(sec2, "Enter title text...", UDim2.new(1, -20, 0, 34), UDim2.new(0, 10, 0, 28))

-- ──────────────────────────────────────
-- SECTION 3: Mode Buttons (FIXED - dengan ScrollingFrame & Wraps)
-- ──────────────────────────────────────
local sec3 = makeSection("Mode", 3, 88) -- Tinggi diperbesar untuk wrapping
makeHeaderLabel(sec3, "COLOR MODE", UDim2.new(1, -20, 0, 20), UDim2.new(0, 10, 0, 6), 10)

-- Gunakan ScrollingFrame agar bisa scroll jika wrapping terlalu banyak
local modeScrollFrame = Instance.new("ScrollingFrame")
modeScrollFrame.Name = "ModeScrollFrame"
modeScrollFrame.Size = UDim2.new(1, -20, 0, 60)
modeScrollFrame.Position = UDim2.new(0, 10, 0, 26)
modeScrollFrame.BackgroundTransparency = 1
modeScrollFrame.BorderSizePixel = 0
modeScrollFrame.ScrollBarThickness = 0
modeScrollFrame.ScrollBarImageTransparency = 1
modeScrollFrame.ScrollingEnabled = true
modeScrollFrame.Active = true
modeScrollFrame.VerticalScrollBarInset = Enum.ScrollBarInset.None
modeScrollFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
modeScrollFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y
modeScrollFrame.ScrollingDirection = Enum.ScrollingDirection.Y
modeScrollFrame.ElasticBehavior = Enum.ElasticBehavior.Never
modeScrollFrame.Parent = sec3

local modeLayout = Instance.new("UIListLayout")
modeLayout.FillDirection       = Enum.FillDirection.Horizontal
modeLayout.Padding             = UDim.new(0, 4)
modeLayout.VerticalAlignment   = Enum.VerticalAlignment.Top
modeLayout.HorizontalAlignment = Enum.HorizontalAlignment.Left
modeLayout.Wraps               = true -- AKTIFKAN WRAPS
modeLayout.Parent              = modeScrollFrame

local modeButtons = {}
local modeList = { "fixed", "rgb", "gradient", "rainbow", "twotone" }
local modeLabels = { fixed="Fixed", rgb="RGB", gradient="Gradient", rainbow="Rainbow", twotone="Two-Tone" }

for _, modeName in ipairs(modeList) do
	local btn = Instance.new("TextButton")
	btn.Name             = "Mode_" .. modeName
	btn.Size             = UDim2.new(0, 72, 0, 28) -- Fixed height
	btn.BackgroundColor3 = ThemeModule.Colors.BackgroundMedium
	btn.BorderSizePixel  = 0
	btn.Text             = modeLabels[modeName]
	btn.TextColor3       = ThemeModule.Colors.TextGray
	btn.TextSize         = 11
	btn.Font             = Enum.Font.GothamMedium
	btn.AutoButtonColor  = false
	btn.Parent           = modeScrollFrame
	makeCorner(btn, 5)
	modeButtons[modeName] = btn
end

-- ──────────────────────────────────────
-- SECTION 4: Font Buttons (FIXED - dengan ScrollingFrame & Wraps)
-- ──────────────────────────────────────
local sec4 = makeSection("Font", 4, 88) -- Tinggi diperbesar untuk wrapping
makeHeaderLabel(sec4, "FONT", UDim2.new(1, -20, 0, 20), UDim2.new(0, 10, 0, 6), 10)

-- Gunakan ScrollingFrame agar bisa scroll jika wrapping terlalu banyak
local fontScrollFrame = Instance.new("ScrollingFrame")
fontScrollFrame.Name = "FontScrollFrame"
fontScrollFrame.Size = UDim2.new(1, -20, 0, 60)
fontScrollFrame.Position = UDim2.new(0, 10, 0, 26)
fontScrollFrame.BackgroundTransparency = 1
fontScrollFrame.BorderSizePixel = 0
fontScrollFrame.ScrollBarThickness = 0
fontScrollFrame.ScrollBarImageTransparency = 1
fontScrollFrame.ScrollingEnabled = true
fontScrollFrame.Active = true
fontScrollFrame.VerticalScrollBarInset = Enum.ScrollBarInset.None
fontScrollFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
fontScrollFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y
fontScrollFrame.ScrollingDirection = Enum.ScrollingDirection.Y
fontScrollFrame.ElasticBehavior = Enum.ElasticBehavior.Never
fontScrollFrame.Parent = sec4

local fontLayout = Instance.new("UIListLayout")
fontLayout.FillDirection     = Enum.FillDirection.Horizontal
fontLayout.Padding           = UDim.new(0, 4)
fontLayout.VerticalAlignment = Enum.VerticalAlignment.Top
fontLayout.HorizontalAlignment = Enum.HorizontalAlignment.Left
fontLayout.Wraps             = true -- AKTIFKAN WRAPS
fontLayout.Parent            = fontScrollFrame

local fontButtons = {}
local fontList = { "Gotham", "Source", "Fantasy", "Arcade", "SciFi", "Code" }

for _, fontName in ipairs(fontList) do
	local btn = Instance.new("TextButton")
	btn.Name             = "Font_" .. fontName
	btn.Size             = UDim2.new(0, 60, 0, 28) -- Fixed height
	btn.BackgroundColor3 = ThemeModule.Colors.BackgroundMedium
	btn.BorderSizePixel  = 0
	btn.Text             = fontName
	btn.TextColor3       = ThemeModule.Colors.TextGray
	btn.TextSize         = 10
	btn.Font             = FontMap[fontName] or Enum.Font.GothamMedium
	btn.AutoButtonColor  = false
	btn.Parent           = fontScrollFrame
	makeCorner(btn, 5)
	fontButtons[fontName] = btn
end

-- ──────────────────────────────────────
-- SECTION 5: Color Picker
-- ──────────────────────────────────────
local sec5 = makeSection("Color", 5, 180)
makeHeaderLabel(sec5, "COLOR / TEMPLATE", UDim2.new(1, -20, 0, 20), UDim2.new(0, 10, 0, 6), 10)

local colorSection = Instance.new("Frame")
colorSection.Name             = "ColorSection"
colorSection.Size             = UDim2.new(1, -20, 0, 148)
colorSection.Position         = UDim2.new(0, 10, 0, 26)
colorSection.BackgroundTransparency = 1
colorSection.ClipsDescendants = true
colorSection.Parent           = sec5

-- ──────────────────────────────────────
-- SECTION 6: Height Slider + Distance
-- ──────────────────────────────────────
local sec6 = makeSection("HeightDist", 6, 100)
makeHeaderLabel(sec6, "HEIGHT OFFSET", UDim2.new(0.5, -8, 0, 20), UDim2.new(0, 10, 0, 6), 10)
makeHeaderLabel(sec6, "DISTANCE LEVEL", UDim2.new(0.5, -8, 0, 20), UDim2.new(0.5, 4, 0, 6), 10)

local sliderTrack = Instance.new("Frame")
sliderTrack.Size             = UDim2.new(0.5, -22, 0, 8)
sliderTrack.Position         = UDim2.new(0, 10, 0, 48)
sliderTrack.BackgroundColor3 = ThemeModule.Colors.BackgroundMedium
sliderTrack.BorderSizePixel  = 0
sliderTrack.Parent           = sec6
makeCorner(sliderTrack, 4)

local sliderFill = Instance.new("Frame")
sliderFill.Size             = UDim2.new(0.5, 0, 1, 0)
sliderFill.BackgroundColor3 = ThemeModule.Colors.Primary1
sliderFill.BorderSizePixel  = 0
sliderFill.Parent           = sliderTrack
makeCorner(sliderFill, 4)
ThemeModule.CreateStaticGradient(sliderFill, "Primary", 0)

local sliderHandle = Instance.new("TextButton")
sliderHandle.Size             = UDim2.new(0, 18, 0, 18)
sliderHandle.Position         = UDim2.new(0.5, -9, 0.5, -9)
sliderHandle.BackgroundColor3 = ThemeModule.Colors.TextWhite
sliderHandle.BorderSizePixel  = 0
sliderHandle.Text             = ""
sliderHandle.AutoButtonColor  = false
sliderHandle.Parent           = sliderTrack
makeCorner(sliderHandle, 9)

local heightValueLabel = Instance.new("TextLabel")
heightValueLabel.Size             = UDim2.new(0, 30, 0, 20)
heightValueLabel.Position         = UDim2.new(0, 10, 0, 64)
heightValueLabel.BackgroundTransparency = 1
heightValueLabel.Text             = "0.0"
heightValueLabel.TextColor3       = ThemeModule.Colors.TextWhite
heightValueLabel.TextSize         = 12
heightValueLabel.Font             = Enum.Font.GothamBold
heightValueLabel.Parent           = sec6

local distanceBox = makeInput(sec6, "20", UDim2.new(0.5, -12, 0, 30), UDim2.new(0.5, 4, 0, 34))
distanceBox.Text = "20"

-- ──────────────────────────────────────
-- SECTION 7: Preview
-- ──────────────────────────────────────
local sec7 = makeSection("Preview", 7, 70)
makeHeaderLabel(sec7, "PREVIEW", UDim2.new(1, -20, 0, 20), UDim2.new(0, 10, 0, 6), 10)

local preview = Instance.new("TextLabel")
preview.Size                 = UDim2.new(1, -20, 0, 34)
preview.Position             = UDim2.new(0, 10, 0, 28)
preview.BackgroundColor3     = ThemeModule.Colors.BackgroundMedium
preview.BorderSizePixel      = 0
preview.Text                 = "Preview Text"
preview.TextColor3           = ThemeModule.Colors.TextWhite
preview.TextSize             = 18
preview.Font                 = Enum.Font.GothamBold
preview.TextScaled           = true
preview.TextStrokeTransparency = 0.6
preview.TextStrokeColor3     = Color3.new(0, 0, 0)
preview.Parent               = sec7
makeCorner(preview, 6)

-- ──────────────────────────────────────
-- SECTION 8: Action Buttons
-- ──────────────────────────────────────
local sec8 = makeSection("Actions", 8, 50)
sec8.BackgroundTransparency = 1
for _, child in ipairs(sec8:GetChildren()) do
	if child:IsA("UIStroke") then child:Destroy() end
end

local buttonContainer = Instance.new("Frame")
buttonContainer.Name = "ButtonContainer"
buttonContainer.Size = UDim2.new(1, 0, 1, 0)
buttonContainer.BackgroundTransparency = 1
buttonContainer.Visible = false
buttonContainer.Parent = sec8

local giveBtn = Instance.new("TextButton")
giveBtn.Name             = "GiveBtn"
giveBtn.Size             = UDim2.new(0.6, 0, 0, 36)
giveBtn.AnchorPoint      = Vector2.new(0.5, 0)
giveBtn.Position         = UDim2.new(0.5, 0, 0, 7)
giveBtn.BackgroundColor3 = ThemeModule.Colors.BackgroundMedium
giveBtn.BorderSizePixel  = 0
giveBtn.Text             = "✨ GIVE TITLE"
giveBtn.TextColor3       = ThemeModule.Colors.TextWhite
giveBtn.TextSize         = 12
giveBtn.Font             = Enum.Font.GothamBold
giveBtn.AutoButtonColor  = false
giveBtn.Parent           = buttonContainer
makeCorner(giveBtn, 6)
ThemeModule.CreateStaticGradient(giveBtn, "Success", 90)

giveBtn.MouseEnter:Connect(function()
	TweenService:Create(giveBtn, TweenInfo.new(0.15), { BackgroundTransparency = 0.1 }):Play()
end)
giveBtn.MouseLeave:Connect(function()
	TweenService:Create(giveBtn, TweenInfo.new(0.15), { BackgroundTransparency = 0 }):Play()
end)

local cancelBtn = Instance.new("TextButton")
cancelBtn.Name             = "CancelBtn"
cancelBtn.Size             = UDim2.new(0.35, 0, 0, 36)
cancelBtn.AnchorPoint      = Vector2.new(0, 0)
cancelBtn.Position         = UDim2.new(0.65, 4, 0, 7)
cancelBtn.BackgroundColor3 = ThemeModule.Colors.BackgroundMedium
cancelBtn.BorderSizePixel  = 0
cancelBtn.Text             = "x CANCEL"
cancelBtn.TextColor3       = ThemeModule.Colors.TextWhite
cancelBtn.TextSize         = 12
cancelBtn.Font             = Enum.Font.GothamBold
cancelBtn.AutoButtonColor  = false
cancelBtn.Visible          = false
cancelBtn.Parent           = buttonContainer
makeCorner(cancelBtn, 6)
ThemeModule.CreateStaticGradient(cancelBtn, "Error", 90)

cancelBtn.MouseEnter:Connect(function()
	TweenService:Create(cancelBtn, TweenInfo.new(0.15), { BackgroundTransparency = 0.1 }):Play()
end)
cancelBtn.MouseLeave:Connect(function()
	TweenService:Create(cancelBtn, TweenInfo.new(0.15), { BackgroundTransparency = 0 }):Play()
end)

local noPlayerLabel = Instance.new("TextLabel")
noPlayerLabel.Name = "NoPlayerLabel"
noPlayerLabel.Size = UDim2.new(1, 0, 1, 0)
noPlayerLabel.BackgroundTransparency = 1
noPlayerLabel.Text = "⬆️ Type player name to give title"
noPlayerLabel.TextColor3 = ThemeModule.Colors.TextMuted
noPlayerLabel.TextSize = 12
noPlayerLabel.Font = Enum.Font.GothamMedium
noPlayerLabel.Parent = sec8

-- ========================================
-- FUNCTIONS
-- ========================================
local function updateButtonLayout(editMode)
	if editMode then
		giveBtn.AnchorPoint = Vector2.new(0, 0)
		giveBtn.Size = UDim2.new(0.6, -4, 0, 36)
		giveBtn.Position = UDim2.new(0, 0, 0, 7)
		cancelBtn.Visible = true
	else
		giveBtn.AnchorPoint = Vector2.new(0.5, 0)
		giveBtn.Size = UDim2.new(0.6, 0, 0, 36)
		giveBtn.Position = UDim2.new(0.5, 0, 0, 7)
		cancelBtn.Visible = false
	end
end

local function updateButtonVisibility()
	if selectedPlayer ~= "" then
		buttonContainer.Visible = true
		noPlayerLabel.Visible = false
	else
		buttonContainer.Visible = false
		noPlayerLabel.Visible = true
	end
end

local function findPlayerByName(name)
	local lowerName = string.lower(name)
	for _, p in ipairs(Players:GetPlayers()) do
		if string.lower(p.Name) == lowerName or string.lower(p.DisplayName) == lowerName then
			return p.Name
		end
	end
	for _, pName in ipairs(currentPlayerList) do
		if string.lower(pName) == lowerName then
			return pName
		end
	end
	return nil
end

local function getMatchingPlayers(text)
	if text == "" then return {} end
	local matches = {}
	local lowerText = string.lower(text)

	for _, p in ipairs(Players:GetPlayers()) do
		local name = p.Name
		local displayName = p.DisplayName
		if string.find(string.lower(name), lowerText, 1, true) or 
			string.find(string.lower(displayName), lowerText, 1, true) then
			table.insert(matches, {name = name, display = displayName})
		end
	end

	return matches
end

local function updateAutoComplete(text)
	for _, c in ipairs(autoComplete:GetChildren()) do
		if c:IsA("TextButton") then c:Destroy() end
	end

	local matches = getMatchingPlayers(text)

	if #matches == 0 or text == "" then
		autoComplete.Visible = false
		autoComplete.Size = UDim2.new(0.5, -12, 0, 0)
		return
	end

	local showCount = math.min(#matches, 5)

	for i = 1, showCount do
		local match = matches[i]
		local item = Instance.new("TextButton")
		item.Name             = "Match_" .. match.name
		item.Size             = UDim2.new(1, 0, 0, 28)
		item.BackgroundColor3 = ThemeModule.Colors.BackgroundMedium
		item.BorderSizePixel  = 0
		item.AutoButtonColor  = false
		item.LayoutOrder      = i
		item.ZIndex           = 11
		item.Parent           = autoComplete
		makeCorner(item, 4)

		local displayText = match.name
		if match.display ~= match.name then
			displayText = match.display .. " (@" .. match.name .. ")"
		end

		local label = Instance.new("TextLabel")
		label.Size                 = UDim2.new(1, -10, 1, 0)
		label.Position             = UDim2.new(0, 8, 0, 0)
		label.BackgroundTransparency = 1
		label.Text                 = displayText
		label.TextColor3           = ThemeModule.Colors.TextWhite
		label.TextSize             = 11
		label.Font                 = Enum.Font.GothamMedium
		label.TextXAlignment       = Enum.TextXAlignment.Left
		label.TextTruncate         = Enum.TextTruncate.AtEnd
		label.ZIndex               = 12
		label.Parent               = item

		item.MouseEnter:Connect(function()
			item.BackgroundColor3 = ThemeModule.Colors.BackgroundLighter
		end)
		item.MouseLeave:Connect(function()
			item.BackgroundColor3 = ThemeModule.Colors.BackgroundMedium
		end)
		item.MouseButton1Click:Connect(function()
			playerNameBox.Text = match.name
			selectedPlayer = match.name
			autoComplete.Visible = false
			playerStatus.Text = "✓ " .. match.name
			playerStatus.TextColor3 = ThemeModule.Colors.Success
			updateButtonVisibility()
		end)
	end

	local height = showCount * 30 + 8
	autoComplete.Size = UDim2.new(0.5, -12, 0, height)
	autoComplete.Visible = true
end

local function validatePlayer(text)
	if text == "" then
		selectedPlayer = ""
		playerStatus.Text = ""
		updateButtonVisibility()
		return
	end

	local found = findPlayerByName(text)
	if found then
		selectedPlayer = found
		playerStatus.Text = "✓ " .. found
		playerStatus.TextColor3 = ThemeModule.Colors.Success
	else
		selectedPlayer = ""
		playerStatus.Text = "✗ Player not found"
		playerStatus.TextColor3 = ThemeModule.Colors.Error
	end
	updateButtonVisibility()
end

local function highlightMode(active)
	for name, btn in pairs(modeButtons) do
		for _, child in ipairs(btn:GetChildren()) do
			if child:IsA("UIGradient") then child:Destroy() end
		end
		if name == active then
			btn.BackgroundColor3 = ThemeModule.Colors.BackgroundLighter
			btn.TextColor3       = ThemeModule.Colors.TextWhite
			btn.Font             = Enum.Font.GothamBold
			ThemeModule.CreateStaticGradient(btn, "Primary", 90)
		else
			btn.BackgroundColor3 = ThemeModule.Colors.BackgroundMedium
			btn.TextColor3       = ThemeModule.Colors.TextGray
			btn.Font             = Enum.Font.GothamMedium
		end
	end
end

local function highlightFont(active)
	for name, btn in pairs(fontButtons) do
		for _, child in ipairs(btn:GetChildren()) do
			if child:IsA("UIGradient") then child:Destroy() end
		end
		if name == active then
			btn.BackgroundColor3 = ThemeModule.Colors.BackgroundLighter
			btn.TextColor3       = ThemeModule.Colors.TextWhite
			ThemeModule.CreateStaticGradient(btn, "Primary", 90)
		else
			btn.BackgroundColor3 = ThemeModule.Colors.BackgroundMedium
			btn.TextColor3       = ThemeModule.Colors.TextGray
		end
	end
end

local function updateSlider(value)
	value = math.clamp(tonumber(value) or 0, -5, 5)
	selectedHeight = value
	local norm = (value + 5) / 10
	sliderFill.Size       = UDim2.new(norm, 0, 1, 0)
	sliderHandle.Position = UDim2.new(norm, -9, 0.5, -9)
	heightValueLabel.Text = string.format("%.1f", value)
end

local function updatePreview()
	if previewThread then task.cancel(previewThread); previewThread = nil end
	for _, c in ipairs(preview:GetChildren()) do
		if c:IsA("UIGradient") then c:Destroy() end
	end

	if currentMode == "fixed" then
		preview.TextColor3 = BasicColorMap[selectedColor] or Color3.new(1,1,1)
	elseif currentMode == "rgb" then
		preview.TextColor3 = Color3.new(1,1,1)
		previewThread = task.spawn(function()
			local t0 = tick()
			while preview and preview.Parent do
				preview.TextColor3 = Color3.fromHSV(((tick()-t0)%6)/6, 1, 1)
				task.wait(0.08)
			end
		end)
	else
		preview.TextColor3 = Color3.new(1,1,1)
		local grad = Instance.new("UIGradient", preview)
		local colors = ColorTemplates[selectedTemplate] or ColorTemplates.Sunset
		local kp = {}
		for i, cd in ipairs(colors) do
			table.insert(kp, ColorSequenceKeypoint.new((i-1)/math.max(#colors-1,1), cd.color))
		end
		grad.Color = ColorSequence.new(kp)

		if currentMode == "rainbow" then
			previewThread = task.spawn(function()
				local t = 0
				while grad and grad.Parent do
					t += 0.04; grad.Rotation = 90 + math.sin(t*1.2)*135; task.wait(0.03)
				end
			end)
		elseif currentMode == "gradient" then
			previewThread = task.spawn(function()
				local t = 0
				while grad and grad.Parent do
					t += 0.05; grad.Rotation = 90 + math.sin(t*2)*60 + math.cos(t*1.5)*40; task.wait(0.03)
				end
			end)
		elseif currentMode == "twotone" then
			grad.Rotation = 0
			previewThread = task.spawn(function()
				local t = 0
				while grad and grad.Parent do
					t += 0.02; grad.Offset = Vector2.new((math.sin(t*1.5)+1)/2*2-1, 0); task.wait(0.03)
				end
			end)
		end
	end
end

local function showBasicColors()
	for _, c in ipairs(colorSection:GetChildren()) do c:Destroy() end

	local sf = Instance.new("ScrollingFrame")
	sf.Name               = "ColorScroll"
	sf.Size               = UDim2.new(1, 0, 1, 0)
	sf.BackgroundColor3   = ThemeModule.Colors.BackgroundDark
	sf.BorderSizePixel    = 0
	sf.ScrollBarThickness = 0
	sf.ScrollBarImageTransparency = 1
	sf.ScrollingEnabled   = true
	sf.VerticalScrollBarInset = Enum.ScrollBarInset.None
	sf.ScrollingDirection = Enum.ScrollingDirection.Y
	sf.ElasticBehavior    = Enum.ElasticBehavior.Never
	sf.CanvasSize         = UDim2.new(0, 0, 0, 0)
	sf.AutomaticCanvasSize = Enum.AutomaticSize.Y
	sf.Parent             = colorSection
	makeCorner(sf, 6)

	local grid = Instance.new("UIGridLayout")
	grid.CellSize    = UDim2.new(0, 32, 0, 28)
	grid.CellPadding = UDim2.new(0, 4, 0, 4)
	grid.FillDirection = Enum.FillDirection.Horizontal
	grid.HorizontalAlignment = Enum.HorizontalAlignment.Left
	grid.SortOrder = Enum.SortOrder.LayoutOrder
	grid.Parent      = sf

	local pad = Instance.new("UIPadding")
	pad.PaddingTop    = UDim.new(0, 6)
	pad.PaddingLeft   = UDim.new(0, 6)
	pad.PaddingBottom = UDim.new(0, 6)
	pad.PaddingRight  = UDim.new(0, 6)
	pad.Parent        = sf

	for idx, colorName in ipairs(BasicColors) do
		local btn = Instance.new("TextButton")
		btn.Name             = "C_" .. colorName
		btn.BackgroundColor3 = BasicColorMap[colorName] or Color3.new(1,1,1)
		btn.Text             = ""
		btn.BorderSizePixel  = 0
		btn.AutoButtonColor  = false
		btn.LayoutOrder      = idx
		btn.Parent           = sf
		makeCorner(btn, 4)

		local stroke = Instance.new("UIStroke")
		if selectedColor == colorName then
			stroke.Color = ThemeModule.Colors.StrokeBase
			stroke.Thickness = 2
			stroke.Parent = btn
			ThemeModule.CreateStaticGradient(stroke, "Primary", 45)
		else
			stroke.Color = ThemeModule.Colors.BackgroundLighter
			stroke.Thickness = 1
			stroke.Parent = btn
		end

		btn.MouseButton1Click:Connect(function()
			selectedColor = colorName
			for _, child in ipairs(sf:GetChildren()) do
				if child:IsA("TextButton") then
					local s = child:FindFirstChildOfClass("UIStroke")
					if s then
						for _, g in ipairs(s:GetChildren()) do
							if g:IsA("UIGradient") then g:Destroy() end
						end
						local cn = child.Name:sub(3)
						if cn == colorName then
							s.Color = ThemeModule.Colors.StrokeBase
							s.Thickness = 2
							ThemeModule.CreateStaticGradient(s, "Primary", 45)
						else
							s.Color = ThemeModule.Colors.BackgroundLighter
							s.Thickness = 1
						end
					end
				end
			end
			updatePreview()
		end)
	end
end

local function showTemplates()
	for _, c in ipairs(colorSection:GetChildren()) do c:Destroy() end

	local sf = Instance.new("ScrollingFrame")
	sf.Name               = "TemplateScroll"
	sf.Size               = UDim2.new(1, 0, 1, 0)
	sf.BackgroundColor3   = ThemeModule.Colors.BackgroundDark
	sf.BorderSizePixel    = 0
	sf.ScrollBarThickness = 0
	sf.ScrollBarImageTransparency = 1
	sf.ScrollingEnabled   = true
	sf.VerticalScrollBarInset = Enum.ScrollBarInset.None
	sf.ScrollingDirection = Enum.ScrollingDirection.Y
	sf.ElasticBehavior    = Enum.ElasticBehavior.Never
	sf.CanvasSize         = UDim2.new(0, 0, 0, 0)
	sf.AutomaticCanvasSize = Enum.AutomaticSize.Y
	sf.Parent             = colorSection
	makeCorner(sf, 6)

	local layout = Instance.new("UIListLayout")
	layout.Padding   = UDim.new(0, 6)
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.FillDirection = Enum.FillDirection.Vertical
	layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	layout.Parent    = sf

	local pad = Instance.new("UIPadding")
	pad.PaddingTop    = UDim.new(0, 6)
	pad.PaddingLeft   = UDim.new(0, 6)
	pad.PaddingBottom = UDim.new(0, 6)
	pad.PaddingRight  = UDim.new(0, 6)
	pad.Parent        = sf

	local sortedTemplates = {}
	for templateName, _ in pairs(ColorTemplates) do
		table.insert(sortedTemplates, templateName)
	end
	table.sort(sortedTemplates)

	for idx, templateName in ipairs(sortedTemplates) do
		local colors = ColorTemplates[templateName]

		local row = Instance.new("Frame")
		row.Name             = "T_" .. templateName
		row.Size             = UDim2.new(1, -4, 0, 44)
		row.BackgroundColor3 = ThemeModule.Colors.BackgroundMedium
		row.BorderSizePixel  = 0
		row.LayoutOrder      = idx
		row.Parent           = sf
		makeCorner(row, 6)

		local stroke = Instance.new("UIStroke")
		if selectedTemplate == templateName then
			stroke.Color = ThemeModule.Colors.StrokeBase
			stroke.Thickness = 2
			stroke.Parent = row
			ThemeModule.CreateStaticGradient(stroke, "Primary", 45)
		else
			stroke.Color = ThemeModule.Colors.BackgroundLighter
			stroke.Thickness = 1
			stroke.Parent = row
		end

		local nameLabel = Instance.new("TextLabel")
		nameLabel.Size             = UDim2.new(0, 70, 1, 0)
		nameLabel.Position         = UDim2.new(0, 8, 0, 0)
		nameLabel.BackgroundTransparency = 1
		nameLabel.Text             = templateName
		nameLabel.TextColor3       = ThemeModule.Colors.TextWhite
		nameLabel.Font             = Enum.Font.GothamBold
		nameLabel.TextSize         = 12
		nameLabel.TextXAlignment   = Enum.TextXAlignment.Left
		nameLabel.Parent           = row
		ThemeModule.CreateStaticGradient(nameLabel, "Primary", 90)

		local swatchFrame = Instance.new("Frame")
		swatchFrame.Size             = UDim2.new(1, -90, 1, -10)
		swatchFrame.Position         = UDim2.new(0, 80, 0, 5)
		swatchFrame.BackgroundTransparency = 1
		swatchFrame.Parent           = row

		local swatchLayout = Instance.new("UIListLayout")
		swatchLayout.FillDirection = Enum.FillDirection.Horizontal
		swatchLayout.Padding       = UDim.new(0, 4)
		swatchLayout.VerticalAlignment = Enum.VerticalAlignment.Center
		swatchLayout.Parent        = swatchFrame

		for _, cd in ipairs(colors) do
			local swatch = Instance.new("Frame")
			swatch.Size             = UDim2.new(0, 28, 0, 28)
			swatch.BackgroundColor3 = cd.color
			swatch.BorderSizePixel  = 0
			swatch.Parent           = swatchFrame
			makeCorner(swatch, 4)
		end

		local btn = Instance.new("TextButton")
		btn.Size                = UDim2.new(1, 0, 1, 0)
		btn.BackgroundTransparency = 1
		btn.Text                = ""
		btn.Parent              = row

		btn.MouseButton1Click:Connect(function()
			selectedTemplate = templateName
			for _, child in ipairs(sf:GetChildren()) do
				if child:IsA("Frame") and child.Name:sub(1,2) == "T_" then
					local s = child:FindFirstChildOfClass("UIStroke")
					if s then
						for _, g in ipairs(s:GetChildren()) do
							if g:IsA("UIGradient") then g:Destroy() end
						end
						local tn = child.Name:sub(3)
						if tn == templateName then
							s.Color = ThemeModule.Colors.StrokeBase
							s.Thickness = 2
							ThemeModule.CreateStaticGradient(s, "Primary", 45)
						else
							s.Color = ThemeModule.Colors.BackgroundLighter
							s.Thickness = 1
						end
					end
				end
			end
			updatePreview()
		end)
	end
end

-- ========================================
-- EVENTS
-- ========================================

playerNameBox:GetPropertyChangedSignal("Text"):Connect(function()
	local text = playerNameBox.Text
	updateAutoComplete(text)
end)

playerNameBox.FocusLost:Connect(function()
	task.wait(0.1)
	if autoComplete.Visible then
		autoComplete.Visible = false
	end
	validatePlayer(playerNameBox.Text)
end)

playerNameBox.Focused:Connect(function()
	if playerNameBox.Text ~= "" then
		updateAutoComplete(playerNameBox.Text)
	end
end)

local sliderDragging = false
sliderHandle.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		sliderDragging = true
	end
end)
UserInputService.InputEnded:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		sliderDragging = false
	end
end)
UserInputService.InputChanged:Connect(function(input)
	if sliderDragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
		local rel = math.clamp((input.Position.X - sliderTrack.AbsolutePosition.X) / sliderTrack.AbsoluteSize.X, 0, 1)
		updateSlider(rel * 10 - 5)
	end
end)

for modeName, btn in pairs(modeButtons) do
	btn.MouseButton1Click:Connect(function()
		currentMode = modeName
		highlightMode(modeName)
		if modeName == "fixed" or modeName == "rgb" then
			showBasicColors()
		else
			showTemplates()
		end
		updatePreview()
	end)
end

for fontName, btn in pairs(fontButtons) do
	btn.MouseButton1Click:Connect(function()
		selectedFont = fontName
		highlightFont(fontName)
		preview.Font = FontMap[fontName] or Enum.Font.GothamBold
	end)
end

titleBox:GetPropertyChangedSignal("Text"):Connect(function()
	preview.Text = titleBox.Text ~= "" and titleBox.Text or "Preview Text"
end)

giveBtn.MouseButton1Click:Connect(function()
	local targetPlayer = findPlayerByName(playerNameBox.Text)

	if not targetPlayer then
		AdminConfig.ShowNotification("Player not found: " .. playerNameBox.Text, "error")
		return
	end

	local slotNum = tonumber(slotBox.Text)
	if not slotNum or slotNum < 1 or slotNum > 14 then
		AdminConfig.ShowNotification("Slot must be between 1 and 14", "error")
		return
	end
	if titleBox.Text == "" then
		AdminConfig.ShowNotification("Title text cannot be empty", "warning")
		return
	end

	local distLevel       = math.clamp(tonumber(distanceBox.Text) or 20, 0, 20)
	local colorOrTemplate = (currentMode == "fixed" or currentMode == "rgb") and selectedColor or selectedTemplate

	TitleEvent:FireServer("SetTitleSlot",
		targetPlayer, slotNum, titleBox.Text,
		currentMode, colorOrTemplate,
		0, selectedHeight, selectedFont, distLevel)

	local state = AdminConfig.CustomTitleState
	if state.isEditMode then
		state.isEditMode    = false
		state.editingSlot   = nil
		slotBox.TextEditable = true

		giveBtn.Text = "✨ GIVE TITLE"
		for _, child in ipairs(giveBtn:GetChildren()) do
			if child:IsA("UIGradient") then child:Destroy() end
		end
		ThemeModule.CreateStaticGradient(giveBtn, "Success", 90)

		updateButtonLayout(false)
		AdminConfig.ShowNotification("Title updated!", "success")
		task.wait(0.3)
		AdminConfig.SwitchTab("ManageTitle")
		TitleEvent:FireServer("RequestPlayerTitles", targetPlayer)
	else
		AdminConfig.ShowNotification("Title given to " .. targetPlayer, "success")
	end
end)

cancelBtn.MouseButton1Click:Connect(function()
	local state = AdminConfig.CustomTitleState
	state.isEditMode    = false
	state.editingSlot   = nil
	slotBox.TextEditable = true

	giveBtn.Text = "✨ GIVE TITLE"
	for _, child in ipairs(giveBtn:GetChildren()) do
		if child:IsA("UIGradient") then child:Destroy() end
	end
	ThemeModule.CreateStaticGradient(giveBtn, "Success", 90)

	updateButtonLayout(false)
	AdminConfig.SwitchTab("ManageTitle")
end)

AdminConfig.CustomTitleUI = {
	SetEditMode = function(slotNum, titleInfo)
		local state = AdminConfig.CustomTitleState
		state.isEditMode   = true
		state.editingSlot  = slotNum

		slotBox.Text         = tostring(slotNum)
		slotBox.TextEditable = false
		titleBox.Text        = titleInfo.Text or ""
		distanceBox.Text     = tostring(titleInfo.Distance or 20)
		updateSlider(titleInfo.Height or 0)

		local mode = titleInfo.Mode or "fixed"
		currentMode = mode
		highlightMode(mode)

		local font = titleInfo.Font or "Gotham"
		selectedFont = font
		highlightFont(font)
		preview.Font = FontMap[font] or Enum.Font.GothamBold

		if mode == "fixed" or mode == "rgb" then
			selectedColor = titleInfo.ColorTemplate or "White"
			showBasicColors()
		else
			selectedTemplate = titleInfo.ColorTemplate or "Sunset"
			showTemplates()
		end

		updatePreview()
		preview.Text = titleInfo.Text ~= "" and titleInfo.Text or "Preview Text"

		giveBtn.Text = "💾 UPDATE"
		for _, child in ipairs(giveBtn:GetChildren()) do
			if child:IsA("UIGradient") then child:Destroy() end
		end
		ThemeModule.CreateStaticGradient(giveBtn, "Warning", 90)

		updateButtonLayout(true)
		updateButtonVisibility()
		AdminConfig.SwitchTab("CustomTitle")
	end,

	SetSelectedPlayer = function(name)
		selectedPlayer = name
		playerNameBox.Text = name
		playerStatus.Text = "✓ " .. name
		playerStatus.TextColor3 = ThemeModule.Colors.Success
		updateButtonVisibility()
	end,
}

TitleEvent.OnClientEvent:Connect(function(action, data)
	if action == "PlayerList" then
		currentPlayerList = data or {}
	end
end)

highlightMode("fixed")
highlightFont("Gotham")
showBasicColors()
updatePreview()
updateSlider(0)
updateButtonLayout(false)
updateButtonVisibility()

print("✅ [CustomTitleClient] Loaded!")
