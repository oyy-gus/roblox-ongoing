--[[
	init.client.luau
	Titik masuk (entry point) utama klien.
	- TopbarController: tampilkan ikon menu di topbar kanan
	- MusicController: urus audio + inisialisasi MenuController di dalamnya
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Tunggu Shared siap (maks 15 detik)
local shared = ReplicatedStorage:WaitForChild("Shared", 15)
if not shared then
	warn("[ClientInit] ReplicatedStorage.Shared tidak ditemukan!")
end

print("[ClientInit] Memulai inisialisasi klien...")

-- 1. TopbarController (ikon menu di topbar)
task.spawn(function()
	local controllers = script:WaitForChild("Controllers", 10)
	if not controllers then
		warn("[ClientInit] Folder Controllers tidak ditemukan!")
		return
	end
	local topbarScript = controllers:WaitForChild("TopbarController", 10)
	if not topbarScript then
		warn("[ClientInit] TopbarController tidak ditemukan!")
		return
	end
	local ok, TopbarController = pcall(require, topbarScript)
	if ok and TopbarController and TopbarController.Init then
		TopbarController.Init()
		print("[ClientInit] TopbarController siap.")
	else
		warn("[ClientInit] Gagal require TopbarController:", TopbarController)
	end
end)

-- 2. MusicController (audio + inisialisasi MenuController di dalamnya)
task.spawn(function()
	local controllers = script:WaitForChild("Controllers", 10)
	if not controllers then return end
	local musicScript = controllers:WaitForChild("MusicController", 10)
	if not musicScript then return end

	local ok, MusicController = pcall(require, musicScript)
	if ok and MusicController and MusicController.Init then
		MusicController.Init()
		print("[ClientInit] MusicController siap.")
	else
		warn("[ClientInit] Gagal require MusicController:", MusicController)
	end
end)

print("[ClientInit] Spawn selesai.")

