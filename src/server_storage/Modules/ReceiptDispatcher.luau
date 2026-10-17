local MarketplaceService = game:GetService("MarketplaceService")

local ReceiptDispatcher = {}
local registeredHandlers = {}

function ReceiptDispatcher.RegisterHandler(handlerName: string, callback: (any) -> any)
	registeredHandlers[handlerName] = callback
end

local function processReceipt(receiptInfo)
	local isHandled = false
	for _, callback in pairs(registeredHandlers) do
		local success, result = pcall(callback, receiptInfo)
		if success and result == Enum.ProductPurchaseDecision.PurchaseGranted then
			isHandled = true
		end
	end
	if isHandled then
		return Enum.ProductPurchaseDecision.PurchaseGranted
	end
	return Enum.ProductPurchaseDecision.NotProcessedYet
end

MarketplaceService.ProcessReceipt = processReceipt

return ReceiptDispatcher
