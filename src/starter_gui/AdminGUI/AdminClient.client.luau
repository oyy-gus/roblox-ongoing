-- ========================================
-- ADMIN CLIENT - Control Panel
-- Place in: StarterGui > AdminGUI(ScreenGui) > AdminClient(LocalScript)
-- ========================================

local Players              = game:GetService("Players")
local ReplicatedStorage    = game:GetService("ReplicatedStorage")
local TweenService         = game:GetService("TweenService")
local UserInputService     = game:GetService("UserInputService")
local ContextActionService = game:GetService("ContextActionService")

local Modules = ReplicatedStorage:WaitForChild("Modules")
local AdminConfig = require(Modules:WaitForChild("AdminConfig"))
local ThemeModule = require(Modules:WaitForChild("ThemeModule"))
local NotifModule = require(Modules:WaitForChild("NotifModule"))

local player    = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local Icon      = require(ReplicatedStorage:WaitForChild("Icon"))

local gui    = script.Parent
local Config = AdminConfig.Config

-- ========================================
-- ALLOWED ROLES FOR ADMIN PANEL
-- ========================================
local ALLOWED_ROLES = {
	["Owner"]     = true,
	["Developer"] = true,
	["Admin"]     = true,
}

-- ========================================
-- PANEL SIZE
-- ========================================
local PANEL_WIDTH   = Config.PanelSize.Width
local PANEL_HEIGHT  = Config.PanelSize.Height
local HEADER_HEIGHT = Config.HeaderHeight
local SIDEBAR_WIDTH = Config.SidebarWidth

-- ========================================
-- DRAG BOUNDARY SETTINGS
-- ========================================
local DRAG_PADDING = 10

-- ========================================
-- ANIMATION SETTINGS
-- ========================================
local ANIMATION_CONFIG = {
	OpenDuration       = 0.35,
	CloseDuration      = 0.25,
	ScaleStart         = 0.85,
	ScaleEnd           = 1,
	SlideOffsetY       = 25,
	OpenEaseStyle      = Enum.EasingStyle.Back,
	OpenEaseDirection  = Enum.EasingDirection.Out,
	CloseEaseStyle     = Enum.EasingStyle.Quart,
	CloseEaseDirection = Enum.EasingDirection.In,
}

-- ========================================
-- CEGAH EKSEKUSI GANDA
-- ========================================
if gui:GetAttribute("AdminInitialized") then return end
gui:SetAttribute("AdminInitialized", true)

-- ========================================
-- SCREEN GUI SETUP
-- ========================================
gui.Name = "AdminGUI"
if gui:IsA("ScreenGui") then
	gui.ResetOnSpawn   = false
	gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	gui.DisplayOrder   = 100
	gui.IgnoreGuiInset = true
	gui.Enabled        = true
end

-- ========================================
-- START GRADIENT ANIMATION SYSTEM
-- ========================================
ThemeModule.GradientSystem.Start()

-- ========================================
-- UI SCALE SYSTEM
-- ========================================
local ScalingSystem = require(
	ReplicatedStorage
		:WaitForChild("AutoScaleSystem")
		:WaitForChild("ScaleSystem")
)

local guiScaler = ScalingSystem.new(gui)

local function getCurrentScale()
	return guiScaler:GetCurrentScale()
end

local uiScale = gui:FindFirstChildOfClass("UIScale")

-- ========================================
-- SOUND SYSTEM
-- ========================================
local SoundSystem = { ClickSound = nil, SoundId = "rbxassetid://139658322785649" }

function SoundSystem.Setup()
	SoundSystem.ClickSound = Instance.new("Sound")
	SoundSystem.ClickSound.Name          = "AdminClickSound"
	SoundSystem.ClickSound.SoundId       = SoundSystem.SoundId
	SoundSystem.ClickSound.Volume        = 0.5
	SoundSystem.ClickSound.PlaybackSpeed = 1.2
	SoundSystem.ClickSound.Parent        = game:GetService("SoundService")
end

function SoundSystem.PlayClick()
	if SoundSystem.ClickSound then
		SoundSystem.ClickSound:Stop()
		SoundSystem.ClickSound:Play()
	end
end

SoundSystem.Setup()
AdminConfig.SoundSystem = SoundSystem

-- ========================================
-- CAMERA LOCK SYSTEM
-- ========================================
local CameraLockSystem = { isLocked = false }

function CameraLockSystem.Lock()
	if CameraLockSystem.isLocked then return end
	CameraLockSystem.originalMouseBehavior         = UserInputService.MouseBehavior
	CameraLockSystem.originalMouseDeltaSensitivity = UserInputService.MouseDeltaSensitivity
	UserInputService.MouseBehavior                 = Enum.MouseBehavior.Default
	UserInputService.MouseDeltaSensitivity         = 0
	CameraLockSystem.isLocked = true
end

function CameraLockSystem.Unlock()
	if not CameraLockSystem.isLocked then return end
	if CameraLockSystem.originalMouseBehavior then
		UserInputService.MouseBehavior = CameraLockSystem.originalMouseBehavior
	end
	if CameraLockSystem.originalMouseDeltaSensitivity then
		UserInputService.MouseDeltaSensitivity = CameraLockSystem.originalMouseDeltaSensitivity
	end
	CameraLockSystem.isLocked = false
end

-- ========================================
-- PANEL CONTAINER
-- ========================================
local panelContainer = Instance.new("Frame")
panelContainer.Name                   = "PanelContainer"
panelContainer.Size                   = UDim2.new(1, 0, 1, 0)
panelContainer.Position               = UDim2.new(0, 0, 0, 0)
panelContainer.BackgroundTransparency = 1
panelContainer.BorderSizePixel        = 0
panelContainer.Visible                = false
panelContainer.Parent                 = gui

-- ========================================
-- HELPER: Get Default Panel Offset
-- ========================================
local function getDefaultPanelOffset()
	local currentScale = getCurrentScale()
	local viewportSize = workspace.CurrentCamera.ViewportSize
	local halfX = viewportSize.X * 0.5
	local offsetX = (halfX - DRAG_PADDING) / currentScale - PANEL_WIDTH / 2
	local offsetY = 0
	return offsetX, offsetY
end

-- ========================================
-- MAIN PANEL (CanvasGroup)
-- ========================================
local mainPanel = Instance.new("CanvasGroup")
mainPanel.Name              = "MainPanel"
mainPanel.Size              = UDim2.new(0, PANEL_WIDTH, 0, PANEL_HEIGHT)
mainPanel.Position          = UDim2.new(0.5, 0, 0.5, 0)
mainPanel.AnchorPoint       = Vector2.new(0.5, 0.5)
mainPanel.BackgroundColor3  = ThemeModule.Colors.BackgroundDark
mainPanel.BorderSizePixel   = 0
mainPanel.Active            = true
mainPanel.GroupTransparency = 0
mainPanel.Parent            = panelContainer

local panelUIScale = Instance.new("UIScale")
panelUIScale.Scale  = 1
panelUIScale.Parent = mainPanel

ThemeModule.CreateCorner(mainPanel, 12)

local mainStroke, mainStrokeGradient = ThemeModule.CreateAnimatedStroke(mainPanel, 2, "Primary", 1.2)
mainStroke.Transparency = 1

-- ========================================
-- HEADER
-- ========================================
local header = Instance.new("Frame")
header.Name             = "Header"
header.Size             = UDim2.new(1, 0, 0, HEADER_HEIGHT)
header.BackgroundColor3 = ThemeModule.Colors.BackgroundMedium
header.BorderSizePixel  = 0
header.Active           = true
header.Parent           = mainPanel

ThemeModule.CreateCorner(header, 12)

local headerCover = Instance.new("Frame")
headerCover.Size             = UDim2.new(1, 0, 0, 15)
headerCover.Position         = UDim2.new(0, 0, 1, -15)
headerCover.BackgroundColor3 = ThemeModule.Colors.BackgroundMedium
headerCover.BorderSizePixel  = 0
headerCover.Active           = true
headerCover.Parent           = header

local titleLabel = Instance.new("TextLabel")
titleLabel.Name               = "Title"
titleLabel.Size               = UDim2.new(0, 300, 1, 0)
titleLabel.Position           = UDim2.new(0, 16, 0, 0)
titleLabel.BackgroundTransparency = 1
titleLabel.Text               = "🛡️  Admin Control Panel"
titleLabel.TextColor3         = ThemeModule.Colors.TextWhite
titleLabel.TextSize           = 16
titleLabel.Font               = Enum.Font.GothamBold
titleLabel.TextXAlignment     = Enum.TextXAlignment.Left
titleLabel.Parent             = header

local titleGradient = ThemeModule.CreatePrimaryGradient(titleLabel, 0, 1)

local closeButton = Instance.new("TextButton")
closeButton.Name             = "CloseButton"
closeButton.Size             = UDim2.new(0, 32, 0, 32)
closeButton.Position         = UDim2.new(1, -40, 0, 7)
closeButton.BackgroundColor3 = ThemeModule.Colors.CloseRed
closeButton.BorderSizePixel  = 0
closeButton.Text             = "x"
closeButton.TextColor3       = ThemeModule.Colors.TextWhite
closeButton.TextSize         = 14
closeButton.Font             = Enum.Font.GothamBold
closeButton.AutoButtonColor  = false
closeButton.Parent           = header

ThemeModule.CreateCorner(closeButton, 6)

closeButton.MouseEnter:Connect(function()
	TweenService:Create(closeButton, TweenInfo.new(0.2), { BackgroundColor3 = ThemeModule.Colors.CloseRedHover }):Play()
end)
closeButton.MouseLeave:Connect(function()
	TweenService:Create(closeButton, TweenInfo.new(0.2), { BackgroundColor3 = ThemeModule.Colors.CloseRed }):Play()
end)

-- ========================================
-- TAB CONTAINER (Sidebar)
-- ========================================
local tabContainer = Instance.new("Frame")
tabContainer.Name             = "TabContainer"
tabContainer.Size             = UDim2.new(0, SIDEBAR_WIDTH, 1, -(HEADER_HEIGHT + 16))
tabContainer.Position         = UDim2.new(0, 8, 0, HEADER_HEIGHT + 8)
tabContainer.BackgroundColor3 = ThemeModule.Colors.BackgroundMedium
tabContainer.BorderSizePixel  = 0
tabContainer.Active           = true
tabContainer.Parent           = mainPanel

ThemeModule.CreateCorner(tabContainer, 8)

local tabPadding = Instance.new("UIPadding")
tabPadding.PaddingTop    = UDim.new(0, 8)
tabPadding.PaddingBottom = UDim.new(0, 8)
tabPadding.PaddingLeft   = UDim.new(0, 5)
tabPadding.PaddingRight  = UDim.new(0, 5)
tabPadding.Parent        = tabContainer

local tabLayout = Instance.new("UIListLayout")
tabLayout.Padding             = UDim.new(0, 4)
tabLayout.FillDirection       = Enum.FillDirection.Vertical
tabLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
tabLayout.VerticalAlignment   = Enum.VerticalAlignment.Top
tabLayout.SortOrder           = Enum.SortOrder.LayoutOrder
tabLayout.Parent              = tabContainer

-- ========================================
-- CONTENT CONTAINER
-- ========================================
local contentContainer = Instance.new("Frame")
contentContainer.Name                   = "ContentContainer"
contentContainer.Size                   = UDim2.new(1, -(SIDEBAR_WIDTH + 24), 1, -(HEADER_HEIGHT + 16))
contentContainer.Position               = UDim2.new(0, SIDEBAR_WIDTH + 16, 0, HEADER_HEIGHT + 8)
contentContainer.BackgroundColor3       = ThemeModule.Colors.BackgroundMedium
contentContainer.BackgroundTransparency = 0
contentContainer.BorderSizePixel        = 0
contentContainer.Active                 = true
contentContainer.ClipsDescendants       = true
contentContainer.Parent                 = mainPanel

ThemeModule.CreateCorner(contentContainer, 8)

-- ========================================
-- TAB DEFINITIONS
-- ========================================
local tabDefinitions = {
	{ Name = "RoleGive",    Icon = "🎭", DisplayName = "Role Give",    Order = 1 },
	{ Name = "Broadcast",   Icon = "📢", DisplayName = "Broadcast",    Order = 2 },
	{ Name = "CustomTitle", Icon = "✨", DisplayName = "Custom Title", Order = 3 },
	{ Name = "ManageTitle", Icon = "📝", DisplayName = "Manage Title", Order = 4 },
	{ Name = "Logs",        Icon = "📋", DisplayName = "Logs",         Order = 5 },
	{ Name = "Players",     Icon = "👥", DisplayName = "Players",      Order = 6 },
	{ Name = "Settings",    Icon = "⚙️", DisplayName = "Settings",     Order = 7 },
}

-- ========================================
-- BUILD TABS & PAGES
-- ========================================
local tabButtons     = {}
local tabFrames      = {}
local tabPages       = {}
local tabNames       = {}
local tabGradients   = {}
local tabHoverTweens = {}

local TAB_COLORS = {
	ActiveBackground   = Color3.fromRGB(255, 255, 255),
	InactiveBackground = ThemeModule.Colors.BackgroundLight,
	HoverBackground    = ThemeModule.Colors.BackgroundLighter,
	ActiveText         = ThemeModule.Colors.BackgroundDark,
	InactiveText       = ThemeModule.Colors.TextGray,
}

local function createTabButton(def)
	local btnFrame = Instance.new("Frame")
	btnFrame.Name             = def.Name .. "TabFrame"
	btnFrame.Size             = UDim2.new(1, 0, 0, Config.TabButtonHeight)
	btnFrame.BackgroundColor3 = TAB_COLORS.InactiveBackground
	btnFrame.BorderSizePixel  = 0
	btnFrame.LayoutOrder      = def.Order
	btnFrame.Parent           = tabContainer

	ThemeModule.CreateCorner(btnFrame, 6)

	local frameGradient = Instance.new("UIGradient")
	frameGradient.Name    = "FrameGradient"
	frameGradient.Color   = ThemeModule.Gradients.Primary
	frameGradient.Rotation = 45
	frameGradient.Enabled = false
	frameGradient.Parent  = btnFrame

	tabGradients[def.Name]   = frameGradient
	tabFrames[def.Name]      = btnFrame
	tabHoverTweens[def.Name] = nil

	local btn = Instance.new("TextButton")
	btn.Name               = def.Name .. "Tab"
	btn.Size               = UDim2.new(1, 0, 1, 0)
	btn.Position           = UDim2.new(0, 0, 0, 0)
	btn.BackgroundTransparency = 1
	btn.BorderSizePixel    = 0
	btn.Text               = def.Icon .. "  " .. def.DisplayName
	btn.TextColor3         = TAB_COLORS.InactiveText
	btn.TextSize           = 11
	btn.Font               = Enum.Font.GothamMedium
	btn.AutoButtonColor    = false
	btn.Parent             = btnFrame

	btn.MouseEnter:Connect(function()
		if AdminConfig.State.currentTab == def.Name then return end
		if tabHoverTweens[def.Name] then tabHoverTweens[def.Name]:Cancel() end
		local t = TweenService:Create(btnFrame, TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			BackgroundColor3 = TAB_COLORS.HoverBackground
		})
		tabHoverTweens[def.Name] = t
		t:Play()
	end)

	btn.MouseLeave:Connect(function()
		if AdminConfig.State.currentTab == def.Name then return end
		if tabHoverTweens[def.Name] then tabHoverTweens[def.Name]:Cancel() end
		local t = TweenService:Create(btnFrame, TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			BackgroundColor3 = TAB_COLORS.InactiveBackground
		})
		tabHoverTweens[def.Name] = t
		t:Play()
	end)

	return btn, btnFrame
end

local function createTabPage(def)
	local page = Instance.new("Frame")
	page.Name                   = def.Name .. "Page"
	page.Size                   = UDim2.new(1, 0, 1, 0)
	page.BackgroundTransparency = 1
	page.BorderSizePixel        = 0
	page.Active                 = true
	page.Visible                = false
	page.Parent                 = contentContainer
	return page
end

for _, def in ipairs(tabDefinitions) do
	local btn, btnFrame = createTabButton(def)
	local page          = createTabPage(def)
	tabButtons[def.Name] = btn
	tabPages[def.Name]   = page
	table.insert(tabNames, def.Name)
end

-- ========================================
-- TAB SWITCHING
-- ========================================
local function switchTab(tabName)
	SoundSystem.PlayClick()
	AdminConfig.State.currentTab = tabName

	for name, page in pairs(tabPages) do
		page.Visible = (name == tabName)
	end

	for name, btn in pairs(tabButtons) do
		local gradient = tabGradients[name]
		local frame    = tabFrames[name]

		if tabHoverTweens[name] then
			tabHoverTweens[name]:Cancel()
			tabHoverTweens[name] = nil
		end

		if name == tabName then
			if gradient then gradient.Enabled = true; ThemeModule.GradientSystem.Register(gradient, 1) end
			if frame then frame.BackgroundColor3 = TAB_COLORS.ActiveBackground end
			btn.TextColor3 = TAB_COLORS.ActiveText
			btn.Font       = Enum.Font.GothamBold
		else
			if gradient then gradient.Enabled = false; ThemeModule.GradientSystem.Unregister(gradient) end
			if frame then frame.BackgroundColor3 = TAB_COLORS.InactiveBackground end
			btn.TextColor3 = TAB_COLORS.InactiveText
			btn.Font       = Enum.Font.GothamMedium
		end
	end

	AdminConfig.Events.OnTabChanged:Fire(tabName)
end

for tabName, btn in pairs(tabButtons) do
	btn.MouseButton1Click:Connect(function() switchTab(tabName) end)
end

-- ========================================
-- NOTIFICATION SYSTEM
-- ========================================
local function showNotification(message, messageType)
	local title    = "Admin Panel"
	local duration = Config.Notification.Duration or 3
	if messageType == "success" then
		NotifModule.Success(title, message, duration)
	elseif messageType == "error" then
		NotifModule.Error(title, message, duration)
	elseif messageType == "warning" then
		NotifModule.Warning(title, message, duration)
	elseif messageType == "info" then
		NotifModule.Info(title, message, duration)
	else
		NotifModule.Notify({ Type = "Notification", Title = title, Text = message, Duration = duration })
	end
end

-- ========================================
-- DRAG BOUNDARY
-- ========================================
local function calculateDragBoundaries()
	local currentScale = getCurrentScale()
	local viewportSize = workspace.CurrentCamera.ViewportSize
	local halfX = viewportSize.X * 0.5
	local halfY = viewportSize.Y * 0.5
	return
		(DRAG_PADDING - halfX) / currentScale + PANEL_WIDTH / 2,
	(halfX - DRAG_PADDING) / currentScale - PANEL_WIDTH / 2,
	(DRAG_PADDING - halfY) / currentScale + PANEL_HEIGHT / 2,
	(halfY - DRAG_PADDING) / currentScale - PANEL_HEIGHT / 2
end

local function clampPanelPosition()
	local pos = mainPanel.Position
	local minX, maxX, minY, maxY = calculateDragBoundaries()
	local cx = math.clamp(pos.X.Offset, minX, maxX)
	local cy = math.clamp(pos.Y.Offset, minY, maxY)
	if cx ~= pos.X.Offset or cy ~= pos.Y.Offset then
		mainPanel.Position = UDim2.new(0.5, cx, 0.5, cy)
	end
end

local function resetPanelPosition()
	local offsetX, offsetY = getDefaultPanelOffset()
	mainPanel.Position = UDim2.new(0.5, offsetX, 0.5, offsetY)
end

workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(function()
	if panelContainer.Visible then
		task.defer(clampPanelPosition)
	end
end)

-- ========================================
-- PANEL TOGGLE
-- ========================================
local panelVisible   = false
local isAnimating    = false
local adminIcon      = nil
local hasAdminAccess = false

local function openPanel()
	if isAnimating or not hasAdminAccess then return end
	isAnimating = true
	panelVisible = true
	AdminConfig.State.isMenuOpen = true

	local offsetX, offsetY = getDefaultPanelOffset()

	resetPanelPosition()
	panelContainer.Visible       = true
	mainPanel.GroupTransparency  = 1
	mainStroke.Transparency      = 1
	panelUIScale.Scale           = ANIMATION_CONFIG.ScaleStart
	mainPanel.Position           = UDim2.new(0.5, offsetX, 0.5, offsetY - ANIMATION_CONFIG.SlideOffsetY)

	local openInfo = TweenInfo.new(ANIMATION_CONFIG.OpenDuration, ANIMATION_CONFIG.OpenEaseStyle, ANIMATION_CONFIG.OpenEaseDirection)
	local fadeInfo = TweenInfo.new(ANIMATION_CONFIG.OpenDuration * 0.7, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	TweenService:Create(panelUIScale, openInfo, { Scale = ANIMATION_CONFIG.ScaleEnd }):Play()
	TweenService:Create(mainPanel, openInfo, { Position = UDim2.new(0.5, offsetX, 0.5, offsetY) }):Play()
	TweenService:Create(mainPanel, fadeInfo, { GroupTransparency = 0 }):Play()
	TweenService:Create(mainStroke, fadeInfo, { Transparency = 0 }):Play()
	task.delay(ANIMATION_CONFIG.OpenDuration, function() isAnimating = false end)
	AdminConfig.Events.OnMenuToggled:Fire(true)
end

local function closePanel()
	if isAnimating then return end
	isAnimating = true
	panelVisible = false
	AdminConfig.State.isMenuOpen = false

	local pos = mainPanel.Position
	local closeTweenInfo = TweenInfo.new(ANIMATION_CONFIG.CloseDuration, ANIMATION_CONFIG.CloseEaseStyle, ANIMATION_CONFIG.CloseEaseDirection)
	TweenService:Create(panelUIScale, closeTweenInfo, { Scale = ANIMATION_CONFIG.ScaleStart }):Play()
	TweenService:Create(mainPanel, closeTweenInfo, { Position = UDim2.new(pos.X.Scale, pos.X.Offset, pos.Y.Scale, pos.Y.Offset - ANIMATION_CONFIG.SlideOffsetY) }):Play()
	TweenService:Create(mainPanel, closeTweenInfo, { GroupTransparency = 1 }):Play()
	TweenService:Create(mainStroke, closeTweenInfo, { Transparency = 1 }):Play()
	task.delay(ANIMATION_CONFIG.CloseDuration, function()
		panelContainer.Visible      = false
		isAnimating                 = false
		panelUIScale.Scale          = ANIMATION_CONFIG.ScaleEnd
		mainPanel.GroupTransparency = 0
		mainStroke.Transparency     = 0
		resetPanelPosition()
	end)
	AdminConfig.Events.OnMenuToggled:Fire(false)
end

local function togglePanel()
	if isAnimating or not hasAdminAccess then return end
	SoundSystem.PlayClick()
	if panelVisible then closePanel() else openPanel() end
end

local function forceClosePanel()
	panelVisible                 = false
	isAnimating                  = false
	AdminConfig.State.isMenuOpen = false
	panelContainer.Visible       = false
	panelUIScale.Scale           = ANIMATION_CONFIG.ScaleEnd
	mainPanel.GroupTransparency  = 0
	mainStroke.Transparency      = 0
	resetPanelPosition()
end

-- ========================================
-- REGISTER CALLBACKS
-- ========================================
AdminConfig.OpenPanel          = openPanel
AdminConfig.ClosePanel         = closePanel
AdminConfig.TogglePanel        = togglePanel
AdminConfig.ForceClosePanel    = forceClosePanel
AdminConfig.SwitchTab          = switchTab
AdminConfig.ShowNotification   = showNotification
AdminConfig.ResetPanelPosition = resetPanelPosition
AdminConfig.ClampPanelPosition = clampPanelPosition

-- ========================================
-- REGISTER GUI REFERENCES
-- ========================================
AdminConfig.GUI.ScreenGui        = gui
AdminConfig.GUI.MainPanel        = mainPanel
AdminConfig.GUI.PanelContainer   = panelContainer
AdminConfig.GUI.Header           = header
AdminConfig.GUI.TabContainer     = tabContainer
AdminConfig.GUI.ContentContainer = contentContainer
AdminConfig.GUI.CloseButton      = closeButton
AdminConfig.GUI.TabButtons       = tabButtons
AdminConfig.GUI.TabFrames        = tabFrames
AdminConfig.GUI.TabPages         = tabPages
AdminConfig.GUI.TabNames         = tabNames
AdminConfig.GUI.UIScale          = uiScale
AdminConfig.GUI.PanelUIScale     = panelUIScale
AdminConfig.GUI.GUIScaler        = guiScaler

-- Individual page references
AdminConfig.GUI.RoleGivePage    = tabPages["RoleGive"]
AdminConfig.GUI.BroadcastPage   = tabPages["Broadcast"]
AdminConfig.GUI.CustomTitlePage = tabPages["CustomTitle"]
AdminConfig.GUI.ManageTitlePage = tabPages["ManageTitle"]
AdminConfig.GUI.LogsPage        = tabPages["Logs"]
AdminConfig.GUI.PlayersPage     = tabPages["Players"]
AdminConfig.GUI.SettingsPage    = tabPages["Settings"]

-- Individual tab button references
AdminConfig.GUI.RoleGiveTab    = tabButtons["RoleGive"]
AdminConfig.GUI.BroadcastTab   = tabButtons["Broadcast"]
AdminConfig.GUI.CustomTitleTab = tabButtons["CustomTitle"]
AdminConfig.GUI.ManageTitleTab = tabButtons["ManageTitle"]
AdminConfig.GUI.LogsTab        = tabButtons["Logs"]
AdminConfig.GUI.PlayersTab     = tabButtons["Players"]
AdminConfig.GUI.SettingsTab    = tabButtons["Settings"]

-- ========================================
-- DRAGGING SYSTEM
-- ========================================
local dragging  = false
local dragInput = nil
local dragStart = nil
local startPos  = nil

local function updateDrag(input)
	local delta        = input.Position - dragStart
	local currentScale = getCurrentScale()
	local adjusted     = delta / currentScale
	local minX, maxX, minY, maxY = calculateDragBoundaries()
	mainPanel.Position = UDim2.new(0.5,
		math.clamp(startPos.X.Offset + adjusted.X, minX, maxX),
		0.5,
		math.clamp(startPos.Y.Offset + adjusted.Y, minY, maxY))
end

header.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		local cp = closeButton.AbsolutePosition
		local cs = closeButton.AbsoluteSize
		if input.Position.X >= cp.X and input.Position.X <= cp.X + cs.X and
			input.Position.Y >= cp.Y and input.Position.Y <= cp.Y + cs.Y then return end
		dragging  = true
		dragStart = input.Position
		startPos  = mainPanel.Position
		CameraLockSystem.Lock()
		ContextActionService:BindActionAtPriority("BlockCameraMovement", function() return Enum.ContextActionResult.Sink end,
		false, Enum.ContextActionPriority.High.Value + 2000, Enum.UserInputType.MouseMovement, Enum.UserInputType.Touch)
		input.Changed:Connect(function()
			if input.UserInputState == Enum.UserInputState.End then
				dragging = false
				CameraLockSystem.Unlock()
				ContextActionService:UnbindAction("BlockCameraMovement")
			end
		end)
	end
end)

header.InputChanged:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
		dragInput = input
	end
end)

UserInputService.InputChanged:Connect(function(input)
	if dragging and input == dragInput then updateDrag(input) end
end)

UserInputService.InputEnded:Connect(function(input)
	if (input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch) and dragging then
		dragging = false
		CameraLockSystem.Unlock()
		ContextActionService:UnbindAction("BlockCameraMovement")
	end
end)

-- ========================================
-- ACCESS CHECK SYSTEM
-- ========================================
local function hasAllowedRole(role)
	return ALLOWED_ROLES[role] == true
end

local function checkAdminAccess()
	local roleValue = player:FindFirstChild("Role")
	if roleValue and hasAllowedRole(roleValue.Value) then
		hasAdminAccess = true

		if not adminIcon then
			local existingIcon = Icon.getIcon("AdminPanelIcon")
			if existingIcon then existingIcon:destroy() end

			adminIcon = Icon.new()
			adminIcon:setName("AdminPanelIcon")
			adminIcon:setImage("rbxassetid://135964688013914")
			adminIcon:setCaption("Admin Panel")
			adminIcon:setRight()
			adminIcon:setOrder(4)

			adminIcon.selected:Connect(function()   SoundSystem.PlayClick(); openPanel()  end)
			adminIcon.deselected:Connect(function() SoundSystem.PlayClick(); closePanel() end)

			AdminConfig.GUI.AdminIcon = adminIcon
		end

		adminIcon:setEnabled(true)
		return true
	else
		hasAdminAccess = false

		if panelVisible then
			forceClosePanel()
			if adminIcon then adminIcon:deselect() end
		end

		if adminIcon then
			adminIcon:destroy()
			adminIcon = nil
			AdminConfig.GUI.AdminIcon = nil
		end

		return false
	end
end

-- ========================================
-- BUTTON CONNECTIONS
-- ========================================
closeButton.MouseButton1Click:Connect(function()
	SoundSystem.PlayClick()
	closePanel()
	if adminIcon then adminIcon:deselect() end
end)

-- ========================================
-- KEYBOARD TOGGLE
-- ========================================
UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed or not hasAdminAccess then return end
	if input.KeyCode == Config.ToggleKey then
		togglePanel()
		if adminIcon then
			if panelVisible then adminIcon:select() else adminIcon:deselect() end
		end
	end
end)

-- ========================================
-- PLACEHOLDER PAGES (Logs, Players, Settings)
-- ========================================
local placeholders = {
	{ page = "Logs",     text = "📋 Logs\n\nKonten akan ditambahkan nanti" },
	{ page = "Players",  text = "👥 Players\n\nKonten akan ditambahkan nanti" },
	{ page = "Settings", text = "⚙️ Settings\n\nKonten akan ditambahkan nanti" },
}

for _, p in ipairs(placeholders) do
	local lbl = Instance.new("TextLabel")
	lbl.Size                   = UDim2.new(1, 0, 1, 0)
	lbl.BackgroundTransparency = 1
	lbl.Text                   = p.text
	lbl.TextColor3             = ThemeModule.Colors.TextGray
	lbl.TextSize               = 14
	lbl.Font                   = Enum.Font.GothamMedium
	lbl.Parent                 = tabPages[p.page]
end

-- ========================================
-- ROLE MONITORING
-- ========================================
task.spawn(function()
	local roleValue = player:WaitForChild("Role", 15)
	if roleValue then
		checkAdminAccess()
		roleValue:GetPropertyChangedSignal("Value"):Connect(function()
			task.wait(0.1)
			checkAdminAccess()
		end)
	else
		hasAdminAccess = false
		if adminIcon then adminIcon:destroy(); adminIcon = nil end
	end
end)

player.ChildAdded:Connect(function(child)
	if child.Name == "Role" and child:IsA("StringValue") then
		task.wait(0.1)
		checkAdminAccess()
		child:GetPropertyChangedSignal("Value"):Connect(function()
			task.wait(0.1)
			checkAdminAccess()
		end)
	end
end)

player.ChildRemoved:Connect(function(child)
	if child.Name == "Role" then
		hasAdminAccess = false
		if panelVisible then forceClosePanel() end
		if adminIcon then
			adminIcon:destroy()
			adminIcon = nil
			AdminConfig.GUI.AdminIcon = nil
		end
	end
end)

-- ========================================
-- CLEANUP ON DESTROY
-- ========================================
gui.Destroying:Connect(function()
	guiScaler:Destroy()
	ThemeModule.GradientSystem.Unregister(mainStrokeGradient)
	ThemeModule.GradientSystem.Unregister(titleGradient)
	for _, gradient in pairs(tabGradients) do ThemeModule.GradientSystem.Unregister(gradient) end
	for _, tween in pairs(tabHoverTweens) do if tween then tween:Cancel() end end
	if adminIcon then adminIcon:destroy(); adminIcon = nil end
end)

-- ========================================
-- INIT
-- ========================================
switchTab("RoleGive")
AdminConfig.MarkGUIReady()

print("✅ [AdminClient] Loaded successfully!")
