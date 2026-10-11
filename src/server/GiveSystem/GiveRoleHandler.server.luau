-- ====================================
-- GIVE ROLE HANDLER - VIP + STREAMER + CREATOR VERSION
-- Location: ServerScriptService > GiveSystem(Folder) > GiveRoleHandler(Script)
-- ====================================

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local DataStoreService = game:GetService("DataStoreService")
local MarketplaceService = game:GetService("MarketplaceService")

local RoleSystem = require(ServerStorage:WaitForChild("Modules"):WaitForChild("RoleSystem"))
local GiveRoleConfig = require(ReplicatedStorage:WaitForChild("GiveModule"):WaitForChild("GiveRoleConfig"))

-- ====================================
-- DEBUG HELPER
-- ====================================
local function debugPrint(...)
	if GiveRoleConfig.Debug.ENABLE_DEBUG and GiveRoleConfig.Debug.SHOW_SERVER_LOGS then
		print("[GiveRole]", ...)
	end
end

local function debugDispatch(...)
	if GiveRoleConfig.Debug.ENABLE_DEBUG and GiveRoleConfig.Debug.SHOW_DISPATCH_LOGS then
		print("[GiveRole]", ...)
	end
end

local function debugReceipt(...)
	if GiveRoleConfig.Debug.ENABLE_DEBUG and GiveRoleConfig.Debug.SHOW_RECEIPT_LOGS then
		print("[GiveRole]", ...)
	end
end

local transactionStore = DataStoreService:GetDataStore(GiveRoleConfig.DataStores.TRANSACTION_HISTORY)
local pendingGiftStore = DataStoreService:GetDataStore(GiveRoleConfig.DataStores.PENDING_GIFTS)

local giveRoleRemote = ReplicatedStorage:FindFirstChild("GiveRoleRemote")
if not giveRoleRemote then
	giveRoleRemote = Instance.new("RemoteEvent")
	giveRoleRemote.Name = "GiveRoleRemote"
	giveRoleRemote.Parent = ReplicatedStorage
	debugPrint("Created GiveRoleRemote")
else
	debugPrint("Using existing GiveRoleRemote")
end

-- ====================================
-- ADMIN ROLES CONFIGURATION
-- ====================================
local ADMIN_ROLES = {Owner = true, Developer = true, Admin = true}

local function isAdmin(player)
	return ADMIN_ROLES[RoleSystem:GetPlayerRole(player)] == true
end

-- ====================================
-- ROLE VALIDATION HELPERS
-- ====================================

local function isAdminPanelRole(roleType)
	for _, r in ipairs(GiveRoleConfig.AdminPanelRoles) do
		if r == roleType then
			return true
		end
	end
	return false
end

local function isPlayerMenuRole(roleType)
	for _, r in ipairs(GiveRoleConfig.PlayerMenuRoles) do
		if r == roleType then
			return true
		end
	end
	return false
end

-- ====================================
-- DATASTORE HELPERS
-- ====================================

local function datastoreRetry(operation, maxAttempts)
	maxAttempts = maxAttempts or GiveRoleConfig.Settings.MAX_RETRY_ATTEMPTS
	for attempt = 1, maxAttempts do
		local success, result = pcall(operation)
		if success then return true, result end
		if attempt < maxAttempts then task.wait(GiveRoleConfig.Settings.RETRY_DELAY) end
	end
	return false, nil
end

local function saveTransaction(giverUserId, targetUserId, roleType, productId, receiptInfo)
	local key = string.format("txn_%d_%d_%d", giverUserId, targetUserId, os.time())
	return datastoreRetry(function()
		transactionStore:SetAsync(key, {
			giver = giverUserId,
			target = targetUserId,
			roleType = roleType,
			productId = productId,
			timestamp = os.time(),
			receiptInfo = receiptInfo
		})
	end)
end

local function savePendingGift(purchaserUserId, targetUserId, roleType)
	local key = "pending_" .. tostring(purchaserUserId)
	return datastoreRetry(function()
		pendingGiftStore:SetAsync(key, {
			target = targetUserId,
			roleType = roleType,
			timestamp = os.time()
		})
	end)
end

local function getPendingGift(purchaserUserId)
	local key = "pending_" .. tostring(purchaserUserId)
	local success, result = datastoreRetry(function()
		return pendingGiftStore:GetAsync(key)
	end)
	return success and result or nil
end

local function clearPendingGift(purchaserUserId)
	local key = "pending_" .. tostring(purchaserUserId)
	pcall(function() pendingGiftStore:RemoveAsync(key) end)
end

-- ====================================
-- CHECK PLAYER ROLE (FOR PLAYER MENU - VIP ONLY)
-- ====================================

local function checkPlayerRoleForVIP(player)
	local currentRole = RoleSystem:GetPlayerRole(player)
	local hasVIP = RoleSystem:HasVIP(player)

	if hasVIP then
		return {
			canReceive = false,
			reason = "has_vip",
			message = "Player sudah memiliki VIP",
			currentRole = currentRole,
			hasVIP = true,
			canReceiveVIP = false
		}
	end

	return {
		canReceive = true,
		reason = "eligible",
		message = "Player dapat menerima VIP",
		currentRole = currentRole,
		hasVIP = false,
		canReceiveVIP = true
	}
end

-- ====================================
-- CHECK PLAYER ROLE (FOR ADMIN PANEL - VIP + STREAMER + CREATOR)
-- Semua role bisa diberikan ke siapa saja
-- ====================================

local function checkPlayerRoleForAdmin(player, roleType)
	-- VIP check
	if roleType == "VIP" then
		if RoleSystem:HasVIP(player) then
			return {
				canReceive = false,
				reason = "has_role",
				message = "Player sudah memiliki VIP"
			}
		end
		return {
			canReceive = true,
			reason = "eligible",
			message = "Player dapat menerima VIP"
		}
	end

	-- Streamer check
	if roleType == "Streamer" then
		if RoleSystem:HasStreamer(player) then
			return {
				canReceive = false,
				reason = "has_role",
				message = "Player sudah memiliki role Streamer"
			}
		end
		return {
			canReceive = true,
			reason = "eligible",
			message = "Player dapat menerima role Streamer"
		}
	end

	-- Creator check
	if roleType == "Creator" then
		if RoleSystem:HasCreator(player) then
			return {
				canReceive = false,
				reason = "has_role",
				message = "Player sudah memiliki role Creator"
			}
		end
		return {
			canReceive = true,
			reason = "eligible",
			message = "Player dapat menerima role Creator"
		}
	end

	return {
		canReceive = false,
		reason = "invalid_role",
		message = "Role tidak valid"
	}
end

-- ====================================
-- PROCESS RECEIPT (FOR PLAYER MENU PURCHASES - VIP ONLY)
-- ====================================

local function processReceipt(receiptInfo)
	local purchaserUserId = receiptInfo.PlayerId
	local productId = receiptInfo.ProductId

	debugReceipt(string.format("ProcessReceipt: User %d, Product %d", purchaserUserId, productId))

	local giftData = getPendingGift(purchaserUserId)
	if not giftData then
		warn("[GiveRole] No pending gift found")
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end

	local targetUserId = giftData.target
	local roleType = giftData.roleType

	if productId ~= GiveRoleConfig.DeveloperProducts.VIP_GIFT then
		warn("[GiveRole] Product ID mismatch")
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end

	debugReceipt(string.format("Giving VIP to user %d", targetUserId))

	local success, result = RoleSystem:GiveRoleToPlayer(targetUserId, "VIP", purchaserUserId)

	if success then
		debugReceipt("✅ Role given successfully!")
		saveTransaction(purchaserUserId, targetUserId, "VIP", productId, receiptInfo)
		clearPendingGift(purchaserUserId)

		local purchaser = Players:GetPlayerByUserId(purchaserUserId)
		if purchaser then
			giveRoleRemote:FireClient(purchaser, {
				source = "PlayerMenu",
				action = "PurchaseComplete",
				success = true,
				message = "VIP role berhasil diberikan!"
			})
		end

		return Enum.ProductPurchaseDecision.PurchaseGranted
	else
		warn("[GiveRole] Failed to give role:", result)
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end
end

MarketplaceService.ProcessReceipt = processReceipt

-- ====================================
-- MAIN REQUEST HANDLER
-- ====================================

giveRoleRemote.OnServerEvent:Connect(function(player, requestData)
	if type(requestData) ~= "table" then
		warn("[GiveRole] Invalid request from", player.Name)
		return
	end

	local source = requestData.source
	local action = requestData.action

	debugDispatch(string.format("📥 Request | Player: %s | Source: %s | Action: %s", 
		player.Name, source or "nil", action or "nil"))

	-- ====================================
	-- ADMIN PANEL HANDLER (VIP + STREAMER + CREATOR - FREE)
	-- ====================================
	if source == "AdminPanel" then
		if action == "GiveRole" then
			debugPrint("📋 AdminPanel: GiveRole")

			if not isAdmin(player) then
				giveRoleRemote:FireClient(player, {
					source = "AdminPanel",
					success = false,
					message = "Kamu tidak memiliki izin admin!"
				})
				return
			end

			local targetUserId = requestData.targetUserId
			local roleType = requestData.roleType
			local targetPlayer = Players:GetPlayerByUserId(targetUserId)

			if not targetPlayer then
				giveRoleRemote:FireClient(player, {
					source = "AdminPanel",
					success = false,
					message = "Player tidak ditemukan!"
				})
				return
			end

			if not isAdminPanelRole(roleType) then
				giveRoleRemote:FireClient(player, {
					source = "AdminPanel",
					success = false,
					message = "Role tidak valid! Hanya VIP, Streamer, dan Creator yang tersedia."
				})
				return
			end

			local roleCheck = checkPlayerRoleForAdmin(targetPlayer, roleType)
			if not roleCheck.canReceive then
				giveRoleRemote:FireClient(player, {
					source = "AdminPanel",
					success = false,
					message = roleCheck.message
				})
				return
			end

			local success, result = RoleSystem:GiveRoleToPlayer(targetUserId, roleType, player.UserId)

			if success then
				local targetDisplayName = targetPlayer.DisplayName or targetPlayer.Name or "Unknown"
				local successMessage = string.format("%s berhasil diberikan ke %s!", roleType, targetDisplayName)

				debugPrint(string.format("✅ Admin %s gave %s to %s", player.Name, roleType, targetPlayer.Name))

				saveTransaction(player.UserId, targetUserId, roleType, 0, nil)

				giveRoleRemote:FireClient(player, {
					source = "AdminPanel",
					success = true,
					message = successMessage
				})
			else
				warn(string.format("[GiveRole] Admin give failed: %s", result or "Unknown"))
				giveRoleRemote:FireClient(player, {
					source = "AdminPanel",
					success = false,
					message = "Gagal memberikan role: " .. (result or "Unknown error")
				})
			end
		else
			warn("[GiveRole] Unknown AdminPanel action:", action)
		end

		-- ====================================
		-- PLAYER MENU HANDLER (VIP ONLY - PAID)
		-- ====================================
	elseif source == "PlayerMenu" then
		if action == "CheckPlayerRole" then
			debugPrint("🎁 PlayerMenu: CheckPlayerRole")

			local targetUserId = requestData.targetUserId
			local targetPlayer = Players:GetPlayerByUserId(targetUserId)

			if not targetPlayer then
				giveRoleRemote:FireClient(player, {
					source = "PlayerMenu",
					action = "CheckResult",
					success = false,
					message = "Player tidak ditemukan"
				})
				return
			end

			giveRoleRemote:FireClient(player, {
				source = "PlayerMenu",
				action = "CheckResult",
				success = true,
				roleInfo = checkPlayerRoleForVIP(targetPlayer)
			})

		elseif action == "InitiatePurchase" then
			debugPrint("🎁 PlayerMenu: InitiatePurchase")

			local targetUserId = requestData.targetUserId
			local roleType = requestData.roleType

			if not targetUserId then
				giveRoleRemote:FireClient(player, {
					source = "PlayerMenu",
					action = "PurchaseError",
					success = false,
					message = "Invalid request data"
				})
				return
			end

			if not isPlayerMenuRole(roleType) then
				giveRoleRemote:FireClient(player, {
					source = "PlayerMenu",
					action = "PurchaseError",
					success = false,
					message = "Hanya VIP yang tersedia!"
				})
				return
			end

			if player.UserId == targetUserId then
				giveRoleRemote:FireClient(player, {
					source = "PlayerMenu",
					action = "PurchaseError",
					success = false,
					message = "Tidak dapat memberikan role ke diri sendiri!"
				})
				return
			end

			local targetPlayer = Players:GetPlayerByUserId(targetUserId)
			if not targetPlayer then
				giveRoleRemote:FireClient(player, {
					source = "PlayerMenu",
					action = "PurchaseError",
					success = false,
					message = "Player sudah meninggalkan game"
				})
				return
			end

			local roleInfo = checkPlayerRoleForVIP(targetPlayer)
			if not roleInfo.canReceive then
				giveRoleRemote:FireClient(player, {
					source = "PlayerMenu",
					action = "PurchaseError",
					success = false,
					message = roleInfo.message
				})
				return
			end

			local saved = savePendingGift(player.UserId, targetUserId, "VIP")
			if not saved then
				giveRoleRemote:FireClient(player, {
					source = "PlayerMenu",
					action = "PurchaseError",
					success = false,
					message = "Gagal menyimpan data, coba lagi"
				})
				return
			end

			local productId = GiveRoleConfig.DeveloperProducts.VIP_GIFT

			debugPrint(string.format("Prompting purchase: Product %d", productId))

			local success, errorMsg = pcall(function()
				MarketplaceService:PromptProductPurchase(player, productId)
			end)

			if not success then
				warn("[GiveRole] Failed to prompt purchase:", errorMsg)
				clearPendingGift(player.UserId)
				giveRoleRemote:FireClient(player, {
					source = "PlayerMenu",
					action = "PurchaseError",
					success = false,
					message = "Gagal membuka prompt pembayaran"
				})
			end
		else
			warn("[GiveRole] Unknown PlayerMenu action:", action)
		end

	else
		warn("[GiveRole] ❌ Unknown source:", source, "from", player.Name)
	end
end)

debugPrint("✅ Give handler loaded (VIP + Streamer + Creator version)")
print("✅ [GiveRoleHandler] Loaded successfully!")
