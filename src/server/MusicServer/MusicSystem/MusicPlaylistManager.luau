local ReplicatedStorage = game:GetService("ReplicatedStorage")
local MusicModule = require(ReplicatedStorage.Modules:WaitForChild("MusicModule"))

local MusicPlaylistManager = {}
MusicPlaylistManager.__index = MusicPlaylistManager

function MusicPlaylistManager.new(config)
	local self = setmetatable({}, MusicPlaylistManager)
	self.config        = config
	self.playlistIndex = 1
	self.shuffleMode   = true
	self.playedSongs   = {}
	self.peekedSong    = nil
	return self
end

function MusicPlaylistManager:GetNextSong()
	local playlist = MusicModule:GetAllMusic()
	if #playlist == 0 then
		warn("Playlist kosong!")
		return nil
	end

	local nextSong

	if self.shuffleMode then
		if self.peekedSong then
			nextSong = self.peekedSong
			self.peekedSong = nil
		else
			local availableSongs = {}
			for i, song in ipairs(playlist) do
				if not self.playedSongs[song.id] then
					table.insert(availableSongs, song)
				end
			end
			if #availableSongs == 0 then
				self.playedSongs = {}
				availableSongs = playlist
			end
			local randomIndex = math.random(1, #availableSongs)
			nextSong = availableSongs[randomIndex]
		end
	else
		nextSong = playlist[self.playlistIndex]
		self.playlistIndex = self.playlistIndex + 1
		if self.playlistIndex > #playlist then
			self.playlistIndex = 1
		end
	end

	if nextSong then
		self.playedSongs[nextSong.id] = true
	end

	return nextSong
end

function MusicPlaylistManager:PeekNextSong()
	local playlist = MusicModule:GetAllMusic()
	if #playlist == 0 then return nil end

	if self.shuffleMode then
		if self.peekedSong then
			return self.peekedSong
		end
		local availableSongs = {}
		for _, song in ipairs(playlist) do
			if not self.playedSongs[song.id] then
				table.insert(availableSongs, song)
			end
		end
		if #availableSongs == 0 then
			availableSongs = playlist
		end

		local randomIndex = math.random(1, #availableSongs)
		self.peekedSong = availableSongs[randomIndex]
		return self.peekedSong
	else
		local peekIndex = self.playlistIndex
		if peekIndex > #playlist then peekIndex = 1 end
		return playlist[peekIndex]
	end
end

function MusicPlaylistManager:SetShuffleMode(enabled)
	self.shuffleMode = enabled
	self.peekedSong  = nil
	if enabled then
		self.playedSongs = {}
	end
end

function MusicPlaylistManager:ResetPlaylist()
	self.playlistIndex = 1
	self.playedSongs   = {}
	self.peekedSong    = nil
end

function MusicPlaylistManager:GetPlaylistSize()
	return #MusicModule:GetAllMusic()
end

return MusicPlaylistManager
