-- Place in: ReplicatedStorage > Modules > MusicStorageHandler(ModuleScript)
-- ====================================
-- Changes:
--   ✅ tick() → workspace:GetServerTimeNow()
--   ✅ Tambah PreloadSound() method (non-blocking preload)
--   ✅ Perbaiki cleanup: hindari destroy sound yang sedang di-preload

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService       = game:GetService("HttpService")

local MusicStorageHandler = {}

-- ====================================
-- CONFIGURATION
-- ====================================
local CONFIG = {
	MAX_CACHED_SOUNDS     = 20,
	LOAD_TIMEOUT          = 3.5,  -- DIPERCEPAT: dari 15 ke 3.5s agar audio rusak/502 langsung di-skip tanpa freeze
	PARALLEL_BATCH_SIZE   = 5,
	CLEANUP_INTERVAL      = 300,
	MIN_USAGE_THRESHOLD   = 60,
	RETRY_ATTEMPTS        = 1,    -- 1x coba cukup, hindari 30 detik freeze saat asset bermasalah
	RETRY_DELAY           = 0.5,
}

-- ====================================
-- STATE MANAGEMENT
-- ====================================
MusicStorageHandler.Status = {
	IsLoading       = false,
	CachedSounds    = {},
	LoadingPromises = {},
	AccessTimes     = {},
	FailedSounds    = {},
	PreloadingSounds = {},  -- BARU: track sounds yang sedang di-preload
	Stats = {
		TotalLoads  = 0,
		CacheHits   = 0,
		CacheMisses = 0,
		MemoryFreed = 0,
	},
}

-- ====================================
-- STORAGE FOLDER
-- ====================================
local storageFolder
local function getStorageFolder()
	if not storageFolder or not storageFolder.Parent then
		storageFolder = ReplicatedStorage:FindFirstChild("MusicStorage")
		if not storageFolder then
			storageFolder        = Instance.new("Folder")
			storageFolder.Name   = "MusicStorage"
			storageFolder.Parent = ReplicatedStorage
		end
	end
	return storageFolder
end

-- ====================================
-- LRU CACHE MANAGEMENT
-- ====================================
local function updateAccessTime(musicId)
	MusicStorageHandler.Status.AccessTimes[musicId] = workspace:GetServerTimeNow()
end

local function getLRUSounds()
	local sounds = {}
	for _, sound in ipairs(getStorageFolder():GetChildren()) do
		if sound:IsA("Sound") then
			local lastAccess = MusicStorageHandler.Status.AccessTimes[sound.Name] or 0
			table.insert(sounds, {
				sound      = sound,
				lastAccess = lastAccess,
				age        = workspace:GetServerTimeNow() - lastAccess,
			})
		end
	end
	table.sort(sounds, function(a, b) return a.lastAccess < b.lastAccess end)
	return sounds
end

local function cleanupOldSounds()
	local sounds      = getLRUSounds()
	local removed     = 0
	local currentTime = workspace:GetServerTimeNow()

	-- Jangan destroy sound yang sedang di-preload
	local preloading = MusicStorageHandler.Status.PreloadingSounds

	while #sounds > CONFIG.MAX_CACHED_SOUNDS do
		local oldest = sounds[1]
		if oldest.sound and not preloading[oldest.sound.Name] then
			pcall(function()
				oldest.sound:Destroy()
				MusicStorageHandler.Status.CachedSounds[oldest.sound.Name] = nil
				MusicStorageHandler.Status.AccessTimes[oldest.sound.Name]  = nil
				removed = removed + 1
			end)
		end
		table.remove(sounds, 1)
	end

	for _, data in ipairs(sounds) do
		if data.age > CONFIG.MIN_USAGE_THRESHOLD and not preloading[data.sound.Name] then
			pcall(function()
				data.sound:Destroy()
				MusicStorageHandler.Status.CachedSounds[data.sound.Name] = nil
				MusicStorageHandler.Status.AccessTimes[data.sound.Name]  = nil
				removed = removed + 1
			end)
		end
	end

	if removed > 0 then
		MusicStorageHandler.Status.Stats.MemoryFreed =
			MusicStorageHandler.Status.Stats.MemoryFreed + removed
	end

	return removed
end

-- ====================================
-- LOADING WITH RETRY
-- ====================================
local function loadSoundWithRetry(musicId, musicTitle)
	for attempt = 1, CONFIG.RETRY_ATTEMPTS do
		local sound       = Instance.new("Sound")
		sound.Name        = musicId
		sound.SoundId     = "rbxassetid://" .. musicId
		sound.Volume      = 0
		sound.Looped      = false
		sound.Parent      = getStorageFolder()

		sound:SetAttribute("Title", musicTitle or "Unknown")
		sound:SetAttribute("CreatedAt", workspace:GetServerTimeNow())

		local startTime = workspace:GetServerTimeNow()
		while sound.TimeLength == 0 and (workspace:GetServerTimeNow() - startTime) < CONFIG.LOAD_TIMEOUT do
			task.wait(0.1)
		end

		if sound.TimeLength > 0 then
			sound:SetAttribute("Duration", sound.TimeLength)
			updateAccessTime(musicId)
			return sound, sound.TimeLength
		else
			pcall(function() sound:Destroy() end)
			if attempt < CONFIG.RETRY_ATTEMPTS then
				task.wait(CONFIG.RETRY_DELAY)
			end
		end
	end

	return nil, 0
end

-- ====================================
-- LAZY LOAD (ON-DEMAND)
-- ====================================
function MusicStorageHandler:LoadSound(musicId, musicTitle)
	local cached = self.Status.CachedSounds[musicId]
	if cached then
		self.Status.Stats.CacheHits = self.Status.Stats.CacheHits + 1
		updateAccessTime(musicId)
		local duration = cached:GetAttribute("Duration") or cached.TimeLength
		return cached, duration
	end

	if self.Status.LoadingPromises[musicId] then
		local startWait = workspace:GetServerTimeNow()
		while self.Status.LoadingPromises[musicId] and (workspace:GetServerTimeNow() - startWait) < CONFIG.LOAD_TIMEOUT do
			task.wait(0.1)
		end
		cached = self.Status.CachedSounds[musicId]
		if cached then
			return cached, cached:GetAttribute("Duration") or cached.TimeLength
		end
	end

	self.Status.LoadingPromises[musicId] = true
	self.Status.Stats.CacheMisses = self.Status.Stats.CacheMisses + 1
	self.Status.Stats.TotalLoads  = self.Status.Stats.TotalLoads + 1

	local sound, duration = loadSoundWithRetry(musicId, musicTitle)
	self.Status.LoadingPromises[musicId] = nil

	if sound and duration > 0 then
		self.Status.CachedSounds[musicId] = sound
		if #getStorageFolder():GetChildren() > CONFIG.MAX_CACHED_SOUNDS then
			cleanupOldSounds()
		end
		return sound, duration
	else
		self.Status.FailedSounds[musicId] = {
			title     = musicTitle,
			timestamp = workspace:GetServerTimeNow(),
		}
		return nil, 0
	end
end

-- ====================================
-- PRELOAD (NON-BLOCKING) — BARU
-- ====================================
--- Preload lagu di background tanpa blocking. Untuk digunakan oleh preload system.
function MusicStorageHandler:PreloadSound(musicId, musicTitle)
	-- Sudah ada di cache? Skip.
	if self.Status.CachedSounds[musicId] then return end
	-- Sedang loading? Skip.
	if self.Status.LoadingPromises[musicId] then return end

	self.Status.PreloadingSounds[musicId] = true
	task.spawn(function()
		self:LoadSound(musicId, musicTitle)
		self.Status.PreloadingSounds[musicId] = nil
	end)
end

-- ====================================
-- BATCH PRELOAD
-- ====================================
function MusicStorageHandler:PreloadBatch(musicList, onProgress, onComplete)
	if self.Status.IsLoading then return end

	self.Status.IsLoading = true
	local totalSongs  = #musicList
	local loadedCount = 0
	local failedCount = 0

	task.spawn(function()
		for i = 1, totalSongs, CONFIG.PARALLEL_BATCH_SIZE do
			local batch    = {}
			local batchEnd = math.min(i + CONFIG.PARALLEL_BATCH_SIZE - 1, totalSongs)
			for j = i, batchEnd do
				local music = musicList[j]
				if music and music.id then
					table.insert(batch, task.spawn(function()
						local sound, duration = self:LoadSound(music.id, music.judul)
						if duration > 0 then
							loadedCount    = loadedCount + 1
							music.Duration = duration
						else
							failedCount = failedCount + 1
						end
						if onProgress then
							onProgress(loadedCount + failedCount, totalSongs, music.judul, duration)
						end
					end))
				end
			end
			task.wait(0.2)
		end
		self.Status.IsLoading = false
		if onComplete then onComplete(loadedCount, totalSongs) end
	end)
end

-- ====================================
-- GET METHODS
-- ====================================
function MusicStorageHandler:GetSound(musicId)
	local sound = self.Status.CachedSounds[musicId]
	if sound then
		updateAccessTime(musicId)
		local duration = sound:GetAttribute("Duration") or sound.TimeLength
		return sound, duration
	end
	return nil, 0
end

function MusicStorageHandler:IsSoundReady(musicId)
	local sound = self.Status.CachedSounds[musicId]
	if sound then
		local duration = sound:GetAttribute("Duration") or 0
		return duration > 0
	end
	return false
end

function MusicStorageHandler:IsSoundFailed(musicId)
	return self.Status.FailedSounds[musicId] ~= nil
end

-- ====================================
-- AUTO CLEANUP LOOP
-- ====================================
function MusicStorageHandler:StartAutoCleanup()
	task.spawn(function()
		while true do
			task.wait(CONFIG.CLEANUP_INTERVAL)
			cleanupOldSounds()
		end
	end)
end

-- ====================================
-- STATISTICS
-- ====================================
function MusicStorageHandler:GetStats()
	local cacheSize = 0
	for _ in pairs(self.Status.CachedSounds) do
		cacheSize = cacheSize + 1
	end
	local hitRate = self.Status.Stats.TotalLoads > 0 and
		(self.Status.Stats.CacheHits / self.Status.Stats.TotalLoads * 100) or 0
	return {
		cachedSounds = cacheSize,
		totalLoads   = self.Status.Stats.TotalLoads,
		cacheHits    = self.Status.Stats.CacheHits,
		cacheMisses  = self.Status.Stats.CacheMisses,
		hitRate      = string.format("%.1f%%", hitRate),
		failedSounds = #self.Status.FailedSounds,
		memoryFreed  = self.Status.Stats.MemoryFreed,
	}
end

function MusicStorageHandler:PrintStats()
	-- Method kept for compatibility
end

-- ====================================
-- MANUAL CLEANUP
-- ====================================
function MusicStorageHandler:ForceCleanup()
	return cleanupOldSounds()
end

function MusicStorageHandler:ClearCache()
	for _, sound in ipairs(getStorageFolder():GetChildren()) do
		if sound:IsA("Sound") then
			pcall(function() sound:Destroy() end)
		end
	end
	self.Status.CachedSounds     = {}
	self.Status.AccessTimes      = {}
	self.Status.FailedSounds     = {}
	self.Status.PreloadingSounds = {}
end

return MusicStorageHandler

-- ====================================
-- NOTIF MODULE
