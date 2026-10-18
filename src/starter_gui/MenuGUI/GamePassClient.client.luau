local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")

local Player = Players.LocalPlayer
local Modules = ReplicatedStorage:WaitForChild("Modules")

local gui = script.Parent
local MenuConfig = nil
local ThemeModule = nil

local success, err = pcall(function()
	MenuConfig  = require(Modules:WaitForChild("MenuConfig"))
	ThemeModule = require(Modules:WaitForChild("ThemeModule"))
end)

if not success or not MenuConfig then
	warn("[Toko] ❌ Gagal memuat MenuConfig:", err)
	return
end

local SIZES = {
	HEADER_H = 54,
	HEADER_TITLE_TEXT = 17,
	HEADER_SUB_TEXT = 10.5,

	CARD_H = 200,
	CARD_CORNER = 14,

	LEFT_SECTION_W = 0.32,
	ICON_SIZE = 60,
	TITLE_TEXT = 13.5,
	PRICE_TEXT = 11.5,

	BENEFIT_CHECK_TEXT = 10.5,
	BENEFIT_TEXT = 10,
	BUTTON_H = 40,
	BUTTON_TEXT = 11.5,

	CORNER_SM = 6,
	CORNER_MD = 10,
	CORNER_LG = 14,
	SPACING = 12,
	SCROLL_PAD = 8,
}

local gamepassPage = nil
local SoundSystem = nil
local maxWaitTime = 15
local waitedTime = 0

while not gamepassPage and waitedTime < maxWaitTime do
	if MenuConfig.GUI then
		gamepassPage = MenuConfig.GUI.TokoPage or MenuConfig.GUI.GamePassPage
		SoundSystem = MenuConfig.SoundSystem
	end

	if not gamepassPage then
		local mainFrame = gui:FindFirstChild("MainPanel")
		if mainFrame then
			local contentContainer = mainFrame:FindFirstChild("ContentContainer")
			if contentContainer then
				gamepassPage = contentContainer:FindFirstChild("TokoPage") or contentContainer:FindFirstChild("GamePassPage")
			end
		end
	end

	if gamepassPage then break end
	task.wait(0.5)
	waitedTime = waitedTime + 0.5
end

if not gamepassPage then
	warn("[Toko] ❌ Halaman Toko tidak ditemukan!")
	return
end

if not SoundSystem then
	SoundSystem = {
		PlayClick = function()
			local sound = Instance.new("Sound")
			sound.SoundId = "rbxassetid://139658322785649"
			sound.Volume = 0.5
			sound.PlaybackSpeed = 1.2
			sound.Parent = game:GetService("SoundService")
			sound:Play()
			game:GetService("Debris"):AddItem(sound, 1)
		end,
		PlayHover = function() end,
		PlaySuccess = function() end,
		PlayError = function() end
	}
end

local function mk(cls, props, parent)
	local inst = Instance.new(cls)
	for k, v in pairs(props) do inst[k] = v end
	if inst:IsA("GuiObject") and not inst:IsA("UIComponent") and props.Active == nil then
		inst.Active = true
	end
	if parent then inst.Parent = parent end
	return inst
end

local function crn(r, f) mk("UICorner", { CornerRadius = UDim.new(0, r) }, f) end

local function getThemeColor(name, fallback)
	if ThemeModule and ThemeModule.Colors and ThemeModule.Colors[name] then
		return ThemeModule.Colors[name]
	end
	return fallback
end

local function addTextGradient(textLabel, animated, speed)
	if ThemeModule then
		if animated then
			return ThemeModule.CreatePrimaryGradient(textLabel, 0, speed or 1.5)
		else
			return ThemeModule.CreateStaticGradient(textLabel, "Primary", 0)
		end
	else
		local gradient = Instance.new("UIGradient")
		gradient.Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 215, 0)),
			ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 140, 0))
		})
		gradient.Rotation = 0
		gradient.Parent = textLabel
		return gradient
	end
end

local function addAnimatedStrokeGradient(parent, thickness, speed)
	if ThemeModule then
		local stroke, gradient = ThemeModule.CreateAnimatedStroke(parent, thickness, "Primary", speed or 1.5)
		return stroke, gradient
	else
		local stroke = Instance.new("UIStroke")
		stroke.Thickness = thickness or 2
		stroke.Color = Color3.fromRGB(255, 215, 0)
		stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
		stroke.Parent = parent
		return stroke, nil
	end
end

local COLORS = {
	VIP = {
		Primary   = getThemeColor("Primary1", Color3.fromHex("#FFFFFF")),
		Secondary = getThemeColor("Primary2", Color3.fromHex("#888888")),
		Glow      = ThemeModule.Colors.Border
	},
	Button = {
		Buy     = ThemeModule.Colors.ButtonPrimaryBg,
		Owned   = ThemeModule.Colors.BackgroundLight,
		Loading = ThemeModule.Colors.BackgroundLighter,
		Error   = ThemeModule.Colors.CloseRed
	},
	Text = {
		Primary   = ThemeModule.Colors.TextWhite,
		Secondary = ThemeModule.Colors.TextGray,
		Gold      = ThemeModule.Colors.Primary1
	}
}

local ButtonStates = {
	Loading = {
		Text            = "⏳ Memuat...",
		BackgroundColor = ThemeModule.Colors.BackgroundLighter,
		TextColor       = ThemeModule.Colors.TextGray,
		Enabled         = false
	},
	Buy = {
		Text            = "🛒 BELI SEKARANG",
		BackgroundColor = ThemeModule.Colors.ButtonPrimaryBg,
		TextColor       = ThemeModule.Colors.ButtonPrimaryText,
		Enabled         = true
	},
	Owned = {
		Text            = "✅ SUDAH DIMILIKI",
		BackgroundColor = ThemeModule.Colors.BackgroundLight,
		TextColor       = ThemeModule.Colors.TextMuted,
		Enabled         = false
	},
	Error = {
		Text            = "❌ Kesalahan",
		BackgroundColor = ThemeModule.Colors.CloseRed,
		TextColor       = ThemeModule.Colors.TextWhite,
		Enabled         = false
	}
}

local GamepassFolder = ReplicatedStorage:FindFirstChild("Gamepass")
local remotes = nil

if GamepassFolder then
	remotes = {
		shopRequest      = GamepassFolder:FindFirstChild("ShopRequest"),
		playerDataUpdated = GamepassFolder:FindFirstChild("PlayerDataUpdated"),
		refreshRole      = GamepassFolder:FindFirstChild("RefreshRole")
	}
end

local GamepassData = {
	VIP = {
		Button      = nil,
		Frame       = nil,
		PriceLabel  = nil,
		IDs         = {},
		Owned       = false,
		Name        = "VIP Pass",
		Price       = 0,
		Icon        = "👑",
		Description = "Akses premium dengan semua fitur eksklusif!",
		Benefits    = {
			"Tambah musik ke antrian (cooldown singkat)",
			"Dapatkan item spesial permanen",
			"Overhead VIP eksklusif",
			"Akses fitur premium lainnya"
		}
	}
}

local shopDataLoaded = false
local uiBuilt        = false

if ThemeModule and ThemeModule.GradientSystem then
	ThemeModule.GradientSystem.Start()
end

local notifContainer, notifFrame, notifText
local isShowingNotif = false

local function showNotification(message, isSuccess)
	if not notifContainer or isShowingNotif then return end
	isShowingNotif = true

	local bgColor = isSuccess and COLORS.Button.Buy or COLORS.Button.Error
	notifText.Text = message
	notifFrame.BackgroundColor3 = bgColor

	notifContainer.Visible = true
	notifFrame.Position = UDim2.new(0.5, 0, 1.5, 0)

	TweenService:Create(notifFrame, TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
		Position = UDim2.new(0.5, 0, 0.5, 0)
	}):Play()

	task.delay(4, function()
		TweenService:Create(notifFrame, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
			Position = UDim2.new(0.5, 0, 1.5, 0)
		}):Play()
		task.wait(0.3)
		notifContainer.Visible = false
		isShowingNotif = false
	end)
end

local function setButtonState(passType, state)
	local data = GamepassData[passType]
	if not data or not data.Button then return end

	local stateConfig = ButtonStates[state]
	if not stateConfig then return end

	data.Button.Text            = stateConfig.Text
	data.Button.Active          = stateConfig.Enabled
	data.Button.AutoButtonColor = stateConfig.Enabled
	if stateConfig.TextColor then
		data.Button.TextColor3 = stateConfig.TextColor
	end

	TweenService:Create(data.Button, TweenInfo.new(0.3), {
		BackgroundColor3 = stateConfig.BackgroundColor
	}):Play()
end

local function updatePriceLabel(passType, price)
	local data = GamepassData[passType]
	if data and data.PriceLabel then
		if price and price > 0 then
			data.PriceLabel.Text = "💎 " .. tostring(price) .. " Robux"
		else
			data.PriceLabel.Text = "💎 Harga tidak tersedia"
		end
	end
end

local function handleOwnershipUpdate(passType, owned)
	local data = GamepassData[passType]
	if not data then return end

	data.Owned = owned

	if owned then

		setButtonState(passType, "Owned")
		showNotification("🎉 Kamu telah menerima " .. data.Name .. "!", true)

		if remotes and remotes.refreshRole then
			task.spawn(function()
				task.wait(1)
				pcall(function()
					remotes.refreshRole:FireServer()
				end)
			end)
		end
	end
end

local function createGamePassCard(passType, passData, colors, parent)
	local card = mk("Frame", {
		Name                = passType .. "Card",
		Size                = UDim2.new(1, 0, 0, SIZES.CARD_H),
		BackgroundColor3    = ThemeModule.Colors.BackgroundMedium,
		BorderSizePixel     = 0,
		LayoutOrder         = 1,
		ClipsDescendants    = true,
	}, parent)
	crn(SIZES.CARD_CORNER, card)

	addAnimatedStrokeGradient(card, 2, 1.2)

	mk("UIGradient", {
		Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, ThemeModule.Colors.BackgroundLight),
			ColorSequenceKeypoint.new(1, ThemeModule.Colors.BackgroundDark)
		}),
		Rotation = 135,
	}, card)

	local shine = mk("Frame", {
		Name                = "Shine",
		Size                = UDim2.new(0.3, 0, 1, 0),
		Position            = UDim2.new(-0.3, 0, 0, 0),
		BackgroundTransparency = 0.7,
		BorderSizePixel     = 0,
		ZIndex              = 2,
	}, card)

	mk("UIGradient", {
		Color = ColorSequence.new(Color3.fromRGB(255, 255, 255)),
		Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 1),
			NumberSequenceKeypoint.new(0.5, 0.8),
			NumberSequenceKeypoint.new(1, 1)
		}),
		Rotation = 20,
	}, shine)

	task.spawn(function()
		while card and card.Parent do
			TweenService:Create(shine, TweenInfo.new(2, Enum.EasingStyle.Linear), {
				Position = UDim2.new(1.3, 0, 0, 0)
			}):Play()
			task.wait(3.5)
			if shine and shine.Parent then
				shine.Position = UDim2.new(-0.3, 0, 0, 0)
			end
		end
	end)

	local leftSection = mk("Frame", {
		Name               = "LeftSection",
		Size               = UDim2.new(SIZES.LEFT_SECTION_W, 0, 1, 0),
		BackgroundTransparency = 1,
		ClipsDescendants   = true,
	}, card)

	local iconContainer = mk("Frame", {
		Name                = "IconContainer",
		Size                = UDim2.new(0, SIZES.ICON_SIZE, 0, SIZES.ICON_SIZE),
		Position            = UDim2.new(0.5, 0, 0, 20),
		AnchorPoint         = Vector2.new(0.5, 0),
		BackgroundColor3    = ThemeModule.Colors.BackgroundLight,
		BackgroundTransparency = 0,
	}, leftSection)
	crn(SIZES.ICON_SIZE / 2, iconContainer)

	mk("UIStroke", {
		Thickness   = 2,
		Color       = ThemeModule.Colors.Border,
		Transparency = 0.2,
	}, iconContainer)

	mk("TextLabel", {
		Name               = "Icon",
		Size               = UDim2.new(1, 0, 1, 0),
		BackgroundTransparency = 1,
		Text               = passData.Icon,
		TextSize           = 32,
		Font               = Enum.Font.GothamBold,
		TextColor3         = COLORS.Text.Primary,
	}, iconContainer)

	local titleYPos = 20 + SIZES.ICON_SIZE + 12
	local titleLabel = mk("TextLabel", {
		Name               = "Title",
		Size               = UDim2.new(1, -16, 0, 24),
		Position           = UDim2.new(0.5, 0, 0, titleYPos),
		AnchorPoint        = Vector2.new(0.5, 0),
		BackgroundTransparency = 1,
		Text               = passData.Name,
		TextSize           = SIZES.TITLE_TEXT,
		Font               = Enum.Font.GothamBold,
		TextColor3         = Color3.fromRGB(255, 255, 255),
		TextTruncate       = Enum.TextTruncate.AtEnd,
	}, leftSection)
	addTextGradient(titleLabel, true, 1)

	local priceYPos = titleYPos + 28
	local priceLabel = mk("TextLabel", {
		Name               = "Price",
		Size               = UDim2.new(1, -16, 0, 20),
		Position           = UDim2.new(0.5, 0, 0, priceYPos),
		AnchorPoint        = Vector2.new(0.5, 0),
		BackgroundTransparency = 1,
		Text               = "💎 Memuat...",
		TextSize           = SIZES.PRICE_TEXT,
		Font               = Enum.Font.GothamMedium,
		TextColor3         = COLORS.Text.Gold,
		TextTruncate       = Enum.TextTruncate.AtEnd,
	}, leftSection)

	local rightSection = mk("Frame", {
		Name               = "RightSection",
		Size               = UDim2.new(1 - SIZES.LEFT_SECTION_W, -16, 1, -16),
		Position           = UDim2.new(SIZES.LEFT_SECTION_W, 8, 0, 8),
		BackgroundTransparency = 1,
		ClipsDescendants   = true,
	}, card)

	local benefitsContainer = mk("ScrollingFrame", {
		Name                  = "Benefits",
		Size                  = UDim2.new(1, 0, 1, -(SIZES.BUTTON_H + 16)),
		BackgroundTransparency = 1,
		BorderSizePixel       = 0,
		ScrollBarThickness    = 0,
		ScrollBarImageTransparency = 1,
		ScrollingEnabled      = true,
		VerticalScrollBarInset = Enum.ScrollBarInset.None,
		CanvasSize            = UDim2.new(0, 0, 0, 0),
		AutomaticCanvasSize   = Enum.AutomaticSize.Y,
		ScrollingDirection    = Enum.ScrollingDirection.Y,
		ClipsDescendants      = true,
	}, rightSection)

	mk("UIListLayout", {
		FillDirection     = Enum.FillDirection.Vertical,
		VerticalAlignment = Enum.VerticalAlignment.Top,
		Padding           = UDim.new(0, 6),
	}, benefitsContainer)

	mk("UIPadding", {
		PaddingTop   = UDim.new(0, 4),
		PaddingLeft  = UDim.new(0, 4),
		PaddingRight = UDim.new(0, 4),
	}, benefitsContainer)

	for i, benefit in ipairs(passData.Benefits) do
		local benefitFrame = mk("Frame", {
			Name          = "BenefitFrame" .. i,
			Size          = UDim2.new(1, 0, 0, 0),
			AutomaticSize = Enum.AutomaticSize.Y,
			BackgroundTransparency = 1,
			LayoutOrder   = i,
		}, benefitsContainer)

		mk("TextLabel", {
			Name               = "Check",
			Size               = UDim2.new(0, 18, 0, 18),
			Position           = UDim2.new(0, 0, 0, 0),
			BackgroundTransparency = 1,
			Text               = "✓",
			TextSize           = SIZES.BENEFIT_CHECK_TEXT,
			Font               = Enum.Font.GothamBold,
			TextColor3         = colors.Primary,
		}, benefitFrame)

		mk("TextLabel", {
			Name               = "Text",
			Size               = UDim2.new(1, -24, 0, 0),
			AutomaticSize      = Enum.AutomaticSize.Y,
			Position           = UDim2.new(0, 22, 0, 0),
			BackgroundTransparency = 1,
			Text               = benefit,
			TextSize           = SIZES.BENEFIT_TEXT,
			Font               = Enum.Font.GothamMedium,
			TextColor3         = COLORS.Text.Secondary,
			TextXAlignment     = Enum.TextXAlignment.Left,
			TextYAlignment     = Enum.TextYAlignment.Top,
			TextWrapped        = true,
		}, benefitFrame)
	end

	local buyButton = mk("TextButton", {
		Name               = "BuyButton",
		Size               = UDim2.new(1, -8, 0, SIZES.BUTTON_H),
		Position           = UDim2.new(0.5, 0, 1, -4),
		AnchorPoint        = Vector2.new(0.5, 1),
		BackgroundColor3   = COLORS.Button.Loading,
		Text               = "⏳ Memuat...",
		TextSize           = SIZES.BUTTON_TEXT,
		Font               = Enum.Font.GothamBold,
		TextColor3         = COLORS.Text.Primary,
		AutoButtonColor    = false,
		ClipsDescendants   = true,
	}, rightSection)
	crn(SIZES.CORNER_MD, buyButton)

	local btnStroke = addAnimatedStrokeGradient(buyButton, 2, 2)
	if btnStroke then btnStroke.Transparency = 0.4 end

	buyButton.MouseEnter:Connect(function()
		if buyButton.Active then
			SoundSystem.PlayHover()
			TweenService:Create(buyButton, TweenInfo.new(0.2), {
				Size = UDim2.new(1, -4, 0, SIZES.BUTTON_H + 2)
			}):Play()
		end
	end)

	buyButton.MouseLeave:Connect(function()
		TweenService:Create(buyButton, TweenInfo.new(0.2), {
			Size = UDim2.new(1, -8, 0, SIZES.BUTTON_H)
		}):Play()
	end)

	GamepassData[passType].Frame      = card
	GamepassData[passType].Button     = buyButton
	GamepassData[passType].PriceLabel = priceLabel

	return card
end

local function buildGamePassUI()
	if uiBuilt then return end

	for _, child in pairs(gamepassPage:GetChildren()) do
		if child:IsA("Frame") or child:IsA("ScrollingFrame") then
			child:Destroy()
		end
	end

	local scrollFrame = mk("ScrollingFrame", {
		Name                  = "GamePassScroll",
		Size                  = UDim2.new(1, 0, 1, 0),
		BackgroundTransparency = 1,
		BorderSizePixel       = 0,
		ScrollBarThickness    = 0,
		ScrollBarImageTransparency = 1,
		ScrollingEnabled      = true,
		VerticalScrollBarInset = Enum.ScrollBarInset.None,
		CanvasSize            = UDim2.new(0, 0, 0, 0),
		AutomaticCanvasSize   = Enum.AutomaticSize.Y,
		ScrollingDirection    = Enum.ScrollingDirection.Y,
		ClipsDescendants      = true,
	}, gamepassPage)

	mk("UIListLayout", {
		FillDirection        = Enum.FillDirection.Vertical,
		HorizontalAlignment  = Enum.HorizontalAlignment.Center,
		Padding              = UDim.new(0, SIZES.SPACING),
		SortOrder            = Enum.SortOrder.LayoutOrder,
	}, scrollFrame)

	mk("UIPadding", {
		PaddingTop    = UDim.new(0, SIZES.SCROLL_PAD),
		PaddingBottom = UDim.new(0, SIZES.SCROLL_PAD),
		PaddingLeft   = UDim.new(0, SIZES.SCROLL_PAD),
		PaddingRight  = UDim.new(0, SIZES.SCROLL_PAD),
	}, scrollFrame)

	local headerFrame = mk("Frame", {
		Name               = "Header",
		Size               = UDim2.new(1, 0, 0, SIZES.HEADER_H),
		BackgroundTransparency = 1,
		LayoutOrder        = 0,
	}, scrollFrame)

	local headerTitle = mk("TextLabel", {
		Name               = "Title",
		Size               = UDim2.new(1, 0, 0, 28),
		BackgroundTransparency = 1,
		Text               = "👑 Toko VIP Premium",
		TextSize           = SIZES.HEADER_TITLE_TEXT,
		Font               = Enum.Font.GothamBold,
		TextColor3         = Color3.fromRGB(255, 255, 255),
		TextTruncate       = Enum.TextTruncate.AtEnd,
	}, headerFrame)
	addTextGradient(headerTitle, true, 0.8)

	mk("TextLabel", {
		Name               = "Subtitle",
		Size               = UDim2.new(1, 0, 0, 18),
		Position           = UDim2.new(0, 0, 0, 32),
		BackgroundTransparency = 1,
		Text               = "Tingkatkan pengalamanmu dengan VIP premium!",
		TextSize           = SIZES.HEADER_SUB_TEXT,
		Font               = Enum.Font.GothamMedium,
		TextColor3         = COLORS.Text.Secondary,
		TextTruncate       = Enum.TextTruncate.AtEnd,
	}, headerFrame)

	createGamePassCard("VIP", GamepassData.VIP, COLORS.VIP, scrollFrame)

	notifContainer = mk("Frame", {
		Name               = "NotificationContainer",
		Size               = UDim2.new(1, -20, 0, 50),
		Position           = UDim2.new(0.5, 0, 1, -10),
		AnchorPoint        = Vector2.new(0.5, 1),
		BackgroundTransparency = 1,
		Visible            = false,
		ZIndex             = 1005,
	}, gamepassPage)

	notifFrame = mk("Frame", {
		Name               = "NotifFrame",
		Size               = UDim2.new(1, 0, 0, 46),
		Position           = UDim2.new(0.5, 0, 0.5, 0),
		AnchorPoint        = Vector2.new(0.5, 0.5),
		BackgroundColor3   = Color3.fromRGB(30, 30, 45),
		ZIndex             = 1006,
		ClipsDescendants   = true,
	}, notifContainer)
	crn(SIZES.CORNER_MD, notifFrame)

	mk("UIStroke", { Thickness = 1.5 }, notifFrame)

	notifText = mk("TextLabel", {
		Name               = "Text",
		Size               = UDim2.new(1, -20, 1, 0),
		Position           = UDim2.new(0.5, 0, 0.5, 0),
		AnchorPoint        = Vector2.new(0.5, 0.5),
		BackgroundTransparency = 1,
		Text               = "",
		TextSize           = 12,
		Font               = Enum.Font.GothamMedium,
		TextColor3         = COLORS.Text.Primary,
		TextWrapped        = true,
		ZIndex             = 1007,
	}, notifFrame)

	uiBuilt = true
	print("[GamePass] ✅ Antarmuka berhasil dibuat!")
end

local function loadShopData()
	if shopDataLoaded then return end

	if not remotes or not remotes.shopRequest then
		print("[GamePass] Mode demo - mengatur harga contoh")
		updatePriceLabel("VIP", 499)
		setButtonState("VIP", "Buy")
		shopDataLoaded = true
		return
	end

	setButtonState("VIP", "Loading")

	local ok, shopData = pcall(function()
		return remotes.shopRequest:InvokeServer({ action = "GetShopData" })
	end)

	if ok and shopData and shopData.success then
		if shopData.gamepasses and shopData.gamepasses.VIP then
			local passData = shopData.gamepasses.VIP
			GamepassData.VIP.IDs   = passData.ids   or {}
			GamepassData.VIP.Owned = passData.owned or false
			GamepassData.VIP.Price = passData.price or 0

			updatePriceLabel("VIP", GamepassData.VIP.Price)
			setButtonState("VIP", passData.owned and "Owned" or "Buy")
		else
			setButtonState("VIP", "Error")
		end

		shopDataLoaded = true
		print("[GamePass] ✅ Data toko berhasil dimuat")
	else
		setButtonState("VIP", "Error")
		showNotification("Gagal memuat data toko!", false)
	end
end

local function promptPurchase(passType)
	local data = GamepassData[passType]
	if not data then return end

	SoundSystem.PlayClick()

	if data.Owned then
		showNotification("Kamu sudah memiliki " .. data.Name .. "!", false)
		return
	end

	if not remotes or not remotes.shopRequest then
		showNotification("Mode demo - pembelian tidak tersedia", false)
		return
	end

	local ok, result = pcall(function()
		return remotes.shopRequest:InvokeServer({
			action       = "PromptPurchase",
			gamepassType = passType
		})
	end)

	if ok and result then
		if not result.success then
			if result.error == "Already owned" then
				showNotification("Kamu sudah memiliki gamepass ini!", false)
				handleOwnershipUpdate(passType, true)
			else
				showNotification("Gagal membuka pembelian!", false)
			end
		end

	else
		showNotification("Error saat memproses pembelian!", false)
	end
end

local function setupButtonConnections()
	local data = GamepassData.VIP
	if data.Button then
		data.Button.MouseButton1Click:Connect(function()
			promptPurchase("VIP")
		end)
	end
end

if remotes and remotes.playerDataUpdated then
	remotes.playerDataUpdated.OnClientEvent:Connect(function(updateData)
		if updateData.type == "ownership_updated" or updateData.type == "purchase_complete" then
			handleOwnershipUpdate(updateData.gamepassType, true)
		end
	end)
end

MarketplaceService.PromptGamePassPurchaseFinished:Connect(function(player, gamepassId, purchaseSuccess)
	if not purchaseSuccess then return end

	for passType, data in pairs(GamepassData) do
		for _, id in ipairs(data.IDs) do
			if id == gamepassId then
				print(string.format("[GamePass] ✅ Purchase confirmed instantly: %s (ID: %d)", passType, gamepassId))
				handleOwnershipUpdate(passType, true)
				return
			end
		end
	end
end)

if MenuConfig and MenuConfig.Events and MenuConfig.Events.OnTabChanged then
	MenuConfig.Events.OnTabChanged.Event:Connect(function(tabName)
		if tabName == "Toko" then
			if not uiBuilt then
				buildGamePassUI()
				setupButtonConnections()
			end
			if not shopDataLoaded then
				task.spawn(function()
					task.wait(0.3)
					loadShopData()
				end)
			end
		end
	end)
end

if MenuConfig and MenuConfig.Events and MenuConfig.Events.OnColorChanged then
	MenuConfig.Events.OnColorChanged.Event:Connect(function()
		for _, passType in ipairs({"VIP", "VVIP"}) do
			local data = GamepassData[passType]
			if data and data.Frame then
				for _, desc in ipairs(data.Frame:GetDescendants()) do
					if desc:IsA("UIGradient") and desc.Name == "StrokeGradient" and ThemeModule and ThemeModule.Gradients then
						desc.Color = ThemeModule.Gradients.Primary
					end
				end
			end
		end
	end)
end

task.spawn(function()
	task.wait(0.5)
	buildGamePassUI()
	setupButtonConnections()

	if Player.Character then
		task.wait(1)
	else
		Player.CharacterAdded:Wait()
		task.wait(2)
	end

	loadShopData()
	print("[GamePass] ✅ Initialized (Toko Tab - Fixed Layout)!")
end)
