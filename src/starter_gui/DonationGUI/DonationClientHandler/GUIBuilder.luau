-- MODULE: GUIBuilder (FINAL - Avatar Headshot & Fixed Layout)
-- ========================================

local GUIBuilder = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ThemeModule       = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("ThemeModule"))
local ScaleSystem       = require(ReplicatedStorage:WaitForChild("AutoScaleSystem"):WaitForChild("ScaleSystem"))

local HEADER_TITLE = {
	MAIN    = "Donasi ke Server",
	MESSAGE = "Tulis Pesan Donasi",
}

local CFG = {
	CORNER_MAIN       = ThemeModule.Styles.Header.CornerRadius,
	CORNER_BTN        = ThemeModule.Styles.Button.CornerRadius,
	CORNER_SMALL      = ThemeModule.Styles.Input.CornerRadius,
	FONT              = ThemeModule.Styles.Button.Font,
	FONT_BODY         = Enum.Font.Gotham,
	BORDER_THICKNESS  = 2,
	ITEM_HEIGHT       = 54,
	ITEM_SPACING      = 5,
	CONTAINER_PADDING = 2,
}

local C = ThemeModule.Colors

local function corner(radius, parent)
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, radius)
	c.Parent = parent
	return c
end

local function padding(top, right, bottom, left, parent)
	local p = Instance.new("UIPadding")
	p.PaddingTop    = UDim.new(0, top)
	p.PaddingRight  = UDim.new(0, right or top)
	p.PaddingBottom = UDim.new(0, bottom or top)
	p.PaddingLeft   = UDim.new(0, left or right or top)
	p.Parent = parent
	return p
end

local function makeFrame(props)
	local f = Instance.new("Frame")
	f.Name                   = props.Name or "Frame"
	f.Size                   = props.Size or UDim2.new(0, 100, 0, 100)
	f.Position               = props.Position or UDim2.new(0, 0, 0, 0)
	f.AnchorPoint            = props.AnchorPoint or Vector2.new(0, 0)
	f.BackgroundColor3       = props.BG or C.BackgroundDark
	f.BackgroundTransparency = props.Transparency or 0
	f.BorderSizePixel        = 0
	f.ZIndex                 = props.ZIndex or 1
	f.Visible                = props.Visible ~= nil and props.Visible or true
	f.ClipsDescendants       = props.Clips or false
	f.Parent                 = props.Parent
	if props.CornerRadius then corner(props.CornerRadius, f) end
	return f
end

local function makeLabel(props)
	local l = Instance.new("TextLabel")
	l.Name                   = props.Name or "Label"
	l.Size                   = props.Size or UDim2.new(1, 0, 0, 20)
	l.Position               = props.Position or UDim2.new(0, 0, 0, 0)
	l.AnchorPoint            = props.AnchorPoint or Vector2.new(0, 0)
	l.BackgroundTransparency = 1
	l.Text                   = props.Text or ""
	l.TextColor3             = props.Color or C.TextWhite
	l.TextSize               = props.TextSize or 14
	l.Font                   = props.Font or CFG.FONT_BODY
	l.TextXAlignment         = props.XAlign or Enum.TextXAlignment.Left
	l.TextYAlignment         = props.YAlign or Enum.TextYAlignment.Center
	l.TextWrapped            = props.Wrap or false
	l.RichText               = props.RichText or false
	l.ZIndex                 = props.ZIndex or 1
	l.Parent                 = props.Parent
	return l
end

local function makeButton(props)
	local b = Instance.new("TextButton")
	b.Name                   = props.Name or "Button"
	b.Size                   = props.Size or UDim2.new(1, 0, 0, 36)
	b.Position               = props.Position or UDim2.new(0, 0, 0, 0)
	b.AnchorPoint            = props.AnchorPoint or Vector2.new(0, 0)
	b.BackgroundColor3       = props.BG or C.BackgroundMedium
	b.BackgroundTransparency = props.Transparency or 0
	b.Text                   = props.Text or "Button"
	b.TextColor3             = props.Color or C.TextWhite
	b.TextSize               = props.TextSize or 14
	b.Font                   = props.Font or CFG.FONT
	b.BorderSizePixel        = 0
	b.AutoButtonColor        = false
	b.ZIndex                 = props.ZIndex or 1
	b.Parent                 = props.Parent
	if props.CornerRadius then corner(props.CornerRadius, b) end
	return b
end

local function makeTextBox(props)
	local t = Instance.new("TextBox")
	t.Name              = props.Name or "TextBox"
	t.Size              = props.Size or UDim2.new(1, 0, 0, 40)
	t.Position          = props.Position or UDim2.new(0, 0, 0, 0)
	t.AnchorPoint       = props.AnchorPoint or Vector2.new(0, 0)
	t.BackgroundColor3  = C.BackgroundLight
	t.BorderSizePixel   = 0
	t.Text              = ""
	t.PlaceholderText   = props.Placeholder or "Ketik di sini..."
	t.PlaceholderColor3 = C.TextMuted
	t.TextColor3        = C.TextWhite
	t.TextSize          = props.TextSize or 14
	t.Font              = CFG.FONT_BODY
	t.ClearTextOnFocus  = false
	t.TextXAlignment    = Enum.TextXAlignment.Left
	t.ZIndex            = props.ZIndex or 1
	t.Parent            = props.Parent
	corner(CFG.CORNER_SMALL, t)
	padding(8, 12, 8, 12, t)
	ThemeModule.CreateAnimatedStroke(t, 1, "Primary", 1)
	return t
end

local function makeScrollFrame(props)
	local sf = Instance.new("ScrollingFrame")
	sf.Name                     = props.Name or "ScrollingFrame"
	sf.Size                     = props.Size or UDim2.new(1, 0, 1, 0)
	sf.Position                 = props.Position or UDim2.new(0, 0, 0, 0)
	sf.BackgroundTransparency   = 1
	sf.BorderSizePixel          = 0
	sf.ScrollBarThickness       = 4
	sf.ScrollBarImageColor3     = C.Primary1
	sf.CanvasSize               = UDim2.new(0, 0, 0, 0)
	sf.ScrollingDirection       = Enum.ScrollingDirection.Y
	sf.HorizontalScrollBarInset = Enum.ScrollBarInset.ScrollBar
	sf.ZIndex                   = props.ZIndex or 1
	sf.Parent                   = props.Parent
	return sf
end

local function applyStroke(frame, thickness, gradientName, speed)
	ThemeModule.CreateAnimatedStroke(frame, thickness or 2, gradientName or "Primary", speed or 1.2)
end

local function buildProductTemplate(container, zBase)
	local bt          = CFG.BORDER_THICKNESS
	local innerRadius = CFG.CORNER_BTN
	local outerRadius = innerRadius + bt

	local borderFrame = makeFrame({
		Name         = "TemplateFrame",
		Size         = UDim2.new(1, 0, 0, CFG.ITEM_HEIGHT),
		BG           = C.Primary1,
		CornerRadius = outerRadius,
		ZIndex       = zBase,
		Visible      = false,
		Parent       = container,
	})
	ThemeModule.CreateAnimatedGradient(borderFrame, "Primary", 45, 1)

	local productCard = makeFrame({
		Name         = "ProductCard",
		Size         = UDim2.new(1, -(bt * 2), 1, -(bt * 2)),
		Position     = UDim2.new(0, bt, 0, bt),
		BG           = C.BackgroundMedium,
		CornerRadius = innerRadius,
		ZIndex       = zBase + 1,
		Parent       = borderFrame,
	})

	makeButton({
		Name         = "TemplateBtn",
		Size         = UDim2.new(1, -12, 1, -8),
		Position     = UDim2.new(0, 6, 0, 4),
		Transparency = 1,
		Text         = "R$ 100",
		TextSize     = 14,
		Font         = CFG.FONT,
		Color        = C.TextWhite,
		ZIndex       = zBase + 2,
		Parent       = productCard,
	})

	return borderFrame
end

local function buildHeader(parent, titleText, zBase)
	local header = makeFrame({
		Name         = "Header",
		Size         = UDim2.new(1, 0, 0, ThemeModule.Styles.Header.Height),
		BG           = ThemeModule.Styles.Header.BackgroundColor,
		CornerRadius = CFG.CORNER_MAIN,
		Clips        = true,
		ZIndex       = zBase + 1,
		Parent       = parent,
	})

	local hGrad    = Instance.new("UIGradient")
	hGrad.Color    = ThemeModule.Gradients.DarkToLight
	hGrad.Rotation = 90
	hGrad.Parent   = header

	local divider = makeFrame({
		Name     = "Divider",
		Size     = UDim2.new(1, 0, 0, 2),
		Position = UDim2.new(0, 0, 1, -2),
		BG       = C.Primary1,
		ZIndex   = zBase + 2,
		Parent   = header,
	})
	ThemeModule.CreateStaticGradient(divider, "Primary", 0)

	local titleLabel = makeLabel({
		Name     = "Title",
		Size     = UDim2.new(1, -56, 1, 0),
		Position = UDim2.new(0, 16, 0, 0),
		Text     = titleText,
		TextSize = 15,
		Font     = CFG.FONT,
		Color    = C.TextWhite,
		ZIndex   = zBase + 3,
		Parent   = header,
	})
	ThemeModule.CreateAnimatedGradient(titleLabel, "Primary", 0, 1.2)

	local closeBtn = makeButton({
		Name         = "CloseBtn",
		Size         = UDim2.new(0, 32, 0, 32),
		Position     = UDim2.new(1, -40, 0.5, 0),
		AnchorPoint  = Vector2.new(0, 0.5),
		BG           = C.CloseRed,
		Text         = "x",
		TextSize     = 14,
		Font         = CFG.FONT,
		Color        = C.TextWhite,
		CornerRadius = 6,
		ZIndex       = zBase + 3,
		Parent       = header,
	})
	closeBtn.MouseEnter:Connect(function() closeBtn.BackgroundColor3 = C.CloseRedHover end)
	closeBtn.MouseLeave:Connect(function() closeBtn.BackgroundColor3 = C.CloseRed      end)

	return header
end

local function buildMainFrame(gui)
	if gui:FindFirstChild("MainFrame") then return gui:FindFirstChild("MainFrame") end

	local frame = makeFrame({
		Name         = "MainFrame",
		Size         = UDim2.new(0, 320, 0, 420),
		Position     = UDim2.new(0.5, 0, 0.5, 0),
		AnchorPoint  = Vector2.new(0.5, 0.5),
		BG           = C.BackgroundDark,
		CornerRadius = CFG.CORNER_MAIN,
		ZIndex       = 10,
		Visible      = false,
		Parent       = gui,
	})
	buildHeader(frame, HEADER_TITLE.MAIN, 10)

	makeLabel({
		Name     = "Subtitle",
		Size     = UDim2.new(1, -24, 0, 24),
		Position = UDim2.new(0, 12, 0, 56),
		Text     = "Pilih jumlah donasi kamu",
		TextSize = 12,
		Color    = C.TextGray,
		ZIndex   = 11,
		Parent   = frame,
	})

	local container = makeScrollFrame({
		Name     = "Container",
		Size     = UDim2.new(1, -24, 1, -90),
		Position = UDim2.new(0, 12, 0, 86),
		ZIndex   = 11,
		Parent   = frame,
	})
	local cp = CFG.CONTAINER_PADDING
	padding(cp, cp, cp, cp, container)
	buildProductTemplate(container, 12)
	applyStroke(frame, 2, "Primary", 1.2)
	return frame
end

local function buildMessageFrame(gui)
	if gui:FindFirstChild("MessageFrame") then return gui:FindFirstChild("MessageFrame") end

	local frame = makeFrame({
		Name         = "MessageFrame",
		Size         = UDim2.new(0, 340, 0, 240),
		Position     = UDim2.new(0.5, 0, 0.5, 0),
		AnchorPoint  = Vector2.new(0.5, 0.5),
		BG           = C.BackgroundDark,
		CornerRadius = CFG.CORNER_MAIN,
		ZIndex       = 20,
		Visible      = false,
		Parent       = gui,
	})
	buildHeader(frame, HEADER_TITLE.MESSAGE, 20)

	makeLabel({
		Name     = "InfoLabel",
		Size     = UDim2.new(1, -24, 0, 22),
		Position = UDim2.new(0, 12, 0, 58),
		Text     = "Pesan akan dikirim ke semua player",
		TextSize = 11,
		Color    = C.TextMuted,
		ZIndex   = 21,
		Parent   = frame,
	})

	makeTextBox({
		Name        = "TextBox",
		Size        = UDim2.new(1, -24, 0, 70),
		Position    = UDim2.new(0, 12, 0, 84),
		Placeholder = "Tulis pesan kamu di sini... (maks 200 karakter)",
		TextSize    = 13,
		ZIndex      = 21,
		Parent      = frame,
	})

	local sendBtn = makeButton({
		Name         = "SendBtn",
		Size         = UDim2.new(0.55, -8, 0, 36),
		Position     = UDim2.new(0, 12, 0, 166),
		BG           = C.Primary2,
		Text         = "Kirim Pesan",
		TextSize     = 13,
		Color        = C.TextOnGradient,
		CornerRadius = CFG.CORNER_BTN,
		ZIndex       = 21,
		Parent       = frame,
	})
	ThemeModule.CreateStaticGradient(sendBtn, "Primary", 90)
	sendBtn.MouseEnter:Connect(function() sendBtn.BackgroundColor3 = C.Primary1 end)
	sendBtn.MouseLeave:Connect(function() sendBtn.BackgroundColor3 = C.Primary2 end)

	local cancelBtn = makeButton({
		Name         = "CancelBtn",
		Size         = UDim2.new(0.45, -8, 0, 36),
		Position     = UDim2.new(0.55, 4, 0, 166),
		BG           = C.BackgroundLight,
		Text         = "Batal",
		TextSize     = 13,
		Color        = C.TextGray,
		CornerRadius = CFG.CORNER_BTN,
		ZIndex       = 21,
		Parent       = frame,
	})
	cancelBtn.MouseEnter:Connect(function() cancelBtn.BackgroundColor3 = C.BackgroundLighter end)
	cancelBtn.MouseLeave:Connect(function() cancelBtn.BackgroundColor3 = C.BackgroundLight   end)

	applyStroke(frame, 2, "Primary", 1.2)
	return frame
end

-- ═══════════════════════════════════════════════════════════
-- NOTIFICATION FRAME - Avatar Headshot (Tanpa Close Button)
-- ═══════════════════════════════════════════════════════════
local function buildNotificationFrame(gui)
	if gui:FindFirstChild("NotificationFrame") then return gui:FindFirstChild("NotificationFrame") end

	local ACCENT_W = 4
	local AVATAR_SIZE = 46
	local BORDER_SIZE = 3
	local PADDING = 12

	local frame = makeFrame({
		Name         = "NotificationFrame",
		Size         = UDim2.new(0, 400, 0, 95),
		Position     = UDim2.new(0.5, 0, 0, -130),
		AnchorPoint  = Vector2.new(0.5, 0),
		BG           = C.BackgroundDark,
		CornerRadius = 14,
		Clips        = true,
		ZIndex       = 30,
		Visible      = false,
		Parent       = gui,
	})

	-- Accent bar vertikal di kiri (dengan padding)
	local accentBar = makeFrame({
		Name         = "AccentBar",
		Size         = UDim2.new(0, ACCENT_W, 1, -20),
		Position     = UDim2.new(0, PADDING, 0.5, 0),
		AnchorPoint  = Vector2.new(0, 0.5),
		BG           = C.Primary1,
		CornerRadius = 2,
		ZIndex       = 31,
		Parent       = frame,
	})
	ThemeModule.CreateStaticGradient(accentBar, "Primary", 90)

	-- Avatar container dengan border gradient
	local avatarStartX = PADDING + ACCENT_W + 10
	local avatarBorder = makeFrame({
		Name         = "AvatarBorder",
		Size         = UDim2.new(0, AVATAR_SIZE + BORDER_SIZE * 2, 0, AVATAR_SIZE + BORDER_SIZE * 2),
		Position     = UDim2.new(0, avatarStartX, 0.5, 0),
		AnchorPoint  = Vector2.new(0, 0.5),
		BG           = C.Primary1,
		CornerRadius = (AVATAR_SIZE + BORDER_SIZE * 2) / 2,
		ZIndex       = 31,
		Parent       = frame,
	})
	ThemeModule.CreateAnimatedGradient(avatarBorder, "Primary", 45, 1.5)

	-- Avatar container (inner)
	local avatarContainer = makeFrame({
		Name         = "AvatarContainer",
		Size         = UDim2.new(0, AVATAR_SIZE, 0, AVATAR_SIZE),
		Position     = UDim2.new(0.5, 0, 0.5, 0),
		AnchorPoint  = Vector2.new(0.5, 0.5),
		BG           = C.BackgroundMedium,
		CornerRadius = AVATAR_SIZE / 2,
		Clips        = true,
		ZIndex       = 32,
		Parent       = avatarBorder,
	})

	-- Avatar headshot image
	local avatarImage = Instance.new("ImageLabel")
	avatarImage.Name = "AvatarImage"
	avatarImage.Size = UDim2.new(1, 0, 1, 0)
	avatarImage.Position = UDim2.new(0, 0, 0, 0)
	avatarImage.BackgroundTransparency = 1
	avatarImage.Image = ""
	avatarImage.ScaleType = Enum.ScaleType.Crop
	avatarImage.ZIndex = 33
	avatarImage.Parent = avatarContainer

	-- Fallback icon
	makeLabel({
		Name     = "FallbackIcon",
		Size     = UDim2.new(1, 0, 1, 0),
		Text     = "💝",
		TextSize = 22,
		Font     = Enum.Font.GothamBold,
		Color    = C.TextWhite,
		XAlign   = Enum.TextXAlignment.Center,
		YAlign   = Enum.TextYAlignment.Center,
		ZIndex   = 32,
		Parent   = avatarContainer,
	})

	-- Online indicator
	local onlineIndicator = makeFrame({
		Name         = "OnlineIndicator",
		Size         = UDim2.new(0, 12, 0, 12),
		Position     = UDim2.new(1, -1, 1, -1),
		AnchorPoint  = Vector2.new(1, 1),
		BG           = Color3.fromRGB(76, 175, 80),
		CornerRadius = 6,
		ZIndex       = 34,
		Visible      = false,
		Parent       = avatarBorder,
	})

	local indicatorStroke = Instance.new("UIStroke")
	indicatorStroke.Color = C.BackgroundDark
	indicatorStroke.Thickness = 2
	indicatorStroke.Parent = onlineIndicator

	-- Content area untuk teks
	local contentX = avatarStartX + AVATAR_SIZE + BORDER_SIZE * 2 + 12
	local contentArea = makeFrame({
		Name         = "ContentArea",
		Size         = UDim2.new(1, -(contentX + 16), 1, -20),
		Position     = UDim2.new(0, contentX, 0, 10),
		Transparency = 1,
		ZIndex       = 31,
		Parent       = frame,
	})

	-- Header label
	makeLabel({
		Name     = "HeaderLabel",
		Size     = UDim2.new(1, 0, 0, 20),
		Position = UDim2.new(0, 0, 0, 0),
		Text     = "Donasi Baru!",
		TextSize = 14,
		Font     = Enum.Font.GothamBold,
		Color    = C.TextWhite,
		Wrap     = false,
		RichText = true,
		ZIndex   = 32,
		Parent   = contentArea,
	})

	-- Info label
	makeLabel({
		Name     = "Infolabel",
		Size     = UDim2.new(1, 0, 0, 18),
		Position = UDim2.new(0, 0, 0, 22),
		Text     = "Seseorang berdonasi",
		TextSize = 12,
		Font     = CFG.FONT_BODY,
		Color    = C.TextGray,
		Wrap     = true,
		RichText = true,
		ZIndex   = 32,
		Parent   = contentArea,
	})

	-- Message container
	local messageContainer = makeFrame({
		Name         = "MessageContainer",
		Size         = UDim2.new(1, 0, 0, 22),
		Position     = UDim2.new(0, 0, 0, 44),
		Transparency = 1,
		ZIndex       = 32,
		Visible      = false,
		Parent       = contentArea,
	})

	-- Quote mark
	makeLabel({
		Name     = "QuoteMark",
		Size     = UDim2.new(0, 10, 0, 22),
		Position = UDim2.new(0, 0, 0, 0),
		Text     = '"',
		TextSize = 14,
		Font     = Enum.Font.GothamBold,
		Color    = C.Primary1,
		XAlign   = Enum.TextXAlignment.Left,
		ZIndex   = 33,
		Parent   = messageContainer,
	})

	-- Message text
	makeLabel({
		Name     = "Message",
		Size     = UDim2.new(1, -12, 0, 22),
		Position = UDim2.new(0, 10, 0, 0),
		Text     = "",
		TextSize = 11,
		Font     = Enum.Font.GothamMedium,
		Color    = C.TextGray,
		Wrap     = true,
		ZIndex   = 33,
		Parent   = messageContainer,
	})

	-- Tier badge
	local tierBadge = makeFrame({
		Name         = "TierBadge",
		Size         = UDim2.new(0, 75, 0, 20),
		Position     = UDim2.new(1, -10, 0, 10),
		AnchorPoint  = Vector2.new(1, 0),
		BG           = C.Primary2,
		CornerRadius = 10,
		Transparency = 0.15,
		ZIndex       = 32,
		Parent       = frame,
	})
	ThemeModule.CreateStaticGradient(tierBadge, "Primary", 90)

	makeLabel({
		Name     = "TierText",
		Size     = UDim2.new(1, 0, 1, 0),
		Text     = "Thanks",
		TextSize = 9,
		Font     = Enum.Font.GothamBold,
		Color    = C.TextWhite,
		XAlign   = Enum.TextXAlignment.Center,
		YAlign   = Enum.TextYAlignment.Center,
		ZIndex   = 33,
		Parent   = tierBadge,
	})

	applyStroke(frame, 2, "Primary", 1.5)

	return frame
end

local function buildTopbarButton()
	local Icon = require(ReplicatedStorage:WaitForChild("Icon"))
	local icon = Icon.new()
		:setLabel("Donate")
	:setRight()
		:setOrder(2)
	return icon
end

function GUIBuilder.build(gui)
	gui = gui or script.Parent
	print("[GUIBuilder] 🏗️ Membangun GUI otomatis...")
	ThemeModule.GradientSystem.Start()

	local icon    = buildTopbarButton()
	local main    = buildMainFrame(gui)
	local msg     = buildMessageFrame(gui)
	local notif   = buildNotificationFrame(gui)
	local _scaler = gui:IsA("ScreenGui") and ScaleSystem.new(gui) or nil

	print("[GUIBuilder] ✅ Semua GUI berhasil dibuat!")

	return {
		donateBtn         = icon,
		mainframe         = main,
		MessageFrame      = msg,
		notificationframe = notif,
		container         = main:WaitForChild("Container"),
		templateframe     = main:WaitForChild("Container"):WaitForChild("TemplateFrame"),
	}
end

return GUIBuilder

-- ========================================
