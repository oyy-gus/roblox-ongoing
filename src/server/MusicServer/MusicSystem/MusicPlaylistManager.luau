-- ====================================
-- MUSIC PLAYLIST MANAGER (IMPROVED)
-- Place in: ServerScriptService > MusicServer(Folder) > MusicSystem(Script) > MusicPlaylistManager(ModuleScript)
-- ====================================
-- Changes:
--   ✅ Tambah PeekNextSong() — lihat lagu berikutnya tanpa mengonsumsi (untuk preload)
--   ✅ workspace:GetServerTimeNow() (tidak ada tick() di file ini, tapi distandarisasi)

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local MusicModule = require(ReplicatedStorage.Modules:WaitForChild("MusicModule"))

local MusicPlaylistManager = {}
MusicPlaylistManager.__index = MusicPlaylistManager

function MusicPlaylistManager.new(config)
	local self = setmetatable({}, MusicPlaylistManager)
	self.config        = config
	self.playlistIndex = 1
	self.shuffleMode   = false
	self.playedSongs   = {}
	return self
end

-- ====================================
-- PLAYLIST OPERATIONS
-- ====================================

function MusicPlaylistManager:GetNextSong()
	local playlist = MusicModule:GetAllMusic()
	if #playlist == 0 then
		warn("Playlist kosong!")
		return nil
	end

	local nextSong

	if self.shuffleMode then
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

--- BARU: Lihat lagu berikutnya TANPA mengonsumsi (untuk preloading)
function MusicPlaylistManager:PeekNextSong()
	local playlist = MusicModule:GetAllMusic()
	if #playlist == 0 then return nil end

	if self.shuffleMode then
		-- Dalam mode shuffle, kita tidak bisa memprediksi dengan pasti,
		-- tapi kita bisa ambil satu random candidate untuk preload
		local availableSongs = {}
		for _, song in ipairs(playlist) do
			if not self.playedSongs[song.id] then
				table.insert(availableSongs, song)
			end
		end
		if #availableSongs == 0 then
			availableSongs = playlist
		end
		-- Gunakan index tetap agar peek konsisten (tidak random setiap panggilan)
		return availableSongs[1]
	else
		-- Sequential: kembalikan lagu di index berikutnya
		local peekIndex = self.playlistIndex
		if peekIndex > #playlist then peekIndex = 1 end
		return playlist[peekIndex]
	end
end

function MusicPlaylistManager:SetShuffleMode(enabled)
	self.shuffleMode = enabled
	if enabled then
		self.playedSongs = {}
	end
end

function MusicPlaylistManager:ResetPlaylist()
	self.playlistIndex = 1
	self.playedSongs   = {}
end

function MusicPlaylistManager:GetPlaylistSize()
	return #MusicModule:GetAllMusic()
end

return MusicPlaylistManager
