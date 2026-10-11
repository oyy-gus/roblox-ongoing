-- ========================================
-- ROLE GIVE CLIENT (Admin Panel)
-- Place in: StarterGui > AdminGUI(ScreenGui) > RoleGiveClient(LocalScript)
-- Supports: VIP + Streamer + Creator
-- ========================================

local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService      = game:GetService("TweenService")

local Modules        = ReplicatedStorage:WaitForChild("Modules")
local GiveModule     = ReplicatedStorage:WaitForChild("GiveModule")
local AdminConfig    = require(Modules:WaitForChild("AdminConfig"))
local GiveRoleConfig = require(GiveModule:WaitForChild("GiveRoleConfig"))
local ThemeModule    = require(Modules:WaitForChild("ThemeModule"))
local NotifModule    = require(Modules:WaitForChild("NotifModule"))

local LocalPlayer = Players.LocalPlayer
local Config = AdminConfig.Config

-- ========================================
-- DEBUG HELPER
-- ========================================

local function debugPrint(...)
	if GiveRoleConfig.Debug.ENABLE_DEBUG and GiveRoleConfig.Debug.SHOW_CLIENT_LOGS then
		print("[RoleGiveClient]", ...)
	end
end

local function debugDispatch(...)
	if GiveRoleConfig.Debug.ENABLE_DEBUG and GiveRoleConfig.Debug.SHOW_DISPATCH_LOGS then
		print("[RoleGiveClient]", ...)
	end
end

-- ========================================
-- WAIT FOR GUI READY
-- ========================================

repeat task.wait(0.1) until AdminConfig.IsGUIReady()

local roleGivePage = AdminConfig.GUI.RoleGivePage
if not roleGivePage then
	warn("[RoleGiveClient] RoleGivePage not found!")
	return
end

-- ========================================
-- REMOTE EVENT
-- ========================================

local giveRoleRemote = ReplicatedStorage:WaitForChild("GiveRoleRemote", 30)
if not giveRoleRemote then
	warn("[RoleGiveClient] Failed to find GiveRoleRemote!")
	return
end

debugPrint("Connected to GiveRoleRemote")

-- ========================================
-- ROLE DEFINITIONS
-- ========================================

local RoleDefinitions = {
	{ 
		Name = "VIP", 
		Icon = "👑", 
		Color = Color3.fromRGB(255, 215, 0), 
		Priority = 1, 
		RequiresPayment = false,
		Description = "VIP Role"
	},
	{ 
		Name = "Streamer", 
		Icon = "📺", 
		Color = Color3.fromRGB(138, 43, 226), 
		Priority = 2, 
		RequiresPayment = false,
		Description = "Streamer Role"
	},
	{ 
		Name = "Creator", 
		Icon = "🎨", 
		Color = Color3.fromRGB(255, 105, 180), 
		Priority = 3, 
		RequiresPayment = false,
		Description = "Creator Role"
	},
}

-- ========================================
-- STATE
-- ========================================

local State = {
	SelectedPlayer = nil,
	SelectedRole = nil,
	PlayerButtons = {},
	RoleButtons = {},
	Gradients = {},
}

-- ========================================
-- BUILD UI
-- ========================================

-- Main Container
local mainContainer = Instance.new("Frame")
mainContainer.Name = "RoleGiveContainer"
mainContainer.Size = UDim2.new(1, 0, 1, 0)
mainContainer.BackgroundTransparency = 1
mainContainer.Parent = roleGivePage

AdminConfig.CreatePadding(mainContainer, 15, 15, 15, 15)

-- Title Section
local titleSection = Instance.new("Frame")
titleSection.Name = "TitleSection"
titleSection.Size = UDim2.new(1, 0, 0, 40)
titleSection.BackgroundTransparency = 1
titleSection.Parent = mainContainer

local titleLabel = Instance.new("TextLabel")
titleLabel.Name = "Title"
titleLabel.Size = UDim2.new(1, 0, 1, 0)
titleLabel.BackgroundTransparency = 1
titleLabel.Text = "🎭 Role Management"
titleLabel.TextColor3 = ThemeModule.Colors.TextWhite
titleLabel.TextSize = 20
titleLabel.Font = Enum.Font.GothamBold
titleLabel.TextXAlignment = Enum.TextXAlignment.Left
titleLabel.Parent = titleSection

local titleGradient = ThemeModule.CreatePrimaryGradient(titleLabel, 0, 1)
State.Gradients.titleGradient = titleGradient

local subtitleLabel = Instance.new("TextLabel")
subtitleLabel.Name = "Subtitle"
subtitleLabel.Size = UDim2.new(1, 0, 0, 18)
subtitleLabel.Position = UDim2.new(0, 0, 1, 3)
subtitleLabel.BackgroundTransparency = 1
subtitleLabel.Text = "Halo @" .. LocalPlayer.DisplayName .. " - Pilih player dan role untuk diberikan"
subtitleLabel.TextColor3 = ThemeModule.Colors.TextMuted
subtitleLabel.TextSize = 12
subtitleLabel.Font = Enum.Font.Gotham
subtitleLabel.TextXAlignment = Enum.TextXAlignment.Left
subtitleLabel.Parent = titleSection

-- Content Area
local contentArea = Instance.new("Frame")
contentArea.Name = "ContentArea"
contentArea.Size = UDim2.new(1, 0, 1, -70)
contentArea.Position = UDim2.new(0, 0, 0, 65)
contentArea.BackgroundTransparency = 1
contentArea.Parent = mainContainer

-- ========================================
-- LEFT PANEL - PLAYER LIST
-- ========================================

local leftPanel = Instance.new("Frame")
leftPanel.Name = "LeftPanel"
leftPanel.Size = UDim2.new(0.5, -8, 1, 0)
leftPanel.BackgroundColor3 = ThemeModule.Colors.BackgroundDark
leftPanel.BorderSizePixel = 0
leftPanel.ClipsDescendants = true
leftPanel.Parent = contentArea

AdminConfig.CreateCorner(leftPanel, 8)
ThemeModule.CreateAnimatedStroke(leftPanel, 1, "Primary", 1.2)

-- Left Panel Header
local leftHeader = Instance.new("Frame")
leftHeader.Name = "Header"
leftHeader.Size = UDim2.new(1, -4, 0, 34)
leftHeader.Position = UDim2.new(0, 2, 0, 2)
leftHeader.BackgroundColor3 = ThemeModule.Colors.BackgroundMedium
leftHeader.BorderSizePixel = 0
leftHeader.Parent = leftPanel

AdminConfig.CreateCorner(leftHeader, 6)

local leftHeaderLabel = Instance.new("TextLabel")
leftHeaderLabel.Size = UDim2.new(1, -50, 1, 0)
leftHeaderLabel.Position = UDim2.new(0, 10, 0, 0)
leftHeaderLabel.BackgroundTransparency = 1
leftHeaderLabel.Text = "👥 Daftar Player"
leftHeaderLabel.TextColor3 = ThemeModule.Colors.TextWhite
leftHeaderLabel.TextSize = 13
leftHeaderLabel.Font = Enum.Font.GothamBold
leftHeaderLabel.TextXAlignment = Enum.TextXAlignment.Left
leftHeaderLabel.Parent = leftHeader

local leftHeaderGradient = ThemeModule.CreatePrimaryGradient(leftHeaderLabel, 0, 1.2)
State.Gradients.leftHeaderGradient = leftHeaderGradient

local playerCountLabel = Instance.new("TextLabel")
playerCountLabel.Name = "PlayerCount"
playerCountLabel.Size = UDim2.new(0, 30, 1, 0)
playerCountLabel.Position = UDim2.new(1, -40, 0, 0)
playerCountLabel.BackgroundTransparency = 1
playerCountLabel.Text = "0"
playerCountLabel.TextColor3 = ThemeModule.Colors.TextMuted
playerCountLabel.TextSize = 11
playerCountLabel.Font = Enum.Font.GothamMedium
playerCountLabel.TextXAlignment = Enum.TextXAlignment.Right
playerCountLabel.Parent = leftHeader

-- Player List ScrollingFrame (VERTICAL ONLY)
local playerListScroll = Instance.new("ScrollingFrame")
playerListScroll.Name = "PlayerList"
playerListScroll.Size = UDim2.new(1, -8, 1, -44)
playerListScroll.Position = UDim2.new(0, 4, 0, 40)
playerListScroll.BackgroundTransparency = 1
playerListScroll.BorderSizePixel = 0
playerListScroll.ScrollBarThickness = 4
playerListScroll.ScrollBarImageColor3 = ThemeModule.Colors.Primary1
playerListScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
playerListScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
playerListScroll.ScrollingDirection = Enum.ScrollingDirection.Y  -- VERTICAL ONLY
playerListScroll.ElasticBehavior = Enum.ElasticBehavior.Never
playerListScroll.Parent = leftPanel

local playerListLayout = Instance.new("UIListLayout")
playerListLayout.Padding = UDim.new(0, 4)
playerListLayout.SortOrder = Enum.SortOrder.Name
playerListLayout.Parent = playerListScroll

local playerListPadding = Instance.new("UIPadding")
playerListPadding.PaddingTop = UDim.new(0, 2)
playerListPadding.PaddingBottom = UDim.new(0, 4)
playerListPadding.PaddingLeft = UDim.new(0, 2)
playerListPadding.PaddingRight = UDim.new(0, 4)
playerListPadding.Parent = playerListScroll

-- ========================================
-- RIGHT PANEL - ROLE SELECTION
-- ========================================

local rightPanel = Instance.new("Frame")
rightPanel.Name = "RightPanel"
rightPanel.Size = UDim2.new(0.5, -8, 1, 0)
rightPanel.Position = UDim2.new(0.5, 8, 0, 0)
rightPanel.BackgroundColor3 = ThemeModule.Colors.BackgroundDark
rightPanel.BorderSizePixel = 0
rightPanel.ClipsDescendants = true
rightPanel.Parent = contentArea

AdminConfig.CreateCorner(rightPanel, 8)
ThemeModule.CreateAnimatedStroke(rightPanel, 1, "Primary", 1.2)

-- Right Panel Header
local rightHeader = Instance.new("Frame")
rightHeader.Name = "Header"
rightHeader.Size = UDim2.new(1, -8, 0, 34)
rightHeader.Position = UDim2.new(0, 4, 0, 4)
rightHeader.BackgroundColor3 = ThemeModule.Colors.BackgroundMedium
rightHeader.BorderSizePixel = 0
rightHeader.Parent = rightPanel

AdminConfig.CreateCorner(rightHeader, 6)

local rightHeaderLabel = Instance.new("TextLabel")
rightHeaderLabel.Size = UDim2.new(1, -20, 1, 0)
rightHeaderLabel.Position = UDim2.new(0, 10, 0, 0)
rightHeaderLabel.BackgroundTransparency = 1
rightHeaderLabel.Text = "🎭 Pilih Role"
rightHeaderLabel.TextColor3 = ThemeModule.Colors.TextWhite
rightHeaderLabel.TextSize = 13
rightHeaderLabel.Font = Enum.Font.GothamBold
rightHeaderLabel.TextXAlignment = Enum.TextXAlignment.Left
rightHeaderLabel.Parent = rightHeader

local rightHeaderGradient = ThemeModule.CreatePrimaryGradient(rightHeaderLabel, 0, 1.2)
State.Gradients.rightHeaderGradient = rightHeaderGradient

-- Selected Player Info: Y=42, H=48
local selectedInfoFrame = Instance.new("Frame")
selectedInfoFrame.Name = "SelectedInfo"
selectedInfoFrame.Size = UDim2.new(1, -8, 0, 48)
selectedInfoFrame.Position = UDim2.new(0, 4, 0, 42)
selectedInfoFrame.BackgroundColor3 = ThemeModule.Colors.BackgroundMedium
selectedInfoFrame.BorderSizePixel = 0
selectedInfoFrame.Parent = rightPanel

AdminConfig.CreateCorner(selectedInfoFrame, 6)

local selectedLabel = Instance.new("TextLabel")
selectedLabel.Name = "SelectedLabel"
selectedLabel.Size = UDim2.new(1, -12, 0, 14)
selectedLabel.Position = UDim2.new(0, 6, 0, 4)
selectedLabel.BackgroundTransparency = 1
selectedLabel.Text = "Player Terpilih:"
selectedLabel.TextColor3 = ThemeModule.Colors.TextMuted
selectedLabel.TextSize = 9
selectedLabel.Font = Enum.Font.Gotham
selectedLabel.TextXAlignment = Enum.TextXAlignment.Left
selectedLabel.Parent = selectedInfoFrame

local selectedPlayerName = Instance.new("TextLabel")
selectedPlayerName.Name = "SelectedPlayerName"
selectedPlayerName.Size = UDim2.new(1, -12, 0, 18)
selectedPlayerName.Position = UDim2.new(0, 6, 0, 22)
selectedPlayerName.BackgroundTransparency = 1
selectedPlayerName.Text = "Belum ada yang dipilih"
selectedPlayerName.TextColor3 = ThemeModule.Colors.TextWhite
selectedPlayerName.TextSize = 11
selectedPlayerName.Font = Enum.Font.GothamBold
selectedPlayerName.TextXAlignment = Enum.TextXAlignment.Left
selectedPlayerName.TextTruncate = Enum.TextTruncate.AtEnd
selectedPlayerName.Parent = selectedInfoFrame

-- Selected Role Info: Y=94, H=48
local selectedRoleFrame = Instance.new("Frame")
selectedRoleFrame.Name = "SelectedRoleInfo"
selectedRoleFrame.Size = UDim2.new(1, -8, 0, 48)
selectedRoleFrame.Position = UDim2.new(0, 4, 0, 94)
selectedRoleFrame.BackgroundColor3 = ThemeModule.Colors.BackgroundMedium
selectedRoleFrame.BorderSizePixel = 0
selectedRoleFrame.Parent = rightPanel

AdminConfig.CreateCorner(selectedRoleFrame, 6)

local selectedRoleLabel = Instance.new("TextLabel")
selectedRoleLabel.Name = "SelectedRoleLabel"
selectedRoleLabel.Size = UDim2.new(1, -12, 0, 14)
selectedRoleLabel.Position = UDim2.new(0, 6, 0, 4)
selectedRoleLabel.BackgroundTransparency = 1
selectedRoleLabel.Text = "Role Terpilih:"
selectedRoleLabel.TextColor3 = ThemeModule.Colors.TextMuted
selectedRoleLabel.TextSize = 9
selectedRoleLabel.Font = Enum.Font.Gotham
selectedRoleLabel.TextXAlignment = Enum.TextXAlignment.Left
selectedRoleLabel.Parent = selectedRoleFrame

local selectedRoleName = Instance.new("TextLabel")
selectedRoleName.Name = "SelectedRoleName"
selectedRoleName.Size = UDim2.new(1, -12, 0, 18)
selectedRoleName.Position = UDim2.new(0, 6, 0, 22)
selectedRoleName.BackgroundTransparency = 1
selectedRoleName.Text = "Belum ada yang dipilih"
selectedRoleName.TextColor3 = ThemeModule.Colors.TextWhite
selectedRoleName.TextSize = 11
selectedRoleName.Font = Enum.Font.GothamBold
selectedRoleName.TextXAlignment = Enum.TextXAlignment.Left
selectedRoleName.TextTruncate = Enum.TextTruncate.AtEnd
selectedRoleName.Parent = selectedRoleFrame

-- ========================================
-- Role Buttons: ScrollingFrame (VERTICAL ONLY)
-- Mulai Y=146, memanjang sampai 50px sebelum bawah panel
-- ========================================

local roleButtonsContainer = Instance.new("ScrollingFrame")
roleButtonsContainer.Name = "RoleButtons"
roleButtonsContainer.Size = UDim2.new(1, -8, 1, -200)
roleButtonsContainer.Position = UDim2.new(0, 4, 0, 146)
roleButtonsContainer.BackgroundTransparency = 1
roleButtonsContainer.BorderSizePixel = 0
roleButtonsContainer.ScrollBarThickness = 4
roleButtonsContainer.ScrollBarImageColor3 = ThemeModule.Colors.Primary1
roleButtonsContainer.CanvasSize = UDim2.new(0, 0, 0, 0)
roleButtonsContainer.AutomaticCanvasSize = Enum.AutomaticSize.Y
roleButtonsContainer.ScrollingDirection = Enum.ScrollingDirection.Y  -- VERTICAL ONLY
roleButtonsContainer.ElasticBehavior = Enum.ElasticBehavior.Never
roleButtonsContainer.ClipsDescendants = true
roleButtonsContainer.Parent = rightPanel

local roleButtonsLayout = Instance.new("UIListLayout")
roleButtonsLayout.FillDirection = Enum.FillDirection.Vertical
roleButtonsLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
roleButtonsLayout.VerticalAlignment = Enum.VerticalAlignment.Top
roleButtonsLayout.Padding = UDim.new(0, 4)
roleButtonsLayout.Parent = roleButtonsContainer

local roleButtonsPadding = Instance.new("UIPadding")
roleButtonsPadding.PaddingTop = UDim.new(0, 2)
roleButtonsPadding.PaddingBottom = UDim.new(0, 4)
roleButtonsPadding.PaddingLeft = UDim.new(0, 2)
roleButtonsPadding.PaddingRight = UDim.new(0, 4)
roleButtonsPadding.Parent = roleButtonsContainer

-- Create Role Buttons
for i, roleDef in ipairs(RoleDefinitions) do
	local roleBtn = Instance.new("TextButton")
	roleBtn.Name = roleDef.Name .. "Btn"
	roleBtn.Size = UDim2.new(1, -8, 0, 36)
	roleBtn.BackgroundColor3 = ThemeModule.Colors.BackgroundMedium
	roleBtn.BorderSizePixel = 0
	roleBtn.Text = roleDef.Icon .. " " .. roleDef.Name
	roleBtn.TextColor3 = ThemeModule.Colors.TextWhite
	roleBtn.TextSize = 11
	roleBtn.Font = Enum.Font.GothamBold
	roleBtn.AutoButtonColor = false
	roleBtn.LayoutOrder = i
	roleBtn.ClipsDescendants = true
	roleBtn.Parent = roleButtonsContainer

	AdminConfig.CreateCorner(roleBtn, 6)
	local btnStroke = AdminConfig.CreateStroke(roleBtn, roleDef.Color, 2)
	btnStroke.Transparency = 0.5

	-- FREE badge
	local freeBadge = Instance.new("TextLabel")
	freeBadge.Name = "FreeBadge"
	freeBadge.Size = UDim2.new(0, 26, 0, 10)
	freeBadge.Position = UDim2.new(1, -28, 0, 2)
	freeBadge.BackgroundColor3 = Color3.fromRGB(46, 204, 113)
	freeBadge.BorderSizePixel = 0
	freeBadge.Text = "FREE"
	freeBadge.TextColor3 = Color3.new(1, 1, 1)
	freeBadge.TextSize = 6
	freeBadge.Font = Enum.Font.GothamBold
	freeBadge.Parent = roleBtn
	AdminConfig.CreateCorner(freeBadge, 3)

	State.RoleButtons[roleDef.Name] = {
		Button = roleBtn,
		Stroke = btnStroke,
		Definition = roleDef
	}

	roleBtn.MouseEnter:Connect(function()
		TweenService:Create(roleBtn, TweenInfo.new(0.15), {
			BackgroundColor3 = roleDef.Color:Lerp(ThemeModule.Colors.BackgroundMedium, 0.6)
		}):Play()
		TweenService:Create(btnStroke, TweenInfo.new(0.15), {Transparency = 0}):Play()
	end)

	roleBtn.MouseLeave:Connect(function()
		if State.SelectedRole ~= roleDef.Name then
			TweenService:Create(roleBtn, TweenInfo.new(0.15), {
				BackgroundColor3 = ThemeModule.Colors.BackgroundMedium
			}):Play()
			TweenService:Create(btnStroke, TweenInfo.new(0.15), {Transparency = 0.5}):Play()
		end
	end)

	roleBtn.MouseButton1Click:Connect(function()
		AdminConfig.PlayClick()

		for name, data in pairs(State.RoleButtons) do
			TweenService:Create(data.Button, TweenInfo.new(0.15), {
				BackgroundColor3 = ThemeModule.Colors.BackgroundMedium
			}):Play()
			TweenService:Create(data.Stroke, TweenInfo.new(0.15), {Transparency = 0.5}):Play()
		end

		State.SelectedRole = roleDef.Name
		TweenService:Create(roleBtn, TweenInfo.new(0.15), {
			BackgroundColor3 = roleDef.Color:Lerp(ThemeModule.Colors.BackgroundMedium, 0.4)
		}):Play()
		TweenService:Create(btnStroke, TweenInfo.new(0.15), {Transparency = 0}):Play()

		selectedRoleName.Text = roleDef.Icon .. " " .. roleDef.Name
		selectedRoleName.TextColor3 = roleDef.Color

		debugPrint("Selected role:", roleDef.Name)
	end)
end

-- Action Buttons Container
local actionContainer = Instance.new("Frame")
actionContainer.Name = "ActionContainer"
actionContainer.Size = UDim2.new(1, -8, 0, 40)
actionContainer.Position = UDim2.new(0, 4, 1, -44)
actionContainer.BackgroundTransparency = 1
actionContainer.ClipsDescendants = true
actionContainer.Parent = rightPanel

local actionLayout = Instance.new("UIListLayout")
actionLayout.FillDirection = Enum.FillDirection.Horizontal
actionLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
actionLayout.VerticalAlignment = Enum.VerticalAlignment.Center
actionLayout.Padding = UDim.new(0, 6)
actionLayout.Parent = actionContainer

-- Confirm Button
local confirmBtn = Instance.new("TextButton")
confirmBtn.Name = "ConfirmBtn"
confirmBtn.Size = UDim2.new(0.5, -4, 1, 0)
confirmBtn.BackgroundColor3 = ThemeModule.Colors.BackgroundMedium
confirmBtn.BorderSizePixel = 0
confirmBtn.Text = "✅ Berikan Role"
confirmBtn.TextColor3 = ThemeModule.Colors.TextWhite
confirmBtn.TextSize = 11
confirmBtn.Font = Enum.Font.GothamBold
confirmBtn.AutoButtonColor = false
confirmBtn.LayoutOrder = 1
confirmBtn.Parent = actionContainer

AdminConfig.CreateCorner(confirmBtn, 6)
ThemeModule.CreateStaticGradient(confirmBtn, "Success", 90)

-- Cancel Button
local cancelBtn = Instance.new("TextButton")
cancelBtn.Name = "CancelBtn"
cancelBtn.Size = UDim2.new(0.5, -4, 1, 0)
cancelBtn.BackgroundColor3 = ThemeModule.Colors.BackgroundMedium
cancelBtn.BorderSizePixel = 0
cancelBtn.Text = "❌ Batalkan"
cancelBtn.TextColor3 = ThemeModule.Colors.TextWhite
cancelBtn.TextSize = 11
cancelBtn.Font = Enum.Font.GothamBold
cancelBtn.AutoButtonColor = false
cancelBtn.LayoutOrder = 2
cancelBtn.Parent = actionContainer

AdminConfig.CreateCorner(cancelBtn, 6)
ThemeModule.CreateStaticGradient(cancelBtn, "Error", 90)

-- Button Hover Effects
confirmBtn.MouseEnter:Connect(function()
	TweenService:Create(confirmBtn, TweenInfo.new(0.15), {BackgroundTransparency = 0.1}):Play()
end)
confirmBtn.MouseLeave:Connect(function()
	TweenService:Create(confirmBtn, TweenInfo.new(0.15), {BackgroundTransparency = 0}):Play()
end)

cancelBtn.MouseEnter:Connect(function()
	TweenService:Create(cancelBtn, TweenInfo.new(0.15), {BackgroundTransparency = 0.1}):Play()
end)
cancelBtn.MouseLeave:Connect(function()
	TweenService:Create(cancelBtn, TweenInfo.new(0.15), {BackgroundTransparency = 0}):Play()
end)

-- ========================================
-- FUNCTIONS
-- ========================================

local function resetSelection()
	State.SelectedRole = nil
	State.SelectedPlayer = nil
	selectedPlayerName.Text = "Belum ada yang dipilih"
	selectedRoleName.Text = "Belum ada yang dipilih"
	selectedRoleName.TextColor3 = ThemeModule.Colors.TextWhite

	for _, data in pairs(State.PlayerButtons) do
		if data.Button then
			TweenService:Create(data.Button, TweenInfo.new(0.15), {
				BackgroundColor3 = ThemeModule.Colors.BackgroundMedium
			}):Play()
			data.Stroke.Color = ThemeModule.Colors.BackgroundLighter
		end
	end

	for _, data in pairs(State.RoleButtons) do
		TweenService:Create(data.Button, TweenInfo.new(0.15), {
			BackgroundColor3 = ThemeModule.Colors.BackgroundMedium
		}):Play()
		TweenService:Create(data.Stroke, TweenInfo.new(0.15), {Transparency = 0.5}):Play()
	end

	debugPrint("Selection reset")
end

local function validateInput()
	if not State.SelectedRole then
		return false, "Pilih role terlebih dahulu!"
	end
	if not State.SelectedPlayer then
		return false, "Pilih player terlebih dahulu!"
	end
	local targetPlayer = Players:FindFirstChild(State.SelectedPlayer.Name)
	if not targetPlayer then
		return false, "Player tidak ditemukan di server!"
	end
	return true, targetPlayer
end

local function createPlayerButton(targetPlayer)
	local btn = Instance.new("TextButton")
	btn.Name = targetPlayer.Name
	btn.Size = UDim2.new(1, -4, 0, 40)
	btn.BackgroundColor3 = ThemeModule.Colors.BackgroundMedium
	btn.BorderSizePixel = 0
	btn.Text = ""
	btn.AutoButtonColor = false
	btn.Parent = playerListScroll

	AdminConfig.CreateCorner(btn, 6)
	local btnStroke = AdminConfig.CreateStroke(btn, ThemeModule.Colors.BackgroundLighter)

	local avatarImage = Instance.new("ImageLabel")
	avatarImage.Name = "Avatar"
	avatarImage.Size = UDim2.new(0, 28, 0, 28)
	avatarImage.Position = UDim2.new(0, 6, 0.5, -14)
	avatarImage.BackgroundColor3 = ThemeModule.Colors.BackgroundLight
	avatarImage.BorderSizePixel = 0
	avatarImage.Parent = btn

	AdminConfig.CreateCorner(avatarImage, 14)

	task.spawn(function()
		local success, result = pcall(function()
			return Players:GetUserThumbnailAsync(targetPlayer.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size48x48)
		end)
		if success and avatarImage then
			avatarImage.Image = result
		end
	end)

	local displayName = targetPlayer.DisplayName
	if targetPlayer == LocalPlayer then
		displayName = displayName .. " (Anda)"
	end

	local nameLabel = Instance.new("TextLabel")
	nameLabel.Name = "PlayerName"
	nameLabel.Size = UDim2.new(1, -46, 0, 16)
	nameLabel.Position = UDim2.new(0, 40, 0, 4)
	nameLabel.BackgroundTransparency = 1
	nameLabel.Text = displayName
	nameLabel.TextColor3 = ThemeModule.Colors.TextWhite
	nameLabel.TextSize = 11
	nameLabel.Font = Enum.Font.GothamBold
	nameLabel.TextXAlignment = Enum.TextXAlignment.Left
	nameLabel.TextTruncate = Enum.TextTruncate.AtEnd
	nameLabel.Parent = btn

	local usernameLabel = Instance.new("TextLabel")
	usernameLabel.Name = "Username"
	usernameLabel.Size = UDim2.new(1, -46, 0, 12)
	usernameLabel.Position = UDim2.new(0, 40, 0, 20)
	usernameLabel.BackgroundTransparency = 1
	usernameLabel.Text = "@" .. targetPlayer.Name
	usernameLabel.TextColor3 = ThemeModule.Colors.TextMuted
	usernameLabel.TextSize = 9
	usernameLabel.Font = Enum.Font.Gotham
	usernameLabel.TextXAlignment = Enum.TextXAlignment.Left
	usernameLabel.TextTruncate = Enum.TextTruncate.AtEnd
	usernameLabel.Parent = btn

	btn.MouseEnter:Connect(function()
		if State.SelectedPlayer ~= targetPlayer then
			TweenService:Create(btn, TweenInfo.new(0.15), {
				BackgroundColor3 = ThemeModule.Colors.BackgroundLighter
			}):Play()
		end
	end)

	btn.MouseLeave:Connect(function()
		if State.SelectedPlayer ~= targetPlayer then
			TweenService:Create(btn, TweenInfo.new(0.15), {
				BackgroundColor3 = ThemeModule.Colors.BackgroundMedium
			}):Play()
		end
	end)

	btn.MouseButton1Click:Connect(function()
		AdminConfig.PlayClick()

		for _, data in pairs(State.PlayerButtons) do
			if data.Button then
				TweenService:Create(data.Button, TweenInfo.new(0.15), {
					BackgroundColor3 = ThemeModule.Colors.BackgroundMedium
				}):Play()
				data.Stroke.Color = ThemeModule.Colors.BackgroundLighter
			end
		end

		State.SelectedPlayer = targetPlayer
		TweenService:Create(btn, TweenInfo.new(0.15), {
			BackgroundColor3 = ThemeModule.Colors.Primary1:Lerp(ThemeModule.Colors.BackgroundMedium, 0.7)
		}):Play()
		btnStroke.Color = ThemeModule.Colors.Primary1

		selectedPlayerName.Text = targetPlayer.DisplayName .. " (@" .. targetPlayer.Name .. ")"

		debugPrint("Selected player:", targetPlayer.DisplayName)
	end)

	State.PlayerButtons[targetPlayer.UserId] = {
		Button = btn,
		Stroke = btnStroke,
		Player = targetPlayer
	}

	return btn
end

local function removePlayerButton(targetPlayer)
	local data = State.PlayerButtons[targetPlayer.UserId]
	if data and data.Button then
		data.Button:Destroy()
		State.PlayerButtons[targetPlayer.UserId] = nil
	end

	if State.SelectedPlayer == targetPlayer then
		State.SelectedPlayer = nil
		selectedPlayerName.Text = "Belum ada yang dipilih"
		NotifModule.Warning("Role Give", "Player yang dipilih telah keluar", 3)
	end
end

local function updatePlayerCount()
	local count = #Players:GetPlayers()
	playerCountLabel.Text = tostring(count)
end

local function initializePlayers()
	for _, targetPlayer in ipairs(Players:GetPlayers()) do
		createPlayerButton(targetPlayer)
	end
	updatePlayerCount()
end

-- ========================================
-- PLAYER EVENTS
-- ========================================

Players.PlayerAdded:Connect(function(targetPlayer)
	createPlayerButton(targetPlayer)
	updatePlayerCount()
end)

Players.PlayerRemoving:Connect(function(targetPlayer)
	removePlayerButton(targetPlayer)
	updatePlayerCount()
end)

-- ========================================
-- ACTION BUTTON HANDLERS
-- ========================================

confirmBtn.MouseButton1Click:Connect(function()
	AdminConfig.PlayClick()

	local isValid, result = validateInput()
	if not isValid then
		NotifModule.Warning("Role Give", result, 3)
		return
	end

	local targetPlayer = result

	debugPrint(string.format("📋 Giving %s role to %s", State.SelectedRole, targetPlayer.DisplayName))
	NotifModule.Info("Role Give", "Memproses permintaan...", 2)

	giveRoleRemote:FireServer({
		source = "AdminPanel",
		action = "GiveRole",
		targetUserId = targetPlayer.UserId,
		roleType = State.SelectedRole
	})
end)

cancelBtn.MouseButton1Click:Connect(function()
	AdminConfig.PlayClick()
	resetSelection()
	NotifModule.Warning("Role Give", "Seleksi dibatalkan", 2)
end)

-- ========================================
-- REMOTE EVENT RESPONSE
-- ========================================

giveRoleRemote.OnClientEvent:Connect(function(responseData)
	if responseData.source ~= "AdminPanel" then return end

	if not responseData or type(responseData) ~= "table" then
		NotifModule.Error("Role Give", "Error: Invalid response dari server", 4)
		return
	end

	if responseData.success then
		NotifModule.Success("Role Give", responseData.message or "Role berhasil diberikan!", 4)
		task.wait(1)
		resetSelection()
	else
		NotifModule.Error("Role Give", responseData.message or "Operasi gagal", 4)
	end
end)

-- ========================================
-- ACCESS CHECK
-- ========================================

local function checkAdminAccess()
	local roleValue = LocalPlayer:FindFirstChild("Role")
	if roleValue then
		local playerRole = roleValue.Value
		if playerRole == "Owner" or playerRole == "Admin" or playerRole == "Developer" then
			debugPrint("Access granted for", playerRole)
			return true
		else
			mainContainer:ClearAllChildren()

			local noAccessLabel = Instance.new("TextLabel")
			noAccessLabel.Size = UDim2.new(1, 0, 1, 0)
			noAccessLabel.BackgroundTransparency = 1
			noAccessLabel.Text = "🚫 Akses Ditolak\n\nAnda tidak memiliki izin untuk mengakses fitur ini.\nDiperlukan role Owner, Developer, atau Admin."
			noAccessLabel.TextColor3 = ThemeModule.Colors.Error
			noAccessLabel.TextSize = 16
			noAccessLabel.Font = Enum.Font.GothamMedium
			noAccessLabel.Parent = mainContainer

			return false
		end
	end
	return false
end

local roleValue = LocalPlayer:WaitForChild("Role", 10)
if roleValue then
	if checkAdminAccess() then
		initializePlayers()
	end

	roleValue:GetPropertyChangedSignal("Value"):Connect(function()
		task.wait(0.1)
		checkAdminAccess()
	end)
else
	LocalPlayer.ChildAdded:Connect(function(child)
		if child.Name == "Role" and child:IsA("StringValue") then
			task.wait(0.1)
			if checkAdminAccess() then
				initializePlayers()
			end

			child:GetPropertyChangedSignal("Value"):Connect(function()
				task.wait(0.1)
				checkAdminAccess()
			end)
		end
	end)
end

-- ========================================
-- CLEANUP
-- ========================================

roleGivePage.Destroying:Connect(function()
	for _, gradient in pairs(State.Gradients) do
		if gradient then
			ThemeModule.GradientSystem.Unregister(gradient)
		end
	end
end)

print("✅ [RoleGiveClient] Loaded!")
