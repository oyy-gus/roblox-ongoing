local Logger = require(script.Parent.Logger)

local DataStoreService = game:GetService("DataStoreService")

local DataStoreManager = {}
DataStoreManager.FailedGivesStore = DataStoreService:GetDataStore("FailedGives_v1")
DataStoreManager.TransactionLogStore = DataStoreService:GetDataStore("TransactionLog_v1")

function DataStoreManager:LogTransaction(data)
	local success = pcall(function()
		local key = "log_" .. os.time() .. "_" .. data.giver
		self.TransactionLogStore:SetAsync(key, data, 2592000)
	end)

	if not success then
		Logger:Warn("Failed to log transaction")
	else
		Logger:Transaction("Transaction logged: " .. data.type)
	end
end

function DataStoreManager:LogFailedGive(giverUserId, targetUserId, targetName, gamepassType, reason)
	local success = pcall(function()
		local key = "failed_" .. giverUserId .. "_" .. tick()
		local data = {
			giver = giverUserId,
			target = targetUserId,
			targetName = targetName,
			gamepassType = gamepassType,
			reason = reason,
			timestamp = os.time(),
			canRetry = true
		}

		self.FailedGivesStore:SetAsync(key, data, 2592000)

		Logger:Transaction(string.format("Logged failed give: %s -> %s (%s) Reason: %s",
			giverUserId, targetName, gamepassType, reason))
	end)

	if not success then
		Logger:Warn("Failed to save failed give log")
	end
end

function DataStoreManager:LogExpiredTransaction(transactionId, data)
	Logger:Info(string.format("Transaction expired: %s (Giver: %d, Target: %d, Type: %s)",
		transactionId, data.giver, data.target, data.gamepassType))

	self:LogTransaction({
		type = "expired",
		giver = data.giver,
		target = data.target,
		gamepassType = data.gamepassType,
		timestamp = os.time()
	})
end

return DataStoreManager
