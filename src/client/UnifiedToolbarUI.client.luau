local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService      = game:GetService("TweenService")
local UIS               = game:GetService("UserInputService")

local player    = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local Modules     = ReplicatedStorage:WaitForChild("Modules")
local ThemeModule = require(Modules:WaitForChild("ThemeModule"))
local MenuConfig  = require(Modules:WaitForChild("MenuConfig"))
local Icon        = require(ReplicatedStorage:WaitForChild("Icon"))
local UIStrings   = require(Modules:WaitForChild("UIStrings"))
local PanelAnimationController = require(Modules:WaitForChild("PanelAnimationController"))

local ScalingSystem = require(
	ReplicatedStorage
		:WaitForChild("AutoScaleSystem")
		:WaitForChild("ScaleSystem")
)

local GS = ThemeModule.GradientSystem
GS.Start()

local function getThemeColor(name, fallback)
	if ThemeModule and ThemeModule.Colors and ThemeModule.Colors[name] then
		return ThemeModule.Colors[name]
	end
	return fallback
end

local T = {
	Bg        = getThemeColor("BackgroundDark", Color3.fromHex("#080808")),
	Card      = getThemeColor("BackgroundLight", Color3.fromHex("#1C1C1C")),
	CardHover = getThemeColor("BackgroundLighter", Color3.fromHex("#262626")),
	Accent    = getThemeColor("Primary1", Color3.fromHex("#FFFFFF")),
	Accent2   = getThemeColor("Primary2", Color3.fromHex("#888888")),
	AccDim    = Color3.fromHex("#333333"),
	Text      = getThemeColor("TextWhite", Color3.fromHex("#FFFFFF")),
	TextDim   = getThemeColor("TextGray",  Color3.fromHex("#A0A0A0")),
	Sub       = getThemeColor("TextMuted", Color3.fromHex("#666666")),
	Border    = getThemeColor("Border", Color3.fromHex("#353535")),
	Close     = getThemeColor("CloseRed", Color3.fromHex("#2A2A2A")),
	CloseHov  = getThemeColor("CloseRedHover", Color3.fromHex("#404040")),
}

local MAX_HAT_CLIENT = 5
local PANEL_W        = 320
local HEADER_H       = 44
local MAX_BODY_H     = 320

local PANEL_H = {
	vip       = HEADER_H + MAX_BODY_H,
	glowstick = HEADER_H + 160,
}

local currentMode    = nil
local currentRemote  = nil
local menuOpen       = false
local boundTools     = {}
local selectedStroke = nil
local isVIP          = false
local vipBuilt       = false
local activeToolMode = nil

local VIPState   = { equipped = {}, currentSize = 1.0 }
local StatusSize, StatusHats

local VIPFolder = ReplicatedStorage:WaitForChild("VIPRemotes", 10)
local RE = {}
if VIPFolder then
	for _, n in ipairs({
		"ShowIcon","RequestIcon","ResetAvatar",
		"HatTryOn","HatInfo","SetSize","Result","SyncData"
	}) do
		RE[n] = VIPFolder:WaitForChild(n, 5)
	end
end

local toolIcon = Icon.new()
toolIcon:setOrder(5)
toolIcon:setRight()
toolIcon:setLabel("/")
toolIcon:setEnabled(false)

local screenGui = Instance.new("ScreenGui")
screenGui.Name           = "UnifiedToolGui"
screenGui.IgnoreGuiInset = true
screenGui.ResetOnSpawn   = false
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.DisplayOrder   = 100
screenGui.Enabled        = true
screenGui.Parent         = playerGui

local guiScaler = ScalingSystem.new(screenGui)

local function make(cls, props, parent)
	local o = Instance.new(cls)
	for k, v in pairs(props) do o[k] = v end
	if o:IsA("GuiObject") and not o:IsA("UIComponent") and props.Active == nil then
		o.Active = true
	end
	if parent then o.Parent = parent end
	return o
end

local function crn(r, p) make("UICorner", { CornerRadius = UDim.new(0, r) }, p) end

local function sk(col, th, tr, p)
	make("UIStroke", { Color = col, Thickness = th, Transparency = tr or 0 }, p)
end

local function tw(obj, dur, props)
	TweenService:Create(obj,
		TweenInfo.new(dur, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		props):Play()
end

local function addGrad(parent, rot, animated)
	if ThemeModule then
		return animated
			and ThemeModule.CreatePrimaryGradient(parent, rot or 0)
			or  ThemeModule.CreateStaticGradient(parent, "Primary", rot or 0)
	end
	return make("UIGradient", {
		Color    = ColorSequence.new({
			ColorSequenceKeypoint.new(0, T.Accent),
			ColorSequenceKeypoint.new(1, T.Accent2),
		}),
		Rotation = rot or 0,
	}, parent)
end

local panel = make("Frame", {
	Name                   = "ToolPanel",
	AnchorPoint            = Vector2.new(0.5, 0.5),
	Size                   = UDim2.new(0, PANEL_W, 0, HEADER_H),
	Position               = UDim2.new(0.5, 0, 0.5, 0),
	BackgroundColor3       = T.Bg,
	BackgroundTransparency = 0,
	BorderSizePixel        = 0,
	Visible                = false,
	Active                 = true,
	ClipsDescendants       = true,
}, screenGui)
crn(14, panel)
ThemeModule.CreateAnimatedStroke(panel, 1.5, "Primary", 1.2)
local panelAnim = PanelAnimationController.new(panel, { CollapsedHeight = HEADER_H })

local header = make("Frame", {
	Size             = UDim2.new(1, 0, 0, HEADER_H),
	BackgroundColor3 = T.Card,
	BorderSizePixel  = 0,
	Active           = true,
}, panel)
crn(14, header)

local modeIcon = make("TextLabel", {
	Size                   = UDim2.new(0, 28, 1, 0),
	Position               = UDim2.new(0, 12, 0, 0),
	BackgroundTransparency = 1,
	Text                   = "[V]",
	TextColor3             = Color3.fromRGB(230, 230, 230),
	Font                   = Enum.Font.GothamBold,
	TextSize               = 11,
}, header)

local titleLabel = make("TextLabel", {
	Size                   = UDim2.new(1, -80, 1, 0),
	Position               = UDim2.new(0, 44, 0, 0),
	BackgroundTransparency = 1,
	Text                   = "VIP Commands",
	TextColor3             = Color3.fromRGB(230, 230, 230),
	Font                   = Enum.Font.GothamBold,
	TextSize               = 13,
	TextXAlignment         = Enum.TextXAlignment.Left,
}, header)

local closeBtn = make("TextButton", {
	Size             = UDim2.new(0, 26, 0, 26),
	Position         = UDim2.new(1, -34, 0.5, -13),
	BackgroundColor3 = T.Close,
	Text             = "x",
	TextColor3       = T.Text,
	Font             = Enum.Font.GothamBold,
	TextSize         = 14,
	AutoButtonColor  = false,
	BorderSizePixel  = 0,
}, header)
crn(6, closeBtn)

local body = make("Frame", {
	Size                   = UDim2.new(1, 0, 1, -HEADER_H),
	Position               = UDim2.new(0, 0, 0, HEADER_H),
	BackgroundTransparency = 1,
	ClipsDescendants       = true,
}, panel)

local vipContent = make("Frame", {
	Name                   = "VIPContent",
	Size                   = UDim2.new(1, 0, 1, 0),
	BackgroundTransparency = 1,
	Visible                = false,
}, body)

local vipScroll = make("ScrollingFrame", {
	Size                       = UDim2.new(1, 0, 1, 0),
	BackgroundTransparency     = 1,
	ScrollBarThickness         = 0,
	ScrollBarImageTransparency = 1,
	ScrollingEnabled           = true,
	CanvasSize                 = UDim2.new(0, 0, 0, 0),
	AutomaticCanvasSize        = Enum.AutomaticSize.Y,
	BorderSizePixel            = 0,
	ScrollingDirection         = Enum.ScrollingDirection.Y,
	VerticalScrollBarInset     = Enum.ScrollBarInset.None,
	ElasticBehavior            = Enum.ElasticBehavior.Always,
}, vipContent)

make("UIListLayout", {
	Padding             = UDim.new(0, 7),
	SortOrder           = Enum.SortOrder.LayoutOrder,
	HorizontalAlignment = Enum.HorizontalAlignment.Center,
}, vipScroll)

make("UIPadding", {
	PaddingTop    = UDim.new(0, 8),
	PaddingBottom = UDim.new(0, 8),
	PaddingLeft   = UDim.new(0, 8),
	PaddingRight  = UDim.new(0, 8),
}, vipScroll)

local glowContent = make("Frame", {
	Name                   = "GlowContent",
	Size                   = UDim2.new(1, 0, 1, 0),
	BackgroundTransparency = 1,
	Visible                = false,
}, body)
make("UIPadding", {
	PaddingLeft   = UDim.new(0, 12), PaddingRight  = UDim.new(0, 12),
	PaddingTop    = UDim.new(0, 10), PaddingBottom = UDim.new(0, 10),
}, glowContent)

make("TextLabel", {
	Size                   = UDim2.new(1, 0, 0, 15),
	BackgroundTransparency = 1,
	Text                   = "Pilih warna  |  tekan R untuk siklus:",
	TextColor3             = Color3.fromRGB(140, 140, 160),
	Font                   = Enum.Font.Gotham,
	TextSize               = 11,
	TextXAlignment         = Enum.TextXAlignment.Left,
}, glowContent)

local colorGrid = make("Frame", {
	Size                   = UDim2.new(1, 0, 0, 68),
	Position               = UDim2.new(0, 0, 0, 20),
	BackgroundTransparency = 1,
}, glowContent)

make("UIGridLayout", {
	CellSize              = UDim2.new(0, 28, 0, 28),
	CellPadding           = UDim2.new(0, 7, 0, 7),
	FillDirectionMaxCells = 9,
	HorizontalAlignment   = Enum.HorizontalAlignment.Left,
	SortOrder             = Enum.SortOrder.LayoutOrder,
}, colorGrid)

local tooltipLabel = make("TextLabel", {
	Size                   = UDim2.new(1, 0, 0, 14),
	Position               = UDim2.new(0, 0, 0, 94),
	BackgroundTransparency = 1,
	Text                   = "",
	TextColor3             = Color3.fromRGB(200, 200, 200),
	Font                   = Enum.Font.Gotham,
	TextSize               = 11,
	TextXAlignment         = Enum.TextXAlignment.Center,
}, glowContent)

make("TextLabel", {
	Size                   = UDim2.new(1, 0, 0, 13),
	Position               = UDim2.new(0, 0, 0, 110),
	BackgroundTransparency = 1,
	Text                   = "Klik / tap untuk toggle lampu",
	TextColor3             = Color3.fromRGB(90, 90, 110),
	Font                   = Enum.Font.Gotham,
	TextSize               = 10,
	TextXAlignment         = Enum.TextXAlignment.Center,
}, glowContent)

local palette = {
	{ Color3.fromRGB(255,255,255), "Putih"     },
	{ Color3.fromRGB(255,0,  0  ), "Merah"     },
	{ Color3.fromRGB(255,140,0  ), "Oranye"    },
	{ Color3.fromRGB(255,255,0  ), "Kuning"    },
	{ Color3.fromRGB(0,  255,0  ), "Hijau"     },
	{ Color3.fromRGB(0,  170,255), "Biru Muda" },
	{ Color3.fromRGB(0,  0,  255), "Biru"      },
	{ Color3.fromRGB(180,0,  255), "Ungu"      },
	{ Color3.fromRGB(255,0,  110), "Pink"      },
	{ Color3.fromRGB(0,  0,  0  ), "Hitam"     },
}

for i, data in ipairs(palette) do
	local col, name = data[1], data[2]
	local isBlack   = (col == Color3.fromRGB(0,0,0))
	local btn = make("TextButton", {
		LayoutOrder      = i,
		Size             = UDim2.new(0, 28, 0, 28),
		Text             = "",
		BackgroundColor3 = col,
	}, colorGrid)
	crn(99, btn)
	local stroke_ = ThemeModule.CreateStaticStroke(
		btn, 1.5,
		isBlack and Color3.fromRGB(150,150,150) or Color3.fromRGB(255,255,255),
		0.65
	)
	btn.MouseEnter:Connect(function()
		tooltipLabel.Text = name
		if stroke_ ~= selectedStroke then tw(stroke_, 0.1, { Transparency=0.1, Thickness=2 }) end
	end)
	btn.MouseLeave:Connect(function()
		tooltipLabel.Text = ""
		if stroke_ ~= selectedStroke then tw(stroke_, 0.1, { Transparency=0.65, Thickness=1.5 }) end
	end)
	btn.MouseButton1Click:Connect(function()
		if not currentRemote then return end
		currentRemote:FireServer("setColor", col)
		if selectedStroke and selectedStroke ~= stroke_ then
			tw(selectedStroke, 0.1, { Transparency=0.65, Thickness=1.5 })
		end
		selectedStroke = stroke_
		tw(stroke_, 0.1, { Transparency=0, Thickness=2.5 })
	end)
end

local function showPanel()
	local h = PANEL_H[currentMode] or PANEL_H.vip
	menuOpen = true
	panelAnim:Open(h)
end

local function hidePanel()
	menuOpen = false
	panelAnim:Close()
end

local function buildVIP()
	if vipBuilt then return end
	vipBuilt = true

	local function secLabel(order, text)
		local f = make("Frame", {
			Size                   = UDim2.new(1, 0, 0, 16),
			BackgroundTransparency = 1,
			LayoutOrder            = order,
		}, vipScroll)
		local lbl = make("TextLabel", {
			Size                   = UDim2.new(1, 0, 1, 0),
			BackgroundTransparency = 1,
			Text                   = text,
			Font                   = Enum.Font.GothamBold,
			TextSize               = 11,
			TextColor3             = Color3.fromRGB(255,255,255),
			TextXAlignment         = Enum.TextXAlignment.Left,
		}, f)
		addGrad(lbl, 0, true)
	end

	local inCard = make("Frame", {
		Size             = UDim2.new(1, 0, 0, 40),
		BackgroundColor3 = T.Card,
		LayoutOrder      = 1,
	}, vipScroll)
	crn(8, inCard)
	sk(T.Accent, 1.5, 0.3, inCard)

	local inBox = make("TextBox", {
		Size              = UDim2.new(1, -60, 0, 28),
		Position          = UDim2.new(0, 6, 0.5, 0),
		AnchorPoint       = Vector2.new(0, 0.5),
		BackgroundColor3  = T.Bg,
		Text              = "",
		PlaceholderText   = "/re  /hat id1 id2  /size 0.5",
		Font              = Enum.Font.Code,
		TextSize          = 12,
		TextColor3        = T.Text,
		PlaceholderColor3 = T.Sub,
		ClearTextOnFocus  = false,
		TextXAlignment    = Enum.TextXAlignment.Left,
	}, inCard)
	crn(6, inBox)
	make("UIPadding", {
		PaddingLeft = UDim.new(0,8), PaddingRight = UDim.new(0,8),
	}, inBox)

	local runBtn = make("TextButton", {
		Size             = UDim2.new(0, 46, 0, 28),
		Position         = UDim2.new(1, -52, 0.5, 0),
		AnchorPoint      = Vector2.new(0, 0.5),
		BackgroundColor3 = T.Accent,
		Text             = "▶ Jalankan",
		Font             = Enum.Font.GothamBold,
		TextSize         = 11,
		TextColor3       = Color3.fromRGB(30,30,30),
		AutoButtonColor  = false,
	}, inCard)
	crn(6, runBtn)
	addGrad(runBtn, 45, false)

	local function resetAvatar()
		if RE.ResetAvatar then RE.ResetAvatar:FireServer() end
	end

	local function run(text)
		text = (text or ""):lower():match("^%s*(.-)%s*$")
		if text == "" then return end
		if text == "/re" then
			inBox.Text = ""; resetAvatar(); return
		end
		local hatArgs = text:match("^/hat%s+(.+)$")
		if hatArgs then
			local ids = {}
			for id in hatArgs:gmatch("%d+") do
				table.insert(ids, tonumber(id))
				if #ids >= MAX_HAT_CLIENT then break end
			end
			if #ids > 0 and RE.HatTryOn then RE.HatTryOn:FireServer(ids); inBox.Text = "" end
			return
		end
		local sv = text:match("^/size%s+([%d%.]+)$")
		if sv then
			local n = tonumber(sv)
			if n and RE.SetSize then RE.SetSize:FireServer(math.clamp(n,0.3,1.0)); inBox.Text = "" end
			return
		end
	end

	runBtn.MouseButton1Click:Connect(function() run(inBox.Text) end)
	inBox.FocusLost:Connect(function(enter) if enter then run(inBox.Text) end end)

	secLabel(2, "⚡  AKSI CEPAT")

	local qGrid = make("Frame", {
		Size                   = UDim2.new(1, 0, 0, 76),
		BackgroundTransparency = 1,
		LayoutOrder            = 3,
	}, vipScroll)
	make("UIGridLayout", {
		CellSize            = UDim2.new(0.5, -5, 0, 34),
		CellPadding         = UDim2.new(0, 10, 0, 8),
		SortOrder           = Enum.SortOrder.LayoutOrder,
		HorizontalAlignment = Enum.HorizontalAlignment.Center,
	}, qGrid)

	local quick = {
		{ "🔄", UIStrings.VIP.ResetAvatar, resetAvatar },
		{ "🔬", "Ukuran 0.3×",   function() if RE.SetSize then RE.SetSize:FireServer(0.3) end end },
		{ "👤", "Ukuran Normal",  function() if RE.SetSize then RE.SetSize:FireServer(1.0) end end },
		{ "📏", "Ukuran 0.5×",   function() if RE.SetSize then RE.SetSize:FireServer(0.5) end end },
	}
	for i, q in ipairs(quick) do
		local b = make("TextButton", {
			BackgroundColor3 = T.Card,
			Text             = q[1].."  "..q[2],
			Font             = Enum.Font.GothamMedium,
			TextSize         = 11,
			TextColor3       = T.TextDim,
			AutoButtonColor  = false,
			LayoutOrder      = i,
		}, qGrid)
		crn(7, b)
		sk(T.Border, 1, 0.5, b)
		b.MouseButton1Click:Connect(function()
			q[3]()
			tw(b, 0.1, { BackgroundColor3 = T.AccDim })
			task.wait(0.15)
			tw(b, 0.1, { BackgroundColor3 = T.Card })
		end)
		b.MouseEnter:Connect(function() tw(b, 0.12, { BackgroundColor3=T.CardHover, TextColor3=T.Accent }) end)
		b.MouseLeave:Connect(function() tw(b, 0.12, { BackgroundColor3=T.Card,      TextColor3=T.TextDim }) end)
	end

	secLabel(4, "📏  PRESET UKURAN")

	local sGrid = make("Frame", {
		Size                   = UDim2.new(1, 0, 0, 30),
		BackgroundTransparency = 1,
		LayoutOrder            = 5,
	}, vipScroll)
	make("UIGridLayout", {
		CellSize            = UDim2.new(0.25, -8, 1, 0),
		CellPadding         = UDim2.new(0, 10, 0, 0),
		SortOrder           = Enum.SortOrder.LayoutOrder,
		HorizontalAlignment = Enum.HorizontalAlignment.Center,
	}, sGrid)

	for i, sp in ipairs({ {"0.3×",0.3},{"0.5×",0.5},{"0.75×",0.75},{"1×",1.0} }) do
		local b = make("TextButton", {
			BackgroundColor3 = T.Card,
			Text             = sp[1],
			Font             = Enum.Font.GothamBold,
			TextSize         = 12,
			TextColor3       = T.TextDim,
			AutoButtonColor  = false,
			LayoutOrder      = i,
		}, sGrid)
		crn(7, b)
		sk(T.Border, 1, 0.5, b)
		b.MouseButton1Click:Connect(function()
			if RE.SetSize then RE.SetSize:FireServer(sp[2]) end
			tw(b, 0.1, { BackgroundColor3=T.Accent, TextColor3=Color3.fromRGB(30,30,30) })
			task.wait(0.2)
			tw(b, 0.12, { BackgroundColor3=T.Card, TextColor3=T.TextDim })
		end)
		b.MouseEnter:Connect(function() tw(b, 0.12, { BackgroundColor3=T.CardHover, TextColor3=T.Accent }) end)
		b.MouseLeave:Connect(function() tw(b, 0.12, { BackgroundColor3=T.Card,      TextColor3=T.TextDim }) end)
	end

	local helpRows = {
		{ cmd = "/re",          desc = "→ Atur ulang avatar & aksesori" },
		{ cmd = "/hat id1 id2", desc = "→ Pakai aksesori (maks 5 ID)" },
		{ cmd = "/size [n]",    desc = "→ Ukuran karakter (0.3–1.0)" },
	}
	local CMD_H, DESC_H, ROW_GAP = 13, 13, 6
	local BADGE_H, V_PAD = 28, 10

	local textBlockH = 0
	for i = 1, #helpRows do
		textBlockH = textBlockH + CMD_H + DESC_H
		if i < #helpRows then textBlockH = textBlockH + ROW_GAP end
	end
	local helpCardH = V_PAD + BADGE_H + 8 + textBlockH + V_PAD

	local help = make("Frame", {
		Name             = "HelpCard",
		Size             = UDim2.new(1, 0, 0, helpCardH),
		BackgroundColor3 = T.Card,
		LayoutOrder      = 6,
	}, vipScroll)
	crn(10, help)
	sk(T.Border, 1, 0.5, help)

	local hdr = make("Frame", {
		Size                   = UDim2.new(1, 0, 0, BADGE_H),
		Position               = UDim2.new(0, 0, 0, V_PAD),
		BackgroundTransparency = 1,
	}, help)
	local ico = make("Frame", {
		Size             = UDim2.new(0, 20, 0, 20),
		Position         = UDim2.new(0, 10, 0.5, 0),
		AnchorPoint      = Vector2.new(0, 0.5),
		BackgroundColor3 = T.AccDim,
	}, hdr)
	crn(5, ico)
	make("TextLabel", {
		Size=UDim2.new(1,0,1,0), BackgroundTransparency=1,
		Text="💡", Font=Enum.Font.GothamBold, TextSize=12, TextColor3=T.Accent,
	}, ico)
	local hTitle = make("TextLabel", {
		Size                   = UDim2.new(1, -40, 1, 0),
		Position               = UDim2.new(0, 38, 0, 0),
		BackgroundTransparency = 1,
		Text                   = "VIP COMMANDS",
		Font                   = Enum.Font.GothamBold,
		TextSize               = 11,
		TextColor3             = Color3.fromRGB(255,255,255),
		TextXAlignment         = Enum.TextXAlignment.Left,
	}, hdr)
	addGrad(hTitle, 0, true)

	local yOff = V_PAD + BADGE_H + 8
	for _, row in ipairs(helpRows) do
		make("TextLabel", {
			Size                   = UDim2.new(1, -20, 0, CMD_H),
			Position               = UDim2.new(0, 10, 0, yOff),
			BackgroundTransparency = 1,
			Text                   = row.cmd,
			Font                   = Enum.Font.Code,
			TextSize               = 12,
			TextColor3             = T.Accent,
			TextXAlignment         = Enum.TextXAlignment.Left,
			TextYAlignment         = Enum.TextYAlignment.Center,
		}, help)
		yOff = yOff + CMD_H
		make("TextLabel", {
			Size                   = UDim2.new(1, -20, 0, DESC_H),
			Position               = UDim2.new(0, 10, 0, yOff),
			BackgroundTransparency = 1,
			Text                   = "   "..row.desc,
			Font                   = Enum.Font.Gotham,
			TextSize               = 11,
			TextColor3             = T.TextDim,
			TextXAlignment         = Enum.TextXAlignment.Left,
			TextYAlignment         = Enum.TextYAlignment.Center,
		}, help)
		yOff = yOff + DESC_H + ROW_GAP
	end

	local stat = make("Frame", {
		Name             = "StatusCard",
		Size             = UDim2.new(1, 0, 0, 42),
		BackgroundColor3 = T.Card,
		LayoutOrder      = 7,
	}, vipScroll)
	crn(10, stat)
	sk(T.Border, 1, 0.5, stat)

	make("TextLabel", {
		Size                   = UDim2.new(1, -16, 0, 13),
		Position               = UDim2.new(0, 10, 0, 5),
		BackgroundTransparency = 1,
		Text                   = "📊 STATUS",
		Font                   = Enum.Font.GothamBold,
		TextSize               = 9,
		TextColor3             = T.Sub,
		TextXAlignment         = Enum.TextXAlignment.Left,
	}, stat)

	local sc = make("Frame", {
		Size                   = UDim2.new(1, -20, 0, 18),
		Position               = UDim2.new(0, 10, 0, 20),
		BackgroundTransparency = 1,
	}, stat)

	StatusSize = make("TextLabel", {
		Size                   = UDim2.new(0.5, 0, 1, 0),
		BackgroundTransparency = 1,
		Text                   = "📏 Size: 1.00×",
		Font                   = Enum.Font.GothamMedium,
		TextSize               = 11,
		TextColor3             = T.TextDim,
		TextXAlignment         = Enum.TextXAlignment.Left,
	}, sc)

	StatusHats = make("TextLabel", {
		Size                   = UDim2.new(0.5, 0, 1, 0),
		Position               = UDim2.new(0.5, 0, 0, 0),
		BackgroundTransparency = 1,
		Text                   = "🎩 Hats: 0",
		Font                   = Enum.Font.GothamMedium,
		TextSize               = 11,
		TextColor3             = T.TextDim,
		TextXAlignment         = Enum.TextXAlignment.Left,
	}, sc)
end

local function updateStatus()
	if not StatusSize or not StatusHats then return end
	StatusSize.Text = string.format(UIStrings.VIP.SizeStatus, VIPState.currentSize)
	local n = 0
	for _ in pairs(VIPState.equipped) do n += 1 end
	StatusHats.Text = string.format(UIStrings.VIP.HatsStatus, n)
end

local function switchMode(mode)
	currentMode         = mode
	vipContent.Visible  = (mode == "vip")
	glowContent.Visible = (mode == "glowstick")

	if mode == "vip" then
		modeIcon.Text   = UIStrings.VIP.PrefixV
		titleLabel.Text = UIStrings.VIP.Title
		buildVIP()
		updateStatus()
	elseif mode == "glowstick" then
		modeIcon.Text   = UIStrings.VIP.PrefixG
		titleLabel.Text = UIStrings.VIP.GlowstickTitle
	end
end

local function refreshIcon()
	if activeToolMode then
		switchMode(activeToolMode)
		toolIcon:setEnabled(true)
	elseif isVIP then
		switchMode("vip")
		toolIcon:setEnabled(true)
	else
		toolIcon:setEnabled(false)
		toolIcon:deselect()
		hidePanel()
		currentMode = nil
	end
end

local function showTool(mode) activeToolMode = mode; refreshIcon() end
local function hideTool()
	activeToolMode = nil; currentRemote = nil; refreshIcon()
end

toolIcon.selected:Connect(function()
	if not currentMode then return end
	showPanel()
end)
toolIcon.deselected:Connect(function() hidePanel() end)

closeBtn.MouseButton1Click:Connect(function() hidePanel(); toolIcon:deselect() end)
closeBtn.MouseEnter:Connect(function()
	tw(closeBtn, 0.1, { BackgroundColor3 = T.CloseHov, TextColor3 = T.Text })
end)
closeBtn.MouseLeave:Connect(function()
	tw(closeBtn, 0.1, { BackgroundColor3 = T.Close, TextColor3 = T.Text })
end)

local function bindGlow(tool)
	if boundTools[tool] then return end
	if not tool.Name:lower():find("glowstick") then return end
	local rf = tool:FindFirstChild("GlowRemote") or tool:WaitForChild("GlowRemote",3)
	if not rf then return end
	boundTools[tool] = true
	local wheel = {
		Color3.fromRGB(0,255,170), Color3.fromRGB(255,0,110),
		Color3.fromRGB(255,170,0), Color3.fromRGB(0,170,255),
		Color3.fromRGB(180,0,255), Color3.fromRGB(0,255,60),
	}
	local ci, ic = 1, nil
	tool.Equipped:Connect(function()
		currentRemote = rf; selectedStroke = nil; showTool("glowstick")
		ic = UIS.InputBegan:Connect(function(inp, gpe)
			if gpe then return end
			if inp.UserInputType == Enum.UserInputType.Keyboard
				and inp.KeyCode == Enum.KeyCode.R then
				ci = (ci % #wheel) + 1; rf:FireServer("setColor", wheel[ci])
			end
		end)
		tool.Activated:Connect(function() rf:FireServer("toggleLights") end)
	end)
	tool.Unequipped:Connect(function()
		if ic then ic:Disconnect(); ic = nil end
		currentRemote = nil
		if activeToolMode == "glowstick" then hideTool() end
	end)
	if player.Character and tool.Parent == player.Character then
		currentRemote = rf; showTool("glowstick")
	end
end

local function bindTool(tool)
	if not tool:IsA("Tool") then return end
	bindGlow(tool)
end

local function scan(parent)
	if not parent then return end
	for _, c in ipairs(parent:GetChildren()) do
		if c:IsA("Tool") then bindTool(c) end
	end
	parent.ChildAdded:Connect(function(c)
		if c:IsA("Tool") then bindTool(c) end
	end)
end

if RE.ShowIcon then
	RE.ShowIcon.OnClientEvent:Connect(function(v)
		isVIP = v
		if MenuConfig.SetVIPAccess then MenuConfig.SetVIPAccess(v) end
		refreshIcon()
	end)
end
if RE.RequestIcon then
	RE.RequestIcon.OnClientEvent:Connect(function(v)
		isVIP = v
		if MenuConfig.SetVIPAccess then MenuConfig.SetVIPAccess(v) end
		refreshIcon()
	end)
end
if RE.Result then
	RE.Result.OnClientEvent:Connect(function(ok, msg)
		print((ok and "✅" or "❌").." "..msg)
	end)
end
if RE.SyncData then
	RE.SyncData.OnClientEvent:Connect(function(data)
		VIPState.equipped    = data.equipped    or {}
		VIPState.currentSize = data.currentSize or 1.0
		updateStatus()
	end)
end

screenGui.Destroying:Connect(function()
	if guiScaler then guiScaler:Destroy() end
end)

task.spawn(function()
	scan(player:WaitForChild("Backpack", 10))
	if player.Character then scan(player.Character) end

	player.CharacterAdded:Connect(function(char)
		activeToolMode = nil; currentRemote = nil
		currentMode    = nil; boundTools    = {}
		hidePanel(); toolIcon:deselect()
		task.wait(0.3); scan(char)
		task.spawn(function() scan(player:WaitForChild("Backpack",5)) end)
		task.wait(0.5); refreshIcon()
	end)

	task.wait(0.6)
	if RE.RequestIcon then RE.RequestIcon:FireServer() end
end)

print("✅ UnifiedToolbarUI — AutoScale + Tengah + Tergabung Siap")
