local ThemeModule = {}

local RunService = game:GetService("RunService")
local SoundService = game:GetService("SoundService")

local lastExternalBeat = 0
local lastInternalBeat = 0
local loudnessAvg = 0
local cachedServerSound = nil

ThemeModule.Colors = {
	Primary1 = Color3.fromHex("#FFFFFF"),
	Primary2 = Color3.fromHex("#888888"),

	BackgroundDark = Color3.fromHex("#080808"),
	BackgroundMedium = Color3.fromHex("#151515"),
	BackgroundLight = Color3.fromHex("#1C1C1C"),
	BackgroundLighter = Color3.fromHex("#262626"),

	TextWhite = Color3.fromHex("#FFFFFF"),
	TextGray = Color3.fromHex("#A0A0A0"),
	TextSecondary = Color3.fromHex("#A0A0A0"),
	TextDark = Color3.fromHex("#111111"),
	TextMuted = Color3.fromHex("#666666"),

	TextOnGradient = Color3.fromHex("#111111"),

	ButtonPrimaryBg = Color3.fromHex("#FFFFFF"),
	ButtonPrimaryText = Color3.fromHex("#111111"),
	ButtonSecondaryBg = Color3.fromHex("#1C1C1C"),
	ButtonSecondaryText = Color3.fromHex("#FFFFFF"),
	ButtonHoverBg = Color3.fromHex("#2A2A2A"),
	ButtonPressedBg = Color3.fromHex("#333333"),

	CloseRed = Color3.fromHex("#2A2A2A"),
	CloseRedHover = Color3.fromHex("#404040"),
	Success = Color3.fromHex("#FFFFFF"),
	SuccessDark = Color3.fromHex("#888888"),
	Warning = Color3.fromHex("#D0D0D0"),
	WarningDark = Color3.fromHex("#707070"),
	Error = Color3.fromHex("#B0B0B0"),
	ErrorDark = Color3.fromHex("#505050"),
	Info = Color3.fromHex("#FFFFFF"),
	InfoDark = Color3.fromHex("#888888"),

	VIPGold = Color3.fromHex("#FFFFFF"),
	VIPOrange = Color3.fromHex("#888888"),

	Disabled = Color3.fromHex("#353535"),
	DisabledText = Color3.fromHex("#666666"),

	StrokeBase = Color3.fromHex("#353535"),
	Border = Color3.fromHex("#353535"),
}

ThemeModule.Gradients = {
	Primary = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromHex("#151515")),
		ColorSequenceKeypoint.new(0.5, Color3.fromHex("#FFFFFF")),
		ColorSequenceKeypoint.new(1, Color3.fromHex("#353535"))
	}),

	PrimaryReversed = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromHex("#353535")),
		ColorSequenceKeypoint.new(0.5, Color3.fromHex("#FFFFFF")),
		ColorSequenceKeypoint.new(1, Color3.fromHex("#151515"))
	}),

	Background = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromHex("#1C1C1C")),
		ColorSequenceKeypoint.new(1, Color3.fromHex("#080808"))
	}),

	ButtonPrimary = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromHex("#FFFFFF")),
		ColorSequenceKeypoint.new(1, Color3.fromHex("#D0D0D0"))
	}),

	Success = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromHex("#FFFFFF")),
		ColorSequenceKeypoint.new(1, Color3.fromHex("#888888"))
	}),

	Warning = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromHex("#D0D0D0")),
		ColorSequenceKeypoint.new(1, Color3.fromHex("#707070"))
	}),

	Error = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromHex("#B0B0B0")),
		ColorSequenceKeypoint.new(1, Color3.fromHex("#505050"))
	}),

	Info = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromHex("#FFFFFF")),
		ColorSequenceKeypoint.new(1, Color3.fromHex("#888888"))
	}),

	VIP = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromHex("#FFFFFF")),
		ColorSequenceKeypoint.new(1, Color3.fromHex("#666666"))
	}),

	DarkToLight = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromHex("#080808")),
		ColorSequenceKeypoint.new(1, Color3.fromHex("#1C1C1C"))
	}),
}

ThemeModule.Animation = {
	OpenDuration = 0.25,
	CloseDuration = 0.18,
	OpenEasingStyle = Enum.EasingStyle.Quart,
	OpenEasingDirection = Enum.EasingDirection.Out,
	CloseEasingStyle = Enum.EasingStyle.Quart,
	CloseEasingDirection = Enum.EasingDirection.In,
}

ThemeModule.Fonts = {
	Title = Enum.Font.GothamBold,
	Header = Enum.Font.GothamBold,
	Body = Enum.Font.GothamMedium,
	BodyBold = Enum.Font.GothamBold,
	Regular = Enum.Font.Gotham,
	Medium = Enum.Font.GothamMedium,
	Bold = Enum.Font.GothamBold,
	SemiBold = Enum.Font.GothamBold,
	Caption = Enum.Font.Gotham,
}

ThemeModule.Typography = {
	Font = Enum.Font.GothamMedium,
	FontBold = Enum.Font.GothamBold,
	SizeTitle = 16,
	SizeSubtitle = 13,
	SizeBody = 12,
	SizeCaption = 10,
}

ThemeModule.Dimensions = {
	HeaderHeight = 44,
	MinTouchTarget = 44,
	CornerSmall = 6,
	CornerMedium = 8,
	CornerLarge = 12,
	CornerPill = 99,
	StrokeThin = 1,
	StrokeMedium = 1.5,
	StrokeBold = 2,
}

ThemeModule.GradientSystem = {
	Gradients = {},
	Connection = nil,
	Speed = 1.2,
	Time = 0,
	IsRunning = false,
	BeatMultiplier = 1.0,
}

function ThemeModule.GradientSystem.SetBeat(multiplier)
	lastExternalBeat = os.clock()
	ThemeModule.GradientSystem.BeatMultiplier = math.clamp(multiplier or 1.0, 0.5, 3.5)
end

function ThemeModule.GradientSystem.Register(gradient, speed)
	if not gradient then return end

	for _, data in ipairs(ThemeModule.GradientSystem.Gradients) do
		if data.gradient == gradient then
			data.speed = speed or data.speed
			return
		end
	end

	table.insert(ThemeModule.GradientSystem.Gradients, {
		gradient = gradient,
		speed = speed or 1
	})

	if not ThemeModule.GradientSystem.IsRunning or not ThemeModule.GradientSystem.Connection then
		ThemeModule.GradientSystem.Start()
	end
end

function ThemeModule.GradientSystem.Unregister(gradient)
	for i = #ThemeModule.GradientSystem.Gradients, 1, -1 do
		if ThemeModule.GradientSystem.Gradients[i].gradient == gradient then
			table.remove(ThemeModule.GradientSystem.Gradients, i)
			break
		end
	end
end

function ThemeModule.GradientSystem.Start()
	if ThemeModule.GradientSystem.Connection then return end

	ThemeModule.GradientSystem.IsRunning = true
	ThemeModule.GradientSystem.Connection = RunService.Heartbeat:Connect(function(dt)
		local now = os.clock()

		if (now - lastExternalBeat) > 0.35 then
			if not cachedServerSound or not cachedServerSound.Parent then
				cachedServerSound = SoundService:FindFirstChild("ServerMusicSound") or workspace:FindFirstChild("ServerMusicSound", true)
			end
			if cachedServerSound and cachedServerSound.IsPlaying then
				local ok, loudness = pcall(function() return cachedServerSound.PlaybackLoudness end)
				if ok and type(loudness) == "number" and loudness > 5 then
					loudnessAvg = (loudnessAvg * 0.92) + (loudness * 0.08)
					local threshold = math.max(loudnessAvg * 1.30, 95)
					if loudness > threshold and (now - lastInternalBeat) > 0.16 then
						lastInternalBeat = now
						local hit = math.clamp((loudness - threshold) / 200, 0.4, 1.0)
						ThemeModule.GradientSystem.BeatMultiplier = math.max(ThemeModule.GradientSystem.BeatMultiplier, 1.0 + (hit * 1.8))
					end
				end
			end
		end

		local currentSpeed = ThemeModule.GradientSystem.Speed * ThemeModule.GradientSystem.BeatMultiplier
		ThemeModule.GradientSystem.Time = ThemeModule.GradientSystem.Time + dt * currentSpeed

		if ThemeModule.GradientSystem.BeatMultiplier > 1.0 then
			ThemeModule.GradientSystem.BeatMultiplier = math.max(1.0, ThemeModule.GradientSystem.BeatMultiplier - dt * 2.5)
		end

		local beatPulse = (ThemeModule.GradientSystem.BeatMultiplier - 1.0) * 0.25
		local amp = 0.5 + beatPulse

		for i = #ThemeModule.GradientSystem.Gradients, 1, -1 do
			local data = ThemeModule.GradientSystem.Gradients[i]
			local g = data and data.gradient
			if g and g.Parent then
				if data.speed and data.speed > 0 then
					pcall(function()
						local rawOffset = math.sin(ThemeModule.GradientSystem.Time * data.speed) * amp
						g.Offset = Vector2.new(rawOffset, 0)
					end)
				end
			else
				table.remove(ThemeModule.GradientSystem.Gradients, i)
			end
		end
	end)
end

function ThemeModule.GradientSystem.Stop()
	ThemeModule.GradientSystem.IsRunning = false
	if ThemeModule.GradientSystem.Connection then
		ThemeModule.GradientSystem.Connection:Disconnect()
		ThemeModule.GradientSystem.Connection = nil
	end
end

function ThemeModule.GradientSystem.Clear()
	for i = #ThemeModule.GradientSystem.Gradients, 1, -1 do
		local data = ThemeModule.GradientSystem.Gradients[i]
		if not data.gradient or not data.gradient.Parent then
			table.remove(ThemeModule.GradientSystem.Gradients, i)
		end
	end
end

function ThemeModule.GradientSystem.SetSpeed(speed)
	ThemeModule.GradientSystem.Speed = speed or 1.2
end

function ThemeModule.GradientSystem.GetCount()
	return #ThemeModule.GradientSystem.Gradients
end

function ThemeModule.CreatePrimaryGradient(parent, rotation, speed)
	local gradient = Instance.new("UIGradient")
	gradient.Color = ThemeModule.Gradients.Primary
	gradient.Rotation = rotation or 0
	gradient.Parent = parent
	ThemeModule.GradientSystem.Register(gradient, speed or 1)
	return gradient
end

function ThemeModule.CreateAnimatedGradient(parent, gradientName, rotation, speed)
	local gradient = Instance.new("UIGradient")
	gradient.Color = ThemeModule.Gradients[gradientName] or ThemeModule.Gradients.Primary
	gradient.Rotation = rotation or 0
	gradient.Parent = parent
	ThemeModule.GradientSystem.Register(gradient, speed or 1)
	return gradient
end

function ThemeModule.CreateStaticGradient(parent, gradientName, rotation)
	local gradient = Instance.new("UIGradient")
	gradient.Color = ThemeModule.Gradients[gradientName] or ThemeModule.Gradients.Primary
	gradient.Rotation = rotation or 0
	gradient.Parent = parent
	ThemeModule.GradientSystem.Register(gradient, 0)
	return gradient
end

function ThemeModule.CreateAnimatedStroke(parent, thickness, gradientName, speed)
	local stroke = Instance.new("UIStroke")
	stroke.Name = "AnimatedStroke"
	stroke.Thickness = thickness or 2
	stroke.Color = ThemeModule.Colors.StrokeBase
	stroke.Transparency = 0
	stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	stroke.Parent = parent

	local gradient = Instance.new("UIGradient")
	gradient.Name = "StrokeGradient"
	gradient.Color = ThemeModule.Gradients[gradientName] or ThemeModule.Gradients.Primary
	gradient.Rotation = 45
	gradient.Parent = stroke
	ThemeModule.GradientSystem.Register(gradient, speed or 1.2)

	return stroke, gradient
end

function ThemeModule.CreateStaticStroke(parent, thickness, color, transparency)
	local stroke = Instance.new("UIStroke")
	stroke.Name = "StaticStroke"
	stroke.Thickness = thickness or 2
	stroke.Color = color or ThemeModule.Colors.StrokeBase
	stroke.Transparency = transparency or 0
	stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	stroke.Parent = parent

	return stroke
end

function ThemeModule.CreateGradientStroke(parent, thickness, gradientName, rotation)
	local stroke = Instance.new("UIStroke")
	stroke.Name = "GradientStroke"
	stroke.Thickness = thickness or 2
	stroke.Color = ThemeModule.Colors.StrokeBase
	stroke.Transparency = 0
	stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	stroke.Parent = parent

	local gradient = Instance.new("UIGradient")
	gradient.Name = "StrokeGradient"
	gradient.Color = ThemeModule.Gradients[gradientName] or ThemeModule.Gradients.Primary
	gradient.Rotation = rotation or 45
	gradient.Parent = stroke
	ThemeModule.GradientSystem.Register(gradient, 0)

	return stroke, gradient
end

function ThemeModule.CreateCorner(parent, radius)
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, radius or 8)
	corner.Parent = parent
	return corner
end

function ThemeModule.ApplyPrimaryGradient(uiGradient, rotation, speed)
	if not uiGradient then return end
	uiGradient.Color = ThemeModule.Gradients.Primary
	uiGradient.Rotation = rotation or 0
	ThemeModule.GradientSystem.Register(uiGradient, speed or 1)
end

function ThemeModule.ApplyGradient(uiGradient, gradientName, rotation, animated, speed)
	if not uiGradient then return end
	uiGradient.Color = ThemeModule.Gradients[gradientName] or ThemeModule.Gradients.Primary
	uiGradient.Rotation = rotation or 0
	if animated then
		ThemeModule.GradientSystem.Register(uiGradient, speed or 1)
	end
end

function ThemeModule.ApplyBackgroundGradient(uiGradient, rotation)
	if not uiGradient then return end
	uiGradient.Color = ThemeModule.Gradients.Background
	uiGradient.Rotation = rotation or 135
end

function ThemeModule.GetColor(name)
	return ThemeModule.Colors[name] or ThemeModule.Colors.TextWhite
end

function ThemeModule.GetGradient(name)
	return ThemeModule.Gradients[name] or ThemeModule.Gradients.Primary
end

function ThemeModule.GetPrimaryColors()
	return ThemeModule.Colors.Primary1, ThemeModule.Colors.Primary2
end

ThemeModule.Styles = {
	Button = {
		BackgroundColor = ThemeModule.Colors.BackgroundMedium,
		TextColor = ThemeModule.Colors.TextWhite,
		CornerRadius = 8,
		Font = Enum.Font.GothamBold,
	},

	ButtonPrimary = {
		BackgroundColor = ThemeModule.Colors.ButtonPrimaryBg,
		TextColor = ThemeModule.Colors.ButtonPrimaryText,
		CornerRadius = 8,
		Font = Enum.Font.GothamBold,
	},

	ButtonSecondary = {
		BackgroundColor = ThemeModule.Colors.ButtonSecondaryBg,
		TextColor = ThemeModule.Colors.ButtonSecondaryText,
		CornerRadius = 8,
		Font = Enum.Font.GothamMedium,
	},

	Card = {
		BackgroundColor = ThemeModule.Colors.BackgroundDark,
		CornerRadius = 12,
	},

	Header = {
		BackgroundColor = ThemeModule.Colors.BackgroundMedium,
		TextColor = ThemeModule.Colors.TextWhite,
		Height = 44,
		CornerRadius = 12,
	},

	Input = {
		BackgroundColor = ThemeModule.Colors.BackgroundLight,
		TextColor = ThemeModule.Colors.TextWhite,
		PlaceholderColor = ThemeModule.Colors.TextMuted,
		CornerRadius = 6,
	},

	Toggle = {
		BackgroundColorOff = ThemeModule.Colors.BackgroundLight,
		BackgroundColorOn = ThemeModule.Colors.Primary1,
		CornerRadius = 10,
	},
}

function ThemeModule.ApplyStyle(instance, styleName)
	local style = ThemeModule.Styles[styleName]
	if not style then return end

	if style.BackgroundColor and instance:IsA("GuiObject") then
		instance.BackgroundColor3 = style.BackgroundColor
	end

	if style.TextColor then
		if instance:IsA("TextLabel") or instance:IsA("TextButton") or instance:IsA("TextBox") then
			instance.TextColor3 = style.TextColor
		end
	end

	if style.PlaceholderColor and instance:IsA("TextBox") then
		instance.PlaceholderColor3 = style.PlaceholderColor
	end

	if style.Font then
		if instance:IsA("TextLabel") or instance:IsA("TextButton") or instance:IsA("TextBox") then
			instance.Font = style.Font
		end
	end

	if style.CornerRadius then
		local corner = instance:FindFirstChildOfClass("UICorner")
		if not corner then
			corner = Instance.new("UICorner")
			corner.Parent = instance
		end
		corner.CornerRadius = UDim.new(0, style.CornerRadius)
	end
end

ThemeModule.Presets = {}

ThemeModule.Presets.Gold = {
	Primary1 = Color3.fromRGB(255, 215, 0),
	Primary2 = Color3.fromRGB(255, 140, 0),
}

ThemeModule.Presets.Blue = {
	Primary1 = Color3.fromRGB(100, 150, 255),
	Primary2 = Color3.fromRGB(50, 100, 200),
}

ThemeModule.Presets.Green = {
	Primary1 = Color3.fromRGB(100, 255, 150),
	Primary2 = Color3.fromRGB(50, 200, 100),
}

ThemeModule.Presets.Purple = {
	Primary1 = Color3.fromRGB(200, 100, 255),
	Primary2 = Color3.fromRGB(150, 50, 200),
}

ThemeModule.Presets.Red = {
	Primary1 = Color3.fromRGB(255, 100, 100),
	Primary2 = Color3.fromRGB(200, 50, 50),
}

ThemeModule.Presets.Cyan = {
	Primary1 = Color3.fromRGB(0, 210, 255),
	Primary2 = Color3.fromRGB(0, 160, 210),
}

ThemeModule.Presets.Pink = {
	Primary1 = Color3.fromRGB(255, 150, 200),
	Primary2 = Color3.fromRGB(255, 100, 150),
}

ThemeModule.Presets.White = {
	Primary1 = Color3.fromRGB(255, 255, 255),
	Primary2 = Color3.fromRGB(200, 200, 200),
}

function ThemeModule.ApplyPreset(presetName)
	local preset = ThemeModule.Presets[presetName]
	local accentColor = nil

	if preset and preset.Primary1 then
		accentColor = preset.Primary1
		ThemeModule.Colors.Primary1 = preset.Primary1
		ThemeModule.Colors.Primary2 = preset.Primary2 or preset.Primary1
	elseif typeof(presetName) == "Color3" then
		accentColor = presetName
		ThemeModule.Colors.Primary1 = presetName
		ThemeModule.Colors.Primary2 = presetName
	elseif type(presetName) == "string" then
		local ok, hexColor = pcall(function() return Color3.fromHex(presetName) end)
		if ok and hexColor then
			accentColor = hexColor
			ThemeModule.Colors.Primary1 = hexColor
			ThemeModule.Colors.Primary2 = hexColor
		end
	end

	if not accentColor then
		warn("ThemeModule: Preset '" .. tostring(presetName) .. "' tidak ditemukan")
		return false
	end

	ThemeModule.Gradients.Primary = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromHex("#151515")),
		ColorSequenceKeypoint.new(0.5, accentColor),
		ColorSequenceKeypoint.new(1, Color3.fromHex("#353535"))
	})

	ThemeModule.Gradients.PrimaryReversed = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromHex("#353535")),
		ColorSequenceKeypoint.new(0.5, accentColor),
		ColorSequenceKeypoint.new(1, Color3.fromHex("#151515"))
	})

	for _, data in ipairs(ThemeModule.GradientSystem.Gradients) do
		if data.gradient and data.gradient.Parent then
			data.gradient.Color = ThemeModule.Gradients.Primary
		end
	end

	print("ThemeModule: Tema '" .. tostring(presetName) .. "' berhasil diterapkan (Gradien diperbarui)")
	return true
end

function ThemeModule.GetCurrentPrimaryColors()
	return ThemeModule.Colors.Primary1, ThemeModule.Colors.Primary2
end

function ThemeModule.LerpColor(color1, color2, alpha)
	return Color3.new(
		color1.R + (color2.R - color1.R) * alpha,
		color1.G + (color2.G - color1.G) * alpha,
		color1.B + (color2.B - color1.B) * alpha
	)
end

function ThemeModule.DarkenColor(color, amount)
	amount = amount or 0.2
	return Color3.new(
		math.max(0, color.R - amount),
		math.max(0, color.G - amount),
		math.max(0, color.B - amount)
	)
end

function ThemeModule.LightenColor(color, amount)
	amount = amount or 0.2
	return Color3.new(
		math.min(1, color.R + amount),
		math.min(1, color.G + amount),
		math.min(1, color.B + amount)
	)
end

function ThemeModule.GetContrastColor(backgroundColor)
	local luminance = 0.299 * backgroundColor.R + 0.587 * backgroundColor.G + 0.114 * backgroundColor.B
	if luminance > 0.5 then
		return Color3.new(0, 0, 0)
	else
		return Color3.new(1, 1, 1)
	end
end

function ThemeModule.GetThemeColor(themeName)
	if typeof(themeName) == "Color3" then
		return themeName
	end
	if type(themeName) == "string" and themeName ~= "" and themeName ~= "White" and themeName ~= "Default" then
		if ThemeModule.Presets and ThemeModule.Presets[themeName] then
			local preset = ThemeModule.Presets[themeName]
			if preset and preset.Primary1 then
				return preset.Primary1
			end
		end
		local ok, hexColor = pcall(function() return Color3.fromHex(themeName) end)
		if ok and hexColor then
			return hexColor
		end
	end
	return Color3.fromRGB(255, 255, 255)
end

return ThemeModule

