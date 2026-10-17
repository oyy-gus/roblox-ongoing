local replicatedStorage = game:GetService("ReplicatedStorage")

local ConfigModule = require(script.ConfigModule)
local DebugModule = require(script.DebugModule)
local ProductModule = require(script.ProductModule)

local getProductsRemote = Instance.new("RemoteFunction")
getProductsRemote.Name = "GetDeveloperProducts"
getProductsRemote.Parent = replicatedStorage

getProductsRemote.OnServerInvoke = function(player)
	DebugModule.log("PLAYER", player.Name .. " requesting products")

	local success, products = pcall(function()
		return ProductModule.getDeveloperProducts()
	end)

	if success and products then
		return products
	else
		DebugModule.warn("KESALAHAN", "Gagal mendapatkan produk:", products)
		return {}
	end
end

task.spawn(function()
	task.wait(2)
	DebugModule.log("LOADING", "Pra-muat produk...")
	ProductModule.getDeveloperProducts()
end)

DebugModule.log("LOADING", "Donation Server Handler (Refactored) initialized!")
