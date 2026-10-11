-- ====================================
-- SERVER MUSIC AUDIO HANDLER (IMPROVED)
-- Place in: ServerScriptService > MusicServer(Folder) > MusicSystem(Script) > ServerMusicAudioHandler(ModuleScript)
-- ====================================
-- Changes:
--   ✅ Added FadeIn / FadeOut / PlayWithFade / StopWithFade using TweenService
--   ✅ Fade-out sebelum stop, fade-in setelah play
--   ✅ CancelFade() untuk membatalkan tween yang sedang berjalan
--   ✅ Volume dimulai dari 0, dikendalikan oleh server fade (client hanya kontrol SoundGroup)

local TweenService = game:GetService("TweenService")

local ServerMusicAudioHandler = {}
ServerMusicAudioHandler.__index = ServerMusicAudioHandler

local CONFIG = {
	Audio = {
		DefaultVolume  = 1,
		FadeInDuration  = 0.8,
		FadeOutDuration = 0.6,
	},
}

function ServerMusicAudioHandler.new()
	local self = setmetatable({}, ServerMusicAudioHandler)
	self.serverSound    = nil
	self.soundContainer = nil
	self.musicGroup     = nil
	self.currentSoundId = nil
	self.isPlaying      = false
	self.currentFadeTween = nil
	self:CreateSoundContainer()
	self:CreateServerSound()
	return self
end

-- ====================================
-- SETUP
-- ====================================

function ServerMusicAudioHandler:CreateSoundContainer()
	local soundService = game:GetService("SoundService")
	local musicGroup = soundService:FindFirstChild("MusicGroup")
	if not musicGroup then
		musicGroup        = Instance.new("SoundGroup")
		musicGroup.Name   = "MusicGroup"
		musicGroup.Parent = soundService
		musicGroup.Volume = 1
	end
	self.soundContainer = soundService
	self.musicGroup     = musicGroup
	return soundService
end

function ServerMusicAudioHandler:CreateServerSound()
	if self.serverSound and self.serverSound.Parent then return self.serverSound end
	if self.serverSound then
		pcall(function() self.serverSound:Stop(); self.serverSound:Destroy() end)
	end
	if not self.soundContainer then self:CreateSoundContainer() end
	local existing = self.soundContainer:FindFirstChild("ServerMusicSound")
	if existing and existing:IsA("Sound") then
		self.serverSound = existing
		return existing
	end
	local sound = Instance.new("Sound")
	sound.Name       = "ServerMusicSound"
	sound.Parent     = self.soundContainer
	sound.Volume     = 0   -- Dimulai dari 0, fade-in akan menaikkan
	sound.Looped     = false
	sound.SoundGroup = self.musicGroup
	self.serverSound = sound
	return sound
end

-- ====================================
-- FADE SYSTEM
-- ====================================

function ServerMusicAudioHandler:CancelFade()
	if self.currentFadeTween then
		self.currentFadeTween:Cancel()
		self.currentFadeTween = nil
	end
end

--- Fade volume dari 0 ke targetVolume dalam duration detik
function ServerMusicAudioHandler:FadeIn(duration, targetVolume)
	self:CancelFade()
	if not self.serverSound then return nil end
	local dur    = duration or CONFIG.Audio.FadeInDuration
	local target = targetVolume or CONFIG.Audio.DefaultVolume
	self.serverSound.Volume = 0
	local tween = TweenService:Create(
		self.serverSound,
		TweenInfo.new(dur, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{ Volume = target }
	)
	self.currentFadeTween = tween
	tween:Play()
	return tween
end

--- Fade volume ke 0 dalam duration detik, panggil callback setelah selesai
function ServerMusicAudioHandler:FadeOut(duration, callback)
	self:CancelFade()
	if not self.serverSound or self.serverSound.Volume <= 0.001 then
		if callback then callback() end
		return nil
	end
	local dur = duration or CONFIG.Audio.FadeOutDuration
	local tween = TweenService:Create(
		self.serverSound,
		TweenInfo.new(dur, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
		{ Volume = 0 }
	)
	self.currentFadeTween = tween
	tween:Play()
	if callback then
		tween.Completed:Connect(function()
			callback()
		end)
	end
	return tween
end

-- ====================================
-- PLAYBACK
-- ====================================

--- Play tanpa fade (internal use). Volume di-set 0.
function ServerMusicAudioHandler:Play(soundId, timePosition)
	if not self.serverSound or not self.serverSound.Parent then self:CreateServerSound() end
	self:CancelFade()
	if self.serverSound.IsPlaying then self.serverSound:Stop() end
	self.serverSound.Volume       = 0
	self.serverSound.SoundId      = "rbxassetid://" .. soundId
	self.serverSound.TimePosition = timePosition or 0
	local success = pcall(function() self.serverSound:Play() end)
	if success then
		self.currentSoundId = soundId
		self.isPlaying      = true
		return true
	else
		warn("[ServerAudio] Failed to play:", soundId)
		return false
	end
end

--- Play lagu baru dengan fade-in
function ServerMusicAudioHandler:PlayWithFade(soundId, timePosition, fadeDuration)
	local success = self:Play(soundId, timePosition)
	if success then
		self:FadeIn(fadeDuration or CONFIG.Audio.FadeInDuration)
	end
	return success
end

--- Stop dengan fade-out terlebih dahulu
function ServerMusicAudioHandler:StopWithFade(fadeDuration, callback)
	if not self.serverSound or not self.isPlaying then
		self.isPlaying      = false
		self.currentSoundId = nil
		if callback then callback() end
		return
	end
	self:FadeOut(fadeDuration or CONFIG.Audio.FadeOutDuration, function()
		pcall(function() self.serverSound:Stop() end)
		self.isPlaying      = false
		self.currentSoundId = nil
		if callback then callback() end
	end)
end

--- Stop langsung tanpa fade
function ServerMusicAudioHandler:Stop()
	self:CancelFade()
	if not self.serverSound then return end
	pcall(function() self.serverSound:Stop() end)
	self.serverSound.Volume = 0
	self.isPlaying      = false
	self.currentSoundId = nil
end

-- ====================================
-- STATUS
-- ====================================

function ServerMusicAudioHandler:IsPlaying()
	return self.isPlaying and self.serverSound and self.serverSound.IsPlaying
end

function ServerMusicAudioHandler:GetTimePosition()
	if not self.serverSound then return 0 end
	return self.serverSound.TimePosition
end

function ServerMusicAudioHandler:GetTimeLength()
	if not self.serverSound then return 0 end
	return self.serverSound.TimeLength
end

function ServerMusicAudioHandler:GetSound()
	return self.serverSound
end

function ServerMusicAudioHandler:GetVolume()
	if not self.serverSound then return 0 end
	return self.serverSound.Volume
end

-- ====================================
-- CLEANUP
-- ====================================

function ServerMusicAudioHandler:Cleanup()
	self:CancelFade()
	if self.serverSound then
		pcall(function() self.serverSound:Stop(); self.serverSound:Destroy() end)
		self.serverSound = nil
	end
end

return ServerMusicAudioHandler
