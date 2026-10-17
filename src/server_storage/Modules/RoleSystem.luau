local RoleSystem = {}

local DataStoreService = game:GetService("DataStoreService")
local MarketplaceService = game:GetService("MarketplaceService")

RoleSystem.Config = {
	GamePasses = {
		VIP = {1576979212}
	},
	ActiveGamepasses = {
		VIP = 1576979212
	},
	OwnerIds = {9168895647},
	DeveloperIds = {9070688506},
	AdminIds = {},

	RoleHierarchy = {
		Owner     = 7,
		Developer = 6,
		Admin     = 5,
		Streamer  = 4,
		Creator   = 3,
		VIP       = 2,
		Guest     = 1
	},

	GiveableRoles = {
		"VIP",
		"Streamer",
		"Creator"
	},

	DATASTORE_NAME = "PlayerRoles_v1",
	DATASTORE_RETRY_ATTEMPTS = 3,
	DATASTORE_RETRY_DELAY = 1,
	GAMEPASS_CHECK_TIMEOUT = 15,
	GAMEPASS_CHECK_RETRIES = 2
}

local roleDataStore = DataStoreService:GetDataStore(RoleSystem.Config.DATASTORE_NAME)
local playerOwnershipCache = {}

local roleChangedEvent = Instance.new("BindableEvent")
roleChangedEvent.Name = "RoleChanged"
RoleSystem.RoleChanged = roleChangedEvent.Event

local vipChangedEvent = Instance.new("BindableEvent")
vipChangedEvent.Name = "VIPChanged"
RoleSystem.VIPChanged = vipChangedEvent.Event

local streamerChangedEvent = Instance.new("BindableEvent")
streamerChangedEvent.Name = "StreamerChanged"
RoleSystem.StreamerChanged = streamerChangedEvent.Event

local creatorChangedEvent = Instance.new("BindableEvent")
creatorChangedEvent.Name = "CreatorChanged"
RoleSystem.CreatorChanged = creatorChangedEvent.Event

local function isInList(userId, list)
	for _, id in ipairs(list) do
		if id == userId then return true end
	end
	return false
end

local function datastoreGetAsync(key)
	for attempt = 1, RoleSystem.Config.DATASTORE_RETRY_ATTEMPTS do
		local success, result = pcall(function()
			return roleDataStore:GetAsync(key)
		end)
		if success then
			return result
		end
		warn(string.format("[RoleSystem] DataStore GetAsync attempt %d failed: %s", attempt, tostring(result)))
		if attempt < RoleSystem.Config.DATASTORE_RETRY_ATTEMPTS then
			task.wait(RoleSystem.Config.DATASTORE_RETRY_DELAY)
		end
	end
	return nil
end

local function datastoreSetAsync(key, value)
	for attempt = 1, RoleSystem.Config.DATASTORE_RETRY_ATTEMPTS do
		local success, err = pcall(function()
			roleDataStore:SetAsync(key, value)
		end)
		if success then
			print(string.format("[RoleSystem] DataStore saved successfully: %s", key))
			return true
		end
		warn(string.format("[RoleSystem] DataStore SetAsync attempt %d failed: %s", attempt, tostring(err)))
		if attempt < RoleSystem.Config.DATASTORE_RETRY_ATTEMPTS then
			task.wait(RoleSystem.Config.DATASTORE_RETRY_DELAY)
		end
	end
	return false
end

local function checkSingleGamepass(player, gamepassId, retryCount)
	retryCount = retryCount or 0
	if not gamepassId or gamepassId == 0 then return false end

	local result = false
	local completed = false
	local checkError = nil

	task.spawn(function()
		local success, hasPass = pcall(function()
			return MarketplaceService:UserOwnsGamePassAsync(player.UserId, gamepassId)
		end)
		if success then
			result = hasPass
		else
			checkError = hasPass
		end
		completed = true
	end)

	local startTime = tick()
	while not completed and (tick() - startTime) < RoleSystem.Config.GAMEPASS_CHECK_TIMEOUT do
		task.wait(0.1)
	end

	if not completed or checkError then
		if retryCount < RoleSystem.Config.GAMEPASS_CHECK_RETRIES then
			task.wait(1)
			return checkSingleGamepass(player, gamepassId, retryCount + 1)
		end
		return false
	end

	return result
end

local function checkAnyGamepass(player, gamepassIds)
	if type(gamepassIds) == "number" then
		return checkSingleGamepass(player, gamepassIds)
	end
	if type(gamepassIds) == "table" then
		for _, id in ipairs(gamepassIds) do
			if checkSingleGamepass(player, id) then return true end
		end
	end
	return false
end

function RoleSystem:CachePlayerOwnership(player)
	local userId = player.UserId

	print(string.format("[RoleSystem] Caching ownership for %s (%d)", player.Name, userId))

	local ownership = {
		VIP = false,
		Streamer = false,
		Creator = false,
		GivenRoles = {},
		CheckedAt = tick()
	}

	local key = "playerroles_" .. tostring(userId)
	local savedData = datastoreGetAsync(key)

	print(string.format("[RoleSystem] DataStore data for %s: %s", player.Name, tostring(savedData)))

	if savedData and type(savedData) == "table" then
		ownership.GivenRoles = savedData.roles or {}

		for _, role in ipairs(ownership.GivenRoles) do
			print(string.format("[RoleSystem] Found saved role: %s", role))
			if role == "VIP" then
				ownership.VIP = true
			elseif role == "Streamer" then
				ownership.Streamer = true
			elseif role == "Creator" then
				ownership.Creator = true
			end
		end
	end

	if not ownership.VIP then
		local hasVIPGamepass = checkAnyGamepass(player, self.Config.GamePasses.VIP)
		if hasVIPGamepass then
			ownership.VIP = true
			task.spawn(function()
				self:SaveRoleToPlayer(userId, "VIP", 0)
			end)
		end
	end

	playerOwnershipCache[userId] = ownership

	print(string.format("[RoleSystem] Final ownership for %s: VIP=%s, Streamer=%s, Creator=%s",
		player.Name, tostring(ownership.VIP), tostring(ownership.Streamer), tostring(ownership.Creator)))

	return ownership
end

function RoleSystem:GetPlayerOwnership(player)
	local userId = player.UserId
	if playerOwnershipCache[userId] then
		return playerOwnershipCache[userId]
	end
	return self:CachePlayerOwnership(player)
end

function RoleSystem:InvalidateOwnershipCache(userId)
	playerOwnershipCache[userId] = nil
end

function RoleSystem:GetPlayerRole(player)
	local userId = player.UserId

	if isInList(userId, self.Config.OwnerIds) then return "Owner" end
	if isInList(userId, self.Config.DeveloperIds) then return "Developer" end
	if isInList(userId, self.Config.AdminIds) then return "Admin" end

	local ownership = playerOwnershipCache[userId]
	if not ownership then
		warn(string.format("[RoleSystem] Ownership cache miss for user %d, defaulting to Guest", userId))
		return "Guest"
	end

	if ownership.Streamer then
		return "Streamer"
	end

	if ownership.Creator then
		return "Creator"
	end

	if ownership.VIP then
		return "VIP"
	end

	return "Guest"
end

function RoleSystem:HasVIP(player)
	local ownership = self:GetPlayerOwnership(player)
	return ownership.VIP == true
end

function RoleSystem:HasStreamer(player)
	local ownership = self:GetPlayerOwnership(player)
	return ownership.Streamer == true
end

function RoleSystem:HasCreator(player)
	local ownership = self:GetPlayerOwnership(player)
	return ownership.Creator == true
end

function RoleSystem:InitializePlayer(player)
	self:CachePlayerOwnership(player)

	local role = self:GetPlayerRole(player)

	local roleValue = player:FindFirstChild("Role")
	if not roleValue then
		roleValue = Instance.new("StringValue")
		roleValue.Name = "Role"
		roleValue.Parent = player
	end

	local oldRole = roleValue.Value
	roleValue.Value = role

	print(string.format("[RoleSystem] Initialized %s with role: %s (was: %s)", player.Name, role, oldRole))

	if oldRole ~= role and oldRole ~= "" then
		roleChangedEvent:Fire(player, oldRole, role)
	end

	return role
end

function RoleSystem:UpdatePlayerRole(player)
	self:InvalidateOwnershipCache(player.UserId)
	return self:InitializePlayer(player)
end

function RoleSystem:SaveRoleToPlayer(targetUserId, roleType, giverUserId)
	local key = "playerroles_" .. tostring(targetUserId)

	print(string.format("[RoleSystem] Saving role %s to user %d", roleType, targetUserId))

	local existingData = datastoreGetAsync(key) or { roles = {} }
	local roles = existingData.roles or {}

	local roleExists = false
	for _, role in ipairs(roles) do
		if role == roleType then
			roleExists = true
			break
		end
	end

	if not roleExists then
		table.insert(roles, roleType)
	end

	local data = {
		roles = roles,
		lastUpdated = os.time(),
		lastGivenBy = giverUserId
	}

	local success = datastoreSetAsync(key, data)
	print(string.format("[RoleSystem] DataStore save result: %s", tostring(success)))

	return success
end

function RoleSystem:GiveRoleToPlayer(targetUserId, roleType, giverUserId)
	print(string.format("[RoleSystem] ⭐ GiveRoleToPlayer: userId=%d, role=%s, giver=%s",
		targetUserId, roleType, tostring(giverUserId)))

	local isGiveable = false
	for _, r in ipairs(self.Config.GiveableRoles) do
		if r == roleType then
			isGiveable = true
			break
		end
	end

	if not isGiveable then
		return false, "Tipe role tidak valid: " .. tostring(roleType)
	end

	local saveSuccess = self:SaveRoleToPlayer(targetUserId, roleType, giverUserId)

	if not saveSuccess then
		warn("[RoleSystem] ❌ Gagal menyimpan ke DataStore")
		return false, "Kesalahan DataStore"
	end

	print(string.format("[RoleSystem] ✅ Role %s saved to DataStore for user %d", roleType, targetUserId))

	local ownership = playerOwnershipCache[targetUserId]
	if not ownership then
		ownership = {
			VIP = false,
			Streamer = false,
			Creator = false,
			GivenRoles = {},
			CheckedAt = tick()
		}
	end

	if roleType == "VIP" then
		ownership.VIP = true
		print(string.format("[RoleSystem] ✅ Set VIP=true in cache"))
	elseif roleType == "Streamer" then
		ownership.Streamer = true
		print(string.format("[RoleSystem] ✅ Set Streamer=true in cache"))
	elseif roleType == "Creator" then
		ownership.Creator = true
		print(string.format("[RoleSystem] ✅ Set Creator=true in cache"))
	end

	local roleInList = false
	for _, r in ipairs(ownership.GivenRoles) do
		if r == roleType then
			roleInList = true
			break
		end
	end
	if not roleInList then
		table.insert(ownership.GivenRoles, roleType)
	end

	ownership.CheckedAt = tick()
	playerOwnershipCache[targetUserId] = ownership

	print(string.format("[RoleSystem] ✅ Cache updated: VIP=%s, Streamer=%s, Creator=%s",
		tostring(ownership.VIP), tostring(ownership.Streamer), tostring(ownership.Creator)))

	local player = game.Players:GetPlayerByUserId(targetUserId)
	if player then

		local roleValue = player:FindFirstChild("Role")
		if not roleValue then
			roleValue = Instance.new("StringValue")
			roleValue.Name = "Role"
			roleValue.Parent = player
		end

		local oldRole = roleValue.Value
		local newRole = self:GetPlayerRole(player)
		roleValue.Value = newRole

		print(string.format("[RoleSystem] ✅ Updated %s: %s -> %s", player.Name, oldRole, newRole))

		if roleType == "VIP" then
			vipChangedEvent:Fire(player, true)
			print("[RoleSystem] 🔔 Fired VIPChanged event")
		elseif roleType == "Streamer" then
			streamerChangedEvent:Fire(player, true)
			print("[RoleSystem] 🔔 Fired StreamerChanged event")
		elseif roleType == "Creator" then
			creatorChangedEvent:Fire(player, true)
			print("[RoleSystem] 🔔 Fired CreatorChanged event")
		end

		if oldRole ~= newRole then
			roleChangedEvent:Fire(player, oldRole, newRole)
			print("[RoleSystem] 🔔 Fired RoleChanged event")
		end
	else
		print(string.format("[RoleSystem] ℹ️ Player %d is offline, role saved for next login", targetUserId))
	end

	return true, "Role given successfully"
end

function RoleSystem:RemoveRoleFromPlayer(targetUserId, roleType)
	local key = "playerroles_" .. tostring(targetUserId)

	local existingData = datastoreGetAsync(key)
	if not existingData or not existingData.roles then
		return false, "No roles found"
	end

	local newRoles = {}
	for _, role in ipairs(existingData.roles) do
		if role ~= roleType then
			table.insert(newRoles, role)
		end
	end

	local data = {
		roles = newRoles,
		lastUpdated = os.time()
	}

	local success = datastoreSetAsync(key, data)

	if success then

		local ownership = playerOwnershipCache[targetUserId]
		if ownership then
			if roleType == "VIP" then
				ownership.VIP = false
			elseif roleType == "Streamer" then
				ownership.Streamer = false
			elseif roleType == "Creator" then
				ownership.Creator = false
			end

			local newGivenRoles = {}
			for _, r in ipairs(ownership.GivenRoles or {}) do
				if r ~= roleType then
					table.insert(newGivenRoles, r)
				end
			end
			ownership.GivenRoles = newGivenRoles
			playerOwnershipCache[targetUserId] = ownership
		end

		local player = game.Players:GetPlayerByUserId(targetUserId)
		if player then
			if roleType == "VIP" then
				vipChangedEvent:Fire(player, false)
			elseif roleType == "Streamer" then
				streamerChangedEvent:Fire(player, false)
			elseif roleType == "Creator" then
				creatorChangedEvent:Fire(player, false)
			end

			local roleValue = player:FindFirstChild("Role")
			if roleValue then
				local oldRole = roleValue.Value
				local newRole = self:GetPlayerRole(player)
				roleValue.Value = newRole

				if oldRole ~= newRole then
					roleChangedEvent:Fire(player, oldRole, newRole)
				end
			end
		end
		return true, "Role removed successfully"
	end

	return false, "DataStore error"
end

function RoleSystem:GivePassToPlayer(targetUserId, passType, giverUserId)
	return self:GiveRoleToPlayer(targetUserId, passType, giverUserId)
end

function RoleSystem:RemovePassFromPlayer(targetUserId)
	return self:RemoveRoleFromPlayer(targetUserId, "VIP")
end

function RoleSystem:GetPlayerGivenRoles(player)
	local ownership = self:GetPlayerOwnership(player)
	return ownership.GivenRoles or {}
end

function RoleSystem:CompareRoles(role1, role2)
	local h1 = self.Config.RoleHierarchy[role1] or 0
	local h2 = self.Config.RoleHierarchy[role2] or 0
	return h1 - h2
end

function RoleSystem:HasHigherRole(player1, player2)
	return self:CompareRoles(self:GetPlayerRole(player1), self:GetPlayerRole(player2)) > 0
end

function RoleSystem:GetPlayerPriority(player)
	return self.Config.RoleHierarchy[self:GetPlayerRole(player)] or 1
end

function RoleSystem:IsGiveableRole(roleType)
	for _, r in ipairs(self.Config.GiveableRoles) do
		if r == roleType then
			return true
		end
	end
	return false
end

function RoleSystem:GetOwnershipStats()
	local stats = { totalCached = 0, vipCount = 0, streamerCount = 0, creatorCount = 0 }
	for _, ownership in pairs(playerOwnershipCache) do
		stats.totalCached += 1
		if ownership.VIP then stats.vipCount += 1 end
		if ownership.Streamer then stats.streamerCount += 1 end
		if ownership.Creator then stats.creatorCount += 1 end
	end
	return stats
end

function RoleSystem:DebugPrintCache(userId)
	local ownership = playerOwnershipCache[userId]
	if ownership then
		print(string.format("[RoleSystem DEBUG] Cache for %d:", userId))
		print(string.format("  VIP: %s", tostring(ownership.VIP)))
		print(string.format("  Streamer: %s", tostring(ownership.Streamer)))
		print(string.format("  Creator: %s", tostring(ownership.Creator)))
		print(string.format("  GivenRoles: %s", table.concat(ownership.GivenRoles or {}, ", ")))
	else
		print(string.format("[RoleSystem DEBUG] No cache for %d", userId))
	end
end

function RoleSystem:GetRolePermissions(role) return {} end
function RoleSystem:GetPlayerPermissions(player) return {} end
function RoleSystem:HasZoneAccess(player, zoneName) return false end
function RoleSystem:HasItemAccess(player, itemName) return false end
function RoleSystem:CanUseCommand(player, commandName) return false end
function RoleSystem:GetFeature(player, featureName) return nil end
function RoleSystem:GetStatMultiplier(player, statName) return 1 end
function RoleSystem:GetAllSpecialItems(player) return {} end
function RoleSystem:ApplyRoleToPlayer(player) return self:GetPlayerRole(player) end
function RoleSystem:GiveSpecialItems(player) end

return RoleSystem
