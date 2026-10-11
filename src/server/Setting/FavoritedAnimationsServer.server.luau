local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")

local favoritedAnimationsStore = DataStoreService:GetDataStore("FavoritedAnimations")
local replicatedStorage = game:GetService("ReplicatedStorage")
local Events = replicatedStorage:WaitForChild("SyncRemotes")
local updateFavoritedAnimationsEvent = Events:WaitForChild("updateFavoritedAnimationsEvent")

Players.PlayerAdded:Connect(function(player)
	local success, savedData = pcall(function()
		return favoritedAnimationsStore:GetAsync("Player_" .. player.UserId)
	end)

	if success and type(savedData) == "string" then
		local decodedData = HttpService:JSONDecode(savedData)
		if type(decodedData) == "table" then
			player:SetAttribute("SavedFavoritedAnimations", savedData) 
		else
		end
	else
	end
end)

Players.PlayerRemoving:Connect(function(player)
	local savedData = player:GetAttribute("SavedFavoritedAnimations")
	if savedData then
		local success, errorMessage = pcall(function()
			favoritedAnimationsStore:SetAsync("Player_" .. player.UserId, savedData)
		end)

		if not success then
		else
		end
	end
end)

updateFavoritedAnimationsEvent.OnServerEvent:Connect(function(player, jsonData)
	local success, decodedData = pcall(function()
		return HttpService:JSONDecode(jsonData)
	end)

	if success and type(decodedData) == "table" then
		player:SetAttribute("SavedFavoritedAnimations", jsonData)
	else
	end
end)
