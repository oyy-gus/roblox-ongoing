local players           = game:GetService("Players")
local marketplaceService = game:GetService("MarketplaceService")
local replicatedStorage = game:GetService("ReplicatedStorage")

local ClientConfig      = require(script.ClientConfig)
local ClientDebug       = require(script.ClientDebug)
local GUIBuilder        = require(script.GUIBuilder)
local UIModule          = require(script.UIModule)
local ProductUIModule   = require(script.ProductUIModule)
local MessageUIModule   = require(script.MessageUIModule)
local NotificationModule = require(script.NotificationModule)
local BroadcastListenerModule = require(script.BroadcastListenerModule)

local gui      = script.Parent
if gui:IsA("ScreenGui") then
	gui.DisplayOrder = 100
end
local elements = GUIBuilder.build(gui)

local player = players.LocalPlayer
local state = {
	isLoading          = false,
	productsLoaded     = false,
	currentButtons     = {},
	lastPurchasedAmount = 0,
	canSendMessage     = false,
	lastMessageTime    = 0,
}

UIModule.initializeUI(elements)

local PanelAnimationController = require(replicatedStorage:WaitForChild("Modules"):WaitForChild("PanelAnimationController"))
local mainPanelAnim = PanelAnimationController.new(elements.mainframe, { CollapsedHeight = 44 })

elements.donateBtn.selected:Connect(function()
	mainPanelAnim:Open(420)
	ClientDebug.log("UI", "Donasi UI dibuka (topbar)")
	if not state.productsLoaded then
		ProductUIModule.loadProducts(elements, state)
	end
end)

elements.donateBtn.deselected:Connect(function()
	mainPanelAnim:Close()
	ClientDebug.log("UI", "Donasi UI ditutup (topbar deselected)")
end)

elements.mainframe:WaitForChild("Header"):WaitForChild("CloseBtn").MouseButton1Click:Connect(function()
	mainPanelAnim:Close()
	elements.donateBtn:deselect()
	ClientDebug.log("UI", "Donasi UI ditutup via header CloseBtn")
end)

MessageUIModule.setupMessageFrame(elements, state)

NotificationModule.initialize(elements.notificationframe)
BroadcastListenerModule.setupListener(elements.notificationframe)

marketplaceService.PromptProductPurchaseFinished:Connect(function(userId, productId, isPurchased)
	if userId == player.UserId and isPurchased then
		ClientDebug.log("PURCHASE", "Purchase successful:", productId)
		if state.lastPurchasedAmount >= ClientConfig.MESSAGE.MIN_DONATION then
			task.wait(1)
			MessageUIModule.showMessageFrame(elements, state, state.lastPurchasedAmount)
		else
			elements.mainframe.Visible = false
			ClientDebug.log("UI", "Auto-closed mainframe for small donation")
		end
	end
end)

players.PlayerRemoving:Connect(function(removedPlayer)
	if removedPlayer == player then
		NotificationModule.cleanup()
		ClientDebug.log("UI", "Cleaned up on player leaving")
	end
end)

ClientDebug.log("UI", "✅ Donation Client Handler (Auto GUI) initialized!")
