-- ====================================
-- SERVER MUSIC AUDIO HANDLER (2D MONO/BALANCED STEREO + PUNCHY BASS)
-- Place in: ServerScriptService > MusicServer(Folder) > MusicSystem(Script) > ServerMusicAudioHandler(ModuleScript)
-- ====================================
-- Fitur:
--   ✅ 2D Global Audio di SoundService (100% seimbang di headset & speaker, bebas putaran kamera)
--   ✅ Punchy Bass Boost: LowGain +4.5 dB (bass lebih nendang & berbobot, enak di headset & speaker)
--   ✅ Clarity EQ: MidGain -0.4 dB (vokal bersih), HighGain +1.2 dB (treble renyah & jernih)
--   ✅ Single Sound Source (Murni, tanpa gema/phase cancellation)
--   ✅ Smooth Fade In & Fade Out menggunakan TweenService
--   ✅ 100% Kompatibel dengan kontrol volume, mute, seek, dan beat visualizer

local TweenService = game:GetService("TweenService")
local SoundService = game:GetService("SoundService")

local ServerMusicAudioHandler = {}
ServerMusicAudioHandler.__index = ServerMusicAudioHandler

local CONFIG = {
	Audio = {
		DefaultVolume   = 1.0,  -- Standar 1.0 murni (mencegah digital clipping/distorsi)
		FadeInDuration  = 1.2,  -- Transisi fade-in lebih mulus (1.2 detik)
		FadeOutDuration = 1.0,  -- Transisi fade-out lebih halus (1.0 detik)
		-- EQ: Bass Padat & Vokal Lebih Maju
		EQ_LowGain      = 3.6,   -- Bass berbobot (+3.8 dB): padat dan punchy
		EQ_MidGain      = 1.0,   -- Vokal dinaikkan (+1.2 dB): artikulasi lirik & vokal lebih jelas dan maju
		EQ_HighGain     = 2.0,   -- Treble jernih & renyah (+2.4 dB)
		-- Nuansa Akustik Ruangan Halus (Indoor Room Ambience)
		Reverb_DecayTime = 1.05,  -- Durasi pantulan ruang pas (1.05 detik, tidak sepanjang 1.2s sebelumnya)
		Reverb_Density   = 0.72,  -- Kepadatan pantulan akustik ruangan
		Reverb_Diffusion = 0.8,   -- Penyebaran pantulan dinding yang halus
		Reverb_DryLevel  = 0,     -- Suara asli lagu tetap 100% jernih & tajam
		Reverb_WetLevel  = -14.5, -- Dinaikkan sedikit (-14.5 dB): pas di antara -16.5 dB dan batas -13 dB sebelumnya
	},
}

function ServerMusicAudioHandler.new()
	local self = setmetatable({}, ServerMusicAudioHandler)
	self.serverSound      = nil
	self.musicGroup       = nil
	self.currentSoundId   = nil
	self.isPlaying        = false
	self.currentFadeTween = nil

	-- Bersihkan node eksperimental dan part speaker di workspace
	self:CleanupUnusedNodes()

	self:CreateSoundGroup()
	self:CreateServerSound()

	return self
end

-- ====================================
-- CLEANUP
-- ====================================

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

	-- Hapus part speaker dari workspace agar audio murni 2D seimbang
	local oldSpeakers = { "MusicSpeaker", "DefaultMusicSpeaker" }
	for _, name in ipairs(oldSpeakers) do
		local sp = workspace:FindFirstChild(name)
		if sp then
			pcall(function() sp:Destroy() end)
		end
	end
end

-- ====================================
-- SOUND SETUP (2D SOUNDSERVICE)
-- ====================================

function ServerMusicAudioHandler:CreateSoundGroup()
	local musicGroup = SoundService:FindFirstChild("MusicGroup")
	if not musicGroup then
		musicGroup        = Instance.new("SoundGroup")
		musicGroup.Name   = "MusicGroup"
		musicGroup.Parent = SoundService
		musicGroup.Volume = 1
	end
	self.musicGroup = musicGroup
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

	-- Hapus jika sound ada di Workspace
	local straySound = workspace:FindFirstChild("ServerMusicSound", true)
	if straySound and straySound:IsA("Sound") then
		pcall(function() straySound:Destroy() end)
	end

	local existing = SoundService:FindFirstChild("ServerMusicSound")
	if existing and existing:IsA("Sound") then
		self.serverSound = existing
	else
		local sound = Instance.new("Sound")
		sound.Name       = "ServerMusicSound"
		sound.Parent     = SoundService -- 2D Global Audio (bebas dari rotasi kamera)
		sound.Volume     = 0
		sound.Looped     = false
		self.serverSound = sound
	end

	self.serverSound.SoundGroup = self.musicGroup

	-- Pasang Equalizer
	local eq = self.serverSound:FindFirstChild("FiestaEqualizer")
	if not eq or not eq:IsA("EqualizerSoundEffect") then
		eq = Instance.new("EqualizerSoundEffect")
		eq.Name   = "FiestaEqualizer"
		eq.Parent = self.serverSound
	end
	eq.LowGain  = CONFIG.Audio.EQ_LowGain
	eq.MidGain  = CONFIG.Audio.EQ_MidGain
	eq.HighGain = CONFIG.Audio.EQ_HighGain

	-- Pasang Reverb: Nuansa Akustik Ruangan (Indoor Room / Venue Ambience)
	local reverb = self.serverSound:FindFirstChild("FiestaReverb")
	if not reverb or not reverb:IsA("ReverbSoundEffect") then
		reverb = Instance.new("ReverbSoundEffect")
		reverb.Name   = "FiestaReverb"
		reverb.Parent = self.serverSound
	end
	reverb.DecayTime = CONFIG.Audio.Reverb_DecayTime
	reverb.Density   = CONFIG.Audio.Reverb_Density
	reverb.Diffusion = CONFIG.Audio.Reverb_Diffusion
	reverb.DryLevel  = CONFIG.Audio.Reverb_DryLevel
	reverb.WetLevel  = CONFIG.Audio.Reverb_WetLevel

	-- Hapus Compressor jika ada agar dinamika kick bass & musik bebas bergerak lepas
	local comp = self.serverSound:FindFirstChild("FiestaCompressor")
	if comp then
		pcall(function() comp:Destroy() end)
	end

	return self.serverSound
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
		TweenInfo.new(dur, Enum.EasingStyle.Sine, Enum.EasingDirection.Out),
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

-- ====================================
-- PLAYBACK
-- ====================================

function ServerMusicAudioHandler:Play(soundId, timePosition)
	if not self.serverSound or self.serverSound.Parent ~= SoundService then
		self:CreateServerSound()
	end
	self:CancelFade()

	if self.serverSound.IsPlaying then
		pcall(function() self.serverSound:Stop() end)
	end

	self.serverSound.Volume       = 0
	self.serverSound.SoundId      = "rbxassetid://" .. tostring(soundId)
	self.serverSound.TimePosition = timePosition or 0

	local eq = self.serverSound:FindFirstChild("FiestaEqualizer")
	if eq and eq:IsA("EqualizerSoundEffect") then
		eq.LowGain  = CONFIG.Audio.EQ_LowGain
		eq.MidGain  = CONFIG.Audio.EQ_MidGain
		eq.HighGain = CONFIG.Audio.EQ_HighGain
	end

	local reverb = self.serverSound:FindFirstChild("FiestaReverb")
	if reverb and reverb:IsA("ReverbSoundEffect") then
		reverb.DecayTime = CONFIG.Audio.Reverb_DecayTime
		reverb.Density   = CONFIG.Audio.Reverb_Density
		reverb.Diffusion = CONFIG.Audio.Reverb_Diffusion
		reverb.DryLevel  = CONFIG.Audio.Reverb_DryLevel
		reverb.WetLevel  = CONFIG.Audio.Reverb_WetLevel
	end

	local comp = self.serverSound:FindFirstChild("FiestaCompressor")
	if comp then
		pcall(function() comp:Destroy() end)
	end

	local success = pcall(function()
		self.serverSound:Play()
	end)

	if success then
		self.currentSoundId = soundId
		self.isPlaying      = true
		return true
	else
		warn("[ServerAudio] Failed to play sound:", soundId)
		return false
	end
end

function ServerMusicAudioHandler:PlayWithFade(soundId, timePosition, fadeDuration)
	local success = self:Play(soundId, timePosition)
	if success then
		self:FadeIn(fadeDuration or CONFIG.Audio.FadeInDuration)
	end
	return success
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

-- ====================================
-- STATUS & ACCESSORS
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
	self:CleanupUnusedNodes()
end

return ServerMusicAudioHandler
