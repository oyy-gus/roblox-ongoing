local RunService = game:GetService("RunService")
local ServerMusicAudioHandler = require(script.Parent.ServerMusicAudioHandler)

local MusicPlaybackManager = {}
MusicPlaybackManager.__index = MusicPlaybackManager

local FADE_IN_DURATION  = 1.2
local FADE_OUT_DURATION = 1.0
local PRE_FADE_BUFFER   = 1.5
local PRELOAD_THRESHOLD = 0.80

function MusicPlaybackManager.new(config)
	local self = setmetatable({}, MusicPlaybackManager)
	self.config              = config
	self.currentSong         = nil
	self.currentUploader     = nil
	self.isPlaying           = false
	self.songStartTime       = 0
	self.songDuration        = 0
	self.isPlaylistMode      = false
	self.audioHandler        = ServerMusicAudioHandler.new()
	self.autoNextCallback    = nil
	self.preloadCallback     = nil
	self.endedConnection     = nil
	self.progressConnection  = nil
	self.lastProgressBroadcast = 0
	self.preloadTriggered    = false
	self.isFadingOut         = false
	self.isTransitioning     = false
	return self
end

function MusicPlaybackManager:GetState()
	local elapsed = self:GetElapsedTime()
	return {
		currentSong     = self.currentSong,
		currentUploader = self.currentUploader,
		isPlaying       = self.isPlaying,
		startTime       = self.songStartTime,
		duration        = self.songDuration,
		isPlaylistMode  = self.isPlaylistMode,
		elapsedTime     = elapsed,
		serverTimeNow   = workspace:GetServerTimeNow(),
	}
end

function MusicPlaybackManager:IsPlaying()
	if not self.isPlaying then return false end
	if self.songDuration > 0 then
		local elapsed = self:GetElapsedTime()
		local wallTime = (self.songStartTime > 0) and (workspace:GetServerTimeNow() - self.songStartTime) or 0
		if elapsed >= (self.songDuration + 1) or wallTime >= (self.songDuration + 3) then
			return false
		end
	end
	return self.audioHandler:IsPlaying()
end

function MusicPlaybackManager:GetCurrentSong()
	return self.currentSong
end

function MusicPlaybackManager:GetElapsedTime()
	if self.isPlaying then
		return self.audioHandler:GetTimePosition()
	end
	return 0
end

function MusicPlaybackManager:IsFromPlaylist()
	return self.isPlaylistMode
end

function MusicPlaybackManager:ConnectEndedEvent(remotes)
	if self.endedConnection then
		self.endedConnection:Disconnect()
		self.endedConnection = nil
	end
	if self.timeLengthConnection then
		self.timeLengthConnection:Disconnect()
		self.timeLengthConnection = nil
	end

	local sound = self.audioHandler:GetSound()
	if not sound then return end

	sound.Looped = false

	local function onDurationLoaded(len)
		if len and len > 0 then
			self.songDuration = len
			if self.currentSong then self.currentSong.Duration = len end
			if remotes then
				self:UpdateProgress(remotes)
				pcall(function()
					remotes.MusicBroadcast:FireAllClients("SongDurationUpdate", {
						SoundId  = self.currentSong and self.currentSong.id,
						Duration = len,
					})
				end)
			end
		end
	end

	if sound.TimeLength > 0 then
		onDurationLoaded(sound.TimeLength)
	else
		self.timeLengthConnection = sound:GetPropertyChangedSignal("TimeLength"):Connect(function()
			if sound.TimeLength > 0 then
				if self.timeLengthConnection then
					self.timeLengthConnection:Disconnect()
					self.timeLengthConnection = nil
				end
				onDurationLoaded(sound.TimeLength)
			end
		end)

		task.spawn(function()
			local waitStart = workspace:GetServerTimeNow()
			while sound and sound.Parent and sound.TimeLength <= 0 and (workspace:GetServerTimeNow() - waitStart) < 8 do
				task.wait(0.1)
			end
			if sound and sound.Parent and sound.TimeLength > 0 then
				onDurationLoaded(sound.TimeLength)
			end
		end)
	end

	self.endedConnection = sound.Ended:Connect(function()
		if self.isTransitioning then return end
		if self.autoNextCallback and self.isPlaying then
			self.isTransitioning = true
			task.spawn(function()
				local success, err = pcall(self.autoNextCallback)
				if not success then
					warn("[PlaybackManager] Kesalahan AutoNext:", err)
					self.isTransitioning = false
				end
			end)
		end
	end)
end

function MusicPlaybackManager:StartProgressBroadcast(remotes)
	if self.progressConnection then self.progressConnection:Disconnect() end

	local progressInterval = self.config.PROGRESS_UPDATE_INTERVAL or 3

	self.progressConnection = RunService.Heartbeat:Connect(function()
		if not self.isPlaying then return end

		local elapsed = self.audioHandler:GetTimePosition()
		local now     = workspace:GetServerTimeNow()
		local wallElapsed = (self.songStartTime > 0) and (now - self.songStartTime) or 0

		if not self.isFadingOut and self.songDuration > 0 then
			local remaining = self.songDuration - elapsed
			if remaining <= PRE_FADE_BUFFER and remaining > 0 then
				self.isFadingOut = true
				self.audioHandler:FadeOut(math.min(remaining, FADE_OUT_DURATION))
			end
		end

		if not self.preloadTriggered and self.songDuration > 0 then
			if elapsed >= self.songDuration * PRELOAD_THRESHOLD then
				self.preloadTriggered = true
				if self.preloadCallback then
					task.spawn(self.preloadCallback)
				end
			end
		end

		if not self.isTransitioning and self.autoNextCallback and self.songStartTime > 0 then
			local songFinished = false

			if wallElapsed > 2.0 and not self.audioHandler:IsPlaying() then
				songFinished = true
			end

			if self.songDuration > 0 and elapsed >= (self.songDuration - 0.25) and wallElapsed > 2.0 then
				songFinished = true
			end

			if self.songDuration > 0 and wallElapsed >= (self.songDuration + 2.0) and not self.audioHandler:IsPlaying() then
				songFinished = true
			elseif wallElapsed >= 600 then

				songFinished = true
			end

			if songFinished then
				self.isTransitioning = true
				task.spawn(function()
					local success, err = pcall(self.autoNextCallback)
					if not success then
						warn("[PlaybackManager] Kesalahan Watchdog AutoNext:", err)
						self.isTransitioning = false
					end
				end)
				return
			end
		end

		if now - self.lastProgressBroadcast < progressInterval then return end
		self.lastProgressBroadcast = now
		self:UpdateProgress(remotes)
	end)
end

function MusicPlaybackManager:StopProgressBroadcast()
	if self.progressConnection then
		self.progressConnection:Disconnect()
		self.progressConnection = nil
	end
end

function MusicPlaybackManager:Play(remotes, songData, uploaderName, isFromPlaylist)

	if self.endedConnection then self.endedConnection:Disconnect(); self.endedConnection = nil end
	self:StopProgressBroadcast()

	local musicData = songData.musicData or songData
	local duration  = songData.Duration or musicData.Duration or self.config.DEFAULT_SONG_DURATION
	if duration <= 0 then return false end

	self.isTransitioning = true

	self.audioHandler:CancelFade()

	self.currentSong      = musicData
	self.currentUploader  = uploaderName or "System"
	self.isPlaying        = true
	self.songDuration     = duration
	self.isPlaylistMode   = isFromPlaylist or false
	self.preloadTriggered = false
	self.isFadingOut      = false

	local success = self.audioHandler:Play(musicData.id, 0)
	if not success then
		self.isTransitioning = false
		self:Stop(remotes)
		return false
	end

	self.songStartTime = workspace:GetServerTimeNow()

	self.isTransitioning = false
	self:ConnectEndedEvent(remotes)
	self:StartProgressBroadcast(remotes)

	self:BroadcastSongUpdate(remotes, musicData, uploaderName, duration)
	return true
end

function MusicPlaybackManager:Stop(remotes)
	if self.endedConnection then self.endedConnection:Disconnect(); self.endedConnection = nil end
	if self.timeLengthConnection then self.timeLengthConnection:Disconnect(); self.timeLengthConnection = nil end
	self:StopProgressBroadcast()
	self.audioHandler:Stop()
	self.currentSong      = nil
	self.currentUploader  = nil
	self.isPlaying        = false
	self.songStartTime    = 0
	self.songDuration     = 0
	self.isPlaylistMode   = false
	self.autoNextCallback = nil
	self.preloadCallback  = nil
	self.preloadTriggered = false
	self.isFadingOut      = false
	self.isTransitioning  = false
	self:BroadcastStopMusic(remotes)
end

function MusicPlaybackManager:StopWithFade(remotes, fadeDuration)
	if self.endedConnection then self.endedConnection:Disconnect(); self.endedConnection = nil end
	if self.timeLengthConnection then self.timeLengthConnection:Disconnect(); self.timeLengthConnection = nil end
	self:StopProgressBroadcast()
	self.audioHandler:StopWithFade(fadeDuration or FADE_OUT_DURATION, function()
		self.currentSong      = nil
		self.currentUploader  = nil
		self.isPlaying        = false
		self.songStartTime    = 0
		self.songDuration     = 0
		self.isPlaylistMode   = false
		self.autoNextCallback = nil
		self.preloadCallback  = nil
		self.preloadTriggered = false
		self.isFadingOut      = false
		self.isTransitioning  = false
		self:BroadcastStopMusic(remotes)
	end)
end

function MusicPlaybackManager:BroadcastSongUpdate(remotes, musicData, uploaderName, duration)
	pcall(function()
		remotes.MusicBroadcast:FireAllClients("SongUpdate", {
			SoundId         = musicData.id,
			Title           = musicData.judul or "Unknown",
			Thumbnail       = musicData.sampul,
			PlaylistName    = musicData.playlistName,
			AddedBy         = uploaderName or "Unknown",
			Duration        = duration,
			IsPlaying       = true,
			ServerStartTime = self.songStartTime,
			ServerTimeNow   = workspace:GetServerTimeNow(),
		})
	end)
end

function MusicPlaybackManager:BroadcastStopMusic(remotes)
	pcall(function()
		remotes.MusicBroadcast:FireAllClients("StopMusic", {})
	end)
end

function MusicPlaybackManager:UpdateProgress(remotes)
	if not self.isPlaying then return end
	local elapsed = self.audioHandler:GetTimePosition()
	pcall(function()
		remotes.MusicBroadcast:FireAllClients("Progress", {
			Current         = elapsed,
			Duration        = self.songDuration,
			IsPlaying       = true,
			ServerStartTime = self.songStartTime,
			ServerTimeNow   = workspace:GetServerTimeNow(),
		})
	end)
end

function MusicPlaybackManager:SyncToPlayer(remotes, player)
	if not self.isPlaying or not self.currentSong then return end
	local sound = self.audioHandler:GetSound()
	if sound and sound.TimeLength > 0 and self.songDuration ~= sound.TimeLength then
		self.songDuration = sound.TimeLength
		if self.currentSong then self.currentSong.Duration = sound.TimeLength end
	end
	local elapsed = self.audioHandler:GetTimePosition()
	pcall(function()
		remotes.MusicUpdate:FireClient(player, "SyncMusic", {
			SoundId         = self.currentSong.id,
			Title           = self.currentSong.judul,
			Thumbnail       = self.currentSong.sampul,
			PlaylistName    = self.currentSong.playlistName,
			AddedBy         = self.currentUploader,
			TimePosition    = elapsed,
			Duration        = self.songDuration,
			IsPlaying       = self.isPlaying,
			ServerStartTime = self.songStartTime,
			ServerTimeNow   = workspace:GetServerTimeNow(),
		})
	end)
end

function MusicPlaybackManager:Reset(remotes)
	self:Stop(remotes)
end

function MusicPlaybackManager:Cleanup()
	if self.endedConnection then self.endedConnection:Disconnect(); self.endedConnection = nil end
	if self.timeLengthConnection then self.timeLengthConnection:Disconnect(); self.timeLengthConnection = nil end
	self:StopProgressBroadcast()
	self.audioHandler:Cleanup()
	self.autoNextCallback = nil
	self.preloadCallback  = nil
end

return MusicPlaybackManager
