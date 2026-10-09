--[[
	Config.lua
	Tujuan: Menyimpan konfigurasi perilaku global sistem musik.
]]

local Config = {
	-- API Playlist URL
	PLAYLIST_URL = "https://oyy-gus.github.io/api/v1/roblox/music/playlist.json",

	-- Interval sinkronisasi server ke klien (detik)
	SYNC_INTERVAL = 5,

	-- Batas toleransi drift waktu sebelum re-seek (detik)
	SEEK_THRESHOLD = 0.3,

	-- Batas lompatan seek maksimum (detik)
	MAX_SEEK_JUMP = 30,

	-- Volume bawaan lokal untuk pemain (0.0 - 1.0)
	DEFAULT_VOLUME = 0.6,

	-- Cooldown tindakan skip/prev lagu di server (detik)
	SKIP_COOLDOWN = 1.5,

	-- Debounce pencarian lagu di klien (detik)
	SEARCH_DEBOUNCE = 0.4,
}

return Config
