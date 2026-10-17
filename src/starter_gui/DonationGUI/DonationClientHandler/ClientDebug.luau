local ClientConfig = require(script.Parent.ClientConfig)

local ClientDebug = {}

function ClientDebug.log(category, ...)
	if not ClientConfig.DEBUG.ENABLED then return end

	local categorySettings = {
		UI = ClientConfig.DEBUG.SHOW_UI_EVENTS,
		LOADING = ClientConfig.DEBUG.SHOW_PRODUCT_LOADING,
		BUTTON = ClientConfig.DEBUG.SHOW_BUTTON_CREATION,
		PURCHASE = ClientConfig.DEBUG.SHOW_PURCHASE_EVENTS,
		ERROR = ClientConfig.DEBUG.SHOW_ERRORS,
	}

	if categorySettings[category] then
		print("[" .. category .. "]", ...)
	end
end

function ClientDebug.warn(category, ...)
	if not ClientConfig.DEBUG.ENABLED then return end
	if ClientConfig.DEBUG.SHOW_ERRORS then
		warn("[" .. category .. "]", ...)
	end
end

return ClientDebug
