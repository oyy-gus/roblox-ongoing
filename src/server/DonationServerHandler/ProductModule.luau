local ConfigModule = require(script.Parent.ConfigModule)
local DebugModule = require(script.Parent.DebugModule)

local ProductModule = {}

local cachedProducts = nil
local lastCacheTime = 0

function ProductModule.getDeveloperProducts()
	local currentTime = tick()

	if cachedProducts and (currentTime - lastCacheTime) < ConfigModule.CACHE.DURATION then
		DebugModule.log("CACHE", "Using cached products (" .. #cachedProducts .. " items)")
		return cachedProducts
	end

	DebugModule.log("LOADING", "Loading developer products...")
	local validProducts = {}

	for _, product in ipairs(ConfigModule.PRODUCTS) do
		if product.id and product.name and product.price then
			table.insert(validProducts, {
				Id = product.id,
				Name = product.name,
				Price = product.price,
				Description = ""
			})
			DebugModule.log("VALIDATION", product.name .. " - R$ " .. product.price .. " [VALID]")
		else
			DebugModule.warn("VALIDATION", "Invalid product configuration:", product)
		end
	end

	table.sort(validProducts, function(a, b)
		return a.Price < b.Price
	end)

	cachedProducts = validProducts
	lastCacheTime = currentTime

	DebugModule.log("LOADING", "Total produk dimuat: " .. #validProducts)

	if #validProducts == 0 then
		DebugModule.warn("KESALAHAN", "TIDAK ADA PRODUK! Periksa CONFIG.PRODUCTS")
	end

	return validProducts
end

return ProductModule
