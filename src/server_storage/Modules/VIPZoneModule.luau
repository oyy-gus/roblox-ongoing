-- ====================================
-- VIP ZONE ACCESS MODULE (PREFIX SYSTEM)
-- Place in: ServerStorage > Modules(Folder) > VIPZoneModule(ModuleScript)
-- ====================================

local VIPZoneModule = {}

local Players = game:GetService("Players")
local PhysicsService = game:GetService("PhysicsService")
local ServerStorage = game:GetService("ServerStorage")

-- Import RoleSystem Module
local RoleSystem = require(ServerStorage.Modules.RoleSystem)

-- Configuration
local CONFIG = {
	ZONE_PART_NAME = "VIPZone1","VIPZone2","VIPZone3","VIPZone4","VIPZone5","VIPZone6","VIPZone7","VIPZone8",
	ZONE_PREFIX = "VIPZone",                  -- Prefix untuk mencari zone parts (VIPZone1, VIPZone2, dll)
	ZONE_COLLISION_GROUP = "VIPZone",         -- Group untuk zone itu sendiri
	VIP_COLLISION_GROUP = "VIPPlayers",       -- Group untuk VIP
	NONVIP_COLLISION_GROUP = "NonVIPPlayers", -- Group untuk NON-VIP
	MIN_ROLE_LEVEL = 2,
	DEBUG_ENABLED = false  -- Set true untuk melihat debug messages
}

local activeZones = {}

-- ====================================
-- DEBUG PRINT FUNCTION
-- ====================================
local function debugPrint(...)
	if CONFIG.DEBUG_ENABLED then
		print("[VIPZone]", ...)
	end
end

-- ====================================
-- COLLISION GROUP SETUP
-- ====================================
local function setupCollisionGroups()
	local groups = {
		CONFIG.ZONE_COLLISION_GROUP,
		CONFIG.VIP_COLLISION_GROUP,
		CONFIG.NONVIP_COLLISION_GROUP
	}

	-- Register semua collision groups
	for _, groupName in ipairs(groups) do
		pcall(function()
			PhysicsService:RegisterCollisionGroup(groupName)
		end)
	end

	-- ===== PLAYER DENGAN PLAYER =====
	-- VIP dengan VIP = tembus
	PhysicsService:CollisionGroupSetCollidable(CONFIG.VIP_COLLISION_GROUP, CONFIG.VIP_COLLISION_GROUP, false)

	-- NON-VIP dengan NON-VIP = tembus
	PhysicsService:CollisionGroupSetCollidable(CONFIG.NONVIP_COLLISION_GROUP, CONFIG.NONVIP_COLLISION_GROUP, false)

	-- VIP dengan NON-VIP = tembus
	PhysicsService:CollisionGroupSetCollidable(CONFIG.VIP_COLLISION_GROUP, CONFIG.NONVIP_COLLISION_GROUP, false)

	-- ===== PLAYER DENGAN ZONE =====
	-- VIP dengan ZONE = TEMBUS (false)
	PhysicsService:CollisionGroupSetCollidable(CONFIG.VIP_COLLISION_GROUP, CONFIG.ZONE_COLLISION_GROUP, false)

	-- NON-VIP dengan ZONE = TERTAHAN (true)
	PhysicsService:CollisionGroupSetCollidable(CONFIG.NONVIP_COLLISION_GROUP, CONFIG.ZONE_COLLISION_GROUP, true)

	debugPrint("✅ Collision groups configured")
end

-- ====================================
-- CHECK PLAYER VIP ACCESS
-- ====================================
local function isPlayerVIP(player)
	local role = RoleSystem:GetPlayerRole(player)
	local roleLevel = RoleSystem.Config.RoleHierarchy[role] or 0
	return roleLevel >= CONFIG.MIN_ROLE_LEVEL
end

-- ====================================
-- APPLY COLLISION GROUP
-- ====================================
local function applyCollisionToCharacter(character, groupName)
	for _, part in ipairs(character:GetDescendants()) do
		if part:IsA("BasePart") then
			pcall(function()
				part.CollisionGroup = groupName
			end)
		end
	end

	-- Handle new parts yang ditambahkan ke character
	character.DescendantAdded:Connect(function(descendant)
		if descendant:IsA("BasePart") then
			task.wait()
			pcall(function()
				descendant.CollisionGroup = groupName
			end)
		end
	end)
end

-- ====================================
-- UPDATE PLAYER ACCESS
-- ====================================
local function updatePlayerAccess(player)
	if not player.Character then return end

	local isVIP = isPlayerVIP(player)
	local groupName = isVIP and CONFIG.VIP_COLLISION_GROUP or CONFIG.NONVIP_COLLISION_GROUP

	applyCollisionToCharacter(player.Character, groupName)

	-- Debug info
	debugPrint(string.format("%s (%s) → CollisionGroup: %s", 
		player.Name, 
		isVIP and "VIP" or "NON-VIP", 
		groupName
		))
end

-- ====================================
-- REGISTER VIP ZONE
-- ====================================
function VIPZoneModule.registerZone(zonePart)
	if not zonePart or not zonePart:IsA("BasePart") then
		warn("[VIPZone] Invalid zone part!")
		return false
	end

	-- Setup zone part
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

-- ====================================
-- FIND AND REGISTER ALL ZONES BY PREFIX
-- ====================================
local function findAndRegisterZones()
	local zonesFound = 0

	-- Recursive function untuk mencari di semua descendants
	local function searchInContainer(container)
		for _, obj in ipairs(container:GetDescendants()) do
			if obj:IsA("BasePart") and string.match(obj.Name, "^" .. CONFIG.ZONE_PREFIX) then
				if VIPZoneModule.registerZone(obj) then
					zonesFound = zonesFound + 1
				end
			end
		end
	end

	-- Search di Workspace
	searchInContainer(workspace)

	if zonesFound > 0 then

	else
		warn(string.format("[VIPZone] ⚠️ No zones found with prefix '%s' in Workspace!", CONFIG.ZONE_PREFIX))
	end

	return zonesFound
end

-- ====================================
-- FIND AND REGISTER SPECIFIC ZONES (LEGACY SUPPORT)
-- ====================================
local function findAndRegisterSpecificZones()
	local zonesFound = 0

	-- Jika ZONE_PART_NAME adalah table (multiple zones)
	if type(CONFIG.ZONE_PART_NAME) == "table" then
		for _, zoneName in ipairs(CONFIG.ZONE_PART_NAME) do
			local zone = workspace:FindFirstChild(zoneName)
			if zone then
				if VIPZoneModule.registerZone(zone) then
					zonesFound = zonesFound + 1
				end
			end
		end
		-- Jika ZONE_PART_NAME adalah string (single zone)
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

-- ====================================
-- SETUP PLAYER
-- ====================================
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

-- ====================================
-- INITIALIZE SYSTEM
-- ====================================
function VIPZoneModule.Init()
	debugPrint("🔧 Initializing VIP Zone System...")

	setupCollisionGroups()

	-- Register zones menggunakan nama spesifik (dari ZONE_PART_NAME)
	local specificZones = findAndRegisterSpecificZones()

	-- Register zones menggunakan prefix system
	local prefixZones = findAndRegisterZones()

	local totalZones = specificZones + prefixZones

	if totalZones == 0 then
		warn("[VIPZone] ⚠️ No zones registered! Check your zone names or prefix.")
	end

	-- Setup existing players
	for _, player in ipairs(Players:GetPlayers()) do
		setupPlayer(player)
	end

	-- Setup new players
	Players.PlayerAdded:Connect(function(player)
		setupPlayer(player)
	end)

	-- Handle role changes (misal: player beli gamepass)
	RoleSystem.RoleChanged:Connect(function(player, oldRole, newRole)
		debugPrint(string.format("Role changed: %s (%s → %s)", player.Name, oldRole, newRole))
		updatePlayerAccess(player)
	end)

end

-- ====================================
-- UTILITY: Change Zone Prefix (Optional)
-- ====================================
function VIPZoneModule.setZonePrefix(newPrefix)
	CONFIG.ZONE_PREFIX = newPrefix
	debugPrint("Zone prefix changed to:", newPrefix)
end

-- ====================================
-- UTILITY: Get Active Zones Count
-- ====================================
function VIPZoneModule.getActiveZonesCount()
	return #activeZones
end

return VIPZoneModule
