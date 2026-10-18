local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")

local Modules = ReplicatedStorage:WaitForChild("Modules")
local MenuConfig = require(Modules:WaitForChild("MenuConfig"))
local ThemeModule = require(Modules:WaitForChild("ThemeModule"))

MenuConfig.WaitForGUIReady(15)

repeat task.wait() until MenuConfig.GUI.PlayersPage

local playersPage = MenuConfig.GUI.PlayersPage
local localPlayer = Players.LocalPlayer
local CONFIG = MenuConfig.GetConfig()

local function getScreenParams()
	local screenInfo = MenuConfig.GetScreenInfo()
	return {
		isMobile = screenInfo.isMobile,
		isLandscape = screenInfo.isLandscape,
		width = screenInfo.width,
		height = screenInfo.height
	}
end

local function getPlayerItemHeight()
	local screenInfo = MenuConfig.GetScreenInfo()
	if screenInfo.isMobile and screenInfo.isLandscape then
		return math.floor(MenuConfig.GetScaledValue(70, 62, 78))
	else
		return math.floor(MenuConfig.GetScaledValue(82, 74, 92))
	end
end

local function getMyProfileHeight()
	local screenInfo = MenuConfig.GetScreenInfo()
	if screenInfo.isMobile and screenInfo.isLandscape then
		return math.floor(MenuConfig.GetScaledValue(80, 72, 90))
	else
		return math.floor(MenuConfig.GetScaledValue(94, 84, 106))
	end
end

local function getTextSize(textType)
	local screenInfo = MenuConfig.GetScreenInfo()
	local sizes = {
		header = {base = 14, min = 11, max = 16},
		displayName = {base = 13, min = 10.5, max = 15},
		username = {base = 10.5, min = 8.5, max = 12},
		profileName = {base = 15, min = 12, max = 17.5},
		profileUsername = {base = 11.5, min = 9.5, max = 13},
	}

	local sizeConfig = sizes[textType] or sizes.displayName
	local scaleFactor = 1

	if screenInfo.isMobile and screenInfo.isLandscape then
		scaleFactor = 0.9
	elseif screenInfo.isMobile then
		scaleFactor = 0.95
	end

	return math.floor(MenuConfig.GetScaledValue(sizeConfig.base * scaleFactor, sizeConfig.min, sizeConfig.max))
end

local PROFILE_COLORS = {
	Background = CONFIG.Colors.PlayerList.ProfileBg or Color3.fromRGB(40, 45, 55),
}

local ConfigRemotes = ReplicatedStorage:WaitForChild("ConfigRemotes", 15)
local SaveSettingRemote = ConfigRemotes and ConfigRemotes:WaitForChild("SaveSetting", 15)
local GROUP_ID = 550072302
local groupRankCache = {}

local function playClickSound()
	if MenuConfig.SoundSystem and MenuConfig.SoundSystem.PlayClick then
		MenuConfig.SoundSystem.PlayClick()
	end
end

local function getPlayerGroupRank(plr, callback)
	local userId = plr.UserId
	if groupRankCache[userId] ~= nil then
		return groupRankCache[userId]
	end

	task.spawn(function()
		local success, role = pcall(function()
			return plr:GetRoleInGroup(GROUP_ID)
		end)
		local rankText = nil
		if success and role and role ~= "" and role ~= "Guest" then
			if role:lower() == "member" or role:lower() == "members" then
				rankText = "- MEMBER -"
			else
				rankText = "- " .. string.upper(role) .. " -"
			end
		end
		groupRankCache[userId] = rankText
		if callback then
			callback(rankText)
		end
	end)

	return nil
end

local function updateCharacterOverheadRank(character, isEnabled)
	if not character then return end
	for _, desc in ipairs(character:GetDescendants()) do
		if desc.Name == "GuestLabel" and desc:IsA("TextLabel") then
			local isRank = desc:GetAttribute("IsRank")
			desc.Visible = (isEnabled and isRank == true)
		end
	end
end

local function updateAllOverheadsRank(isEnabled)
	for _, plr in ipairs(Players:GetPlayers()) do
		if plr.Character then
			updateCharacterOverheadRank(plr.Character, isEnabled)
		end
	end
end

local function getFriendsInServer()
	local friendsInServer = {}
	for _, player in ipairs(Players:GetPlayers()) do
		if player ~= localPlayer then
			local success, isFriend = pcall(function()
				return localPlayer:IsFriendsWith(player.UserId)
			end)
			if success and isFriend then
				table.insert(friendsInServer, player)
			end
		end
	end
	return friendsInServer
end

local playersScroll = Instance.new("ScrollingFrame")
playersScroll.Name = "PlayersScroll"
playersScroll.Size = UDim2.new(1, 0, 1, 0)
playersScroll.Position = UDim2.new(0, 0, 0, 0)
playersScroll.BackgroundColor3 = CONFIG.Colors.PlayerList.Background
playersScroll.BorderSizePixel = 0
playersScroll.ScrollBarThickness = 0
playersScroll.ScrollBarImageTransparency = 1
playersScroll.ScrollingEnabled = true
playersScroll.Active = true
playersScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
playersScroll.ScrollingDirection = Enum.ScrollingDirection.Y
playersScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
playersScroll.VerticalScrollBarInset = Enum.ScrollBarInset.None
playersScroll.HorizontalScrollBarInset = Enum.ScrollBarInset.None
playersScroll.Parent = playersPage

Instance.new("UICorner", playersScroll).CornerRadius = UDim.new(0, CONFIG.Layout.ButtonCorner)

local playersScrollPadding = Instance.new("UIPadding", playersScroll)
playersScrollPadding.PaddingLeft = UDim.new(0, 6)
playersScrollPadding.PaddingRight = UDim.new(0, 6)
playersScrollPadding.PaddingTop = UDim.new(0, 6)
playersScrollPadding.PaddingBottom = UDim.new(0, 6)

local playersListLayout = Instance.new("UIListLayout", playersScroll)
playersListLayout.SortOrder = Enum.SortOrder.LayoutOrder
playersListLayout.Padding = UDim.new(0, 8)

local function createSectionHeader(name, text, layoutOrder)
	local header = Instance.new("TextLabel")
	header.Name = name
	header.Text = text
	header.Size = UDim2.new(1, 0, 0, 22)
	header.BackgroundTransparency = 1
	header.TextScaled = true
	header.TextXAlignment = Enum.TextXAlignment.Left
	header.Font = Enum.Font.GothamBold
	header.LayoutOrder = layoutOrder
	header.TextColor3 = Color3.new(1, 1, 1)
	header.Parent = playersScroll

	ThemeModule.CreatePrimaryGradient(header, 0, 1)

	Instance.new("UITextSizeConstraint", header).MaxTextSize = getTextSize("header")
	return header
end

local function createGameRankOption(layoutOrder)
	local itemHeight = math.floor(MenuConfig.GetScaledValue(52, 46, 58))
	local toggleWidth = math.floor(MenuConfig.GetScaledValue(46, 40, 50))
	local toggleHeight = math.floor(MenuConfig.GetScaledValue(24, 20, 26))
	local toggleKnobSize = toggleHeight - 4

	local item = Instance.new("Frame")
	item.Name = "GameRankSetting"
	item.Size = UDim2.new(1, 0, 0, itemHeight)
	item.BackgroundColor3 = PROFILE_COLORS.Background
	item.BorderSizePixel = 0
	item.LayoutOrder = layoutOrder
	item.ClipsDescendants = true
	item.Parent = playersScroll

	ThemeModule.CreateCorner(item, CONFIG.Layout.SmallCorner)

	local textContainer = Instance.new("Frame")
	textContainer.Name = "TextContainer"
	textContainer.Size = UDim2.new(1, -(toggleWidth + 28), 1, 0)
	textContainer.Position = UDim2.new(0, 12, 0, 0)
	textContainer.BackgroundTransparency = 1
	textContainer.Parent = item

	local title = Instance.new("TextLabel")
	title.Name = "Title"
	title.Text = "🎖️ Tampilkan Rank Grup"
	title.Size = UDim2.new(1, 0, 0, 20)
	title.Position = UDim2.new(0, 0, 0, 7)
	title.BackgroundTransparency = 1
	title.TextColor3 = Color3.fromRGB(255, 255, 255)
	title.TextSize = getTextSize("displayName")
	title.TextXAlignment = Enum.TextXAlignment.Left
	title.TextYAlignment = Enum.TextYAlignment.Center
	title.Font = Enum.Font.GothamSemibold
	title.Parent = textContainer

	local desc = Instance.new("TextLabel")
	desc.Name = "Description"
	desc.Text = "Tampilkan status rank/member di overhead & list"
	desc.Size = UDim2.new(1, 0, 0, 16)
	desc.Position = UDim2.new(0, 0, 0, 28)
	desc.BackgroundTransparency = 1
	desc.TextColor3 = ThemeModule.Colors.TextGray or Color3.fromRGB(180, 180, 180)
	desc.TextSize = getTextSize("username")
	desc.TextXAlignment = Enum.TextXAlignment.Left
	desc.TextYAlignment = Enum.TextYAlignment.Center
	desc.Font = Enum.Font.Gotham
	desc.Parent = textContainer

	local isRankEnabled = MenuConfig.UserSettings.game_rank ~= false

	local toggleBg = Instance.new("Frame")
	toggleBg.Name = "ToggleBg"
	toggleBg.Size = UDim2.new(0, toggleWidth, 0, toggleHeight)
	toggleBg.Position = UDim2.new(1, -(toggleWidth + 14), 0.5, -toggleHeight / 2)
	toggleBg.BackgroundColor3 = isRankEnabled and (ThemeModule.Colors.Primary1 or Color3.fromRGB(60, 150, 240)) or Color3.fromRGB(80, 80, 90)
	toggleBg.BorderSizePixel = 0
	toggleBg.Parent = item

	ThemeModule.CreateCorner(toggleBg, toggleHeight / 2)

	local knobPadding = 2
	local knob = Instance.new("Frame")
	knob.Name = "Knob"
	knob.Size = UDim2.new(0, toggleKnobSize, 0, toggleKnobSize)
	knob.Position = isRankEnabled
		and UDim2.new(1, -(toggleKnobSize + knobPadding), 0.5, -toggleKnobSize / 2)
		or UDim2.new(0, knobPadding, 0.5, -toggleKnobSize / 2)
	knob.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	knob.BorderSizePixel = 0
	knob.Parent = toggleBg

	ThemeModule.CreateCorner(knob, toggleKnobSize / 2)

	local toggleBtn = Instance.new("TextButton")
	toggleBtn.Name = "ToggleBtn"
	toggleBtn.Text = ""
	toggleBtn.Size = UDim2.new(1, 0, 1, 0)
	toggleBtn.BackgroundTransparency = 1
	toggleBtn.Parent = toggleBg

	local function setVisualState(enabled)
		local targetPos = enabled
			and UDim2.new(1, -(toggleKnobSize + knobPadding), 0.5, -toggleKnobSize / 2)
			or UDim2.new(0, knobPadding, 0.5, -toggleKnobSize / 2)
		local targetColor = enabled
			and (ThemeModule.Colors.Primary1 or Color3.fromRGB(60, 150, 240))
			or Color3.fromRGB(80, 80, 90)

		TweenService:Create(knob, TweenInfo.new(0.2, Enum.EasingStyle.Quad), { Position = targetPos }):Play()
		TweenService:Create(toggleBg, TweenInfo.new(0.2, Enum.EasingStyle.Quad), { BackgroundColor3 = targetColor }):Play()
	end

	toggleBtn.MouseButton1Click:Connect(function()
		playClickSound()

		local newState = not (MenuConfig.UserSettings.game_rank ~= false)
		MenuConfig.UserSettings.game_rank = newState

		setVisualState(newState)

		if SaveSettingRemote then
			pcall(function()
				SaveSettingRemote:FireServer("game_rank", newState)
			end)
		end

		MenuConfig.Events.OnSettingChanged:Fire("game_rank", newState)
		updateAllOverheadsRank(newState)

		for _, child in ipairs(playersScroll:GetDescendants()) do
			if child.Name == "RankLabel" and child:IsA("TextLabel") then
				child.Visible = newState
			end
		end
	end)

	return item
end

local function createMyProfile(layoutOrder)
	local profileHeight = getMyProfileHeight()

	local profileFrame = Instance.new("TextButton")
	profileFrame.Name = "MyProfile"
	profileFrame.Size = UDim2.new(1, 0, 0, profileHeight)
	profileFrame.BackgroundColor3 = PROFILE_COLORS.Background
	profileFrame.BorderSizePixel = 0
	profileFrame.LayoutOrder = layoutOrder
	profileFrame.Text = ""
	profileFrame.AutoButtonColor = false
	profileFrame.Parent = playersScroll

	ThemeModule.CreateCorner(profileFrame, CONFIG.Layout.ButtonCorner)

	local profileStroke, profileStrokeGradient = ThemeModule.CreateAnimatedStroke(profileFrame, 2, "Primary", 1.2)
	profileStroke.Name = "ProfileBorder"
	profileStroke.Transparency = 0.2

	local avatarSize = profileHeight - 20
	local avatar = Instance.new("ImageLabel")
	avatar.Name = "Avatar"
	avatar.Size = UDim2.new(0, avatarSize, 0, avatarSize)
	avatar.Position = UDim2.new(0, 12, 0.5, 0)
	avatar.AnchorPoint = Vector2.new(0, 0.5)
	avatar.BackgroundColor3 = CONFIG.Colors.PlayerList.ItemBg
	avatar.BorderSizePixel = 0
	avatar.Parent = profileFrame

	ThemeModule.CreateCorner(avatar, avatarSize / 2)

	task.spawn(function()
		local success, result = pcall(function()
			return Players:GetUserThumbnailAsync(localPlayer.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size150x150)
		end)
		if success and avatar and avatar.Parent then
			avatar.Image = result
		end
	end)

	local infoContainer = Instance.new("Frame")
	infoContainer.Name = "InfoContainer"
	infoContainer.Size = UDim2.new(1, -avatarSize - 32, 1, -12)
	infoContainer.Position = UDim2.new(0, avatarSize + 22, 0.5, 0)
	infoContainer.AnchorPoint = Vector2.new(0, 0.5)
	infoContainer.BackgroundTransparency = 1
	infoContainer.Parent = profileFrame

	local infoLayout = Instance.new("UIListLayout")
	infoLayout.SortOrder = Enum.SortOrder.LayoutOrder
	infoLayout.FillDirection = Enum.FillDirection.Vertical
	infoLayout.VerticalAlignment = Enum.VerticalAlignment.Center
	infoLayout.Padding = UDim.new(0, 3)
	infoLayout.Parent = infoContainer

	local isPremium = (localPlayer.MembershipType == Enum.MembershipType.Premium)
	local isVerified = false
	pcall(function()
		isVerified = localPlayer.HasVerifiedBadge
	end)
	local premiumPrefix = isPremium and (utf8.char(57345) .. " ") or ""
	local verifiedSuffix = isVerified and utf8.char(57344) or ""

	local displayName = Instance.new("TextLabel")
	displayName.Name = "DisplayName"
	displayName.Text = premiumPrefix .. localPlayer.DisplayName .. verifiedSuffix
	displayName.Size = UDim2.new(1, 0, 0, getTextSize("profileName") + 2)
	displayName.BackgroundTransparency = 1
	displayName.TextColor3 = ThemeModule.GetThemeColor(localPlayer:GetAttribute("CurrentTheme"))
	displayName.TextSize = getTextSize("profileName")
	displayName.TextXAlignment = Enum.TextXAlignment.Left
	displayName.TextYAlignment = Enum.TextYAlignment.Center
	displayName.Font = Enum.Font.GothamBold
	displayName.TextTruncate = Enum.TextTruncate.AtEnd
	displayName.LayoutOrder = 1
	displayName.Parent = infoContainer

	local localThemeConn = localPlayer:GetAttributeChangedSignal("CurrentTheme"):Connect(function()
		displayName.TextColor3 = ThemeModule.GetThemeColor(localPlayer:GetAttribute("CurrentTheme"))
	end)

	local username = Instance.new("TextLabel")
	username.Name = "Username"
	username.Text = "@" .. localPlayer.Name
	username.Size = UDim2.new(1, 0, 0, getTextSize("profileUsername") + 2)
	username.BackgroundTransparency = 1
	username.TextColor3 = CONFIG.Colors.PlayerList.UsernameText
	username.TextSize = getTextSize("profileUsername")
	username.TextXAlignment = Enum.TextXAlignment.Left
	username.TextYAlignment = Enum.TextYAlignment.Center
	username.Font = Enum.Font.Gotham
	username.TextTruncate = Enum.TextTruncate.AtEnd
	username.LayoutOrder = 2
	username.Parent = infoContainer

	local rankLabel = Instance.new("TextLabel")
	rankLabel.Name = "RankLabel"
	rankLabel.Size = UDim2.new(1, 0, 0, getTextSize("profileUsername"))
	rankLabel.BackgroundTransparency = 1
	rankLabel.TextColor3 = ThemeModule.Colors.TextGray or Color3.fromRGB(180, 185, 195)
	rankLabel.TextSize = math.max(10, getTextSize("profileUsername") - 1)
	rankLabel.TextXAlignment = Enum.TextXAlignment.Left
	rankLabel.TextYAlignment = Enum.TextYAlignment.Center
	rankLabel.Font = Enum.Font.Gotham
	rankLabel.TextTruncate = Enum.TextTruncate.AtEnd
	rankLabel.LayoutOrder = 3
	rankLabel.Parent = infoContainer

	local myRank = getPlayerGroupRank(localPlayer, function(txt)
		if rankLabel and rankLabel.Parent then
			if txt and MenuConfig.UserSettings.game_rank ~= false then
				rankLabel.Text = txt
				rankLabel.Visible = true
			else
				rankLabel.Visible = false
			end
		end
	end)

	if myRank and MenuConfig.UserSettings.game_rank ~= false then
		rankLabel.Text = myRank
		rankLabel.Visible = true
	else
		rankLabel.Visible = false
	end

	profileFrame:SetAttribute("IsMyProfile", true)

	profileFrame.MouseButton1Click:Connect(function()
		if MenuConfig.OpenProfileCard then
			MenuConfig.OpenProfileCard(localPlayer)
		end
	end)

	profileFrame.MouseEnter:Connect(function()
		TweenService:Create(profileFrame, TweenInfo.new(0.15), {BackgroundColor3 = Color3.fromRGB(50, 55, 65)}):Play()
	end)
	profileFrame.MouseLeave:Connect(function()
		TweenService:Create(profileFrame, TweenInfo.new(0.15), {BackgroundColor3 = PROFILE_COLORS.Background}):Play()
	end)

	profileFrame.Destroying:Connect(function()
		localThemeConn:Disconnect()
	end)

	return profileFrame
end

local function createPlayerItem(plr, layoutOrder, isFriend, isInConnectionSection)
	local itemHeight = getPlayerItemHeight()

	local playerItem = Instance.new("TextButton")
	playerItem.Name = "Player_" .. plr.Name
	playerItem.Size = UDim2.new(1, 0, 0, itemHeight)
	playerItem.BackgroundColor3 = CONFIG.Colors.PlayerList.ItemBg
	playerItem.BackgroundTransparency = isInConnectionSection and 0 or 0.5
	playerItem.BorderSizePixel = 0
	playerItem.LayoutOrder = layoutOrder
	playerItem.Text = ""
	playerItem.AutoButtonColor = false
	playerItem.Parent = playersScroll

	ThemeModule.CreateCorner(playerItem, CONFIG.Layout.SmallCorner)

	if isInConnectionSection then
		local connectionStroke, connectionGradient = ThemeModule.CreateAnimatedStroke(playerItem, 1.5, "Primary", 1)
		connectionStroke.Transparency = 0.4
	end

	local avatarSize = itemHeight - 20
	local avatar = Instance.new("ImageLabel")
	avatar.Size = UDim2.new(0, avatarSize, 0, avatarSize)
	avatar.Position = UDim2.new(0, 10, 0.5, 0)
	avatar.AnchorPoint = Vector2.new(0, 0.5)
	avatar.BackgroundColor3 = CONFIG.Colors.PlayerList.ItemBg
	avatar.BorderSizePixel = 0
	avatar.Parent = playerItem

	ThemeModule.CreateCorner(avatar, avatarSize / 2)

	task.spawn(function()
		local success, result = pcall(function()
			return Players:GetUserThumbnailAsync(plr.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size150x150)
		end)
		if success and avatar and avatar.Parent then
			avatar.Image = result
		end
	end)

	local infoContainer = Instance.new("Frame")
	infoContainer.Size = UDim2.new(1, -avatarSize - 28, 1, -10)
	infoContainer.Position = UDim2.new(0, avatarSize + 18, 0.5, 0)
	infoContainer.AnchorPoint = Vector2.new(0, 0.5)
	infoContainer.BackgroundTransparency = 1
	infoContainer.Parent = playerItem

	local infoLayout = Instance.new("UIListLayout")
	infoLayout.SortOrder = Enum.SortOrder.LayoutOrder
	infoLayout.FillDirection = Enum.FillDirection.Vertical
	infoLayout.VerticalAlignment = Enum.VerticalAlignment.Center
	infoLayout.Padding = UDim.new(0, 3)
	infoLayout.Parent = infoContainer

	local isPremium = (plr.MembershipType == Enum.MembershipType.Premium)
	local isVerified = false
	pcall(function()
		isVerified = plr.HasVerifiedBadge
	end)
	local premiumPrefix = isPremium and (utf8.char(57345) .. " ") or ""
	local verifiedSuffix = isVerified and utf8.char(57344) or ""

	local displayName = Instance.new("TextLabel")
	displayName.Text = premiumPrefix .. plr.DisplayName .. verifiedSuffix
	displayName.Size = UDim2.new(1, 0, 0, getTextSize("displayName") + 2)
	displayName.BackgroundTransparency = 1
	displayName.TextColor3 = ThemeModule.GetThemeColor(plr:GetAttribute("CurrentTheme"))
	displayName.TextSize = getTextSize("displayName")
	displayName.TextXAlignment = Enum.TextXAlignment.Left
	displayName.TextYAlignment = Enum.TextYAlignment.Center
	displayName.Font = Enum.Font.GothamBold
	displayName.TextTruncate = Enum.TextTruncate.AtEnd
	displayName.LayoutOrder = 1
	displayName.Parent = infoContainer

	local themeConn = plr:GetAttributeChangedSignal("CurrentTheme"):Connect(function()
		displayName.TextColor3 = ThemeModule.GetThemeColor(plr:GetAttribute("CurrentTheme"))
	end)

	local username = Instance.new("TextLabel")
	username.Text = "@" .. plr.Name
	username.Size = UDim2.new(1, 0, 0, getTextSize("username") + 2)
	username.BackgroundTransparency = 1
	username.TextColor3 = CONFIG.Colors.PlayerList.UsernameText
	username.TextSize = getTextSize("username")
	username.TextXAlignment = Enum.TextXAlignment.Left
	username.TextYAlignment = Enum.TextYAlignment.Center
	username.Font = Enum.Font.Gotham
	username.TextTruncate = Enum.TextTruncate.AtEnd
	username.LayoutOrder = 2
	username.Parent = infoContainer

	local rankLabel = Instance.new("TextLabel")
	rankLabel.Name = "RankLabel"
	rankLabel.Size = UDim2.new(1, 0, 0, getTextSize("username"))
	rankLabel.BackgroundTransparency = 1
	rankLabel.TextColor3 = ThemeModule.Colors.TextGray or Color3.fromRGB(180, 185, 195)
	rankLabel.TextSize = math.max(10, getTextSize("username") - 1)
	rankLabel.TextXAlignment = Enum.TextXAlignment.Left
	rankLabel.TextYAlignment = Enum.TextYAlignment.Center
	rankLabel.Font = Enum.Font.Gotham
	rankLabel.TextTruncate = Enum.TextTruncate.AtEnd
	rankLabel.LayoutOrder = 3
	rankLabel.Parent = infoContainer

	local plrRank = getPlayerGroupRank(plr, function(txt)
		if rankLabel and rankLabel.Parent then
			if txt and MenuConfig.UserSettings.game_rank ~= false then
				rankLabel.Text = txt
				rankLabel.Visible = true
			else
				rankLabel.Visible = false
			end
		end
	end)

	if plrRank and MenuConfig.UserSettings.game_rank ~= false then
		rankLabel.Text = plrRank
		rankLabel.Visible = true
	else
		rankLabel.Visible = false
	end

	local originalBgTransparency = playerItem.BackgroundTransparency
	local originalBgColor = playerItem.BackgroundColor3

	playerItem.MouseButton1Click:Connect(function()
		if MenuConfig.OpenProfileCard then
			MenuConfig.OpenProfileCard(plr)
		end
	end)

	playerItem.MouseEnter:Connect(function()
		TweenService:Create(playerItem, TweenInfo.new(0.15), {
			BackgroundTransparency = 0,
			BackgroundColor3 = CONFIG.Colors.PlayerList.ItemHover
		}):Play()
	end)

	playerItem.MouseLeave:Connect(function()
		TweenService:Create(playerItem, TweenInfo.new(0.15), {
			BackgroundTransparency = originalBgTransparency,
			BackgroundColor3 = originalBgColor
		}):Play()
	end)

	playerItem.Destroying:Connect(function()
		themeConn:Disconnect()
	end)

	return playerItem
end

local function createDivider(layoutOrder)
	local dividerContainer = Instance.new("Frame")
	dividerContainer.Name = "Divider"
	dividerContainer.Size = UDim2.new(1, 0, 0, 1)
	dividerContainer.BackgroundTransparency = 1
	dividerContainer.LayoutOrder = layoutOrder
	dividerContainer.Parent = playersScroll

	local divider = Instance.new("Frame")
	divider.Size = UDim2.new(1, -20, 0, 1)
	divider.Position = UDim2.new(0.5, 0, 0.5, 0)
	divider.AnchorPoint = Vector2.new(0.5, 0.5)
	divider.BackgroundColor3 = ThemeModule.Colors.Primary1
	divider.BackgroundTransparency = 0.6
	divider.BorderSizePixel = 0
	divider.Parent = dividerContainer

	return dividerContainer
end

local function createSpacer(layoutOrder, height)
	local spacer = Instance.new("Frame")
	spacer.Name = "Spacer"
	spacer.Size = UDim2.new(1, 0, 0, height or 4)
	spacer.BackgroundTransparency = 1
	spacer.LayoutOrder = layoutOrder
	spacer.Parent = playersScroll
	return spacer
end

local function updatePlayerList()
	for _, child in pairs(playersScroll:GetChildren()) do
		if not child:IsA("UIListLayout") and not child:IsA("UICorner") and not child:IsA("UIPadding") then
			child:Destroy()
		end
	end

	local layoutOrder = 0
	local friendsInServer = getFriendsInServer()
	local allPlayers = Players:GetPlayers()

	local friendIds = {}
	for _, friend in ipairs(friendsInServer) do
		friendIds[friend.UserId] = true
	end

	createSectionHeader("ProfileHeader", "👤 Profil Saya", layoutOrder)
	layoutOrder = layoutOrder + 1
	createSpacer(layoutOrder, 4)
	layoutOrder = layoutOrder + 1
	createMyProfile(layoutOrder)
	layoutOrder = layoutOrder + 1
	createSpacer(layoutOrder, 4)
	layoutOrder = layoutOrder + 1
	createGameRankOption(layoutOrder)
	layoutOrder = layoutOrder + 1
	createSpacer(layoutOrder, 8)
	layoutOrder = layoutOrder + 1
	createDivider(layoutOrder)
	layoutOrder = layoutOrder + 1
	createSpacer(layoutOrder, 8)
	layoutOrder = layoutOrder + 1

	if #friendsInServer > 0 then
		createSectionHeader("ConnectionHeader", "🔗 Koneksi (" .. #friendsInServer .. " teman)", layoutOrder)
		layoutOrder = layoutOrder + 1
		createSpacer(layoutOrder, 4)
		layoutOrder = layoutOrder + 1
		for _, friend in ipairs(friendsInServer) do
			createPlayerItem(friend, layoutOrder, true, true)
			layoutOrder = layoutOrder + 1
		end
		createSpacer(layoutOrder, 8)
		layoutOrder = layoutOrder + 1
		createDivider(layoutOrder)
		layoutOrder = layoutOrder + 1
		createSpacer(layoutOrder, 8)
		layoutOrder = layoutOrder + 1
	end

	createSectionHeader("AllPlayerHeader", "👥 Semua Pemain (" .. #allPlayers .. ")", layoutOrder)
	layoutOrder = layoutOrder + 1
	createSpacer(layoutOrder, 4)
	layoutOrder = layoutOrder + 1
	for _, plr in ipairs(allPlayers) do
		local isFriend = friendIds[plr.UserId] or false
		createPlayerItem(plr, layoutOrder, isFriend, false)
		layoutOrder = layoutOrder + 1
	end

	createSpacer(layoutOrder, 12)
end

local function updatePlayersLayout()
	if MenuConfig.State.isMenuOpen and MenuConfig.State.currentMainTab == "Pemain" then
		updatePlayerList()
	end
end

MenuConfig.Events.OnScreenResized.Event:Connect(function()
	updatePlayersLayout()
end)

MenuConfig.Events.OnMenuToggled.Event:Connect(function(isOpen)
	if isOpen and MenuConfig.State.currentMainTab == "Pemain" then
		updatePlayerList()
	end
end)

MenuConfig.Events.OnTabChanged.Event:Connect(function(tab)
	if tab == "Pemain" then
		updatePlayerList()
	end
end)

MenuConfig.Events.OnThemeChanged.Event:Connect(function()
	if MenuConfig.State.isMenuOpen and MenuConfig.State.currentMainTab == "Pemain" then
		updatePlayerList()
	end
end)

MenuConfig.Events.OnColorChanged.Event:Connect(function()
	if MenuConfig.State.isMenuOpen and MenuConfig.State.currentMainTab == "Pemain" then
		updatePlayerList()
	end
end)

MenuConfig.Events.OnSettingChanged.Event:Connect(function(key, value)
	if key == "game_rank" then
		updateAllOverheadsRank(value ~= false)
		for _, child in ipairs(playersScroll:GetDescendants()) do
			if child.Name == "RankLabel" and child:IsA("TextLabel") then
				child.Visible = (value ~= false)
			end
		end
	end
end)

workspace.DescendantAdded:Connect(function(desc)
	if desc.Name == "GuestLabel" and desc:IsA("TextLabel") then
		task.wait(0.05)
		local isRankEnabled = MenuConfig.UserSettings.game_rank ~= false
		local isRank = desc:GetAttribute("IsRank")
		desc.Visible = (isRankEnabled and isRank == true)
	end
end)

Players.PlayerAdded:Connect(function(plr)
	plr.CharacterAdded:Connect(function(char)
		task.wait(0.2)
		updateCharacterOverheadRank(char, MenuConfig.UserSettings.game_rank ~= false)
	end)

	if MenuConfig.State.isMenuOpen and MenuConfig.State.currentMainTab == "Pemain" then
		updatePlayerList()
	end
end)

for _, plr in ipairs(Players:GetPlayers()) do
	plr.CharacterAdded:Connect(function(char)
		task.wait(0.2)
		updateCharacterOverheadRank(char, MenuConfig.UserSettings.game_rank ~= false)
	end)
end

Players.PlayerRemoving:Connect(function(leavingPlayer)
	groupRankCache[leavingPlayer.UserId] = nil
	task.wait(0.1)
	if MenuConfig.State.isMenuOpen and MenuConfig.State.currentMainTab == "Pemain" then
		updatePlayerList()
	end
end)

task.spawn(function()
	task.wait(0.5)
	updateAllOverheadsRank(MenuConfig.UserSettings.game_rank ~= false)
	if MenuConfig.State.isMenuOpen and MenuConfig.State.currentMainTab == "Pemain" then
		updatePlayerList()
	end
end)

if MenuConfig and MenuConfig.Events and MenuConfig.Events.OnColorChanged then
	MenuConfig.Events.OnColorChanged.Event:Connect(function()
		local isRankEnabled = MenuConfig.UserSettings.game_rank ~= false
		local targetColor = isRankEnabled
			and (ThemeModule.Colors.Primary1 or Color3.fromRGB(60, 150, 240))
			or Color3.fromRGB(80, 80, 90)
		for _, desc in ipairs(playersScroll:GetDescendants()) do
			if desc.Name == "ToggleBg" and desc:IsA("Frame") then
				desc.BackgroundColor3 = targetColor
			elseif desc:IsA("UIGradient") and ThemeModule and ThemeModule.Gradients then
				desc.Color = ThemeModule.Gradients.Primary
			end
		end
	end)
end

print("✅ [PlayerClient] Berhasil Dimuat!")

