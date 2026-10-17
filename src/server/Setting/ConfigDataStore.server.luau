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
	musicVolume       = 100,
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

local pendingSaves = {}

local SAVE_THROTTLE_TIME = 5

local function flushSave(userId)
	local pending = pendingSaves[userId]
	if not pending then return end

	pendingSaves[userId] = nil

	local key = "Player_" .. tostring(userId)

	local ok, currentData = pcall(function()
		return ConfigStore:GetAsync(key)
	end)

	local dataToSave = (ok and type(currentData) == "table") and currentData or {}

	for settingKey, value in pairs(pending.data) do
		dataToSave[settingKey] = value
	end

	local saveOk, saveErr = pcall(function()
		ConfigStore:SetAsync(key, dataToSave)
	end)

	if saveOk then
		local count = 0
		for _ in pairs(pending.data) do count = count + 1 end
		print(string.format("💾 Tersimpan %d pengaturan untuk userId %d", count, userId))
	else
		warn("❌ Gagal menyimpan batch pengaturan untuk userId", userId, ":", saveErr)
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

LoadSettingsEvent.OnServerInvoke = function(player)
	local key = "Player_" .. tostring(player.UserId)

	local ok, data = pcall(function()
		return ConfigStore:GetAsync(key)
	end)

	if ok and type(data) == "table" then

		local merged = {}
		for k, v in pairs(DEFAULT_SETTINGS) do
			if data[k] ~= nil then
				merged[k] = data[k]
			else
				merged[k] = v
			end
		end
		print("✅ Pengaturan berhasil dimuat untuk", player.Name)
		return merged
	end

	local migrated = migrateFromV2(player)
	if migrated then
		return migrated
	end

	print("📋 Tidak ada pengaturan tersimpan untuk", player.Name, "- menggunakan bawaan")

	pcall(function()
		local defaultCopy = {}
		for k, v in pairs(DEFAULT_SETTINGS) do
			defaultCopy[k] = v
		end
		ConfigStore:SetAsync(key, defaultCopy)
	end)

	return DEFAULT_SETTINGS
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

	scheduleSave(player.UserId, settingKey, value)
end)

ResetSettingsEvent.OnServerEvent:Connect(function(player)
	local key = "Player_" .. tostring(player.UserId)

	pendingSaves[player.UserId] = nil

	local resetData = {}
	for k, v in pairs(DEFAULT_SETTINGS) do
		resetData[k] = v
	end

	local ok, err = pcall(function()
		ConfigStore:SetAsync(key, resetData)
	end)

	if ok then
		print("🔄 Atur ulang pengaturan untuk", player.Name)
	else
		warn("❌ Gagal mengatur ulang pengaturan untuk", player.Name, ":", err)
	end
end)

Players.PlayerRemoving:Connect(function(player)
	local userId = player.UserId

	if pendingSaves[userId] then
		task.spawn(function()
			flushSave(userId)
		end)
	end

	print("👋", player.Name, "keluar")
end)

game:BindToClose(function()
	local flushThreads = {}

	for userId, _ in pairs(pendingSaves) do
		table.insert(flushThreads, task.spawn(function()
			flushSave(userId)
		end))
	end

	task.wait(5)
end)

print("✅ ConfigDataStore V3 (Tersinkronisasi dengan ConfigClient) Berhasil dimuat!")
print("🔄 Migrasi otomatis dari V2 aktif")
print("⏱️ Jeda penyimpanan:", SAVE_THROTTLE_TIME, "detik")
