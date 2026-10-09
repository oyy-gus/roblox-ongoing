--[[
	QueueList.lua — Antrean lagu, hitam-putih bersih.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Theme = require(ReplicatedStorage.Shared.Theme)
local UIStrings = require(ReplicatedStorage.Shared.UIStrings)
local TitleCleaner = require(ReplicatedStorage.Shared.Utils.TitleCleaner)

local QueueList = {}
QueueList.__index = QueueList

function QueueList.new()
	local self = setmetatable({}, QueueList)

	local container = Instance.new("Frame")
	container.Name = "QueueListContainer"
	container.Size = UDim2.new(1, 0, 1, 0)
	container.BackgroundColor3 = Theme.Colors.CardBackground
	container.BorderSizePixel = 0

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, Theme.Dimensions.CornerRadius)
	corner.Parent = container

	local stroke = Instance.new("UIStroke")
	stroke.Color = Theme.Colors.Stroke
	stroke.Thickness = 1
	stroke.Parent = container

	-- Header
	local hdr = Instance.new("Frame")
	hdr.Size = UDim2.new(1, 0, 0, 26)
	hdr.BackgroundColor3 = Theme.Colors.Surface
	hdr.BorderSizePixel = 0
	hdr.Parent = container

	local hCorner = Instance.new("UICorner")
	hCorner.CornerRadius = UDim.new(0, Theme.Dimensions.CornerRadius)
	hCorner.Parent = hdr

	local hFix = Instance.new("Frame")
	hFix.Size = UDim2.new(1, 0, 0, 8)
	hFix.Position = UDim2.new(0, 0, 1, -8)
	hFix.BackgroundColor3 = Theme.Colors.Surface
	hFix.BorderSizePixel = 0
	hFix.Parent = hdr

	local hLbl = Instance.new("TextLabel")
	hLbl.Size = UDim2.new(1, -8, 1, 0)
	hLbl.Position = UDim2.new(0, 8, 0, 0)
	hLbl.BackgroundTransparency = 1
	hLbl.Text = "📜 " .. UIStrings.Music.Queue
	hLbl.TextColor3 = Theme.Colors.Text
	hLbl.Font = Theme.Fonts.Header
	hLbl.TextSize = Theme.TextSizes.Header
	hLbl.TextXAlignment = Enum.TextXAlignment.Left
	hLbl.Parent = hdr

	-- Scroll
	local scroll = Instance.new("ScrollingFrame")
	scroll.Name = "QueueScroll"
	scroll.Size = UDim2.new(1, -12, 1, -30)
	scroll.Position = UDim2.new(0, 6, 0, 28)
	scroll.BackgroundTransparency = 1
	scroll.BorderSizePixel = 0
	scroll.ScrollBarThickness = 3
	scroll.ScrollBarImageColor3 = Theme.Colors.StrokeHighlight
	scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
	scroll.CanvasSize = UDim2.new(0,0,0,0)
	scroll.Parent = container

	local layout = Instance.new("UIListLayout")
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Padding = UDim.new(0, 4)
	layout.Parent = scroll

	layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
		scroll.CanvasSize = UDim2.new(0,0,0, layout.AbsoluteContentSize.Y + 4)
	end)

	self.Instance = container
	self.Scroll = scroll
	return self
end

function QueueList:Update(queueData)
	if self.LastQueueData == queueData then return end
	self.LastQueueData = queueData

	for _, c in ipairs(self.Scroll:GetChildren()) do
		if c:IsA("Frame") or c:IsA("TextLabel") then c:Destroy() end
	end

	if not queueData or #queueData == 0 then
		local lbl = Instance.new("TextLabel")
		lbl.Size = UDim2.new(1, 0, 0, 60)
		lbl.BackgroundTransparency = 1
		lbl.Text = UIStrings.Music.EmptyQueue
		lbl.TextColor3 = Theme.Colors.TextSubtle
		lbl.Font = Theme.Fonts.Body
		lbl.TextSize = Theme.TextSizes.Small
		lbl.TextWrapped = true
		lbl.TextXAlignment = Enum.TextXAlignment.Center
		lbl.Parent = self.Scroll
		return
	end

	for idx, item in ipairs(queueData) do
		local row = Instance.new("Frame")
		row.Name = "Q_" .. idx
		row.Size = UDim2.new(1, -2, 0, 40)
		row.BackgroundColor3 = Theme.Colors.Surface
		row.BorderSizePixel = 0

		local rc = Instance.new("UICorner")
		rc.CornerRadius = UDim.new(0, 5)
		rc.Parent = row

		local rs = Instance.new("UIStroke")
		rs.Color = Theme.Colors.Stroke
		rs.Thickness = 1
		rs.Transparency = 0.5
		rs.Parent = row

		-- Badge nomor
		local badge = Instance.new("Frame")
		badge.Size = UDim2.new(0, 24, 0, 18)
		badge.Position = UDim2.new(0, 7, 0.5, -9)
		badge.BackgroundColor3 = Theme.Colors.SurfaceHover
		badge.BorderSizePixel = 0

		local bc = Instance.new("UICorner")
		bc.CornerRadius = UDim.new(0, 3)
		bc.Parent = badge

		local badgeLbl = Instance.new("TextLabel")
		badgeLbl.Size = UDim2.new(1, 0, 1, 0)
		badgeLbl.BackgroundTransparency = 1
		badgeLbl.Text = tostring(idx)
		badgeLbl.TextColor3 = Theme.Colors.Text
		badgeLbl.Font = Theme.Fonts.Header
		badgeLbl.TextSize = Theme.TextSizes.Small
		badgeLbl.TextXAlignment = Enum.TextXAlignment.Center
		badgeLbl.Parent = badge
		badge.Parent = row

		-- Info
		local info = Instance.new("Frame")
		info.Size = UDim2.new(1, -40, 1, 0)
		info.Position = UDim2.new(0, 36, 0, 0)
		info.BackgroundTransparency = 1
		info.Parent = row

		local t = Instance.new("TextLabel")
		t.Size = UDim2.new(1, 0, 0, 20)
		t.Position = UDim2.new(0, 0, 0, 3)
		t.BackgroundTransparency = 1
		t.Text = TitleCleaner.CleanTitle(item.title)
		t.TextColor3 = Theme.Colors.Text
		t.Font = Theme.Fonts.Header
		t.TextSize = Theme.TextSizes.Body
		t.TextTruncate = Enum.TextTruncate.AtEnd
		t.TextXAlignment = Enum.TextXAlignment.Left
		t.Parent = info

		local r = Instance.new("TextLabel")
		r.Size = UDim2.new(1, 0, 0, 13)
		r.Position = UDim2.new(0, 0, 0, 24)
		r.BackgroundTransparency = 1
		r.Text = string.format(UIStrings.Music.RequestedBy, item.requestedBy or "Sistem")
		r.TextColor3 = Theme.Colors.TextSubtle
		r.Font = Theme.Fonts.Body
		r.TextSize = Theme.TextSizes.Small
		r.TextTruncate = Enum.TextTruncate.AtEnd
		r.TextXAlignment = Enum.TextXAlignment.Left
		r.Parent = info

		row.Parent = self.Scroll
	end
end

function QueueList:Destroy()
	if self.Instance then self.Instance:Destroy() end
end

return QueueList
