local players            = game:GetService("Players")
local marketplaceService = game:GetService("MarketplaceService")
local replicatedStorage  = game:GetService("ReplicatedStorage")

local ClientConfig  = require(script.Parent.ClientConfig)
local ClientDebug   = require(script.Parent.ClientDebug)
local UIModule      = require(script.Parent.UIModule)

local ProductUIModule = {}
local player = players.LocalPlayer

local function createButton(productData, index, elements, state)
	local borderFrame = elements.templateframe:Clone()
	borderFrame.Name    = "Product_" .. productData.Id
	borderFrame.Visible = true
	borderFrame.Parent  = elements.container

	local card = borderFrame:WaitForChild("ProductCard")
	local btn  = card:WaitForChild("TemplateBtn")

	btn.Text = "R$ " .. UIModule.formatNumber(productData.Price)

	local yPos = (index - 1) * (borderFrame.Size.Y.Offset + ClientConfig.UI.BUTTON_SPACING)
	borderFrame.Position = UDim2.new(0, 0, 0, yPos)

	local isProcessing = false
	btn.MouseButton1Click:Connect(function()
		if isProcessing then return end
		isProcessing = true

		local originalText = btn.Text
		btn.Text = ClientConfig.UI.PROCESSING_TEXT

		ClientDebug.log("PURCHASE", "Initiating purchase:", productData.Id)
		state.lastPurchasedAmount = productData.Price

		local success, err = pcall(function()
			marketplaceService:PromptProductPurchase(player, productData.Id)
		end)

		task.wait(0.5)
		btn.Text = originalText
		isProcessing = false

		if not success then
			ClientDebug.warn("KESALAHAN", "Kesalahan prompt pembelian:", err)
			UIModule.notify("Error", ClientConfig.MESSAGES.PURCHASE_FAILED, ClientConfig.NOTIFICATIONS.DURATION.ERROR)
		end
	end)

	btn.MouseEnter:Connect(function()
		card.BackgroundTransparency = 0.3
	end)
	btn.MouseLeave:Connect(function()
		card.BackgroundTransparency = 0
	end)

	table.insert(state.currentButtons, borderFrame)
	ClientDebug.log("BUTTON", "Created button:", productData.Id, "- R$" .. productData.Price)

	return borderFrame
end

local function clearButtons(state, elements)
	for _, btn in ipairs(state.currentButtons) do
		if btn and btn.Parent then
			btn:Destroy()
		end
	end
	state.currentButtons = {}
	UIModule.hideError(elements.container)
	ClientDebug.log("UI", "Cleared all product buttons")
end

function ProductUIModule.loadProducts(elements, state)
	if state.isLoading or state.productsLoaded then return end

	state.isLoading = true
	UIModule.setLoading(elements.container, true)
	clearButtons(state, elements)

	ClientDebug.log("LOADING", "Requesting products from server...")

	local remote = replicatedStorage:WaitForChild("GetDeveloperProducts", 10)

	if not remote then
		UIModule.setLoading(elements.container, false)
		UIModule.showError(elements.container, ClientConfig.MESSAGES.SERVER_UNAVAILABLE)
		UIModule.notify("Error", ClientConfig.MESSAGES.SERVER_NOT_READY, ClientConfig.NOTIFICATIONS.DURATION.ERROR)
		state.isLoading = false
		return
	end

	local success, products = pcall(function()
		return remote:InvokeServer()
	end)

	UIModule.setLoading(elements.container, false)

	if success and products and type(products) == "table" and #products > 0 then
		ClientDebug.log("LOADING", "Received", #products, "products")

		for i, product in ipairs(products) do
			createButton(product, i, elements, state)
			task.wait(ClientConfig.UI.BUTTON_CREATE_DELAY)
		end

		local itemHeight = elements.templateframe.Size.Y.Offset
		local totalHeight = #products * (itemHeight + ClientConfig.UI.BUTTON_SPACING)
		elements.container.CanvasSize = UDim2.new(0, 0, 0, totalHeight)

		state.productsLoaded = true
		UIModule.notify(
			ClientConfig.MESSAGES.LOAD_SUCCESS,
			#products .. " produk tersedia",
			ClientConfig.NOTIFICATIONS.DURATION.INFO
		)
	else
		local msg = ClientConfig.MESSAGES.NO_PRODUCTS
		if not success then
			msg = "Error: " .. tostring(products)
		end

		UIModule.showError(elements.container, msg)
		UIModule.notify("Error", ClientConfig.MESSAGES.LOAD_FAILED, ClientConfig.NOTIFICATIONS.DURATION.ERROR)
		ClientDebug.warn("KESALAHAN", "Gagal memuat:", products)
	end

	state.isLoading = false
end

return ProductUIModule
