-- ====================================
-- CONFIG DATA STORE (SYNCED WITH CONFIGCLIENT)
-- Place in: ServerScriptService > Setting(Folder) > ConfigDataStore(Script)
-- ====================================
-- Perubahan:
--   ✅ Key disinkronkan dengan ConfigClient (hide* format)
--   ✅ Tambah muteMusic & hideShadow
--   ✅ Hapus key lama yang tidak digunakan (bubbleChatEnabled, dll)
--   ✅ Migrasi otomatis dari format lama ke format baru
--   ✅ Throttle save untuk mencegah spam DataStore

local Players          = game:GetService("Players")
local DataStoreService = game:GetService("DataStoreService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ConfigStore = DataStoreService:GetDataStore("ConfigClientStoreV3") -- versi baru (migrasi key)

-- ========================================
-- REMOTES
-- ========================================
local RemotesFolder = Instance.new("Folder")
RemotesFolder.Name   = "ConfigRemotes"
RemotesFolder.Parent = ReplicatedStorage

local LoadSettingsEvent = Instance.new("RemoteFunction")
LoadSettingsEvent.Name   = "LoadSettings"
LoadSettingsEvent.Parent = RemotesFolder

local SaveSettingEvent = Instance.new("RemoteEvent")
SaveSettingEvent.Name   = "SaveSetting"
SaveSettingEvent.Parent = RemotesFolder

local ResetSettingsEvent = Instance.new("RemoteEvent")
ResetSettingsEvent.Name   = "ResetSettings"
ResetSettingsEvent.Parent = RemotesFolder

-- ========================================
-- DEFAULT SETTINGS (SESUAI CONFIGCLIENT)
-- ========================================
local DEFAULT_SETTINGS = {
	hideBubbleChat    = false,
	hidePlayerEffects = false,
	hidePlayers       = false,
	hideOverhead      = false,
	hideShadow        = false,
	muteMusic         = false,
	musicVolume       = 50,
}

-- ========================================
-- MIGRASI DARI FORMAT LAMA
-- Konversi key lama (V2) ke key baru (V3)
-- ========================================
local MIGRATION_MAP = {
	-- oldKey = { newKey, invertValue }
	bubbleChatEnabled    = { newKey = "hideBubbleChat",    invert = true },
	playerEffectsEnabled = { newKey = "hidePlayerEffects", invert = true },
	showPlayersEnabled   = { newKey = "hidePlayers",       invert = true },
	playerNamesEnabled   = { newKey = "hideOverhead",      invert = true },
	musicVolume          = { newKey = "musicVolume",        invert = false },
}

local OldConfigStore = DataStoreService:GetDataStore("ConfigClientStoreV2")

local function migrateFromV2(player)
	local key = "Player_" .. tostring(player.UserId)

	local ok, oldData = pcall(function()
		return OldConfigStore:GetAsync(key)
	end)

	if not ok or type(oldData) ~= "table" then
		return nil -- Tidak ada data lama
	end

	-- Konversi ke format baru
	local migrated = {}
	for oldKey, mapping in pairs(MIGRATION_MAP) do
		if oldData[oldKey] ~= nil then
			if mapping.invert then
				migrated[mapping.newKey] = not oldData[oldKey]
			else
				migrated[mapping.newKey] = oldData[oldKey]
			end
		end
	end

	-- Pastikan semua key default ada
	for k, v in pairs(DEFAULT_SETTINGS) do
		if migrated[k] == nil then
			migrated[k] = v
		end
	end

	-- Simpan ke V3
	local saveOk, saveErr = pcall(function()
		ConfigStore:SetAsync(key, migrated)
	end)

	if saveOk then
		print("🔄 Migrated V2→V3 settings for", player.Name)
	else
		warn("❌ Failed to save migrated settings for", player.Name, ":", saveErr)
	end

	return migrated
end

-- ========================================
-- SAVE THROTTLE (Mencegah spam DataStore)
-- ========================================
local pendingSaves = {} -- [userId] = { data = {}, scheduled = false }

local SAVE_THROTTLE_TIME = 5 -- Tunggu 5 detik sebelum save batch

local function flushSave(userId)
	local pending = pendingSaves[userId]
	if not pending then return end

	pendingSaves[userId] = nil

	local key = "Player_" .. tostring(userId)

	-- Ambil data terbaru dari DataStore
	local ok, currentData = pcall(function()
		return ConfigStore:GetAsync(key)
	end)

	local dataToSave = (ok and type(currentData) == "table") and currentData or {}

	-- Merge pending changes
	for settingKey, value in pairs(pending.data) do
		dataToSave[settingKey] = value
	end

	local saveOk, saveErr = pcall(function()
		ConfigStore:SetAsync(key, dataToSave)
	end)

	if saveOk then
		local count = 0
		for _ in pairs(pending.data) do count = count + 1 end
		print(string.format("💾 Batch saved %d setting(s) for userId %d", count, userId))
	else
		warn("❌ Failed to batch save for userId", userId, ":", saveErr)
	end
end

local function scheduleSave(userId, settingKey, value)
	if not pendingSaves[userId] then
		pendingSaves[userId] = { data = {}, scheduled = false }
	end

	pendingSaves[userId].data[settingKey] = value

	if not pendingSaves[userId].scheduled then
		pendingSaves[userId].scheduled = true
		task.delay(SAVE_THROTTLE_TIME, function()
			flushSave(userId)
		end)
	end
end

-- ========================================
-- LOAD SETTINGS
-- ========================================
LoadSettingsEvent.OnServerInvoke = function(player)
	local key = "Player_" .. tostring(player.UserId)

	-- Coba ambil dari V3
	local ok, data = pcall(function()
		return ConfigStore:GetAsync(key)
	end)

	if ok and type(data) == "table" then
		-- Gabungkan dengan default (key baru yang belum ada)
		local merged = {}
		for k, v in pairs(DEFAULT_SETTINGS) do
			if data[k] ~= nil then
				merged[k] = data[k]
			else
				merged[k] = v
			end
		end
		print("✅ Loaded settings for", player.Name)
		return merged
	end

	-- V3 kosong → coba migrasi dari V2
	local migrated = migrateFromV2(player)
	if migrated then
		return migrated
	end

	-- Tidak ada data sama sekali → default
	print("📋 No saved settings for", player.Name, "- using defaults")

	-- Simpan default ke DataStore agar load berikutnya lebih cepat
	pcall(function()
		local defaultCopy = {}
		for k, v in pairs(DEFAULT_SETTINGS) do
			defaultCopy[k] = v
		end
		ConfigStore:SetAsync(key, defaultCopy)
	end)

	return DEFAULT_SETTINGS
end

-- ========================================
-- SAVE SINGLE SETTING (THROTTLED)
-- ========================================
SaveSettingEvent.OnServerEvent:Connect(function(player, settingKey, value)
	-- Validasi: tipe key harus string
	if type(settingKey) ~= "string" then
		warn("⚠️ Invalid setting key type from", player.Name)
		return
	end

	-- Validasi: hanya izinkan key yang dikenal
	if DEFAULT_SETTINGS[settingKey] == nil then
		warn("⚠️ Unknown setting key:", settingKey, "from", player.Name)
		return
	end

	-- Validasi: tipe value harus sesuai default
	local expectedType = type(DEFAULT_SETTINGS[settingKey])
	if type(value) ~= expectedType then
		warn(string.format("⚠️ Type mismatch for %s: expected %s, got %s from %s",
			settingKey, expectedType, type(value), player.Name))
		return
	end

	-- Validasi: range untuk musicVolume
	if settingKey == "musicVolume" then
		if type(value) ~= "number" then return end
		value = math.clamp(math.floor(value), 0, 100)
	end

	-- Throttled save
	scheduleSave(player.UserId, settingKey, value)
end)

-- ========================================
-- RESET ALL SETTINGS
-- ========================================
ResetSettingsEvent.OnServerEvent:Connect(function(player)
	local key = "Player_" .. tostring(player.UserId)

	-- Batalkan pending save jika ada
	pendingSaves[player.UserId] = nil

	local resetData = {}
	for k, v in pairs(DEFAULT_SETTINGS) do
		resetData[k] = v
	end

	local ok, err = pcall(function()
		ConfigStore:SetAsync(key, resetData)
	end)

	if ok then
		print("🔄 Reset settings for", player.Name)
	else
		warn("❌ Failed to reset settings for", player.Name, ":", err)
	end
end)

-- ========================================
-- CLEANUP: Flush pending saves saat player keluar
-- ========================================
Players.PlayerRemoving:Connect(function(player)
	local userId = player.UserId

	-- Flush pending save sebelum player pergi
	if pendingSaves[userId] then
		task.spawn(function()
			flushSave(userId)
		end)
	end

	print("👋", player.Name, "left")
end)

-- ========================================
-- BIND TO CLOSE: Flush semua pending saves
-- ========================================
game:BindToClose(function()
	local flushThreads = {}

	for userId, _ in pairs(pendingSaves) do
		table.insert(flushThreads, task.spawn(function()
			flushSave(userId)
		end))
	end

	-- Tunggu semua flush selesai (max 5 detik)
	task.wait(5)
end)

print("✅ ConfigDataStore V3 (Synced with ConfigClient) Loaded!")
print("🔄 Auto-migration from V2 enabled")
print("⏱️ Save throttle:", SAVE_THROTTLE_TIME, "seconds")
