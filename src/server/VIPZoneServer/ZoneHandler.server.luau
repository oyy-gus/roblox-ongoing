local ServerStorage = game:GetService("ServerStorage")

local CONFIG = {
	ENABLE_DEBUG = false,
	MODULE_INIT_DELAY = 0.5
}

local function debugPrint(message: string, level: string)
	if not CONFIG.ENABLE_DEBUG then return end
	local prefix = {
		info = "ℹ️",
		success = "✅",
		warning = "⚠️",
		error = "❌"
	}
	print((prefix[level] or "📝") .. " [INIT] " .. message)
end

local function initVIPZoneModule()
	task.wait(CONFIG.MODULE_INIT_DELAY)

	local success, result = pcall(function()
		local VIPZone = require(ServerStorage.Modules.VIPZoneModule)
		return VIPZone
	end)

	if not success then
		debugPrint("Gagal memuat modul VIPZone: " .. tostring(result), "error")
		return
	end

	local initSuccess, initError = pcall(function()
		result.Init()
	end)

	if initSuccess then
		debugPrint("Modul VIPZone berhasil diinisialisasi", "success")
	else
		debugPrint("Gagal menginisialisasi VIPZone: " .. tostring(initError), "error")
	end
end

debugPrint("Memulai inisialisasi server...", "info")
initVIPZoneModule()
debugPrint("Seluruh sistem siap", "success")
