-- Place in: StarterGui > MenuGUI(ScreenGui) > ConfigClient(LocalScript)
-- Dioptimalkan untuk ContentContainer panel 800×460 (konten ~784×398px)
-- ========================================

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Modules = ReplicatedStorage:WaitForChild("Modules")  
local SoundService = game:GetService("SoundService")
local MenuConfig  = require(Modules:WaitForChild("MenuConfig"))
local ThemeModule = require(Modules:WaitForChild("ThemeModule"))

-- ========================================
-- TUNGGU PENGATURAN PAGE DULU
-- ========================================
repeat task.wait() until MenuConfig.GUI.PengaturanPage or MenuConfig.GUI.ConfigPage

local Players = MenuConfig.Services.Players
local TweenService = MenuConfig.Services.TweenService
local UserInputService = MenuConfig.Services.UserInputService
local ReplicatedStorage = MenuConfig.Services.ReplicatedStorage
local GuiService = game:GetService("GuiService")
local TextChatService = game:GetService("TextChatService")
local Lighting = game:GetService("Lighting")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer

-- Gunakan PengaturanPage atau ConfigPage (backward compatibility)
local configPage = MenuConfig.GUI.PengaturanPage or MenuConfig.GUI.ConfigPage

local CONFIG = MenuConfig.GetConfig()

-- ========================================
-- START THEME GRADIENT SYSTEM
-- ========================================
ThemeModule.GradientSystem.Start()

-- ========================================
-- UKURAN KONSTAN (Optimized for 800×460 panel)
-- ========================================
local SIZES = {
	-- Section Header
	SECTION_H = 28,
	SECTION_TEXT = 13,

	-- Toggle Items
	TOGGLE_H = 60,
	TOGGLE_LABEL_TEXT = 14,
	TOGGLE_DESC_TEXT = 11,
	TOGGLE_WIDTH = 50,
	TOGGLE_HEIGHT = 26,
	TOGGLE_KNOB = 22,

	-- Slider Items
	SLIDER_H = 70,
	SLIDER_LABEL_TEXT = 14,
	SLIDER_VALUE_TEXT = 13,
	SLIDER_BAR_H = 10,
	SLIDER_KNOB = 22,
	SLIDER_VALUE_W = 55,

	-- Button
	BUTTON_H = 48,
	BUTTON_TEXT = 14,

	-- General
	CORNER_SM = 6,
	CORNER_MD = 8,
	CORNER_LG = 10,
	SPACING = 8,
	SCROLL_PAD = 8,
	ITEM_PAD = 12,
}

-- ========================================
-- NOTIF MODULE (NON-BLOCKING)
-- ========================================
local NotifModule = nil
local useCustomNotif = false

local function showNotification(notifType, title, text, duration)
	duration = duration or 2

	if useCustomNotif and NotifModule then
		local success = pcall(function()
			if notifType == "Success" then
				NotifModule.Success(title, text, duration)
			elseif notifType == "Error" then
				NotifModule.Error(title, text, duration)
			elseif notifType == "Warning" then
				NotifModule.Warning(title, text, duration)
			elseif notifType == "Info" then
				NotifModule.Info(title, text, duration)
			elseif notifType == "Settings" then
				NotifModule.Settings(title, text, duration)
			else
				NotifModule.Notify({
					Type = notifType,
					Title = title,
					Text = text,
					Duration = duration
				})
			end
		end)
		if success then return end
	end

	pcall(function()
		game.StarterGui:SetCore("SendNotification", {
			Title = title,
			Text = text,
			Duration = duration
		})
	end)
end

task.spawn(function()
	task.wait(0.5)
	local notifModuleScript = Modules:FindFirstChild("NotifModule")
	if notifModuleScript then
		local success, result = pcall(function()
			return require(notifModuleScript)
		end)
		if success and result then
			NotifModule = result
			useCustomNotif = true
		end
	end
end)

-- ========================================
-- SOUND SYSTEM
-- ========================================
local SoundSystem = {
	ClickSound = nil,
	SoundId = "rbxassetid://139658322785649"
}

function SoundSystem.Setup()
	pcall(function()
		SoundSystem.ClickSound = Instance.new("Sound")
		SoundSystem.ClickSound.Name = "ConfigClickSound"
		SoundSystem.ClickSound.SoundId = SoundSystem.SoundId
		SoundSystem.ClickSound.Volume = 0.5
		SoundSystem.ClickSound.PlaybackSpeed = 1.2
		SoundSystem.ClickSound.Parent = game:GetService("SoundService")
	end)
end

function SoundSystem.PlayClick()
	pcall(function()
		if SoundSystem.ClickSound then
			SoundSystem.ClickSound:Stop()
			SoundSystem.ClickSound:Play()
		end
	end)
end

SoundSystem.Setup()

-- ========================================
-- REMOTE DATASTORE
-- ========================================
local ConfigRemotes = ReplicatedStorage:FindFirstChild("ConfigRemotes")
if not ConfigRemotes then
	ConfigRemotes = ReplicatedStorage:WaitForChild("ConfigRemotes", 10)
end

local LoadSettingsRemote = ConfigRemotes and ConfigRemotes:FindFirstChild("LoadSettings")
local SaveSettingRemote = ConfigRemotes and ConfigRemotes:FindFirstChild("SaveSetting")
local ResetSettingsRemote = ConfigRemotes and ConfigRemotes:FindFirstChild("ResetSettings")

-- ========================================
-- UI ELEMENT REFERENCES
-- ========================================
local UIElements = {
	sections = {},
	toggles = {},
	sliders = {},
	buttons = {},
	scrollFrame = nil,
}

-- ========================================
-- ACTIVE SLIDER TRACKING
-- ========================================
local activeSlider = nil

-- ========================================
-- PENGATURAN DEFAULT
-- ========================================
local DEFAULT_SETTINGS = {
	hideBubbleChat = false,
	hidePlayerEffects = false,
	hidePlayers = false,
	hideOverhead = false,
	hideShadow = false,
	muteMusic = false,
	musicVolume = 100
}

-- ========================================
-- STATUS PENGATURAN
-- ========================================
local settingsLoaded = false
local userSettings = nil

-- ========================================
-- MUAT PENGATURAN
-- ========================================
local function loadSettings()
	for attempt = 1, 3 do
		if LoadSettingsRemote then
			local success, data = pcall(function()
				return LoadSettingsRemote:InvokeServer()
			end)

			if success and data and type(data) == "table" then
				for key, defaultValue in pairs(DEFAULT_SETTINGS) do
					if data[key] == nil then
						data[key] = defaultValue
					end
				end
				settingsLoaded = true
				return data
			end
		end

		if attempt < 3 then
			task.wait(0.5)
		end
	end

	settingsLoaded = true
	local defaultCopy = {}
	for k, v in pairs(DEFAULT_SETTINGS) do
		defaultCopy[k] = v
	end
	return defaultCopy
end

if not MenuConfig.UserSettings then
	MenuConfig.UserSettings = loadSettings()
end

userSettings = MenuConfig.UserSettings

-- ========================================
-- FUNGSI SINKRONISASI & SIMPAN
-- ========================================
local function syncUserSettings()
	if MenuConfig.UserSettings then
		userSettings = MenuConfig.UserSettings
	end
end

local function saveSetting(settingKey, value)
	if SaveSettingRemote then
		pcall(function()
			SaveSettingRemote:FireServer(settingKey, value)
		end)
	end
end

-- ========================================
-- MUSIC SYSTEM FUNCTIONS
-- ========================================
local function getMusicGroup()
	return SoundService:FindFirstChild("MusicGroup") or SoundService:FindFirstChild("ServerMusicSound")
end

local function setMusicMuted(muted)
	userSettings.muteMusic = muted
	local musicGroup = getMusicGroup()
	if musicGroup then
		if muted then
			musicGroup.Volume = 0
		else
			musicGroup.Volume = (userSettings.musicVolume or 100) / 100
		end
	end
end

local function setMusicVolume(volume)
	userSettings.musicVolume = volume
	local musicGroup = getMusicGroup()
	if musicGroup and not userSettings.muteMusic then
		musicGroup.Volume = volume / 100
	end
end

-- ========================================
-- REFRESH UI TOGGLE STATES
-- ========================================
local function refreshAllUI()
	syncUserSettings()
	local knobPadding = 2

	for _, toggleData in ipairs(UIElements.toggles) do
		local toggleBg = toggleData.toggleBg
		local toggleKnob = toggleData.toggleKnob
		local settingKey = toggleData.settingKey

		if toggleBg and toggleKnob and settingKey then
			local isOn = userSettings[settingKey]
			local targetBgColor = isOn and ThemeModule.Colors.Primary1 or Color3.fromRGB(80, 80, 90)
			local targetKnobPos = isOn 
				and UDim2.new(1, -(SIZES.TOGGLE_KNOB + knobPadding), 0.5, -SIZES.TOGGLE_KNOB/2) 
				or UDim2.new(0, knobPadding, 0.5, -SIZES.TOGGLE_KNOB/2)

			TweenService:Create(toggleBg, TweenInfo.new(0.3, Enum.EasingStyle.Quint), {
				BackgroundColor3 = targetBgColor
			}):Play()
			TweenService:Create(toggleKnob, TweenInfo.new(0.3, Enum.EasingStyle.Quint), {
				Position = targetKnobPos
			}):Play()
		end
	end

	for _, sliderData in ipairs(UIElements.sliders) do
		local sliderFill = sliderData.sliderFill
		local sliderKnob = sliderData.sliderKnob
		local valueLabel = sliderData.valueLabel
		local settingKey = sliderData.settingKey
		local minValue = sliderData.minValue
		local maxValue = sliderData.maxValue

		if sliderFill and sliderKnob and settingKey then
			local value = userSettings[settingKey] or 50
			local progress = (value - minValue) / (maxValue - minValue)

			sliderFill.Size = UDim2.new(progress, 0, 1, 0)
			sliderKnob.Position = UDim2.new(progress, -SIZES.SLIDER_KNOB / 2, 0.5, -SIZES.SLIDER_KNOB / 2)

			if valueLabel then
				valueLabel.Text = tostring(math.floor(value)) .. "%"
			end
		end
	end
end

local function resetAllSettings()
	if ResetSettingsRemote then
		pcall(function()
			ResetSettingsRemote:FireServer()
		end)
	end

	for key, value in pairs(DEFAULT_SETTINGS) do
		userSettings[key] = value
	end

	MenuConfig.UserSettings = userSettings
	refreshAllUI()
end

-- ========================================
-- FUNGSI SISTEM TAMPILAN
-- ========================================

local function setBubbleChatHidden(hide)
	pcall(function()
		local bubbleConfig = TextChatService:FindFirstChild("BubbleChatConfiguration")
		if bubbleConfig then
			bubbleConfig.Enabled = not hide
		end
	end)

	local function updateCharacterBubbles(character)
		if not character then return end
		for _, descendant in pairs(character:GetDescendants()) do
			if descendant:IsA("BillboardGui") then
				if descendant.Name == "BubbleChat" or 
					descendant.Name == "ChatBubble" or 
					string.find(descendant.Name:lower(), "bubble") then
					pcall(function()
						descendant.Enabled = not hide
					end)
				end
			end
		end
	end

	for _, otherPlayer in pairs(Players:GetPlayers()) do
		if otherPlayer.Character then
			updateCharacterBubbles(otherPlayer.Character)
		end
	end

	userSettings.hideBubbleChat = hide
end

local function setCharacterOverheadHidden(character, hide)
	if not character then return end

	local head = character:FindFirstChild("Head")
	if head then
		for _, child in pairs(head:GetDescendants()) do
			if child:IsA("BillboardGui") then
				local name = child.Name:lower()
				if name == "overhead" or name == "titlebillboard" or string.find(name, "title") then
					pcall(function() child.Enabled = not hide end)
				end
			end
		end
	end

	for _, child in pairs(character:GetChildren()) do
		if child:IsA("BillboardGui") then
			local name = child.Name:lower()
			if name == "overhead" or name == "titlebillboard" then
				pcall(function() child.Enabled = not hide end)
			end
		end
	end
end

local function setOverheadHidden(hide)
	userSettings.hideOverhead = hide
	for _, otherPlayer in pairs(Players:GetPlayers()) do
		if otherPlayer.Character then
			setCharacterOverheadHidden(otherPlayer.Character, hide)
		end
	end
end

local function setShadowHidden(hide)
	userSettings.hideShadow = hide
	pcall(function()
		Lighting.GlobalShadows = not hide
	end)
end

local effectTypes = {
	"ParticleEmitter", "Trail", "Beam", "Fire", "Smoke", "Sparkles",
	"PointLight", "SurfaceLight", "SpotLight"
}

local function setCharacterEffectsHidden(character, hide)
	if not character then return end
	for _, descendant in pairs(character:GetDescendants()) do
		for _, effectType in ipairs(effectTypes) do
			if descendant:IsA(effectType) then
				pcall(function() descendant.Enabled = not hide end)
			end
		end
	end
end

local function setPlayerEffectsHidden(hide)
	userSettings.hidePlayerEffects = hide
	for _, otherPlayer in pairs(Players:GetPlayers()) do
		if otherPlayer.Character then
			setCharacterEffectsHidden(otherPlayer.Character, hide)
		end
	end
end

local function setCharacterHidden(character, hide)
	if not character then return end
	for _, descendant in pairs(character:GetDescendants()) do
		if descendant:IsA("BasePart") then
			pcall(function() descendant.LocalTransparencyModifier = hide and 1 or 0 end)
		elseif descendant:IsA("Decal") or descendant:IsA("Texture") then
			pcall(function() descendant.Transparency = hide and 1 or 0 end)
		elseif descendant:IsA("BillboardGui") then
			pcall(function() descendant.Enabled = not hide end)
		end
	end
end

local function setPlayersHidden(hide)
	userSettings.hidePlayers = hide
	for _, otherPlayer in pairs(Players:GetPlayers()) do
		if otherPlayer ~= player then
			if otherPlayer.Character then
				setCharacterHidden(otherPlayer.Character, hide)
				if hide then
					setCharacterEffectsHidden(otherPlayer.Character, true)
				elseif not userSettings.hidePlayerEffects then
					setCharacterEffectsHidden(otherPlayer.Character, false)
				end
			end
		end
	end
end

-- ========================================
-- SETUP CHARACTER MONITOR
-- ========================================
local function setupCharacter(targetPlayer, character)
	task.wait(0.5)

	if userSettings.hidePlayerEffects then
		setCharacterEffectsHidden(character, true)
	end

	if targetPlayer ~= player and userSettings.hidePlayers then
		setCharacterHidden(character, true)
	end

	if userSettings.hideOverhead then
		setCharacterOverheadHidden(character, true)
	end

	character.DescendantAdded:Connect(function(descendant)
		if userSettings.hidePlayerEffects then
			for _, effectType in ipairs(effectTypes) do
				if descendant:IsA(effectType) then
					pcall(function() descendant.Enabled = false end)
					break
				end
			end
		end

		if userSettings.hideBubbleChat then
			if descendant:IsA("BillboardGui") and 
				(descendant.Name == "BubbleChat" or string.find(descendant.Name:lower(), "bubble")) then
				pcall(function() descendant.Enabled = false end)
			end
		end

		if userSettings.hideOverhead then
			if descendant:IsA("BillboardGui") then
				local name = descendant.Name:lower()
				if name == "overhead" or name == "titlebillboard" then
					pcall(function() descendant.Enabled = false end)
				end
			end
		end

		if targetPlayer ~= player and userSettings.hidePlayers then
			if descendant:IsA("BasePart") then
				pcall(function() descendant.LocalTransparencyModifier = 1 end)
			elseif descendant:IsA("Decal") or descendant:IsA("Texture") then
				pcall(function() descendant.Transparency = 1 end)
			end
		end
	end)
end

local function setupPlayerMonitor()
	for _, targetPlayer in pairs(Players:GetPlayers()) do
		if targetPlayer.Character then
			task.spawn(function()
				setupCharacter(targetPlayer, targetPlayer.Character)
			end)
		end
		targetPlayer.CharacterAdded:Connect(function(character)
			task.spawn(function()
				setupCharacter(targetPlayer, character)
			end)
		end)
	end

	Players.PlayerAdded:Connect(function(targetPlayer)
		targetPlayer.CharacterAdded:Connect(function(character)
			task.spawn(function()
				setupCharacter(targetPlayer, character)
			end)
		end)
	end)
end

task.spawn(function()
	task.wait(1)
	setupPlayerMonitor()
end)

-- ========================================
-- HELPER FUNCTIONS
-- ========================================
local function mk(cls, props, parent)
	local inst = Instance.new(cls)
	for k, v in pairs(props) do inst[k] = v end
	if parent then inst.Parent = parent end
	return inst
end

local function crn(r, f) mk("UICorner", { CornerRadius = UDim.new(0, r) }, f) end

-- ========================================
-- FRAME GULIR KONFIGURASI (AUTO CANVAS)
-- ========================================
local configScroll = mk("ScrollingFrame", {
	Name = "ConfigScroll",
	Size = UDim2.new(1, 0, 1, 0),
	Position = UDim2.new(0, 0, 0, 0),
	BackgroundColor3 = Color3.fromRGB(30, 30, 40),
	BorderSizePixel = 0,
	ScrollBarThickness = 0,
	ScrollBarImageTransparency = 1,
	ScrollingEnabled = true,
	CanvasSize = UDim2.new(0, 0, 0, 0),
	AutomaticCanvasSize = Enum.AutomaticSize.Y,
	ClipsDescendants = true,
	ScrollingDirection = Enum.ScrollingDirection.Y,
	HorizontalScrollBarInset = Enum.ScrollBarInset.None,
	VerticalScrollBarInset = Enum.ScrollBarInset.None,
	ElasticBehavior = Enum.ElasticBehavior.Always,
}, configPage)

crn(SIZES.CORNER_MD, configScroll)

mk("UIListLayout", {
	SortOrder = Enum.SortOrder.LayoutOrder,
	Padding = UDim.new(0, SIZES.SPACING),
}, configScroll)

mk("UIPadding", {
	PaddingTop = UDim.new(0, SIZES.SCROLL_PAD),
	PaddingBottom = UDim.new(0, SIZES.SCROLL_PAD),
	PaddingLeft = UDim.new(0, SIZES.SCROLL_PAD),
	PaddingRight = UDim.new(0, SIZES.SCROLL_PAD),
}, configScroll)

UIElements.scrollFrame = configScroll

-- ========================================
-- UI ELEMENT CREATORS
-- ========================================

local function createSectionHeader(text, layoutOrder)
	local section = mk("Frame", {
		Name = "Section_" .. text:gsub("%s+", ""),
		Size = UDim2.new(1, 0, 0, SIZES.SECTION_H),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		LayoutOrder = layoutOrder,
	}, configScroll)

	local sectionLabel = mk("TextLabel", {
		Name = "Label",
		Text = text,
		Size = UDim2.new(1, -16, 1, 0),
		Position = UDim2.new(0, 8, 0, 0),
		BackgroundTransparency = 1,
		TextColor3 = Color3.fromRGB(255, 255, 255),
		TextSize = SIZES.SECTION_TEXT,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextYAlignment = Enum.TextYAlignment.Center,
		Font = Enum.Font.GothamBold,
	}, section)

	ThemeModule.CreatePrimaryGradient(sectionLabel, 0, 1)

	table.insert(UIElements.sections, {
		element = section,
		labelElement = sectionLabel,
	})

	return section
end

local function createToggleSetting(labelText, description, settingKey, layoutOrder, onToggleCallback)
	local hasDesc = description and description ~= ""
	local toggleTotalWidth = SIZES.TOGGLE_WIDTH + SIZES.ITEM_PAD + 10

	local item = mk("Frame", {
		Name = "Toggle_" .. settingKey,
		Size = UDim2.new(1, 0, 0, SIZES.TOGGLE_H),
		BackgroundColor3 = Color3.fromRGB(40, 40, 50),
		BorderSizePixel = 0,
		LayoutOrder = layoutOrder,
		ClipsDescendants = true,
	}, configScroll)
	crn(SIZES.CORNER_MD, item)

	-- Text Container
	local textContainer = mk("Frame", {
		Name = "TextContainer",
		Size = UDim2.new(1, -toggleTotalWidth, 1, 0),
		Position = UDim2.new(0, 0, 0, 0),
		BackgroundTransparency = 1,
		ClipsDescendants = true,
	}, item)

	local labelYPos = hasDesc and 10 or (SIZES.TOGGLE_H/2 - 10)
	local labelHeight = 20

	local label = mk("TextLabel", {
		Name = "Label",
		Text = labelText,
		Size = UDim2.new(1, -20, 0, labelHeight),
		Position = UDim2.new(0, SIZES.ITEM_PAD, 0, labelYPos),
		BackgroundTransparency = 1,
		TextColor3 = Color3.fromRGB(255, 255, 255),
		TextSize = SIZES.TOGGLE_LABEL_TEXT,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextYAlignment = Enum.TextYAlignment.Center,
		TextTruncate = Enum.TextTruncate.AtEnd,
		Font = Enum.Font.GothamSemibold,
	}, textContainer)

	local desc = nil
	if hasDesc then
		local descYPos = labelYPos + labelHeight + 4
		local descHeight = SIZES.TOGGLE_H - descYPos - 10

		desc = mk("TextLabel", {
			Name = "Description",
			Text = description,
			Size = UDim2.new(1, -20, 0, descHeight),
			Position = UDim2.new(0, SIZES.ITEM_PAD, 0, descYPos),
			BackgroundTransparency = 1,
			TextColor3 = Color3.fromRGB(140, 140, 150),
			TextSize = SIZES.TOGGLE_DESC_TEXT,
			TextXAlignment = Enum.TextXAlignment.Left,
			TextYAlignment = Enum.TextYAlignment.Top,
			TextTruncate = Enum.TextTruncate.AtEnd,
			TextWrapped = true,
			Font = Enum.Font.Gotham,
		}, textContainer)
	end

	local isOn = userSettings[settingKey]

	-- Toggle Background
	local toggleBg = mk("Frame", {
		Name = "ToggleBg",
		Size = UDim2.new(0, SIZES.TOGGLE_WIDTH, 0, SIZES.TOGGLE_HEIGHT),
		Position = UDim2.new(1, -(SIZES.TOGGLE_WIDTH + SIZES.ITEM_PAD), 0.5, -SIZES.TOGGLE_HEIGHT/2),
		BackgroundColor3 = isOn and ThemeModule.Colors.Primary1 or Color3.fromRGB(80, 80, 90),
		BorderSizePixel = 0,
	}, item)
	crn(SIZES.TOGGLE_HEIGHT/2, toggleBg)

	if isOn then
		ThemeModule.CreatePrimaryGradient(toggleBg, 0, 1.2)
	end

	-- Toggle Knob
	local knobPadding = 2
	local toggleKnob = mk("Frame", {
		Name = "Knob",
		Size = UDim2.new(0, SIZES.TOGGLE_KNOB, 0, SIZES.TOGGLE_KNOB),
		Position = isOn 
			and UDim2.new(1, -(SIZES.TOGGLE_KNOB + knobPadding), 0.5, -SIZES.TOGGLE_KNOB/2) 
			or UDim2.new(0, knobPadding, 0.5, -SIZES.TOGGLE_KNOB/2),
		BackgroundColor3 = Color3.fromRGB(255, 255, 255),
		BorderSizePixel = 0,
	}, toggleBg)
	crn(SIZES.TOGGLE_KNOB/2, toggleKnob)

	-- Toggle Button
	local toggleBtn = mk("TextButton", {
		Name = "ToggleBtn",
		Text = "",
		Size = UDim2.new(1, 0, 1, 0),
		BackgroundTransparency = 1,
	}, toggleBg)

	table.insert(UIElements.toggles, {
		element = item,
		textContainer = textContainer,
		label = label,
		description = desc,
		toggleBg = toggleBg,
		toggleKnob = toggleKnob,
		settingKey = settingKey
	})

	toggleBtn.MouseButton1Click:Connect(function()
		SoundSystem.PlayClick()

		userSettings[settingKey] = not userSettings[settingKey]
		local currentIsOn = userSettings[settingKey]

		local existingGradient = toggleBg:FindFirstChildOfClass("UIGradient")
		if currentIsOn then
			if not existingGradient then
				ThemeModule.CreatePrimaryGradient(toggleBg, 0, 1.2)
			end
			toggleBg.BackgroundColor3 = ThemeModule.Colors.Primary1
		else
			if existingGradient then
				ThemeModule.GradientSystem.Unregister(existingGradient)
				existingGradient:Destroy()
			end
			TweenService:Create(toggleBg, TweenInfo.new(0.2, Enum.EasingStyle.Quad), {
				BackgroundColor3 = Color3.fromRGB(80, 80, 90)
			}):Play()
		end

		local targetKnobPos = currentIsOn 
			and UDim2.new(1, -(SIZES.TOGGLE_KNOB + knobPadding), 0.5, -SIZES.TOGGLE_KNOB/2) 
			or UDim2.new(0, knobPadding, 0.5, -SIZES.TOGGLE_KNOB/2)

		TweenService:Create(toggleKnob, TweenInfo.new(0.2, Enum.EasingStyle.Quad), {Position = targetKnobPos}):Play()

		if onToggleCallback then
			onToggleCallback(currentIsOn)
		end

		saveSetting(settingKey, currentIsOn)
		MenuConfig.Events.OnSettingChanged:Fire(settingKey, currentIsOn)
	end)

	-- Hover effects
	item.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseMovement then
			TweenService:Create(item, TweenInfo.new(0.15), {
				BackgroundColor3 = Color3.fromRGB(50, 50, 60)
			}):Play()
		end
	end)

	item.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseMovement then
			TweenService:Create(item, TweenInfo.new(0.15), {
				BackgroundColor3 = Color3.fromRGB(40, 40, 50)
			}):Play()
		end
	end)

	return item
end

-- ========================================
-- SLIDER CREATOR
-- ========================================
local function createSliderSetting(labelText, settingKey, layoutOrder, minValue, maxValue, onValueChanged)
	minValue = minValue or 0
	maxValue = maxValue or 100

	local item = mk("Frame", {
		Name = "Slider_" .. settingKey,
		Size = UDim2.new(1, 0, 0, SIZES.SLIDER_H),
		BackgroundColor3 = Color3.fromRGB(40, 40, 50),
		BorderSizePixel = 0,
		LayoutOrder = layoutOrder,
		ClipsDescendants = true,
	}, configScroll)
	crn(SIZES.CORNER_MD, item)

	-- Label
	local label = mk("TextLabel", {
		Name = "Label",
		Text = labelText,
		Size = UDim2.new(1, -20, 0, 22),
		Position = UDim2.new(0, SIZES.ITEM_PAD, 0, 8),
		BackgroundTransparency = 1,
		TextColor3 = Color3.fromRGB(255, 255, 255),
		TextSize = SIZES.SLIDER_LABEL_TEXT,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextYAlignment = Enum.TextYAlignment.Center,
		TextTruncate = Enum.TextTruncate.AtEnd,
		Font = Enum.Font.GothamSemibold,
	}, item)

	local currentValue = userSettings[settingKey] or (DEFAULT_SETTINGS[settingKey] or 100)
	local progress = (currentValue - minValue) / (maxValue - minValue)
	local sliderY = 38

	-- Value Label
	local valueLabel = mk("TextLabel", {
		Name = "ValueLabel",
		Text = tostring(math.floor(currentValue)) .. "%",
		Size = UDim2.new(0, SIZES.SLIDER_VALUE_W, 0, SIZES.SLIDER_KNOB),
		Position = UDim2.new(1, -(SIZES.SLIDER_VALUE_W + SIZES.ITEM_PAD), 0, sliderY),
		BackgroundTransparency = 1,
		TextColor3 = ThemeModule.Colors.Primary1,
		TextSize = SIZES.SLIDER_VALUE_TEXT,
		TextXAlignment = Enum.TextXAlignment.Right,
		TextYAlignment = Enum.TextYAlignment.Center,
		Font = Enum.Font.GothamBold,
	}, item)

	-- Slider Container
	local sliderContainer = mk("Frame", {
		Name = "SliderContainer",
		Size = UDim2.new(1, -(SIZES.ITEM_PAD * 2 + SIZES.SLIDER_VALUE_W + 10), 0, SIZES.SLIDER_KNOB + 10),
		Position = UDim2.new(0, SIZES.ITEM_PAD, 0, sliderY - 5),
		BackgroundTransparency = 1,
		ClipsDescendants = false,
	}, item)

	-- Slider Background
	local sliderBg = mk("Frame", {
		Name = "SliderBg",
		Size = UDim2.new(1, 0, 0, SIZES.SLIDER_BAR_H),
		Position = UDim2.new(0, 0, 0.5, -SIZES.SLIDER_BAR_H / 2),
		BackgroundColor3 = Color3.fromRGB(60, 60, 70),
		BorderSizePixel = 0,
	}, sliderContainer)
	crn(SIZES.SLIDER_BAR_H / 2, sliderBg)

	-- Slider Fill
	local sliderFill = mk("Frame", {
		Name = "SliderFill",
		Size = UDim2.new(progress, 0, 1, 0),
		Position = UDim2.new(0, 0, 0, 0),
		BackgroundColor3 = ThemeModule.Colors.Primary1,
		BorderSizePixel = 0,
	}, sliderBg)
	crn(SIZES.SLIDER_BAR_H / 2, sliderFill)

	ThemeModule.CreatePrimaryGradient(sliderFill, 0, 0.8)

	-- Slider Knob
	local sliderKnob = mk("Frame", {
		Name = "SliderKnob",
		Size = UDim2.new(0, SIZES.SLIDER_KNOB, 0, SIZES.SLIDER_KNOB),
		Position = UDim2.new(progress, -SIZES.SLIDER_KNOB / 2, 0.5, -SIZES.SLIDER_KNOB / 2),
		BackgroundColor3 = Color3.fromRGB(255, 255, 255),
		BorderSizePixel = 0,
		ZIndex = 2,
	}, sliderBg)
	crn(SIZES.SLIDER_KNOB / 2, sliderKnob)

	-- Knob Glow
	local knobGlow = mk("Frame", {
		Name = "KnobGlow",
		Size = UDim2.new(1, 6, 1, 6),
		Position = UDim2.new(0, -3, 0, -3),
		BackgroundColor3 = ThemeModule.LerpColor(ThemeModule.Colors.Primary1, Color3.new(1,1,1), 0.3),
		BackgroundTransparency = 0.7,
		BorderSizePixel = 0,
		ZIndex = 1,
	}, sliderKnob)
	crn(SIZES.SLIDER_KNOB / 2 + 3, knobGlow)

	-- Slider Hit Area
	local sliderHitArea = mk("TextButton", {
		Name = "SliderHitArea",
		Text = "",
		Size = UDim2.new(1, 0, 1, 0),
		Position = UDim2.new(0, 0, 0, 0),
		BackgroundTransparency = 1,
		ZIndex = 10,
	}, sliderContainer)

	local sliderData = {
		element = item,
		label = label,
		sliderContainer = sliderContainer,
		sliderBg = sliderBg,
		sliderFill = sliderFill,
		sliderKnob = sliderKnob,
		valueLabel = valueLabel,
		settingKey = settingKey,
		minValue = minValue,
		maxValue = maxValue,
		onValueChanged = onValueChanged
	}

	table.insert(UIElements.sliders, sliderData)

	local function updateSliderValue(inputX)
		local sliderAbsPos = sliderBg.AbsolutePosition.X
		local sliderAbsSize = sliderBg.AbsoluteSize.X

		if sliderAbsSize <= 0 then return end

		local relativeX = inputX - sliderAbsPos
		relativeX = math.clamp(relativeX, 0, sliderAbsSize)

		local newProgress = relativeX / sliderAbsSize

		local newValue = math.floor(minValue + (maxValue - minValue) * newProgress + 0.5)
		newValue = math.clamp(newValue, minValue, maxValue)

		userSettings[settingKey] = newValue

		local visualProgress = (newValue - minValue) / (maxValue - minValue)

		sliderFill.Size = UDim2.new(visualProgress, 0, 1, 0)
		sliderKnob.Position = UDim2.new(visualProgress, -SIZES.SLIDER_KNOB / 2, 0.5, -SIZES.SLIDER_KNOB / 2)
		valueLabel.Text = tostring(newValue) .. "%"

		if onValueChanged then
			onValueChanged(newValue)
		end
	end

	local isDragging = false

	sliderHitArea.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or 
			input.UserInputType == Enum.UserInputType.Touch then
			SoundSystem.PlayClick()
			isDragging = true
			activeSlider = sliderData

			updateSliderValue(input.Position.X)

			TweenService:Create(sliderKnob, TweenInfo.new(0.1), {
				Size = UDim2.new(0, SIZES.SLIDER_KNOB + 4, 0, SIZES.SLIDER_KNOB + 4)
			}):Play()
		end
	end)

	sliderHitArea.InputChanged:Connect(function(input)
		if isDragging then
			if input.UserInputType == Enum.UserInputType.MouseMovement or
				input.UserInputType == Enum.UserInputType.Touch then
				updateSliderValue(input.Position.X)
			end
		end
	end)

	sliderHitArea.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or 
			input.UserInputType == Enum.UserInputType.Touch then
			if isDragging then
				isDragging = false
				activeSlider = nil

				saveSetting(settingKey, userSettings[settingKey])
				MenuConfig.Events.OnSettingChanged:Fire(settingKey, userSettings[settingKey])

				TweenService:Create(sliderKnob, TweenInfo.new(0.1), {
					Size = UDim2.new(0, SIZES.SLIDER_KNOB, 0, SIZES.SLIDER_KNOB)
				}):Play()
			end
		end
	end)

	-- Hover effects
	item.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseMovement then
			TweenService:Create(item, TweenInfo.new(0.15), {
				BackgroundColor3 = Color3.fromRGB(50, 50, 60)
			}):Play()
		end
	end)

	item.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseMovement then
			TweenService:Create(item, TweenInfo.new(0.15), {
				BackgroundColor3 = Color3.fromRGB(40, 40, 50)
			}):Play()
		end
	end)

	return item
end

-- ========================================
-- GLOBAL INPUT HANDLER FOR SLIDER DRAGGING
-- ========================================
UserInputService.InputChanged:Connect(function(input, gameProcessed)
	if activeSlider then
		if input.UserInputType == Enum.UserInputType.MouseMovement then
			local mousePos = UserInputService:GetMouseLocation()

			local sliderBg = activeSlider.sliderBg
			local sliderAbsPos = sliderBg.AbsolutePosition.X
			local sliderAbsSize = sliderBg.AbsoluteSize.X

			if sliderAbsSize <= 0 then return end

			local inputX = mousePos.X
			local relativeX = inputX - sliderAbsPos
			relativeX = math.clamp(relativeX, 0, sliderAbsSize)

			local newProgress = relativeX / sliderAbsSize
			local minValue = activeSlider.minValue
			local maxValue = activeSlider.maxValue
			local newValue = math.floor(minValue + (maxValue - minValue) * newProgress + 0.5)
			newValue = math.clamp(newValue, minValue, maxValue)

			userSettings[activeSlider.settingKey] = newValue

			local visualProgress = (newValue - minValue) / (maxValue - minValue)

			activeSlider.sliderFill.Size = UDim2.new(visualProgress, 0, 1, 0)
			activeSlider.sliderKnob.Position = UDim2.new(visualProgress, -SIZES.SLIDER_KNOB / 2, 0.5, -SIZES.SLIDER_KNOB / 2)
			activeSlider.valueLabel.Text = tostring(newValue) .. "%"

			if activeSlider.onValueChanged then
				activeSlider.onValueChanged(newValue)
			end

		elseif input.UserInputType == Enum.UserInputType.Touch then
			local sliderBg = activeSlider.sliderBg
			local sliderAbsPos = sliderBg.AbsolutePosition.X
			local sliderAbsSize = sliderBg.AbsoluteSize.X

			if sliderAbsSize <= 0 then return end

			local inputX = input.Position.X
			local relativeX = inputX - sliderAbsPos
			relativeX = math.clamp(relativeX, 0, sliderAbsSize)

			local newProgress = relativeX / sliderAbsSize
			local minValue = activeSlider.minValue
			local maxValue = activeSlider.maxValue
			local newValue = math.floor(minValue + (maxValue - minValue) * newProgress + 0.5)
			newValue = math.clamp(newValue, minValue, maxValue)

			userSettings[activeSlider.settingKey] = newValue

			local visualProgress = (newValue - minValue) / (maxValue - minValue)

			activeSlider.sliderFill.Size = UDim2.new(visualProgress, 0, 1, 0)
			activeSlider.sliderKnob.Position = UDim2.new(visualProgress, -SIZES.SLIDER_KNOB / 2, 0.5, -SIZES.SLIDER_KNOB / 2)
			activeSlider.valueLabel.Text = tostring(newValue) .. "%"

			if activeSlider.onValueChanged then
				activeSlider.onValueChanged(newValue)
			end
		end
	end
end)

UserInputService.InputEnded:Connect(function(input)
	if activeSlider then
		if input.UserInputType == Enum.UserInputType.MouseButton1 or 
			input.UserInputType == Enum.UserInputType.Touch then

			saveSetting(activeSlider.settingKey, userSettings[activeSlider.settingKey])
			MenuConfig.Events.OnSettingChanged:Fire(activeSlider.settingKey, userSettings[activeSlider.settingKey])

			TweenService:Create(activeSlider.sliderKnob, TweenInfo.new(0.1), {
				Size = UDim2.new(0, SIZES.SLIDER_KNOB, 0, SIZES.SLIDER_KNOB)
			}):Play()

			activeSlider = nil
		end
	end
end)

-- ========================================
-- RESET BUTTON CREATOR
-- ========================================
local function createResetButton(layoutOrder)
	local btn = mk("TextButton", {
		Name = "ResetButton",
		Text = "🔄 RESET PENGATURAN",
		Size = UDim2.new(1, 0, 0, SIZES.BUTTON_H),
		BackgroundColor3 = Color3.fromRGB(200, 80, 80),
		BorderSizePixel = 0,
		TextColor3 = Color3.fromRGB(255, 255, 255),
		TextSize = SIZES.BUTTON_TEXT,
		Font = Enum.Font.GothamBold,
		LayoutOrder = layoutOrder,
		ClipsDescendants = true,
	}, configScroll)
	crn(SIZES.CORNER_MD, btn)

	table.insert(UIElements.buttons, {
		element = btn,
	})

	btn.MouseButton1Click:Connect(function()
		SoundSystem.PlayClick()

		resetAllSettings()

		setBubbleChatHidden(DEFAULT_SETTINGS.hideBubbleChat)
		setPlayerEffectsHidden(DEFAULT_SETTINGS.hidePlayerEffects)
		setPlayersHidden(DEFAULT_SETTINGS.hidePlayers)
		setOverheadHidden(DEFAULT_SETTINGS.hideOverhead)
		setShadowHidden(DEFAULT_SETTINGS.hideShadow)

		setMusicMuted(DEFAULT_SETTINGS.muteMusic)
		setMusicVolume(DEFAULT_SETTINGS.musicVolume)

		showNotification("Warning", "🔄 Reset Pengaturan", "Semua pengaturan dikembalikan!", 3)
	end)

	btn.MouseEnter:Connect(function()
		TweenService:Create(btn, TweenInfo.new(0.15), {
			BackgroundColor3 = Color3.fromRGB(220, 100, 100)
		}):Play()
	end)

	btn.MouseLeave:Connect(function()
		TweenService:Create(btn, TweenInfo.new(0.15), {
			BackgroundColor3 = Color3.fromRGB(200, 80, 80)
		}):Play()
	end)

	return btn
end

-- ========================================
-- BANGUN UI KONFIGURASI
-- ========================================

-- SECTION 1: PENGATURAN TAMPILAN
createSectionHeader("PENGATURAN TAMPILAN", 1)

createToggleSetting("💬 Sembunyikan Bubble Chat", "Menyembunyikan chat bubble pemain lain", "hideBubbleChat", 2, function(isHidden)
	setBubbleChatHidden(isHidden)
	showNotification("Settings", "💬 Bubble Chat", isHidden and "Disembunyikan" or "Ditampilkan", 2)
end)

createToggleSetting("✨ Sembunyikan Efek Pemain", "Menyembunyikan efek visual pemain lain", "hidePlayerEffects", 3, function(isHidden)
	setPlayerEffectsHidden(isHidden)
	showNotification("Settings", "✨ Efek Pemain", isHidden and "Disembunyikan" or "Ditampilkan", 2)
end)

createToggleSetting("👥 Sembunyikan Pemain Lain", "Menyembunyikan pemain lain dari pandangan", "hidePlayers", 4, function(isHidden)
	setPlayersHidden(isHidden)
	showNotification("Settings", "👥 Pemain Lain", isHidden and "Disembunyikan" or "Ditampilkan", 2)
end)

createToggleSetting("🏷️ Sembunyikan Overhead", "Menyembunyikan nama & title pemain", "hideOverhead", 5, function(isHidden)
	setOverheadHidden(isHidden)
	showNotification("Settings", "🏷️ Overhead", isHidden and "Disembunyikan" or "Ditampilkan", 2)
end)

createToggleSetting("🌑 Sembunyikan Bayangan", "Mematikan bayangan global game", "hideShadow", 6, function(isHidden)
	setShadowHidden(isHidden)
	showNotification("Settings", "🌑 Bayangan", isHidden and "Dimatikan" or "Dinyalakan", 2)
end)

-- SECTION 2: PENGATURAN MUSIK
createSectionHeader("PENGATURAN MUSIK", 10)

createToggleSetting("🔇 Bisukan Musik", "Mematikan suara musik sepenuhnya", "muteMusic", 11, function(isMuted)
	setMusicMuted(isMuted)
	showNotification("Settings", "🔇 Musik", isMuted and "Dibisukan" or "Diaktifkan", 2)
end)

createSliderSetting("🔊 Volume Musik", "musicVolume", 12, 0, 100, function(volume)
	setMusicVolume(volume)
end)

-- RESET BUTTON
createResetButton(20)

-- ========================================
-- REGISTER CONTENT UPDATE CALLBACK
-- ========================================
MenuConfig.RegisterContentUpdateCallback("ConfigClient", function()
	-- No need to update sizes, we use fixed sizes now
end)

-- ========================================
-- EVENT LISTENERS
-- ========================================
MenuConfig.Events.OnMenuToggled.Event:Connect(function(isOpen)
	if isOpen and MenuConfig.State.currentMainTab == "Pengaturan" then
		task.wait(0.1)
		refreshAllUI()
	end
end)

MenuConfig.Events.OnTabChanged.Event:Connect(function(tab)
	if tab == "Pengaturan" then
		task.wait(0.1)
		refreshAllUI()
	end
end)

-- ========================================
-- TERAPKAN PENGATURAN SAAT MULAI
-- ========================================
task.spawn(function()
	task.wait(1)

	setBubbleChatHidden(userSettings.hideBubbleChat)
	setPlayerEffectsHidden(userSettings.hidePlayerEffects)
	setPlayersHidden(userSettings.hidePlayers)
	setOverheadHidden(userSettings.hideOverhead)
	setShadowHidden(userSettings.hideShadow)

	setMusicMuted(userSettings.muteMusic)
	setMusicVolume(userSettings.musicVolume)
end)

-- ========================================
-- LISTEN FOR MUSIC SETTING CHANGES
-- ========================================
MenuConfig.Events.OnSettingChanged.Event:Connect(function(key, value)
	if key == "musicVolume" then
		for _, sliderData in ipairs(UIElements.sliders) do
			if sliderData.settingKey == "musicVolume" then
				local progress = value / 100

				sliderData.sliderFill.Size = UDim2.new(progress, 0, 1, 0)
				sliderData.sliderKnob.Position = UDim2.new(progress, -SIZES.SLIDER_KNOB / 2, 0.5, -SIZES.SLIDER_KNOB / 2)
				sliderData.valueLabel.Text = tostring(math.floor(value)) .. "%"
				break
			end
		end
	elseif key == "muteMusic" then
		for _, toggleData in ipairs(UIElements.toggles) do
			if toggleData.settingKey == "muteMusic" then
				local knobPadding = 2
				local toggleBg = toggleData.toggleBg

				local existingGradient = toggleBg:FindFirstChildOfClass("UIGradient")
				if value then
					if not existingGradient then
						ThemeModule.CreatePrimaryGradient(toggleBg, 0, 1.2)
					end
					toggleBg.BackgroundColor3 = ThemeModule.Colors.Primary1
				else
					if existingGradient then
						ThemeModule.GradientSystem.Unregister(existingGradient)
						existingGradient:Destroy()
					end
					TweenService:Create(toggleBg, TweenInfo.new(0.2, Enum.EasingStyle.Quad), {
						BackgroundColor3 = Color3.fromRGB(80, 80, 90)
					}):Play()
				end

				local targetKnobPos = value 
					and UDim2.new(1, -(SIZES.TOGGLE_KNOB + knobPadding), 0.5, -SIZES.TOGGLE_KNOB/2) 
					or UDim2.new(0, knobPadding, 0.5, -SIZES.TOGGLE_KNOB/2)

				TweenService:Create(toggleData.toggleKnob, TweenInfo.new(0.2, Enum.EasingStyle.Quad), {Position = targetKnobPos}):Play()
				break
			end
		end
	end
end)

print("✅ ConfigClient (Fixed Layout) Loaded Successfully!")
print("🎨 Optimized for 800×460 panel")
