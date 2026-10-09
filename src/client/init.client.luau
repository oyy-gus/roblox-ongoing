-- MusicClient: Client-side music player + dangdut GUI
-- Receives sync from server, corrects position with latency compensation,
-- renders a KERE (budget) dangdut-themed GUI.

local Players            = game:GetService("Players")
local ReplicatedStorage  = game:GetService("ReplicatedStorage")
local RunService         = game:GetService("RunService")
local TweenService       = game:GetService("TweenService")
local SoundService       = game:GetService("SoundService")

local LocalPlayer        = Players.LocalPlayer
local PlayerGui          = LocalPlayer:WaitForChild("PlayerGui")

-- ─── Wait for Remotes ────────────────────────────────────────────────────────
local Remotes      = ReplicatedStorage:WaitForChild("MusicRemotes", 15)
local RE_SyncState = Remotes:WaitForChild("SyncState")
local RE_NextSong  = Remotes:WaitForChild("NextSong")
local RE_PrevSong  = Remotes:WaitForChild("PrevSong")
local RF_GetState  = Remotes:WaitForChild("GetState")
local RF_GetPlaylist = Remotes:WaitForChild("GetPlaylist")

-- ─── Sound Setup ─────────────────────────────────────────────────────────────
-- Sound lives in SoundService so it's unaffected by camera/position
local sound = Instance.new("Sound")
sound.Name      = "MusicSync"
sound.Volume    = 0.6
sound.Looped    = false
sound.RollOffMaxDistance = 0  -- global, not 3D
sound.Parent    = SoundService

-- ─── State ───────────────────────────────────────────────────────────────────
local currentSoundId = ""
local currentIndex   = 0
local totalSongs     = 0
local currentTitle   = ""
local isPlaying      = false
local playlist       = {}

-- Track server's clock offset for latency compensation
local clockOffset    = 0  -- serverClock - os.clock() at sync moment

-- ─── Apply Sync State ────────────────────────────────────────────────────────
local function applySync(state)
	if not state or not state.loaded then return end

	-- Latency compensation: estimate how many seconds ago the server sent this
	local localNow    = os.clock()
	clockOffset       = state.serverClock - localNow
	-- True position = state.position + (how long ago server sent it)
	-- Since we don't know exact send time, use: position at serverClock
	-- The corrected position = state.position + (localNow - state.serverClock)
	-- = state.position - clockOffset
	local corrected   = state.position + (localNow - state.serverClock)
	corrected         = math.max(0, corrected)

	currentIndex  = state.index
	totalSongs    = state.total
	currentTitle  = state.title
	isPlaying     = state.isPlaying

	-- Load new sound if needed
	if state.soundId ~= currentSoundId then
		currentSoundId = state.soundId
		sound:Stop()
		sound.SoundId = "rbxassetid://" .. state.soundId
		sound:Play()

		-- Wait for sound to load, then seek
		local function seekAfterLoad()
			local waited = 0
			while not sound.IsLoaded and waited < 5 do
				task.wait(0.05)
				waited += 0.05
			end
			-- Recalculate position after load delay
			local nowAfterLoad = os.clock()
			local finalPos = state.position + (nowAfterLoad - state.serverClock)
			finalPos = math.max(0, finalPos)
			if finalPos < sound.TimeLength then
				sound.TimePosition = finalPos
			end
		end
		task.spawn(seekAfterLoad)
	else
		-- Same song, just seek
		if math.abs(sound.TimePosition - corrected) > 0.3 then
			sound.TimePosition = corrected
		end
	end

	if isPlaying and not sound.IsPlaying then
		sound:Play()
	elseif not isPlaying and sound.IsPlaying then
		sound:Pause()
	end
end

-- ─── GUI Construction ────────────────────────────────────────────────────────
-- DANGDUT KERE THEME: pink/gold/neon, flashy labels, bling bling 🎶

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name           = "DangdutMusicPlayer"
ScreenGui.ResetOnSpawn   = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.Parent         = PlayerGui

-- ── Main Frame ───────────────────────────────────────────────────────────────
local MainFrame = Instance.new("Frame")
MainFrame.Name            = "MainFrame"
MainFrame.Size            = UDim2.new(0, 340, 0, 220)
MainFrame.Position        = UDim2.new(0.5, -170, 1, -240)
MainFrame.BackgroundColor3 = Color3.fromRGB(15, 5, 25)
MainFrame.BorderSizePixel = 0
MainFrame.Parent          = ScreenGui

-- Gradient background
local BG_Grad = Instance.new("UIGradient")
BG_Grad.Color = ColorSequence.new({
	ColorSequenceKeypoint.new(0, Color3.fromRGB(30, 0, 50)),
	ColorSequenceKeypoint.new(0.5, Color3.fromRGB(10, 0, 30)),
	ColorSequenceKeypoint.new(1, Color3.fromRGB(50, 0, 30)),
})
BG_Grad.Rotation = 135
BG_Grad.Parent = MainFrame

-- Gold border stroke
local Stroke = Instance.new("UIStroke")
Stroke.Color     = Color3.fromRGB(255, 200, 0)
Stroke.Thickness = 2.5
Stroke.Parent    = MainFrame

-- Rounded corners
local Corner = Instance.new("UICorner")
Corner.CornerRadius = UDim.new(0, 10)
Corner.Parent       = MainFrame

-- ── Header ───────────────────────────────────────────────────────────────────
local Header = Instance.new("Frame")
Header.Name              = "Header"
Header.Size              = UDim2.new(1, 0, 0, 36)
Header.Position          = UDim2.new(0, 0, 0, 0)
Header.BackgroundColor3  = Color3.fromRGB(255, 180, 0)
Header.BorderSizePixel   = 0
Header.ZIndex            = 2
Header.Parent            = MainFrame

local HeaderCorner = Instance.new("UICorner")
HeaderCorner.CornerRadius = UDim.new(0, 10)
HeaderCorner.Parent       = Header

-- Bottom fix for header rounded corner
local HeaderFix = Instance.new("Frame")
HeaderFix.Name             = "Fix"
HeaderFix.Size             = UDim2.new(1, 0, 0, 10)
HeaderFix.Position         = UDim2.new(0, 0, 1, -10)
HeaderFix.BackgroundColor3 = Color3.fromRGB(255, 180, 0)
HeaderFix.BorderSizePixel  = 0
HeaderFix.ZIndex           = 2
HeaderFix.Parent           = Header

local HeaderGrad = Instance.new("UIGradient")
HeaderGrad.Color = ColorSequence.new({
	ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 200, 0)),
	ColorSequenceKeypoint.new(1, Color3.fromRGB(220, 100, 0)),
})
HeaderGrad.Rotation = 90
HeaderGrad.Parent   = Header

local HeaderLabel = Instance.new("TextLabel")
HeaderLabel.Name             = "Title"
HeaderLabel.Size             = UDim2.new(1, 0, 1, 0)
HeaderLabel.BackgroundTransparency = 1
HeaderLabel.Text             = "🎶 DANGDUT PLAYER 🎶"
HeaderLabel.TextColor3       = Color3.fromRGB(15, 5, 25)
HeaderLabel.Font             = Enum.Font.GothamBold
HeaderLabel.TextSize         = 15
HeaderLabel.ZIndex           = 3
HeaderLabel.Parent           = Header

-- ── Disco / Equalizer Bar (decorative) ───────────────────────────────────────
local EQBar = Instance.new("Frame")
EQBar.Name             = "EQBar"
EQBar.Size             = UDim2.new(1, -20, 0, 18)
EQBar.Position         = UDim2.new(0, 10, 0, 42)
EQBar.BackgroundTransparency = 1
EQBar.Parent           = MainFrame

local EQ_NUM_BARS = 20
local eqBars = {}
local EQLayout = Instance.new("UIListLayout")
EQLayout.FillDirection  = Enum.FillDirection.Horizontal
EQLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
EQLayout.Padding        = UDim.new(0, 2)
EQLayout.Parent         = EQBar

for i = 1, EQ_NUM_BARS do
	local bar = Instance.new("Frame")
	bar.Name              = "Bar"..i
	bar.Size              = UDim2.new(0, 10, 0.4, 0)
	bar.BackgroundColor3  = Color3.fromHSV((i/EQ_NUM_BARS)*0.8, 1, 1)
	bar.BorderSizePixel   = 0
	bar.AnchorPoint       = Vector2.new(0, 1)
	bar.Position          = UDim2.new(0, 0, 1, 0)

	local bc = Instance.new("UICorner")
	bc.CornerRadius = UDim.new(0, 2)
	bc.Parent = bar
	bar.Parent = EQBar
	eqBars[i] = bar
end

-- ── Song Info ─────────────────────────────────────────────────────────────────
local SongTitle = Instance.new("TextLabel")
SongTitle.Name                  = "SongTitle"
SongTitle.Size                  = UDim2.new(1, -20, 0, 24)
SongTitle.Position              = UDim2.new(0, 10, 0, 64)
SongTitle.BackgroundTransparency = 1
SongTitle.Text                  = "Memuat playlist..."
SongTitle.TextColor3            = Color3.fromRGB(255, 220, 100)
SongTitle.Font                  = Enum.Font.GothamBold
SongTitle.TextSize              = 13
SongTitle.TextTruncate          = Enum.TextTruncate.AtEnd
SongTitle.TextXAlignment        = Enum.TextXAlignment.Center
SongTitle.Parent                = MainFrame

local SongIndex = Instance.new("TextLabel")
SongIndex.Name                  = "SongIndex"
SongIndex.Size                  = UDim2.new(1, -20, 0, 16)
SongIndex.Position              = UDim2.new(0, 10, 0, 88)
SongIndex.BackgroundTransparency = 1
SongIndex.Text                  = "Track 0 / 0"
SongIndex.TextColor3            = Color3.fromRGB(200, 150, 255)
SongIndex.Font                  = Enum.Font.Gotham
SongIndex.TextSize              = 11
SongIndex.TextXAlignment        = Enum.TextXAlignment.Center
SongIndex.Parent                = MainFrame

-- ── Progress Bar ─────────────────────────────────────────────────────────────
local ProgressBG = Instance.new("Frame")
ProgressBG.Name             = "ProgressBG"
ProgressBG.Size             = UDim2.new(1, -20, 0, 8)
ProgressBG.Position         = UDim2.new(0, 10, 0, 112)
ProgressBG.BackgroundColor3 = Color3.fromRGB(50, 20, 80)
ProgressBG.BorderSizePixel  = 0
ProgressBG.Parent           = MainFrame

local ProgCorner = Instance.new("UICorner")
ProgCorner.CornerRadius = UDim.new(1, 0)
ProgCorner.Parent       = ProgressBG

local ProgressFill = Instance.new("Frame")
ProgressFill.Name             = "Fill"
ProgressFill.Size             = UDim2.new(0, 0, 1, 0)
ProgressFill.Position         = UDim2.new(0, 0, 0, 0)
ProgressFill.BackgroundColor3 = Color3.fromRGB(255, 180, 0)
ProgressFill.BorderSizePixel  = 0
ProgressFill.Parent           = ProgressBG

local FillCorner = Instance.new("UICorner")
FillCorner.CornerRadius = UDim.new(1, 0)
FillCorner.Parent       = ProgressFill

local FillGrad = Instance.new("UIGradient")
FillGrad.Color = ColorSequence.new({
	ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 80, 180)),
	ColorSequenceKeypoint.new(0.5, Color3.fromRGB(255, 200, 0)),
	ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 80, 0)),
})
FillGrad.Parent = ProgressFill

-- ── Time Labels ───────────────────────────────────────────────────────────────
local TimeElapsed = Instance.new("TextLabel")
TimeElapsed.Name                  = "TimeElapsed"
TimeElapsed.Size                  = UDim2.new(0, 60, 0, 14)
TimeElapsed.Position              = UDim2.new(0, 10, 0, 122)
TimeElapsed.BackgroundTransparency = 1
TimeElapsed.Text                  = "0:00"
TimeElapsed.TextColor3            = Color3.fromRGB(180, 180, 180)
TimeElapsed.Font                  = Enum.Font.Code
TimeElapsed.TextSize              = 11
TimeElapsed.TextXAlignment        = Enum.TextXAlignment.Left
TimeElapsed.Parent                = MainFrame

local TimeTotal = Instance.new("TextLabel")
TimeTotal.Name                  = "TimeTotal"
TimeTotal.Size                  = UDim2.new(0, 60, 0, 14)
TimeTotal.Position              = UDim2.new(1, -70, 0, 122)
TimeTotal.BackgroundTransparency = 1
TimeTotal.Text                  = "0:00"
TimeTotal.TextColor3            = Color3.fromRGB(180, 180, 180)
TimeTotal.Font                  = Enum.Font.Code
TimeTotal.TextSize              = 11
TimeTotal.TextXAlignment        = Enum.TextXAlignment.Right
TimeTotal.Parent                = MainFrame

-- ── Buttons ───────────────────────────────────────────────────────────────────
local ButtonContainer = Instance.new("Frame")
ButtonContainer.Name             = "Buttons"
ButtonContainer.Size             = UDim2.new(1, -20, 0, 44)
ButtonContainer.Position         = UDim2.new(0, 10, 0, 142)
ButtonContainer.BackgroundTransparency = 1
ButtonContainer.Parent           = MainFrame

local BtnLayout = Instance.new("UIListLayout")
BtnLayout.FillDirection  = Enum.FillDirection.Horizontal
BtnLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
BtnLayout.VerticalAlignment   = Enum.VerticalAlignment.Center
BtnLayout.Padding = UDim.new(0, 12)
BtnLayout.Parent  = ButtonContainer

local function makeButton(text, color)
	local btn = Instance.new("TextButton")
	btn.Size              = UDim2.new(0, 110, 0, 36)
	btn.BackgroundColor3  = color
	btn.BorderSizePixel   = 0
	btn.Text              = text
	btn.TextColor3        = Color3.fromRGB(255, 255, 255)
	btn.Font              = Enum.Font.GothamBold
	btn.TextSize          = 13
	btn.AutoButtonColor   = false

	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, 8)
	c.Parent = btn

	local s = Instance.new("UIStroke")
	s.Color     = Color3.fromRGB(255, 255, 255)
	s.Thickness = 1
	s.Transparency = 0.7
	s.Parent    = btn

	btn.MouseEnter:Connect(function()
		TweenService:Create(btn, TweenInfo.new(0.15), {
			BackgroundColor3 = color:Lerp(Color3.fromRGB(255,255,255), 0.2)
		}):Play()
	end)
	btn.MouseLeave:Connect(function()
		TweenService:Create(btn, TweenInfo.new(0.15), {
			BackgroundColor3 = color
		}):Play()
	end)
	btn.MouseButton1Down:Connect(function()
		TweenService:Create(btn, TweenInfo.new(0.08), {
			Size = UDim2.new(0, 104, 0, 32)
		}):Play()
	end)
	btn.MouseButton1Up:Connect(function()
		TweenService:Create(btn, TweenInfo.new(0.08), {
			Size = UDim2.new(0, 110, 0, 36)
		}):Play()
	end)

	return btn
end

local BtnPrev = makeButton("⏮ PREV", Color3.fromRGB(100, 0, 180))
BtnPrev.Parent = ButtonContainer

local BtnNext = makeButton("NEXT ⏭", Color3.fromRGB(180, 50, 0))
BtnNext.Parent = ButtonContainer

-- ── Volume Slider ─────────────────────────────────────────────────────────────
local VolumeLabel = Instance.new("TextLabel")
VolumeLabel.Name                  = "VolumeLabel"
VolumeLabel.Size                  = UDim2.new(1, -20, 0, 14)
VolumeLabel.Position              = UDim2.new(0, 10, 0, 192)
VolumeLabel.BackgroundTransparency = 1
VolumeLabel.Text                  = "🔊 Volume: 60%"
VolumeLabel.TextColor3            = Color3.fromRGB(180, 255, 180)
VolumeLabel.Font                  = Enum.Font.Gotham
VolumeLabel.TextSize              = 11
VolumeLabel.TextXAlignment        = Enum.TextXAlignment.Left
VolumeLabel.Parent                = MainFrame

-- ── Toggle Button (minimize) ──────────────────────────────────────────────────
local ToggleBtn = Instance.new("TextButton")
ToggleBtn.Name             = "Toggle"
ToggleBtn.Size             = UDim2.new(0, 28, 0, 28)
ToggleBtn.Position         = UDim2.new(1, -34, 0, 4)
ToggleBtn.BackgroundColor3 = Color3.fromRGB(40, 0, 60)
ToggleBtn.BorderSizePixel  = 0
ToggleBtn.Text             = "–"
ToggleBtn.TextColor3       = Color3.fromRGB(255, 200, 0)
ToggleBtn.Font             = Enum.Font.GothamBold
ToggleBtn.TextSize         = 18
ToggleBtn.ZIndex           = 4
ToggleBtn.Parent           = MainFrame

local TCorner = Instance.new("UICorner")
TCorner.CornerRadius = UDim.new(0, 6)
TCorner.Parent = ToggleBtn

-- ── Neon Glow ─────────────────────────────────────────────────────────────────
-- Simulated with a shadow frame
local GlowFrame = Instance.new("Frame")
GlowFrame.Name             = "Glow"
GlowFrame.Size             = UDim2.new(1, 20, 1, 20)
GlowFrame.Position         = UDim2.new(0, -10, 0, -10)
GlowFrame.BackgroundColor3 = Color3.fromRGB(255, 180, 0)
GlowFrame.BackgroundTransparency = 0.85
GlowFrame.BorderSizePixel  = 0
GlowFrame.ZIndex           = 0
GlowFrame.Parent           = MainFrame

local GlowCorner = Instance.new("UICorner")
GlowCorner.CornerRadius = UDim.new(0, 16)
GlowCorner.Parent = GlowFrame

-- ─── Marquee Text Effect ──────────────────────────────────────────────────────
-- Scrolling song title
local marqueeOffset = 0

-- ─── Helper: Format time ─────────────────────────────────────────────────────
local function formatTime(secs)
	if secs ~= secs or secs < 0 then secs = 0 end
	local m = math.floor(secs / 60)
	local s = math.floor(secs % 60)
	return string.format("%d:%02d", m, s)
end

-- ─── EQ Animation ────────────────────────────────────────────────────────────
local eqTime = 0
local function updateEQ(dt)
	eqTime += dt
	for i, bar in ipairs(eqBars) do
		local h = 0.2 + 0.8 * math.abs(math.sin(eqTime * (1 + i * 0.3) + i * 0.5))
		if not isPlaying then h = 0.05 end
		bar.Size = UDim2.new(0, 10, h, 0)
		bar.BackgroundColor3 = Color3.fromHSV(((i / EQ_NUM_BARS) * 0.8 + eqTime * 0.05) % 1, 1, 1)
	end
end

-- ─── Marquee Effect ──────────────────────────────────────────────────────────
local function updateMarquee(dt)
	if not currentTitle or currentTitle == "" then return end
	local full = currentTitle .. "   ◈   "
	local len  = #full
	marqueeOffset = (marqueeOffset + dt * 8) % len
	local idx    = math.floor(marqueeOffset) + 1
	local display = full:sub(idx) .. full:sub(1, idx - 1)
	-- Trim to fit
	if #display > 34 then display = display:sub(1, 34) end
	SongTitle.Text = display
end

-- ─── Glow Pulse ──────────────────────────────────────────────────────────────
local glowTime = 0
local function updateGlow(dt)
	glowTime += dt
	local alpha = 0.85 + 0.1 * math.sin(glowTime * 2)
	GlowFrame.BackgroundTransparency = alpha
end

-- ─── GUI Update Loop ─────────────────────────────────────────────────────────
RunService.RenderStepped:Connect(function(dt)
	updateEQ(dt)
	updateMarquee(dt)
	updateGlow(dt)

	-- Update progress bar
	if sound.IsPlaying and sound.TimeLength > 0 then
		local pos   = sound.TimePosition
		local total = sound.TimeLength
		local pct   = math.clamp(pos / total, 0, 1)
		ProgressFill.Size = UDim2.new(pct, 0, 1, 0)
		TimeElapsed.Text  = formatTime(pos)
		TimeTotal.Text    = formatTime(total)
	end

	-- Update index
	if totalSongs > 0 then
		SongIndex.Text = string.format("Track %d / %d", currentIndex, totalSongs)
	end
end)

-- ─── Sync Receiver ────────────────────────────────────────────────────────────
RE_SyncState.OnClientEvent:Connect(function(state)
	applySync(state)
end)

-- ─── Song Ended → Request server to advance ──────────────────────────────────
sound.Ended:Connect(function()
	-- Server drives song changes; we just report. But if we're out of sync, 
	-- the server's periodic sync will catch us. Optionally request next:
	RE_NextSong:FireServer()
end)

-- ─── Button Handlers ─────────────────────────────────────────────────────────
BtnPrev.MouseButton1Click:Connect(function()
	RE_PrevSong:FireServer()
end)

BtnNext.MouseButton1Click:Connect(function()
	RE_NextSong:FireServer()
end)

-- ─── Toggle Minimize ─────────────────────────────────────────────────────────
local minimized = false
ToggleBtn.MouseButton1Click:Connect(function()
	minimized = not minimized
	if minimized then
		TweenService:Create(MainFrame, TweenInfo.new(0.3, Enum.EasingStyle.Back), {
			Size = UDim2.new(0, 340, 0, 40)
		}):Play()
		ToggleBtn.Text = "+"
	else
		TweenService:Create(MainFrame, TweenInfo.new(0.3, Enum.EasingStyle.Back), {
			Size = UDim2.new(0, 340, 0, 220)
		}):Play()
		ToggleBtn.Text = "–"
	end
end)

-- ─── Draggable ───────────────────────────────────────────────────────────────
do
	local dragging, dragStart, startPos
	Header.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			dragging  = true
			dragStart = input.Position
			startPos  = MainFrame.Position
		end
	end)
	Header.InputChanged:Connect(function(input)
		if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
			local delta = input.Position - dragStart
			MainFrame.Position = UDim2.new(
				startPos.X.Scale,
				startPos.X.Offset + delta.X,
				startPos.Y.Scale,
				startPos.Y.Offset + delta.Y
			)
		end
	end)
	Header.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			dragging = false
		end
	end)
end

-- ─── Volume Control (scroll wheel on GUI) ────────────────────────────────────
MainFrame.InputChanged:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseWheel then
		sound.Volume = math.clamp(sound.Volume + input.Position.Z * 0.05, 0, 1)
		VolumeLabel.Text = string.format("🔊 Volume: %d%%", math.floor(sound.Volume * 100))
	end
end)

-- ─── Initial State Request ───────────────────────────────────────────────────
task.spawn(function()
	task.wait(2)  -- wait for server to init
	local state = RF_GetState:InvokeServer()
	if state then
		applySync(state)
	end

	-- Load full playlist for display
	local pl = RF_GetPlaylist:InvokeServer()
	if pl then
		playlist = pl
		totalSongs = #pl
	end
end)
