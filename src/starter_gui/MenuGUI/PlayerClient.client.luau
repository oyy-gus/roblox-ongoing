-- ========================================
-- PLAYER CLIENT - Daftar Pemain
-- Place in: StarterGui > MenuGUI(ScreenGui) > PlayerClient(LocalScript)
-- ========================================

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")

-- Load Modules
local Modules = ReplicatedStorage:WaitForChild("Modules")
local MenuConfig = require(Modules:WaitForChild("MenuConfig"))
local ThemeModule = require(Modules:WaitForChild("ThemeModule"))

-- Tunggu GUI siap
MenuConfig.WaitForGUIReady(15)

-- Pastikan PlayersPage sudah ada
repeat task.wait() until MenuConfig.GUI.PlayersPage

-- ========================================
-- REFERENSI
-- ========================================
local playersPage = MenuConfig.GUI.PlayersPage
local localPlayer = Players.LocalPlayer
local CONFIG = MenuConfig.GetConfig()

-- ========================================
-- FUNGSI PEMBANTU INFO LAYAR
-- ========================================
local function getScreenParams()
	local screenInfo = MenuConfig.GetScreenInfo()
	return {
		isMobile = screenInfo.isMobile,
		isLandscape = screenInfo.isLandscape,
		width = screenInfo.width,
		height = screenInfo.height
	}
end

-- ========================================
-- FUNGSI PEMBANTU UKURAN SKALA
-- ========================================
local function getPlayerItemHeight()
	local screenInfo = MenuConfig.GetScreenInfo()
	if screenInfo.isMobile and screenInfo.isLandscape then
		return math.floor(MenuConfig.GetScaledValue(50, 44, 58))
	else
		return math.floor(MenuConfig.GetScaledValue(60, 52, 70))
	end
end

local function getMyProfileHeight()
	local screenInfo = MenuConfig.GetScreenInfo()
	if screenInfo.isMobile and screenInfo.isLandscape then
		return math.floor(MenuConfig.GetScaledValue(60, 52, 70))
	else
		return math.floor(MenuConfig.GetScaledValue(70, 60, 82))
	end
end

local function getTextSize(textType)
	local screenInfo = MenuConfig.GetScreenInfo()
	local sizes = {
		header = {base = 15, min = 12, max = 18},
		displayName = {base = 15, min = 11, max = 17},
		username = {base = 12, min = 9, max = 14},
		profileName = {base = 17, min = 13, max = 20},
		profileUsername = {base = 13, min = 10, max = 15},
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

-- ========================================
-- WARNA
-- ========================================
local PROFILE_COLORS = {
	Background = CONFIG.Colors.PlayerList.ProfileBg or Color3.fromRGB(40, 45, 55),
}

-- ========================================
-- FUNGSI HELPER
-- ========================================
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

-- ========================================
-- SCROLL PEMAIN
-- ========================================
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
playersScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y  -- Auto resize canvas
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

-- ========================================
-- FUNGSI BUAT HEADER BAGIAN (dengan gradient)
-- ========================================
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

	-- Apply gradient dari ThemeModule
	ThemeModule.CreatePrimaryGradient(header, 0, 1)

	Instance.new("UITextSizeConstraint", header).MaxTextSize = getTextSize("header")
	return header
end

-- ========================================
-- FUNGSI BUAT PROFIL SAYA
-- ========================================
local function createMyProfile(layoutOrder)
	local profileHeight = getMyProfileHeight()

	local profileFrame = Instance.new("TextButton")  -- Ubah ke TextButton langsung
	profileFrame.Name = "MyProfile"
	profileFrame.Size = UDim2.new(1, 0, 0, profileHeight)
	profileFrame.BackgroundColor3 = PROFILE_COLORS.Background
	profileFrame.BorderSizePixel = 0
	profileFrame.LayoutOrder = layoutOrder
	profileFrame.Text = ""
	profileFrame.AutoButtonColor = false
	profileFrame.Parent = playersScroll

	ThemeModule.CreateCorner(profileFrame, CONFIG.Layout.ButtonCorner)

	-- Stroke dengan gradient dari ThemeModule
	local profileStroke, profileStrokeGradient = ThemeModule.CreateAnimatedStroke(profileFrame, 2, "Primary", 1.2)
	profileStroke.Name = "ProfileBorder"
	profileStroke.Transparency = 0.2

	local avatarSize = profileHeight - 16
	local avatar = Instance.new("ImageLabel")
	avatar.Name = "Avatar"
	avatar.Size = UDim2.new(0, avatarSize, 0, avatarSize)
	avatar.Position = UDim2.new(0, 8, 0.5, 0)
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

	-- Container untuk nama
	local infoContainer = Instance.new("Frame")
	infoContainer.Name = "InfoContainer"
	infoContainer.Size = UDim2.new(1, -avatarSize - 24, 0, avatarSize)
	infoContainer.Position = UDim2.new(0, avatarSize + 16, 0.5, 0)
	infoContainer.AnchorPoint = Vector2.new(0, 0.5)
	infoContainer.BackgroundTransparency = 1
	infoContainer.Parent = profileFrame

	local displayName = Instance.new("TextLabel")
	displayName.Name = "DisplayName"
	displayName.Text = localPlayer.DisplayName
	displayName.Size = UDim2.new(1, 0, 0.55, 0)
	displayName.Position = UDim2.new(0, 0, 0, 0)
	displayName.BackgroundTransparency = 1
	displayName.TextColor3 = Color3.new(1, 1, 1)
	displayName.TextScaled = true
	displayName.TextXAlignment = Enum.TextXAlignment.Left
	displayName.TextYAlignment = Enum.TextYAlignment.Bottom
	displayName.Font = Enum.Font.GothamBold
	displayName.TextTruncate = Enum.TextTruncate.AtEnd
	displayName.Parent = infoContainer

	-- Gradient untuk display name
	ThemeModule.CreatePrimaryGradient(displayName, 0, 1)

	Instance.new("UITextSizeConstraint", displayName).MaxTextSize = getTextSize("profileName")

	local username = Instance.new("TextLabel")
	username.Name = "Username"
	username.Text = "@" .. localPlayer.Name
	username.Size = UDim2.new(1, 0, 0.45, 0)
	username.Position = UDim2.new(0, 0, 0.55, 0)
	username.BackgroundTransparency = 1
	username.TextColor3 = CONFIG.Colors.PlayerList.UsernameText
	username.TextScaled = true
	username.TextXAlignment = Enum.TextXAlignment.Left
	username.TextYAlignment = Enum.TextYAlignment.Top
	username.Font = Enum.Font.GothamSemibold
	username.TextTruncate = Enum.TextTruncate.AtEnd
	username.Parent = infoContainer

	Instance.new("UITextSizeConstraint", username).MaxTextSize = getTextSize("profileUsername")

	profileFrame:SetAttribute("IsMyProfile", true)

	-- Event handlers langsung di profileFrame
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

	return profileFrame
end

-- ========================================
-- FUNGSI BUAT ITEM PEMAIN
-- ========================================
local function createPlayerItem(plr, layoutOrder, isFriend, isInConnectionSection)
	local itemHeight = getPlayerItemHeight()

	local playerItem = Instance.new("TextButton")  -- Ubah ke TextButton langsung
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

	-- Stroke untuk Connection section dengan gradient
	if isInConnectionSection then
		local connectionStroke, connectionGradient = ThemeModule.CreateAnimatedStroke(playerItem, 1.5, "Primary", 1)
		connectionStroke.Transparency = 0.4
	end

	local avatarSize = itemHeight - 12
	local avatar = Instance.new("ImageLabel")
	avatar.Size = UDim2.new(0, avatarSize, 0, avatarSize)
	avatar.Position = UDim2.new(0, 6, 0.5, 0)
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

	-- Info container
	local infoContainer = Instance.new("Frame")
	infoContainer.Size = UDim2.new(1, -avatarSize - 18, 0, avatarSize)
	infoContainer.Position = UDim2.new(0, avatarSize + 12, 0.5, 0)
	infoContainer.AnchorPoint = Vector2.new(0, 0.5)
	infoContainer.BackgroundTransparency = 1
	infoContainer.Parent = playerItem

	local displayName = Instance.new("TextLabel")
	displayName.Text = plr.DisplayName
	displayName.Size = UDim2.new(1, 0, 0.55, 0)
	displayName.Position = UDim2.new(0, 0, 0, 0)
	displayName.BackgroundTransparency = 1
	displayName.TextColor3 = CONFIG.Colors.PlayerList.NameText
	displayName.TextScaled = true
	displayName.TextXAlignment = Enum.TextXAlignment.Left
	displayName.TextYAlignment = Enum.TextYAlignment.Bottom
	displayName.Font = Enum.Font.GothamBold
	displayName.TextTruncate = Enum.TextTruncate.AtEnd
	displayName.Parent = infoContainer

	-- Gradient untuk nama di connection section
	if isInConnectionSection then
		displayName.TextColor3 = Color3.new(1, 1, 1)
		ThemeModule.CreatePrimaryGradient(displayName, 0, 1)
	end

	Instance.new("UITextSizeConstraint", displayName).MaxTextSize = getTextSize("displayName")

	local username = Instance.new("TextLabel")
	username.Text = "@" .. plr.Name
	username.Size = UDim2.new(1, 0, 0.45, 0)
	username.Position = UDim2.new(0, 0, 0.55, 0)
	username.BackgroundTransparency = 1
	username.TextColor3 = CONFIG.Colors.PlayerList.UsernameText
	username.TextScaled = true
	username.TextXAlignment = Enum.TextXAlignment.Left
	username.TextYAlignment = Enum.TextYAlignment.Top
	username.Font = Enum.Font.Gotham
	username.TextTruncate = Enum.TextTruncate.AtEnd
	username.Parent = infoContainer

	Instance.new("UITextSizeConstraint", username).MaxTextSize = getTextSize("username")

	local originalBgTransparency = playerItem.BackgroundTransparency
	local originalBgColor = playerItem.BackgroundColor3

	-- Event handlers langsung di playerItem
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

	return playerItem
end

-- ========================================
-- BUAT PEMBATAS & SPASI
-- ========================================
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

-- ========================================
-- FUNGSI UPDATE DAFTAR PEMAIN
-- ========================================
local function updatePlayerList()
	-- Hapus semua children kecuali UIListLayout, UICorner, UIPadding
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

	-- PROFIL SAYA
	createSectionHeader("ProfileHeader", "👤 Profil Saya", layoutOrder)
	layoutOrder = layoutOrder + 1
	createSpacer(layoutOrder, 4)
	layoutOrder = layoutOrder + 1
	createMyProfile(layoutOrder)
	layoutOrder = layoutOrder + 1
	createSpacer(layoutOrder, 8)
	layoutOrder = layoutOrder + 1
	createDivider(layoutOrder)
	layoutOrder = layoutOrder + 1
	createSpacer(layoutOrder, 8)
	layoutOrder = layoutOrder + 1

	-- KONEKSI (Teman)
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

	-- SEMUA PEMAIN
	createSectionHeader("AllPlayerHeader", "👥 Semua Pemain (" .. #allPlayers .. ")", layoutOrder)
	layoutOrder = layoutOrder + 1
	createSpacer(layoutOrder, 4)
	layoutOrder = layoutOrder + 1
	for _, plr in ipairs(allPlayers) do
		local isFriend = friendIds[plr.UserId] or false
		createPlayerItem(plr, layoutOrder, isFriend, false)
		layoutOrder = layoutOrder + 1
	end

	-- Tambah spacer di akhir untuk padding bawah
	createSpacer(layoutOrder, 12)
end

-- ========================================
-- FUNGSI UPDATE TATA LETAK
-- ========================================
local function updatePlayersLayout()
	if MenuConfig.State.isMenuOpen and MenuConfig.State.currentMainTab == "Pemain" then
		updatePlayerList()
	end
end

-- ========================================
-- EVENT LISTENERS
-- ========================================
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

Players.PlayerAdded:Connect(function()
	if MenuConfig.State.isMenuOpen and MenuConfig.State.currentMainTab == "Pemain" then
		updatePlayerList()
	end
end)

Players.PlayerRemoving:Connect(function(leavingPlayer)
	task.wait(0.1)
	if MenuConfig.State.isMenuOpen and MenuConfig.State.currentMainTab == "Pemain" then
		updatePlayerList()
	end
end)

-- ========================================
-- PEMUATAN AWAL
-- ========================================
task.spawn(function()
	task.wait(0.5)
	if MenuConfig.State.isMenuOpen and MenuConfig.State.currentMainTab == "Pemain" then
		updatePlayerList()
	end
end)

print("✅ [PlayerClient] Berhasil Dimuat!")
