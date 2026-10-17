local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local MarketplaceService = game:GetService("MarketplaceService")

local ReceiptDispatcher = require(ServerStorage:WaitForChild("Modules"):WaitForChild("ReceiptDispatcher"))

local remotesFolder = ReplicatedStorage:FindFirstChild("Remotes")
if not remotesFolder then
	remotesFolder = Instance.new("Folder")
	remotesFolder.Name = "Remotes"
	remotesFolder.Parent = ReplicatedStorage
end

local showDonationGUI = remotesFolder:FindFirstChild("ShowDonationGUI")
if not showDonationGUI then
	showDonationGUI = Instance.new("RemoteEvent")
	showDonationGUI.Name = "ShowDonationGUI"
	showDonationGUI.Parent = remotesFolder
end

showDonationGUI.OnServerEvent:Connect(function(player)
	player:Kick("Exploit Detection: Unauthorized RemoteEvent call")
end)

local DISPLAY_DURATION = 5
local PURCHASE_COOLDOWN = 5
local recentPurchases = {}
local processedReceipts = {}

local templateDonation = ServerStorage:FindFirstChild("TemplateDonation")

local function getPriceRanges()
	if not templateDonation then
		return {}
	end

	return {
		{
			name = "Level 1",
			minPrice = 50,
			maxPrice = 99,
			templatePath = templateDonation:FindFirstChild("Level1")
		},
		{
			name = "Level 2",
			minPrice = 100,
			maxPrice = 199,
			templatePath = templateDonation:FindFirstChild("Level2")
		},
		{
			name = "Level 3",
			minPrice = 200,
			maxPrice = 9999999,
			templatePath = templateDonation:FindFirstChild("Level3")
		},
	}
end

local function getProductPrice(productId: number): number
	local success, result = pcall(function()
		return MarketplaceService:GetProductInfo(productId, Enum.InfoType.Product)
	end)

	if success and result and result.PriceInRobux then
		return result.PriceInRobux
	end

	return 0
end

local function canProcessPurchase(userId: number, productId: number): boolean
	local key = tostring(userId) .. "_" .. tostring(productId) .. "_" .. tostring(tick())

	for existingKey, timestamp in pairs(recentPurchases) do
		if existingKey:match("^" .. tostring(userId) .. "_" .. tostring(productId)) then
			if (tick() - timestamp) < PURCHASE_COOLDOWN then
				return false
			end
		end
	end

	recentPurchases[key] = tick()

	task.delay(PURCHASE_COOLDOWN + 1, function()
		recentPurchases[key] = nil
	end)

	return true
end

local function getPlayerName(userId: number): string
	local player = Players:GetPlayerByUserId(userId)
	if player then
		return player.DisplayName
	end

	local success, username = pcall(function()
		return Players:GetNameFromUserIdAsync(userId)
	end)

	if success and username then
		return username
	end

	return "Player" .. tostring(userId)
end

local function getTemplateByPrice(price: number)
	for _, range in ipairs(getPriceRanges()) do
		if price >= range.minPrice and price <= range.maxPrice then
			return range.templatePath, range.name
		end
	end
	return nil, nil
end

local function displayDonationObject(player: Player, template: Instance, donationName: string)
	local character = player.Character
	if not character then return end

	local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
	if not humanoidRootPart or not template then return end

	local donationObject = template:Clone()

	if donationObject:IsA("Model") then
		if donationObject.PrimaryPart then
			donationObject:SetPrimaryPartCFrame(humanoidRootPart.CFrame)
		else
			donationObject:Destroy()
			return
		end
	elseif donationObject:IsA("BasePart") then
		donationObject.CFrame = humanoidRootPart.CFrame
	end

	local weld = Instance.new("WeldConstraint")
	weld.Part0 = humanoidRootPart

	if donationObject:IsA("Model") and donationObject.PrimaryPart then
		weld.Part1 = donationObject.PrimaryPart
	elseif donationObject:IsA("BasePart") then
		weld.Part1 = donationObject
	end

	weld.Parent = donationObject
	donationObject.Parent = workspace

	task.delay(DISPLAY_DURATION, function()
		if donationObject and donationObject.Parent then
			donationObject:Destroy()
		end
	end)
end

local function grantDonationEffect(userId: number, productId: number, price: number): boolean
	if not canProcessPurchase(userId, productId) then
		return false
	end

	local player = Players:GetPlayerByUserId(userId)
	if not player then
		return false
	end

	local template, donationName = getTemplateByPrice(price)
	if not template then
		return false
	end

	pcall(function()
		displayDonationObject(player, template, donationName)
	end)

	local playerName = getPlayerName(userId)
	showDonationGUI:FireAllClients(playerName, price, donationName)

	return true
end

local function handleDonationReceipt(receiptInfo)
	if not receiptInfo or not receiptInfo.PlayerId or not receiptInfo.ProductId then
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end

	local receiptKey = tostring(receiptInfo.PlayerId) .. "_" .. tostring(receiptInfo.ProductId) .. "_" .. tostring(receiptInfo.PurchaseId or os.time())

	if processedReceipts[receiptKey] then
		return Enum.ProductPurchaseDecision.PurchaseGranted
	end

	local userId = receiptInfo.PlayerId
	local productId = receiptInfo.ProductId
	local price = getProductPrice(productId)

	if price == 0 then
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end

	processedReceipts[receiptKey] = true

	grantDonationEffect(userId, productId, price)

	task.delay(60, function()
		processedReceipts[receiptKey] = nil
	end)

	return Enum.ProductPurchaseDecision.PurchaseGranted
end

ReceiptDispatcher.RegisterHandler("DonationDisplay", handleDonationReceipt)

MarketplaceService.PromptProductPurchaseFinished:Connect(function(playerOrUserId, productId, wasPurchased)
	if not wasPurchased then return end

	local userId
	if type(playerOrUserId) == "number" then
		userId = playerOrUserId
	elseif typeof(playerOrUserId) == "Instance" and playerOrUserId:IsA("Player") then
		userId = playerOrUserId.UserId
	else
		return
	end

	task.wait(1)
	local price = getProductPrice(productId)
	if price > 0 then
		grantDonationEffect(userId, productId, price)
	end
end)
