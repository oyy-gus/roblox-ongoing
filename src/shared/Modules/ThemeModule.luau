-- Place in: ReplicatedStorage > Modules(Folder) > ThemeModule(ModuleScript)
-- ====================================

local ThemeModule = {}

local RunService = game:GetService("RunService")

-- ========================================
-- WARNA UTAMA
-- ========================================
ThemeModule.Colors = {
	-- Primary Colors (Monochrome Black & White Theme)
	Primary1 = Color3.fromHex("#FFFFFF"),      -- Pure White Accent
	Primary2 = Color3.fromHex("#888888"),      -- Smooth Gray Transition

	-- Background Colors (Monochrome)
	BackgroundDark = Color3.fromHex("#080808"),   -- Hitam pekat
	BackgroundMedium = Color3.fromHex("#151515"), -- Secondary background
	BackgroundLight = Color3.fromHex("#1C1C1C"),  -- Panel background
	BackgroundLighter = Color3.fromHex("#262626"),-- Surface / Card background

	-- Text Colors
	TextWhite = Color3.fromHex("#FFFFFF"),
	TextGray = Color3.fromHex("#A0A0A0"),
	TextSecondary = Color3.fromHex("#A0A0A0"),
	TextDark = Color3.fromHex("#111111"),
	TextMuted = Color3.fromHex("#666666"),
	
	TextOnGradient = Color3.fromHex("#111111"),  -- Dark text untuk di atas gradient putih

	-- Accent Colors (Monokromatis)
	CloseRed = Color3.fromHex("#2A2A2A"),        -- Sleek dark close button
	CloseRedHover = Color3.fromHex("#404040"),   -- Hover state
	Success = Color3.fromHex("#FFFFFF"),         -- White indicator
	SuccessDark = Color3.fromHex("#888888"),
	Warning = Color3.fromHex("#D0D0D0"),
	WarningDark = Color3.fromHex("#707070"),
	Error = Color3.fromHex("#B0B0B0"),
	ErrorDark = Color3.fromHex("#505050"),
	Info = Color3.fromHex("#FFFFFF"),
	InfoDark = Color3.fromHex("#888888"),

	-- VIP Colors (Monochrome Silver/White)
	VIPGold = Color3.fromHex("#FFFFFF"),
	VIPOrange = Color3.fromHex("#888888"),

	-- Disabled State
	Disabled = Color3.fromHex("#353535"),
	DisabledText = Color3.fromHex("#666666"),

	-- Stroke Base Color & Borders
	StrokeBase = Color3.fromHex("#353535"),
	Border = Color3.fromHex("#353535"),
}

-- ========================================
-- GRADIENT SEQUENCES
-- ========================================
ThemeModule.Gradients = {
	-- Primary gradient (Black & White with Gray transition)
	Primary = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromHex("#151515")),
		ColorSequenceKeypoint.new(0.5, Color3.fromHex("#FFFFFF")),
		ColorSequenceKeypoint.new(1, Color3.fromHex("#353535"))
	}),

	-- Primary reversed
	PrimaryReversed = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromHex("#353535")),
		ColorSequenceKeypoint.new(0.5, Color3.fromHex("#FFFFFF")),
		ColorSequenceKeypoint.new(1, Color3.fromHex("#151515"))
	}),

	-- Background gradient (Hitam pekat ke Panel dark)
	Background = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromHex("#1C1C1C")),
		ColorSequenceKeypoint.new(1, Color3.fromHex("#080808"))
	}),

	-- Success gradient
	Success = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromHex("#FFFFFF")),
		ColorSequenceKeypoint.new(1, Color3.fromHex("#888888"))
	}),

	-- Warning gradient
	Warning = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromHex("#D0D0D0")),
		ColorSequenceKeypoint.new(1, Color3.fromHex("#707070"))
	}),

	-- Error gradient
	Error = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromHex("#B0B0B0")),
		ColorSequenceKeypoint.new(1, Color3.fromHex("#505050"))
	}),

	-- Info gradient
	Info = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromHex("#FFFFFF")),
		ColorSequenceKeypoint.new(1, Color3.fromHex("#888888"))
	}),

	-- VIP gradient (Monochrome Silver/White)
	VIP = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromHex("#FFFFFF")),
		ColorSequenceKeypoint.new(1, Color3.fromHex("#666666"))
	}),

	-- Dark to light
	DarkToLight = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromHex("#080808")),
		ColorSequenceKeypoint.new(1, Color3.fromHex("#1C1C1C"))
	}),
}

-- ========================================
-- GRADIENT ANIMATION SYSTEM
-- ========================================
ThemeModule.GradientSystem = {
	Gradients = {},
	Connection = nil,
	Speed = 1.2,
	Time = 0,
	IsRunning = false
}

function ThemeModule.GradientSystem.Register(gradient, speed)
	if not gradient then return end

	-- Check if already registered
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
		ThemeModule.GradientSystem.Time = ThemeModule.GradientSystem.Time + dt * ThemeModule.GradientSystem.Speed

		for i = #ThemeModule.GradientSystem.Gradients, 1, -1 do
			local data = ThemeModule.GradientSystem.Gradients[i]
			if data.gradient and data.gradient.Parent then
				local offset = math.sin(ThemeModule.GradientSystem.Time * data.speed) * 0.5
				data.gradient.Offset = Vector2.new(offset, 0)
			else
				-- Remove invalid gradient
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
	ThemeModule.GradientSystem.Stop()
	ThemeModule.GradientSystem.Gradients = {}
	ThemeModule.GradientSystem.Time = 0
end

function ThemeModule.GradientSystem.SetSpeed(speed)
	ThemeModule.GradientSystem.Speed = speed or 1.2
end

function ThemeModule.GradientSystem.GetCount()
	return #ThemeModule.GradientSystem.Gradients
end

-- ========================================
-- HELPER FUNCTIONS - CREATE
-- ========================================

-- Create UIGradient with primary colors (animated)
function ThemeModule.CreatePrimaryGradient(parent, rotation, speed)
	local gradient = Instance.new("UIGradient")
	gradient.Color = ThemeModule.Gradients.Primary
	gradient.Rotation = rotation or 0
	gradient.Parent = parent
	ThemeModule.GradientSystem.Register(gradient, speed or 1)
	return gradient
end

-- Create UIGradient with any gradient (animated)
function ThemeModule.CreateAnimatedGradient(parent, gradientName, rotation, speed)
	local gradient = Instance.new("UIGradient")
	gradient.Color = ThemeModule.Gradients[gradientName] or ThemeModule.Gradients.Primary
	gradient.Rotation = rotation or 0
	gradient.Parent = parent
	ThemeModule.GradientSystem.Register(gradient, speed or 1)
	return gradient
end

-- Create static UIGradient (not animated)
function ThemeModule.CreateStaticGradient(parent, gradientName, rotation)
	local gradient = Instance.new("UIGradient")
	gradient.Color = ThemeModule.Gradients[gradientName] or ThemeModule.Gradients.Primary
	gradient.Rotation = rotation or 0
	gradient.Parent = parent
	return gradient
end

-- ========================================
-- FIXED: Create animated stroke with gradient
-- ========================================
function ThemeModule.CreateAnimatedStroke(parent, thickness, gradientName, speed)
	local stroke = Instance.new("UIStroke")
	stroke.Name = "AnimatedStroke"
	stroke.Thickness = thickness or 2
	stroke.Color = ThemeModule.Colors.StrokeBase  -- FIXED: Set base color
	stroke.Transparency = 0  -- FIXED: Ensure visible
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

-- Create static stroke (no animation)
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

-- Create stroke with gradient (no animation)
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

	return stroke, gradient
end

-- Create UICorner
function ThemeModule.CreateCorner(parent, radius)
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, radius or 8)
	corner.Parent = parent
	return corner
end

-- ========================================
-- HELPER FUNCTIONS - APPLY
-- ========================================

-- Apply primary gradient to existing UIGradient
function ThemeModule.ApplyPrimaryGradient(uiGradient, rotation, speed)
	if not uiGradient then return end
	uiGradient.Color = ThemeModule.Gradients.Primary
	uiGradient.Rotation = rotation or 0
	ThemeModule.GradientSystem.Register(uiGradient, speed or 1)
end

-- Apply any gradient to existing UIGradient
function ThemeModule.ApplyGradient(uiGradient, gradientName, rotation, animated, speed)
	if not uiGradient then return end
	uiGradient.Color = ThemeModule.Gradients[gradientName] or ThemeModule.Gradients.Primary
	uiGradient.Rotation = rotation or 0
	if animated then
		ThemeModule.GradientSystem.Register(uiGradient, speed or 1)
	end
end

-- Apply background gradient
function ThemeModule.ApplyBackgroundGradient(uiGradient, rotation)
	if not uiGradient then return end
	uiGradient.Color = ThemeModule.Gradients.Background
	uiGradient.Rotation = rotation or 135
end

-- ========================================
-- HELPER FUNCTIONS - GET
-- ========================================

-- Get color by name
function ThemeModule.GetColor(name)
	return ThemeModule.Colors[name] or ThemeModule.Colors.TextWhite
end

-- Get gradient by name
function ThemeModule.GetGradient(name)
	return ThemeModule.Gradients[name] or ThemeModule.Gradients.Primary
end

-- Get primary colors
function ThemeModule.GetPrimaryColors()
	return ThemeModule.Colors.Primary1, ThemeModule.Colors.Primary2
end

-- ========================================
-- PRESET STYLES
-- ========================================
ThemeModule.Styles = {
	-- Button style
	Button = {
		BackgroundColor = ThemeModule.Colors.BackgroundMedium,
		TextColor = ThemeModule.Colors.TextWhite,
		CornerRadius = 8,
		Font = Enum.Font.GothamBold,
	},

	-- Card style
	Card = {
		BackgroundColor = ThemeModule.Colors.BackgroundDark,
		CornerRadius = 12,
	},

	-- Header style
	Header = {
		BackgroundColor = ThemeModule.Colors.BackgroundMedium,
		TextColor = ThemeModule.Colors.TextWhite,
		Height = 50,
		CornerRadius = 12,
	},

	-- Input style
	Input = {
		BackgroundColor = ThemeModule.Colors.BackgroundLight,
		TextColor = ThemeModule.Colors.TextWhite,
		PlaceholderColor = ThemeModule.Colors.TextMuted,
		CornerRadius = 6,
	},

	-- Toggle style
	Toggle = {
		BackgroundColorOff = ThemeModule.Colors.BackgroundLight,
		BackgroundColorOn = ThemeModule.Colors.Primary1,
		CornerRadius = 10,
	},
}

-- Apply style to instance
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

-- ========================================
-- THEME PRESETS (untuk ganti tema)
-- ========================================
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
	Primary1 = Color3.fromRGB(100, 255, 255),
	Primary2 = Color3.fromRGB(50, 200, 200),
}

ThemeModule.Presets.Pink = {
	Primary1 = Color3.fromRGB(255, 150, 200),
	Primary2 = Color3.fromRGB(255, 100, 150),
}

-- Apply theme preset
function ThemeModule.ApplyPreset(presetName)
	local preset = ThemeModule.Presets[presetName]
	if not preset then 
		warn("ThemeModule: Preset '" .. tostring(presetName) .. "' not found")
		return false
	end

	-- Update colors
	ThemeModule.Colors.Primary1 = preset.Primary1
	ThemeModule.Colors.Primary2 = preset.Primary2

	-- Update gradients
	ThemeModule.Gradients.Primary = ColorSequence.new({
		ColorSequenceKeypoint.new(0, preset.Primary1),
		ColorSequenceKeypoint.new(1, preset.Primary2)
	})

	ThemeModule.Gradients.PrimaryReversed = ColorSequence.new({
		ColorSequenceKeypoint.new(0, preset.Primary2),
		ColorSequenceKeypoint.new(1, preset.Primary1)
	})

	-- Update existing gradients
	for _, data in ipairs(ThemeModule.GradientSystem.Gradients) do
		if data.gradient and data.gradient.Parent then
			data.gradient.Color = ThemeModule.Gradients.Primary
		end
	end

	print("✅ ThemeModule: Applied preset '" .. presetName .. "'")
	return true
end

-- Get current preset colors
function ThemeModule.GetCurrentPrimaryColors()
	return ThemeModule.Colors.Primary1, ThemeModule.Colors.Primary2
end

-- ========================================
-- UTILITY FUNCTIONS
-- ========================================

-- Lerp between two colors
function ThemeModule.LerpColor(color1, color2, alpha)
	return Color3.new(
		color1.R + (color2.R - color1.R) * alpha,
		color1.G + (color2.G - color1.G) * alpha,
		color1.B + (color2.B - color1.B) * alpha
	)
end

-- Darken a color
function ThemeModule.DarkenColor(color, amount)
	amount = amount or 0.2
	return Color3.new(
		math.max(0, color.R - amount),
		math.max(0, color.G - amount),
		math.max(0, color.B - amount)
	)
end

-- Lighten a color
function ThemeModule.LightenColor(color, amount)
	amount = amount or 0.2
	return Color3.new(
		math.min(1, color.R + amount),
		math.min(1, color.G + amount),
		math.min(1, color.B + amount)
	)
end

-- Get contrasting text color (white or black)
function ThemeModule.GetContrastColor(backgroundColor)
	local luminance = 0.299 * backgroundColor.R + 0.587 * backgroundColor.G + 0.114 * backgroundColor.B
	if luminance > 0.5 then
		return Color3.new(0, 0, 0)  -- Dark text
	else
		return Color3.new(1, 1, 1)  -- Light text
	end
end

return ThemeModule
