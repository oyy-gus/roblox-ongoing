--[[
	SearchBar.lua
	Tujuan: Kolom pencarian lagu — tema ungu neon dengan border glow saat fokus.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Config = require(ReplicatedStorage.Shared.Config)
local Theme = require(ReplicatedStorage.Shared.Theme)
local UIStrings = require(ReplicatedStorage.Shared.UIStrings)

local SearchBar = {}
SearchBar.__index = SearchBar

function SearchBar.new(onSearchSubmitted)
	local self = setmetatable({}, SearchBar)

	local container = Instance.new("Frame")
	container.Name = "SearchBarContainer"
	container.Size = UDim2.new(1, 0, 0, 34)
	container.BackgroundColor3 = Theme.Colors.Surface
	container.BorderSizePixel = 0

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, Theme.Dimensions.CornerRadiusSmall)
	corner.Parent = container

	local stroke = Instance.new("UIStroke")
	stroke.Color = Theme.Colors.Stroke
	stroke.Thickness = 1
	stroke.Parent = container

	-- Ikon pencarian
	local icon = Instance.new("TextLabel")
	icon.Name = "SearchIcon"
	icon.Size = UDim2.new(0, 28, 1, 0)
	icon.Position = UDim2.new(0, 4, 0, 0)
	icon.BackgroundTransparency = 1
	icon.Text = "🔍"
	icon.TextColor3 = Theme.Colors.TextMuted
	icon.Font = Theme.Fonts.Body
	icon.TextSize = Theme.TextSizes.Body
	icon.TextXAlignment = Enum.TextXAlignment.Center
	icon.Parent = container

	local textBox = Instance.new("TextBox")
	textBox.Name = "InputBox"
	textBox.Size = UDim2.new(1, -40, 1, 0)
	textBox.Position = UDim2.new(0, 34, 0, 0)
	textBox.BackgroundTransparency = 1
	textBox.PlaceholderText = UIStrings.Music.SearchPlaceholder
	textBox.PlaceholderColor3 = Theme.Colors.TextSubtle
	textBox.Text = ""
	textBox.TextColor3 = Theme.Colors.Text
	textBox.Font = Theme.Fonts.Body
	textBox.TextSize = Theme.TextSizes.Body
	textBox.TextXAlignment = Enum.TextXAlignment.Left
	textBox.ClearTextOnFocus = false
	textBox.Parent = container

	-- Glow saat fokus
	textBox.Focused:Connect(function()
		TweenService:Create(stroke, TweenInfo.new(Theme.Animation.Fast), {
			Color = Theme.Colors.Primary,
			Thickness = 1.5,
		}):Play()
		TweenService:Create(container, TweenInfo.new(Theme.Animation.Fast), {
			BackgroundColor3 = Theme.Colors.SurfaceHover,
		}):Play()
	end)
	textBox.FocusLost:Connect(function()
		TweenService:Create(stroke, TweenInfo.new(Theme.Animation.Fast), {
			Color = Theme.Colors.Stroke,
			Thickness = 1,
		}):Play()
		TweenService:Create(container, TweenInfo.new(Theme.Animation.Fast), {
			BackgroundColor3 = Theme.Colors.Surface,
		}):Play()
	end)

	self.Instance = container
	self.TextBox = textBox
	self.OnSearchSubmitted = onSearchSubmitted

	local searchTimer = nil
	textBox:GetPropertyChangedSignal("Text"):Connect(function()
		if searchTimer then
			task.cancel(searchTimer)
		end
		searchTimer = task.delay(Config.SEARCH_DEBOUNCE, function()
			if self.OnSearchSubmitted then
				self.OnSearchSubmitted(textBox.Text)
			end
		end)
	end)

	return self
end

function SearchBar:Destroy()
	if self.Instance then
		self.Instance:Destroy()
		self.Instance = nil
	end
end

return SearchBar
