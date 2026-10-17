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

function MusicPlaybackManager:ConnectEndedEvent()
	if self.endedConnection then
		self.endedConnection:Disconnect()
		self.endedConnection = nil
	end
	local sound = self.audioHandler:GetSound()
	if not sound then return end

	self.endedConnection = sound.Ended:Connect(function()
		if self.isTransitioning then return end
		if self.autoNextCallback and self.isPlaying then
			task.spawn(function()
				local success, err = pcall(self.autoNextCallback)
				if not success then warn("[PlaybackManager] Kesalahan AutoNext:", err) end
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

		if not self.isTransitioning and self.songDuration > 0 and self.autoNextCallback then
			local wallElapsed = (self.songStartTime > 0) and (now - self.songStartTime) or 0
			if (elapsed >= self.songDuration + 0.5) or (wallElapsed >= self.songDuration + 2) then
				self.isTransitioning = true
				task.spawn(function()
					local success, err = pcall(self.autoNextCallback)
					if not success then warn("[PlaybackManager] Kesalahan Watchdog AutoNext:", err) end
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

	if self.audioHandler:IsPlaying() and not self.isFadingOut then
		self.audioHandler:FadeOut(FADE_OUT_DURATION)
		task.wait(FADE_OUT_DURATION + 0.02)
	elseif self.isFadingOut then
		task.wait(0.05)
	end

	self.currentSong      = musicData
	self.currentUploader  = uploaderName or "System"
	self.isPlaying        = true
	self.songDuration     = duration
	self.isPlaylistMode   = isFromPlaylist or false
	self.preloadTriggered = false
	self.isFadingOut      = false

	local success = self.audioHandler:PlayWithFade(musicData.id, 0, FADE_IN_DURATION)
	if not success then
		self.isTransitioning = false
		self:Stop(remotes)
		return false
	end

	self.songStartTime = workspace:GetServerTimeNow()

	self.isTransitioning = false
	self:ConnectEndedEvent()
	self:StartProgressBroadcast(remotes)

	self:BroadcastSongUpdate(remotes, musicData, uploaderName, duration)
	return true
end

function MusicPlaybackManager:Stop(remotes)
	if self.endedConnection then self.endedConnection:Disconnect(); self.endedConnection = nil end
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
	self:StopProgressBroadcast()
	self.audioHandler:Cleanup()
	self.autoNextCallback = nil
	self.preloadCallback  = nil
end

return MusicPlaybackManager
