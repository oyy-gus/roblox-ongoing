local Config = require(script.Parent.Config)
local Logger = require(script.Parent.Logger)

local MarketplaceService = game:GetService("MarketplaceService")

local ShopHandler = {}

function ShopHandler:Init(roleSystem, validationManager)
	self.roleSystem = roleSystem
	self.validationManager = validationManager
	Logger:Debug("ShopHandler initialized (VIP only)")
end

function ShopHandler:GetShopData(player)
	if not self.validationManager:ValidatePlayer(player) then
		return {success = false, error = "Invalid player"}
	end

	local ownership = self.roleSystem:GetPlayerOwnership(player)

	local data = {
		success = true,
		gamepasses = {
			VIP = {
				ids = self.roleSystem.Config.GamePasses.VIP,
				owned = ownership.VIP,
				name = "VIP Pass",
				price = 100
			}
		},
		debug = {
			givenPass = ownership.GivenPass,
			cachedAt = ownership.CheckedAt
		}
	}

	Logger:Debug(string.format("Shop data retrieved for %s (VIP: %s)",
		player.Name, tostring(ownership.VIP)))

	return data
end

function ShopHandler:PromptPurchase(player, gamepassType)
	if not self.validationManager:ValidatePlayer(player) then
		return {success = false, error = "Invalid player"}
	end

	if gamepassType ~= "VIP" then
		return {success = false, error = "Invalid gamepass type"}
	end

	local ownership = self.roleSystem:GetPlayerOwnership(player)

	if ownership.VIP then
		Logger:Debug(string.format("%s already owns VIP", player.Name))
		return {success = false, error = "Already owned"}
	end

	local gamepassId = self.roleSystem.Config.ActiveGamepasses.VIP

	if not gamepassId or gamepassId == 0 then
		Logger:Error("Invalid gamepass configuration for VIP")
		return {success = false, error = "Invalid gamepass configuration"}
	end

	Logger:Info(string.format("Prompting %s for VIP (ID: %d)",
		player.Name, gamepassId))

	local success, errorMsg = pcall(function()
		MarketplaceService:PromptGamePassPurchase(player, gamepassId)
	end)

	if success then
		return {success = true, promptedId = gamepassId}
	else
		Logger:Error("Failed to prompt purchase: " .. tostring(errorMsg))
		return {success = false, error = "Failed to prompt purchase"}
	end
end

function ShopHandler:HandlePurchaseFinished(player, purchasedPassID, purchaseSuccess)
	if not self.validationManager:ValidatePlayer(player) then return end

	Logger:Info(string.format("Gamepass Purchase - Player: %s, ID: %d, Success: %s",
		player.Name, purchasedPassID, tostring(purchaseSuccess)))

	if not purchaseSuccess then
		Logger:Debug("Purchase was not successful, skipping processing")
		return
	end

	local gamepassType = nil
	local vipIds = self.roleSystem.Config.GamePasses.VIP

	for _, id in ipairs(vipIds) do
		if id == purchasedPassID then
			gamepassType = "VIP"
			break
		end
	end

	if not gamepassType then
		Logger:Warn(string.format("Unknown gamepass purchased: %d", purchasedPassID))
		return
	end

	Logger:Success(string.format("%s purchased VIP Pass!", player.Name))

	self.roleSystem:GivePassToPlayer(
		player.UserId,
		"VIP",
		0,
		function(success, result)
			if success then
				Logger:Success(string.format("Successfully saved VIP purchase for %s", player.Name))

				local newRole = self.roleSystem:GetPlayerRole(player)
				self:NotifyPurchaseComplete(player, "VIP", newRole)

				if Config.AutoUpdateRole then
					task.spawn(function()
						task.wait(Config.UpdateDelay)
						local finalRole = self:UpdatePlayerRole(player)
						Logger:Success(string.format("Final role for %s: %s", player.Name, finalRole))
					end)
				end
			else
				Logger:Error(string.format("Failed to save purchase: %s", result))
			end
		end
	)
end

function ShopHandler:UpdatePlayerRole(player)
	if not self.validationManager:ValidatePlayer(player) then
		return nil
	end

	Logger:Debug(string.format("Updating role for player: %s", player.Name))

	task.wait(Config.UpdateDelay)

	self.roleSystem:InvalidateOwnershipCache(player.UserId)

	local newRole = self.roleSystem:UpdatePlayerRole(player)

	Logger:Info(string.format("Role updated for %s: %s", player.Name, newRole))

	if Config.BroadcastRoleChange then
		self:NotifyRoleUpdate(player, newRole)
	end

	return newRole
end

function ShopHandler:NotifyPurchaseComplete(player, gamepassType, role)
	local remote = game.ReplicatedStorage.Gamepass:FindFirstChild("PlayerDataUpdated")
	if remote then
		remote:FireClient(player, {
			type = "purchase_complete",
			gamepassType = gamepassType,
			ownership = {
				VIP = true
			},
			role = role,
			message = "Kamu telah menerima VIP!"
		})
	end
end

function ShopHandler:NotifyRoleUpdate(player, newRole)
	local remote = game.ReplicatedStorage.Gamepass:FindFirstChild("PlayerDataUpdated")
	if remote then
		remote:FireClient(player, {
			type = "role_updated",
			role = newRole
		})
	end
end

return ShopHandler
