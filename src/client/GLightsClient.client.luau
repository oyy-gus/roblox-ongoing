--[[
    ║              GLights Pro Controller v4.1 (BridgeNet Edition)               ║
    ║     Auto Mode ON • Party Preset Auto • TopbarPlus • Developer Only         ║
    ║     ✨ Redesigned UI with classic Top Tabs & Stable Layout                 ║
    ╚═══════════════════════════════════════════════════════════════════════════╝
]]


local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local BridgeNet = require(ReplicatedStorage:WaitForChild("BridgeNet"))
local Bridges = require(ReplicatedStorage:WaitForChild("Bridges"))
local Icon = require(ReplicatedStorage:WaitForChild("Icon"))
local AutoScaleSystem = ReplicatedStorage:WaitForChild("AutoScaleSystem")
local ScaleSystem = require(AutoScaleSystem:WaitForChild("ScaleSystem"))

-- ═══════════════════════════════════════════════════════════════════════════════
--                      DEVELOPER ONLY ACCESS CHECK
-- ═══════════════════════════════════════════════════════════════════════════════
local ALLOWED_ROLES = {
	["Developer"] = true,
	["Owner"] = true,
}

local function getPlayerRole()
	local roleValue = player:FindFirstChild("Role")
	if roleValue and roleValue:IsA("StringValue") then
		return roleValue.Value
	end
	return nil
end

local function isDeveloper()
	local role = getPlayerRole()
	if role and ALLOWED_ROLES[role] then
		return true
	end
	return false
end

local function waitForRoleAndCheck()
	local startTime = tick()
	local maxWait = 15
	local roleValue = player:WaitForChild("Role", maxWait)

	if not roleValue then return false end
	if roleValue.Value ~= "" then return isDeveloper() end

	local roleSet = false
	local connection
	connection = roleValue:GetPropertyChangedSignal("Value"):Connect(function()
		if roleValue.Value ~= "" then
			roleSet = true
			if connection then connection:Disconnect() end
		end
	end)

	while not roleSet and (tick() - startTime) < maxWait do
		task.wait(0.2)
	end
	if connection then connection:Disconnect() end
	if not roleSet then return false end

	return isDeveloper()
end

if not waitForRoleAndCheck() then
	return
end

-- ═══════════════════════════════════════════════════════════════════════════════
--                              CONFIGURATION
-- ═══════════════════════════════════════════════════════════════════════════════
local CONFIG = {
	FRAME_WIDTH = 700,
	FRAME_HEIGHT = 450,

	FIXTURES = {"All", "Heads", "Washes", "Bars"},
	ALL_FIXTURES = {"Heads", "Washes", "Bars"},

	COLORS = {
		{name = "White",   color = Color3.fromRGB(255, 255, 255)},
		{name = "Red",     color = Color3.fromRGB(255, 30, 30)},
		{name = "Orange",  color = Color3.fromRGB(255, 120, 0)},
		{name = "Yellow",  color = Color3.fromRGB(255, 220, 0)},
		{name = "Lime",    color = Color3.fromRGB(100, 255, 0)},
		{name = "Green",   color = Color3.fromRGB(30, 220, 30)},
		{name = "Cyan",    color = Color3.fromRGB(0, 220, 255)},
		{name = "Blue",    color = Color3.fromRGB(30, 80, 255)},
		{name = "Purple",  color = Color3.fromRGB(140, 0, 255)},
		{name = "Magenta", color = Color3.fromRGB(255, 0, 220)},
		{name = "Pink",    color = Color3.fromRGB(255, 100, 180)},
		{name = "Gold",    color = Color3.fromRGB(255, 180, 0)},
		{name = "Teal",    color = Color3.fromRGB(0, 180, 180)},
		{name = "Violet",  color = Color3.fromRGB(120, 0, 220)},
		{name = "Ice",     color = Color3.fromRGB(180, 230, 255)},
		{name = "Coral",   color = Color3.fromRGB(255, 100, 100)},
	},

	STATE_CUES = {
		{name = "Cue1", label = "Cue 1", cue = "State.Cue1"}, {name = "Cue2", label = "Cue 2", cue = "State.Cue2"}, {name = "Cue3", label = "Cue 3", cue = "State.Cue3"},
		{name = "Cue4", label = "Cue 4", cue = "State.Cue4"}, {name = "Cue5", label = "Cue 5", cue = "State.Cue5"}, {name = "Cue6", label = "Cue 6", cue = "State.Cue6"},
		{name = "Cue7", label = "Cue 7", cue = "State.Cue7"}, {name = "Cue8", label = "Cue 8", cue = "State.Cue8"}, {name = "Cue9", label = "Cue 9", cue = "State.Cue9"},
		{name = "Cue10", label = "Cue 10", cue = "State.Cue10"}, {name = "Cue11", label = "Cue 11", cue = "State.Cue11"}, {name = "Cue12", label = "Cue 12", cue = "State.Cue12"},
	},

	COLOR_CUES = {
		{name = "ColorCue1", label = "Color 1", cue = "Color.ColorCue1"}, {name = "ColorCue2", label = "Color 2", cue = "Color.ColorCue2"},
		{name = "ColorCue3", label = "Color 3", cue = "Color.ColorCue3"}, {name = "ColorCue4", label = "Color 4", cue = "Color.ColorCue4"}, {name = "ColorCue5", label = "Color 5", cue = "Color.ColorCue5"},
	},

	EFFECT_CUES = {
		{name = "Strobe", label = "⚡ Strobe", cue = "Strobe"}, {name = "Random", label = "🎲 Random", cue = "Random"},
		{name = "FadeRandom", label = "🌈 Fade Rnd", cue = "FadeRandom"}, {name = "BumpRandom", label = "💥 Bump Rnd", cue = "BumpRandom"},
	},

	POSITION_CUES = {
		{name = "Circle", label = "⭕ Circle", cue = "Position.Circle"}, {name = "RandomCircle", label = "🔄 Rnd Circle", cue = "Position.RandomCircle"},
		{name = "SmoothPan", label = "↔️ Smooth Pan", cue = "Position.SmoothPan"}, {name = "SmoothTilt", label = "↕️ Smooth Tilt", cue = "Position.SmoothTilt"},
		{name = "RandomPan", label = "🔀 Random Pan", cue = "Position.RandomPan"}, {name = "RandomTilt", label = "🔃 Random Tilt", cue = "Position.RandomTilt"},
	},

	CUSTOM_POSITIONS = {
		{name = "CrossFwd", label = "✖️ Cross →", cue = "CustomPositions.Cross", reverse = false}, {name = "CrossBwd", label = "✖️ Cross ←", cue = "CustomPositions.Cross", reverse = true},
		{name = "InFwd", label = "🎯 In →", cue = "CustomPositions.In", reverse = false}, {name = "InBwd", label = "🎯 In ←", cue = "CustomPositions.In", reverse = true},
		{name = "WideFwd", label = "↔️ Wide →", cue = "CustomPositions.Wide", reverse = false}, {name = "WideBwd", label = "↔️ Wide ←", cue = "CustomPositions.Wide", reverse = true},
		{name = "UDFwd", label = "↕️ UD →", cue = "CustomPositions.UD", reverse = false}, {name = "UDBwd", label = "↕️ UD ←", cue = "CustomPositions.UD", reverse = true},
	},

	QUICK_ACTIONS = {
		{name = "ON", emoji = "💡", cmd = "On"}, {name = "OFF", emoji = "🔌", cmd = "Off"}, {name = "FADE IN", emoji = "🌅", cmd = "FadeOn"}, {name = "FADE OUT", emoji = "🌙", cmd = "FadeOff"},
		{name = "RESET", emoji = "🔄", cmd = "Reset"}, {name = "HARD RST", emoji = "⚠️", cmd = "HardReset"}, {name = "FLASH", emoji = "⚡", cmd = "Flash"}, {name = "C.FLASH", emoji = "🌈", cmd = "ColorFlash"},
	},

	BEAM_MODES = {
		{name = "Beam", label = "💫 Beam", mode = "Beam"}, {name = "NoBeam", label = "🔲 No Beam", mode = "NoBeam"}, {name = "Gobo", label = "🎭 Gobo", mode = "Gobo"},
	},

	MOTOR_SPEEDS = {
		{name = "Freeze", label = "❄️ Freeze", speed = 0}, {name = "Slow", label = "🐢 Slow", speed = 0.002}, {name = "Medium", label = "🚶 Medium", speed = 0.01}, {name = "Fast", label = "🏃 Fast", speed = 0.03}, {name = "Ultra", label = "⚡ Ultra", speed = 0.05},
	},

	PRESETS = {
		{
			name = "🎉 Party Mode", desc = "Colorful beats & motion",
			actions = function(fire, fixture)
				fire(fixture, "On") fire(fixture, "Cue", "Color.ColorCue1", true) fire(fixture, "Cue", "Position.RandomCircle", true) fire(fixture, "Dimness", 0)
			end
		},
		{
			name = "🔥 Fire Show", desc = "Warm orange & red tones",
			actions = function(fire, fixture)
				fire(fixture, "On") fire(fixture, "Color", Color3.fromRGB(255, 80, 0)) fire(fixture, "Cue", "Position.SmoothTilt", true)
			end
		},
		{
			name = "❄️ Ice Storm", desc = "Cool blue & cyan tones",
			actions = function(fire, fixture)
				fire(fixture, "On") fire(fixture, "Color", Color3.fromRGB(100, 180, 255)) fire(fixture, "Cue", "Position.Circle", true)
			end
		},
		{
			name = "🌈 Rainbow Wave", desc = "Full spectrum cycle",
			actions = function(fire, fixture)
				fire(fixture, "On") fire(fixture, "Cue", "Color.ColorCue2", true) fire(fixture, "Cue", "Position.SmoothPan", true) fire(fixture, "SmoothColor", true)
			end
		},
		{
			name = "⚡ Strobe Flash", desc = "High energy strobe",
			actions = function(fire, fixture)
				fire(fixture, "On") fire(fixture, "Color", Color3.fromRGB(255, 255, 255)) fire(fixture, "Cue", "Strobe", true)
			end
		},
		{
			name = "🌊 Ocean Flow", desc = "Smooth wave motion",
			actions = function(fire, fixture)
				fire(fixture, "On") fire(fixture, "Color", Color3.fromRGB(0, 150, 200)) fire(fixture, "Cue", "FadeRandom", true)
			end
		},
	},

	THEME = {
		primary = Color3.fromRGB(110, 90, 220),
		primaryDark = Color3.fromRGB(80, 60, 180),
		secondary = Color3.fromRGB(45, 42, 60),
		background = Color3.fromRGB(20, 18, 28),
		backgroundAlt = Color3.fromRGB(30, 27, 40),
		card = Color3.fromRGB(38, 35, 50),
		cardHover = Color3.fromRGB(50, 48, 65),
		text = Color3.fromRGB(255, 255, 255),
		textDim = Color3.fromRGB(160, 150, 180),
		success = Color3.fromRGB(70, 200, 110),
		danger = Color3.fromRGB(230, 70, 70),
		warning = Color3.fromRGB(255, 180, 50),
	}
}

-- ═══════════════════════════════════════════════════════════════════════════════
--                                  STATE
-- ═══════════════════════════════════════════════════════════════════════════════
local State = {
	panelOpen = false, currentFixture = "All", currentTab = "Power",
	autoMode = true, musicSync = true, brightness = 1, cueSpeed = 1, fadeSpeed = 1,
	smoothColor = false, loopCues = false, animatedGradients = false, beamMode = "Beam",
	beamThickness = 0.5, goboSpread = 50, pan = 0, tilt = 0, motorSpeed = 0.01,
	colorSelector = "All", overshoot = false, groupRandom = false, activeCues = {},
	beatHistory = {}, lastBeat = 0, lastLoud = 0, autoHue = 0, partyModeActive = false,
}

-- ═══════════════════════════════════════════════════════════════════════════════
--                             UTILITY FUNCTIONS
-- ═══════════════════════════════════════════════════════════════════════════════
local function targets(fixture)
	if fixture == "All" then return CONFIG.ALL_FIXTURES else return {fixture} end
end

local function fire(fixture, cmd, ...)
	for _, t in ipairs(targets(fixture)) do
		Bridges.GLightsRun:Fire(t, cmd, ...)
	end
end

local function createTween(obj, props, duration)
	return TweenService:Create(obj, TweenInfo.new(duration or 0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), props)
end

local function createCorner(parent, radius)
	local corner = Instance.new("UICorner") corner.CornerRadius = UDim.new(0, radius or 6) corner.Parent = parent return corner
end

-- ═══════════════════════════════════════════════════════════════════════════════
--           FIXED SCROLLING FRAME
-- ═══════════════════════════════════════════════════════════════════════════════
local function createScrollingFrame(parent, name)
	local scroll = Instance.new("ScrollingFrame")
	scroll.Name = name
	scroll.Size = UDim2.new(1, 0, 1, 0)
	scroll.BackgroundTransparency = 1
	scroll.BorderSizePixel = 0
	scroll.ScrollingDirection = Enum.ScrollingDirection.Y
	scroll.ScrollBarThickness = 4
	scroll.ScrollBarImageColor3 = CONFIG.THEME.primary
	scroll.ScrollBarImageTransparency = 0.2
	scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
	scroll.CanvasSize = UDim2.new(0, 0, 0, 0)
	scroll.Parent = parent

	local layout = Instance.new("UIListLayout")
	layout.Padding = UDim.new(0, 8)
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Parent = scroll

	local padding = Instance.new("UIPadding")
	padding.PaddingTop = UDim.new(0, 8)
	padding.PaddingBottom = UDim.new(0, 60)
	padding.PaddingLeft = UDim.new(0, 4)
	padding.PaddingRight = UDim.new(0, 8)
	padding.Parent = scroll

	return scroll, layout
end

-- ═══════════════════════════════════════════════════════════════════════════════
--                              UI COMPONENTS
-- ═══════════════════════════════════════════════════════════════════════════════
local function createSectionHeader(parent, text, layoutOrder)
	local header = Instance.new("Frame")
	header.Size = UDim2.new(1, 0, 0, 22)
	header.BackgroundTransparency = 1
	header.LayoutOrder = layoutOrder or 0
	header.Parent = parent

	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(1, 0, 1, 0)
	label.BackgroundTransparency = 1
	label.Text = text
	label.TextColor3 = CONFIG.THEME.textDim
	label.TextSize = 11
	label.Font = Enum.Font.GothamBold
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.Parent = header
	return header
end

local function createToggle(parent, title, default, callback, layoutOrder)
	local container = Instance.new("Frame")
	container.Size = UDim2.new(1, 0, 0, 36)
	container.BackgroundColor3 = CONFIG.THEME.card
	container.BorderSizePixel = 0
	container.LayoutOrder = layoutOrder or 0
	container.Parent = parent
	createCorner(container, 6)

	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(0.6, 0, 1, 0)
	label.Position = UDim2.new(0.03, 0, 0, 0)
	label.BackgroundTransparency = 1
	label.Text = title
	label.TextColor3 = CONFIG.THEME.text
	label.TextSize = 12
	label.Font = Enum.Font.GothamMedium
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.Parent = container

	local toggleBg = Instance.new("Frame")
	toggleBg.Size = UDim2.new(0, 40, 0, 22)
	toggleBg.Position = UDim2.new(0.95, -40, 0.5, -11)
	toggleBg.BackgroundColor3 = default and CONFIG.THEME.success or CONFIG.THEME.secondary
	toggleBg.BorderSizePixel = 0
	toggleBg.Parent = container
	createCorner(toggleBg, 11)

	local knob = Instance.new("Frame")
	knob.Size = UDim2.new(0, 16, 0, 16)
	knob.Position = default and UDim2.new(1, -19, 0.5, -8) or UDim2.new(0, 3, 0.5, -8)
	knob.BackgroundColor3 = Color3.new(1, 1, 1)
	knob.BorderSizePixel = 0
	knob.Parent = toggleBg
	createCorner(knob, 8)

	local btn = Instance.new("TextButton")
	btn.Size = UDim2.new(1, 0, 1, 0)
	btn.BackgroundTransparency = 1
	btn.Text = ""
	btn.Parent = container

	local enabled = default
	local function setToggle(state)
		enabled = state
		createTween(toggleBg, {BackgroundColor3 = enabled and CONFIG.THEME.success or CONFIG.THEME.secondary}):Play()
		createTween(knob, {Position = enabled and UDim2.new(1, -19, 0.5, -8) or UDim2.new(0, 3, 0.5, -8)}):Play()
	end
	btn.MouseButton1Click:Connect(function() setToggle(not enabled) if callback then callback(enabled) end end)
	return container, function() return enabled end, setToggle
end

local function createSlider(parent, title, min, max, default, suffix, callback, layoutOrder)
	local container = Instance.new("Frame")
	container.Size = UDim2.new(1, 0, 0, 48)
	container.BackgroundColor3 = CONFIG.THEME.card
	container.BorderSizePixel = 0
	container.LayoutOrder = layoutOrder or 0
	container.Parent = parent
	createCorner(container, 6)

	local titleLabel = Instance.new("TextLabel")
	titleLabel.Size = UDim2.new(0.55, 0, 0, 16)
	titleLabel.Position = UDim2.new(0.03, 0, 0, 6)
	titleLabel.BackgroundTransparency = 1
	titleLabel.Text = title
	titleLabel.TextColor3 = CONFIG.THEME.text
	titleLabel.TextSize = 11
	titleLabel.Font = Enum.Font.GothamMedium
	titleLabel.TextXAlignment = Enum.TextXAlignment.Left
	titleLabel.Parent = container

	local valueLabel = Instance.new("TextLabel")
	valueLabel.Size = UDim2.new(0.4, 0, 0, 16)
	valueLabel.Position = UDim2.new(0.57, 0, 0, 6)
	valueLabel.BackgroundTransparency = 1
	valueLabel.TextColor3 = CONFIG.THEME.primary
	valueLabel.TextSize = 11
	valueLabel.Font = Enum.Font.GothamBold
	valueLabel.TextXAlignment = Enum.TextXAlignment.Right
	valueLabel.Parent = container

	local sliderBg = Instance.new("Frame")
	sliderBg.Size = UDim2.new(0.94, 0, 0, 6)
	sliderBg.Position = UDim2.new(0.03, 0, 0, 30)
	sliderBg.BackgroundColor3 = CONFIG.THEME.backgroundAlt
	sliderBg.BorderSizePixel = 0
	sliderBg.Parent = container
	createCorner(sliderBg, 3)

	local pct_def = math.clamp((default - min) / (max - min), 0, 1)
	local fill = Instance.new("Frame")
	fill.Size = UDim2.new(pct_def, 0, 1, 0)
	fill.BackgroundColor3 = CONFIG.THEME.primary
	fill.BorderSizePixel = 0
	fill.Parent = sliderBg
	createCorner(fill, 3)

	local knob = Instance.new("Frame")
	knob.Size = UDim2.new(0, 14, 0, 14)
	knob.Position = UDim2.new(pct_def, 0, 0.5, -7)
	knob.AnchorPoint = Vector2.new(0.5, 0)
	knob.BackgroundColor3 = Color3.new(1, 1, 1)
	knob.BorderSizePixel = 0
	knob.ZIndex = 2
	knob.Parent = sliderBg
	createCorner(knob, 7)

	local currentValue = default
	valueLabel.Text = suffix == "x" and string.format("%.1f%s", default, suffix) or math.floor(default) .. suffix

	local function updateSlider(pct)
		pct = math.clamp(pct, 0, 1)
		local value = min + pct * (max - min)
		currentValue = value
		fill.Size = UDim2.new(pct, 0, 1, 0)
		knob.Position = UDim2.new(pct, 0, 0.5, -7)
		valueLabel.Text = suffix == "x" and string.format("%.1f%s", value, suffix) or math.floor(value) .. suffix
		if callback then callback(value) end
	end

	local dragging = false
	local function processInput(input)
		local absPos = sliderBg.AbsolutePosition.X
		local absSize = sliderBg.AbsoluteSize.X
		local pct = math.clamp((input.Position.X - absPos) / absSize, 0, 1)
		updateSlider(pct)
	end

	sliderBg.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragging = true processInput(input)
		end
	end)
	UserInputService.InputChanged:Connect(function(input)
		if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
			processInput(input)
		end
	end)
	UserInputService.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then dragging = false end
	end)

	return container, function() return currentValue end
end

local function createActionButton(parent, text, color, activeColor, size, callback, layoutOrder)
	local btn = Instance.new("TextButton")
	btn.Size = size or UDim2.new(1, 0, 1, 0)
	btn.BackgroundColor3 = color or CONFIG.THEME.secondary
	btn.BorderSizePixel = 0
	btn.Text = text
	btn.TextSize = 10
	btn.TextColor3 = CONFIG.THEME.text
	btn.Font = Enum.Font.GothamMedium
	btn.AutoButtonColor = false
	btn.LayoutOrder = layoutOrder or 0
	btn.Parent = parent
	createCorner(btn, 6)

	btn.MouseEnter:Connect(function() createTween(btn, {BackgroundColor3 = CONFIG.THEME.cardHover}):Play() end)
	btn.MouseLeave:Connect(function() createTween(btn, {BackgroundColor3 = color or CONFIG.THEME.secondary}):Play() end)
	if callback then btn.MouseButton1Click:Connect(callback) end
	return btn
end

local function createCueButton(parent, cueData, callback)
	local btn = Instance.new("TextButton")
	btn.BackgroundColor3 = CONFIG.THEME.secondary
	btn.BorderSizePixel = 0
	btn.Text = cueData.label
	btn.TextSize = 10
	btn.TextColor3 = CONFIG.THEME.text
	btn.Font = Enum.Font.GothamMedium
	btn.AutoButtonColor = false
	btn.Parent = parent
	createCorner(btn, 6)

	local active = false
	local function setActive(state)
		active = state
		State.activeCues[cueData.cue] = state
		createTween(btn, {BackgroundColor3 = active and CONFIG.THEME.success or CONFIG.THEME.secondary}):Play()
	end
	btn.MouseButton1Click:Connect(function() setActive(not active) if callback then callback(cueData, active) end end)
	return btn, setActive
end

local function createGridLayout(parent, cellOffset, padding)
	local grid = Instance.new("UIGridLayout")
	grid.CellSize = cellOffset or UDim2.new(0, 160, 0, 36)
	grid.CellPadding = padding or UDim2.new(0, 6, 0, 6)
	grid.HorizontalAlignment = Enum.HorizontalAlignment.Left
	grid.SortOrder = Enum.SortOrder.LayoutOrder
	grid.Parent = parent
	return grid
end

-- ═══════════════════════════════════════════════════════════════════════════════
--                              MAIN UI BUILDER
-- ═══════════════════════════════════════════════════════════════════════════════
local function buildUI()
	local gui = Instance.new("ScreenGui")
	gui.Name = "GLightsProUI"
	gui.ResetOnSpawn = false
	gui.IgnoreGuiInset = true

	local mainPanel = Instance.new("Frame")
	mainPanel.Size = UDim2.new(0, CONFIG.FRAME_WIDTH, 0, CONFIG.FRAME_HEIGHT)
	mainPanel.Position = UDim2.new(0.5, 0, 0.5, 0)
	mainPanel.AnchorPoint = Vector2.new(0.5, 0.5)
	mainPanel.BackgroundColor3 = CONFIG.THEME.background
	mainPanel.BorderSizePixel = 0
	mainPanel.Visible = false
	mainPanel.ClipsDescendants = true
	mainPanel.Parent = gui
	createCorner(mainPanel, 12)

	-- Header
	local header = Instance.new("Frame")
	header.Size = UDim2.new(1, 0, 0, 46)
	header.BackgroundColor3 = CONFIG.THEME.backgroundAlt
	header.BorderSizePixel = 0
	header.Parent = mainPanel

	local title = Instance.new("TextLabel")
	title.Size = UDim2.new(0, 160, 1, 0)
	title.Position = UDim2.new(0, 16, 0, 0)
	title.BackgroundTransparency = 1
	title.Text = "💡 GLights Pro v4.1"
	title.TextColor3 = CONFIG.THEME.text
	title.TextSize = 14
	title.Font = Enum.Font.GothamBold
	title.TextXAlignment = Enum.TextXAlignment.Left
	title.Parent = header

	local closeBtn = Instance.new("TextButton")
	closeBtn.Size = UDim2.new(0, 32, 0, 32)
	closeBtn.Position = UDim2.new(1, -40, 0.5, -16)
	closeBtn.BackgroundColor3 = CONFIG.THEME.danger
	closeBtn.BorderSizePixel = 0
	closeBtn.Text = "X"
	closeBtn.TextSize = 14
	closeBtn.TextColor3 = Color3.new(1, 1, 1)
	closeBtn.Font = Enum.Font.GothamBold
	closeBtn.Parent = header
	createCorner(closeBtn, 6)

	-- Fixture Selector (Top Center)
	local fixtureSel = Instance.new("Frame")
	fixtureSel.Size = UDim2.new(0, 280, 0, 30)
	fixtureSel.Position = UDim2.new(0.5, -140, 0.5, -15)
	fixtureSel.BackgroundTransparency = 1
	fixtureSel.Parent = header

	local fixLayout = Instance.new("UIListLayout")
	fixLayout.FillDirection = Enum.FillDirection.Horizontal
	fixLayout.Padding = UDim.new(0, 4)
	fixLayout.Parent = fixtureSel

	local fixtureButtons = {}
	for i, fixture in ipairs(CONFIG.FIXTURES) do
		local btn = Instance.new("TextButton")
		btn.Size = UDim2.new(0, 66, 1, 0)
		btn.BackgroundColor3 = fixture == State.currentFixture and CONFIG.THEME.primary or CONFIG.THEME.secondary
		btn.BorderSizePixel = 0
		btn.Text = fixture
		btn.TextSize = 11
		btn.TextColor3 = CONFIG.THEME.text
		btn.Font = Enum.Font.GothamMedium
		btn.Parent = fixtureSel
		createCorner(btn, 6)
		fixtureButtons[fixture] = btn
	end

	-- Tab Navigation (Below Header)
	local TABS = {"Power", "Colors", "Cues", "Motion", "Beam", "Presets"}
	local tabNav = Instance.new("Frame")
	tabNav.Size = UDim2.new(1, -24, 0, 32)
	tabNav.Position = UDim2.new(0, 12, 0, 56)
	tabNav.BackgroundTransparency = 1
	tabNav.Parent = mainPanel

	local tabLayout = Instance.new("UIListLayout")
	tabLayout.FillDirection = Enum.FillDirection.Horizontal
	tabLayout.Padding = UDim.new(0, 6)
	tabLayout.Parent = tabNav

	local tabButtons = {}
	for i, tabName in ipairs(TABS) do
		local btn = Instance.new("TextButton")
		btn.Size = UDim2.new(0, 96, 1, 0)
		btn.BackgroundColor3 = tabName == State.currentTab and CONFIG.THEME.primary or CONFIG.THEME.card
		btn.BorderSizePixel = 0
		btn.Text = tabName
		btn.TextSize = 11
		btn.TextColor3 = CONFIG.THEME.text
		btn.Font = Enum.Font.GothamMedium
		btn.Parent = tabNav
		createCorner(btn, 6)
		tabButtons[tabName] = btn
	end

	-- Content Area
	local contentArea = Instance.new("Frame")
	contentArea.Size = UDim2.new(1, -24, 1, -110)
	contentArea.Position = UDim2.new(0, 12, 0, 98)
	contentArea.BackgroundTransparency = 1
	contentArea.Parent = mainPanel
	local tabs = {}

	-- POWER TAB
	local powerTab = createScrollingFrame(contentArea, "PowerTab") tabs["Power"] = powerTab
	createSectionHeader(powerTab, "QUICK ACTIONS", 1)
	local quickGrid = Instance.new("Frame") quickGrid.Size = UDim2.new(1, 0, 0, 80) quickGrid.BackgroundTransparency = 1 quickGrid.LayoutOrder = 2 quickGrid.Parent = powerTab
	createGridLayout(quickGrid, UDim2.new(0, 160, 0, 36))
	for i, act in ipairs(CONFIG.QUICK_ACTIONS) do
		local frame = Instance.new("Frame") frame.BackgroundTransparency = 1 frame.Parent = quickGrid
		createActionButton(frame, act.emoji .. " " .. act.name, CONFIG.THEME.secondary, nil, nil, function() fire(State.currentFixture, act.cmd) end)
	end
	createSectionHeader(powerTab, "CONTROLS", 3)
	createSlider(powerTab, "☀️ Brightness", 0, 100, 100, "%", function(val) State.brightness = val / 100 fire(State.currentFixture, "Dimness", 1 - State.brightness) end, 4)
	createSlider(powerTab, "⚡ Cue Speed", 0.1, 3, 1, "x", function(val) State.cueSpeed = val fire(State.currentFixture, "CueSpeed", val) end, 5)
	createSlider(powerTab, "🌈 Fade Speed", 0.1, 3, 1, "x", function(val) State.fadeSpeed = val fire(State.currentFixture, "FadeSpeed", val) end, 6)
	createSectionHeader(powerTab, "TOGGLES", 7)
	createToggle(powerTab, "🎨 Smooth Color", false, function(en) State.smoothColor = en fire(State.currentFixture, "SmoothColor", en) end, 8)
	createToggle(powerTab, "🔁 Loop Cues", false, function(en) State.loopCues = en fire(State.currentFixture, "LoopCues", en) end, 9)
	createToggle(powerTab, "✨ Animated Gradients", false, function(en) State.animatedGradients = en fire(State.currentFixture, "AnimatedGradients", en) end, 10)
	createSectionHeader(powerTab, "AUTO MODE", 11)
	local _, getAutoMode, setAutoModeToggle = createToggle(powerTab, "🤖 Auto Mode", true, function(en) State.autoMode = en end, 12)
	local _, getMusicSync = createToggle(powerTab, "🎵 Music Sync", true, function(en) State.musicSync = en end, 13)

	-- COLORS TAB
	local colorsTab = createScrollingFrame(contentArea, "ColorsTab") colorsTab.Visible = false tabs["Colors"] = colorsTab
	createSectionHeader(colorsTab, "COLOR SELECTION", 1)
	local colorGrid = Instance.new("Frame") colorGrid.Size = UDim2.new(1, 0, 0, 160) colorGrid.BackgroundTransparency = 1 colorGrid.LayoutOrder = 2 colorGrid.Parent = colorsTab
	createGridLayout(colorGrid, UDim2.new(0, 48, 0, 48))
	for i, col in ipairs(CONFIG.COLORS) do
		local btn = Instance.new("TextButton") btn.BackgroundColor3 = col.color btn.Text = "" btn.Parent = colorGrid createCorner(btn, 8)
		btn.MouseButton1Click:Connect(function() fire(State.currentFixture, "Color", col.color, State.colorSelector) end)
		btn.MouseButton2Click:Connect(function() fire(State.currentFixture, "SetGlobalCueSetting", "SecondaryColor", col.color) end)
	end
	createSectionHeader(colorsTab, "COLOR CUES", 3)
	local colCueGrid = Instance.new("Frame") colCueGrid.Size = UDim2.new(1, 0, 0, 40) colCueGrid.BackgroundTransparency = 1 colCueGrid.LayoutOrder = 4 colCueGrid.Parent = colorsTab
	createGridLayout(colCueGrid, UDim2.new(0, 128, 0, 36))
	for i, cue in ipairs(CONFIG.COLOR_CUES) do createCueButton(colCueGrid, cue, function(data, act) fire(State.currentFixture, "Cue", data.cue, act) end) end

	-- CUES TAB
	local cuesTab = createScrollingFrame(contentArea, "CuesTab") cuesTab.Visible = false tabs["Cues"] = cuesTab
	createSectionHeader(cuesTab, "STATE CUES", 1)
	local stateGrid = Instance.new("Frame") stateGrid.Size = UDim2.new(1, 0, 0, 120) stateGrid.BackgroundTransparency = 1 stateGrid.LayoutOrder = 2 stateGrid.Parent = cuesTab
	createGridLayout(stateGrid, UDim2.new(0, 106, 0, 32))
	for i, cue in ipairs(CONFIG.STATE_CUES) do createCueButton(stateGrid, cue, function(data, act) fire(State.currentFixture, "Cue", data.cue, act) end) end
	createSectionHeader(cuesTab, "EFFECT CUES", 3)
	local fxGrid = Instance.new("Frame") fxGrid.Size = UDim2.new(1, 0, 0, 40) fxGrid.BackgroundTransparency = 1 fxGrid.LayoutOrder = 4 fxGrid.Parent = cuesTab
	createGridLayout(fxGrid, UDim2.new(0, 160, 0, 36))
	for i, cue in ipairs(CONFIG.EFFECT_CUES) do createCueButton(fxGrid, cue, function(data, act) fire(State.currentFixture, "Cue", data.cue, act) end) end

	-- MOTION TAB
	local motionTab = createScrollingFrame(contentArea, "MotionTab") motionTab.Visible = false tabs["Motion"] = motionTab
	createSectionHeader(motionTab, "POSITION CONTROLS", 1)
	createSlider(motionTab, "↔️ Pan", -360, 360, 0, "°", function(val) fire(State.currentFixture, "Pan", val, State.colorSelector) end, 2)
	createSlider(motionTab, "↕️ Tilt", -180, 180, 0, "°", function(val) fire(State.currentFixture, "Tilt", val, State.colorSelector) end, 3)
	createSectionHeader(motionTab, "MOTOR SPEED", 4)
	local motorGrid = Instance.new("Frame") motorGrid.Size = UDim2.new(1, 0, 0, 40) motorGrid.BackgroundTransparency = 1 motorGrid.LayoutOrder = 5 motorGrid.Parent = motionTab
	createGridLayout(motorGrid, UDim2.new(0, 128, 0, 36))
	local motorBtns = {}
	for i, speed in ipairs(CONFIG.MOTOR_SPEEDS) do
		local frame = Instance.new("Frame") frame.BackgroundTransparency = 1 frame.Parent = motorGrid
		local btn = createActionButton(frame, speed.label, CONFIG.THEME.secondary, nil, nil, function()
			fire(State.currentFixture, "MotorSpeed", speed.speed)
			for n, b in pairs(motorBtns) do createTween(b, {BackgroundColor3 = n == speed.name and CONFIG.THEME.primary or CONFIG.THEME.secondary}):Play() end
		end) motorBtns[speed.name] = btn
	end
	createSectionHeader(motionTab, "POSITION CUES", 6)
	local posGrid = Instance.new("Frame") posGrid.Size = UDim2.new(1, 0, 0, 80) posGrid.BackgroundTransparency = 1 posGrid.LayoutOrder = 7 posGrid.Parent = motionTab
	createGridLayout(posGrid, UDim2.new(0, 214, 0, 36))
	for i, cue in ipairs(CONFIG.POSITION_CUES) do createCueButton(posGrid, cue, function(data, act) fire(State.currentFixture, "Cue", data.cue, act) end) end

	-- BEAM TAB
	local beamTab = createScrollingFrame(contentArea, "BeamTab") beamTab.Visible = false tabs["Beam"] = beamTab
	createSectionHeader(beamTab, "BEAM MODE", 1)
	local modeGrid = Instance.new("Frame") modeGrid.Size = UDim2.new(1, 0, 0, 40) modeGrid.BackgroundTransparency = 1 modeGrid.LayoutOrder = 2 modeGrid.Parent = beamTab
	createGridLayout(modeGrid, UDim2.new(0, 214, 0, 36))
	local modeBtns = {}
	for i, mode in ipairs(CONFIG.BEAM_MODES) do
		local frame = Instance.new("Frame") frame.BackgroundTransparency = 1 frame.Parent = modeGrid
		local btn = createActionButton(frame, mode.label, mode.mode == "Beam" and CONFIG.THEME.primary or CONFIG.THEME.secondary, nil, nil, function()
			fire(State.currentFixture, "BeamMode", mode.mode)
			for n, b in pairs(modeBtns) do createTween(b, {BackgroundColor3 = n == mode.mode and CONFIG.THEME.primary or CONFIG.THEME.secondary}):Play() end
		end) modeBtns[mode.mode] = btn
	end
	createSectionHeader(beamTab, "BEAM SETTINGS", 3)
	createSlider(beamTab, "💫 Beam Thickness", 0, 100, 50, "%", function(val) fire(State.currentFixture, "BeamThickness", val / 100) end, 4)
	createSlider(beamTab, "🎭 Gobo Spread", 5, 300, 50, "", function(val) fire(State.currentFixture, "GoboSpread", val) end, 5)

	-- PRESETS TAB
	local presetsTab = createScrollingFrame(contentArea, "PresetsTab") presetsTab.Visible = false tabs["Presets"] = presetsTab
	createSectionHeader(presetsTab, "LIGHT PRESETS", 1)
	for i, pre in ipairs(CONFIG.PRESETS) do
		local card = Instance.new("TextButton") card.Size = UDim2.new(1, 0, 0, 50) card.BackgroundColor3 = CONFIG.THEME.card card.BorderSizePixel = 0 card.Text = "" card.LayoutOrder = i + 1 card.Parent = presetsTab createCorner(card, 6)
		local title = Instance.new("TextLabel") title.Size = UDim2.new(0.8, 0, 0.5, 0) title.Position = UDim2.new(0, 16, 0.1, 0) title.BackgroundTransparency = 1 title.Text = pre.name title.TextColor3 = CONFIG.THEME.text title.TextSize = 13 title.Font = Enum.Font.GothamBold title.TextXAlignment = Enum.TextXAlignment.Left title.Parent = card
		local desc = Instance.new("TextLabel") desc.Size = UDim2.new(0.8, 0, 0.4, 0) desc.Position = UDim2.new(0, 16, 0.5, 0) desc.BackgroundTransparency = 1 desc.Text = pre.desc desc.TextColor3 = CONFIG.THEME.textDim desc.TextSize = 10 desc.Font = Enum.Font.Gotham title.TextXAlignment = Enum.TextXAlignment.Left desc.TextXAlignment = Enum.TextXAlignment.Left desc.Parent = card
		card.MouseButton1Click:Connect(function() pre.actions(fire, State.currentFixture) end)
	end

	-- Beat Indicator
	local beatBar = Instance.new("Frame") beatBar.Size = UDim2.new(1, 0, 0, 4) beatBar.Position = UDim2.new(0, 0, 1, -8) beatBar.BackgroundColor3 = CONFIG.THEME.backgroundAlt beatBar.BorderSizePixel = 0 beatBar.Parent = mainPanel createCorner(beatBar, 2)
	local beatFill = Instance.new("Frame") beatFill.Size = UDim2.new(0, 0, 1, 0) beatFill.BackgroundColor3 = CONFIG.THEME.success beatFill.BorderSizePixel = 0 beatFill.Parent = beatBar createCorner(beatFill, 2)

	return {
		gui = gui, mainPanel = mainPanel, header = header, closeBtn = closeBtn,
		fixtureButtons = fixtureButtons, tabButtons = tabButtons, tabs = tabs,
		beatFill = beatFill, getAutoMode = getAutoMode, getMusicSync = getMusicSync,
		setAutoModeToggle = setAutoModeToggle
	}
end

local UI = buildUI()
UI.gui.Parent = playerGui
local scaler = ScaleSystem.new(UI.gui)

local glightsIcon = Icon.new()
glightsIcon:setImage("rbxassetid://14438678142")
glightsIcon:setCaption("Light Controller (Dev Only)")
glightsIcon:setRight()
glightsIcon:setOrder(3)

glightsIcon.selected:Connect(function() State.panelOpen = true UI.mainPanel.Visible = true end)
glightsIcon.deselected:Connect(function() State.panelOpen = false UI.mainPanel.Visible = false end)
UI.closeBtn.MouseButton1Click:Connect(function() glightsIcon:deselect() end)

for fixture, btn in pairs(UI.fixtureButtons) do
	btn.MouseButton1Click:Connect(function()
		State.currentFixture = fixture
		for f, b in pairs(UI.fixtureButtons) do
			b.BackgroundColor3 = f == fixture and CONFIG.THEME.primary or CONFIG.THEME.secondary
		end
	end)
end

for tabName, btn in pairs(UI.tabButtons) do
	btn.MouseButton1Click:Connect(function()
		State.currentTab = tabName
		for name, b in pairs(UI.tabButtons) do
			b.BackgroundColor3 = name == tabName and CONFIG.THEME.primary or CONFIG.THEME.card
		end
		for name, tab in pairs(UI.tabs) do
			tab.Visible = (name == tabName)
		end
	end)
end

local dragging = false
local dragStart, startPos
UI.header.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		dragging = true dragStart = input.Position startPos = UI.mainPanel.Position
	end
end)
UI.header.InputEnded:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then dragging = false end
end)
UserInputService.InputChanged:Connect(function(input)
	if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
		local delta = input.Position - dragStart
		UI.mainPanel.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
	end
end)

local function detectBeat(loud)
	table.insert(State.beatHistory, loud)
	if #State.beatHistory > 15 then table.remove(State.beatHistory, 1) end
	local avg = 0 for _, v in ipairs(State.beatHistory) do avg = avg + v end
	avg = avg / math.max(#State.beatHistory, 1)
	local now = tick()
	local threshold = math.max(25, avg * 0.25)
	if loud - State.lastLoud > threshold and loud > avg * 1.15 and now - State.lastBeat > 0.08 then
		State.lastBeat = now return true
	end
	return false
end

local updateThrottle = 0
local fireThrottle = 0

-- MENGGUNAKAN HEARTBEAT AGAR TETAP JALAN MESKIPUN PLAYER TIDAK BERGERAK
RunService.Heartbeat:Connect(function(dt)
	updateThrottle = updateThrottle + dt
	fireThrottle = fireThrottle + dt

	local totalLoud, count = 0, 0
	for _, sound in pairs(workspace:GetDescendants()) do
		if sound:IsA("Sound") and sound.IsPlaying then
			totalLoud = totalLoud + sound.PlaybackLoudness
			count = count + 1
		end
	end

	local loud = count > 0 and totalLoud / count or 0
	local beat = detectBeat(loud)

	if updateThrottle > 0.03 then
		updateThrottle = 0
		local pct = math.clamp(loud / 500, 0, 1)
		createTween(UI.beatFill, {Size = UDim2.new(pct, 0, 1, 0)}, 0.06):Play()
	end

	if State.autoMode and State.musicSync and fireThrottle > 0.05 then
		fireThrottle = 0
		local intensity = math.clamp(loud / 400, 0, 1)

		if beat then
			fire(State.currentFixture, "Dimness", 0)
			State.autoHue = (State.autoHue + 0.06) % 1
			fire(State.currentFixture, "Color", Color3.fromHSV(State.autoHue, 0.85, 1))
			if loud > 300 then
				fire(State.currentFixture, "BeamThickness", math.random(30, 90) / 100)
			end
		else
			local dim = math.clamp(0.5 - intensity * 0.35, 0.1, 0.7)
			fire(State.currentFixture, "Dimness", dim)
		end

		if loud > 150 then
			fire(State.currentFixture, "MotorSpeed", math.clamp(intensity * 0.02, 0.002, 0.03))
		end
	end
	State.lastLoud = loud
end)

task.defer(function()
	task.wait(1.5)
	for _, fixture in ipairs(CONFIG.ALL_FIXTURES) do
		Bridges.GLightsRun:Fire(fixture, "On")
	end
	task.wait(0.5)
	local partyPreset = CONFIG.PRESETS[1]
	if partyPreset and partyPreset.actions then
		partyPreset.actions(fire, "All")
		State.partyModeActive = true
	end
end)

local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local SCREEN_FOLDER_NAME = "StageScreens"
local TEMPLATE_NAME = "ScreenTemplate"
local CAMERA_OFFSET = Vector3.new(0, 1.5, 10)

local screenTemplate = ReplicatedStorage:WaitForChild(TEMPLATE_NAME)
local screenFolder = Workspace:WaitForChild(SCREEN_FOLDER_NAME)

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local activeScreens = {}

-- ==========================================
-- ATTACH SCREEN
-- ==========================================

local function attachScreenToPart(part)
    if not part:IsA("BasePart") then return end
    
    for _, screenData in pairs(activeScreens) do
        if screenData.Part == part then return end
    end
    
    local newGui = screenTemplate:Clone()
    newGui.Adornee = part
    newGui.Parent = playerGui
    newGui.Enabled = true
    newGui.Name = "LiveGui_" .. part.Name
    
    local viewport = newGui:FindFirstChild("View3D", true)
    if viewport then
        local cam = Instance.new("Camera")
        cam.Parent = viewport
        viewport.CurrentCamera = cam
        
        table.insert(activeScreens, {
        Gui = newGui,
        Viewport = viewport,
        Clone = nil,
        Cam = cam,
        Part = part
        })
    else
        warn("View3D tidak ditemukan di ScreenTemplate!")
    end
end

local function initScreens()
    for _, part in pairs(screenFolder:GetChildren()) do
        attachScreenToPart(part)
    end
    
    screenFolder.ChildAdded:Connect(function(child)
        task.wait(0.1)
        attachScreenToPart(child)
    end)
end

-- ==========================================
-- SETUP DISPLAY DIRI SENDIRI
-- ==========================================

local function setupSelfDisplay()
    -- Tunggu karakter spawn
    local character = player.Character or player.CharacterAdded:Wait()
    local humanoidRoot = character:WaitForChild("HumanoidRootPart")
    
    character.Archivable = true
    
    for _, screenData in pairs(activeScreens) do
        -- Destroy clone lama kalau ada
        if screenData.Clone then
            screenData.Clone:Destroy()
            screenData.Clone = nil
        end
        
        local worldModel = screenData.Viewport:FindFirstChild("WorldModel")
        if not worldModel then
            worldModel = Instance.new("WorldModel")
            worldModel.Name = "WorldModel"
            worldModel.Parent = screenData.Viewport
        else
            worldModel:ClearAllChildren()
        end
        
        local newClone = character:Clone()
        if newClone and newClone.PrimaryPart then
            newClone.Name = "VisualizerActor"
            
            -- Bersihkan script/sound/tool
            for _, item in pairs(newClone:GetDescendants()) do
                if item:IsA("Script") or item:IsA("LocalScript") or item:IsA("Sound") or item:IsA("Tool") then
                    item:Destroy()
                end
            end
            
            newClone.Parent = worldModel
            newClone:PivotTo(CFrame.new(Vector3.zero) * CFrame.Angles(0, math.pi, 0))
            
            -- Kamera
            screenData.Cam.CFrame = CFrame.lookAt(CAMERA_OFFSET, Vector3.zero)
            
            -- Highlight
            local hl = Instance.new("Highlight")
            hl.FillTransparency = 1
            hl.OutlineColor = Color3.new(1, 1, 1)
            hl.OutlineTransparency = 0
            hl.Parent = newClone
            
            screenData.Clone = newClone
        end
    end
end

-- ==========================================
-- UPDATE LOOP (copy animasi)
-- ==========================================

RunService.RenderStepped:Connect(function()
    local character = player.Character
    if not character then return end
    
    local realRoot = character:FindFirstChild("HumanoidRootPart")
    if not realRoot then return end
    
    for _, screenData in pairs(activeScreens) do
        local clone = screenData.Clone
        if clone and clone.PrimaryPart then
            
            -- Copy animasi Motor6D
            for _, originalMotor in pairs(character:GetDescendants()) do
                if originalMotor:IsA("Motor6D") then
                    local cloneMotor = clone:FindFirstChild(originalMotor.Name, true)
                    if cloneMotor and cloneMotor:IsA("Motor6D") then
                        cloneMotor.Transform = originalMotor.Transform
                    end
                end
            end
            
            -- Tetap hadap kamera (Static)
            clone:PivotTo(CFrame.new(Vector3.zero) * CFrame.Angles(0, math.pi, 0))
        end
    end
end)

-- ==========================================
-- INIT
-- ==========================================

initScreens()

-- Setup saat character spawn/respawn
player.CharacterAdded:Connect(function()
    task.wait(0.5) -- tunggu character fully loaded
    setupSelfDisplay()
end)

-- Setup langsung kalau character sudah ada
if player.Character then
    task.wait(0.5)
    setupSelfDisplay()
end
