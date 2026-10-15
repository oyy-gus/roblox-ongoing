-- ========================================
-- MANAGE TITLE CLIENT
-- Place in: StarterGui > AdminGUI(ScreenGui) > ManageTitleClient(LocalScript)
-- Inject UI ke ManageTitlePage di admin panel
-- ========================================

local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService      = game:GetService("TweenService")

local Modules     = ReplicatedStorage:WaitForChild("Modules")
local AdminConfig = require(Modules:WaitForChild("AdminConfig"))
local ThemeModule = require(Modules:WaitForChild("ThemeModule"))

local player     = Players.LocalPlayer
local TitleEvent = ReplicatedStorage:WaitForChild("TitleEvent", 10)
if not TitleEvent then return end

AdminConfig.WaitForGUIReady()

local page = AdminConfig.GUI.ManageTitlePage
if not page then
	warn("[ManageTitleClient] ManageTitlePage not found")
	return
end

-- ========================================
-- STATE
-- ========================================
local currentTitles    = {}
local selectedPlayer   = ""

-- ========================================
-- HELPERS
-- ========================================
local function makeCorner(parent, radius)
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, radius)
	c.Parent = parent
end

local function makeButton(parent, text, gradientName, size, pos)
	local btn = Instance.new("TextButton")
	btn.Size             = size
	btn.Position         = pos
	btn.BackgroundColor3 = ThemeModule.Colors.BackgroundMedium
	btn.BorderSizePixel  = 0
	btn.Text             = text
	btn.TextColor3       = ThemeModule.Colors.TextWhite
	btn.TextSize         = 11
	btn.Font             = Enum.Font.GothamBold
	btn.AutoButtonColor  = false
	btn.Parent           = parent
	makeCorner(btn, 6)

	ThemeModule.CreateStaticGradient(btn, gradientName or "Primary", 90)

	btn.MouseEnter:Connect(function()
		TweenService:Create(btn, TweenInfo.new(0.15), { BackgroundTransparency = 0.1 }):Play()
	end)
	btn.MouseLeave:Connect(function()
		TweenService:Create(btn, TweenInfo.new(0.15), { BackgroundTransparency = 0 }):Play()
	end)
	return btn
end

-- ========================================
-- BUILD ROOT UI
-- ========================================

-- Main container dengan padding untuk stroke
local container = Instance.new("Frame")
container.Name               = "Container"
container.Size               = UDim2.new(1, 0, 1, 0)
container.BackgroundTransparency = 1
container.Active             = true
container.Parent             = page

local containerPad = Instance.new("UIPadding")
containerPad.PaddingTop    = UDim.new(0, 4)
containerPad.PaddingBottom = UDim.new(0, 4)
containerPad.PaddingLeft   = UDim.new(0, 4)
containerPad.PaddingRight  = UDim.new(0, 4)
containerPad.Parent        = container

-- Header bar
local headerBar = Instance.new("Frame")
headerBar.Name             = "HeaderBar"
headerBar.Size             = UDim2.new(1, 0, 0, 40)
headerBar.Position         = UDim2.new(0, 0, 0, 0)
headerBar.BackgroundColor3 = ThemeModule.Colors.BackgroundDark
headerBar.BorderSizePixel  = 0
headerBar.Parent           = container
makeCorner(headerBar, 8)
ThemeModule.CreateAnimatedStroke(headerBar, 1, "Primary", 1.2)

-- Inner padding untuk header content
local headerPad = Instance.new("UIPadding")
headerPad.PaddingTop    = UDim.new(0, 4)
headerPad.PaddingBottom = UDim.new(0, 4)
headerPad.PaddingLeft   = UDim.new(0, 6)
headerPad.PaddingRight  = UDim.new(0, 6)
headerPad.Parent        = headerBar

-- Player dropdown button
local playerDropBtn = Instance.new("TextButton")
playerDropBtn.Size             = UDim2.new(0.55, -4, 1, 0)
playerDropBtn.Position         = UDim2.new(0, 0, 0, 0)
playerDropBtn.BackgroundColor3 = ThemeModule.Colors.BackgroundMedium
playerDropBtn.BorderSizePixel  = 0
playerDropBtn.Text             = "  Select Player ▼"
playerDropBtn.TextColor3       = ThemeModule.Colors.TextMuted
playerDropBtn.TextSize         = 12
playerDropBtn.Font             = Enum.Font.GothamMedium
playerDropBtn.TextXAlignment   = Enum.TextXAlignment.Left
playerDropBtn.AutoButtonColor  = false
playerDropBtn.Parent           = headerBar
makeCorner(playerDropBtn, 6)
ThemeModule.CreateGradientStroke(playerDropBtn, 1, "Primary", 90)

-- Remove All button
local removeAllBtn = Instance.new("TextButton")
removeAllBtn.Size             = UDim2.new(0.45, -4, 1, 0)
removeAllBtn.Position         = UDim2.new(0.55, 4, 0, 0)
removeAllBtn.BackgroundColor3 = ThemeModule.Colors.BackgroundMedium
removeAllBtn.BorderSizePixel  = 0
removeAllBtn.Text             = "x Remove All"
removeAllBtn.TextColor3       = ThemeModule.Colors.TextWhite
removeAllBtn.TextSize         = 11
removeAllBtn.Font             = Enum.Font.GothamBold
removeAllBtn.AutoButtonColor  = false
removeAllBtn.Parent           = headerBar
makeCorner(removeAllBtn, 6)
ThemeModule.CreateStaticGradient(removeAllBtn, "Error", 90)

removeAllBtn.MouseEnter:Connect(function()
	TweenService:Create(removeAllBtn, TweenInfo.new(0.15), { BackgroundTransparency = 0.1 }):Play()
end)
removeAllBtn.MouseLeave:Connect(function()
	TweenService:Create(removeAllBtn, TweenInfo.new(0.15), { BackgroundTransparency = 0 }):Play()
end)

-- Dropdown list
local dropList = Instance.new("ScrollingFrame")
dropList.Name                 = "DropList"
dropList.Size                 = UDim2.new(0.55, -4, 0, 0)
dropList.Position             = UDim2.new(0, 0, 0, 44)
dropList.BackgroundColor3     = ThemeModule.Colors.BackgroundDark
dropList.BorderSizePixel      = 0
dropList.ScrollBarThickness   = 4
dropList.ScrollBarImageColor3 = ThemeModule.Colors.Primary1
dropList.ZIndex               = 20
dropList.Active               = true
dropList.Visible              = false
dropList.ClipsDescendants     = true
dropList.Parent               = container
makeCorner(dropList, 6)
ThemeModule.CreateAnimatedStroke(dropList, 1.5, "Primary", 1.5)

local dropLayout = Instance.new("UIListLayout")
dropLayout.Padding   = UDim.new(0, 2)
dropLayout.SortOrder = Enum.SortOrder.LayoutOrder
dropLayout.Parent    = dropList

local dropPad = Instance.new("UIPadding")
dropPad.PaddingTop    = UDim.new(0, 4)
dropPad.PaddingBottom = UDim.new(0, 4)
dropPad.PaddingLeft   = UDim.new(0, 4)
dropPad.PaddingRight  = UDim.new(0, 4)
dropPad.Parent        = dropList

-- Titles scroll list - dengan margin dari header
local titlesScroll = Instance.new("ScrollingFrame")
titlesScroll.Name                 = "TitlesScroll"
titlesScroll.Size                 = UDim2.new(1, 0, 1, -48)
titlesScroll.Position             = UDim2.new(0, 0, 0, 48)
titlesScroll.BackgroundTransparency = 1
titlesScroll.BorderSizePixel      = 0
titlesScroll.ScrollBarThickness   = 4
titlesScroll.ScrollBarImageColor3 = ThemeModule.Colors.Primary1
titlesScroll.ScrollingDirection   = Enum.ScrollingDirection.Y
titlesScroll.ElasticBehavior      = Enum.ElasticBehavior.Never
titlesScroll.Active               = true
titlesScroll.CanvasSize           = UDim2.new(0, 0, 0, 0)
titlesScroll.AutomaticCanvasSize  = Enum.AutomaticSize.Y
titlesScroll.Parent               = container

local titlesLayout = Instance.new("UIListLayout")
titlesLayout.Padding             = UDim.new(0, 6)
titlesLayout.FillDirection       = Enum.FillDirection.Vertical
titlesLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
titlesLayout.SortOrder           = Enum.SortOrder.LayoutOrder
titlesLayout.Parent              = titlesScroll

local titlesPad = Instance.new("UIPadding")
titlesPad.PaddingTop    = UDim.new(0, 2)
titlesPad.PaddingBottom = UDim.new(0, 4)
titlesPad.PaddingLeft   = UDim.new(0, 2)
titlesPad.PaddingRight  = UDim.new(0, 2)
titlesPad.Parent        = titlesScroll

-- ========================================
-- DROPDOWN LOGIC
-- ========================================
local currentPlayerList = {}

local function updateDropdown()
	for _, c in ipairs(dropList:GetChildren()) do
		if c:IsA("TextButton") or (c:IsA("TextLabel") and c.Name == "EmptyLabel") then 
			c:Destroy() 
		end
	end

	if #currentPlayerList == 0 then
		local empty = Instance.new("TextLabel")
		empty.Name               = "EmptyLabel"
		empty.Size               = UDim2.new(1, -8, 0, 30)
		empty.BackgroundTransparency = 1
		empty.Text               = "⚠️ No players online"
		empty.TextColor3         = ThemeModule.Colors.Error
		empty.TextSize           = 12
		empty.Font               = Enum.Font.GothamMedium
		empty.Parent             = dropList
		dropList.Size    = UDim2.new(0.55, -4, 0, 38)
		dropList.Visible = true
		return
	end

	for idx, name in ipairs(currentPlayerList) do
		local item = Instance.new("TextButton")
		item.Name             = "Player_" .. name
		item.Size             = UDim2.new(1, -8, 0, 30)
		item.BackgroundColor3 = ThemeModule.Colors.BackgroundMedium
		item.BorderSizePixel  = 0
		item.Text             = "  " .. name
		item.TextColor3       = ThemeModule.Colors.TextWhite
		item.TextSize         = 12
		item.Font             = Enum.Font.GothamMedium
		item.TextXAlignment   = Enum.TextXAlignment.Left
		item.AutoButtonColor  = false
		item.ZIndex           = 21
		item.LayoutOrder      = idx
		item.Parent           = dropList
		makeCorner(item, 4)

		item.MouseEnter:Connect(function()
			item.BackgroundColor3 = ThemeModule.Colors.BackgroundLighter
			for _, child in ipairs(item:GetChildren()) do
				if child:IsA("UIGradient") then child:Destroy() end
			end
			ThemeModule.CreateStaticGradient(item, "Primary", 90)
		end)
		item.MouseLeave:Connect(function()
			item.BackgroundColor3 = ThemeModule.Colors.BackgroundMedium
			for _, child in ipairs(item:GetChildren()) do
				if child:IsA("UIGradient") then child:Destroy() end
			end
			item.TextColor3 = ThemeModule.Colors.TextWhite
		end)

		item.MouseButton1Click:Connect(function()
			selectedPlayer = name
			playerDropBtn.Text = "  " .. name .. " ▼"
			playerDropBtn.TextColor3 = ThemeModule.Colors.TextWhite

			for _, child in ipairs(playerDropBtn:GetChildren()) do
				if child:IsA("UIGradient") then child:Destroy() end
			end
			ThemeModule.CreateStaticGradient(playerDropBtn, "Primary", 90)

			dropList.Visible = false

			if AdminConfig.CustomTitleUI then
				AdminConfig.CustomTitleUI.SetSelectedPlayer(name)
			end

			TitleEvent:FireServer("RequestPlayerTitles", name)
		end)
	end

	task.wait(0.05)
	local count = math.min(#currentPlayerList, 5)
	dropList.Size    = UDim2.new(0.55, -4, 0, count * 34 + 8)
	dropList.Visible = true
	dropList.CanvasSize = UDim2.new(0, 0, 0, dropLayout.AbsoluteContentSize.Y + 8)
end

playerDropBtn.MouseButton1Click:Connect(function()
	if dropList.Visible then
		dropList.Visible = false
		return
	end
	TitleEvent:FireServer("RequestPlayerList")
	task.wait(0.15)
	updateDropdown()
end)

-- ========================================
-- DISPLAY TITLES
-- ========================================
local function displayTitles(titles)
	for _, c in ipairs(titlesScroll:GetChildren()) do
		if not c:IsA("UIListLayout") and not c:IsA("UIPadding") then
			c:Destroy()
		end
	end

	local hasTitles = false
	for i = 1, 14 do
		if titles[i] and titles[i].Text and titles[i].Text ~= "" then
			hasTitles = true
			break
		end
	end

	if not hasTitles then
		local empty = Instance.new("Frame")
		empty.Size             = UDim2.new(1, -4, 0, 70)
		empty.BackgroundColor3 = ThemeModule.Colors.BackgroundDark
		empty.BorderSizePixel  = 0
		empty.Parent           = titlesScroll
		makeCorner(empty, 8)
		ThemeModule.CreateGradientStroke(empty, 1, "Primary", 45)

		local lbl = Instance.new("TextLabel")
		lbl.Size                 = UDim2.new(1, 0, 1, 0)
		lbl.BackgroundTransparency = 1
		lbl.Text                 = "📭  No custom titles for this player"
		lbl.TextColor3           = ThemeModule.Colors.TextGray
		lbl.TextSize             = 13
		lbl.Font                 = Enum.Font.GothamMedium
		lbl.Parent               = empty
		return
	end

	for slotNum = 1, 14 do
		local titleInfo = titles[slotNum]
		if not (titleInfo and titleInfo.Text and titleInfo.Text ~= "") then continue end

		local card = Instance.new("Frame")
		card.Name             = "Card_" .. slotNum
		card.Size             = UDim2.new(1, -4, 0, 88)
		card.BackgroundColor3 = ThemeModule.Colors.BackgroundDark
		card.BorderSizePixel  = 0
		card.LayoutOrder      = slotNum
		card.Parent           = titlesScroll
		makeCorner(card, 8)
		ThemeModule.CreateGradientStroke(card, 1, "Primary", 45)

		-- Slot badge
		local slotBadge = Instance.new("Frame")
		slotBadge.Size             = UDim2.new(0, 54, 0, 22)
		slotBadge.Position         = UDim2.new(0, 10, 0, 10)
		slotBadge.BackgroundColor3 = ThemeModule.Colors.BackgroundMedium
		slotBadge.BorderSizePixel  = 0
		slotBadge.Parent           = card
		makeCorner(slotBadge, 5)
		ThemeModule.CreateStaticGradient(slotBadge, "Primary", 90)

		local slotLbl = Instance.new("TextLabel")
		slotLbl.Size                 = UDim2.new(1, 0, 1, 0)
		slotLbl.BackgroundTransparency = 1
		slotLbl.Text                 = "SLOT " .. slotNum
		slotLbl.TextColor3           = ThemeModule.Colors.TextWhite
		slotLbl.TextSize             = 10
		slotLbl.Font                 = Enum.Font.GothamBold
		slotLbl.Parent               = slotBadge

		-- Title text
		local titleLbl = Instance.new("TextLabel")
		titleLbl.Size             = UDim2.new(1, -140, 0, 26)
		titleLbl.Position         = UDim2.new(0, 10, 0, 36)
		titleLbl.BackgroundTransparency = 1
		titleLbl.Text             = titleInfo.Text
		titleLbl.TextColor3       = ThemeModule.Colors.TextWhite
		titleLbl.TextSize         = 15
		titleLbl.Font             = Enum.Font.GothamBold
		titleLbl.TextXAlignment   = Enum.TextXAlignment.Left
		titleLbl.TextTruncate     = Enum.TextTruncate.AtEnd
		titleLbl.Parent           = card
		ThemeModule.CreatePrimaryGradient(titleLbl, 90, 1.5)

		-- Info line
		local infoLbl = Instance.new("TextLabel")
		infoLbl.Size             = UDim2.new(1, -140, 0, 18)
		infoLbl.Position         = UDim2.new(0, 10, 0, 64)
		infoLbl.BackgroundTransparency = 1
		infoLbl.Text             = string.format("Mode: %s  |  Color: %s  |  Font: %s",
			(titleInfo.Mode or "fixed"):upper(),
			titleInfo.ColorTemplate or "White",
			titleInfo.Font or "Gotham")
		infoLbl.TextColor3       = ThemeModule.Colors.TextMuted
		infoLbl.TextSize         = 10
		infoLbl.Font             = Enum.Font.GothamMedium
		infoLbl.TextXAlignment   = Enum.TextXAlignment.Left
		infoLbl.TextTruncate     = Enum.TextTruncate.AtEnd
		infoLbl.Parent           = card

		-- Edit button
		local editBtn = makeButton(card, "✏️ Edit", "Warning",
			UDim2.new(0, 56, 0, 26),
			UDim2.new(1, -124, 0, 10))
		editBtn.TextSize = 10

		-- Remove button - dengan x
		local removeBtn = makeButton(card, "x Delete", "Error",
			UDim2.new(0, 54, 0, 26),
			UDim2.new(1, -64, 0, 10))
		removeBtn.TextSize = 10

		editBtn.MouseButton1Click:Connect(function()
			if AdminConfig.CustomTitleUI then
				AdminConfig.CustomTitleUI.SetEditMode(slotNum, titleInfo)
				AdminConfig.CustomTitleUI.SetSelectedPlayer(selectedPlayer)
			end
		end)

		removeBtn.MouseButton1Click:Connect(function()
			TweenService:Create(card, TweenInfo.new(0.2), { 
				BackgroundTransparency = 0.5 
			}):Play()
			task.wait(0.2)
			TitleEvent:FireServer("RemoveTitleSlot", selectedPlayer, slotNum)
			task.wait(0.3)
			TitleEvent:FireServer("RequestPlayerTitles", selectedPlayer)
		end)
	end
end

-- ========================================
-- REMOVE ALL
-- ========================================
removeAllBtn.MouseButton1Click:Connect(function()
	if selectedPlayer == "" then
		AdminConfig.ShowNotification("Please select a player first", "warning")
		return
	end
	TitleEvent:FireServer("RemoveAllTitles", selectedPlayer)
	AdminConfig.ShowNotification("All titles removed for " .. selectedPlayer, "success")
	task.wait(0.3)
	TitleEvent:FireServer("RequestPlayerTitles", selectedPlayer)
end)

-- ========================================
-- SERVER EVENTS
-- ========================================
TitleEvent.OnClientEvent:Connect(function(action, data)
	if action == "PlayerList" then
		currentPlayerList = data or {}
	elseif action == "PlayerTitles" then
		currentTitles = data or {}
		displayTitles(currentTitles)
	end
end)

AdminConfig.Events.OnTabChanged.Event:Connect(function(tabName)
	if tabName == "ManageTitle" and selectedPlayer ~= "" then
		TitleEvent:FireServer("RequestPlayerTitles", selectedPlayer)
	end
end)

print("✅ [ManageTitleClient] Loaded!")
