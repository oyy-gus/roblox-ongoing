local replicatedStorage = game:GetService("ReplicatedStorage")
local players = game:GetService("Players")
local ServerStorage = game:GetService("ServerStorage")

local BroadcastConfig = require(script.BroadcastConfig)
local BroadcastDebug = require(script.BroadcastDebug)
local SecurityModule = require(script.SecurityModule)
local QueueModule = require(script.QueueModule)
local MessageModule = require(script.MessageModule)
local ReceiptDispatcher = require(ServerStorage:WaitForChild("Modules"):WaitForChild("ReceiptDispatcher"))

local broadcastRemote = Instance.new("RemoteFunction")
broadcastRemote.Name = "BroadcastDonationMessage"
broadcastRemote.Parent = replicatedStorage

local receiveRemote = Instance.new("RemoteEvent")
receiveRemote.Name = "ReceiveDonationBroadcast"
receiveRemote.Parent = replicatedStorage

local function getRandomAutoMessage()
	local messages = BroadcastConfig.AUTO_MESSAGES
	return messages[math.random(1, #messages)]
end

broadcastRemote.OnServerInvoke = function(player, message, amount)
	BroadcastDebug.log("BROADCAST", player.Name, "requesting broadcast. Amount:", amount)

	if not player or not player.Parent then
		return false, "Player tidak valid"
	end

	if type(message) ~= "string" or #message < 1 then
		return false, "Pesan tidak valid"
	end

	if #message > BroadcastConfig.BROADCAST.MAX_MESSAGE_LENGTH then
		return false, "Pesan terlalu panjang"
	end

	if type(amount) ~= "number" then
		BroadcastDebug.warn("SECURITY", player.Name, "sent invalid amount type:", type(amount))
		return false, "Donasi tidak valid"
	end

	if amount < BroadcastConfig.BROADCAST.MIN_DONATION then
		return false, "Donasi tidak mencukupi"
	end

	return QueueModule.addToQueue(player, message, amount, receiveRemote)
end

local function processReceipt(receiptInfo)
	local userId = receiptInfo.PlayerId
	local productId = receiptInfo.ProductId
	local amount = BroadcastConfig.PRODUCT_PRICES[productId]

	if not amount then
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end

	local player = players:GetPlayerByUserId(userId)
	if player then
		SecurityModule.handlePurchaseReceipt(player, productId)
		BroadcastDebug.log("BROADCAST", "Purchase detected:", player.Name, "-", amount, "R$")

		if BroadcastConfig.BROADCAST.AUTO_MESSAGE_ENABLED and amount < BroadcastConfig.BROADCAST.AUTO_MESSAGE_THRESHOLD then
			BroadcastDebug.log("BROADCAST", "Triggering auto broadcast for small donation")
			local autoMessage = getRandomAutoMessage()

			task.spawn(function()
				local success, result = QueueModule.addToQueue(player, autoMessage, amount, receiveRemote, true)
				if success then
					BroadcastDebug.log("BROADCAST", "Auto broadcast queued:", player.Name)
				else
					BroadcastDebug.warn("KESALAHAN", "Broadcast otomatis gagal:", result)
				end
			end)
		else
			BroadcastDebug.log("BROADCAST", "Amount >= threshold or auto message disabled, no auto broadcast")
		end
	end

	return Enum.ProductPurchaseDecision.PurchaseGranted
end

ReceiptDispatcher.RegisterHandler("DonationBroadcast", processReceipt)

players.PlayerRemoving:Connect(function(player)
	QueueModule.cleanupPlayer(player)
	SecurityModule.cleanupPlayer(player)
	BroadcastDebug.log("BROADCAST", "Cleaned up data for:", player.Name)
end)

task.spawn(function()
	while true do
		task.wait(60)
		SecurityModule.cleanupExpiredPurchases()
	end
end)

BroadcastDebug.log("LOADING", "Donation Broadcast Handler initialized")
