-- ============================================================
-- OverheadHandler (Updated)
-- Fix: overhead hilang setelah /re (ApplyDescription)
-- Place in: StarterScriptService > OverheadSystem(Folder) > OverheadHandler(Script)
-- ============================================================

local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage     = game:GetService("ServerStorage")

local RoleSystem      = require(ServerStorage.Modules.RoleSystem)
local CountryService  = require(ReplicatedStorage.Modules.CountryService)
local DataStoreModule = require(script.Parent.Parent:WaitForChild("GiveSystem"):WaitForChild("Title"):WaitForChild("DataStoreModule"))
local TitleRenderer   = require(script.Parent.Parent:WaitForChild("GiveSystem"):WaitForChild("Title"):WaitForChild("TitleRenderer"))

local OverheadTemplate = ReplicatedStorage:WaitForChild("UI"):WaitForChild("Overhead")

-- ============================================================
-- CONFIG
-- ============================================================
local Config = {
	GROUP_ID = 550072302,

	RoleColors = {
		Owner      = Color3.fromRGB(255, 170, 90),
		Developer  = Color3.fromRGB(120, 200, 140),
		Admin      = Color3.fromRGB(200, 80, 80),
		Streamer   = Color3.fromRGB(170, 140, 255),
		Creator    = Color3.fromRGB(120, 220, 220),
		VIP        = Color3.fromRGB(255, 210, 120),
		Guest      = Color3.fromRGB(140, 140, 140),
		PlayerName = Color3.fromRGB(220, 235, 255),
	},

	DisplayText = {
		Owner     = "👑 OWNER 👑",
		Developer = "⚙️ DEVELOPER ⚙️",
		Admin     = "🛡️ ADMIN 🛡️",
		Streamer  = "🔴 STREAMER 🔴",
		Creator   = "🎨 CREATOR 🎨",
		VIP       = "⭐ VIP ⭐",
		Guest     = "GUEST",
	},

	StrokeColors = {
		Owner      = Color3.fromRGB(0, 0, 0),
		Developer  = Color3.fromRGB(0, 0, 0),
		Admin      = Color3.fromRGB(0, 0, 0),
		Streamer   = Color3.fromRGB(0, 0, 0),
		Creator    = Color3.fromRGB(0, 0, 0),
		VIP        = Color3.fromRGB(0, 0, 0),
		Guest      = Color3.fromRGB(0, 0, 0),
		PlayerName = Color3.fromRGB(0, 0, 0),
	},

	StrokeTransparency = 0.5,

	LayoutOrder = {
		StaffLabel    = 1,
		StreamerLabel = 2,
		CreatorLabel  = 3,
		VIPLabel      = 4,
		Icons         = 5,
		PlayerName    = 6,
		GuestLabel    = 7,
	
	},

	LabelSize          = UDim2.new(1, 0, 0.037, 0),
	ListLayoutPadding  = UDim.new(0.009, 0),
	IconImageSize      = UDim2.new(0.2, 0, 0.55, 0),
	IconTextSize       = UDim2.new(0.2, 0, 0.55, 0),
	IconsLayoutPadding = UDim.new(0.02, 0),
}

-- ============================================================
-- DISABLE DEFAULT NAMETAGS
-- ============================================================
local nametagConnections = {}

local function disableDefaultNametag(player, character)
	local humanoid = character:WaitForChild("Humanoid", 5)
	if not humanoid then return end
	humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None

	if nametagConnections[player.UserId] then
		nametagConnections[player.UserId]:Disconnect()
	end

	nametagConnections[player.UserId] = humanoid:GetPropertyChangedSignal("DisplayDistanceType"):Connect(function()
		if humanoid.DisplayDistanceType ~= Enum.HumanoidDisplayDistanceType.None then
			humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
		end
	end)
end

-- ============================================================
-- HELPERS
-- ============================================================
local function isStaffRole(role)
	return role == "Owner" or role == "Developer" or role == "Admin"
end

-- ============================================================
-- GROUP MEMBERSHIP CACHE
-- ============================================================
local groupMembershipCache = {}

local function isPlayerInGroup(player)
	local userId = player.UserId
	if groupMembershipCache[userId] ~= nil then
		return groupMembershipCache[userId]
	end
	local success, isInGroup = pcall(function()
		return player:IsInGroupAsync(Config.GROUP_ID)
	end)
	if success then
		groupMembershipCache[userId] = isInGroup
		return isInGroup
	end
	return false
end

-- ============================================================
-- STROKE SYSTEM
-- ============================================================
local function applyStroke(label, strokeType)
	if not label then return end
	label.TextStrokeColor3       = Config.StrokeColors[strokeType] or Config.StrokeColors.PlayerName
	label.TextStrokeTransparency = Config.StrokeTransparency
end

local function hideStroke(label)
	if not label then return end
	label.TextStrokeTransparency = 1
end

-- ============================================================
-- SIZE & LAYOUT
-- ============================================================
local function applySizes(canvas)
	for _, name in ipairs({"StaffLabel","StreamerLabel","CreatorLabel","VIPLabel","PlayerName","GuestLabel"}) do
		local el = canvas:FindFirstChild(name)
		if el then el.Size = Config.LabelSize end
	end
end

local function applyListLayoutPadding(canvas)
	local layout = canvas:FindFirstChildWhichIsA("UIListLayout")
	if layout then layout.Padding = Config.ListLayoutPadding end
end

local function applyIconsSizes(iconsFrame)
	for _, name in ipairs({"Computer","Phone","Premium","VIP","Verified"}) do
		local icon = iconsFrame:FindFirstChild(name)
		if icon then icon.Size = Config.IconImageSize end
	end
	local country = iconsFrame:FindFirstChild("Country")
	if country then country.Size = Config.IconTextSize end
	local layout = iconsFrame:FindFirstChildWhichIsA("UIListLayout")
	if layout then layout.Padding = Config.IconsLayoutPadding end
end

-- ============================================================
-- UPDATE ICONS
-- ============================================================
local function updateIcons(player, iconsFrame)
	if not iconsFrame then return end
	applyIconsSizes(iconsFrame)

	local computerIcon = iconsFrame:FindFirstChild("Computer")
	local phoneIcon    = iconsFrame:FindFirstChild("Phone")
	local premiumIcon  = iconsFrame:FindFirstChild("Premium")
	local vipIcon      = iconsFrame:FindFirstChild("VIP")
	local verifiedIcon = iconsFrame:FindFirstChild("Verified")
	local countryIcon  = iconsFrame:FindFirstChild("Country")

	if computerIcon then computerIcon.Visible = false end
	if phoneIcon    then phoneIcon.Visible    = false end
	if premiumIcon  then premiumIcon.Visible  = false end
	if vipIcon      then vipIcon.Visible      = false end
	if verifiedIcon then verifiedIcon.Visible = false end
	if countryIcon  then countryIcon.Visible  = false end

	if vipIcon      then vipIcon.Visible      = RoleSystem:HasVIP(player)                              end
	if verifiedIcon then verifiedIcon.Visible = isPlayerInGroup(player)                                end
	if premiumIcon  then premiumIcon.Visible  = (player.MembershipType == Enum.MembershipType.Premium) end

	if countryIcon then
		local success, country = pcall(function()
			return CountryService:GetPlayerCountry(player)
		end)
		if success and country then
			countryIcon.Text    = country.Emoji
			countryIcon.Visible = true
		end
	end

	local getDeviceRemote = ReplicatedStorage:WaitForChild("Remotes"):FindFirstChild("GetDevice")
	if getDeviceRemote and getDeviceRemote:IsA("RemoteFunction") then
		task.spawn(function()
			local success, isMobile = pcall(function()
				return getDeviceRemote:InvokeClient(player)
			end)
			if success then
				if computerIcon then computerIcon.Visible = not isMobile end
				if phoneIcon    then phoneIcon.Visible    = isMobile     end
			else
				if computerIcon then computerIcon.Visible = true end
			end
		end)
	else
		if computerIcon then computerIcon.Visible = true end
	end

	iconsFrame.Visible = true
end

-- ============================================================
-- UPDATE LABELS (role, name, icons)
-- ============================================================
local function updateOverheadLabels(player, overhead)
	local canvas = overhead:FindFirstChild("Canvas")
	if not canvas then return end

	applySizes(canvas)
	applyListLayoutPadding(canvas)

	local role       = RoleSystem:GetPlayerRole(player)
	local hasVIP     = RoleSystem:HasVIP(player)
	local hasStreamer = RoleSystem:HasStreamer(player)
	local hasCreator = RoleSystem:HasCreator(player)

	local staffLabel      = canvas:FindFirstChild("StaffLabel")
	local streamerLabel   = canvas:FindFirstChild("StreamerLabel")
	local creatorLabel    = canvas:FindFirstChild("CreatorLabel")
	local vipLabel        = canvas:FindFirstChild("VIPLabel")
	local playerNameLabel = canvas:FindFirstChild("PlayerName")
	local guestLabel      = canvas:FindFirstChild("GuestLabel")
	local iconsFrame      = canvas:FindFirstChild("Icons")

	if not playerNameLabel then return end

	-- Reset semua
	if staffLabel      then staffLabel.Visible      = false; hideStroke(staffLabel)      end
	if streamerLabel   then streamerLabel.Visible   = false; hideStroke(streamerLabel)   end
	if creatorLabel    then creatorLabel.Visible    = false; hideStroke(creatorLabel)    end
	if vipLabel        then vipLabel.Visible        = false; hideStroke(vipLabel)        end
	if playerNameLabel then playerNameLabel.Visible = false; hideStroke(playerNameLabel) end
	if guestLabel      then guestLabel.Visible      = false; hideStroke(guestLabel)      end
	if iconsFrame      then iconsFrame.Visible      = false                              end

	-- Staff Role
	if staffLabel and isStaffRole(role) then
		staffLabel.Text        = Config.DisplayText[role] or role
		staffLabel.TextColor3  = Config.RoleColors[role] or Config.RoleColors.Guest
		staffLabel.LayoutOrder = Config.LayoutOrder.StaffLabel
		staffLabel.Visible     = true
		applyStroke(staffLabel, role)
	end

	-- Streamer Badge
	if streamerLabel and (role == "Streamer" or hasStreamer) then
		streamerLabel.Text        = Config.DisplayText.Streamer
		streamerLabel.TextColor3  = Config.RoleColors.Streamer
		streamerLabel.LayoutOrder = Config.LayoutOrder.StreamerLabel
		streamerLabel.Visible     = true
		applyStroke(streamerLabel, "Streamer")
	end

	-- Creator Badge
	if creatorLabel and (role == "Creator" or hasCreator) then
		creatorLabel.Text        = Config.DisplayText.Creator
		creatorLabel.TextColor3  = Config.RoleColors.Creator
		creatorLabel.LayoutOrder = Config.LayoutOrder.CreatorLabel
		creatorLabel.Visible     = true
		applyStroke(creatorLabel, "Creator")
	end

	-- VIP Badge
	if vipLabel and (role == "VIP" or hasVIP) then
		vipLabel.Text        = Config.DisplayText.VIP
		vipLabel.TextColor3  = Config.RoleColors.VIP
		vipLabel.LayoutOrder = Config.LayoutOrder.VIPLabel
		vipLabel.Visible     = true
		applyStroke(vipLabel, "VIP")
	end

	-- Player Name (selalu tampil)
	playerNameLabel.Text        = player.DisplayName
	playerNameLabel.TextColor3  = Config.RoleColors.PlayerName
	playerNameLabel.LayoutOrder = Config.LayoutOrder.PlayerName
	playerNameLabel.Visible     = true
	applyStroke(playerNameLabel, "PlayerName")

	-- Guest Label
	if guestLabel and role == "Guest" and not hasVIP and not hasStreamer and not hasCreator then
		guestLabel.Text        = Config.DisplayText.Guest
		guestLabel.TextColor3  = Config.RoleColors.Guest
		guestLabel.LayoutOrder = Config.LayoutOrder.GuestLabel
		guestLabel.Visible     = true
		applyStroke(guestLabel, "Guest")
	end

	-- Icons
	if iconsFrame then
		iconsFrame.LayoutOrder = Config.LayoutOrder.Icons
		updateIcons(player, iconsFrame)
	end
end

-- ============================================================
-- OVERHEAD MANAGEMENT
-- ============================================================
local activeOverheads = {}

local function removeOverhead(player)
	if activeOverheads[player.UserId] then
		activeOverheads[player.UserId]:Destroy()
		activeOverheads[player.UserId] = nil
	end
end

local function createOverhead(player, character)
	removeOverhead(player)

	local head = character:WaitForChild("Head", 5)
	if not head then
		warn("[OverheadHandler] Head not found for:", player.Name)
		return
	end

	local overhead = OverheadTemplate:Clone()
	overhead.Adornee = head
	overhead.Parent  = head

	updateOverheadLabels(player, overhead)

	task.spawn(function()
		task.wait(0.3)
		local titles = DataStoreModule:LoadTitlesForUserId(player.UserId) or {}
		TitleRenderer:RenderAllTitles(player, character, titles)
	end)

	activeOverheads[player.UserId] = overhead
	return overhead
end

local function updateOverhead(player)
	local overhead = activeOverheads[player.UserId]
	if not overhead then return end
	updateOverheadLabels(player, overhead)
end

-- ============================================================
-- PLAYER EVENTS
-- ============================================================
local function onCharacterAdded(player, character)
	task.wait(0.1)
	disableDefaultNametag(player, character)
	createOverhead(player, character)
end

local function onPlayerAdded(player)
	RoleSystem:InitializePlayer(player)

	if player.Character then
		onCharacterAdded(player, player.Character)
	end

	player.CharacterAdded:Connect(function(character)
		onCharacterAdded(player, character)
	end)
end

local function onPlayerRemoving(player)
	if nametagConnections[player.UserId] then
		nametagConnections[player.UserId]:Disconnect()
		nametagConnections[player.UserId] = nil
	end
	groupMembershipCache[player.UserId] = nil
	removeOverhead(player)
end

-- ============================================================
-- ROLE LISTENERS
-- ============================================================
RoleSystem.RoleChanged:Connect(function(player)    updateOverhead(player) end)
RoleSystem.VIPChanged:Connect(function(player)     updateOverhead(player) end)
RoleSystem.StreamerChanged:Connect(function(player) updateOverhead(player) end)
RoleSystem.CreatorChanged:Connect(function(player)  updateOverhead(player) end)

-- ============================================================
-- GROUP MEMBERSHIP UPDATE
-- ============================================================
local groupJoinedRemote = ReplicatedStorage:FindFirstChild("GroupJoined")
if not groupJoinedRemote then
	groupJoinedRemote = Instance.new("RemoteEvent")
	groupJoinedRemote.Name   = "GroupJoined"
	groupJoinedRemote.Parent = ReplicatedStorage
end

groupJoinedRemote.OnServerEvent:Connect(function(player)
	groupMembershipCache[player.UserId] = nil
	isPlayerInGroup(player)
	updateOverhead(player)
end)

-- ============================================================
-- FIX: /re (ApplyDescription) — overhead rebuild listener
-- VIPBenefit menembak RefreshOverheadEvent setelah ApplyDescription
-- selesai. Karena tidak ada LoadCharacter, CharacterAdded tidak
-- ter-fire, sehingga overhead perlu di-rebuild manual dari sini.
-- ============================================================
local RefreshOverheadEvent = ServerStorage:FindFirstChild("RefreshOverheadEvent")
if not RefreshOverheadEvent then
	-- Buat jika VIPBenefit belum sempat membuat (race condition)
	RefreshOverheadEvent = Instance.new("BindableEvent")
	RefreshOverheadEvent.Name   = "RefreshOverheadEvent"
	RefreshOverheadEvent.Parent = ServerStorage
end

RefreshOverheadEvent.Event:Connect(function(player)
	if not player or not player.Parent then return end

	local character = player.Character
	if not character then return end

	-- Tunggu sebentar agar ApplyDescription benar-benar selesai
	-- dan semua aksesori sudah terpasang kembali di karakter
	task.wait(0.2)

	-- Overhead lama masih attached ke Head yang sama,
	-- cukup rebuild (destroy lama → clone baru) agar
	-- label & icon kembali muncul di atas kepala.
	createOverhead(player, character)
end)

-- ============================================================
-- INIT
-- ============================================================
for _, player in ipairs(Players:GetPlayers()) do
	task.spawn(onPlayerAdded, player)
end

Players.PlayerAdded:Connect(onPlayerAdded)
Players.PlayerRemoving:Connect(onPlayerRemoving)

print("✅ [OverheadHandler] Loaded successfully!")
