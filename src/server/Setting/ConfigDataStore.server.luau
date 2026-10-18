local Players          = game:GetService("Players")
local DataStoreService = game:GetService("DataStoreService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ConfigStore = DataStoreService:GetDataStore("ConfigClientStoreV3")

local RemotesFolder = ReplicatedStorage:FindFirstChild("ConfigRemotes") or ReplicatedStorage:WaitForChild("ConfigRemotes", 10)
if not RemotesFolder then
	RemotesFolder = Instance.new("Folder")
	RemotesFolder.Name = "ConfigRemotes"
	RemotesFolder.Parent = ReplicatedStorage
end

local LoadSettingsEvent = RemotesFolder:FindFirstChild("LoadSettings")
if not LoadSettingsEvent then
	LoadSettingsEvent = Instance.new("RemoteFunction")
	LoadSettingsEvent.Name = "LoadSettings"
	LoadSettingsEvent.Parent = RemotesFolder
end

local SaveSettingEvent = RemotesFolder:FindFirstChild("SaveSetting")
if not SaveSettingEvent then
	SaveSettingEvent = Instance.new("RemoteEvent")
	SaveSettingEvent.Name = "SaveSetting"
	SaveSettingEvent.Parent = RemotesFolder
end

local ResetSettingsEvent = RemotesFolder:FindFirstChild("ResetSettings")
if not ResetSettingsEvent then
	ResetSettingsEvent = Instance.new("RemoteEvent")
	ResetSettingsEvent.Name = "ResetSettings"
	ResetSettingsEvent.Parent = RemotesFolder
end

local DEFAULT_SETTINGS = {
	hideBubbleChat    = false,
	hidePlayerEffects = false,
	hidePlayers       = false,
	hideOverhead      = false,
	hideShadow        = false,
	muteMusic         = false,
	musicVolume       = 50,
	game_rank         = true,
	currentTheme      = "White",
}

local MIGRATION_MAP = {

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
		return nil
	end

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

	for k, v in pairs(DEFAULT_SETTINGS) do
		if migrated[k] == nil then
			migrated[k] = v
		end
	end

	local saveOk, saveErr = pcall(function()
		ConfigStore:SetAsync(key, migrated)
	end)

	if saveOk then
		print("🔄 Pengaturan V2→V3 dimigrasi untuk", player.Name)
	else
		warn("❌ Gagal menyimpan migrasi pengaturan untuk", player.Name, ":", saveErr)
	end

	return migrated
end

local sessionSettings = {}
local pendingSaves = {}

local SAVE_THROTTLE_TIME = 3

local function flushSave(userId)
	local dataToSave = sessionSettings[userId]
	if not dataToSave then
		local pending = pendingSaves[userId]
		if pending and pending.data then
			dataToSave = pending.data
		end
	end

	pendingSaves[userId] = nil
	if not dataToSave then return end

	local key = "Player_" .. tostring(userId)

	local saveOk, saveErr = pcall(function()
		ConfigStore:UpdateAsync(key, function(oldData)
			local merged = (type(oldData) == "table") and oldData or {}
			for k, v in pairs(dataToSave) do
				merged[k] = v
			end
			return merged
		end)
	end)

	if saveOk then
		print(string.format("💾 [ConfigDataStore] Pengaturan tersimpan ke DataStore untuk userId %d (Tema: %s)", userId, tostring(dataToSave.currentTheme or "White")))
	else
		if string.find(tostring(saveErr), "403") or string.find(tostring(saveErr), "API Services") then
			warn("⚠️ [ConfigDataStore] Akses API DataStore di Roblox Studio belum diaktifkan! Buka Game Settings -> Security -> Aktifkan 'Enable Studio Access to API Services'.")
		else
			warn("❌ [ConfigDataStore] Gagal menyimpan ke DataStore untuk userId", userId, ":", saveErr)
		end
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

local function loadPlayerSettings(player)
	local userId = player.UserId
	if sessionSettings[userId] then
		return sessionSettings[userId]
	end

	local key = "Player_" .. tostring(userId)

	local ok, data = pcall(function()
		return ConfigStore:GetAsync(key)
	end)

	local settings = {}
	if ok and type(data) == "table" then
		for k, v in pairs(DEFAULT_SETTINGS) do
			if data[k] ~= nil then
				settings[k] = data[k]
			else
				settings[k] = v
			end
		end
		print("✅ [ConfigDataStore] Pengaturan berhasil dimuat untuk", player.Name, "- Tema:", settings.currentTheme)
	else
		local migrated = migrateFromV2(player)
		if migrated then
			settings = migrated
		else
			for k, v in pairs(DEFAULT_SETTINGS) do
				settings[k] = v
			end
			print("📋 [ConfigDataStore] Tidak ada pengaturan tersimpan untuk", player.Name, "- menggunakan bawaan")
		end
	end

	sessionSettings[userId] = settings
	player:SetAttribute("CurrentTheme", settings.currentTheme or "White")
	player:SetAttribute("SettingsLoaded", true)
	return settings
end

LoadSettingsEvent.OnServerInvoke = function(player)
	return loadPlayerSettings(player)
end

SaveSettingEvent.OnServerEvent:Connect(function(player, settingKey, value)
	if type(settingKey) ~= "string" then
		warn("⚠️ Tipe kunci pengaturan tidak valid dari", player.Name)
		return
	end

	if DEFAULT_SETTINGS[settingKey] == nil then
		warn("⚠️ Kunci pengaturan tidak dikenal:", settingKey, "dari", player.Name)
		return
	end

	local expectedType = type(DEFAULT_SETTINGS[settingKey])
	if type(value) ~= expectedType then
		warn(string.format("⚠️ Ketidakcocokan tipe untuk %s: diharapkan %s, diterima %s dari %s",
			settingKey, expectedType, type(value), player.Name))
		return
	end

	if settingKey == "musicVolume" then
		if type(value) ~= "number" then return end
		value = math.clamp(math.floor(value), 0, 100)
	end

	local userId = player.UserId
	if not sessionSettings[userId] then
		sessionSettings[userId] = loadPlayerSettings(player)
	end

	sessionSettings[userId][settingKey] = value

	if settingKey == "currentTheme" then
		if type(value) == "string" and #value <= 50 then
			player:SetAttribute("CurrentTheme", value)
		end
	end

	scheduleSave(userId, settingKey, value)
end)

ResetSettingsEvent.OnServerEvent:Connect(function(player)
	local userId = player.UserId
	local key = "Player_" .. tostring(userId)

	pendingSaves[userId] = nil

	local resetData = {}
	for k, v in pairs(DEFAULT_SETTINGS) do
		resetData[k] = v
	end

	sessionSettings[userId] = resetData
	player:SetAttribute("CurrentTheme", "White")

	local ok, err = pcall(function()
		ConfigStore:SetAsync(key, resetData)
	end)

	if ok then
		print("🔄 Atur ulang pengaturan untuk", player.Name)
	else
		warn("❌ Gagal mengatur ulang pengaturan untuk", player.Name, ":", err)
	end
end)

Players.PlayerAdded:Connect(function(player)
	task.spawn(function()
		loadPlayerSettings(player)
	end)
end)

for _, player in ipairs(Players:GetPlayers()) do
	task.spawn(function()
		loadPlayerSettings(player)
	end)
end

Players.PlayerRemoving:Connect(function(player)
	local userId = player.UserId

	flushSave(userId)
	sessionSettings[userId] = nil
	print("👋", player.Name, "keluar map (pengaturan tersimpan)")
end)

game:BindToClose(function()
	print("🛑 Server menutup, menyimpan semua pengaturan pemain...")
	for userId, _ in pairs(sessionSettings) do
		flushSave(userId)
	end
end)

print("✅ ConfigDataStore V3 (Tersinkronisasi dengan ConfigClient) Berhasil dimuat!")
print("🔄 Migrasi otomatis dari V2 aktif")
print("⏱️ Jeda penyimpanan:", SAVE_THROTTLE_TIME, "detik")

