local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Modules = ReplicatedStorage:WaitForChild("Modules")
local SoundService = game:GetService("SoundService")
local MenuConfig  = require(Modules:WaitForChild("MenuConfig"))
local ThemeModule = require(Modules:WaitForChild("ThemeModule"))
local NotifModule = require(Modules:WaitForChild("NotifModule"))
local UIStrings = require(Modules:WaitForChild("UIStrings"))

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

local configPage = MenuConfig.GUI.PengaturanPage or MenuConfig.GUI.ConfigPage

local CONFIG = MenuConfig.GetConfig()

ThemeModule.GradientSystem.Start()

local SIZES = {

	SECTION_H = 30,
	SECTION_TEXT = UIStrings.TextSize.Header,

	TOGGLE_H = 54,
	TOGGLE_LABEL_TEXT = UIStrings.TextSize.Title,
	TOGGLE_DESC_TEXT = UIStrings.TextSize.Caption,
	TOGGLE_WIDTH = 50,
	TOGGLE_HEIGHT = 26,
	TOGGLE_KNOB = 20,

	SLIDER_H = 64,
	SLIDER_LABEL_TEXT = UIStrings.TextSize.Title,
	SLIDER_VALUE_TEXT = UIStrings.TextSize.Caption,
	SLIDER_BAR_H = 8,
	SLIDER_KNOB = 20,
	SLIDER_VALUE_W = 50,

	BUTTON_H = 42,
	BUTTON_TEXT = UIStrings.TextSize.Button,

	CORNER_SM = 6,
	CORNER_MD = 8,
	CORNER_LG = 10,
	SPACING = 8,
	SCROLL_PAD = 8,
	ITEM_PAD = 12,
}

local function showNotification(notifType, title, text, duration)
	duration = duration or 2

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
			Type = notifType or "Notification",
			Title = title,
			Text = text,
			Duration = duration,
		})
	end
end

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

local ConfigRemotes = ReplicatedStorage:WaitForChild("ConfigRemotes", 15)
local LoadSettingsRemote = ConfigRemotes and ConfigRemotes:WaitForChild("LoadSettings", 15)
local SaveSettingRemote = ConfigRemotes and ConfigRemotes:WaitForChild("SaveSetting", 15)
local ResetSettingsRemote = ConfigRemotes and ConfigRemotes:WaitForChild("ResetSettings", 15)

local UIElements = {
	sections = {},
	toggles = {},
	sliders = {},
	buttons = {},
	scrollFrame = nil,
}

local activeSlider = nil

local DEFAULT_SETTINGS = {
	hideBubbleChat = false,
	hidePlayerEffects = false,
	hidePlayers = false,
	hideOverhead = false,
	hideShadow = false,
	muteMusic = false,
	musicVolume = 50,
	game_rank = true,
	currentTheme = "White"
}

local settingsLoaded = false
local userSettings = nil

local function loadSettings()
	for attempt = 1, 5 do
		if not LoadSettingsRemote and ConfigRemotes then
			LoadSettingsRemote = ConfigRemotes:WaitForChild("LoadSettings", 5)
		end
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

		if attempt < 5 then
			task.wait(0.5)
		end
	end

	settingsLoaded = true
	local defaultCopy = {}
	for k, v in pairs(DEFAULT_SETTINGS) do
		defaultCopy[k] = v
	end
	local serverAttrTheme = player:GetAttribute("CurrentTheme")
	if serverAttrTheme and serverAttrTheme ~= "" then
		defaultCopy.currentTheme = serverAttrTheme
	end
	return defaultCopy
end

if not MenuConfig.UserSettings then
	MenuConfig.UserSettings = loadSettings()
end

userSettings = MenuConfig.UserSettings

local function syncUserSettings()
	if MenuConfig.UserSettings then
		userSettings = MenuConfig.UserSettings
	end
end

local function saveSetting(settingKey, value)
	if not SaveSettingRemote and ConfigRemotes then
		SaveSettingRemote = ConfigRemotes:WaitForChild("SaveSetting", 5)
	end
	if SaveSettingRemote then
		pcall(function()
			SaveSettingRemote:FireServer(settingKey, value)
		end)
	else
		warn("⚠️ [ConfigClient] SaveSettingRemote tidak ditemukan untuk:", settingKey)
	end
end

local function getMusicGroup()
	return SoundService:FindFirstChild("mainEffects") or SoundService:FindFirstChild("MusicGroup") or SoundService:FindFirstChild("ServerMusicSound")
end

local function setMusicMuted(muted)
	userSettings.muteMusic = muted
	if MenuConfig.UserSettings then
		MenuConfig.UserSettings.muteMusic = muted
	end
	if MenuConfig.Events and MenuConfig.Events.OnSettingChanged then
		MenuConfig.Events.OnSettingChanged:Fire("muteMusic", muted)
	end
end

local function setMusicVolume(volume)
	userSettings.musicVolume = volume
	if MenuConfig.UserSettings then
		MenuConfig.UserSettings.musicVolume = volume
	end
	if MenuConfig.Events and MenuConfig.Events.OnSettingChanged then
		MenuConfig.Events.OnSettingChanged:Fire("musicVolume", volume)
	end
end

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

	if UIElements.updateThemeSelector then
		UIElements.updateThemeSelector()
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

	player:SetAttribute("CurrentTheme", "White")
	local remotes = ReplicatedStorage:FindFirstChild("Remotes")
	local setCurrentThemeRemote = remotes and remotes:FindFirstChild("SetCurrentTheme")
	if setCurrentThemeRemote then
		pcall(function()
			setCurrentThemeRemote:FireServer("White")
		end)
	end

	if ThemeModule.ApplyPreset then
		ThemeModule.ApplyPreset("White")
	end

	if MenuConfig.Events and MenuConfig.Events.OnColorChanged then
		MenuConfig.Events.OnColorChanged:Fire()
	end

	MenuConfig.UserSettings = userSettings
	refreshAllUI()
end

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

local function mk(cls, props, parent)
	local inst = Instance.new(cls)
	for k, v in pairs(props) do inst[k] = v end
	if inst:IsA("GuiObject") and not inst:IsA("UIComponent") and props.Active == nil then
		inst.Active = true
	end
	if parent then inst.Parent = parent end
	return inst
end

local function crn(r, f) mk("UICorner", { CornerRadius = UDim.new(0, r) }, f) end

local configScroll = mk("ScrollingFrame", {
	Name = "ConfigScroll",
	Size = UDim2.new(1, 0, 1, 0),
	Position = UDim2.new(0, 0, 0, 0),
	BackgroundColor3 = ThemeModule.Colors.BackgroundDark,
	ScrollBarThickness = 0,
	ScrollBarImageTransparency = 1,
	ScrollingEnabled = true,
	Active = true,
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

local function createSectionHeader(text, layoutOrder)
	local section = mk("Frame", {
		Name = "Section_" .. text:gsub("%s+", ""),
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		LayoutOrder = layoutOrder,
	}, configScroll)

	local sectionLabel = mk("TextLabel", {
		Name = "Label",
		Text = text,
		Size = UDim2.new(1, -16, 0, 0),
		Position = UDim2.new(0, 8, 0, 4),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
		TextColor3 = Color3.fromRGB(255, 255, 255),
		TextSize = SIZES.SECTION_TEXT,
		TextWrapped = true,
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

	local item = mk("Frame", {
		Name = "Toggle_" .. settingKey,
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundColor3 = ThemeModule.Colors.BackgroundMedium,
		BorderSizePixel = 0,
		LayoutOrder = layoutOrder,
		ClipsDescendants = false,
	}, configScroll)
	crn(SIZES.CORNER_MD, item)

	mk("UIPadding", {
		PaddingTop = UDim.new(0, 10),
		PaddingBottom = UDim.new(0, 10),
		PaddingLeft = UDim.new(0, SIZES.ITEM_PAD),
		PaddingRight = UDim.new(0, SIZES.ITEM_PAD),
	}, item)

	local textContainer = mk("Frame", {
		Name = "TextContainer",
		Size = UDim2.new(1, -(SIZES.TOGGLE_WIDTH + 16), 0, 0),
		Position = UDim2.new(0, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
		ClipsDescendants = false,
	}, item)

	mk("UIListLayout", {
		SortOrder = Enum.SortOrder.LayoutOrder,
		Padding = UDim.new(0, 4),
		FillDirection = Enum.FillDirection.Vertical,
	}, textContainer)

	local label = mk("TextLabel", {
		Name = "Label",
		Text = labelText,
		Size = UDim2.new(1, 0, 0, 0),
		Position = UDim2.new(0, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
		TextColor3 = Color3.fromRGB(255, 255, 255),
		TextSize = SIZES.TOGGLE_LABEL_TEXT,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextYAlignment = Enum.TextYAlignment.Center,
		TextWrapped = true,
		TextTruncate = Enum.TextTruncate.None,
		Font = Enum.Font.GothamSemibold,
		LayoutOrder = 1,
	}, textContainer)

	local desc = nil
	if hasDesc then
		desc = mk("TextLabel", {
			Name = "Description",
			Text = description,
			Size = UDim2.new(1, 0, 0, 0),
			Position = UDim2.new(0, 0, 0, 0),
			AutomaticSize = Enum.AutomaticSize.Y,
			BackgroundTransparency = 1,
			TextColor3 = ThemeModule.Colors.TextGray,
			TextSize = SIZES.TOGGLE_DESC_TEXT,
			TextXAlignment = Enum.TextXAlignment.Left,
			TextYAlignment = Enum.TextYAlignment.Top,
			TextWrapped = true,
			TextTruncate = Enum.TextTruncate.None,
			Font = Enum.Font.Gotham,
			LayoutOrder = 2,
		}, textContainer)
	end

	local isOn = userSettings[settingKey]

	local toggleBg = mk("Frame", {
		Name = "ToggleBg",
		Size = UDim2.new(0, SIZES.TOGGLE_WIDTH, 0, SIZES.TOGGLE_HEIGHT),
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, 0, 0.5, 0),
		BackgroundColor3 = isOn and ThemeModule.Colors.Primary1 or ThemeModule.Colors.Disabled,
		BorderSizePixel = 0,
	}, item)
	crn(SIZES.TOGGLE_HEIGHT/2, toggleBg)

	if isOn then
		ThemeModule.CreatePrimaryGradient(toggleBg, 0, 1.2)
	end

	local knobPadding = 3
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

	local toggleBtn = mk("TextButton", {
		Name = "ToggleBtn",
		Text = "",
		Size = UDim2.new(1, 8, 1, 14),
		Position = UDim2.new(0.5, 0, 0.5, 0),
		AnchorPoint = Vector2.new(0.5, 0.5),
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
				BackgroundColor3 = ThemeModule.Colors.Disabled
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

	item.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseMovement then
			TweenService:Create(item, TweenInfo.new(0.15), {
				BackgroundColor3 = ThemeModule.Colors.BackgroundLight
			}):Play()
		end
	end)

	item.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseMovement then
			TweenService:Create(item, TweenInfo.new(0.15), {
				BackgroundColor3 = ThemeModule.Colors.BackgroundMedium
			}):Play()
		end
	end)

	return item
end

local function createSliderSetting(labelText, settingKey, layoutOrder, minValue, maxValue, onValueChanged)
	minValue = minValue or 0
	maxValue = maxValue or 100

	local item = mk("Frame", {
		Name = "Slider_" .. settingKey,
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundColor3 = ThemeModule.Colors.BackgroundMedium,
		BorderSizePixel = 0,
		LayoutOrder = layoutOrder,
		ClipsDescendants = false,
	}, configScroll)
	crn(SIZES.CORNER_MD, item)

	mk("UIPadding", {
		PaddingTop = UDim.new(0, 10),
		PaddingBottom = UDim.new(0, 12),
		PaddingLeft = UDim.new(0, SIZES.ITEM_PAD),
		PaddingRight = UDim.new(0, SIZES.ITEM_PAD),
	}, item)

	mk("UIListLayout", {
		SortOrder = Enum.SortOrder.LayoutOrder,
		Padding = UDim.new(0, 8),
		FillDirection = Enum.FillDirection.Vertical,
	}, item)

	local label = mk("TextLabel", {
		Name = "Label",
		Text = labelText,
		Size = UDim2.new(1, 0, 0, 0),
		Position = UDim2.new(0, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
		TextColor3 = Color3.fromRGB(255, 255, 255),
		TextSize = SIZES.SLIDER_LABEL_TEXT,
		TextWrapped = true,
		TextTruncate = Enum.TextTruncate.None,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextYAlignment = Enum.TextYAlignment.Center,
		Font = Enum.Font.GothamSemibold,
		LayoutOrder = 1,
	}, item)

	local currentValue = userSettings[settingKey] or (DEFAULT_SETTINGS[settingKey] or 50)
	local progress = (currentValue - minValue) / (maxValue - minValue)

	local sliderRow = mk("Frame", {
		Name = "SliderRow",
		Size = UDim2.new(1, 0, 0, math.max(SIZES.SLIDER_KNOB + 16, 44)),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		LayoutOrder = 2,
	}, item)

	local valueLabel = mk("TextLabel", {
		Name = "ValueLabel",
		Text = tostring(math.floor(currentValue)) .. "%",
		Size = UDim2.new(0, SIZES.SLIDER_VALUE_W, 1, 0),
		Position = UDim2.new(1, -SIZES.SLIDER_VALUE_W, 0, 0),
		BackgroundTransparency = 1,
		TextColor3 = ThemeModule.Colors.Primary1,
		TextSize = SIZES.SLIDER_VALUE_TEXT,
		TextXAlignment = Enum.TextXAlignment.Right,
		TextYAlignment = Enum.TextYAlignment.Center,
		Font = Enum.Font.GothamBold,
	}, sliderRow)

	local sliderContainer = mk("Frame", {
		Name = "SliderContainer",
		Size = UDim2.new(1, -(SIZES.SLIDER_VALUE_W + 10), 1, 0),
		Position = UDim2.new(0, 0, 0, 0),
		BackgroundTransparency = 1,
		ClipsDescendants = false,
	}, sliderRow)

	local sliderBg = mk("Frame", {
		Name = "SliderBg",
		Size = UDim2.new(1, 0, 0, SIZES.SLIDER_BAR_H),
		Position = UDim2.new(0, 0, 0.5, -SIZES.SLIDER_BAR_H / 2),
		BackgroundColor3 = ThemeModule.Colors.Disabled,
		BorderSizePixel = 0,
	}, sliderContainer)
	crn(SIZES.SLIDER_BAR_H / 2, sliderBg)

	local sliderFill = mk("Frame", {
		Name = "SliderFill",
		Size = UDim2.new(progress, 0, 1, 0),
		Position = UDim2.new(0, 0, 0, 0),
		BackgroundColor3 = ThemeModule.Colors.Primary1,
		BorderSizePixel = 0,
	}, sliderBg)
	crn(SIZES.SLIDER_BAR_H / 2, sliderFill)

	ThemeModule.CreatePrimaryGradient(sliderFill, 0, 0.8)

	local sliderKnob = mk("Frame", {
		Name = "SliderKnob",
		Size = UDim2.new(0, SIZES.SLIDER_KNOB, 0, SIZES.SLIDER_KNOB),
		Position = UDim2.new(progress, -SIZES.SLIDER_KNOB / 2, 0.5, -SIZES.SLIDER_KNOB / 2),
		BackgroundColor3 = Color3.fromRGB(255, 255, 255),
		BorderSizePixel = 0,
		ZIndex = 2,
	}, sliderBg)
	crn(SIZES.SLIDER_KNOB / 2, sliderKnob)

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

local function createResetButton(layoutOrder)
	local btn = mk("TextButton", {
		Name = "ResetButton",
		Text = "🔄 RESET PENGATURAN",
		Size = UDim2.new(1, 0, 0, SIZES.BUTTON_H),
		BackgroundColor3 = ThemeModule.Colors.CloseRed,
		BorderSizePixel = 0,
		TextColor3 = ThemeModule.Colors.TextWhite,
		TextSize = SIZES.BUTTON_TEXT,
		Font = Enum.Font.GothamBold,
		LayoutOrder = layoutOrder,
		ClipsDescendants = true,
	}, configScroll)
	crn(SIZES.CORNER_MD, btn)
	ThemeModule.CreateAnimatedStroke(btn, 1.2, "Primary", 1.2)

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
			BackgroundColor3 = ThemeModule.Colors.CloseRedHover
		}):Play()
	end)

	btn.MouseLeave:Connect(function()
		TweenService:Create(btn, TweenInfo.new(0.15), {
			BackgroundColor3 = ThemeModule.Colors.CloseRed
		}):Play()
	end)

	return btn
end

local THEME_LIST = {
	{ id = "White",  name = "Putih",  color = Color3.fromRGB(255, 255, 255) },
	{ id = "Cyan",   name = "Cyan",   color = Color3.fromRGB(0, 210, 255) },
	{ id = "Gold",   name = "Gold",   color = Color3.fromRGB(255, 215, 0) },
	{ id = "Blue",   name = "Blue",   color = Color3.fromRGB(100, 150, 255) },
	{ id = "Green",  name = "Green",  color = Color3.fromRGB(100, 255, 150) },
	{ id = "Purple", name = "Purple", color = Color3.fromRGB(200, 100, 255) },
	{ id = "Red",    name = "Red",    color = Color3.fromRGB(255, 100, 100) },
	{ id = "Pink",   name = "Pink",   color = Color3.fromRGB(255, 150, 200) },
}

local function createThemeSelector(layoutOrder)
	local item = mk("Frame", {
		Name = "ThemeSelectorCard",
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundColor3 = ThemeModule.Colors.BackgroundMedium,
		BorderSizePixel = 0,
		LayoutOrder = layoutOrder,
		ClipsDescendants = false,
		Active = false,
	}, configScroll)
	crn(SIZES.CORNER_MD, item)

	mk("UIPadding", {
		PaddingTop = UDim.new(0, 10),
		PaddingBottom = UDim.new(0, 12),
		PaddingLeft = UDim.new(0, SIZES.ITEM_PAD),
		PaddingRight = UDim.new(0, SIZES.ITEM_PAD),
	}, item)

	mk("UIListLayout", {
		SortOrder = Enum.SortOrder.LayoutOrder,
		Padding = UDim.new(0, 10),
		FillDirection = Enum.FillDirection.Vertical,
	}, item)

	local headerContainer = mk("Frame", {
		Name = "HeaderContainer",
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
		Active = false,
		LayoutOrder = 1,
	}, item)

	mk("UIListLayout", {
		SortOrder = Enum.SortOrder.LayoutOrder,
		Padding = UDim.new(0, 4),
		FillDirection = Enum.FillDirection.Vertical,
	}, headerContainer)

	local titleLabel = mk("TextLabel", {
		Name = "Title",
		Text = "🎨 Warna Nama & Tema",
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
		TextColor3 = Color3.fromRGB(255, 255, 255),
		TextSize = SIZES.TOGGLE_LABEL_TEXT,
		TextWrapped = true,
		TextTruncate = Enum.TextTruncate.None,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextYAlignment = Enum.TextYAlignment.Center,
		Font = Enum.Font.GothamSemibold,
		Active = false,
		LayoutOrder = 1,
	}, headerContainer)

	local descLabel = mk("TextLabel", {
		Name = "Description",
		Text = "Pilih warna nama overhead dan nuansa visual menu Anda",
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
		TextColor3 = ThemeModule.Colors.TextGray,
		TextSize = SIZES.TOGGLE_DESC_TEXT,
		TextWrapped = true,
		TextTruncate = Enum.TextTruncate.None,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextYAlignment = Enum.TextYAlignment.Top,
		Font = Enum.Font.Gotham,
		Active = false,
		LayoutOrder = 2,
	}, headerContainer)

	local gridContainer = mk("Frame", {
		Name = "GridContainer",
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
		Active = false,
		LayoutOrder = 2,
	}, item)

	local gridLayout = mk("UIGridLayout", {
		CellSize = UDim2.new(0.235, 0, 0, 44),
		CellPadding = UDim2.new(0.02, 0, 0, 8),
		SortOrder = Enum.SortOrder.LayoutOrder,
	}, gridContainer)

	local chipElements = {}

	local function updateThemeChipsVisual(activeThemeId)
		for _, chipData in ipairs(chipElements) do
			local isActive = (chipData.themeId == activeThemeId) or (activeThemeId == nil and chipData.themeId == "White")
			local stroke = chipData.stroke
			local chip = chipData.chip
			local label = chipData.label

			if isActive then
				stroke.Color = chipData.color
				stroke.Thickness = 2
				stroke.Transparency = 0
				chip.BackgroundColor3 = Color3.fromRGB(36, 40, 50)
				label.TextColor3 = Color3.fromRGB(255, 255, 255)
				label.Font = Enum.Font.GothamBold
			else
				stroke.Color = Color3.fromRGB(55, 55, 65)
				stroke.Thickness = 1
				stroke.Transparency = 0.5
				chip.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
				label.TextColor3 = Color3.fromRGB(190, 190, 200)
				label.Font = Enum.Font.GothamMedium
			end
		end
	end

	for idx, theme in ipairs(THEME_LIST) do
		local chip = mk("Frame", {
			Name = "Chip_" .. theme.id,
			BackgroundColor3 = Color3.fromRGB(25, 25, 30),
			BorderSizePixel = 0,
			LayoutOrder = idx,
			Active = false,
		}, gridContainer)
		crn(6, chip)

		local stroke = mk("UIStroke", {
			Color = Color3.fromRGB(55, 55, 65),
			Thickness = 1,
			Transparency = 0.5,
			ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
		}, chip)

		local dot = mk("Frame", {
			Name = "ColorDot",
			Size = UDim2.new(0, 12, 0, 12),
			Position = UDim2.new(0, 8, 0.5, -6),
			BackgroundColor3 = theme.color,
			BorderSizePixel = 0,
			Active = false,
		}, chip)
		crn(6, dot)

		local nameLabel = mk("TextLabel", {
			Name = "NameLabel",
			Text = theme.name,
			Size = UDim2.new(1, -26, 1, 0),
			Position = UDim2.new(0, 24, 0, 0),
			BackgroundTransparency = 1,
			TextColor3 = Color3.fromRGB(190, 190, 200),
			TextSize = UIStrings.TextSize.Caption,
			Font = Enum.Font.GothamMedium,
			TextXAlignment = Enum.TextXAlignment.Left,
			TextYAlignment = Enum.TextYAlignment.Center,
			TextTruncate = Enum.TextTruncate.None,
			Active = false,
		}, chip)

		local btn = mk("TextButton", {
			Name = "ClickBtn",
			Text = "",
			Size = UDim2.new(1, 0, 1, 0),
			Position = UDim2.new(0, 0, 0, 0),
			BackgroundTransparency = 1,
			ZIndex = 10,
			Active = true,
			Selectable = true,
			AutoButtonColor = false,
		}, chip)

		table.insert(chipElements, {
			themeId = theme.id,
			color = theme.color,
			chip = chip,
			stroke = stroke,
			label = nameLabel,
		})

		btn.MouseEnter:Connect(function()
			local current = userSettings.currentTheme or player:GetAttribute("CurrentTheme") or "White"
			if current ~= theme.id then
				TweenService:Create(chip, TweenInfo.new(0.15), {
					BackgroundColor3 = Color3.fromRGB(34, 34, 42)
				}):Play()
			end
		end)

		btn.MouseLeave:Connect(function()
			local current = userSettings.currentTheme or player:GetAttribute("CurrentTheme") or "White"
			if current ~= theme.id then
				TweenService:Create(chip, TweenInfo.new(0.15), {
					BackgroundColor3 = Color3.fromRGB(25, 25, 30)
				}):Play()
			end
		end)

		btn.InputBegan:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
				TweenService:Create(chip, TweenInfo.new(0.08), {
					BackgroundColor3 = Color3.fromRGB(45, 48, 60)
				}):Play()
			end
		end)

		btn.InputEnded:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
				local current = userSettings.currentTheme or player:GetAttribute("CurrentTheme") or "White"
				local targetBg = (current == theme.id) and Color3.fromRGB(36, 40, 50) or Color3.fromRGB(25, 25, 30)
				TweenService:Create(chip, TweenInfo.new(0.12), {
					BackgroundColor3 = targetBg
				}):Play()
			end
		end)

		local isProcessing = false
		local function selectTheme()
			if isProcessing then return end
			isProcessing = true
			task.delay(0.2, function() isProcessing = false end)

			SoundSystem.PlayClick()
			userSettings.currentTheme = theme.id
			saveSetting("currentTheme", theme.id)
			player:SetAttribute("CurrentTheme", theme.id)

			local remotes = ReplicatedStorage:FindFirstChild("Remotes")
			local setCurrentThemeRemote = remotes and remotes:FindFirstChild("SetCurrentTheme")
			if setCurrentThemeRemote then
				pcall(function()
					setCurrentThemeRemote:FireServer(theme.id)
				end)
			end

			if ThemeModule.ApplyPreset then
				ThemeModule.ApplyPreset(theme.id)
			end

			if MenuConfig.Events and MenuConfig.Events.OnColorChanged then
				MenuConfig.Events.OnColorChanged:Fire()
			end

			MenuConfig.Events.OnSettingChanged:Fire("currentTheme", theme.id)
			updateThemeChipsVisual(theme.id)
			showNotification("Settings", "🎨 Tema & Warna", "Tema diubah ke " .. theme.name, 2)
		end

		btn.Activated:Connect(selectTheme)
		btn.MouseButton1Click:Connect(selectTheme)
	end

	local function updateResponsiveGrid()
		local width = gridContainer.AbsoluteSize.X
		if width > 0 and width < 380 then
			gridLayout.CellSize = UDim2.new(0.485, 0, 0, 38)
			gridLayout.CellPadding = UDim2.new(0.03, 0, 0, 8)
			gridContainer.Size = UDim2.new(1, -24, 0, 180)
			item.Size = UDim2.new(1, 0, 0, 246)
		else
			gridLayout.CellSize = UDim2.new(0.235, 0, 0, 36)
			gridLayout.CellPadding = UDim2.new(0.02, 0, 0, 8)
			gridContainer.Size = UDim2.new(1, -24, 0, 82)
			item.Size = UDim2.new(1, 0, 0, 150)
		end
	end

	gridContainer:GetPropertyChangedSignal("AbsoluteSize"):Connect(updateResponsiveGrid)
	task.defer(updateResponsiveGrid)

	local initialTheme = userSettings.currentTheme or player:GetAttribute("CurrentTheme") or "White"
	updateThemeChipsVisual(initialTheme)

	UIElements.updateThemeSelector = function()
		local active = userSettings.currentTheme or player:GetAttribute("CurrentTheme") or "White"
		updateThemeChipsVisual(active)
	end

	return item
end

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

createSectionHeader("PENGATURAN TEMA & NAMA", 7)

createThemeSelector(8)

createSectionHeader("PENGATURAN MUSIK", 10)

createToggleSetting("🔇 Bisukan Musik", "Mematikan suara musik sepenuhnya", "muteMusic", 11, function(isMuted)
	setMusicMuted(isMuted)
	showNotification("Settings", "🔇 Musik", isMuted and "Dibisukan" or "Diaktifkan", 2)
end)

createSliderSetting("🔊 Volume Musik", "musicVolume", 12, 0, 100, function(volume)
	setMusicVolume(volume)
end)

createResetButton(20)

MenuConfig.RegisterContentUpdateCallback("ConfigClient", function()

end)

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

task.spawn(function()
	task.wait(1)

	setBubbleChatHidden(userSettings.hideBubbleChat)
	setPlayerEffectsHidden(userSettings.hidePlayerEffects)
	setPlayersHidden(userSettings.hidePlayers)
	setOverheadHidden(userSettings.hideOverhead)
	setShadowHidden(userSettings.hideShadow)

	setMusicMuted(userSettings.muteMusic)
	setMusicVolume(userSettings.musicVolume)

	local serverAttrTheme = player:GetAttribute("CurrentTheme")
	local initialTheme = userSettings.currentTheme
	if serverAttrTheme and serverAttrTheme ~= "" then
		initialTheme = serverAttrTheme
		userSettings.currentTheme = serverAttrTheme
	elseif not initialTheme then
		initialTheme = "White"
		userSettings.currentTheme = "White"
	end

	player:SetAttribute("CurrentTheme", initialTheme)
	local remotes = ReplicatedStorage:FindFirstChild("Remotes")
	local setCurrentThemeRemote = remotes and remotes:FindFirstChild("SetCurrentTheme")
	if setCurrentThemeRemote then
		pcall(function()
			setCurrentThemeRemote:FireServer(initialTheme)
		end)
	end
	if ThemeModule.ApplyPreset then
		ThemeModule.ApplyPreset(initialTheme)
	end
	if MenuConfig.Events and MenuConfig.Events.OnColorChanged then
		MenuConfig.Events.OnColorChanged:Fire()
	end
	if UIElements.updateThemeSelector then
		UIElements.updateThemeSelector()
	end
end)

player:GetAttributeChangedSignal("CurrentTheme"):Connect(function()
	local theme = player:GetAttribute("CurrentTheme") or "White"
	if userSettings.currentTheme ~= theme then
		userSettings.currentTheme = theme
	end
	if ThemeModule.ApplyPreset then
		ThemeModule.ApplyPreset(theme)
	end
	if MenuConfig.Events and MenuConfig.Events.OnColorChanged then
		MenuConfig.Events.OnColorChanged:Fire()
	end
	if UIElements.updateThemeSelector then
		UIElements.updateThemeSelector()
	end
end)

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
	elseif key == "currentTheme" then
		if UIElements.updateThemeSelector then
			UIElements.updateThemeSelector()
		end
	end
end)

print("✅ ConfigClient (Tata Letak Tetap) Berhasil Dimuat!")
print("🎨 Dioptimalkan untuk panel 800×460")

