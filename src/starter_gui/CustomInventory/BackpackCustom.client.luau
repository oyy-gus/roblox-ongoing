local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local ContextActionService = game:GetService("ContextActionService")
local StarterGui = game:GetService("StarterGui")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Modules = ReplicatedStorage:WaitForChild("Modules")
local ThemeModule = require(Modules:WaitForChild("ThemeModule"))
local UIStrings = require(Modules:WaitForChild("UIStrings"))
local AutoScaleSystem = ReplicatedStorage:WaitForChild("AutoScaleSystem")
local ScaleSystem = require(AutoScaleSystem:WaitForChild("ScaleSystem"))

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local mouse = player:GetMouse()
local camera = workspace.CurrentCamera

StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Backpack, false)

local SETTINGS = {
	MAX_HOTBAR_SLOTS = 5,
	MAX_TOTAL_SLOTS = 9,
	SLOT_SIZE = 36,
	SLOT_PADDING = 4,
	HOTBAR_INNER_PADDING = 5,

	SLOT_COLOR = Color3.fromHex("#1C1C1C"),
	SLOT_HOVER_COLOR = Color3.fromHex("#262626"),
	SLOT_EQUIPPED_COLOR = Color3.fromHex("#FFFFFF"),
	SLOT_DISABLED_COLOR = Color3.fromHex("#121212"),
	SLOT_DROP_TARGET_COLOR = Color3.fromHex("#A0A0A0"),
	SLOT_STROKE_COLOR = Color3.fromHex("#353535"),
	HOTBAR_BG_COLOR = Color3.fromHex("#080808"),
	INVENTORY_BG_COLOR = Color3.fromHex("#151515"),
	TEXT_COLOR = Color3.fromHex("#FFFFFF"),
	ACCENT_COLOR = Color3.fromHex("#FFFFFF"),
	ACCENT_COLOR_2 = Color3.fromHex("#888888"),

	INVENTORY_KEYBIND = Enum.KeyCode.Tab,
	SCROLL_HOTBAR_WITH_WHEEL = true,
	ALWAYS_SHOW_TOOL_NAME = false,
	EQUIP_TOUCH_SENSITIVITY = 60,

	TWEEN_SPEED = 0.2,
}

local State = {
	hotbarTools = {},
	inventoryTools = {},
	currentlyEquipped = nil,
	inventoryOpen = false,
	slotsLocked = false,
	boundTools = {},
	isDragging = false,
	draggedObject = nil,
	dragFrame = nil,
	dragStartPos = nil,
}

local EnumKeys = {
	Enum.KeyCode.One,
	Enum.KeyCode.Two,
	Enum.KeyCode.Three,
	Enum.KeyCode.Four,
	Enum.KeyCode.Five,
	Enum.KeyCode.Six,
	Enum.KeyCode.Seven,
	Enum.KeyCode.Eight,
	Enum.KeyCode.Nine,
}

local screenGui = playerGui:WaitForChild("CustomInventory")
local guiScaler = ScaleSystem.new(screenGui)

local function addCorner(parent, radius)
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, radius or 5)
	corner.Parent = parent
	return corner
end

local function addStroke(parent, color, thickness, transparency)
	local stroke = Instance.new("UIStroke")
	stroke.Color = color or Color3.fromRGB(255, 255, 255)
	stroke.Thickness = thickness or 1
	stroke.Transparency = transparency or 0.5
	stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	stroke.Parent = parent
	return stroke
end

local function addGradient(parent, color1, color2, rotation)
	local gradient = Instance.new("UIGradient")
	gradient.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, color1),
		ColorSequenceKeypoint.new(1, color2)
	})
	gradient.Rotation = rotation or 90
	gradient.Parent = parent
	ThemeModule.GradientSystem.Register(gradient, 1)
	return gradient
end

local function tweenProperty(object, properties, duration, style, direction)
	local tween = TweenService:Create(
		object,
		TweenInfo.new(duration or SETTINGS.TWEEN_SPEED, style or Enum.EasingStyle.Quad, direction or Enum.EasingDirection.Out),
		properties
	)
	tween:Play()
	return tween
end

local function isUserTyping()
	return UserInputService:GetFocusedTextBox() ~= nil
end

local INVENTORY_WIDTH = 260
local INVENTORY_HEIGHT = 115
local INVENTORY_GAP = 8

local hotbarFrame = Instance.new("Frame")
hotbarFrame.Name = "HotbarFrame"
hotbarFrame.AnchorPoint = Vector2.new(0.5, 1)
hotbarFrame.Position = UDim2.new(0.5, 0, 1, -6)
hotbarFrame.Size = UDim2.new(0, 60, 0, SETTINGS.SLOT_SIZE + SETTINGS.HOTBAR_INNER_PADDING * 2)
hotbarFrame.BackgroundColor3 = SETTINGS.HOTBAR_BG_COLOR
hotbarFrame.BackgroundTransparency = 0.1
hotbarFrame.BorderSizePixel = 0
hotbarFrame.ClipsDescendants = true
hotbarFrame.Visible = false
hotbarFrame.Parent = screenGui

addCorner(hotbarFrame, 8)
local hotbarStroke = addStroke(hotbarFrame, SETTINGS.ACCENT_COLOR, 1, 0.6)
addGradient(hotbarStroke, SETTINGS.ACCENT_COLOR, SETTINGS.ACCENT_COLOR_2, 45)

local hotbarContainer = Instance.new("Frame")
hotbarContainer.Name = "SlotsContainer"
hotbarContainer.Size = UDim2.new(1, -SETTINGS.HOTBAR_INNER_PADDING * 2, 1, -SETTINGS.HOTBAR_INNER_PADDING * 2)
hotbarContainer.Position = UDim2.new(0.5, 0, 0.5, 0)
hotbarContainer.AnchorPoint = Vector2.new(0.5, 0.5)
hotbarContainer.BackgroundTransparency = 1
hotbarContainer.ClipsDescendants = false
hotbarContainer.Parent = hotbarFrame

local hotbarLayout = Instance.new("UIListLayout")
hotbarLayout.Name = "Layout"
hotbarLayout.FillDirection = Enum.FillDirection.Horizontal
hotbarLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
hotbarLayout.VerticalAlignment = Enum.VerticalAlignment.Center
hotbarLayout.Padding = UDim.new(0, SETTINGS.SLOT_PADDING)
hotbarLayout.SortOrder = Enum.SortOrder.LayoutOrder
hotbarLayout.Parent = hotbarContainer

local openBtn = Instance.new("TextButton")
openBtn.Name = "OpenBackpackBtn"
openBtn.Size = UDim2.new(0, 50, 0, 18)
openBtn.AnchorPoint = Vector2.new(0.5, 0)
openBtn.Position = UDim2.new(0.5, 0, 1, -67)
openBtn.BackgroundTransparency = 1
openBtn.Text = "^"
openBtn.TextColor3 = Color3.fromHex("#A0A0A0")
openBtn.TextSize = 12
openBtn.Font = Enum.Font.GothamBold
openBtn.AutoButtonColor = false
openBtn.ZIndex = 5
openBtn.Visible = false
openBtn.Parent = screenGui
UIStrings.LockTextSize(openBtn, 12)

openBtn.MouseEnter:Connect(function()
	tweenProperty(openBtn, {TextColor3 = SETTINGS.ACCENT_COLOR}, 0.15)
end)
openBtn.MouseLeave:Connect(function()
	tweenProperty(openBtn, {TextColor3 = Color3.fromHex("#A0A0A0")}, 0.15)
end)

local function getTotalToolCount()
	local hotbarCount = 0
	local inventoryCount = 0

	for _ in pairs(State.hotbarTools) do
		hotbarCount = hotbarCount + 1
	end

	for _ in pairs(State.inventoryTools) do
		inventoryCount = inventoryCount + 1
	end

	return hotbarCount + inventoryCount, hotbarCount, inventoryCount
end

local function updateVisibility()
	local totalTools, hotbarCount, inventoryCount = getTotalToolCount()

	if totalTools == 0 then
		hotbarFrame.Visible = false
		openBtn.Visible = false

		if State.inventoryOpen then
			State.inventoryOpen = false
			inventoryFrame.Visible = false
		end
	else
		if hotbarCount > 0 then
			hotbarFrame.Visible = true
		else
			hotbarFrame.Visible = false
		end

		if inventoryCount > 0 and not State.inventoryOpen then
			openBtn.Visible = true
		elseif inventoryCount == 0 then
			openBtn.Visible = false
		end
	end
end

local function updateHotbarSize()
	local slotCount = 0
	for _, child in ipairs(hotbarContainer:GetChildren()) do
		if child:IsA("Frame") and child.Visible then
			slotCount = slotCount + 1
		end
	end

	updateVisibility()

	if slotCount == 0 then
		return
	end

	local slotsWidth = (SETTINGS.SLOT_SIZE * slotCount) + (SETTINGS.SLOT_PADDING * math.max(0, slotCount - 1))
	local totalWidth = slotsWidth + (SETTINGS.HOTBAR_INNER_PADDING * 2)
	local totalHeight = SETTINGS.SLOT_SIZE + (SETTINGS.HOTBAR_INNER_PADDING * 2)

	tweenProperty(hotbarFrame, {
		Size = UDim2.new(0, totalWidth, 0, totalHeight)
	}, 0.25, Enum.EasingStyle.Back)
end

hotbarLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
	task.defer(updateHotbarSize)
end)

local inventoryFrame = Instance.new("Frame")
inventoryFrame.Name = "InventoryPanel"
inventoryFrame.AnchorPoint = Vector2.new(0.5, 1)
inventoryFrame.Position = UDim2.new(0.5, 0, 1, -(SETTINGS.SLOT_SIZE + SETTINGS.HOTBAR_INNER_PADDING * 2 + 6 + INVENTORY_GAP))
inventoryFrame.Size = UDim2.new(0, INVENTORY_WIDTH, 0, INVENTORY_HEIGHT)
inventoryFrame.BackgroundColor3 = SETTINGS.INVENTORY_BG_COLOR
inventoryFrame.BackgroundTransparency = 0.05
inventoryFrame.BorderSizePixel = 0
inventoryFrame.Visible = false
inventoryFrame.ClipsDescendants = true
inventoryFrame.ZIndex = 2
inventoryFrame.Parent = screenGui

addCorner(inventoryFrame, 8)
local invStroke = addStroke(inventoryFrame, SETTINGS.ACCENT_COLOR, 1, 0.4)
addGradient(invStroke, SETTINGS.ACCENT_COLOR, SETTINGS.ACCENT_COLOR_2, 45)

local invHeader = Instance.new("Frame")
invHeader.Name = "Header"
invHeader.Size = UDim2.new(1, 0, 0, 24)
invHeader.BackgroundColor3 = Color3.fromHex("#1C1C1C")
invHeader.BorderSizePixel = 0
invHeader.ClipsDescendants = true
invHeader.ZIndex = 3
invHeader.Parent = inventoryFrame

local headerCorner = Instance.new("UICorner")
headerCorner.CornerRadius = UDim.new(0, 8)
headerCorner.Parent = invHeader

local headerCover = Instance.new("Frame")
headerCover.Size = UDim2.new(1, 0, 0, 10)
headerCover.Position = UDim2.new(0, 0, 1, -10)
headerCover.BackgroundColor3 = Color3.fromHex("#1C1C1C")
headerCover.BorderSizePixel = 0
headerCover.ZIndex = 3
headerCover.Parent = invHeader

local invTitle = Instance.new("TextLabel")
invTitle.Name = "Title"
invTitle.Size = UDim2.new(0, 50, 1, 0)
invTitle.Position = UDim2.new(0, 8, 0, 0)
invTitle.BackgroundTransparency = 1
invTitle.Text = "Tas"
invTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
invTitle.TextSize = 11
invTitle.Font = Enum.Font.GothamBold
invTitle.TextXAlignment = Enum.TextXAlignment.Left
invTitle.ZIndex = 4
invTitle.Parent = invHeader
UIStrings.LockTextSize(invTitle, 11)

addGradient(invTitle, SETTINGS.ACCENT_COLOR, SETTINGS.ACCENT_COLOR_2, 0)

local searchContainer = Instance.new("Frame")
searchContainer.Name = "SearchContainer"
searchContainer.Size = UDim2.new(0, 90, 0, 18)
searchContainer.Position = UDim2.new(0.5, 0, 0.5, 0)
searchContainer.AnchorPoint = Vector2.new(0.5, 0.5)
searchContainer.BackgroundColor3 = Color3.fromHex("#262626")
searchContainer.ZIndex = 4
searchContainer.Parent = invHeader

addCorner(searchContainer, 4)

local searchPlaceholder = Instance.new("TextLabel")
searchPlaceholder.Name = "Placeholder"
searchPlaceholder.Size = UDim2.new(1, -16, 1, 0)
searchPlaceholder.Position = UDim2.new(0, 8, 0, 0)
searchPlaceholder.BackgroundTransparency = 1
searchPlaceholder.Text = "Cari..."
searchPlaceholder.TextColor3 = Color3.fromHex("#777777")
searchPlaceholder.TextSize = 9
searchPlaceholder.Font = Enum.Font.Gotham
searchPlaceholder.TextXAlignment = Enum.TextXAlignment.Left
searchPlaceholder.ZIndex = 5
searchPlaceholder.Parent = searchContainer
UIStrings.LockTextSize(searchPlaceholder, 9)

local searchBox = Instance.new("TextBox")
searchBox.Name = "SearchBox"
searchBox.Size = UDim2.new(1, -16, 1, 0)
searchBox.Position = UDim2.new(0, 8, 0, 0)
searchBox.BackgroundTransparency = 1
searchBox.PlaceholderText = ""
searchBox.Text = ""
searchBox.TextColor3 = Color3.fromRGB(255, 255, 255)
searchBox.TextSize = 9
searchBox.Font = Enum.Font.Gotham
searchBox.TextXAlignment = Enum.TextXAlignment.Left
searchBox.ClearTextOnFocus = false
searchBox.ZIndex = 6
searchBox.Parent = searchContainer
UIStrings.LockTextSize(searchBox, 9)

local function updatePlaceholder()
	searchPlaceholder.Visible = (searchBox.Text == "")
end

searchBox:GetPropertyChangedSignal("Text"):Connect(updatePlaceholder)
searchBox.Focused:Connect(updatePlaceholder)
searchBox.FocusLost:Connect(updatePlaceholder)

local closeBtn = Instance.new("TextButton")
closeBtn.Name = "CloseBtn"
closeBtn.Size = UDim2.new(0, 22, 0, 18)
closeBtn.Position = UDim2.new(1, -28, 0.5, 0)
closeBtn.AnchorPoint = Vector2.new(0, 0.5)
closeBtn.BackgroundColor3 = Color3.fromHex("#2A2A2A")
closeBtn.BackgroundTransparency = 0
closeBtn.Text = "x"
closeBtn.TextColor3 = Color3.fromHex("#FFFFFF")
closeBtn.TextSize = 12
closeBtn.Font = Enum.Font.GothamBold
closeBtn.TextXAlignment = Enum.TextXAlignment.Center
closeBtn.TextYAlignment = Enum.TextYAlignment.Center
closeBtn.AutoButtonColor = false
closeBtn.ZIndex = 4
closeBtn.Parent = invHeader
UIStrings.LockTextSize(closeBtn, 12)

addCorner(closeBtn, 6)

local closePad = Instance.new("UIPadding")
closePad.PaddingBottom = UDim.new(0, 2)
closePad.Parent = closeBtn

closeBtn.MouseEnter:Connect(function()
	tweenProperty(closeBtn, {BackgroundColor3 = Color3.fromHex("#404040")}, 0.1)
end)
closeBtn.MouseLeave:Connect(function()
	tweenProperty(closeBtn, {BackgroundColor3 = Color3.fromHex("#2A2A2A")}, 0.1)
end)

local invContent = Instance.new("Frame")
invContent.Name = "Content"
invContent.Size = UDim2.new(1, -8, 1, -28)
invContent.Position = UDim2.new(0, 4, 0, 26)
invContent.BackgroundTransparency = 1
invContent.ClipsDescendants = true
invContent.ZIndex = 3
invContent.Parent = inventoryFrame

local invScroll = Instance.new("ScrollingFrame")
invScroll.Name = "ItemsContainer"
invScroll.Size = UDim2.new(1, 0, 1, 0)
invScroll.Position = UDim2.new(0, 0, 0, 0)
invScroll.BackgroundTransparency = 1
invScroll.BorderSizePixel = 0
invScroll.ScrollBarThickness = 2
invScroll.ScrollBarImageColor3 = SETTINGS.ACCENT_COLOR
invScroll.ScrollBarImageTransparency = 0.3
invScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
invScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
invScroll.ScrollingDirection = Enum.ScrollingDirection.Y
invScroll.ClipsDescendants = true
invScroll.ZIndex = 3
invScroll.Parent = invContent

local scrollPadding = Instance.new("UIPadding")
scrollPadding.PaddingLeft = UDim.new(0, 2)
scrollPadding.PaddingRight = UDim.new(0, 4)
scrollPadding.PaddingTop = UDim.new(0, 2)
scrollPadding.PaddingBottom = UDim.new(0, 2)
scrollPadding.Parent = invScroll

local invGrid = Instance.new("UIGridLayout")
invGrid.CellSize = UDim2.new(0, SETTINGS.SLOT_SIZE, 0, SETTINGS.SLOT_SIZE)
invGrid.CellPadding = UDim2.new(0, 4, 0, 4)
invGrid.SortOrder = Enum.SortOrder.Name
invGrid.HorizontalAlignment = Enum.HorizontalAlignment.Left
invGrid.Parent = invScroll

local dragGhost = Instance.new("Frame")
dragGhost.Name = "DragGhost"
dragGhost.Size = UDim2.new(0, SETTINGS.SLOT_SIZE, 0, SETTINGS.SLOT_SIZE)
dragGhost.BackgroundColor3 = SETTINGS.SLOT_COLOR
dragGhost.BackgroundTransparency = 0.2
dragGhost.BorderSizePixel = 0
dragGhost.Visible = false
dragGhost.ZIndex = 100
dragGhost.Parent = screenGui

addCorner(dragGhost, 6)
local dragGhostStroke = addStroke(dragGhost, SETTINGS.ACCENT_COLOR, 1.5, 0)

local dragGhostIcon = Instance.new("ImageLabel")
dragGhostIcon.Name = "Icon"
dragGhostIcon.Size = UDim2.new(0.75, 0, 0.75, 0)
dragGhostIcon.Position = UDim2.new(0.5, 0, 0.5, 0)
dragGhostIcon.AnchorPoint = Vector2.new(0.5, 0.5)
dragGhostIcon.BackgroundTransparency = 1
dragGhostIcon.ZIndex = 101
dragGhostIcon.Parent = dragGhost

local dragGhostName = Instance.new("TextLabel")
dragGhostName.Name = "Name"
dragGhostName.Size = UDim2.new(1, -4, 0.5, 0)
dragGhostName.Position = UDim2.new(0.5, 0, 0.5, 0)
dragGhostName.AnchorPoint = Vector2.new(0.5, 0.5)
dragGhostName.BackgroundTransparency = 1
dragGhostName.TextColor3 = SETTINGS.TEXT_COLOR
dragGhostName.TextSize = 8
dragGhostName.Font = Enum.Font.GothamBold
dragGhostName.TextTruncate = Enum.TextTruncate.AtEnd
dragGhostName.TextScaled = true
dragGhostName.ZIndex = 101
dragGhostName.Parent = dragGhost

local dragNameConstraint = Instance.new("UITextSizeConstraint")
dragNameConstraint.MaxTextSize = 9
dragNameConstraint.MinTextSize = 6
dragNameConstraint.Parent = dragGhostName

local function createToolSlot(position, parent, isHotbar)
	local slotWrapper = Instance.new("Frame")
	slotWrapper.Name = "Wrapper_" .. tostring(position)
	slotWrapper.Size = UDim2.new(0, SETTINGS.SLOT_SIZE, 0, SETTINGS.SLOT_SIZE)
	slotWrapper.BackgroundTransparency = 1
	slotWrapper.LayoutOrder = type(position) == "number" and position or 999
	slotWrapper.ClipsDescendants = false
	slotWrapper.Parent = parent

	local slot = Instance.new("ImageButton")
	slot.Name = tostring(position)
	slot.Size = UDim2.new(1, 0, 1, 0)
	slot.Position = UDim2.new(0, 0, 0, 0)
	slot.BackgroundColor3 = SETTINGS.SLOT_COLOR
	slot.BackgroundTransparency = 0.1
	slot.BorderSizePixel = 0
	slot.Image = ""
	slot.AutoButtonColor = false
	slot.ClipsDescendants = false
	slot.Parent = slotWrapper

	addCorner(slot, 6)

	local slotStroke = Instance.new("UIStroke")
	slotStroke.Name = "SlotStroke"
	slotStroke.Color = SETTINGS.SLOT_STROKE_COLOR
	slotStroke.Thickness = 1
	slotStroke.Transparency = 0.2
	slotStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	slotStroke.Parent = slot

	local equippedIndicator = Instance.new("Frame")
	equippedIndicator.Name = "EquippedIndicator"
	equippedIndicator.Size = UDim2.new(0.5, 0, 0, 2)
	equippedIndicator.Position = UDim2.new(0.5, 0, 1, -3)
	equippedIndicator.AnchorPoint = Vector2.new(0.5, 0)
	equippedIndicator.BackgroundColor3 = SETTINGS.ACCENT_COLOR
	equippedIndicator.BackgroundTransparency = 1
	equippedIndicator.BorderSizePixel = 0
	equippedIndicator.ZIndex = 3
	equippedIndicator.Parent = slot

	addCorner(equippedIndicator, 1)

	local toolIcon = Instance.new("ImageLabel")
	toolIcon.Name = "ToolIcon"
	toolIcon.Size = UDim2.new(0.8, 0, 0.8, 0)
	toolIcon.Position = UDim2.new(0.5, 0, 0.5, 0)
	toolIcon.AnchorPoint = Vector2.new(0.5, 0.5)
	toolIcon.BackgroundTransparency = 1
	toolIcon.Image = ""
	toolIcon.ScaleType = Enum.ScaleType.Fit
	toolIcon.ZIndex = 2
	toolIcon.Parent = slot

	local toolName = Instance.new("TextLabel")
	toolName.Name = "ToolName"
	toolName.Size = UDim2.new(1, -4, 0.55, 0)
	toolName.Position = UDim2.new(0.5, 0, 0.5, 0)
	toolName.AnchorPoint = Vector2.new(0.5, 0.5)
	toolName.BackgroundTransparency = 1
	toolName.Text = ""
	toolName.TextColor3 = SETTINGS.TEXT_COLOR
	toolName.TextSize = 8
	toolName.Font = Enum.Font.GothamBold
	toolName.TextTruncate = Enum.TextTruncate.AtEnd
	toolName.TextScaled = true
	toolName.Visible = false
	toolName.ZIndex = 2
	toolName.Parent = slot

	local nameConstraint = Instance.new("UITextSizeConstraint")
	nameConstraint.MaxTextSize = 9
	nameConstraint.MinTextSize = 5
	nameConstraint.Parent = toolName

	local amountBg = Instance.new("Frame")
	amountBg.Name = "AmountBg"
	amountBg.Size = UDim2.new(0, 0, 0, 10)
	amountBg.AutomaticSize = Enum.AutomaticSize.X
	amountBg.Position = UDim2.new(1, -1, 1, -1)
	amountBg.AnchorPoint = Vector2.new(1, 1)
	amountBg.BackgroundColor3 = SETTINGS.ACCENT_COLOR
	amountBg.BackgroundTransparency = 0.1
	amountBg.Visible = false
	amountBg.ZIndex = 3
	amountBg.Parent = slot

	addCorner(amountBg, 2)

	local amountPadding = Instance.new("UIPadding")
	amountPadding.PaddingLeft = UDim.new(0, 2)
	amountPadding.PaddingRight = UDim.new(0, 2)
	amountPadding.Parent = amountBg

	local toolAmount = Instance.new("TextLabel")
	toolAmount.Name = "ToolAmount"
	toolAmount.Size = UDim2.new(0, 0, 1, 0)
	toolAmount.AutomaticSize = Enum.AutomaticSize.X
	toolAmount.BackgroundTransparency = 1
	toolAmount.Text = ""
	toolAmount.TextColor3 = Color3.fromHex("#111111")
	toolAmount.TextSize = 7
	toolAmount.Font = Enum.Font.GothamBold
	toolAmount.ZIndex = 4
	toolAmount.Parent = amountBg
	UIStrings.LockTextSize(toolAmount, 7)

	return slotWrapper, slot
end

local ToolObject = {}
ToolObject.__index = ToolObject

function ToolObject.new(tool, parent, position)
	local self = setmetatable({}, ToolObject)

	self.Tool = tool
	self.Parent = parent
	self.Position = position
	self.Name = tool.Name
	self.Wrapper = nil
	self.Frame = nil
	self.CONNECTIONS = {}
	self.isGrabbed = false
	self.DescriptionFrame = nil

	return self
end

function ToolObject:isEquipped()
	local character = player.Character
	return character and self.Tool.Parent == character
end

function ToolObject:updateIcon()
	if not self.Frame then return end

	local toolIcon = self.Frame:FindFirstChild("ToolIcon")
	local toolName = self.Frame:FindFirstChild("ToolName")

	if not toolIcon or not toolName then return end

	local textureId = self.Tool.TextureId

	if textureId == "" or textureId == nil then
		toolIcon.Visible = false
		toolIcon.Image = ""
		toolName.Visible = true
		toolName.Text = self.Tool.Name
	else
		toolIcon.Visible = true
		toolIcon.Image = textureId
		toolName.Visible = SETTINGS.ALWAYS_SHOW_TOOL_NAME
		toolName.Text = self.Tool.Name
	end
end

function ToolObject:updateAmount()
	if not self.Frame then return end

	local amountBg = self.Frame:FindFirstChild("AmountBg")
	if not amountBg then return end

	local toolAmount = amountBg:FindFirstChild("ToolAmount")
	if not toolAmount then return end

	local amount = self.Tool:GetAttribute("amount") or 1
	if amount > 1 then
		toolAmount.Text = "x" .. amount
		amountBg.Visible = true
	else
		amountBg.Visible = false
	end
end

function ToolObject:setEquipped(equipped)
	if not self.Frame then return end

	local stroke = self.Frame:FindFirstChild("SlotStroke")
	local equippedIndicator = self.Frame:FindFirstChild("EquippedIndicator")

	if equipped then
		if stroke then
			stroke.Color = SETTINGS.ACCENT_COLOR
			stroke.Thickness = 1.5
			stroke.Transparency = 0
		end
		if equippedIndicator then
			tweenProperty(equippedIndicator, {BackgroundTransparency = 0}, 0.15)
		end
		tweenProperty(self.Frame, {BackgroundTransparency = 0}, 0.1)
	else
		if stroke then
			stroke.Color = SETTINGS.SLOT_STROKE_COLOR
			stroke.Thickness = 1
			stroke.Transparency = 0.2
		end
		if equippedIndicator then
			tweenProperty(equippedIndicator, {BackgroundTransparency = 1}, 0.15)
		end
		tweenProperty(self.Frame, {BackgroundTransparency = 0.1}, 0.1)
	end
end

function ToolObject:setEnabled(enabled)
	if not self.Frame then return end

	local toolIcon = self.Frame:FindFirstChild("ToolIcon")
	local toolName = self.Frame:FindFirstChild("ToolName")

	if enabled then
		self.Frame.BackgroundColor3 = SETTINGS.SLOT_COLOR
		if toolIcon then toolIcon.ImageTransparency = 0 end
		if toolName then toolName.TextTransparency = 0 end
	else
		self.Frame.BackgroundColor3 = SETTINGS.SLOT_DISABLED_COLOR
		if toolIcon then toolIcon.ImageTransparency = 0.5 end
		if toolName then toolName.TextTransparency = 0.5 end
	end
end

function ToolObject:showDescription()
	if self.DescriptionFrame then return end

	local toolDescription = self.Tool.ToolTip
	if toolDescription == "" then return end

	local descFrame = Instance.new("Frame")
	descFrame.Name = "DescriptionFrame"
	descFrame.AnchorPoint = Vector2.new(0.5, 1)
	descFrame.BackgroundColor3 = Color3.fromHex("#151515")
	descFrame.BackgroundTransparency = 0.05
	descFrame.BorderSizePixel = 0
	descFrame.AutomaticSize = Enum.AutomaticSize.XY
	descFrame.ZIndex = 100
	descFrame.Parent = screenGui

	addCorner(descFrame, 5)
	addStroke(descFrame, SETTINGS.ACCENT_COLOR, 1, 0.5)

	local padding = Instance.new("UIPadding")
	padding.PaddingTop = UDim.new(0, 3)
	padding.PaddingBottom = UDim.new(0, 3)
	padding.PaddingLeft = UDim.new(0, 6)
	padding.PaddingRight = UDim.new(0, 6)
	padding.Parent = descFrame

	local descText = Instance.new("TextLabel")
	descText.BackgroundTransparency = 1
	descText.Text = toolDescription
	descText.TextColor3 = Color3.fromRGB(255, 255, 255)
	descText.TextSize = 9
	descText.Font = Enum.Font.Gotham
	descText.AutomaticSize = Enum.AutomaticSize.XY
	descText.TextWrapped = true
	descText.Parent = descFrame
	UIStrings.LockTextSize(descText, 9)

	local constraint = Instance.new("UISizeConstraint")
	constraint.MaxSize = Vector2.new(140, 50)
	constraint.Parent = descText

	local framePos = self.Frame.AbsolutePosition
	local frameSize = self.Frame.AbsoluteSize
	descFrame.Position = UDim2.new(0, framePos.X + frameSize.X/2, 0, framePos.Y - 3)

	self.DescriptionFrame = descFrame
	game:GetService("Debris"):AddItem(descFrame, 6)
end

function ToolObject:removeDescription()
	if self.DescriptionFrame then
		self.DescriptionFrame:Destroy()
		self.DescriptionFrame = nil
	end
end

function ToolObject:DisconnectAll()
	for _, conn in pairs(self.CONNECTIONS) do
		if conn then conn:Disconnect() end
	end
	self.CONNECTIONS = {}

	if self.Wrapper then
		self.Wrapper:Destroy()
		self.Wrapper = nil
		self.Frame = nil
	end

	if self.Parent == "HotBar" and self.Position then
		ContextActionService:UnbindAction(self.Position .. "hotBar")
		State.hotbarTools[self.Position] = nil
	elseif self.Parent == "Inventory" then
		State.inventoryTools[self.Name] = nil
	end

	self:removeDescription()
	task.defer(updateHotbarSize)
	task.defer(updateVisibility)
end

local InventoryModule = {}

function InventoryModule:getObjectFromTool(tool)
	for _, toolObject in pairs(State.hotbarTools) do
		if toolObject and toolObject.Tool == tool then
			return toolObject
		end
	end
	for _, toolObject in pairs(State.inventoryTools) do
		if toolObject and toolObject.Tool == tool then
			return toolObject
		end
	end
	return nil
end

function InventoryModule:getToolPosition(tool)
	local toolObject = self:getObjectFromTool(tool)
	return toolObject and toolObject.Position
end

function InventoryModule:searchTool()
	local searchText = searchBox.Text:lower()

	for _, toolObject in pairs(State.inventoryTools) do
		if toolObject.Wrapper then
			if searchText == "" then
				toolObject.Wrapper.Visible = true
			else
				toolObject.Wrapper.Visible = string.find(toolObject.Name:lower(), searchText, 1, true) ~= nil
			end
		end
	end
end

function InventoryModule:getNextHotbarPosition()
	for i = 1, SETTINGS.MAX_HOTBAR_SLOTS do
		if not State.hotbarTools[i] then
			return i
		end
	end
	return nil
end

function InventoryModule:countHotbarTools()
	local count = 0
	for _ in pairs(State.hotbarTools) do
		count = count + 1
	end
	return count
end

function InventoryModule:startDrag(toolObject)
	if not State.inventoryOpen then return end
	if State.isDragging then return end

	State.isDragging = true
	State.draggedObject = toolObject
	State.dragStartPos = Vector2.new(mouse.X, mouse.Y)

	local textureId = toolObject.Tool.TextureId
	if textureId and textureId ~= "" then
		dragGhostIcon.Image = textureId
		dragGhostIcon.Visible = true
		dragGhostName.Visible = false
	else
		dragGhostIcon.Visible = false
		dragGhostName.Text = toolObject.Tool.Name
		dragGhostName.Visible = true
	end

	dragGhost.Visible = true
	dragGhost.Position = UDim2.new(0, mouse.X - SETTINGS.SLOT_SIZE/2, 0, mouse.Y - SETTINGS.SLOT_SIZE/2)

	if toolObject.Frame then
		toolObject.Frame.BackgroundTransparency = 0.6
		local icon = toolObject.Frame:FindFirstChild("ToolIcon")
		local name = toolObject.Frame:FindFirstChild("ToolName")
		if icon then icon.ImageTransparency = 0.5 end
		if name then name.TextTransparency = 0.5 end
	end
end

function InventoryModule:updateDrag()
	if not State.isDragging then return end

	dragGhost.Position = UDim2.new(0, mouse.X - SETTINGS.SLOT_SIZE/2, 0, mouse.Y - SETTINGS.SLOT_SIZE/2)

	local guisAtPos = playerGui:GetGuiObjectsAtPosition(mouse.X, mouse.Y)

	for _, child in ipairs(hotbarContainer:GetChildren()) do
		if child:IsA("Frame") then
			local slot = child:FindFirstChildOfClass("ImageButton")
			if slot and slot ~= State.draggedObject.Frame then
				local stroke = slot:FindFirstChild("SlotStroke")
				if stroke then
					stroke.Color = SETTINGS.SLOT_STROKE_COLOR
				end
			end
		end
	end
	for _, child in ipairs(invScroll:GetChildren()) do
		if child:IsA("Frame") then
			local slot = child:FindFirstChildOfClass("ImageButton")
			if slot and slot ~= State.draggedObject.Frame then
				local stroke = slot:FindFirstChild("SlotStroke")
				if stroke then
					stroke.Color = SETTINGS.SLOT_STROKE_COLOR
				end
			end
		end
	end

	for _, gui in ipairs(guisAtPos) do
		if gui:IsA("ImageButton") then
			local parentWrapper = gui.Parent
			if parentWrapper and parentWrapper:IsA("Frame") then
				if parentWrapper.Parent == hotbarContainer or parentWrapper.Parent == invScroll then
					if gui ~= State.draggedObject.Frame then
						local stroke = gui:FindFirstChild("SlotStroke")
						if stroke then
							stroke.Color = SETTINGS.SLOT_DROP_TARGET_COLOR
						end
					end
					break
				end
			end
		end
	end

	local hotbarPos = hotbarFrame.AbsolutePosition
	local hotbarSize = hotbarFrame.AbsoluteSize
	local inHotbarArea = mouse.X >= hotbarPos.X and mouse.X <= hotbarPos.X + hotbarSize.X and
		mouse.Y >= hotbarPos.Y and mouse.Y <= hotbarPos.Y + hotbarSize.Y

	if inHotbarArea and State.draggedObject.Parent == "Inventory" then
		hotbarStroke.Transparency = 0.2
	else
		hotbarStroke.Transparency = 0.6
	end

	local invPos = inventoryFrame.AbsolutePosition
	local invSize = inventoryFrame.AbsoluteSize
	local inInvArea = mouse.X >= invPos.X and mouse.X <= invPos.X + invSize.X and
		mouse.Y >= invPos.Y and mouse.Y <= invPos.Y + invSize.Y

	if inInvArea and State.draggedObject.Parent == "HotBar" then
		invStroke.Transparency = 0.1
	else
		invStroke.Transparency = 0.4
	end
end

function InventoryModule:endDrag()
	if not State.isDragging then return end

	local toolObject = State.draggedObject
	dragGhost.Visible = false
	hotbarStroke.Transparency = 0.6
	invStroke.Transparency = 0.4

	if toolObject.Frame then
		toolObject.Frame.BackgroundTransparency = 0.1
		local icon = toolObject.Frame:FindFirstChild("ToolIcon")
		local name = toolObject.Frame:FindFirstChild("ToolName")
		if icon then icon.ImageTransparency = 0 end
		if name then name.TextTransparency = 0 end
	end

	local dragDistance = (Vector2.new(mouse.X, mouse.Y) - State.dragStartPos).Magnitude
	if dragDistance < SETTINGS.EQUIP_TOUCH_SENSITIVITY then
		State.isDragging = false
		State.draggedObject = nil
		return
	end

	local guisAtPos = playerGui:GetGuiObjectsAtPosition(mouse.X, mouse.Y)
	local targetSlot = nil
	local targetWrapper = nil
	local targetParent = nil

	for _, gui in ipairs(guisAtPos) do
		if gui:IsA("ImageButton") then
			local wrapper = gui.Parent
			if wrapper and wrapper:IsA("Frame") then
				if wrapper.Parent == hotbarContainer then
					targetSlot = gui
					targetWrapper = wrapper
					targetParent = "HotBar"
					break
				elseif wrapper.Parent == invScroll then
					targetSlot = gui
					targetWrapper = wrapper
					targetParent = "Inventory"
					break
				end
			end
		elseif gui == hotbarFrame or gui == hotbarContainer then
			targetParent = "HotBar"
		elseif gui == invScroll or gui == inventoryFrame or gui == invContent then
			targetParent = "Inventory"
		end
	end

	if targetSlot and targetSlot ~= toolObject.Frame then
		local targetObject = nil

		if targetParent == "HotBar" then
			local pos = tonumber(targetSlot.Name)
			targetObject = State.hotbarTools[pos]
		else
			targetObject = State.inventoryTools[targetSlot.Name]
		end

		if targetObject then
			self:swapTools(toolObject, targetObject)
		else
			if targetParent == "HotBar" then
				local pos = tonumber(targetSlot.Name)
				if pos then
					self:moveToolToHotbar(toolObject, pos)
				end
			end
		end
	elseif targetParent == "HotBar" and toolObject.Parent == "Inventory" then
		local nextPos = self:getNextHotbarPosition()
		if nextPos then
			self:moveToolToHotbar(toolObject, nextPos)
		end
	elseif targetParent == "Inventory" and toolObject.Parent == "HotBar" then
		self:moveToolToInventory(toolObject)
	end

	for _, child in ipairs(hotbarContainer:GetChildren()) do
		if child:IsA("Frame") then
			local slot = child:FindFirstChildOfClass("ImageButton")
			if slot then
				local stroke = slot:FindFirstChild("SlotStroke")
				if stroke then
					stroke.Color = SETTINGS.SLOT_STROKE_COLOR
				end
			end
		end
	end
	for _, child in ipairs(invScroll:GetChildren()) do
		if child:IsA("Frame") then
			local slot = child:FindFirstChildOfClass("ImageButton")
			if slot then
				local stroke = slot:FindFirstChild("SlotStroke")
				if stroke then
					stroke.Color = SETTINGS.SLOT_STROKE_COLOR
				end
			end
		end
	end

	State.isDragging = false
	State.draggedObject = nil
end

function InventoryModule:swapTools(obj1, obj2)
	local tool1 = obj1.Tool
	local tool2 = obj2.Tool
	local parent1 = obj1.Parent
	local parent2 = obj2.Parent
	local pos1 = obj1.Position
	local pos2 = obj2.Position

	obj1:DisconnectAll()
	obj2:DisconnectAll()
	State.boundTools[tool1] = nil
	State.boundTools[tool2] = nil
	tool1:SetAttribute("toolAdded", false)
	tool2:SetAttribute("toolAdded", false)

	self:addTool(tool1, parent2, pos2)
	self:addTool(tool2, parent1, pos1)
end

function InventoryModule:moveToolToHotbar(toolObject, position)
	local tool = toolObject.Tool

	toolObject:DisconnectAll()
	State.boundTools[tool] = nil
	tool:SetAttribute("toolAdded", false)

	self:addTool(tool, "HotBar", position)
end

function InventoryModule:moveToolToInventory(toolObject)
	local tool = toolObject.Tool

	toolObject:DisconnectAll()
	State.boundTools[tool] = nil
	tool:SetAttribute("toolAdded", false)

	self:addTool(tool, "Inventory", nil)
end

function InventoryModule:addTool(tool, parent, position)
	if State.boundTools[tool] then return end
	State.boundTools[tool] = true

	if parent == "HotBar" then
		if not position then
			position = self:getNextHotbarPosition()
		end
		if not position then
			parent = "Inventory"
			position = nil
		end
	end

	local toolObject = ToolObject.new(tool, parent, position)

	local slotParent = parent == "HotBar" and hotbarContainer or invScroll
	local wrapper, slot = createToolSlot(position or tool.Name, slotParent, parent == "HotBar")
	wrapper.Name = "Wrapper_" .. (parent == "HotBar" and tostring(position) or tool.Name)
	slot.Name = parent == "HotBar" and tostring(position) or tool.Name
	toolObject.Wrapper = wrapper
	toolObject.Frame = slot

	if parent == "HotBar" then
		State.hotbarTools[position] = toolObject
	else
		State.inventoryTools[tool.Name] = toolObject
	end

	toolObject:updateIcon()
	toolObject:updateAmount()
	toolObject:setEnabled(tool.Enabled)

	if toolObject:isEquipped() then
		toolObject:setEquipped(true)
		State.currentlyEquipped = toolObject
	end

	local function manageTool(_, inputState, inputObject)
		if State.isDragging then return end

		if isUserTyping() then return end

		if inputObject and inputObject.UserInputType ~= Enum.UserInputType.Keyboard and inputObject.UserInputType ~= Enum.UserInputType.Touch then
			return
		end

		local character = player.Character
		local humanoid = character and character:FindFirstChildOfClass("Humanoid")

		if not humanoid or humanoid.Health <= 0 or not tool.Parent or inputState == Enum.UserInputState.End or State.slotsLocked then
			return
		end

		if toolObject:isEquipped() then
			humanoid:UnequipTools()
			toolObject:setEquipped(false)
			State.currentlyEquipped = nil
		elseif tool.Enabled then
			humanoid:EquipTool(tool)
			if State.currentlyEquipped then
				State.currentlyEquipped:setEquipped(false)
			end
			toolObject:setEquipped(true)
			State.currentlyEquipped = toolObject
		end
	end

	toolObject.CONNECTIONS.EnabledChanged = tool:GetPropertyChangedSignal("Enabled"):Connect(function()
		toolObject:setEnabled(tool.Enabled)
	end)

	toolObject.CONNECTIONS.ToolRemoved = tool.AncestryChanged:Connect(function(_, newParent)
		if newParent == nil or (newParent ~= player.Backpack and newParent ~= player.Character) then
			toolObject:DisconnectAll()
			State.boundTools[tool] = nil
			tool:SetAttribute("toolAdded", false)
			return
		end

		if toolObject:isEquipped() then
			toolObject:setEquipped(true)
			State.currentlyEquipped = toolObject
		else
			toolObject:setEquipped(false)
			if State.currentlyEquipped == toolObject then
				State.currentlyEquipped = nil
			end
		end
	end)

	toolObject.CONNECTIONS.NameChanged = tool:GetPropertyChangedSignal("Name"):Connect(function()
		toolObject.Name = tool.Name
		toolObject:updateIcon()
	end)

	toolObject.CONNECTIONS.TextureChanged = tool:GetPropertyChangedSignal("TextureId"):Connect(function()
		toolObject:updateIcon()
	end)

	toolObject.CONNECTIONS.AmountChanged = tool:GetAttributeChangedSignal("amount"):Connect(function()
		toolObject:updateAmount()
	end)

	toolObject.CONNECTIONS.MouseEnter = slot.MouseEnter:Connect(function()
		if State.isDragging then return end
		toolObject:showDescription()

		if not toolObject:isEquipped() then
			tweenProperty(slot, {BackgroundColor3 = SETTINGS.SLOT_HOVER_COLOR, BackgroundTransparency = 0}, 0.1)
		end
	end)

	toolObject.CONNECTIONS.MouseLeave = slot.MouseLeave:Connect(function()
		toolObject:removeDescription()

		if not toolObject:isEquipped() and not State.isDragging then
			tweenProperty(slot, {BackgroundColor3 = SETTINGS.SLOT_COLOR, BackgroundTransparency = 0.1}, 0.1)
		end
	end)

	toolObject.CONNECTIONS.MouseButton1Down = slot.MouseButton1Down:Connect(function()
		toolObject:removeDescription()
		State.dragStartPos = Vector2.new(mouse.X, mouse.Y)

		local moveConn
		local upConn

		moveConn = mouse.Move:Connect(function()
			local dragDistance = (Vector2.new(mouse.X, mouse.Y) - State.dragStartPos).Magnitude
			if dragDistance > 8 and State.inventoryOpen then
				moveConn:Disconnect()
				upConn:Disconnect()
				self:startDrag(toolObject)
			end
		end)

		upConn = UserInputService.InputEnded:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
				moveConn:Disconnect()
				upConn:Disconnect()

				if not State.isDragging then
					manageTool(nil, Enum.UserInputState.Begin, {UserInputType = Enum.UserInputType.Touch})
				end
			end
		end)
	end)

	if parent == "HotBar" and position and position <= SETTINGS.MAX_TOTAL_SLOTS then
		ContextActionService:BindAction(position .. "hotBar", manageTool, false, EnumKeys[position])
	end

	tool:SetAttribute("toolAdded", true)
	task.defer(updateHotbarSize)
	task.defer(updateVisibility)

	return toolObject
end

function InventoryModule:newTool(tool)
	if not tool:IsA("Tool") then return end
	if tool:GetAttribute("toolAdded") then return end

	local position = tool:GetAttribute("position")
	local parent = "HotBar"

	if position == -1 then
		parent = "Inventory"
		position = nil
	elseif self:countHotbarTools() >= SETTINGS.MAX_HOTBAR_SLOTS then
		parent = "Inventory"
		position = nil
	end

	self:addTool(tool, parent, position)
end

function InventoryModule:toggleInventory()
	local _, _, inventoryCount = getTotalToolCount()
	if inventoryCount == 0 then
		return
	end

	State.inventoryOpen = not State.inventoryOpen

	if State.inventoryOpen then
		tweenProperty(openBtn, {TextTransparency = 1}, 0.15)
		task.delay(0.15, function()
			openBtn.Visible = false
		end)

		inventoryFrame.Visible = true
		inventoryFrame.BackgroundTransparency = 1
		inventoryFrame.Size = UDim2.new(0, INVENTORY_WIDTH, 0, 0)

		tweenProperty(inventoryFrame, {
			Size = UDim2.new(0, INVENTORY_WIDTH, 0, INVENTORY_HEIGHT),
			BackgroundTransparency = 0.05
		}, 0.25, Enum.EasingStyle.Back)
	else
		if State.isDragging then
			self:endDrag()
		end

		searchBox.Text = ""

		tweenProperty(inventoryFrame, {
			Size = UDim2.new(0, INVENTORY_WIDTH, 0, 0),
			BackgroundTransparency = 1
		}, 0.2).Completed:Connect(function()
			inventoryFrame.Visible = false

			local _, _, invCount = getTotalToolCount()
			if invCount > 0 then
				openBtn.Visible = true
				openBtn.TextTransparency = 1
				tweenProperty(openBtn, {TextTransparency = 0}, 0.15)
			end
		end)
	end
end

function InventoryModule:reloadInventory(character)
	for pos, toolObject in pairs(State.hotbarTools) do
		if toolObject then
			toolObject:DisconnectAll()
		end
	end
	for name, toolObject in pairs(State.inventoryTools) do
		if toolObject then
			toolObject:DisconnectAll()
		end
	end

	State.hotbarTools = {}
	State.inventoryTools = {}
	State.boundTools = {}
	State.currentlyEquipped = nil
	State.isDragging = false
	State.draggedObject = nil

	for _, child in ipairs(hotbarContainer:GetChildren()) do
		if child:IsA("Frame") then
			child:Destroy()
		end
	end
	for _, child in ipairs(invScroll:GetChildren()) do
		if child:IsA("Frame") then
			child:Destroy()
		end
	end

	local backpack = player:WaitForChild("Backpack", 5)
	if not backpack then return end

	for _, tool in ipairs(backpack:GetChildren()) do
		if tool:IsA("Tool") then
			self:newTool(tool)
		end
	end

	if character then
		for _, child in ipairs(character:GetChildren()) do
			if child:IsA("Tool") then
				self:newTool(child)
			end
		end
	end

	backpack.ChildAdded:Connect(function(child)
		if child:IsA("Tool") then
			self:newTool(child)
		end
	end)

	if character then
		character.ChildAdded:Connect(function(child)
			if child:IsA("Tool") then
				self:newTool(child)
			end
		end)
	end

	task.defer(updateHotbarSize)
	task.defer(updateVisibility)
end

openBtn.MouseButton1Click:Connect(function()
	InventoryModule:toggleInventory()
end)

closeBtn.MouseButton1Click:Connect(function()
	InventoryModule:toggleInventory()
end)

searchBox:GetPropertyChangedSignal("Text"):Connect(function()
	InventoryModule:searchTool()
end)

ContextActionService:BindAction("ToggleInventory", function(_, inputState)
	if inputState == Enum.UserInputState.Begin then
		if isUserTyping() then return end

		local _, _, inventoryCount = getTotalToolCount()
		if inventoryCount > 0 then
			InventoryModule:toggleInventory()
		end
	end
end, false, SETTINGS.INVENTORY_KEYBIND)

RunService.RenderStepped:Connect(function()
	if State.isDragging then
		InventoryModule:updateDrag()
	end
end)

UserInputService.InputEnded:Connect(function(input)
	if (input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch) and State.isDragging then
		InventoryModule:endDrag()
	end
end)

UserInputService.InputChanged:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseWheel and SETTINGS.SCROLL_HOTBAR_WITH_WHEEL then

		if isUserTyping() then return end

		if not hotbarFrame.Visible then return end

		local mousePos = UserInputService:GetMouseLocation()
		local hotbarPos = hotbarFrame.AbsolutePosition
		local hotbarSize = hotbarFrame.AbsoluteSize

		local isOverHotbar = mousePos.X >= hotbarPos.X and
			mousePos.X <= hotbarPos.X + hotbarSize.X and
			mousePos.Y >= hotbarPos.Y and
			mousePos.Y <= hotbarPos.Y + hotbarSize.Y

		if not isOverHotbar then return end

		local direction = input.Position.Z > 0 and -1 or 1
		local character = player.Character
		local humanoid = character and character:FindFirstChildOfClass("Humanoid")
		if not humanoid then return end

		local currentPos = State.currentlyEquipped and State.currentlyEquipped.Position or 0

		local searchStart = currentPos + direction
		local searchEnd = direction > 0 and SETTINGS.MAX_HOTBAR_SLOTS or 1

		for i = searchStart, searchEnd, direction do
			if State.hotbarTools[i] then
				humanoid:EquipTool(State.hotbarTools[i].Tool)
				return
			end
		end

		local wrapStart = direction > 0 and 1 or SETTINGS.MAX_HOTBAR_SLOTS
		local wrapEnd = direction > 0 and currentPos or 1

		for i = wrapStart, wrapEnd, direction do
			if State.hotbarTools[i] then
				humanoid:EquipTool(State.hotbarTools[i].Tool)
				return
			end
		end
	end
end)

player.CharacterAdded:Connect(function(character)
	task.wait(0.5)
	InventoryModule:reloadInventory(character)
end)

task.spawn(function()
	local character = player.Character or player.CharacterAdded:Wait()
	task.wait(0.5)
	InventoryModule:reloadInventory(character)
	task.defer(updateHotbarSize)
	task.defer(updateVisibility)
end)

local function updateForDevice()
	local viewportSize = camera.ViewportSize
	local isMobile = UserInputService.TouchEnabled and viewportSize.X < 1000

	if isMobile then
		SETTINGS.SLOT_SIZE = 32
		SETTINGS.SLOT_PADDING = 3
		SETTINGS.HOTBAR_INNER_PADDING = 4
		INVENTORY_WIDTH = math.min(220, viewportSize.X - 20)
		INVENTORY_HEIGHT = 95
		dragGhost.Size = UDim2.new(0, 32, 0, 32)
		openBtn.TextSize = 10
		openBtn.Size = UDim2.new(0, 40, 0, 16)
		invGrid.CellPadding = UDim2.new(0, 3, 0, 3)
	else
		SETTINGS.SLOT_SIZE = 36
		SETTINGS.SLOT_PADDING = 4
		SETTINGS.HOTBAR_INNER_PADDING = 5
		INVENTORY_WIDTH = 260
		INVENTORY_HEIGHT = 115
		dragGhost.Size = UDim2.new(0, 36, 0, 36)
		openBtn.TextSize = 12
		openBtn.Size = UDim2.new(0, 50, 0, 18)
		invGrid.CellPadding = UDim2.new(0, 4, 0, 4)
	end

	for _, child in ipairs(hotbarContainer:GetChildren()) do
		if child:IsA("Frame") then
			child.Size = UDim2.new(0, SETTINGS.SLOT_SIZE, 0, SETTINGS.SLOT_SIZE)
		end
	end

	invGrid.CellSize = UDim2.new(0, SETTINGS.SLOT_SIZE, 0, SETTINGS.SLOT_SIZE)

	hotbarContainer.Size = UDim2.new(1, -SETTINGS.HOTBAR_INNER_PADDING * 2, 1, -SETTINGS.HOTBAR_INNER_PADDING * 2)

	local hotbarHeight = SETTINGS.SLOT_SIZE + SETTINGS.HOTBAR_INNER_PADDING * 2
	inventoryFrame.Position = UDim2.new(0.5, 0, 1, -(hotbarHeight + 6 + INVENTORY_GAP))

	if State.inventoryOpen then
		inventoryFrame.Size = UDim2.new(0, INVENTORY_WIDTH, 0, INVENTORY_HEIGHT)
	end

	task.defer(updateHotbarSize)
	task.defer(updateVisibility)
end

camera:GetPropertyChangedSignal("ViewportSize"):Connect(updateForDevice)
task.defer(updateForDevice)

print("Inventaris Ultra Ringkas Siap!")
