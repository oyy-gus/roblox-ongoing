local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService  = game:GetService("UserInputService")
local RunService        = game:GetService("RunService")
local Modules           = ReplicatedStorage:WaitForChild("Modules")

local MenuConfig        = require(Modules:WaitForChild("MenuConfig"))
local ThemeModule       = require(Modules:WaitForChild("ThemeModule"))
local BugReportConfig   = require(Modules:WaitForChild("BugReportConfig"))

local guiReady = MenuConfig.WaitForGUIReady(15)
if not guiReady then
	warn("❌ ReportBugClient: GUI belum siap!")
	return
end

local reportPage = MenuConfig.GUI.ReportPage
	or MenuConfig.GUI.BugPage
	or MenuConfig.GUI.KreditPage

if not reportPage then
	warn("❌ ReportBugClient: Halaman tidak ditemukan!")
	return
end

print("✅ reportPage ditemukan:", reportPage:GetFullName())
print("✅ Ukuran reportPage:", reportPage.AbsoluteSize)

local Players      = MenuConfig.Services.Players
local TweenService = MenuConfig.Services.TweenService
local player       = Players.LocalPlayer

print("⏳ Menunggu RemoteEvent...")

local remoteFolder = ReplicatedStorage:WaitForChild("Remotes", 30)
if not remoteFolder then
	warn("❌ Folder 'Remotes' tidak ditemukan!")
	return
end

local bugRemote = remoteFolder:WaitForChild(BugReportConfig.RemoteName, 30)
if not bugRemote then
	warn("❌ RemoteEvent tidak ditemukan! Name:", BugReportConfig.RemoteName)
	return
end

print("✅ RemoteEvent:", bugRemote:GetFullName())

local State = {
	selectedCategory = nil,
	selectedSeverity = nil,
	isSubmitting     = false,
	cooldownUntil    = 0,
}

local SIZES = {
	CORNER_SM  = 6,
	CORNER_MD  = 8,
	CORNER_LG  = 10,
	SPACING    = 8,
	PAD        = 10,
	LABEL_H    = 20,
	INPUT_H    = 36,
	TEXTAREA_H = 90,
	CHIP_H     = 28,
	CHIP_W     = 118,
	BOTTOM_H   = 54,
}

local COLORS = {
	BG          = Color3.fromRGB(30, 30, 40),
	PANEL       = Color3.fromRGB(40, 40, 55),
	PANEL2      = Color3.fromRGB(35, 35, 50),
	INPUT_BG    = Color3.fromRGB(25, 25, 35),
	ACCENT      = Color3.fromRGB(255, 215, 0),
	TEXT        = Color3.fromRGB(255, 255, 255),
	TEXT_DIM    = Color3.fromRGB(150, 150, 165),
	TEXT_HINT   = Color3.fromRGB(100, 100, 115),
	SUCCESS     = Color3.fromRGB(60, 200, 100),
	ERROR       = Color3.fromRGB(220, 80, 80),
	WARNING     = Color3.fromRGB(255, 170, 50),
	CHIP_NORMAL = Color3.fromRGB(45, 45, 62),
	CHIP_SEL    = Color3.fromRGB(60, 55, 30),
	SUBMIT      = Color3.fromRGB(50, 130, 220),
	SUBMIT_HOV  = Color3.fromRGB(70, 150, 240),
	BOTTOM_BG   = Color3.fromRGB(28, 28, 40),
}

local function mk(cls, props, parent)
	local inst = Instance.new(cls)
	for k, v in pairs(props) do inst[k] = v end
	if inst:IsA("GuiObject") and not inst:IsA("UIComponent") and props.Active == nil then
		inst.Active = true
	end
	if parent then inst.Parent = parent end
	return inst
end

local function crn(r, f)
	mk("UICorner", { CornerRadius = UDim.new(0, r) }, f)
end

local function tw(inst, props, dur, style, dir)
	TweenService:Create(inst,
		TweenInfo.new(
			dur   or 0.2,
			style or Enum.EasingStyle.Quad,
			dir   or Enum.EasingDirection.Out
		), props
	):Play()
end

local function addGradient(label, animated, speed)
	if ThemeModule then
		if animated then
			return ThemeModule.CreatePrimaryGradient(label, 0, speed or 1.5)
		else
			return ThemeModule.CreateStaticGradient(label, "Primary", 0)
		end
	end
end

local function addStroke(parent, thickness, color, transparency)
	return mk("UIStroke", {
		Thickness       = thickness or 1,
		Color           = color or Color3.fromRGB(80, 80, 100),
		Transparency    = transparency or 0,
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
	}, parent)
end

local function isMouseOverFrame(frame)
	if not frame or not frame.Parent then return false end

	if not frame.Visible then return false end

	local ok, absPos  = pcall(function() return frame.AbsolutePosition end)
	local ok2, absSize = pcall(function() return frame.AbsoluteSize end)
	if not ok or not ok2 then return false end

	if absSize.X <= 0 or absSize.Y <= 0 then return false end

	local mPos = UserInputService:GetMouseLocation()

	local result = mPos.X >= absPos.X
		and mPos.X <= absPos.X + absSize.X
		and mPos.Y >= absPos.Y
		and mPos.Y <= absPos.Y + absSize.Y

	return result
end

if ThemeModule and ThemeModule.GradientSystem then
	ThemeModule.GradientSystem.Start()
end

local BOTTOM_H   = SIZES.BOTTOM_H
local BTN_MARGIN = 10
local SUBMIT_W   = 185
local RESET_W    = 115
local BTN_H      = BOTTOM_H - (BTN_MARGIN * 2)

local bottomBar = mk("Frame", {
	Name             = "BottomBar",
	Size             = UDim2.new(1, 0, 0, BOTTOM_H),
	AnchorPoint      = Vector2.new(0, 1),
	Position         = UDim2.new(0, 0, 1, 0),
	BackgroundColor3 = COLORS.BOTTOM_BG,
	BorderSizePixel  = 0,
	ZIndex           = 100,
	ClipsDescendants = false,
}, reportPage)

mk("Frame", {
	Name             = "Separator",
	Size             = UDim2.new(1, 0, 0, 1),
	Position         = UDim2.new(0, 0, 0, 0),
	BackgroundColor3 = Color3.fromRGB(60, 60, 80),
	BorderSizePixel  = 0,
	ZIndex           = 101,
}, bottomBar)

local submitBtn = mk("TextButton", {
	Name             = "SubmitBtn",
	Size             = UDim2.new(0, SUBMIT_W, 0, BTN_H),
	Position         = UDim2.new(0, BTN_MARGIN, 0, BTN_MARGIN),
	BackgroundColor3 = COLORS.SUBMIT,
	BorderSizePixel  = 0,
	Text             = "📤 Kirim Laporan Bug",
	TextColor3       = Color3.fromRGB(255, 255, 255),
	TextSize         = 13,
	Font             = Enum.Font.GothamBold,
	AutoButtonColor  = false,
	ZIndex           = 102,
}, bottomBar)
crn(SIZES.CORNER_SM, submitBtn)
addStroke(submitBtn, 1.5, Color3.fromRGB(30, 100, 190), 0)

local submitLabel = submitBtn
local submitFrame = submitBtn

local resetBtn = mk("TextButton", {
	Name             = "ResetBtn",
	Size             = UDim2.new(0, RESET_W, 0, BTN_H),
	Position         = UDim2.new(1, -(RESET_W + BTN_MARGIN), 0, BTN_MARGIN),
	BackgroundColor3 = COLORS.PANEL2,
	BorderSizePixel  = 0,
	Text             = "🔄 Reset Form",
	TextColor3       = COLORS.TEXT_DIM,
	TextSize         = 12,
	Font             = Enum.Font.GothamSemibold,
	AutoButtonColor  = false,
	ZIndex           = 102,
}, bottomBar)
crn(SIZES.CORNER_SM, resetBtn)
addStroke(resetBtn, 1.5, Color3.fromRGB(70, 70, 90), 0)

local resetLabel = resetBtn
local resetFrame = resetBtn

local cooldownLabel = mk("TextLabel", {
	Size                   = UDim2.new(
		1, -(SUBMIT_W + RESET_W + BTN_MARGIN * 4),
		0, BTN_H
	),
	Position               = UDim2.new(
		0, SUBMIT_W + BTN_MARGIN * 2,
		0, BTN_MARGIN
	),
	BackgroundTransparency = 1,
	Text                   = "",
	TextColor3             = COLORS.TEXT_HINT,
	TextSize               = 10,
	Font                   = Enum.Font.Gotham,
	TextXAlignment         = Enum.TextXAlignment.Center,
	TextYAlignment         = Enum.TextYAlignment.Center,
	ZIndex                 = 102,
}, bottomBar)

local rootScroll = mk("ScrollingFrame", {
	Name                       = "BugReportScroll",
	Size                       = UDim2.new(1, 0, 1, -BOTTOM_H),
	Position                   = UDim2.new(0, 0, 0, 0),
	BackgroundColor3           = COLORS.BG,
	BorderSizePixel            = 0,
	ScrollBarThickness         = 0,
	ScrollBarImageTransparency = 1,
	ScrollingEnabled           = true,
	CanvasSize                 = UDim2.new(0, 0, 0, 0),
	AutomaticCanvasSize        = Enum.AutomaticSize.Y,
	ClipsDescendants           = true,
	ScrollingDirection         = Enum.ScrollingDirection.Y,
	VerticalScrollBarInset     = Enum.ScrollBarInset.None,
	ElasticBehavior            = Enum.ElasticBehavior.WhenScrollable,
	ZIndex                     = 5,
}, reportPage)
crn(SIZES.CORNER_MD, rootScroll)

mk("UIListLayout", {
	SortOrder           = Enum.SortOrder.LayoutOrder,
	Padding             = UDim.new(0, SIZES.SPACING),
	HorizontalAlignment = Enum.HorizontalAlignment.Center,
}, rootScroll)

mk("UIPadding", {
	PaddingTop    = UDim.new(0, 10),
	PaddingBottom = UDim.new(0, 14),
	PaddingLeft   = UDim.new(0, 10),
	PaddingRight  = UDim.new(0, 10),
}, rootScroll)

local notifBanner = mk("Frame", {
	Name             = "NotifBanner",
	Size             = UDim2.new(1, 0, 0, 0),
	BackgroundColor3 = COLORS.SUCCESS,
	BorderSizePixel  = 0,
	ClipsDescendants = true,
	LayoutOrder      = 0,
	Visible          = false,
	ZIndex           = 6,
}, rootScroll)
crn(SIZES.CORNER_SM, notifBanner)

local notifLabel = mk("TextLabel", {
	Size                   = UDim2.new(1, -20, 1, 0),
	Position               = UDim2.new(0, 10, 0, 0),
	BackgroundTransparency = 1,
	Text                   = "",
	TextColor3             = Color3.fromRGB(255, 255, 255),
	TextSize               = 12,
	Font                   = Enum.Font.GothamBold,
	TextXAlignment         = Enum.TextXAlignment.Left,
	TextWrapped            = true,
	ZIndex                 = 7,
}, notifBanner)

local function showNotif(message, isSuccess, duration)
	print("🔔 showNotif:", message, "| success:", isSuccess)
	notifBanner.BackgroundColor3 = isSuccess and COLORS.SUCCESS or COLORS.ERROR
	notifLabel.Text  = message
	notifBanner.Visible = true
	tw(notifBanner,
		{ Size = UDim2.new(1, 0, 0, 40) }, 0.3,
		Enum.EasingStyle.Back, Enum.EasingDirection.Out
	)
	task.delay(duration or 4, function()
		if notifBanner and notifBanner.Parent then
			tw(notifBanner, { Size = UDim2.new(1, 0, 0, 0) }, 0.25)
			task.delay(0.3, function()
				if notifBanner and notifBanner.Parent then
					notifBanner.Visible = false
				end
			end)
		end
	end)
end

local function makeSection(title, layoutOrder, contentHeight)
	local totalH = 26 + SIZES.PAD + contentHeight + SIZES.PAD

	local frame = mk("Frame", {
		Name             = "Section_" .. tostring(layoutOrder),
		Size             = UDim2.new(1, 0, 0, totalH),
		BackgroundColor3 = COLORS.PANEL,
		BorderSizePixel  = 0,
		LayoutOrder      = layoutOrder,
		ZIndex           = 6,
	}, rootScroll)
	crn(SIZES.CORNER_LG, frame)
	addStroke(frame, 1, Color3.fromRGB(70, 70, 90), 0)

	local titleLabel = mk("TextLabel", {
		Name                   = "SectionTitle",
		Size                   = UDim2.new(1, -20, 0, 26),
		Position               = UDim2.new(0, 10, 0, 0),
		BackgroundTransparency = 1,
		Text                   = title,
		TextColor3             = COLORS.TEXT,
		TextSize               = 12,
		Font                   = Enum.Font.GothamBold,
		TextXAlignment         = Enum.TextXAlignment.Left,
		TextYAlignment         = Enum.TextYAlignment.Center,
		ZIndex                 = 7,
	}, frame)
	addGradient(titleLabel, true, 1.0)

	mk("Frame", {
		Name             = "Divider",
		Size             = UDim2.new(1, -20, 0, 1),
		Position         = UDim2.new(0, 10, 0, 26),
		BackgroundColor3 = Color3.fromRGB(60, 60, 80),
		BorderSizePixel  = 0,
		ZIndex           = 7,
	}, frame)

	local content = mk("Frame", {
		Name                   = "Content",
		Size                   = UDim2.new(1, -20, 0, contentHeight),
		Position               = UDim2.new(0, 10, 0, 26 + SIZES.PAD),
		BackgroundTransparency = 1,
		ZIndex                 = 7,
	}, frame)

	return frame, content
end

local function makeLabel(parent, text, yPos)
	return mk("TextLabel", {
		Size                   = UDim2.new(1, 0, 0, SIZES.LABEL_H),
		Position               = UDim2.new(0, 0, 0, yPos),
		BackgroundTransparency = 1,
		Text                   = text,
		TextColor3             = COLORS.TEXT_DIM,
		TextSize               = 11,
		Font                   = Enum.Font.GothamSemibold,
		TextXAlignment         = Enum.TextXAlignment.Left,
		TextYAlignment         = Enum.TextYAlignment.Center,
		ZIndex                 = 8,
	}, parent)
end

local function makeInput(parent, placeholder, yPos, height, multiline)
	local bg = mk("Frame", {
		Size             = UDim2.new(1, 0, 0, height or SIZES.INPUT_H),
		Position         = UDim2.new(0, 0, 0, yPos),
		BackgroundColor3 = COLORS.INPUT_BG,
		BorderSizePixel  = 0,
		ZIndex           = 8,
	}, parent)
	crn(SIZES.CORNER_SM, bg)
	local stroke = addStroke(bg, 1, Color3.fromRGB(65, 65, 85), 0)

	local inputBox = mk("TextBox", {
		Size              = UDim2.new(1, -16, 1, -8),
		Position          = UDim2.new(0, 8, 0, 4),
		BackgroundTransparency = 1,
		Text              = "",
		PlaceholderText   = placeholder or "",
		TextColor3        = COLORS.TEXT,
		PlaceholderColor3 = COLORS.TEXT_HINT,
		TextSize          = 12,
		Font              = Enum.Font.Gotham,
		TextXAlignment    = Enum.TextXAlignment.Left,
		TextYAlignment    = multiline
			and Enum.TextYAlignment.Top
			or  Enum.TextYAlignment.Center,
		MultiLine         = multiline or false,
		TextWrapped       = multiline or false,
		ClearTextOnFocus  = false,
		ZIndex            = 9,
	}, bg)

	inputBox.Focused:Connect(function()
		tw(stroke, { Color = COLORS.ACCENT }, 0.2)
		tw(bg, { BackgroundColor3 = Color3.fromRGB(30, 30, 45) }, 0.2)
	end)
	inputBox.FocusLost:Connect(function()
		tw(stroke, { Color = Color3.fromRGB(65, 65, 85) }, 0.2)
		tw(bg, { BackgroundColor3 = COLORS.INPUT_BG }, 0.2)
	end)

	return inputBox, bg
end

local function makeCharCounter(parent, inputBox, maxLen, yPos)
	local counter = mk("TextLabel", {
		Size                   = UDim2.new(1, 0, 0, 14),
		Position               = UDim2.new(0, 0, 0, yPos),
		BackgroundTransparency = 1,
		Text                   = "0 / " .. maxLen,
		TextColor3             = COLORS.TEXT_HINT,
		TextSize               = 10,
		Font                   = Enum.Font.Gotham,
		TextXAlignment         = Enum.TextXAlignment.Right,
		ZIndex                 = 8,
	}, parent)

	inputBox:GetPropertyChangedSignal("Text"):Connect(function()
		local len = #inputBox.Text
		counter.Text = len .. " / " .. maxLen
		counter.TextColor3 = len > maxLen * 0.9 and COLORS.ERROR
			or len > maxLen * 0.7 and COLORS.WARNING
			or COLORS.TEXT_HINT
	end)

	return counter
end

local function makeChipGroup(parent, items, groupName, onSelect)
	local chips = {}

	local wrapFrame = mk("Frame", {
		Name                   = "ChipGroup_" .. groupName,
		Size                   = UDim2.new(1, 0, 1, 0),
		BackgroundTransparency = 1,
		ZIndex                 = 8,
	}, parent)

	mk("UIGridLayout", {
		CellSize            = UDim2.new(0, SIZES.CHIP_W, 0, SIZES.CHIP_H),
		CellPadding         = UDim2.new(0, 6, 0, 6),
		SortOrder           = Enum.SortOrder.LayoutOrder,
		HorizontalAlignment = Enum.HorizontalAlignment.Left,
	}, wrapFrame)

	for i, item in ipairs(items) do

		local chip = mk("TextButton", {
			Name             = "Chip_" .. item.id,
			BackgroundColor3 = COLORS.CHIP_NORMAL,
			BorderSizePixel  = 0,
			LayoutOrder      = i,
			Text             = "",
			AutoButtonColor  = false,
			ZIndex           = 9,
		}, wrapFrame)
		crn(SIZES.CHIP_H / 2, chip)
		local chipStroke = addStroke(chip, 1, Color3.fromRGB(70, 70, 90), 0)

		mk("TextLabel", {
			Name                   = "ChipLabel",
			Size                   = UDim2.new(1, -8, 1, 0),
			Position               = UDim2.new(0, 4, 0, 0),
			BackgroundTransparency = 1,
			Text                   = item.label,
			TextColor3             = COLORS.TEXT_DIM,
			TextSize               = 10,
			Font                   = Enum.Font.GothamSemibold,
			TextTruncate           = Enum.TextTruncate.AtEnd,
			TextXAlignment         = Enum.TextXAlignment.Center,
			ZIndex                 = 10,
		}, chip)

		chips[item.id] = { frame = chip, stroke = chipStroke }

		local function setSelected(sel)
			local lbl = chip:FindFirstChild("ChipLabel")
			if sel then
				tw(chip,       { BackgroundColor3 = COLORS.CHIP_SEL }, 0.15)
				tw(chipStroke, { Color = COLORS.ACCENT }, 0.15)
				if lbl then
					lbl.TextColor3 = COLORS.ACCENT
					lbl.Font       = Enum.Font.GothamBold
				end
			else
				tw(chip,       { BackgroundColor3 = COLORS.CHIP_NORMAL }, 0.15)
				tw(chipStroke, { Color = Color3.fromRGB(70, 70, 90) }, 0.15)
				if lbl then
					lbl.TextColor3 = COLORS.TEXT_DIM
					lbl.Font       = Enum.Font.GothamSemibold
				end
			end
		end

		chips[item.id].setSelected = setSelected

		chip.MouseButton1Click:Connect(function()
			for id, c in pairs(chips) do
				c.setSelected(false)
			end
			setSelected(true)
			onSelect(item.id)
		end)

		chip.MouseEnter:Connect(function()
			local isSel = (groupName == "category" and State.selectedCategory == item.id)
				or (groupName == "severity" and State.selectedSeverity == item.id)
			if not isSel then
				tw(chip, { BackgroundColor3 = Color3.fromRGB(55, 55, 72) }, 0.1)
			end
		end)

		chip.MouseLeave:Connect(function()
			local isSel = (groupName == "category" and State.selectedCategory == item.id)
				or (groupName == "severity" and State.selectedSeverity == item.id)
			if not isSel then
				tw(chip, { BackgroundColor3 = COLORS.CHIP_NORMAL }, 0.1)
			end
		end)
	end

	return wrapFrame, chips
end

local _, headerContent = makeSection("📋 Laporan Bug", 1, 52)
mk("TextLabel", {
	Size                   = UDim2.new(1, 0, 0, 34),
	BackgroundTransparency = 1,
	Text                   = "Temukan bug? Bantu kami memperbaikinya!\nIsi form dan laporan akan dikirim ke tim developer.",
	TextColor3             = COLORS.TEXT_DIM,
	TextSize               = 11,
	Font                   = Enum.Font.Gotham,
	TextXAlignment         = Enum.TextXAlignment.Left,
	TextWrapped            = true,
	ZIndex                 = 8,
}, headerContent)

local playerBadge = mk("Frame", {
	Size             = UDim2.new(1, 0, 0, 22),
	Position         = UDim2.new(0, 0, 0, 36),
	BackgroundColor3 = COLORS.PANEL2,
	BorderSizePixel  = 0,
	ZIndex           = 8,
}, headerContent)
crn(SIZES.CORNER_SM, playerBadge)
mk("TextLabel", {
	Size                   = UDim2.new(1, -12, 1, 0),
	Position               = UDim2.new(0, 6, 0, 0),
	BackgroundTransparency = 1,
	Text                   = string.format(
		"👤  %s  (@%s)  |  ID: %d",
		player.DisplayName, player.Name, player.UserId
	),
	TextColor3             = COLORS.TEXT_DIM,
	TextSize               = 10,
	Font                   = Enum.Font.Gotham,
	TextXAlignment         = Enum.TextXAlignment.Left,
	TextYAlignment         = Enum.TextYAlignment.Center,
	ZIndex                 = 9,
}, playerBadge)

local _, titleContent = makeSection("📌 Judul Bug", 2,
	SIZES.LABEL_H + 4 + SIZES.INPUT_H + 4 + 14)
makeLabel(titleContent, "Deskripsikan bug secara singkat  *", 0)
local titleInput = makeInput(titleContent,
	"Contoh: NPC tidak bisa bergerak di area spawn...",
	SIZES.LABEL_H + 4, SIZES.INPUT_H, false)
makeCharCounter(titleContent, titleInput,
	BugReportConfig.Validation.TitleMaxLength,
	SIZES.LABEL_H + 4 + SIZES.INPUT_H + 2)

local catRows = math.ceil(#BugReportConfig.Categories / 3)
local catH    = catRows * SIZES.CHIP_H + (catRows - 1) * 6
local _, catContent = makeSection("📂 Kategori  *", 3,
	SIZES.LABEL_H + 4 + catH + 4)
makeLabel(catContent, "Pilih kategori bug yang paling sesuai", 0)
local catWrap = mk("Frame", {
	Size                   = UDim2.new(1, 0, 0, catH + 4),
	Position               = UDim2.new(0, 0, 0, SIZES.LABEL_H + 4),
	BackgroundTransparency = 1,
	ZIndex                 = 8,
}, catContent)
makeChipGroup(catWrap, BugReportConfig.Categories, "category", function(id)
	State.selectedCategory = id
	print("📂 Category selected:", id)
end)

local sevRows = math.ceil(#BugReportConfig.Severities / 3)
local sevH    = sevRows * SIZES.CHIP_H + (sevRows - 1) * 6
local _, sevContent = makeSection("⚡ Tingkat Keparahan  *", 4,
	SIZES.LABEL_H + 4 + sevH + 4)
makeLabel(sevContent, "Seberapa parah bug ini mempengaruhi game?", 0)
local sevWrap = mk("Frame", {
	Size                   = UDim2.new(1, 0, 0, sevH + 4),
	Position               = UDim2.new(0, 0, 0, SIZES.LABEL_H + 4),
	BackgroundTransparency = 1,
	ZIndex                 = 8,
}, sevContent)
makeChipGroup(sevWrap, BugReportConfig.Severities, "severity", function(id)
	State.selectedSeverity = id
	print("⚡ Severity selected:", id)
end)

local _, descContent = makeSection("📝 Deskripsi Bug  *", 5,
	SIZES.LABEL_H + 4 + SIZES.TEXTAREA_H + 4 + 14)
makeLabel(descContent, "Jelaskan bug yang kamu temukan secara detail", 0)
local descInput = makeInput(descContent,
	"Ceritakan apa yang terjadi, kapan terjadi, dan dampaknya...",
	SIZES.LABEL_H + 4, SIZES.TEXTAREA_H, true)
makeCharCounter(descContent, descInput,
	BugReportConfig.Validation.DescMaxLength,
	SIZES.LABEL_H + 4 + SIZES.TEXTAREA_H + 2)

local stepsH = SIZES.TEXTAREA_H - 20
local _, stepsContent = makeSection("🔁 Langkah Reproduksi  (Opsional)", 6,
	SIZES.LABEL_H + 4 + stepsH + 4 + 14)
makeLabel(stepsContent, "Langkah untuk mereproduksi bug (opsional)", 0)
local stepsInput = makeInput(stepsContent,
	"1. Buka menu...\n2. Klik tombol...\n3. Bug terjadi...",
	SIZES.LABEL_H + 4, stepsH, true)
makeCharCounter(stepsContent, stepsInput,
	BugReportConfig.Validation.StepsMaxLength,
	SIZES.LABEL_H + 4 + stepsH + 2)

local function setSubmitState(loading)
	State.isSubmitting = loading
	if loading then
		submitBtn.Text             = "⏳ Mengirim..."
		submitBtn.BackgroundColor3 = Color3.fromRGB(40, 100, 170)
		submitBtn.Active           = false
	else
		submitBtn.Text             = "📤 Kirim Laporan Bug"
		submitBtn.BackgroundColor3 = COLORS.SUBMIT
		submitBtn.Active           = true
	end
end

local function validateForm()
	local title = titleInput.Text:match("^%s*(.-)%s*$") or ""
	local desc  = descInput.Text:match("^%s*(.-)%s*$") or ""
	local val   = BugReportConfig.Validation

	print("🔍 Validating form...")
	print("  title len:", #title)
	print("  desc len:", #desc)
	print("  category:", State.selectedCategory)
	print("  severity:", State.selectedSeverity)

	if #title < val.TitleMinLength then
		return false, string.format("Judul minimal %d karakter!", val.TitleMinLength)
	end
	if #title > val.TitleMaxLength then
		return false, string.format("Judul maksimal %d karakter!", val.TitleMaxLength)
	end
	if not State.selectedCategory then
		return false, "Pilih kategori bug terlebih dahulu!"
	end
	if not State.selectedSeverity then
		return false, "Pilih tingkat keparahan bug!"
	end
	if #desc < val.DescMinLength then
		return false, string.format("Deskripsi minimal %d karakter!", val.DescMinLength)
	end
	if #desc > val.DescMaxLength then
		return false, string.format("Deskripsi maksimal %d karakter!", val.DescMaxLength)
	end

	print("  ✅ Form valid!")
	return true, nil
end

local function resetForm()
	titleInput.Text        = ""
	descInput.Text         = ""
	stepsInput.Text        = ""
	State.selectedCategory = nil
	State.selectedSeverity = nil

	for _, desc in ipairs({
		{rootScroll, "Chip_"},
		}) do
		for _, frame in ipairs(desc[1]:GetDescendants()) do
			if frame:IsA("TextButton") and frame.Name:sub(1, 5) == "Chip_" then
				local lbl    = frame:FindFirstChild("ChipLabel")
				local stroke = frame:FindFirstChildOfClass("UIStroke")
				frame.BackgroundColor3 = COLORS.CHIP_NORMAL
				if stroke then stroke.Color = Color3.fromRGB(70, 70, 90) end
				if lbl then
					lbl.TextColor3 = COLORS.TEXT_DIM
					lbl.Font       = Enum.Font.GothamSemibold
				end
			end
		end
	end

	showNotif("✅ Form berhasil direset!", true, 2)
end

local cooldownThread = nil
local function startCooldownDisplay(seconds)
	if cooldownThread then
		pcall(task.cancel, cooldownThread)
	end
	cooldownLabel.Visible = true
	cooldownThread = task.spawn(function()
		local rem = seconds
		while rem > 0 do
			cooldownLabel.Text = string.format("⏱️ Cooldown: %ds", rem)
			task.wait(1)
			rem -= 1
		end
		cooldownLabel.Text    = ""
		cooldownLabel.Visible = false
	end)
end

local function doSubmit()
	print("🚀 doSubmit() dipanggil!")

	if State.isSubmitting then
		print("⚠️ Sudah submitting, skip")
		return
	end

	local now = tick()
	if now < State.cooldownUntil then
		local rem = math.ceil(State.cooldownUntil - now)
		print("⏱️ Masih cooldown:", rem, "detik")
		showNotif(string.format("⏱️ Tunggu %d detik lagi!", rem), false, 3)
		return
	end

	local valid, errMsg = validateForm()
	if not valid then
		print("❌ Validasi gagal:", errMsg)
		showNotif("❌ " .. errMsg, false, 4)
		return
	end

	local reportData = {
		title       = titleInput.Text:match("^%s*(.-)%s*$") or "",
		description = descInput.Text:match("^%s*(.-)%s*$") or "",
		steps       = stepsInput.Text:match("^%s*(.-)%s*$") or "",
		category    = State.selectedCategory,
		severity    = State.selectedSeverity,
	}

	print("========================================")
	print("📤 FIRING SERVER EVENT")
	print("  Remote:", bugRemote:GetFullName())
	print("  Data:")
	print("    title:", reportData.title)
	print("    category:", reportData.category)
	print("    severity:", reportData.severity)
	print("    desc len:", #reportData.description)
	print("    steps len:", #reportData.steps)
	print("========================================")

	setSubmitState(true)

	local fireOk, fireErr = pcall(function()
		bugRemote:FireServer(reportData)
	end)

	if not fireOk then
		warn("❌ FireServer GAGAL:", fireErr)
		setSubmitState(false)
		showNotif("❌ Gagal kirim ke server!", false, 5)
		return
	end

	print("✅ FireServer berhasil dipanggil!")
	print("⏳ Menunggu response dari server...")

	task.delay(20, function()
		if State.isSubmitting then
			warn("⚠️ Timeout: server tidak merespons dalam 20 detik")
			setSubmitState(false)
			showNotif("⚠️ Server timeout. Coba lagi.", false, 5)
		end
	end)
end

submitBtn.MouseButton1Click:Connect(function()
	print("🖱️ Tombol kirim ditekan!")
	doSubmit()
end)

submitBtn.MouseEnter:Connect(function()
	if not State.isSubmitting then
		tw(submitBtn, { BackgroundColor3 = COLORS.SUBMIT_HOV }, 0.15)
	end
end)

submitBtn.MouseLeave:Connect(function()
	if not State.isSubmitting then
		tw(submitBtn, { BackgroundColor3 = COLORS.SUBMIT }, 0.15)
	end
end)

resetBtn.MouseButton1Click:Connect(function()
	print("🖱️ Tombol reset ditekan!")
	resetForm()
end)

resetBtn.MouseEnter:Connect(function()
	tw(resetBtn, { BackgroundColor3 = Color3.fromRGB(50, 50, 68) }, 0.15)
end)

resetBtn.MouseLeave:Connect(function()
	tw(resetBtn, { BackgroundColor3 = COLORS.PANEL2 }, 0.15)
end)

bugRemote.OnClientEvent:Connect(function(response)
	print("========================================")
	print("📨 RESPON DITERIMA DARI SERVER!")
	print("  tipe:", type(response))
	if type(response) == "table" then
		print("  sukses:", tostring(response.success))
		print("  pesan:", tostring(response.message))
	end
	print("========================================")

	setSubmitState(false)

	if type(response) ~= "table" then
		showNotif("❌ Response tidak valid dari server", false, 5)
		return
	end

	if response.success then
		titleInput.Text        = ""
		descInput.Text         = ""
		stepsInput.Text        = ""
		State.selectedCategory = nil
		State.selectedSeverity = nil
		State.cooldownUntil    = tick() + BugReportConfig.RateLimit.CooldownSeconds

		for _, frame in ipairs(rootScroll:GetDescendants()) do
			if frame:IsA("TextButton") and frame.Name:sub(1, 5) == "Chip_" then
				local lbl    = frame:FindFirstChild("ChipLabel")
				local stroke = frame:FindFirstChildOfClass("UIStroke")
				frame.BackgroundColor3 = COLORS.CHIP_NORMAL
				if stroke then stroke.Color = Color3.fromRGB(70, 70, 90) end
				if lbl then
					lbl.TextColor3 = COLORS.TEXT_DIM
					lbl.Font       = Enum.Font.GothamSemibold
				end
			end
		end

		startCooldownDisplay(BugReportConfig.RateLimit.CooldownSeconds)
		showNotif(response.message or "✅ Berhasil!", true, 5)
		rootScroll.CanvasPosition = Vector2.new(0, 0)
	else
		showNotif(response.message or "❌ Gagal.", false, 5)

		if response.message then
			local waitTime = response.message:match("(%d+) detik")
			if waitTime then
				local secs = tonumber(waitTime)
				if secs then
					State.cooldownUntil = tick() + secs
					startCooldownDisplay(secs)
				end
			end
		end
	end
end)

if MenuConfig.Events and MenuConfig.Events.OnMenuToggled then
	MenuConfig.Events.OnMenuToggled.Event:Connect(function(isOpen)
		if not isOpen then
			local focused = UserInputService:GetFocusedTextBox()
			if focused then focused:ReleaseFocus() end
		end
	end)
end

if MenuConfig.Events and MenuConfig.Events.OnTabChanged then
	MenuConfig.Events.OnTabChanged.Event:Connect(function(tab)
		if tab == "Report" or tab == "Bug" or tab == "Kredit" then
			rootScroll.CanvasPosition = Vector2.new(0, 0)
		end
	end)
end

print("========================================")
print("✅ ReportBugClient siap!")
print("📡 Remote:", bugRemote:GetFullName())
print("🔘 Kirim via MouseButton1Click")
print("========================================")
