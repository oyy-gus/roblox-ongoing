-- ========================================
-- PROFILE CLIENT (FINAL COMPLETE VERSION)
-- Place in: StarterGui > MenuGUI(ScreenGui) > ProfileClient(LocalScript)
-- ========================================

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local GuiService = game:GetService("GuiService")
local TextChatService = game:GetService("TextChatService")
local ContextActionService = game:GetService("ContextActionService")
local TweenService = game:GetService("TweenService")

local Modules     = ReplicatedStorage:WaitForChild("Modules")
local CarryModule = ReplicatedStorage:WaitForChild("ContextModule")
local MenuConfig  = require(Modules:WaitForChild("MenuConfig"))
local ThemeModule = require(Modules:WaitForChild("ThemeModule"))
local CarryConfig = require(CarryModule:WaitForChild("CarryConfig"))
local FriendConfig = require(Modules:WaitForChild("FriendConfig"))

local AutoScaleSystem = ReplicatedStorage:WaitForChild("AutoScaleSystem")
local ScaleSystem     = require(AutoScaleSystem:WaitForChild("ScaleSystem"))

local remotes     = ReplicatedStorage:WaitForChild("SyncRemotes")
local startSyncRE = remotes:WaitForChild("startSync")
local GiveRoleClient = require(
	ReplicatedStorage:WaitForChild("GiveModule"):WaitForChild("GiveRoleClient")
)

MenuConfig.WaitForGUIReady(15)

local screenGui   = MenuConfig.GUI and MenuConfig.GUI.ScreenGui
local localPlayer = Players.LocalPlayer
local camera      = workspace.CurrentCamera
local mainScaler  = (screenGui and screenGui:IsA("ScreenGui")) and ScaleSystem.new(screenGui) or nil

-- ========================================
-- CONSTANTS
-- ========================================
local RAYCAST_DISTANCE  = 500
local CLICK_ACTION_NAME = "PlayerMenuClick"
local MAX_DISTANCE      = 30
local CLICK_COOLDOWN    = 0.3

-- ========================================
-- BASE DIMENSIONS
-- ========================================
local BASE = {
	SHEET_WIDTH     = 350,
	SHEET_HEIGHT    = 400,
	CORNER_RADIUS   = 24,

	BUTTONS_AREA_H      = 440,
	BUTTONS_AREA_H_SELF = 440,

	BUTTON_HEIGHT     = 56,
	BUTTON_CORNER     = 14,
	BUTTON_SPACING    = 12,
	BUTTON_TEXT_SIZE  = 17,

	NAME_TEXT_SIZE     = 32,
	USERNAME_TEXT_SIZE = 20,
	STATS_TEXT_SIZE    = 18,

	PADDING           = 24,
	NAME_CONTAINER_H  = 90,
	NAME_SPACING      = 4,

	CLOSE_BTN_SIZE    = 32,
	CLOSE_BTN_MARGIN  = 10,
	CLOSE_TEXT_SIZE   = 14,
	CLOSE_CORNER      = 10,

	SCROLL_HINT_H     = 40,
	HINT_PILL_W       = 50,
	HINT_PILL_H       = 6,
	HINT_ARROW_SIZE   = 14,

	DIVIDER_MARGIN_TOP = 10,
	BUTTONS_MARGIN_TOP = 22,

	SCROLLBAR_THICKNESS = 5,
	BORDER_THICKNESS    = 2,
	SLIDE_OFFSET_Y      = 30,

	GIVE_FRAME_WIDTH  = 320,
	GIVE_FRAME_HEIGHT = 220,
	GIVE_CORNER       = 16,
	GIVE_BTN_HEIGHT   = 48,
	GIVE_BTN_CORNER   = 12,
	GIVE_TEXT_SIZE    = 16,
	GIVE_LABEL_SIZE   = 14,
}

-- ========================================
-- ANIMATION SETTINGS
-- ========================================
local ANIMATION_CONFIG = {
	OpenDuration  = 0.35,
	CloseDuration = 0.25,
	ScaleStart    = 0.85,
	ScaleEnd      = 1,
	OpenEaseStyle      = Enum.EasingStyle.Back,
	OpenEaseDirection  = Enum.EasingDirection.Out,
	CloseEaseStyle     = Enum.EasingStyle.Quart,
	CloseEaseDirection = Enum.EasingDirection.In,
}

-- ========================================
-- HIGHLIGHT SETTINGS
-- ========================================
local HIGHLIGHT_CONFIG = {
	OutlineColor        = Color3.fromRGB(255, 180, 80),
	OutlineTransparency = 0.2,
	FillColor           = Color3.fromRGB(255, 220, 150),
	FillTransparency    = 0.95,
	DepthMode           = Enum.HighlightDepthMode.Occluded,
	AnimatePulse        = true,
	PulseDuration       = 1.2,
	PulseMin            = 0.3,
	PulseMax            = 0.6,
}

-- ========================================
-- WARNA
-- ========================================
local C = {
	SheetBg         = Color3.fromRGB(26, 16, 20),
	AvatarBg        = Color3.fromRGB(17, 13, 16),
	ItemBg          = Color3.fromRGB(42, 21, 32),
	ItemBgHover     = Color3.fromRGB(55, 28, 42),
	ItemBgDisabled  = Color3.fromRGB(30, 18, 24),
	CloseBtn        = ThemeModule.Colors.CloseRed,
	CloseBtnHov     = ThemeModule.Colors.CloseRedHover,
	TextPrimary     = Color3.fromRGB(220, 235, 255),
	TextSecond      = Color3.fromRGB(180, 190, 200),
	TextMuted       = Color3.fromRGB(140, 150, 160),
	TextDisabled    = Color3.fromRGB(100, 100, 110),
	Divider         = Color3.fromRGB(76, 76, 113),
	SyncActive      = Color3.fromRGB(30, 100, 55),
	SyncDisabled    = Color3.fromRGB(55, 55, 60),
	ScrollBar       = Color3.fromRGB(76, 76, 113),
	GradientColor   = Color3.fromRGB(76, 76, 113),
	GiveOverlayBg   = Color3.fromRGB(20, 12, 16),
	GiveBtnActive   = Color3.fromRGB(85, 170, 255),
	GiveBtnDisabled = Color3.fromRGB(100, 100, 100),
	GiveCloseBg     = Color3.fromRGB(60, 30, 40),
}

-- ========================================
-- STATE VARIABLES
-- ========================================
local currentSheet     = nil
local isSheetOpen      = false
local isAnimating      = false
local currentTarget    = nil
local lastClickTime    = 0
local syncConnection   = nil
local friendTracker    = nil
local currentHighlight = nil
local highlightPulseThread = nil

local currentGiveFrame    = nil
local currentGiveBtn      = nil
local currentGiveLabel    = nil
local currentGiveCloseBtn = nil

-- ========================================
-- HELPER FUNCTIONS
-- ========================================
local function playClick()
	local s = ReplicatedStorage:FindFirstChild("Sounds")
	if s then
		local c = s:FindFirstChild("minimal-pop-click-ui")
		if c then c:Play() end
	end
end

local function isSyncingNow()
	if not localPlayer.Character then return false end
	local v = localPlayer.Character:GetAttribute("Syncing")
	return v and v ~= ""
end

local function isInRange(target, dist)
	local mc = localPlayer.Character
	local tc = target and target.Character
	if not mc or not tc then return false end
	local mh = mc:FindFirstChild("HumanoidRootPart")
	local th = tc:FindFirstChild("HumanoidRootPart")
	if not mh or not th then return false end
	return (mh.Position - th.Position).Magnitude <= dist
end

-- ========================================
-- HIGHLIGHT FUNCTIONS
-- ========================================
local function stopHighlightPulse()
	if highlightPulseThread then
		task.cancel(highlightPulseThread)
		highlightPulseThread = nil
	end
end

local function startHighlightPulse(highlight)
	stopHighlightPulse()
	if not HIGHLIGHT_CONFIG.AnimatePulse then return end
	highlightPulseThread = task.spawn(function()
		while highlight and highlight.Parent do
			TweenService:Create(highlight,
				TweenInfo.new(HIGHLIGHT_CONFIG.PulseDuration / 2, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut),
				{OutlineTransparency = HIGHLIGHT_CONFIG.PulseMin}
			):Play()
			task.wait(HIGHLIGHT_CONFIG.PulseDuration / 2)
			if not highlight or not highlight.Parent then break end
			TweenService:Create(highlight,
				TweenInfo.new(HIGHLIGHT_CONFIG.PulseDuration / 2, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut),
				{OutlineTransparency = HIGHLIGHT_CONFIG.PulseMax}
			):Play()
			task.wait(HIGHLIGHT_CONFIG.PulseDuration / 2)
		end
	end)
end

local function createCharacterHighlight(targetPlayer)
	if currentHighlight then
		stopHighlightPulse()
		currentHighlight:Destroy()
		currentHighlight = nil
	end
	if not targetPlayer or targetPlayer == localPlayer then return end
	local character = targetPlayer.Character
	if not character then return end

	local highlight = Instance.new("Highlight")
	highlight.Name = "ProfileHighlight_Local"
	highlight.Adornee = character
	highlight.DepthMode = HIGHLIGHT_CONFIG.DepthMode
	highlight.OutlineColor = HIGHLIGHT_CONFIG.OutlineColor
	highlight.OutlineTransparency = 1
	highlight.FillColor = HIGHLIGHT_CONFIG.FillColor
	highlight.FillTransparency = 1
	highlight.Parent = character
	currentHighlight = highlight

	TweenService:Create(highlight,
		TweenInfo.new(ANIMATION_CONFIG.OpenDuration, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{OutlineTransparency = HIGHLIGHT_CONFIG.OutlineTransparency, FillTransparency = HIGHLIGHT_CONFIG.FillTransparency}
	):Play()

	task.delay(ANIMATION_CONFIG.OpenDuration, function()
		if highlight and highlight.Parent then
			startHighlightPulse(highlight)
		end
	end)
end

local function removeCharacterHighlight(instant)
	if not currentHighlight then return end
	stopHighlightPulse()
	if instant then
		currentHighlight:Destroy()
		currentHighlight = nil
		return
	end
	local highlight = currentHighlight
	TweenService:Create(highlight,
		TweenInfo.new(ANIMATION_CONFIG.CloseDuration, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
		{OutlineTransparency = 1, FillTransparency = 1}
	):Play()
	task.delay(ANIMATION_CONFIG.CloseDuration + 0.05, function()
		if highlight and highlight.Parent then
			highlight:Destroy()
		end
	end)
	currentHighlight = nil
end

-- ========================================
-- CREATE GIVE ROLE OVERLAY
-- ========================================
local function createGiveRoleOverlay(parentCanvasGroup)
	local B = BASE

	local giveFrame = Instance.new("Frame")
	giveFrame.Name = "GiveRoleOverlay"
	giveFrame.AnchorPoint = Vector2.new(0.5, 0.5)
	giveFrame.Size = UDim2.new(1, 0, 1, 0)
	giveFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
	giveFrame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	giveFrame.BackgroundTransparency = 0.3
	giveFrame.BorderSizePixel = 0
	giveFrame.Visible = false
	giveFrame.ZIndex = 100
	giveFrame.Parent = parentCanvasGroup

	local innerPanel = Instance.new("Frame")
	innerPanel.Name = "InnerPanel"
	innerPanel.AnchorPoint = Vector2.new(0.5, 0.5)
	innerPanel.Size = UDim2.new(0, B.GIVE_FRAME_WIDTH, 0, B.GIVE_FRAME_HEIGHT)
	innerPanel.Position = UDim2.new(0.5, 0, 0.5, 0)
	innerPanel.BackgroundColor3 = C.GiveOverlayBg
	innerPanel.BorderSizePixel = 0
	innerPanel.ZIndex = 101
	innerPanel.Parent = giveFrame

	ThemeModule.CreateCorner(innerPanel, B.GIVE_CORNER)

	local innerStroke = Instance.new("UIStroke")
	innerStroke.Color = Color3.fromRGB(76, 76, 113)
	innerStroke.Thickness = 1
	innerStroke.Transparency = 0.5
	innerStroke.Parent = innerPanel

	local titleLabel = Instance.new("TextLabel")
	titleLabel.Name = "Title"
	titleLabel.Text = "🎁 Hadiah Gamepass"
	titleLabel.Size = UDim2.new(1, -20, 0, 30)
	titleLabel.Position = UDim2.new(0, 10, 0, 12)
	titleLabel.BackgroundTransparency = 1
	titleLabel.TextColor3 = C.TextPrimary
	titleLabel.TextSize = B.GIVE_TEXT_SIZE + 2
	titleLabel.Font = Enum.Font.GothamBold
	titleLabel.TextXAlignment = Enum.TextXAlignment.Center
	titleLabel.ZIndex = 102
	titleLabel.Parent = innerPanel

	local loadingText = Instance.new("TextLabel")
	loadingText.Name = "LoadingText"
	loadingText.Text = "Loading..."
	loadingText.Size = UDim2.new(1, -30, 0, 50)
	loadingText.Position = UDim2.new(0, 15, 0, 50)
	loadingText.BackgroundTransparency = 1
	loadingText.TextColor3 = Color3.fromRGB(255, 255, 255)
	loadingText.TextSize = B.GIVE_LABEL_SIZE
	loadingText.Font = Enum.Font.Gotham
	loadingText.TextXAlignment = Enum.TextXAlignment.Center
	loadingText.TextYAlignment = Enum.TextYAlignment.Center
	loadingText.TextWrapped = true
	loadingText.ZIndex = 102
	loadingText.Parent = innerPanel

	local roleBtn = Instance.new("TextButton")
	roleBtn.Name = "VIPButton"
	roleBtn.Text = "VIP - Loading..."
	roleBtn.Size = UDim2.new(1, -30, 0, B.GIVE_BTN_HEIGHT)
	roleBtn.Position = UDim2.new(0, 15, 0, 110)
	roleBtn.BackgroundColor3 = C.GiveBtnDisabled
	roleBtn.BorderSizePixel = 0
	roleBtn.TextColor3 = C.TextPrimary
	roleBtn.TextSize = B.GIVE_TEXT_SIZE
	roleBtn.Font = Enum.Font.GothamMedium
	roleBtn.Active = false
	roleBtn.AutoButtonColor = false
	roleBtn.ZIndex = 102
	roleBtn.Parent = innerPanel

	ThemeModule.CreateCorner(roleBtn, B.GIVE_BTN_CORNER)

	local closeOverlayBtn = Instance.new("TextButton")
	closeOverlayBtn.Name = "CloseOverlay"
	closeOverlayBtn.Text = "Tutup"
	closeOverlayBtn.Size = UDim2.new(1, -30, 0, 36)
	closeOverlayBtn.Position = UDim2.new(0, 15, 0, 168)
	closeOverlayBtn.BackgroundColor3 = C.GiveCloseBg
	closeOverlayBtn.BorderSizePixel = 0
	closeOverlayBtn.TextColor3 = C.TextMuted
	closeOverlayBtn.TextSize = B.GIVE_LABEL_SIZE
	closeOverlayBtn.Font = Enum.Font.GothamMedium
	closeOverlayBtn.AutoButtonColor = false
	closeOverlayBtn.ZIndex = 102
	closeOverlayBtn.Parent = innerPanel

	ThemeModule.CreateCorner(closeOverlayBtn, B.GIVE_BTN_CORNER)

	closeOverlayBtn.MouseEnter:Connect(function()
		TweenService:Create(closeOverlayBtn, TweenInfo.new(0.15),
			{BackgroundColor3 = Color3.fromRGB(80, 40, 55)}):Play()
	end)
	closeOverlayBtn.MouseLeave:Connect(function()
		TweenService:Create(closeOverlayBtn, TweenInfo.new(0.15),
			{BackgroundColor3 = C.GiveCloseBg}):Play()
	end)

	return giveFrame, roleBtn, loadingText, closeOverlayBtn
end

-- ========================================
-- CLOSE SHEET
-- ========================================
local function closeSheet(instant)
	if not currentSheet or not isSheetOpen then return end
	if isAnimating and not instant then return end

	isAnimating = true
	isSheetOpen = false

	GiveRoleClient:Reset()
	currentTarget = nil

	currentGiveFrame    = nil
	currentGiveBtn      = nil
	currentGiveLabel    = nil
	currentGiveCloseBtn = nil

	if friendTracker then
		friendTracker:Destroy()
		friendTracker = nil
	end

	removeCharacterHighlight(instant)

	local function destroy()
		if currentSheet then
			currentSheet:Destroy()
			currentSheet = nil
		end
		isAnimating = false
	end

	if instant then
		destroy()
		return
	end

	local pos = currentSheet.Position
	local closeTweenInfo = TweenInfo.new(
		ANIMATION_CONFIG.CloseDuration,
		ANIMATION_CONFIG.CloseEaseStyle,
		ANIMATION_CONFIG.CloseEaseDirection
	)

	TweenService:Create(currentSheet, closeTweenInfo, {
		Position = UDim2.new(pos.X.Scale, pos.X.Offset, pos.Y.Scale, pos.Y.Offset - BASE.SLIDE_OFFSET_Y)
	}):Play()
	TweenService:Create(currentSheet, closeTweenInfo, {GroupTransparency = 1}):Play()

	task.delay(ANIMATION_CONFIG.CloseDuration + 0.05, destroy)

	if MenuConfig.Events.OnProfileCardClosed then
		MenuConfig.Events.OnProfileCardClosed:Fire()
	end
end

-- ========================================
-- OPEN SHEET
-- ========================================
local function openSheet(player)
	if isSheetOpen then
		closeSheet(true)
		task.wait(0.05)
	end

	if not player or not player.Parent then return end
	if isAnimating then return end

	isAnimating  = true
	isSheetOpen  = true
	currentTarget = player

	local isSelf = (player == localPlayer)

	if MenuConfig.Events.OnProfileCardOpened then
		MenuConfig.Events.OnProfileCardOpened:Fire(player)
	end

	if not isSelf then
		createCharacterHighlight(player)
		friendTracker = FriendConfig.CreateTracker()
	end

	local B = BASE
	local sheetW      = B.SHEET_WIDTH
	local sheetH      = B.SHEET_HEIGHT
	local buttonsAreaH = isSelf and B.BUTTONS_AREA_H_SELF or B.BUTTONS_AREA_H

	-- =====================
	-- CANVAS GROUP
	-- =====================
	local canvasGroup = Instance.new("CanvasGroup")
	canvasGroup.Name = "ProfileSheet"
	canvasGroup.AnchorPoint = Vector2.new(0.5, 0.5)
	canvasGroup.Size = UDim2.new(0, sheetW, 0, sheetH)
	canvasGroup.Position = UDim2.new(0.5, 0, 0.5, -B.SLIDE_OFFSET_Y)
	canvasGroup.BackgroundColor3 = C.SheetBg
	canvasGroup.BackgroundTransparency = 0
	canvasGroup.BorderSizePixel = 0
	canvasGroup.GroupTransparency = 1
	canvasGroup.ZIndex = 50
	canvasGroup.Parent = screenGui
	currentSheet = canvasGroup

	ThemeModule.CreateCorner(canvasGroup, B.CORNER_RADIUS)

	local borderStroke, borderGradient = ThemeModule.CreateAnimatedStroke(
		canvasGroup, B.BORDER_THICKNESS, "Primary", 1
	)
	borderStroke.Transparency = 1

	local openTweenInfo = TweenInfo.new(
		ANIMATION_CONFIG.OpenDuration,
		ANIMATION_CONFIG.OpenEaseStyle,
		ANIMATION_CONFIG.OpenEaseDirection
	)
	local fadeInfo = TweenInfo.new(
		ANIMATION_CONFIG.OpenDuration * 0.7,
		Enum.EasingStyle.Quad,
		Enum.EasingDirection.Out
	)

	TweenService:Create(canvasGroup, openTweenInfo, {Position = UDim2.new(0.5, 0, 0.5, 0)}):Play()
	TweenService:Create(canvasGroup, fadeInfo, {GroupTransparency = 0}):Play()
	TweenService:Create(borderStroke, fadeInfo, {Transparency = 0.3}):Play()

	task.delay(ANIMATION_CONFIG.OpenDuration, function()
		isAnimating = false
	end)

	-- =====================
	-- SCROLL FRAME
	-- =====================
	local totalCanvas = sheetH + buttonsAreaH

	local scroll = Instance.new("ScrollingFrame")
	scroll.Name = "MainScroll"
	scroll.Size = UDim2.new(1, 0, 1, 0)
	scroll.Position = UDim2.new(0, 0, 0, 0)
	scroll.BackgroundTransparency = 1
	scroll.BorderSizePixel = 0
	scroll.ScrollBarThickness = B.SCROLLBAR_THICKNESS
	scroll.ScrollBarImageColor3 = C.ScrollBar
	scroll.ScrollBarImageTransparency = 0.5
	scroll.VerticalScrollBarInset = Enum.ScrollBarInset.ScrollBar
	scroll.ScrollingDirection = Enum.ScrollingDirection.Y
	scroll.ElasticBehavior = Enum.ElasticBehavior.Always
	scroll.CanvasSize = UDim2.new(0, 0, 0, totalCanvas)
	scroll.CanvasPosition = Vector2.new(0, 0)
	scroll.Active = true
	scroll.Parent = canvasGroup

	-- =====================
	-- AVATAR SECTION
	-- =====================
	local avatarSection = Instance.new("Frame")
	avatarSection.Name = "AvatarSection"
	avatarSection.Size = UDim2.new(1, 0, 0, sheetH)
	avatarSection.Position = UDim2.new(0, 0, 0, 0)
	avatarSection.BackgroundColor3 = C.AvatarBg
	avatarSection.BorderSizePixel = 0
	avatarSection.Parent = scroll

	local gradientFrame = Instance.new("Frame")
	gradientFrame.Size = UDim2.new(1, 0, 0.45, 0)
	gradientFrame.Position = UDim2.new(0, 0, 0.55, 0)
	gradientFrame.BackgroundColor3 = Color3.new(1, 1, 1)
	gradientFrame.BorderSizePixel = 0
	gradientFrame.ZIndex = 1
	gradientFrame.Parent = avatarSection

	local uiGrad = Instance.new("UIGradient")
	uiGrad.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, C.GradientColor),
		ColorSequenceKeypoint.new(1, C.SheetBg)
	})
	uiGrad.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 1),
		NumberSequenceKeypoint.new(0.6, 0.3),
		NumberSequenceKeypoint.new(1, 0),
	})
	uiGrad.Rotation = 90
	uiGrad.Parent = gradientFrame

	local avatarImg = Instance.new("ImageLabel")
	avatarImg.Name = "AvatarImage"
	avatarImg.AnchorPoint = Vector2.new(0.5, 0.5)
	avatarImg.Size = UDim2.new(1, 0, 1, 0)
	avatarImg.Position = UDim2.new(0.5, 0, 0.5, 0)
	avatarImg.BackgroundTransparency = 1
	avatarImg.ScaleType = Enum.ScaleType.Fit
	avatarImg.ZIndex = 2
	avatarImg.Parent = avatarSection

	-- =====================
	-- NAME CONTAINER
	-- =====================
	local nameContainer = Instance.new("Frame")
	nameContainer.Name = "NameContainer"
	nameContainer.Size = UDim2.new(1, -B.PADDING * 2, 0, B.NAME_CONTAINER_H)
	nameContainer.Position = UDim2.new(0, B.PADDING, 1, -B.NAME_CONTAINER_H - B.PADDING)
	nameContainer.BackgroundTransparency = 1
	nameContainer.ZIndex = 3
	nameContainer.Parent = avatarSection

	local nameLayout = Instance.new("UIListLayout")
	nameLayout.SortOrder = Enum.SortOrder.LayoutOrder
	nameLayout.Padding = UDim.new(0, B.NAME_SPACING)
	nameLayout.HorizontalAlignment = Enum.HorizontalAlignment.Left
	nameLayout.VerticalAlignment = Enum.VerticalAlignment.Bottom
	nameLayout.Parent = nameContainer

	local function createLabel(text, color, textSize, font, order)
		local label = Instance.new("TextLabel")
		label.Text = text
		label.Size = UDim2.new(1, 0, 0, textSize + math.floor(textSize * 0.3))
		label.BackgroundTransparency = 1
		label.TextColor3 = color
		label.TextSize = textSize
		label.Font = font or Enum.Font.Gotham
		label.TextXAlignment = Enum.TextXAlignment.Left
		label.LayoutOrder = order or 0
		label.TextTruncate = Enum.TextTruncate.AtEnd
		label.ZIndex = 3
		label.Parent = nameContainer
		return label
	end

	local displayNameText = FriendConfig.GetDisplayNameWithIndicator(player)
	local nameLabel = createLabel(displayNameText, C.TextPrimary, B.NAME_TEXT_SIZE, Enum.Font.GothamBold, 1)

	if friendTracker then
		friendTracker:SetNameLabel(nameLabel)
	end

	createLabel("@" .. player.Name, C.TextSecond, B.USERNAME_TEXT_SIZE, Enum.Font.Gotham, 2)

	local statsLabel = createLabel("⏳ Memuat...", C.TextMuted, B.STATS_TEXT_SIZE, Enum.Font.Gotham, 3)

	task.spawn(function()
		local friendCount, followerCount = 0, 0
		pcall(function() friendCount = FriendConfig.GetFriendCount(player.UserId) end)
		if statsLabel and statsLabel.Parent then
			statsLabel.Text = "Teman: " .. FriendConfig.FormatNumber(friendCount) .. "  ·  Pengikut: ⏳"
		end
		pcall(function() followerCount = FriendConfig.GetFollowerCount(player.UserId) end)
		if statsLabel and statsLabel.Parent then
			statsLabel.Text = "Teman: " .. FriendConfig.FormatNumber(friendCount) .. "  ·  Pengikut: " .. FriendConfig.FormatNumber(followerCount)
		end
	end)

	-- =====================
	-- SCROLL HINT
	-- =====================
	local scrollHint = Instance.new("Frame")
	scrollHint.Name = "ScrollHint"
	scrollHint.Size = UDim2.new(1, 0, 0, B.SCROLL_HINT_H)
	scrollHint.Position = UDim2.new(0, 0, 1, -B.SCROLL_HINT_H)
	scrollHint.BackgroundTransparency = 1
	scrollHint.ZIndex = 3
	scrollHint.Parent = avatarSection

	local hintPill = Instance.new("Frame")
	hintPill.AnchorPoint = Vector2.new(0.5, 0.5)
	hintPill.Size = UDim2.new(0, B.HINT_PILL_W, 0, B.HINT_PILL_H)
	hintPill.Position = UDim2.new(0.5, 0, 0.4, 0)
	hintPill.BackgroundColor3 = C.TextPrimary
	hintPill.BackgroundTransparency = 0.4
	hintPill.BorderSizePixel = 0
	hintPill.ZIndex = 3
	hintPill.Parent = scrollHint
	ThemeModule.CreateCorner(hintPill, 99)

	local hintArrow = Instance.new("TextLabel")
	hintArrow.AnchorPoint = Vector2.new(0.5, 0)
	hintArrow.Size = UDim2.new(0, B.HINT_ARROW_SIZE * 2, 0, B.HINT_ARROW_SIZE + 4)
	hintArrow.Position = UDim2.new(0.5, 0, 0.65, 0)
	hintArrow.BackgroundTransparency = 1
	hintArrow.Text = "▼"
	hintArrow.TextColor3 = C.TextMuted
	hintArrow.TextSize = B.HINT_ARROW_SIZE
	hintArrow.Font = Enum.Font.GothamBold
	hintArrow.ZIndex = 3
	hintArrow.Parent = scrollHint

	task.spawn(function()
		while hintPill and hintPill.Parent and isSheetOpen do
			TweenService:Create(hintPill, TweenInfo.new(0.5, Enum.EasingStyle.Sine), {BackgroundTransparency = 0.2}):Play()
			TweenService:Create(hintArrow, TweenInfo.new(0.5, Enum.EasingStyle.Sine), {Position = UDim2.new(0.5, 0, 0.7, 0)}):Play()
			task.wait(0.5)
			if not hintPill or not hintPill.Parent then break end
			TweenService:Create(hintPill, TweenInfo.new(0.5, Enum.EasingStyle.Sine), {BackgroundTransparency = 0.6}):Play()
			TweenService:Create(hintArrow, TweenInfo.new(0.5, Enum.EasingStyle.Sine), {Position = UDim2.new(0.5, 0, 0.65, 0)}):Play()
			task.wait(0.5)
		end
	end)

	task.spawn(function()
		local ok, img = pcall(function()
			return Players:GetUserThumbnailAsync(player.UserId, Enum.ThumbnailType.AvatarThumbnail, Enum.ThumbnailSize.Size420x420)
		end)
		if ok and avatarImg and avatarImg.Parent then
			avatarImg.Image = img
		end
	end)

	-- =====================
	-- BUTTON SECTION
	-- =====================
	local buttonSection = Instance.new("Frame")
	buttonSection.Name = "ButtonSection"
	buttonSection.Size = UDim2.new(1, 0, 0, buttonsAreaH)
	buttonSection.Position = UDim2.new(0, 0, 0, sheetH)
	buttonSection.BackgroundColor3 = C.SheetBg
	buttonSection.BorderSizePixel = 0
	buttonSection.Parent = scroll

	local divider = Instance.new("Frame")
	divider.Size = UDim2.new(1, -B.PADDING * 2, 0, 1)
	divider.Position = UDim2.new(0, B.PADDING, 0, B.DIVIDER_MARGIN_TOP)
	divider.BackgroundColor3 = C.Divider
	divider.BackgroundTransparency = 0.5
	divider.BorderSizePixel = 0
	divider.Parent = buttonSection

	local buttonContainer = Instance.new("Frame")
	buttonContainer.Name = "ButtonContainer"
	buttonContainer.Size = UDim2.new(1, -B.PADDING * 2, 1, -B.BUTTONS_MARGIN_TOP - B.PADDING)
	buttonContainer.Position = UDim2.new(0, B.PADDING, 0, B.BUTTONS_MARGIN_TOP)
	buttonContainer.BackgroundTransparency = 1
	buttonContainer.Parent = buttonSection

	local buttonLayout = Instance.new("UIListLayout")
	buttonLayout.SortOrder = Enum.SortOrder.LayoutOrder
	buttonLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	buttonLayout.Padding = UDim.new(0, B.BUTTON_SPACING)
	buttonLayout.Parent = buttonContainer

	-- =====================
	-- CREATE BUTTON HELPER
	-- =====================
	local function createButton(label, bgColor, order, onClick, isEnabled)
		if isEnabled == nil then isEnabled = true end
		local btn = Instance.new("TextButton")
		btn.Name = "Btn_" .. order
		btn.Text = label
		btn.Size = UDim2.new(1, 0, 0, B.BUTTON_HEIGHT)
		btn.BackgroundColor3 = isEnabled and bgColor or C.ItemBgDisabled
		btn.BorderSizePixel = 0
		btn.TextColor3 = isEnabled and C.TextPrimary or C.TextDisabled
		btn.TextSize = B.BUTTON_TEXT_SIZE
		btn.Font = Enum.Font.GothamMedium
		btn.LayoutOrder = order
		btn.AutoButtonColor = false
		btn.Active = isEnabled
		btn.TextTransparency = isEnabled and 0 or 0.5
		btn.Parent = buttonContainer
		ThemeModule.CreateCorner(btn, B.BUTTON_CORNER)

		if isEnabled then
			btn.MouseEnter:Connect(function()
				TweenService:Create(btn, TweenInfo.new(0.15), {BackgroundColor3 = C.ItemBgHover}):Play()
			end)
			btn.MouseLeave:Connect(function()
				TweenService:Create(btn, TweenInfo.new(0.15), {BackgroundColor3 = bgColor}):Play()
			end)
			btn.MouseButton1Click:Connect(function()
				playClick()
				onClick()
			end)
		end
		return btn
	end

	-- =====================
	-- FRIEND BUTTON
	-- =====================
	local function createFriendButton(order, targetPlayer, isEnabled)
		if isEnabled == nil then isEnabled = true end
		local initialStatus = FriendConfig.GetFriendStatus(targetPlayer)
		local config = FriendConfig.GetStatusConfig(initialStatus)

		local btn = Instance.new("TextButton")
		btn.Name = "Btn_Friend"
		btn.Text = config.text
		btn.Size = UDim2.new(1, 0, 0, B.BUTTON_HEIGHT)
		btn.BackgroundColor3 = isEnabled and config.color or C.ItemBgDisabled
		btn.BorderSizePixel = 0
		btn.TextColor3 = isEnabled and C.TextPrimary or C.TextDisabled
		btn.TextSize = B.BUTTON_TEXT_SIZE
		btn.Font = Enum.Font.GothamMedium
		btn.LayoutOrder = order
		btn.AutoButtonColor = false
		btn.Active = isEnabled and config.active
		btn.TextTransparency = (isEnabled and config.active) and 0 or 0.5
		btn.Parent = buttonContainer
		btn:SetAttribute("FriendAction", config.action)
		ThemeModule.CreateCorner(btn, B.BUTTON_CORNER)

		if isEnabled then
			btn.MouseEnter:Connect(function()
				if btn.Active then
					local hoverConfig = FriendConfig.GetStatusConfig(FriendConfig.GetFriendStatus(targetPlayer))
					TweenService:Create(btn, TweenInfo.new(0.15), {BackgroundColor3 = hoverConfig.hoverColor}):Play()
				end
			end)
			btn.MouseLeave:Connect(function()
				local normalConfig = FriendConfig.GetStatusConfig(FriendConfig.GetFriendStatus(targetPlayer))
				TweenService:Create(btn, TweenInfo.new(0.15), {BackgroundColor3 = normalConfig.color}):Play()
			end)
			btn.MouseButton1Click:Connect(function()
				if btn.Active and friendTracker then
					playClick()
					friendTracker:HandleAction(targetPlayer, btn:GetAttribute("FriendAction"))
				end
			end)
		end
		return btn
	end

	local buttonOrder = 1

	-- FRIEND BUTTON
	local friendBtn = createFriendButton(buttonOrder, player, not isSelf)
	buttonOrder += 1

	if friendTracker and not isSelf then
		friendTracker:StartPolling(friendBtn, player)
		friendTracker:SetOnStatusChanged(function(newStatus)
			if newStatus == Enum.FriendStatus.Friend and statsLabel and statsLabel.Parent then
				task.spawn(function()
					task.wait(1)
					local fc = FriendConfig.GetFriendCount(player.UserId)
					local fo = FriendConfig.GetFollowerCount(player.UserId)
					if statsLabel and statsLabel.Parent then
						statsLabel.Text = "Teman: " .. FriendConfig.FormatNumber(fc) .. "  ·  Pengikut: " .. FriendConfig.FormatNumber(fo)
					end
				end)
			end
		end)
	end

	-- SYNC BUTTON
	local syncBtn = createButton(
		isSyncingNow() and "✓ Sudah Sinkron" or "🎭 Tarian Koordinat",
		isSyncingNow() and C.SyncDisabled or C.SyncActive,
		buttonOrder,
		function()
			if isSyncingNow() or not currentTarget then return end
			startSyncRE:FireServer(currentTarget, true)
			closeSheet()
		end,
		not isSelf
	)
	if not isSelf then
		syncBtn.Active = not isSyncingNow()
		if syncConnection then syncConnection:Disconnect() end
		if localPlayer.Character then
			syncConnection = localPlayer.Character:GetAttributeChangedSignal("Syncing"):Connect(function()
				if isSyncingNow() then
					syncBtn.Text = "✓ Sudah Sinkron"
					syncBtn.BackgroundColor3 = C.SyncDisabled
					syncBtn.Active = false
				else
					syncBtn.Text = "🎭 Tarian Koordinat"
					syncBtn.BackgroundColor3 = C.SyncActive
					syncBtn.Active = true
				end
			end)
		end
	end
	buttonOrder += 1

	-- GENDONG BUTTON
	createButton("🤗 Gendong", C.ItemBg, buttonOrder, function()
		if not currentTarget then return end
		if not isInRange(currentTarget, CarryConfig.MAX_DISTANCE) then
			closeSheet()
			return
		end
		local ce = ReplicatedStorage:FindFirstChild("CarryEvents")
		if not ce then
			ce = Instance.new("Folder")
			ce.Name = "CarryEvents"
			ce.Parent = ReplicatedStorage
		end
		local sui = ce:FindFirstChild("ShowStyleUI")
		if not sui then
			sui = Instance.new("BindableEvent")
			sui.Name = "ShowStyleUI"
			sui.Parent = ce
		end
		pcall(function() sui:Fire(currentTarget) end)
		closeSheet()
	end, not isSelf)
	buttonOrder += 1

	-- =====================
	-- ✅ HADIAH GAMEPASS BUTTON (FINAL FIX)
	-- =====================
	if not isSelf then

		-- Buat overlay sekali saat sheet dibuka
		if not currentGiveFrame or not currentGiveFrame.Parent then
			local gFrame, gBtn, gLabel, gClose = createGiveRoleOverlay(canvasGroup)
			currentGiveFrame    = gFrame
			currentGiveBtn      = gBtn
			currentGiveLabel    = gLabel
			currentGiveCloseBtn = gClose

			GiveRoleClient:Initialize(
				currentGiveFrame,
				currentGiveBtn,
				currentGiveLabel,
				function()
					if currentGiveFrame then
						currentGiveFrame.Visible = false
					end
				end
			)

			if currentGiveCloseBtn then
				currentGiveCloseBtn.MouseButton1Click:Connect(function()
					playClick()
					GiveRoleClient:Reset()
				end)
			end
		end

		-- Buat tombol disabled dulu, sambil cek status VIP di background
		local hadiahBtn = Instance.new("TextButton")
		hadiahBtn.Name = "Btn_Hadiah"
		hadiahBtn.Text = "🎁 Memeriksa..."
		hadiahBtn.Size = UDim2.new(1, 0, 0, B.BUTTON_HEIGHT)
		hadiahBtn.BackgroundColor3 = C.ItemBgDisabled
		hadiahBtn.BorderSizePixel = 0
		hadiahBtn.TextColor3 = C.TextDisabled
		hadiahBtn.TextSize = B.BUTTON_TEXT_SIZE
		hadiahBtn.Font = Enum.Font.GothamMedium
		hadiahBtn.LayoutOrder = buttonOrder
		hadiahBtn.AutoButtonColor = false
		hadiahBtn.Active = false
		hadiahBtn.TextTransparency = 0.5
		hadiahBtn.Parent = buttonContainer
		ThemeModule.CreateCorner(hadiahBtn, B.BUTTON_CORNER)

		buttonOrder += 1

		-- Background check
		task.spawn(function()
			local targetRef = player

			GiveRoleClient:CheckPlayerRoleAsync(targetRef, function(roleInfo)

				-- Pastikan sheet masih terbuka dan tombol masih ada
				if not hadiahBtn or not hadiahBtn.Parent then return end
				if not isSheetOpen then return end

				if roleInfo and roleInfo.canReceive then
					-- ✅ BELUM VIP: aktifkan tombol
					hadiahBtn.Text = "🎁 Hadiah Gamepass"
					hadiahBtn.BackgroundColor3 = C.ItemBg
					hadiahBtn.TextColor3 = C.TextPrimary
					hadiahBtn.Active = true
					hadiahBtn.TextTransparency = 0

					hadiahBtn.MouseEnter:Connect(function()
						if hadiahBtn.Active then
							TweenService:Create(hadiahBtn, TweenInfo.new(0.15),
								{BackgroundColor3 = C.ItemBgHover}):Play()
						end
					end)
					hadiahBtn.MouseLeave:Connect(function()
						if hadiahBtn.Active then
							TweenService:Create(hadiahBtn, TweenInfo.new(0.15),
								{BackgroundColor3 = C.ItemBg}):Play()
						end
					end)
					hadiahBtn.MouseButton1Click:Connect(function()
						if not hadiahBtn.Active then return end
						playClick()
						GiveRoleClient:ShowOverlayForPlayer(targetRef)
					end)

				else
					-- ✅ SUDAH VIP: tetap disabled
					hadiahBtn.Text = "🎁 Sudah Memiliki VIP ✓"
					hadiahBtn.BackgroundColor3 = C.ItemBgDisabled
					hadiahBtn.TextColor3 = C.TextDisabled
					hadiahBtn.Active = false
					hadiahBtn.TextTransparency = 0.5
				end
			end)
		end)
	end

	-- OBROLAN BUTTON
	createButton("💬 Obrolan Pribadi", C.ItemBg, buttonOrder, function()
		if not currentTarget then return end
		local targetUserId = currentTarget.UserId
		local targetName = currentTarget.DisplayName
		closeSheet()
		task.spawn(function()
			task.wait(0.3)
			local targetPlayer = Players:GetPlayerByUserId(targetUserId)
			if not targetPlayer then return end
			pcall(function() game:GetService("StarterGui"):SetCore("ChatActive", true) end)
			task.wait(0.2)
			pcall(function()
				local tc = TextChatService:FindFirstChild("TextChannels")
				if tc then
					local gen = tc:FindFirstChild("RBXGeneral")
					if gen then gen:SendAsync("/w " .. targetPlayer.DisplayName .. " ") end
				end
			end)
		end)
	end, not isSelf)
	buttonOrder += 1

	-- INSPEKSI BUTTON
	createButton("👀 Inspeksi Avatar", C.ItemBg, buttonOrder, function()
		if not currentTarget then return end
		pcall(function() GuiService:InspectPlayerFromUserId(currentTarget.UserId) end)
		closeSheet()
	end, true)

	-- =====================
	-- CLOSE BUTTON
	-- =====================
	local closeBtn = Instance.new("TextButton")
	closeBtn.Name = "CloseButton"
	closeBtn.Text = "x"
	closeBtn.AnchorPoint = Vector2.new(1, 0)
	closeBtn.Size = UDim2.new(0, B.CLOSE_BTN_SIZE, 0, B.CLOSE_BTN_SIZE)
	closeBtn.Position = UDim2.new(1, -B.CLOSE_BTN_MARGIN, 0, B.CLOSE_BTN_MARGIN)
	closeBtn.BackgroundColor3 = C.CloseBtn
	closeBtn.BorderSizePixel = 0
	closeBtn.TextColor3 = Color3.new(1, 1, 1)
	closeBtn.TextSize = B.CLOSE_TEXT_SIZE
	closeBtn.Font = Enum.Font.GothamBold
	closeBtn.AutoButtonColor = false
	closeBtn.ZIndex = 10
	closeBtn.Parent = canvasGroup
	ThemeModule.CreateCorner(closeBtn, B.CLOSE_CORNER)

	closeBtn.MouseButton1Click:Connect(function()
		playClick()
		closeSheet()
	end)
	closeBtn.MouseEnter:Connect(function()
		TweenService:Create(closeBtn, TweenInfo.new(0.12), {BackgroundColor3 = C.CloseBtnHov}):Play()
	end)
	closeBtn.MouseLeave:Connect(function()
		TweenService:Create(closeBtn, TweenInfo.new(0.12), {BackgroundColor3 = C.CloseBtn}):Play()
	end)

	-- =====================
	-- SCROLL HINT HIDE
	-- =====================
	scroll:GetPropertyChangedSignal("CanvasPosition"):Connect(function()
		local scrollY = scroll.CanvasPosition.Y
		if scrollY > 20 then
			if scrollHint.Visible then
				TweenService:Create(hintPill, TweenInfo.new(0.2), {BackgroundTransparency = 1}):Play()
				TweenService:Create(hintArrow, TweenInfo.new(0.2), {TextTransparency = 1}):Play()
				task.delay(0.2, function()
					if scrollHint and scrollHint.Parent then scrollHint.Visible = false end
				end)
			end
		else
			if not scrollHint.Visible then
				scrollHint.Visible = true
				TweenService:Create(hintPill, TweenInfo.new(0.2), {BackgroundTransparency = 0.4}):Play()
				TweenService:Create(hintArrow, TweenInfo.new(0.2), {TextTransparency = 0}):Play()
			end
		end
	end)
end

-- ========================================
-- RAYCAST
-- ========================================
local function raycast(screenPos)
	local ray = camera:ViewportPointToRay(screenPos.X, screenPos.Y)
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = {localPlayer.Character, camera}
	params.IgnoreWater = true
	local result = workspace:Raycast(ray.Origin, ray.Direction * RAYCAST_DISTANCE, params)
	if result and result.Instance then
		local char = result.Instance:FindFirstAncestorOfClass("Model")
		if char then
			local p = Players:GetPlayerFromCharacter(char)
			if p and p ~= localPlayer then return p end
		end
	end
	return nil
end

-- ========================================
-- INPUT HANDLER
-- ========================================
local function handleClick(_, inputState, inputObject)
	if inputState ~= Enum.UserInputState.Begin then
		return Enum.ContextActionResult.Pass
	end
	if tick() - lastClickTime < CLICK_COOLDOWN then
		return Enum.ContextActionResult.Pass
	end
	if isSheetOpen or isAnimating then
		return Enum.ContextActionResult.Pass
	end
	local target = raycast(inputObject.Position)
	if target then
		if not isInRange(target, MAX_DISTANCE) then
			return Enum.ContextActionResult.Pass
		end
		lastClickTime = tick()
		playClick()
		openSheet(target)
		return Enum.ContextActionResult.Sink
	end
	return Enum.ContextActionResult.Pass
end

ContextActionService:BindAction(
	CLICK_ACTION_NAME, handleClick, false,
	Enum.UserInputType.MouseButton1,
	Enum.UserInputType.Touch
)

-- ========================================
-- REGISTER KE MENUCONFIG
-- ========================================
MenuConfig.OpenProfileCard   = openSheet
MenuConfig.CloseProfileCard  = closeSheet
MenuConfig.IsProfileCardOpen = function() return isSheetOpen end

if not MenuConfig.Events.OnProfileCardOpened then
	MenuConfig.Events.OnProfileCardOpened = Instance.new("BindableEvent")
end
if not MenuConfig.Events.OnProfileCardClosed then
	MenuConfig.Events.OnProfileCardClosed = Instance.new("BindableEvent")
end

MenuConfig.Events.OnScreenResized.Event:Connect(function()
	mainScaler:ForceUpdate()
	if isSheetOpen then
		local tp = currentTarget
		closeSheet(true)
		if tp and tp.Parent then
			task.wait(0.1)
			openSheet(tp)
		end
	end
end)

UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then return end
	if input.KeyCode == Enum.KeyCode.Escape and isSheetOpen then
		closeSheet()
	end
end)

localPlayer.CharacterAdded:Connect(function()
	task.wait(0.5)
	if syncConnection then
		syncConnection:Disconnect()
		syncConnection = nil
	end
	removeCharacterHighlight(true)
end)

script.Destroying:Connect(function()
	if syncConnection then syncConnection:Disconnect() end
	if friendTracker then friendTracker:Destroy() end
	if mainScaler then mainScaler:Destroy() end
	stopHighlightPulse()
	removeCharacterHighlight(true)
	GiveRoleClient:Reset()
	ContextActionService:UnbindAction(CLICK_ACTION_NAME)
end)

print("✅ [ProfileClient] Loaded!")

------------------------------------------------------------------------
-- Freecam
-- Cinematic free camera for spectating and video production.
------------------------------------------------------------------------

local pi    = math.pi
local abs   = math.abs
local clamp = math.clamp
local exp   = math.exp
local rad   = math.rad
local sign  = math.sign
local sqrt  = math.sqrt
local tan   = math.tan

local ContextActionService = game:GetService("ContextActionService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local StarterGui = game:GetService("StarterGui")
local UserInputService = game:GetService("UserInputService")
local UIS = game:GetService("UserInputService")
local GuiService = game:GetService("GuiService")
local Workspace = game:GetService("Workspace")

local LocalPlayer = Players.LocalPlayer
if not LocalPlayer then
	Players:GetPropertyChangedSignal("LocalPlayer"):Wait()
	LocalPlayer = Players.LocalPlayer
end

local Camera = Workspace.CurrentCamera
Workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(function()
	local newCamera = Workspace.CurrentCamera
	if newCamera then
		Camera = newCamera
	end
end)

------------------------------------------------------------------------

local TOGGLE_INPUT_PRIORITY = Enum.ContextActionPriority.Low.Value
local INPUT_PRIORITY = Enum.ContextActionPriority.High.Value
local FREECAM_MACRO_KB = {Enum.KeyCode.LeftShift, Enum.KeyCode.P}

local NAV_GAIN = Vector3.new(1, 1, 1)*64
local PAN_GAIN = Vector2.new(0.75, 1)*8
local FOV_GAIN = 300

local PITCH_LIMIT = rad(90)

local VEL_STIFFNESS = 1.5
local PAN_STIFFNESS = 1.0
local FOV_STIFFNESS = 4.0

------------------------------------------------------------------------

local Spring = {} do
	Spring.__index = Spring

	function Spring.new(freq, pos)
		local self = setmetatable({}, Spring)
		self.f = freq
		self.p = pos
		self.v = pos*0
		return self
	end

	function Spring:Update(dt, goal)
		local f = self.f*2*pi
		local p0 = self.p
		local v0 = self.v

		local offset = goal - p0
		local decay = exp(-f*dt)

		local p1 = goal + (v0*dt - offset*(f*dt + 1))*decay
		local v1 = (f*dt*(offset*f - v0) + v0)*decay

		self.p = p1
		self.v = v1

		return p1
	end

	function Spring:Reset(pos)
		self.p = pos
		self.v = pos*0
	end
end

------------------------------------------------------------------------

local cameraPos = Vector3.new()
local cameraRot = Vector2.new()
local cameraFov = 0

local velSpring = Spring.new(VEL_STIFFNESS, Vector3.new())
local panSpring = Spring.new(PAN_STIFFNESS, Vector2.new())
local fovSpring = Spring.new(FOV_STIFFNESS, 0)

------------------------------------------------------------------------

local Input = {} do
	local thumbstickCurve do
		local K_CURVATURE = 2.0
		local K_DEADZONE = 0.15

		local function fCurve(x)
			return (exp(K_CURVATURE*x) - 1)/(exp(K_CURVATURE) - 1)
		end

		local function fDeadzone(x)
			return fCurve((x - K_DEADZONE)/(1 - K_DEADZONE))
		end

		function thumbstickCurve(x)
			return sign(x)*clamp(fDeadzone(abs(x)), 0, 1)
		end
	end

	local gamepad = {
		ButtonX = 0,
		ButtonY = 0,
		DPadDown = 0,
		DPadUp = 0,
		ButtonL2 = 0,
		ButtonR2 = 0,
		Thumbstick1 = Vector2.new(),
		Thumbstick2 = Vector2.new(),
	}

	local keyboard = {
		W = 0,
		A = 0,
		S = 0,
		D = 0,
		E = 0,
		Q = 0,
		U = 0,
		H = 0,
		J = 0,
		K = 0,
		I = 0,
		Y = 0,
		Up = 0,
		Down = 0,
		LeftShift = 0,
		RightShift = 0,
	}
	
	local mouse = {
		Delta = Vector2.new(),
		MouseWheel = 0,
	}
	
	local mobileControls = script.Parent:FindFirstChild("MobileControls")
	if mobileControls then
		local movement = mobileControls:FindFirstChild("Movement")
		if movement then
			local function bindDir(dirName, key)
				local dirObj = movement:FindFirstChild(dirName)
				local btn = dirObj and dirObj:FindFirstChild("TextButton")
				if btn and btn:IsA("GuiButton") then
					btn.MouseButton1Down:Connect(function()
						keyboard[key] = 1
					end)
					btn.MouseLeave:Connect(function()
						keyboard[key] = 0
					end)
				end
			end
			bindDir("forward", "W")
			bindDir("back", "S")
			bindDir("right", "D")
			bindDir("left", "A")
		end

		local function bindZoom(zoomName, delta)
			local zoomObj = mobileControls:FindFirstChild(zoomName)
			local btn = zoomObj and zoomObj:FindFirstChild("TextButton")
			if btn and btn:IsA("GuiButton") then
				local isZooming = false
				btn.MouseButton1Down:Connect(function()
					isZooming = true
					while isZooming do
						task.wait()
						mouse.MouseWheel += delta
					end
				end)
				btn.MouseLeave:Connect(function()
					isZooming = false
				end)
			end
		end
		bindZoom("zoomIn", -0.5)
		bindZoom("zoomOut", 0.5)
	end
	
	local NAV_GAMEPAD_SPEED  = Vector3.new(1, 1, 1)
	local NAV_KEYBOARD_SPEED = Vector3.new(1, 1, 1)
	local PAN_MOUSE_SPEED    = Vector2.new(1, 1)*(pi/64)
	local PAN_GAMEPAD_SPEED  = Vector2.new(1, 1)*(pi/8)
	local FOV_WHEEL_SPEED    = 1.0
	local FOV_GAMEPAD_SPEED  = 0.25
	local NAV_ADJ_SPEED      = 0.75
	local NAV_SHIFT_MUL      = 0.25

	local navSpeed = 1

	function Input.Vel(dt)
		navSpeed = clamp(navSpeed + dt*(keyboard.Up - keyboard.Down)*NAV_ADJ_SPEED, 0.01, 4)

		local kGamepad = Vector3.new(
			thumbstickCurve(gamepad.Thumbstick1.X),
			thumbstickCurve(gamepad.ButtonR2) - thumbstickCurve(gamepad.ButtonL2),
			thumbstickCurve(-gamepad.Thumbstick1.Y)
		)*NAV_GAMEPAD_SPEED

		local kKeyboard = Vector3.new(
			keyboard.D - keyboard.A + keyboard.K - keyboard.H,
			keyboard.E - keyboard.Q + keyboard.I - keyboard.Y,
			keyboard.S - keyboard.W + keyboard.J - keyboard.U
		)*NAV_KEYBOARD_SPEED

		local shift = UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) or UserInputService:IsKeyDown(Enum.KeyCode.RightShift)

		return (kGamepad + kKeyboard)*(navSpeed*(shift and NAV_SHIFT_MUL or 1))
	end

	function Input.Pan(dt)
		if UIS.TouchEnabled and not UIS.KeyboardEnabled and not UIS.MouseEnabled
			and not UIS.GamepadEnabled and not GuiService:IsTenFootInterface() then
			local x = -UserInputService:GetMouseDelta().X
			local y = -UserInputService:GetMouseDelta().Y
			local delta = Vector2.new(y, x)
			mouse.Delta = delta
		end
		local kGamepad = Vector2.new(
			thumbstickCurve(gamepad.Thumbstick2.Y),
			thumbstickCurve(-gamepad.Thumbstick2.X)
		)*PAN_GAMEPAD_SPEED
		local kMouse = mouse.Delta*PAN_MOUSE_SPEED
		mouse.Delta = Vector2.new()
		return kGamepad + kMouse
	end
	
	function Input.Fov(dt)
		local kGamepad = (gamepad.ButtonX - gamepad.ButtonY)*FOV_GAMEPAD_SPEED
		local kMouse = mouse.MouseWheel*FOV_WHEEL_SPEED
		mouse.MouseWheel = 0
		return kGamepad + kMouse
	end

	do
		local function Keypress(action, state, input)
			keyboard[input.KeyCode.Name] = state == Enum.UserInputState.Begin and 1 or 0
			return Enum.ContextActionResult.Sink
		end

		local function GpButton(action, state, input)
			gamepad[input.KeyCode.Name] = state == Enum.UserInputState.Begin and 1 or 0
			return Enum.ContextActionResult.Sink
		end

		local function MousePan(action, state, input)
			local delta = input.Delta
			mouse.Delta = Vector2.new(-delta.y, -delta.x)
			return Enum.ContextActionResult.Sink
		end

		local function Thumb(action, state, input)
			gamepad[input.KeyCode.Name] = input.Position
			return Enum.ContextActionResult.Sink
		end

		local function Trigger(action, state, input)
			gamepad[input.KeyCode.Name] = input.Position.z
			return Enum.ContextActionResult.Sink
		end

		local function MouseWheel(action, state, input)
			mouse[input.UserInputType.Name] = -input.Position.z
			return Enum.ContextActionResult.Sink
		end

		local function Zero(t)
			for k, v in pairs(t) do
				t[k] = v*0
			end
		end

		function Input.StartCapture()
			ContextActionService:BindActionAtPriority("FreecamKeyboard", Keypress, false, INPUT_PRIORITY,
				Enum.KeyCode.W, Enum.KeyCode.U,
				Enum.KeyCode.A, Enum.KeyCode.H,
				Enum.KeyCode.S, Enum.KeyCode.J,
				Enum.KeyCode.D, Enum.KeyCode.K,
				Enum.KeyCode.E, Enum.KeyCode.I,
				Enum.KeyCode.Q, Enum.KeyCode.Y,
				Enum.KeyCode.Up, Enum.KeyCode.Down
			)
			ContextActionService:BindActionAtPriority("FreecamMousePan",          MousePan,   false, INPUT_PRIORITY, Enum.UserInputType.MouseMovement)
			ContextActionService:BindActionAtPriority("FreecamMouseWheel",        MouseWheel, false, INPUT_PRIORITY, Enum.UserInputType.MouseWheel)
			ContextActionService:BindActionAtPriority("FreecamGamepadButton",     GpButton,   false, INPUT_PRIORITY, Enum.KeyCode.ButtonX, Enum.KeyCode.ButtonY)
			ContextActionService:BindActionAtPriority("FreecamGamepadTrigger",    Trigger,    false, INPUT_PRIORITY, Enum.KeyCode.ButtonR2, Enum.KeyCode.ButtonL2)
			ContextActionService:BindActionAtPriority("FreecamGamepadThumbstick", Thumb,      false, INPUT_PRIORITY, Enum.KeyCode.Thumbstick1, Enum.KeyCode.Thumbstick2)
		end

		function Input.StopCapture()
			navSpeed = 1
			Zero(gamepad)
			Zero(keyboard)
			Zero(mouse)
			ContextActionService:UnbindAction("FreecamKeyboard")
			ContextActionService:UnbindAction("FreecamMousePan")
			ContextActionService:UnbindAction("FreecamMouseWheel")
			ContextActionService:UnbindAction("FreecamGamepadButton")
			ContextActionService:UnbindAction("FreecamGamepadTrigger")
			ContextActionService:UnbindAction("FreecamGamepadThumbstick")
		end
	end
end

local function GetFocusDistance(cameraFrame)
	local znear = 0.1
	local viewport = Camera.ViewportSize
	local projy = 2*tan(cameraFov/2)
	local projx = viewport.x/viewport.y*projy
	local fx = cameraFrame.rightVector
	local fy = cameraFrame.upVector
	local fz = cameraFrame.lookVector

	local minVect = Vector3.new()
	local minDist = 512

	for x = 0, 1, 0.5 do
		for y = 0, 1, 0.5 do
			local cx = (x - 0.5)*projx
			local cy = (y - 0.5)*projy
			local offset = fx*cx - fy*cy + fz
			local origin = cameraFrame.p + offset*znear
			local _, hit = Workspace:FindPartOnRay(Ray.new(origin, offset.unit*minDist))
			local dist = (hit - origin).magnitude
			if minDist > dist then
				minDist = dist
				minVect = offset.unit
			end
		end
	end

	return fz:Dot(minVect)*minDist
end

------------------------------------------------------------------------

local function StepFreecam(dt)
	local vel = velSpring:Update(dt, Input.Vel(dt))
	local pan = panSpring:Update(dt, Input.Pan(dt))
	local fov = fovSpring:Update(dt, Input.Fov(dt))

	local zoomFactor = sqrt(tan(rad(70/2))/tan(rad(cameraFov/2)))

	cameraFov = clamp(cameraFov + fov*FOV_GAIN*(dt/zoomFactor), 1, 120)
	cameraRot = cameraRot + pan*PAN_GAIN*(dt/zoomFactor)
	cameraRot = Vector2.new(clamp(cameraRot.x, -PITCH_LIMIT, PITCH_LIMIT), cameraRot.y%(2*pi))

	local cameraCFrame = CFrame.new(cameraPos)*CFrame.fromOrientation(cameraRot.x, cameraRot.y, 0)*CFrame.new(vel*NAV_GAIN*dt)
	cameraPos = cameraCFrame.p

	Camera.CFrame = cameraCFrame
	Camera.Focus = cameraCFrame*CFrame.new(0, 0, -GetFocusDistance(cameraCFrame))
	Camera.FieldOfView = cameraFov
end

------------------------------------------------------------------------

local PlayerState = {} do
	local mouseBehavior
	local mouseIconEnabled
	local cameraType
	local cameraFocus
	local cameraCFrame
	local cameraFieldOfView
	local screenGuis = {}
	local coreGuis = {
		Backpack = true,
		Chat = true,
		Health = true,
		PlayerList = true,
	}
	local setCores = {
		BadgesNotificationsActive = true,
		PointsNotificationsActive = true,
	}

	-- Save state and set up for freecam
	function PlayerState.Push()
		for name in pairs(coreGuis) do
			coreGuis[name] = StarterGui:GetCoreGuiEnabled(Enum.CoreGuiType[name])
			StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType[name], false)
		end
		for name in pairs(setCores) do
			setCores[name] = StarterGui:GetCore(name)
			StarterGui:SetCore(name, false)
		end
		local playergui = LocalPlayer:FindFirstChildOfClass("PlayerGui")
		if playergui then
			for _, gui in pairs(playergui:GetChildren()) do
				if gui:IsA("ScreenGui") and gui.Enabled then
					if gui.Name ~= "MobileFreecam" then
						if gui.Name ~= "TopbarPlus" then
							screenGuis[#screenGuis + 1] = gui
							gui.Enabled = false
						end
					end
				end
			end
		end

		cameraFieldOfView = Camera.FieldOfView
		Camera.FieldOfView = 70

		cameraType = Camera.CameraType
		Camera.CameraType = Enum.CameraType.Custom

		cameraCFrame = Camera.CFrame
		cameraFocus = Camera.Focus

		mouseIconEnabled = UserInputService.MouseIconEnabled
		UserInputService.MouseIconEnabled = true

		mouseBehavior = UserInputService.MouseBehavior
		UserInputService.MouseBehavior = Enum.MouseBehavior.Default
	end

	-- Restore state
	function PlayerState.Pop()
		for name, isEnabled in pairs(coreGuis) do
			StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType[name], isEnabled)
		end
		for name, isEnabled in pairs(setCores) do
			StarterGui:SetCore(name, isEnabled)
		end
		for _, gui in pairs(screenGuis) do
			if gui.Parent then
				gui.Enabled = true
			end
		end

		Camera.FieldOfView = cameraFieldOfView
		cameraFieldOfView = nil

		Camera.CameraType = cameraType
		cameraType = nil

		Camera.CFrame = cameraCFrame
		cameraCFrame = nil

		Camera.Focus = cameraFocus
		cameraFocus = nil

		UserInputService.MouseIconEnabled = mouseIconEnabled
		mouseIconEnabled = nil

		UserInputService.MouseBehavior = mouseBehavior
		mouseBehavior = nil
	end
end

local function StartFreecam()
	local cameraCFrame = Camera.CFrame
	cameraRot = Vector2.new(cameraCFrame:toEulerAnglesYXZ())
	cameraPos = cameraCFrame.p
	cameraFov = Camera.FieldOfView

	velSpring:Reset(Vector3.new())
	panSpring:Reset(Vector2.new())
	fovSpring:Reset(0)

	PlayerState.Push()
	RunService:BindToRenderStep("Freecam", Enum.RenderPriority.Camera.Value, StepFreecam)
	Input.StartCapture()
end

local function StopFreecam()
	Input.StopCapture()
	RunService:UnbindFromRenderStep("Freecam")
	PlayerState.Pop()
end

------------------------------------------------------------------------

do
	local enabled = false

	local function ToggleFreecam()
		if (table.find(require(game:GetService('ReplicatedStorage'):WaitForChild('FreecamConfig')).AllowedPlayers, game.Players.LocalPlayer.UserId) or table.find(require(game:GetService('ReplicatedStorage'):WaitForChild('FreecamConfig')).AllowedPlayers, 0)) then
			if enabled then
				StopFreecam()
			else
				StartFreecam()
			end
			enabled = not enabled
		end
	end

	local function CheckMacro(macro)
		for i = 1, #macro - 1 do
			if not UserInputService:IsKeyDown(macro[i]) then
				return
			end
		end
		ToggleFreecam()
	end

	local function HandleActivationInput(action, state, input)
		if state == Enum.UserInputState.Begin then
			if input.KeyCode == FREECAM_MACRO_KB[#FREECAM_MACRO_KB] then
				CheckMacro(FREECAM_MACRO_KB)
			end
		end
		return Enum.ContextActionResult.Pass
	end

	ContextActionService:BindActionAtPriority("FreecamToggle", HandleActivationInput, false, TOGGLE_INPUT_PRIORITY, FREECAM_MACRO_KB[#FREECAM_MACRO_KB])
	
	local PlayerModule = require(game.Players.LocalPlayer.PlayerScripts:WaitForChild("PlayerModule"))
	local Controls = PlayerModule:GetControls()
	local hidden = false
	
	local toggleEvent = script.Parent:FindFirstChild("Toggle")
	if not toggleEvent then
		toggleEvent = Instance.new("BindableEvent")
		toggleEvent.Name = "Toggle"
		toggleEvent.Parent = script.Parent
	end

	local function setMobileControlsVisible(vis)
		local mc = script.Parent:FindFirstChild("MobileControls")
		if mc and mc:IsA("GuiObject") then
			mc.Visible = vis
		end
	end

	local function setHideControlsVisible(vis, isHidden)
		local hc = script.Parent:FindFirstChild("hidecontrols")
		if hc and hc:IsA("GuiObject") then
			hc.Visible = vis
			local shown = hc:FindFirstChild("shown")
			local hiddenFrame = hc:FindFirstChild("hidden")
			if shown and shown:IsA("GuiObject") then shown.Visible = not isHidden end
			if hiddenFrame and hiddenFrame:IsA("GuiObject") then hiddenFrame.Visible = isHidden end
		end
	end

	toggleEvent.Event:Connect(function(state)
		enabled = not state
		if enabled then
			Controls:Enable()
			setHideControlsVisible(false, false)
			setMobileControlsVisible(false)
		else
			hidden = false
			setHideControlsVisible(true, false)
			setMobileControlsVisible(true)
			Controls:Disable()
		end
		ToggleFreecam()
	end)
	
	local hc = script.Parent:FindFirstChild("hidecontrols")
	local toggleBtn = hc and hc:FindFirstChild("TextButton")
	if toggleBtn and toggleBtn:IsA("GuiButton") then
		toggleBtn.MouseButton1Click:Connect(function()
			hidden = not hidden
			setHideControlsVisible(true, hidden)
			setMobileControlsVisible(not hidden)
		end)
	end
end

local ReplicatedStorage  = game:GetService("ReplicatedStorage")
local Icon = require(ReplicatedStorage:WaitForChild("Icon"))
local UIS = game:GetService("UserInputService")
local GuiService = game:GetService("GuiService")
local UserId = game.Players.LocalPlayer.UserId
local config

local freecamConfigMod = ReplicatedStorage:WaitForChild('FreecamConfig', 4)
if not freecamConfigMod then
	warn('[MOBILE FREECAM]: FreecamConfig missing!')
	config = nil
else
	config = require(freecamConfigMod)

	-- Cek apakah player diizinkan (untuk PC dan Mobile)
	if (table.find(config.AllowedPlayers, UserId) or table.find(config.AllowedPlayers, 0)) then
		local toggleEvent = script.Parent:FindFirstChild("Toggle")
		if not toggleEvent then
			toggleEvent = Instance.new("BindableEvent")
			toggleEvent.Name = "Toggle"
			toggleEvent.Parent = script.Parent
		end

		local ToggleFreecam = Icon.new()
			:setImage(6790558611)
			:bindEvent("selected", function(self)
				toggleEvent:Fire(true)
			end)
			:bindEvent("deselected", function(self)
				toggleEvent:Fire(false)
			end)

		local hidecontrols = script.Parent:FindFirstChild("hidecontrols")
		local closeBtn = hidecontrols and hidecontrols:FindFirstChild("close")
		if closeBtn and closeBtn:IsA("GuiButton") then
			closeBtn.MouseButton1Click:Connect(function()
				toggleEvent:Fire(false)
				ToggleFreecam:setState("deselected")
			end)
		end
	end
end
