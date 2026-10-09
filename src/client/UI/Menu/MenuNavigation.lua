--[[
	MenuNavigation.lua — Hitam-putih, tab aktif putih dengan teks hitam.
]]

local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Theme = require(ReplicatedStorage.Shared.Theme)
local UIStrings = require(ReplicatedStorage.Shared.UIStrings)

local MenuNavigation = {}
MenuNavigation.__index = MenuNavigation

function MenuNavigation.new(onTabSelected)
	local self = setmetatable({}, MenuNavigation)

	local container = Instance.new("Frame")
	container.Name = "MenuNavigation"
	container.Size = UDim2.new(1, 0, 0, 30)
	container.BackgroundColor3 = Theme.Colors.CardBackground
	container.BorderSizePixel = 0

	local cCorner = Instance.new("UICorner")
	cCorner.CornerRadius = UDim.new(0, 6)
	cCorner.Parent = container

	local cStroke = Instance.new("UIStroke")
	cStroke.Color = Theme.Colors.Stroke
	cStroke.Thickness = 1
	cStroke.Parent = container

	local layout = Instance.new("UIListLayout")
	layout.FillDirection = Enum.FillDirection.Horizontal
	layout.HorizontalAlignment = Enum.HorizontalAlignment.Left
	layout.VerticalAlignment = Enum.VerticalAlignment.Center
	layout.Padding = UDim.new(0, 4)
	layout.Parent = container

	local pad = Instance.new("UIPadding")
	pad.PaddingLeft = UDim.new(0, 5)
	pad.PaddingTop = UDim.new(0, 3)
	pad.PaddingBottom = UDim.new(0, 3)
	pad.Parent = container

	local tabMusic = Instance.new("TextButton")
	tabMusic.Name = "Tab_Music"
	tabMusic.Size = UDim2.new(0, 110, 1, 0)
	tabMusic.BackgroundColor3 = Theme.Colors.Primary
	tabMusic.BorderSizePixel = 0
	tabMusic.Text = UIStrings.Menu.TabMusic
	tabMusic.TextColor3 = Theme.Colors.TextDark
	tabMusic.Font = Theme.Fonts.Header
	tabMusic.TextSize = Theme.TextSizes.Body
	tabMusic.AutoButtonColor = false

	local tabCorner = Instance.new("UICorner")
	tabCorner.CornerRadius = UDim.new(0, 5)
	tabCorner.Parent = tabMusic

	tabMusic.MouseButton1Click:Connect(function()
		if onTabSelected then onTabSelected("Music") end
	end)
	tabMusic.Parent = container

	self.Instance = container
	self.TabMusic = tabMusic
	return self
end

function MenuNavigation:Destroy()
	if self.Instance then self.Instance:Destroy() end
end

return MenuNavigation
