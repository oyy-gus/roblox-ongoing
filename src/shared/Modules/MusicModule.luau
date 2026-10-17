local MusicModule = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService        = game:GetService("RunService")

local cachedList     = {}
local lastFetchTime  = 0
local CACHE_DURATION = 300

function MusicModule:SetPlaylist(list)
	cachedList    = list or {}
	lastFetchTime = workspace:GetServerTimeNow()
end

local function fetchFromServer()
	local remoteFolder = ReplicatedStorage:FindFirstChild("MusicRemotes")
		or ReplicatedStorage:WaitForChild("MusicRemotes", 10)
	if not remoteFolder then
		warn("[MusicModule] MusicRemotes tidak ditemukan!")
		return {}
	end
	local getPlaylist = remoteFolder:WaitForChild("GetPlaylist", 10)
	if not getPlaylist then
		warn("[MusicModule] GetPlaylist remote tidak ditemukan!")
		return {}
	end
	local ok, result = pcall(function() return getPlaylist:InvokeServer() end)
	if ok and result and #result > 0 then
		cachedList    = result
		lastFetchTime = workspace:GetServerTimeNow()
		return cachedList
	else
		warn("[MusicModule] Gagal fetch playlist dari server:", result)
		return cachedList or {}
	end
end

function MusicModule:Preload()
	if RunService:IsClient() then
		if #cachedList == 0 or (workspace:GetServerTimeNow() - lastFetchTime) >= CACHE_DURATION then
			fetchFromServer()
		end
	end
	return #cachedList
end

function MusicModule:GetAllMusic()
	if RunService:IsClient() then
		if #cachedList == 0 or (workspace:GetServerTimeNow() - lastFetchTime) >= CACHE_DURATION then
			fetchFromServer()
		end
	end
	local sorted = {}
	for _, song in ipairs(cachedList) do table.insert(sorted, song) end
	table.sort(sorted, function(a, b) return string.lower(a.judul) < string.lower(b.judul) end)
	return sorted
end

function MusicModule:GetMusicById(musicId)
	for _, music in ipairs(self:GetAllMusic()) do
		if music.id == musicId then return music end
	end
	return nil
end

function MusicModule:SearchMusic(query)
	local list = self:GetAllMusic()
	if not query or query == "" then return list end
	local results    = {}
	local lowerQuery = string.lower(query)
	for _, music in ipairs(list) do
		if string.find(string.lower(music.judul), lowerQuery, 1, true) then
			table.insert(results, music)
		end
	end
	table.sort(results, function(a, b) return string.lower(a.judul) < string.lower(b.judul) end)
	return results
end

MusicModule.ActionTypes = {
	ADD_TO_QUEUE  = "ADD_TO_QUEUE",
	CONTROL_NEXT  = "CONTROL_NEXT",
	CONTROL_PREV  = "CONTROL_PREV",
	CONTROL_PAUSE = "CONTROL_PAUSE",
	SKIP_VOTE_YES = "SKIP_VOTE_YES",
	SKIP_VOTE_NO  = "SKIP_VOTE_NO",
}

MusicModule.EventTypes = {
	SYNC_STATE       = "SYNC_STATE",
	QUEUE_UPDATE     = "QUEUE_UPDATE",
	NOTIFY           = "NOTIFY",
	SKIP_VOTE_START  = "SKIP_VOTE_START",
	SKIP_VOTE_UPDATE = "SKIP_VOTE_UPDATE",
	SKIP_VOTE_END    = "SKIP_VOTE_END",
}

return MusicModule
