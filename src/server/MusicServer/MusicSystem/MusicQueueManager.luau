local MusicQueueManager = {}
MusicQueueManager.__index = MusicQueueManager

function MusicQueueManager.new(config)
	local self = setmetatable({}, MusicQueueManager)
	self.config           = config
	self.queue            = {}
	self.playerQueueCount = {}
	return self
end

local function cleanId(raw)
	if not raw then return "" end
	local s = tostring(raw):gsub("%s+", "")
	return s:match("%d+") or s
end

function MusicQueueManager:IsInQueue(musicId)
	if not musicId then return false end
	local targetId = cleanId(musicId)
	if targetId == "" then return false end
	for _, entry in ipairs(self.queue) do
		local mData = entry.musicData or entry
		local rawId = mData and (mData.id or mData.sound_id)
		if rawId and cleanId(rawId) == targetId then
			return true
		end
	end
	return false
end

function MusicQueueManager:AddToQueue(musicData, uploaderName, userId)
	local rawId = musicData and (musicData.id or musicData.sound_id)
	if self:IsInQueue(rawId) then
		return false, "Lagu ini sudah ada di antrean!"
	end

	if #self.queue >= self.config.MAX_QUEUE_SIZE then
		return false, "Queue penuh! Tunggu beberapa lagu selesai."
	end

	local userCount = self.playerQueueCount[userId] or 0
	if userCount >= self.config.MAX_QUEUE_PER_USER then
		return false, string.format("Anda sudah punya %d lagu di queue!", self.config.MAX_QUEUE_PER_USER)
	end

	table.insert(self.queue, {
		musicData = musicData,
		uploader  = uploaderName,
		userId    = userId,
		Duration  = (musicData and (musicData.Duration or musicData.duration)) or 0,
		addedTime = workspace:GetServerTimeNow(),
	})

	self.playerQueueCount[userId] = userCount + 1
	return true, nil
end

function MusicQueueManager:GetNext()
	if #self.queue > 0 then
		local nextSong = table.remove(self.queue, 1)
		if nextSong.userId then
			local count = self.playerQueueCount[nextSong.userId] or 0
			self.playerQueueCount[nextSong.userId] = math.max(0, count - 1)
		end
		return nextSong
	end
	return nil
end

function MusicQueueManager:GetQueue()
	return self.queue
end

function MusicQueueManager:IsEmpty()
	return #self.queue == 0
end

function MusicQueueManager:GetSize()
	return #self.queue
end

function MusicQueueManager:RemoveUserSongs(userId)
	local removed = 0
	for i = #self.queue, 1, -1 do
		if self.queue[i].userId == userId then
			table.remove(self.queue, i)
			removed = removed + 1
		end
	end
	self.playerQueueCount[userId] = nil
	return removed
end

function MusicQueueManager:GetUserQueueCount(userId)
	return self.playerQueueCount[userId] or 0
end

function MusicQueueManager:UpdateDuration(musicId, duration)
	if not musicId or not duration or duration <= 0 then return false end
	local updated = false
	for _, entry in ipairs(self.queue) do
		local entryId = entry.musicData and entry.musicData.id
		if entryId == musicId then
			entry.Duration = math.round(duration)
			if entry.musicData then
				entry.musicData.Duration = math.round(duration)
			end
			updated = true
		end
	end
	return updated
end

function MusicQueueManager:Clear()
	self.queue            = {}
	self.playerQueueCount = {}
end

return MusicQueueManager
