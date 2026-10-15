-- ========================================
-- MENU CLIENT - Control Panel (Fixed Layout)
-- Place in: StarterGui > MenuGUI(ScreenGui) > MenuClient(LocalScript)
-- ========================================

local Players            = game:GetService("Players")
local ReplicatedStorage  = game:GetService("ReplicatedStorage")
local TweenService       = game:GetService("TweenService")
local UserInputService   = game:GetService("UserInputService")

local Modules = ReplicatedStorage:WaitForChild("Modules")
local MenuConfig  = require(Modules:WaitForChild("MenuConfig"))
local ThemeModule = require(Modules:WaitForChild("ThemeModule"))
local NotifModule = require(Modules:WaitForChild("NotifModule"))

local player    = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local Icon      = require(ReplicatedStorage:WaitForChild("Icon"))

local gui = script.Parent
local Config = MenuConfig.Config

MenuConfig.SetThemeModule(ThemeModule)

-- ========================================
-- PANEL SIZE
-- ========================================
local PANEL_WIDTH   = Config.PanelSize.Width
local PANEL_HEIGHT  = Config.PanelSize.Height
local HEADER_HEIGHT = Config.HeaderHeight

-- ========================================
-- PANEL POSITION SETTINGS
-- ========================================
local PANEL_PADDING = 10

-- ========================================
-- ANIMATION SETTINGS
-- ========================================
local ANIMATION_CONFIG = {
	OpenDuration   = 0.35,
	CloseDuration  = 0.25,
	ScaleStart     = 0.85,
	ScaleEnd       = 1,
	SlideOffsetY   = 25,
	OpenEaseStyle      = Enum.EasingStyle.Back,
	OpenEaseDirection  = Enum.EasingDirection.Out,
	CloseEaseStyle     = Enum.EasingStyle.Quart,
	CloseEaseDirection = Enum.EasingDirection.In,
}

-- ========================================
-- CEGAH EKSEKUSI GANDA
-- ========================================
if gui:GetAttribute("PanelInitialized") then return end
gui:SetAttribute("PanelInitialized", true)

-- ========================================
-- SCREEN GUI SETUP
-- ========================================
gui.Name = "MenuGUI"
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
local SoundSystem = {
	ClickSound = nil,
	SoundId    = "rbxassetid://139658322785649"
}

function SoundSystem.Setup()
	SoundSystem.ClickSound               = Instance.new("Sound")
	SoundSystem.ClickSound.Name          = "PanelClickSound"
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

function SoundSystem.PlayHover()
	if SoundSystem.ClickSound then
		SoundSystem.ClickSound.Volume        = 0.3
		SoundSystem.ClickSound.PlaybackSpeed = 1.5
		SoundSystem.ClickSound:Stop()
		SoundSystem.ClickSound:Play()
		SoundSystem.ClickSound.Volume        = 0.5
		SoundSystem.ClickSound.PlaybackSpeed = 1.2
	end
end

function SoundSystem.PlaySuccess()
	if SoundSystem.ClickSound then
		SoundSystem.ClickSound.Volume        = 0.6
		SoundSystem.ClickSound.PlaybackSpeed = 1.0
		SoundSystem.ClickSound:Stop()
		SoundSystem.ClickSound:Play()
		SoundSystem.ClickSound.Volume        = 0.5
		SoundSystem.ClickSound.PlaybackSpeed = 1.2
	end
end

function SoundSystem.PlayError()
	if SoundSystem.ClickSound then
		SoundSystem.ClickSound.Volume        = 0.5
		SoundSystem.ClickSound.PlaybackSpeed = 0.8
		SoundSystem.ClickSound:Stop()
		SoundSystem.ClickSound:Play()
		SoundSystem.ClickSound.Volume        = 0.5
		SoundSystem.ClickSound.PlaybackSpeed = 1.2
	end
end

SoundSystem.Setup()
MenuConfig.SoundSystem = SoundSystem

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
	local halfX        = viewportSize.X * 0.5
	local offsetX      = (halfX - PANEL_PADDING) / currentScale - PANEL_WIDTH / 2
	local offsetY      = 0
	return offsetX, offsetY
end

-- ========================================
-- MAIN PANEL
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

local panelUIScale   = Instance.new("UIScale")
panelUIScale.Scale   = 1
panelUIScale.Parent  = mainPanel

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
headerCover.Name             = "HeaderCover"
headerCover.Size             = UDim2.new(1, 0, 0, 15)
headerCover.Position         = UDim2.new(0, 0, 1, -15)
headerCover.BackgroundColor3 = ThemeModule.Colors.BackgroundMedium
headerCover.BorderSizePixel  = 0
headerCover.Active           = true
headerCover.Parent           = header

local headerContent = Instance.new("Frame")
headerContent.Name                   = "HeaderContent"
headerContent.Size                   = UDim2.new(1, -16, 1, -10)
headerContent.Position               = UDim2.new(0, 8, 0, 5)
headerContent.BackgroundTransparency = 1
headerContent.BorderSizePixel        = 0
headerContent.Active                 = true
headerContent.Parent                 = header

local tabContainer = Instance.new("Frame")
tabContainer.Name                   = "TabContainer"
tabContainer.Size                   = UDim2.new(1, -44, 1, 0)
tabContainer.Position               = UDim2.new(0, 0, 0, 0)
tabContainer.BackgroundTransparency = 1
tabContainer.BorderSizePixel        = 0
tabContainer.Active                 = true
tabContainer.ClipsDescendants       = true
tabContainer.Parent                 = headerContent

local tabBar = Instance.new("ScrollingFrame")
tabBar.Name                   = "TabBar"
tabBar.Size                   = UDim2.new(1, 0, 1, 0)
tabBar.Position               = UDim2.new(0, 0, 0, 0)
tabBar.BackgroundTransparency = 1
tabBar.BorderSizePixel        = 0
tabBar.ScrollBarThickness     = 0
tabBar.ScrollBarImageTransparency = 1
tabBar.ScrollingEnabled       = true
tabBar.Active                 = true
tabBar.HorizontalScrollBarInset = Enum.ScrollBarInset.None
tabBar.VerticalScrollBarInset = Enum.ScrollBarInset.None
tabBar.ScrollingDirection     = Enum.ScrollingDirection.X
tabBar.AutomaticCanvasSize    = Enum.AutomaticSize.X
tabBar.CanvasSize             = UDim2.new(0, 0, 1, 0)
tabBar.ElasticBehavior        = Enum.ElasticBehavior.Never
tabBar.Parent                 = tabContainer

local tabBarLayout = Instance.new("UIListLayout")
tabBarLayout.FillDirection       = Enum.FillDirection.Horizontal
tabBarLayout.VerticalAlignment   = Enum.VerticalAlignment.Center
tabBarLayout.HorizontalAlignment = Enum.HorizontalAlignment.Left
tabBarLayout.Padding             = UDim.new(0, 4)
tabBarLayout.SortOrder          = Enum.SortOrder.LayoutOrder
tabBarLayout.Parent             = tabBar

local closeButton = Instance.new("TextButton")
closeButton.Name             = "CloseButton"
closeButton.Size             = UDim2.new(0, 32, 0, 32)
closeButton.Position         = UDim2.new(1, -32, 0.5, -16)
closeButton.BackgroundColor3 = ThemeModule.Colors.CloseRed
closeButton.BorderSizePixel  = 0
closeButton.Text             = "x"
closeButton.TextColor3       = ThemeModule.Colors.TextWhite
closeButton.TextSize         = 14
closeButton.Font             = Enum.Font.GothamBold
closeButton.AutoButtonColor  = false
closeButton.Parent           = headerContent

ThemeModule.CreateCorner(closeButton, 6)

closeButton.MouseEnter:Connect(function()
	TweenService:Create(closeButton, TweenInfo.new(0.2),
		{ BackgroundColor3 = ThemeModule.Colors.CloseRedHover }):Play()
end)
closeButton.MouseLeave:Connect(function()
	TweenService:Create(closeButton, TweenInfo.new(0.2),
		{ BackgroundColor3 = ThemeModule.Colors.CloseRed }):Play()
end)

-- ========================================
-- CONTENT CONTAINER
-- ========================================
local contentContainer = Instance.new("Frame")
contentContainer.Name                   = "ContentContainer"
contentContainer.Size                   = UDim2.new(1, -16, 1, -(HEADER_HEIGHT + 16))
contentContainer.Position               = UDim2.new(0, 8, 0, HEADER_HEIGHT + 8)
contentContainer.BackgroundColor3       = ThemeModule.Colors.BackgroundMedium
contentContainer.BackgroundTransparency = 0
contentContainer.BorderSizePixel        = 0
contentContainer.Active                 = true
contentContainer.ClipsDescendants       = true
contentContainer.Parent                 = mainPanel

ThemeModule.CreateCorner(contentContainer, 8)

-- ========================================
-- TAB DEFINITIONS  (Commands dihapus)
-- ========================================
local tabDefinitions = {
	{ Name = "Music",      Icon = "🎵", DisplayName = "Music",      Order = 1 },
	{ Name = "Pengaturan", Icon = "⚙️", DisplayName = "Pengaturan", Order = 2 },
	{ Name = "Pemain",     Icon = "👥", DisplayName = "Pemain",     Order = 3 },
	{ Name = "Toko",       Icon = "🛒", DisplayName = "Toko",       Order = 4 },
	{ Name = "Lapor",      Icon = "📜", DisplayName = "Lapor",      Order = 5 },
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
	btnFrame.Size             = UDim2.new(0, 0, 1, 0)
	btnFrame.AutomaticSize    = Enum.AutomaticSize.X
	btnFrame.BackgroundColor3 = TAB_COLORS.InactiveBackground
	btnFrame.BorderSizePixel  = 0
	btnFrame.LayoutOrder      = def.Order
	btnFrame.Parent           = tabBar

	ThemeModule.CreateCorner(btnFrame, 6)

	local frameGradient = Instance.new("UIGradient")
	frameGradient.Name     = "FrameGradient"
	frameGradient.Color    = ThemeModule.Gradients.Primary
	frameGradient.Rotation = 45
	frameGradient.Enabled  = false
	frameGradient.Parent   = btnFrame

	tabGradients[def.Name]   = frameGradient
	tabFrames[def.Name]      = btnFrame
	tabHoverTweens[def.Name] = nil

	local btnPadding = Instance.new("UIPadding")
	btnPadding.PaddingLeft  = UDim.new(0, 12)
	btnPadding.PaddingRight = UDim.new(0, 12)
	btnPadding.Parent       = btnFrame

	local btn = Instance.new("TextButton")
	btn.Name               = def.Name .. "Tab"
	btn.Size               = UDim2.new(0, 0, 1, 0)
	btn.AutomaticSize      = Enum.AutomaticSize.X
	btn.Position           = UDim2.new(0, 0, 0, 0)
	btn.BackgroundTransparency = 1
	btn.BorderSizePixel    = 0
	btn.Text               = def.Icon .. "  " .. def.DisplayName
	btn.TextColor3         = TAB_COLORS.InactiveText
	btn.TextSize           = 12
	btn.Font               = Enum.Font.GothamMedium
	btn.AutoButtonColor    = false
	btn.Parent             = btnFrame

	btn.MouseEnter:Connect(function()
		if MenuConfig.State.currentTab == def.Name then return end
		if tabHoverTweens[def.Name] then tabHoverTweens[def.Name]:Cancel() end
		local t = TweenService:Create(btnFrame,
			TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
			{ BackgroundColor3 = TAB_COLORS.HoverBackground })
		tabHoverTweens[def.Name] = t
		t:Play()
	end)

	btn.MouseLeave:Connect(function()
		if MenuConfig.State.currentTab == def.Name then return end
		if tabHoverTweens[def.Name] then tabHoverTweens[def.Name]:Cancel() end
		local t = TweenService:Create(btnFrame,
			TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
			{ BackgroundColor3 = TAB_COLORS.InactiveBackground })
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
	MenuConfig.State.currentTab     = tabName
	MenuConfig.State.currentMainTab = tabName

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
			if frame    then frame.BackgroundColor3 = TAB_COLORS.ActiveBackground end
			btn.TextColor3 = TAB_COLORS.ActiveText
			btn.Font       = Enum.Font.GothamBold
		else
			if gradient then gradient.Enabled = false; ThemeModule.GradientSystem.Unregister(gradient) end
			if frame    then frame.BackgroundColor3 = TAB_COLORS.InactiveBackground end
			btn.TextColor3 = TAB_COLORS.InactiveText
			btn.Font       = Enum.Font.GothamMedium
		end
	end

	MenuConfig.Events.OnTabChanged:Fire(tabName)
end

for tabName, btn in pairs(tabButtons) do
	btn.MouseButton1Click:Connect(function() switchTab(tabName) end)
end

-- ========================================
-- NOTIFICATION SYSTEM
-- ========================================
local function showNotification(message, messageType)
	local title    = "Control Panel"
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
-- PANEL POSITION
-- ========================================
local function resetPanelPosition()
	local offsetX, offsetY = getDefaultPanelOffset()
	mainPanel.Position = UDim2.new(0.5, offsetX, 0.5, offsetY)
end

workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(function()
	if panelContainer.Visible then
		task.defer(resetPanelPosition)
	end
end)

-- ========================================
-- PANEL TOGGLE
-- ========================================
local panelVisible = false
local isAnimating  = false
local panelIcon    = nil

local function openPanel()
	if isAnimating then return end
	isAnimating  = true
	panelVisible = true
	MenuConfig.State.isMenuOpen = true

	local offsetX, offsetY = getDefaultPanelOffset()
	resetPanelPosition()
	panelContainer.Visible      = true
	mainPanel.GroupTransparency = 1
	mainStroke.Transparency     = 1
	panelUIScale.Scale          = ANIMATION_CONFIG.ScaleStart
	mainPanel.Position          = UDim2.new(0.5, offsetX, 0.5, offsetY - ANIMATION_CONFIG.SlideOffsetY)

	local openInfo = TweenInfo.new(ANIMATION_CONFIG.OpenDuration, ANIMATION_CONFIG.OpenEaseStyle, ANIMATION_CONFIG.OpenEaseDirection)
	local fadeInfo = TweenInfo.new(ANIMATION_CONFIG.OpenDuration * 0.7, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	TweenService:Create(panelUIScale, openInfo, { Scale = ANIMATION_CONFIG.ScaleEnd }):Play()
	TweenService:Create(mainPanel,    openInfo, { Position = UDim2.new(0.5, offsetX, 0.5, offsetY) }):Play()
	TweenService:Create(mainPanel,    fadeInfo, { GroupTransparency = 0 }):Play()
	TweenService:Create(mainStroke,   fadeInfo, { Transparency = 0 }):Play()
	task.delay(ANIMATION_CONFIG.OpenDuration, function() isAnimating = false end)
	MenuConfig.Events.OnMenuToggled:Fire(true)
end

local function closePanel()
	if isAnimating then return end
	isAnimating  = true
	panelVisible = false
	MenuConfig.State.isMenuOpen = false

	local pos            = mainPanel.Position
	local closeTweenInfo = TweenInfo.new(ANIMATION_CONFIG.CloseDuration, ANIMATION_CONFIG.CloseEaseStyle, ANIMATION_CONFIG.CloseEaseDirection)
	TweenService:Create(panelUIScale, closeTweenInfo, { Scale = ANIMATION_CONFIG.ScaleStart }):Play()
	TweenService:Create(mainPanel,    closeTweenInfo, {
		Position = UDim2.new(pos.X.Scale, pos.X.Offset, pos.Y.Scale, pos.Y.Offset - ANIMATION_CONFIG.SlideOffsetY)
	}):Play()
	TweenService:Create(mainPanel,    closeTweenInfo, { GroupTransparency = 1 }):Play()
	TweenService:Create(mainStroke,   closeTweenInfo, { Transparency = 1 }):Play()
	task.delay(ANIMATION_CONFIG.CloseDuration, function()
		panelContainer.Visible      = false
		isAnimating                 = false
		panelUIScale.Scale          = ANIMATION_CONFIG.ScaleEnd
		mainPanel.GroupTransparency = 0
		mainStroke.Transparency     = 0
		resetPanelPosition()
	end)
	MenuConfig.Events.OnMenuToggled:Fire(false)
end

local function togglePanel()
	if isAnimating then return end
	SoundSystem.PlayClick()
	if panelVisible then closePanel() else openPanel() end
end

local function forceClosePanel()
	panelVisible                = false
	isAnimating                 = false
	MenuConfig.State.isMenuOpen = false
	panelContainer.Visible      = false
	panelUIScale.Scale          = ANIMATION_CONFIG.ScaleEnd
	mainPanel.GroupTransparency = 0
	mainStroke.Transparency     = 0
	resetPanelPosition()
end

-- ========================================
-- REGISTER CALLBACKS
-- ========================================
MenuConfig.OpenPanel          = openPanel
MenuConfig.ClosePanel         = closePanel
MenuConfig.TogglePanel        = togglePanel
MenuConfig.ForceClosePanel    = forceClosePanel
MenuConfig.SwitchTab          = switchTab
MenuConfig.ShowNotification   = showNotification
MenuConfig.ResetPanelPosition = resetPanelPosition

-- ========================================
-- REGISTER GUI REFERENCES
-- ========================================
MenuConfig.GUI.ScreenGui        = gui
MenuConfig.GUI.MainPanel        = mainPanel
MenuConfig.GUI.PanelContainer   = panelContainer
MenuConfig.GUI.Header           = header
MenuConfig.GUI.HeaderContent    = headerContent
MenuConfig.GUI.TabContainer     = tabContainer
MenuConfig.GUI.TabBar           = tabBar
MenuConfig.GUI.ContentContainer = contentContainer
MenuConfig.GUI.CloseButton      = closeButton
MenuConfig.GUI.TabButtons       = tabButtons
MenuConfig.GUI.TabFrames        = tabFrames
MenuConfig.GUI.TabPages         = tabPages
MenuConfig.GUI.TabNames         = tabNames
MenuConfig.GUI.UIScale          = uiScale
MenuConfig.GUI.PanelUIScale     = panelUIScale
MenuConfig.GUI.GUIScaler        = guiScaler

-- Page references (Commands dihapus)
MenuConfig.GUI.MusicPage      = tabPages["Music"]
MenuConfig.GUI.PengaturanPage = tabPages["Pengaturan"]
MenuConfig.GUI.PemainPage     = tabPages["Pemain"]
MenuConfig.GUI.PlayersPage    = tabPages["Pemain"]
MenuConfig.GUI.TokoPage       = tabPages["Toko"]
MenuConfig.GUI.LaporPage      = tabPages["Lapor"]
MenuConfig.GUI.ConfigPage     = tabPages["Pengaturan"]
MenuConfig.GUI.GamePassPage   = tabPages["Toko"]
MenuConfig.GUI.ReportPage     = tabPages["Lapor"]

-- Tab button references (Commands dihapus)
MenuConfig.GUI.MusicTab      = tabButtons["Music"]
MenuConfig.GUI.PengaturanTab = tabButtons["Pengaturan"]
MenuConfig.GUI.PemainTab     = tabButtons["Pemain"]
MenuConfig.GUI.TokoTab       = tabButtons["Toko"]
MenuConfig.GUI.LaporTab      = tabButtons["Lapor"]

-- ========================================
-- ICON TOOLBAR
-- ========================================
local existingIcon = Icon.getIcon("PanelIcon")
if existingIcon then existingIcon:destroy() end

panelIcon = Icon.new()
panelIcon:setName("PanelIcon")
panelIcon:setImage("rbxassetid://9405921255")
panelIcon:setCaption("MENU")
panelIcon:setRight()
panelIcon:setOrder(6)

panelIcon.selected:Connect(function()   SoundSystem.PlayClick(); openPanel()  end)
panelIcon.deselected:Connect(function() SoundSystem.PlayClick(); closePanel() end)

MenuConfig.GUI.PanelIcon = panelIcon

-- ========================================
-- RESPAWN HANDLER
-- ========================================
local function onCharacterAdded()
	task.defer(function()
		forceClosePanel()
		if panelIcon then panelIcon:deselect() end
	end)
end

player.CharacterAdded:Connect(onCharacterAdded)

-- ========================================
-- BUTTON CONNECTIONS
-- ========================================
closeButton.MouseButton1Click:Connect(function()
	SoundSystem.PlayClick()
	closePanel()
	if panelIcon then panelIcon:deselect() end
end)

-- ========================================
-- KEYBOARD TOGGLE
-- ========================================
UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then return end
	if input.KeyCode == Config.ToggleKey then
		togglePanel()
		if panelIcon then
			if panelVisible then panelIcon:select() else panelIcon:deselect() end
		end
	end
end)

-- ========================================
-- CLEANUP ON DESTROY
-- ========================================
gui.Destroying:Connect(function()
	guiScaler:Destroy()
	ThemeModule.GradientSystem.Unregister(mainStrokeGradient)
	for _, gradient in pairs(tabGradients) do ThemeModule.GradientSystem.Unregister(gradient) end
	for _, tween   in pairs(tabHoverTweens) do if tween then tween:Cancel() end end
	if panelIcon then panelIcon:destroy(); panelIcon = nil end
end)

-- ========================================
-- INIT
-- ========================================
switchTab("Music")
MenuConfig.MarkGUIReady()

print("✅ [MenuClient] Loaded — Commands tab removed!")
