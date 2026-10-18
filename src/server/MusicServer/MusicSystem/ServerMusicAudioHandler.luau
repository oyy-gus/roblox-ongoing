local TweenService = game:GetService("TweenService")
local SoundService = game:GetService("SoundService")

local ServerMusicAudioHandler = {}
ServerMusicAudioHandler.__index = ServerMusicAudioHandler

local CONFIG = {
	Audio = {
		DefaultVolume   = 0.5,
		FadeInDuration  = 1.2,
		FadeOutDuration = 1.0,

		EQ_LowGain      = 10,
		EQ_MidGain      = -10,
		EQ_HighGain     = 10,

		Reverb_DecayTime = 1.5,
		Reverb_Density   = 1,
		Reverb_Diffusion = 1,
		Reverb_DryLevel  = 0,
		Reverb_WetLevel  = -20,
	},
}

function ServerMusicAudioHandler.new()
	local self = setmetatable({}, ServerMusicAudioHandler)
	self.serverSound      = nil
	self.musicGroup       = nil
	self.currentSoundId   = nil
	self.isPlaying        = false
	self.currentFadeTween = nil

	self:CleanupUnusedNodes()

	self:CreateSoundGroup()
	self:CreateServerSound()

	return self
end

function ServerMusicAudioHandler:CleanupUnusedNodes()
	local toDestroy = {
		"ServerAudioPlayer",
		"FiestaAudioEqualizer",
		"ServerAudioFader",
		"ClientMusicFader",
		"ClientAudioOutput",
	}
	for _, name in ipairs(toDestroy) do
		local node = SoundService:FindFirstChild(name)
		if node then
			pcall(function() node:Destroy() end)
		end
	end

	local oldSpeakers = { "MusicSpeaker", "DefaultMusicSpeaker" }
	for _, name in ipairs(oldSpeakers) do
		local sp = workspace:FindFirstChild(name)
		if sp then
			pcall(function() sp:Destroy() end)
		end
	end
end

function ServerMusicAudioHandler:CreateSoundGroup()
	local musicGroup = SoundService:FindFirstChild("mainEffects") or SoundService:FindFirstChild("MusicGroup")
	if not musicGroup then
		musicGroup        = Instance.new("SoundGroup")
		musicGroup.Name   = "mainEffects"
		musicGroup.Parent = SoundService
		musicGroup.Volume = 0
	else
		musicGroup.Name   = "mainEffects"
		musicGroup.Volume = 0
	end
	self.musicGroup = musicGroup

	local eq = musicGroup:FindFirstChild("AudioEqualizer") or musicGroup:FindFirstChild("FiestaEqualizer") or musicGroup:FindFirstChildWhichIsA("EqualizerSoundEffect")
	if not eq then
		eq = Instance.new("EqualizerSoundEffect")
		eq.Name   = "AudioEqualizer"
		eq.Parent = musicGroup
	else
		eq.Name   = "AudioEqualizer"
	end
	eq.LowGain  = CONFIG.Audio.EQ_LowGain
	eq.MidGain  = CONFIG.Audio.EQ_MidGain
	eq.HighGain = CONFIG.Audio.EQ_HighGain

	local reverb = musicGroup:FindFirstChild("ReverbSoundEffect") or musicGroup:FindFirstChild("FiestaReverb") or musicGroup:FindFirstChildWhichIsA("ReverbSoundEffect")
	if not reverb then
		reverb = Instance.new("ReverbSoundEffect")
		reverb.Name   = "ReverbSoundEffect"
		reverb.Parent = musicGroup
	else
		reverb.Name   = "ReverbSoundEffect"
	end
	reverb.DecayTime = CONFIG.Audio.Reverb_DecayTime
	reverb.Density   = CONFIG.Audio.Reverb_Density
	reverb.Diffusion = CONFIG.Audio.Reverb_Diffusion
	reverb.DryLevel  = CONFIG.Audio.Reverb_DryLevel
	reverb.WetLevel  = CONFIG.Audio.Reverb_WetLevel

	return musicGroup
end

function ServerMusicAudioHandler:CreateServerSound()
	if self.serverSound and self.serverSound.Parent == SoundService then
		return self.serverSound
	end
	if self.serverSound then
		pcall(function() self.serverSound:Stop(); self.serverSound:Destroy() end)
	end
	if not self.musicGroup then self:CreateSoundGroup() end

	local straySound = workspace:FindFirstChild("ServerMusicSound", true)
	if straySound and straySound:IsA("Sound") then
		pcall(function() straySound:Destroy() end)
	end

	local existing = SoundService:FindFirstChild("ServerMusicSound")
	if existing and existing:IsA("Sound") then
		self.serverSound = existing
		self.serverSound.Looped = false
	else
		local sound = Instance.new("Sound")
		sound.Name       = "ServerMusicSound"
		sound.Parent     = SoundService
		sound.Volume     = 1
		sound.Looped     = false
		self.serverSound = sound
	end

	self.serverSound.SoundGroup = self.musicGroup

	local legacyEq = self.serverSound:FindFirstChild("FiestaEqualizer") or self.serverSound:FindFirstChildWhichIsA("EqualizerSoundEffect")
	if legacyEq then pcall(function() legacyEq:Destroy() end) end

	local legacyReverb = self.serverSound:FindFirstChild("FiestaReverb") or self.serverSound:FindFirstChildWhichIsA("ReverbSoundEffect")
	if legacyReverb then pcall(function() legacyReverb:Destroy() end) end

	local comp = self.serverSound:FindFirstChild("FiestaCompressor")
	if comp then
		pcall(function() comp:Destroy() end)
	end

	return self.serverSound
end

function ServerMusicAudioHandler:CancelFade()
	if self.currentFadeTween then
		self.currentFadeTween:Cancel()
		self.currentFadeTween = nil
	end
end

function ServerMusicAudioHandler:FadeIn(duration, targetVolume)
	self:CancelFade()
	if not self.serverSound then return nil end

	local dur    = duration or CONFIG.Audio.FadeInDuration
	local target = targetVolume or CONFIG.Audio.DefaultVolume

	self.serverSound.Volume = 0
	local tween = TweenService:Create(
		self.serverSound,
		TweenInfo.new(dur, Enum.EasingStyle.Sine, Enum.EasingDirection.Out),
		{ Volume = target }
	)
	self.currentFadeTween = tween
	tween:Play()
	return tween
end

function ServerMusicAudioHandler:FadeOut(duration, callback)
	self:CancelFade()
	if not self.serverSound or self.serverSound.Volume <= 0.001 then
		if callback then callback() end
		return nil
	end

	local dur = duration or CONFIG.Audio.FadeOutDuration
	local tween = TweenService:Create(
		self.serverSound,
		TweenInfo.new(dur, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut),
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

function ServerMusicAudioHandler:Play(soundId, timePosition)
	if not self.serverSound or self.serverSound.Parent ~= SoundService then
		self:CreateServerSound()
	end
	self:CancelFade()

	if self.serverSound.IsPlaying then
		pcall(function() self.serverSound:Stop() end)
	end

	self.serverSound.Looped       = false
	self.serverSound.Volume       = 1
	self.serverSound.SoundId      = "rbxassetid://" .. tostring(soundId)
	self.serverSound.TimePosition = timePosition or 0
	self.serverSound.SoundGroup   = self.musicGroup

	if self.musicGroup then
		local eq = self.musicGroup:FindFirstChild("AudioEqualizer") or self.musicGroup:FindFirstChild("FiestaEqualizer") or self.musicGroup:FindFirstChildWhichIsA("EqualizerSoundEffect")
		if eq then
			eq.LowGain  = CONFIG.Audio.EQ_LowGain
			eq.MidGain  = CONFIG.Audio.EQ_MidGain
			eq.HighGain = CONFIG.Audio.EQ_HighGain
		end

		local reverb = self.musicGroup:FindFirstChild("ReverbSoundEffect") or self.musicGroup:FindFirstChild("FiestaReverb") or self.musicGroup:FindFirstChildWhichIsA("ReverbSoundEffect")
		if reverb then
			reverb.DecayTime = CONFIG.Audio.Reverb_DecayTime
			reverb.Density   = CONFIG.Audio.Reverb_Density
			reverb.Diffusion = CONFIG.Audio.Reverb_Diffusion
			reverb.DryLevel  = CONFIG.Audio.Reverb_DryLevel
			reverb.WetLevel  = CONFIG.Audio.Reverb_WetLevel
		end
	end

	local comp = self.serverSound:FindFirstChild("FiestaCompressor")
	if comp then
		pcall(function() comp:Destroy() end)
	end

	local loadStart = os.clock()
	while not self.serverSound.IsLoaded and (os.clock() - loadStart) < 4 do
		task.wait(0.03)
	end

	local success = pcall(function()
		self.serverSound:Play()
	end)

	if success then
		self.currentSoundId = soundId
		self.isPlaying      = true
		return true
	else
		warn("[ServerAudio] Gagal memutar suara:", soundId)
		return false
	end
end

function ServerMusicAudioHandler:PlayWithFade(soundId, timePosition, fadeDuration)
	return self:Play(soundId, timePosition)
end

function ServerMusicAudioHandler:StopWithFade(fadeDuration, callback)
	if not self.isPlaying or not self.serverSound then
		self.isPlaying      = false
		self.currentSoundId = nil
		if callback then callback() end
		return
	end

	self:FadeOut(fadeDuration or CONFIG.Audio.FadeOutDuration, function()
		self:Stop()
		if callback then callback() end
	end)
end

function ServerMusicAudioHandler:Stop()
	self:CancelFade()
	if self.serverSound then
		pcall(function() self.serverSound:Stop() end)
		self.serverSound.Volume = 0
	end
	self.isPlaying      = false
	self.currentSoundId = nil
end

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

function ServerMusicAudioHandler:Cleanup()
	self:CancelFade()
	if self.serverSound then
		pcall(function() self.serverSound:Stop(); self.serverSound:Destroy() end)
		self.serverSound = nil
	end
	self:CleanupUnusedNodes()
end

return ServerMusicAudioHandler
