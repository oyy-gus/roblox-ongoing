-- Letakkan di ScreenGui
-- GUI sekarang dibangun otomatis oleh GUIBuilder
-- ========================================

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

-- ============================================
-- 🏗️ BUILD GUI OTOMATIS
-- ============================================
local gui      = script.Parent
if gui:IsA("ScreenGui") then
	gui.DisplayOrder = 100
end
local elements = GUIBuilder.build(gui)

-- ============================================
-- 🔧 STATE
-- ============================================
local player = players.LocalPlayer
local state = {
	isLoading          = false,
	productsLoaded     = false,
	currentButtons     = {},
	lastPurchasedAmount = 0,
	canSendMessage     = false,
	lastMessageTime    = 0,
}

-- ============================================
-- 🚀 INITIALIZATION
-- ============================================

UIModule.initializeUI(elements)

-- Buka / tutup UI donasi via TopbarPlus icon
elements.donateBtn.selected:Connect(function()
	elements.mainframe.Visible = true
	ClientDebug.log("UI", "Donation UI opened (topbar)")
	if not state.productsLoaded then
		ProductUIModule.loadProducts(elements, state)
	end
end)

elements.donateBtn.deselected:Connect(function()
	elements.mainframe.Visible = false
	ClientDebug.log("UI", "Donation UI closed (topbar deselected)")
end)

-- Tutup MainFrame via tombol ✕ header
elements.mainframe:WaitForChild("Header"):WaitForChild("CloseBtn").MouseButton1Click:Connect(function()
	elements.mainframe.Visible = false
	elements.donateBtn:deselect()
	ClientDebug.log("UI", "Donation UI closed via header CloseBtn")
end)

-- Setup MessageFrame
MessageUIModule.setupMessageFrame(elements, state)

-- Setup notifikasi & broadcast
NotificationModule.initialize(elements.notificationframe)
BroadcastListenerModule.setupListener(elements.notificationframe)

-- Handler selesai beli
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

-- Cleanup saat player keluar
players.PlayerRemoving:Connect(function(removedPlayer)
	if removedPlayer == player then
		NotificationModule.cleanup()
		ClientDebug.log("UI", "Cleaned up on player leaving")
	end
end)

ClientDebug.log("UI", "✅ Donation Client Handler (Auto GUI) initialized!")

-- ========================================
