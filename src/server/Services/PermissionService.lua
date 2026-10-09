--[[
	PermissionService.lua
	Tujuan: Memvalidasi hak akses pemain (Admin, DJ, atau Pemain Biasa) untuk tindakan kontrol musik.
]]

local PermissionService = {}

-- Daftar UserID Admin atau DJ (Dapat dikembangkan lebih lanjut)
local ADMIN_IDS = {}
local DJ_IDS = {}

function PermissionService.CanControlPlayback(player)
	if not player then return false end
	
	-- Secara bawaan, beri izin atau periksa role (bisa disesuaikan dengan Owner/Group Role)
	if player.UserId == game.CreatorId or game.CreatorId == 0 then
		return true
	end
	
	if ADMIN_IDS[player.UserId] or DJ_IDS[player.UserId] then
		return true
	end

	-- Sementara mengizinkan semua pemain untuk vote / request jika diperbolehkan
	return true
end

function PermissionService.CanSkipSong(player)
	return PermissionService.CanControlPlayback(player)
end

return PermissionService
