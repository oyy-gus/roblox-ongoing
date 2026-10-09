--[[
	Remotes.lua
	Tujuan: Definisi terpusat nama RemoteEvent dan RemoteFunction serta helper pengaksesannya.

	PENTING:
	  - Server: membuat folder & remote jika belum ada (Instance.new)
	  - Client: MENUNGGU folder & remote yang dibuat server (WaitForChild)
	  Jangan pernah buat folder/remote baru di sisi klien!
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Remotes = {
	NAMES = {
		SyncState       = "SyncState",
		NextSong        = "NextSong",
		PrevSong        = "PrevSong",
		VoteSkip        = "VoteSkip",
		PlaySongAtIndex = "PlaySongAtIndex",
		AddToQueue      = "AddToQueue",
		GetState        = "GetState",
		GetPlaylist     = "GetPlaylist",
		SearchMusic     = "SearchMusic",
		ToggleFavorite  = "ToggleFavorite",
		GetFavorites    = "GetFavorites",
	}
}

function Remotes.GetFolder()
	if RunService:IsServer() then
		-- Server: buat jika belum ada
		local folder = ReplicatedStorage:FindFirstChild("MusicRemotes")
		if not folder then
			folder = Instance.new("Folder")
			folder.Name = "MusicRemotes"
			folder.Parent = ReplicatedStorage
		end
		return folder
	else
		-- Client: TUNGGU folder dari server (maks 15 detik)
		local folder = ReplicatedStorage:WaitForChild("MusicRemotes", 15)
		if not folder then
			warn("[Remotes] Folder 'MusicRemotes' tidak ditemukan dalam 15 detik!")
		end
		return folder
	end
end

function Remotes.GetEvent(name)
	local folder = Remotes.GetFolder()
	if not folder then return nil end

	local remote = folder:FindFirstChild(name)
	if not remote then
		if RunService:IsServer() then
			remote = Instance.new("RemoteEvent")
			remote.Name = name
			remote.Parent = folder
		else
			-- Client: tunggu dari server
			remote = folder:WaitForChild(name, 10)
			if not remote then
				warn(string.format("[Remotes] RemoteEvent '%s' tidak ditemukan dalam 10 detik!", name))
			end
		end
	end
	return remote
end

function Remotes.GetFunction(name)
	local folder = Remotes.GetFolder()
	if not folder then return nil end

	local remote = folder:FindFirstChild(name)
	if not remote then
		if RunService:IsServer() then
			remote = Instance.new("RemoteFunction")
			remote.Name = name
			remote.Parent = folder
		else
			-- Client: tunggu dari server
			remote = folder:WaitForChild(name, 10)
			if not remote then
				warn(string.format("[Remotes] RemoteFunction '%s' tidak ditemukan dalam 10 detik!", name))
			end
		end
	end
	return remote
end

return Remotes

