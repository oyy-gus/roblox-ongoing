local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local favoritedAnimationsStore = DataStoreService:GetDataStore("FavoritedAnimations")
local Events = ReplicatedStorage:WaitForChild("SyncRemotes")
local updateFavoritedAnimationsEvent = Events:WaitForChild("updateFavoritedAnimationsEvent")

Players.PlayerAdded:Connect(function(player)
	local success, savedData = pcall(function()
		return favoritedAnimationsStore:GetAsync("Player_" .. player.UserId)
	end)

	if success and type(savedData) == "string" then
		local decodeSuccess, decodedData = pcall(function()
			return HttpService:JSONDecode(savedData)
		end)
		if decodeSuccess and type(decodedData) == "table" then
			player:SetAttribute("SavedFavoritedAnimations", savedData)
		end
	end
end)

Players.PlayerRemoving:Connect(function(player)
	local savedData = player:GetAttribute("SavedFavoritedAnimations")
	if savedData then
		pcall(function()
			favoritedAnimationsStore:SetAsync("Player_" .. player.UserId, savedData)
		end)
	end
end)

updateFavoritedAnimationsEvent.OnServerEvent:Connect(function(player, jsonData)
	local success, decodedData = pcall(function()
		return HttpService:JSONDecode(jsonData)
	end)

	if success and type(decodedData) == "table" then
		player:SetAttribute("SavedFavoritedAnimations", jsonData)
	end
end)
