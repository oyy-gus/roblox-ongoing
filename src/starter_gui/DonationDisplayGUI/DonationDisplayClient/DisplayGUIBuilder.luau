local DisplayGUIBuilder = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ThemeModule = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("ThemeModule"))
local UIStrings   = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("UIStrings"))

local C = ThemeModule.Colors

local CFG = {
	FRAME_WIDTH = 270,
	FRAME_HEIGHT = 86,
	CORNER_RADIUS = 10,
	AVATAR_SIZE = 42,
	AVATAR_BORDER = 2,
	ACCENT_WIDTH = 3,
	PADDING = 10,
	FONT = Enum.Font.GothamBold,
	FONT_BODY = Enum.Font.Gotham,
}

local function corner(radius, parent)
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, radius)
	c.Parent = parent
	return c
end

local function makeFrame(props)
	local f = Instance.new("Frame")
	f.Name = props.Name or "Frame"
	f.Size = props.Size or UDim2.new(0, 100, 0, 100)
	f.Position = props.Position or UDim2.new(0, 0, 0, 0)
	f.AnchorPoint = props.AnchorPoint or Vector2.new(0, 0)
	f.BackgroundColor3 = props.BG or C.BackgroundDark
	f.BackgroundTransparency = props.Transparency or 0
	f.BorderSizePixel = 0
	f.ZIndex = props.ZIndex or 1
	f.Visible = props.Visible ~= nil and props.Visible or true
	f.ClipsDescendants = props.Clips or false
	f.Parent = props.Parent
	if props.CornerRadius then corner(props.CornerRadius, f) end
	return f
end

local function makeLabel(props)
	local l = Instance.new("TextLabel")
	l.Name = props.Name or "Label"
	l.Size = props.Size or UDim2.new(1, 0, 0, 20)
	l.Position = props.Position or UDim2.new(0, 0, 0, 0)
	l.AnchorPoint = props.AnchorPoint or Vector2.new(0, 0)
	l.BackgroundTransparency = 1
	l.Text = props.Text or ""
	l.TextColor3 = props.Color or C.TextWhite
	l.TextSize = props.TextSize or UIStrings.TextSize.Caption
	l.Font = props.Font or CFG.FONT_BODY
	l.TextXAlignment = props.XAlign or Enum.TextXAlignment.Left
	l.TextYAlignment = props.YAlign or Enum.TextYAlignment.Center
	l.TextWrapped = props.Wrap or false
	l.TextTruncate = props.Truncate or Enum.TextTruncate.AtEnd
	l.RichText = props.RichText or false
	l.ZIndex = props.ZIndex or 1
	l.Parent = props.Parent
	return l
end

local function applyStroke(frame, thickness, gradientName, speed)
	ThemeModule.CreateAnimatedStroke(frame, thickness or 2, gradientName or "Primary", speed or 1.2)
end

function DisplayGUIBuilder.build(gui)
	if gui:FindFirstChild("Frame") then
		return {
			Frame = gui.Frame,
			nameLabel = gui.Frame:FindFirstChild("nameLabel"),
			infoLabel = gui.Frame:FindFirstChild("infoLabel"),
			typeLabel = gui.Frame:FindFirstChild("typeLabel"),
			avatarImage = gui.Frame:FindFirstChild("AvatarBorder") and gui.Frame.AvatarBorder:FindFirstChild("AvatarContainer") and gui.Frame.AvatarBorder.AvatarContainer:FindFirstChild("AvatarImage"),
		}
	end

	print("[DisplayGUIBuilder] 🏗️ Building Donation Display GUI...")

	local frame = makeFrame({
		Name = "Frame",
		Size = UDim2.new(0, CFG.FRAME_WIDTH, 0, CFG.FRAME_HEIGHT),
		Position = UDim2.new(1.3, 0, 1, -15),
		AnchorPoint = Vector2.new(1, 1),
		BG = C.BackgroundDark,
		CornerRadius = CFG.CORNER_RADIUS,
		Clips = true,
		ZIndex = 50,
		Visible = false,
		Parent = gui,
	})

	local accentBar = makeFrame({
		Name = "AccentBar",
		Size = UDim2.new(0, CFG.ACCENT_WIDTH, 1, -14),
		Position = UDim2.new(0, 8, 0.5, 0),
		AnchorPoint = Vector2.new(0, 0.5),
		BG = C.Primary1,
		CornerRadius = 2,
		ZIndex = 51,
		Parent = frame,
	})
	ThemeModule.CreateStaticGradient(accentBar, "Primary", 90)

	local avatarStartX = 8 + CFG.ACCENT_WIDTH + 8
	local avatarBorder = makeFrame({
		Name = "AvatarBorder",
		Size = UDim2.new(0, CFG.AVATAR_SIZE + CFG.AVATAR_BORDER * 2, 0, CFG.AVATAR_SIZE + CFG.AVATAR_BORDER * 2),
		Position = UDim2.new(0, avatarStartX, 0.5, 0),
		AnchorPoint = Vector2.new(0, 0.5),
		BG = C.Primary1,
		CornerRadius = (CFG.AVATAR_SIZE + CFG.AVATAR_BORDER * 2) / 2,
		ZIndex = 51,
		Parent = frame,
	})
	ThemeModule.CreateAnimatedGradient(avatarBorder, "Primary", 45, 1.5)

	local avatarContainer = makeFrame({
		Name = "AvatarContainer",
		Size = UDim2.new(0, CFG.AVATAR_SIZE, 0, CFG.AVATAR_SIZE),
		Position = UDim2.new(0.5, 0, 0.5, 0),
		AnchorPoint = Vector2.new(0.5, 0.5),
		BG = C.BackgroundMedium,
		CornerRadius = CFG.AVATAR_SIZE / 2,
		Clips = true,
		ZIndex = 52,
		Parent = avatarBorder,
	})

	local avatarImage = Instance.new("ImageLabel")
	avatarImage.Name = "AvatarImage"
	avatarImage.Size = UDim2.new(1, 0, 1, 0)
	avatarImage.Position = UDim2.new(0, 0, 0, 0)
	avatarImage.BackgroundTransparency = 1
	avatarImage.Image = ""
	avatarImage.ScaleType = Enum.ScaleType.Crop
	avatarImage.ZIndex = 53
	avatarImage.Parent = avatarContainer

	local fallbackIcon = makeLabel({
		Name = "FallbackIcon",
		Size = UDim2.new(1, 0, 1, 0),
		Text = "💝",
		TextSize = 20,
		Font = Enum.Font.GothamBold,
		Color = C.TextWhite,
		XAlign = Enum.TextXAlignment.Center,
		YAlign = Enum.TextYAlignment.Center,
		ZIndex = 52,
		Parent = avatarContainer,
	})

	local contentX = avatarStartX + CFG.AVATAR_SIZE + CFG.AVATAR_BORDER * 2 + 8
	local contentArea = makeFrame({
		Name = "ContentArea",
		Size = UDim2.new(1, -(contentX + 10), 1, -12),
		Position = UDim2.new(0, contentX, 0, 6),
		Transparency = 1,
		ZIndex = 51,
		Parent = frame,
	})

	local nameLabel = makeLabel({
		Name = "nameLabel",
		Size = UDim2.new(1, 0, 0, 20),
		Position = UDim2.new(0, 0, 0, 0),
		Text = "Player Name",
		TextSize = UIStrings.TextSize.Body,
		Font = CFG.FONT,
		Color = C.TextWhite,
		XAlign = Enum.TextXAlignment.Left,
		ZIndex = 52,
		Parent = contentArea,
	})
	ThemeModule.CreateAnimatedGradient(nameLabel, "Primary", 0, 1.2)

	local infoLabel = makeLabel({
		Name = "infoLabel",
		Size = UDim2.new(1, 0, 0, 18),
		Position = UDim2.new(0, 0, 0, 22),
		Text = "donated 100 Robux!",
		TextSize = UIStrings.TextSize.Caption,
		Font = CFG.FONT_BODY,
		Color = C.TextGray,
		XAlign = Enum.TextXAlignment.Left,
		ZIndex = 52,
		Parent = contentArea,
	})

	local typeLabel = makeLabel({
		Name = "typeLabel",
		Size = UDim2.new(1, 0, 0, 18),
		Position = UDim2.new(0, 0, 0, 42),
		Text = "Thank You!",
		TextSize = UIStrings.TextSize.Caption,
		Font = Enum.Font.GothamMedium,
		Color = C.Primary1,
		XAlign = Enum.TextXAlignment.Left,
		ZIndex = 52,
		Parent = contentArea,
	})

	applyStroke(frame, 1.5, "Primary", 1.5)

	print("[DisplayGUIBuilder] ✅ Donation Display GUI built!")

	return {
		Frame = frame,
		nameLabel = nameLabel,
		infoLabel = infoLabel,
		typeLabel = typeLabel,
		avatarImage = avatarImage,
		fallbackIcon = fallbackIcon,
		contentArea = contentArea,
	}
end

return DisplayGUIBuilder
