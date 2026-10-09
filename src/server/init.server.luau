--[[
	init.server.luau
	Titik masuk utama server Roblox.
	Menginisialisasi semua service: FavoriteService, MusicService.
]]

print("[ServerInit] Server mulai...")

local Server   = script
local Services = Server:WaitForChild("Services", 10)

if not Services then
	error("[ServerInit] FATAL: Folder 'Services' tidak ditemukan!")
end

-- 1. FavoriteService (DataStore favorit lagu pemain)
local favOk, FavoriteService = pcall(require, Services:WaitForChild("FavoriteService"))
if favOk and FavoriteService and type(FavoriteService.Init) == "function" then
	local initOk, err = pcall(FavoriteService.Init)
	if initOk then
		print("[ServerInit] FavoriteService siap.")
	else
		warn("[ServerInit] FavoriteService.Init gagal:", err)
	end
else
	warn("[ServerInit] FavoriteService tidak dapat dimuat:", FavoriteService)
end

-- 2. MusicService (remote, playlist, sinkronisasi, pemutaran lagu)
local musOk, MusicService = pcall(require, Services:WaitForChild("MusicService"))
if not musOk then
	error("[ServerInit] FATAL: MusicService gagal dimuat: " .. tostring(MusicService))
end

if type(MusicService.Init) ~= "function" then
	error("[ServerInit] FATAL: MusicService.Init bukan fungsi!")
end

local initOk, initErr = pcall(MusicService.Init)
if initOk then
	print("[ServerInit] MusicService siap. Lagu mulai diputar.")
else
	error("[ServerInit] FATAL: MusicService.Init error: " .. tostring(initErr))
end
