--[[
	FavoriteService.lua
	Tujuan: Mengelola penyimpanan favorit lagu per pemain menggunakan DataStore.
	Menyediakan RemoteFunction RF_GetFavorites dan RemoteEvent RE_ToggleFavorite.
]]

local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Remotes = require(ReplicatedStorage.Shared.Remotes)

local FavoriteService = {}
local favoriteStore = nil

-- Safe DataStore initialization
local dsOk, err = pcall(function()
	favoriteStore = DataStoreService:GetDataStore("PlayerFavorites_v1")
end)
if not dsOk then
	warn("[FavoriteService] DataStore tidak dapat diinisialisasi (Studio API Access mungkin mati):", err)
end

local userFavorites = {} -- UserId -> { [sound_id] = true }

local function loadFavorites(player)
	local userId = player.UserId
	userFavorites[userId] = {}

	if not favoriteStore then return end

	local ok, data = pcall(function()
		return favoriteStore:GetAsync("fav_" .. userId)
	end)

	if ok and type(data) == "table" then
		for _, soundId in ipairs(data) do
			userFavorites[userId][tostring(soundId)] = true
		end
		print(string.format("[FavoriteService] Memuat %d lagu favorit untuk %s.", #data, player.Name))
	end
end

local function saveFavorites(player)
	local userId = player.UserId
	local favMap = userFavorites[userId]
	if not favMap or not favoriteStore then return end

	local listToSave = {}
	for soundId, isFav in pairs(favMap) do
		if isFav then
			table.insert(listToSave, tostring(soundId))
		end
	end

	local ok, saveErr = pcall(function()
		favoriteStore:SetAsync("fav_" .. userId, listToSave)
	end)

	if ok then
		print(string.format("[FavoriteService] Berhasil menyimpan %d lagu favorit untuk %s.", #listToSave, player.Name))
	else
		warn(string.format("[FavoriteService] Gagal menyimpan favorit %s: %s", player.Name, tostring(saveErr)))
	end
end

function FavoriteService.Init()
	local RF_GetFavorites = Remotes.GetFunction(Remotes.NAMES.GetFavorites)
	local RE_ToggleFavorite = Remotes.GetEvent(Remotes.NAMES.ToggleFavorite)

	-- Server Callbacks
	RF_GetFavorites.OnServerInvoke = function(player)
		local favMap = userFavorites[player.UserId] or {}
		local list = {}
		for soundId, isFav in pairs(favMap) do
			if isFav then table.insert(list, soundId) end
		end
		return list
	end

	RE_ToggleFavorite.OnServerEvent:Connect(function(player, soundId, isFav)
		if not soundId then return end
		local userId = player.UserId
		if not userFavorites[userId] then
			userFavorites[userId] = {}
		end
		userFavorites[userId][tostring(soundId)] = (isFav == true)
		saveFavorites(player)
	end)

	-- Player Events
	Players.PlayerAdded:Connect(loadFavorites)
	Players.PlayerRemoving:Connect(function(player)
		saveFavorites(player)
		userFavorites[player.UserId] = nil
	end)

	for _, player in ipairs(Players:GetPlayers()) do
		task.spawn(loadFavorites, player)
	end

	game:BindToClose(function()
		for _, player in ipairs(Players:GetPlayers()) do
			saveFavorites(player)
		end
	end)
end

return FavoriteService
