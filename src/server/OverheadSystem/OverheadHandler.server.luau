local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage     = game:GetService("ServerStorage")

local RoleSystem      = require(ServerStorage.Modules.RoleSystem)
local ThemeModule     = require(ReplicatedStorage.Modules.ThemeModule)
local DataStoreModule = require(script.Parent.Parent:WaitForChild("GiveSystem"):WaitForChild("Title"):WaitForChild("DataStoreModule"))
local TitleRenderer   = require(script.Parent.Parent:WaitForChild("GiveSystem"):WaitForChild("Title"):WaitForChild("TitleRenderer"))

local OverheadTemplate = ReplicatedStorage:WaitForChild("UI"):WaitForChild("Overhead")

local Config = {
	GROUP_ID = 550072302,

	RoleColors = {
		Owner      = Color3.fromRGB(255, 170, 90),
		Developer  = Color3.fromRGB(120, 200, 140),
		Admin      = Color3.fromRGB(200, 80, 80),
		Streamer   = Color3.fromRGB(170, 140, 255),
		Creator    = Color3.fromRGB(120, 220, 220),
		VIP        = Color3.fromRGB(255, 210, 120),
		Guest      = Color3.fromRGB(180, 185, 200),
		PlayerName = Color3.fromRGB(255, 255, 255),
	},

	Fonts = {
		Owner      = Enum.Font.Oswald,
		Developer  = Enum.Font.TitilliumWeb,
		Admin      = Enum.Font.GothamBlack,
		Streamer   = Enum.Font.LuckiestGuy,
		Creator    = Enum.Font.PermanentMarker,
		VIP        = Enum.Font.Fondamento,
		PlayerName = Enum.Font.GothamBold,
		Guest      = Enum.Font.Gotham,
	},

	DisplayText = {
		Owner     = "OWNER",
		Developer = "DEVELOPER",
		Admin     = "ADMIN",
		Streamer  = "STREAMER",
		Creator   = "CREATOR",
		VIP       = "VIP",
		Guest     = "- MEMBER -",
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

	LabelSize          = UDim2.new(1, 0, 0.030, 0),
	GuestLabelSize     = UDim2.new(1, 0, 0.024, 0),
	ListLayoutPadding  = UDim.new(0.007, 0),
	IconImageSize      = UDim2.new(0.2, 0, 0.55, 0),
	IconTextSize       = UDim2.new(0.2, 0, 0.55, 0),
	IconsLayoutPadding = UDim.new(0.02, 0),
}

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

local function isStaffRole(role)
	return role == "Owner" or role == "Developer" or role == "Admin"
end

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

local groupRoleCache = {}
local function getPlayerGroupRole(player)
	local userId = player.UserId
	if groupRoleCache[userId] ~= nil then
		return groupRoleCache[userId]
	end
	local success, roleName = pcall(function()
		return player:GetRoleInGroup(Config.GROUP_ID)
	end)
	if success and roleName and roleName ~= "" and roleName ~= "Guest" then
		groupRoleCache[userId] = roleName
		return roleName
	end
	groupRoleCache[userId] = "Guest"
	return "Guest"
end

local function getPlayerThemeColor(player)
	local themeAttr = player:GetAttribute("CurrentTheme")
	if typeof(themeAttr) == "Color3" then
		return themeAttr
	elseif type(themeAttr) == "string" and themeAttr ~= "" and themeAttr ~= "White" and themeAttr ~= "Default" then
		if ThemeModule and ThemeModule.Presets and ThemeModule.Presets[themeAttr] then
			return ThemeModule.Presets[themeAttr].Primary1
		end
		if ThemeModule and ThemeModule.GetThemeColor then
			local col = ThemeModule.GetThemeColor(themeAttr)
			if col and col ~= Color3.fromRGB(255, 255, 255) then
				return col
			end
		end
		local ok, hexColor = pcall(function() return Color3.fromHex(themeAttr) end)
		if ok and hexColor then return hexColor end
	end
	return Config.RoleColors.PlayerName or Color3.fromRGB(255, 255, 255)
end

local function applyStroke(label, strokeType)
	if not label then return end
	label.TextStrokeColor3       = Config.StrokeColors[strokeType] or Config.StrokeColors.PlayerName
	label.TextStrokeTransparency = Config.StrokeTransparency
end

local function hideStroke(label)
	if not label then return end
	label.TextStrokeTransparency = 1
end

local function applySizes(canvas)
	for _, name in ipairs({"StaffLabel","StreamerLabel","CreatorLabel","VIPLabel","PlayerName"}) do
		local el = canvas:FindFirstChild(name)
		if el then el.Size = Config.LabelSize end
	end
	local guest = canvas:FindFirstChild("GuestLabel")
	if guest then
		guest.Size = Config.GuestLabelSize or Config.LabelSize
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

local function updateIcons(player, iconsFrame)
	if not iconsFrame then return end
	iconsFrame.Visible = false
	for _, child in ipairs(iconsFrame:GetChildren()) do
		if child:IsA("GuiObject") then
			child.Visible = false
		end
	end
end

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

	if staffLabel      then staffLabel.Visible      = false; hideStroke(staffLabel)      end
	if streamerLabel   then streamerLabel.Visible   = false; hideStroke(streamerLabel)   end
	if creatorLabel    then creatorLabel.Visible    = false; hideStroke(creatorLabel)    end
	if vipLabel        then vipLabel.Visible        = false; hideStroke(vipLabel)        end
	if playerNameLabel then playerNameLabel.Visible = false; hideStroke(playerNameLabel) end
	if guestLabel      then guestLabel.Visible      = false; hideStroke(guestLabel)      end
	if iconsFrame      then iconsFrame.Visible      = false                              end

	if staffLabel and isStaffRole(role) then
		staffLabel.Text        = Config.DisplayText[role] or role
		staffLabel.TextColor3  = Config.RoleColors[role] or Config.RoleColors.Guest
		staffLabel.Font        = Config.Fonts[role] or Enum.Font.GothamBold
		staffLabel.LayoutOrder = Config.LayoutOrder.StaffLabel
		staffLabel.Visible     = true
		applyStroke(staffLabel, role)
	end

	if streamerLabel and (role == "Streamer" or hasStreamer) then
		streamerLabel.Text        = Config.DisplayText.Streamer
		streamerLabel.TextColor3  = Config.RoleColors.Streamer
		streamerLabel.Font        = Config.Fonts.Streamer
		streamerLabel.LayoutOrder = Config.LayoutOrder.StreamerLabel
		streamerLabel.Visible     = true
		applyStroke(streamerLabel, "Streamer")
	end

	if creatorLabel and (role == "Creator" or hasCreator) then
		creatorLabel.Text        = Config.DisplayText.Creator
		creatorLabel.TextColor3  = Config.RoleColors.Creator
		creatorLabel.Font        = Config.Fonts.Creator
		creatorLabel.LayoutOrder = Config.LayoutOrder.CreatorLabel
		creatorLabel.Visible     = true
		applyStroke(creatorLabel, "Creator")
	end

	if vipLabel and (role == "VIP" or hasVIP) then
		vipLabel.Text        = Config.DisplayText.VIP
		vipLabel.TextColor3  = Config.RoleColors.VIP
		vipLabel.Font        = Config.Fonts.VIP
		vipLabel.LayoutOrder = Config.LayoutOrder.VIPLabel
		vipLabel.Visible     = true
		applyStroke(vipLabel, "VIP")
	end

	local isPremium = (player.MembershipType == Enum.MembershipType.Premium)
	local isVerified = false
	pcall(function()
		isVerified = player.HasVerifiedBadge
	end)

	local premiumPrefix = isPremium and (utf8.char(57345) .. " ") or ""
	local verifiedSuffix = isVerified and utf8.char(57344) or ""

	local nameColor = getPlayerThemeColor(player)
	playerNameLabel.Text        = premiumPrefix .. player.DisplayName .. verifiedSuffix
	playerNameLabel.TextColor3  = nameColor
	playerNameLabel.Font        = Config.Fonts.PlayerName
	playerNameLabel.LayoutOrder = Config.LayoutOrder.PlayerName
	playerNameLabel.Visible     = true

	local vipGrad = playerNameLabel:FindFirstChild("VIPGradient")
	if vipGrad then
		vipGrad.Enabled = false
	end

	applyStroke(playerNameLabel, "PlayerName")

	if guestLabel then
		local inGroup = isPlayerInGroup(player)
		if inGroup then
			local groupRole = getPlayerGroupRole(player)
			local rankText = "- MEMBER -"
			if groupRole and groupRole ~= "Guest" and groupRole ~= "" then
				if groupRole:lower() == "member" or groupRole:lower() == "members" then
					rankText = "- MEMBER -"
				else
					rankText = "- " .. string.upper(groupRole) .. " -"
				end
			end

			guestLabel.Text        = rankText
			guestLabel.TextColor3  = Config.RoleColors.Guest
			guestLabel.Font        = Config.Fonts.Guest
			guestLabel.LayoutOrder = Config.LayoutOrder.GuestLabel
			guestLabel.Visible     = true
			guestLabel:SetAttribute("IsRank", true)

			local guestGrad = guestLabel:FindFirstChild("VIPGradient")
			if guestGrad then
				guestGrad.Enabled = false
			end

			applyStroke(guestLabel, "Guest")
		else
			guestLabel.Visible     = false
			guestLabel:SetAttribute("IsRank", false)
		end
	end

	if iconsFrame then
		iconsFrame.LayoutOrder = Config.LayoutOrder.Icons
		updateIcons(player, iconsFrame)
	end
end

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
		warn("[OverheadHandler] Kepala tidak ditemukan untuk:", player.Name)
		return
	end

	local overhead = OverheadTemplate:Clone()
	overhead.Adornee = head
	overhead.StudsOffset = Vector3.new(0, 9.8, 0)
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

local function onCharacterAdded(player, character)
	task.wait(0.1)
	disableDefaultNametag(player, character)
	createOverhead(player, character)
end

local function onPlayerAdded(player)
	RoleSystem:InitializePlayer(player)

	if not player:GetAttribute("CurrentTheme") then
		player:SetAttribute("CurrentTheme", "White")
	end

	player:GetAttributeChangedSignal("CurrentTheme"):Connect(function()
		updateOverhead(player)
	end)

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
	groupRoleCache[player.UserId] = nil
	removeOverhead(player)
end

task.spawn(function()
	local remotesFolder = ReplicatedStorage:WaitForChild("Remotes", 10)
	if remotesFolder then
		local setCurrentThemeRemote = remotesFolder:WaitForChild("SetCurrentTheme", 10)
		if setCurrentThemeRemote then
			setCurrentThemeRemote.OnServerEvent:Connect(function(player, themeName)
				if typeof(themeName) == "string" and #themeName <= 50 then
					player:SetAttribute("CurrentTheme", themeName)
					updateOverhead(player)
				end
			end)
		end
	end
end)

RoleSystem.RoleChanged:Connect(function(player)    updateOverhead(player) end)
RoleSystem.VIPChanged:Connect(function(player)     updateOverhead(player) end)
RoleSystem.StreamerChanged:Connect(function(player) updateOverhead(player) end)
RoleSystem.CreatorChanged:Connect(function(player)  updateOverhead(player) end)

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

local RefreshOverheadEvent = ServerStorage:FindFirstChild("RefreshOverheadEvent")
if not RefreshOverheadEvent then

	RefreshOverheadEvent = Instance.new("BindableEvent")
	RefreshOverheadEvent.Name   = "RefreshOverheadEvent"
	RefreshOverheadEvent.Parent = ServerStorage
end

RefreshOverheadEvent.Event:Connect(function(player)
	if not player or not player.Parent then return end

	local character = player.Character
	if not character then return end

	task.wait(0.2)

	createOverhead(player, character)
end)

for _, player in ipairs(Players:GetPlayers()) do
	task.spawn(onPlayerAdded, player)
end

Players.PlayerAdded:Connect(onPlayerAdded)
Players.PlayerRemoving:Connect(onPlayerRemoving)

print("✅ [OverheadHandler] Berhasil dimuat!")

