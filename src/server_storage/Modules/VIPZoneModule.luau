local VIPZoneModule = {}

local Players = game:GetService("Players")
local PhysicsService = game:GetService("PhysicsService")
local ServerStorage = game:GetService("ServerStorage")

local RoleSystem = require(ServerStorage.Modules.RoleSystem)

local CONFIG = {
	ZONE_PART_NAMES = {"VIPZone1","VIPZone2","VIPZone3","VIPZone4","VIPZone5","VIPZone6","VIPZone7","VIPZone8"},
	ZONE_PREFIX = "VIPZone",
	ZONE_COLLISION_GROUP = "VIPZone",
	VIP_COLLISION_GROUP = "VIPPlayers",
	NONVIP_COLLISION_GROUP = "NonVIPPlayers",
	MIN_ROLE_LEVEL = 2,
	DEBUG_ENABLED = false
}

local activeZones = {}

local function debugPrint(...)
	if CONFIG.DEBUG_ENABLED then
		print("[VIPZone]", ...)
	end
end

local function setupCollisionGroups()
	local groups = {
		CONFIG.ZONE_COLLISION_GROUP,
		CONFIG.VIP_COLLISION_GROUP,
		CONFIG.NONVIP_COLLISION_GROUP
	}

	for _, groupName in ipairs(groups) do
		pcall(function()
			PhysicsService:RegisterCollisionGroup(groupName)
		end)
	end

	PhysicsService:CollisionGroupSetCollidable(CONFIG.VIP_COLLISION_GROUP, CONFIG.VIP_COLLISION_GROUP, false)

	PhysicsService:CollisionGroupSetCollidable(CONFIG.NONVIP_COLLISION_GROUP, CONFIG.NONVIP_COLLISION_GROUP, false)

	PhysicsService:CollisionGroupSetCollidable(CONFIG.VIP_COLLISION_GROUP, CONFIG.NONVIP_COLLISION_GROUP, false)

	PhysicsService:CollisionGroupSetCollidable(CONFIG.VIP_COLLISION_GROUP, CONFIG.ZONE_COLLISION_GROUP, false)

	PhysicsService:CollisionGroupSetCollidable(CONFIG.NONVIP_COLLISION_GROUP, CONFIG.ZONE_COLLISION_GROUP, true)

	debugPrint("✅ Collision groups configured")
end

local function isPlayerVIP(player)
	local role = RoleSystem:GetPlayerRole(player)
	local roleLevel = RoleSystem.Config.RoleHierarchy[role] or 0
	return roleLevel >= CONFIG.MIN_ROLE_LEVEL
end

local function applyCollisionToCharacter(character, groupName)
	for _, part in ipairs(character:GetDescendants()) do
		if part:IsA("BasePart") then
			pcall(function()
				part.CollisionGroup = groupName
			end)
		end
	end

	character.DescendantAdded:Connect(function(descendant)
		if descendant:IsA("BasePart") then
			task.wait()
			pcall(function()
				descendant.CollisionGroup = groupName
			end)
		end
	end)
end

local function updatePlayerAccess(player)
	if not player.Character then return end

	local isVIP = isPlayerVIP(player)
	local groupName = isVIP and CONFIG.VIP_COLLISION_GROUP or CONFIG.NONVIP_COLLISION_GROUP

	applyCollisionToCharacter(player.Character, groupName)

	debugPrint(string.format("%s (%s) → CollisionGroup: %s",
		player.Name,
		isVIP and "VIP" or "NON-VIP",
		groupName
		))
end

function VIPZoneModule.registerZone(zonePart)
	if not zonePart or not zonePart:IsA("BasePart") then
		warn("[VIPZone] Part zona tidak valid!")
		return false
	end

	zonePart.CanCollide = true
	zonePart.CollisionGroup = CONFIG.ZONE_COLLISION_GROUP
	zonePart.Transparency = 1
	zonePart.Material = Enum.Material.ForceField
	zonePart.Color = Color3.fromRGB(255, 255, 255)
	zonePart.Anchored = true

	table.insert(activeZones, zonePart)

	debugPrint("✅ Zone registered:", zonePart.Name)

	return true
end

local function findAndRegisterZones()
	local zonesFound = 0

	local function searchInContainer(container)
		for _, obj in ipairs(container:GetDescendants()) do
			if obj:IsA("BasePart") and string.match(obj.Name, "^" .. CONFIG.ZONE_PREFIX) then
				if VIPZoneModule.registerZone(obj) then
					zonesFound = zonesFound + 1
				end
			end
		end
	end

	searchInContainer(workspace)

	if zonesFound > 0 then

	else
		warn(string.format("[VIPZone] ⚠️ No zones found with prefix '%s' in Workspace!", CONFIG.ZONE_PREFIX))
	end

	return zonesFound
end

local function findAndRegisterSpecificZones()
	local zonesFound = 0

	if type(CONFIG.ZONE_PART_NAME) == "table" then
		for _, zoneName in ipairs(CONFIG.ZONE_PART_NAME) do
			local zone = workspace:FindFirstChild(zoneName)
			if zone then
				if VIPZoneModule.registerZone(zone) then
					zonesFound = zonesFound + 1
				end
			end
		end

	elseif type(CONFIG.ZONE_PART_NAME) == "string" then
		local zone = workspace:FindFirstChild(CONFIG.ZONE_PART_NAME)
		if zone then
			if VIPZoneModule.registerZone(zone) then
				zonesFound = zonesFound + 1
			end
		end
	end

	return zonesFound
end

local function setupPlayer(player)
	RoleSystem:InitializePlayer(player)

	player.CharacterAdded:Connect(function(character)
		character:WaitForChild("HumanoidRootPart")
		task.wait(0.1)
		updatePlayerAccess(player)
	end)

	if player.Character then
		updatePlayerAccess(player)
	end
end

function VIPZoneModule.Init()
	debugPrint("🔧 Initializing VIP Zone System...")

	setupCollisionGroups()

	local specificZones = findAndRegisterSpecificZones()

	local prefixZones = findAndRegisterZones()

	local totalZones = specificZones + prefixZones

	if totalZones == 0 then
		warn("[VIPZone] ⚠️ No zones registered! Check your zone names or prefix.")
	end

	for _, player in ipairs(Players:GetPlayers()) do
		setupPlayer(player)
	end

	Players.PlayerAdded:Connect(function(player)
		setupPlayer(player)
	end)

	RoleSystem.RoleChanged:Connect(function(player, oldRole, newRole)
		debugPrint(string.format("Role changed: %s (%s → %s)", player.Name, oldRole, newRole))
		updatePlayerAccess(player)
	end)

end

function VIPZoneModule.setZonePrefix(newPrefix)
	CONFIG.ZONE_PREFIX = newPrefix
	debugPrint("Zone prefix changed to:", newPrefix)
end

function VIPZoneModule.getActiveZonesCount()
	return #activeZones
end

return VIPZoneModule
