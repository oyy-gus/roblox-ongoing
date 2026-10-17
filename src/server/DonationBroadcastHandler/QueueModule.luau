local BroadcastConfig = require(script.Parent.BroadcastConfig)
local BroadcastDebug = require(script.Parent.BroadcastDebug)
local SecurityModule = require(script.Parent.SecurityModule)
local MessageModule = require(script.Parent.MessageModule)

local QueueModule = {}

local broadcastQueue = {}
local isProcessingQueue = false
local playerCooldowns = {}

local function getPlayerQueueCount(userId)
	local count = 0
	for _, broadcast in ipairs(broadcastQueue) do
		if broadcast.userId == userId then
			count = count + 1
		end
	end
	return count
end

local function processQueue(receiveRemote)
	if isProcessingQueue then return end
	isProcessingQueue = true

	while #broadcastQueue > 0 do
		local broadcast = table.remove(broadcastQueue, 1)

		BroadcastDebug.log("QUEUE", "Processing:", broadcast.displayName, "Queue:", #broadcastQueue)

		if receiveRemote then

			receiveRemote:FireAllClients(
				broadcast.displayName,
				broadcast.amount,
				broadcast.message,
				broadcast.userId
			)
			BroadcastDebug.log("BROADCAST", "Sent:", broadcast.displayName, "-", broadcast.amount, "R$ - UserId:", broadcast.userId)
		end

		task.wait(BroadcastConfig.BROADCAST.DISPLAY_DURATION + BroadcastConfig.BROADCAST.QUEUE_DELAY)
	end

	isProcessingQueue = false
	BroadcastDebug.log("QUEUE", "Queue processing finished")
end

function QueueModule.addToQueue(player, message, amount, receiveRemote, skipSecurity)

	if not skipSecurity then
		if not SecurityModule.verifyPurchase(player, amount) then
			BroadcastDebug.warn("SECURITY", "REJECTED:", player.Name)

			if BroadcastConfig.SECURITY.KICK_ON_FAKE then
				player:Kick("Fake donation detected")
				BroadcastDebug.warn("SECURITY", "KICKED:", player.Name)
			end

			return false, "Donasi tidak terverifikasi"
		end
	end

	if amount < BroadcastConfig.BROADCAST.MIN_DONATION then
		BroadcastDebug.warn("KESALAHAN", player.Name, "donasi tidak mencukupi:", amount)
		return false, "Donasi minimal " .. BroadcastConfig.BROADCAST.MIN_DONATION .. " Robux"
	end

	if BroadcastConfig.ANTISPAM.ENABLED then
		local currentTime = tick()
		local lastTime = playerCooldowns[player.UserId] or 0

		if currentTime - lastTime < BroadcastConfig.ANTISPAM.COOLDOWN then
			local remaining = math.ceil(BroadcastConfig.ANTISPAM.COOLDOWN - (currentTime - lastTime))
			BroadcastDebug.warn("KESALAHAN", player.Name, "sedang cooldown:", remaining, "detik")
			return false, "Cooldown: " .. remaining .. " detik lagi"
		end

		playerCooldowns[player.UserId] = currentTime
	end

	local playerQueueCount = getPlayerQueueCount(player.UserId)
	if playerQueueCount >= BroadcastConfig.ANTISPAM.MAX_QUEUE_PER_PLAYER then
		BroadcastDebug.warn("KESALAHAN", player.Name, "melebihi batas antrean:", playerQueueCount)
		return false, "Anda sudah memiliki " .. playerQueueCount .. " pesan dalam antrian"
	end

	if #broadcastQueue >= BroadcastConfig.ANTISPAM.MAX_QUEUE then
		BroadcastDebug.warn("KESALAHAN", "Antrean penuh:", #broadcastQueue)
		return false, "Antrian penuh, coba lagi nanti"
	end

	local filteredMessage = MessageModule.filterMessage(message)

	table.insert(broadcastQueue, {
		userId = player.UserId,
		displayName = player.DisplayName,
		amount = amount,
		message = filteredMessage,
		timestamp = tick()
	})

	BroadcastDebug.log("QUEUE", "Added:", player.DisplayName, "- UserId:", player.UserId, "- Queue:", #broadcastQueue)

	task.spawn(function()
		processQueue(receiveRemote)
	end)

	return true, "Pesan ditambahkan ke antrian"
end

function QueueModule.cleanupPlayer(player)
	playerCooldowns[player.UserId] = nil

	for i = #broadcastQueue, 1, -1 do
		if broadcastQueue[i].userId == player.UserId then
			table.remove(broadcastQueue, i)
		end
	end
end

return QueueModule
