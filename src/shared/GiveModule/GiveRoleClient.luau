-- ====================================
-- GIVE ROLE CLIENT - FINAL COMPLETE VERSION
-- Place in: ReplicatedStorage > GiveModule > GiveRoleClient(ModuleScript)
-- ====================================

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GiveRoleConfig = require(
	ReplicatedStorage:WaitForChild("GiveModule"):WaitForChild("GiveRoleConfig")
)

local giveRoleRemote = ReplicatedStorage:WaitForChild("GiveRoleRemote")

if not giveRoleRemote then
	warn("[GiveRoleClient] GiveRoleRemote not found!")
end

local function debugPrint(...)
	if GiveRoleConfig.Debug.ENABLE_DEBUG and GiveRoleConfig.Debug.SHOW_CLIENT_LOGS then
		print("[GiveRoleClient]", ...)
	end
end

local GiveRoleClient = {}

-- ==============================
-- STATE
-- ==============================
GiveRoleClient.currentTargetPlayer = nil
GiveRoleClient.currentRoleInfo     = nil
GiveRoleClient.isChecking          = false
GiveRoleClient.giveFrame           = nil
GiveRoleClient.roleBtn             = nil
GiveRoleClient.loadingText         = nil
GiveRoleClient.closeCallback       = nil
GiveRoleClient._initialized        = false
GiveRoleClient._callbackMode       = false
GiveRoleClient._pendingCallback    = nil

-- ==============================
-- UI HELPERS
-- ==============================
local function setLoadingText(text, color)
	if GiveRoleClient.loadingText then
		GiveRoleClient.loadingText.Text = text
		GiveRoleClient.loadingText.TextColor3 = color or Color3.new(1, 1, 1)
	end
end

local function setButtonState(enabled, text)
	local btn = GiveRoleClient.roleBtn
	if not btn then return end
	btn.Active          = enabled
	btn.AutoButtonColor = enabled
	btn.BackgroundColor3 = enabled
		and Color3.fromRGB(85, 170, 255)
		or  Color3.fromRGB(100, 100, 100)
	if text then btn.Text = text end
end

-- ==============================
-- INITIALIZE
-- ==============================
function GiveRoleClient:Initialize(giveFrame, roleBtn, loadingText, closeCallback)
	self.giveFrame    = giveFrame
	self.roleBtn      = roleBtn
	self.loadingText  = loadingText
	self.closeCallback = closeCallback
	self._initialized = true

	if self.giveFrame then
		self.giveFrame.Visible = false
	end

	if self.roleBtn then
		self.roleBtn.MouseButton1Click:Connect(function()
			if self.roleBtn.Active then
				self:InitiatePurchase()
			end
		end)
	end

	debugPrint("Initialized")
end

-- ==============================
-- BACKGROUND CHECK (TANPA BUKA OVERLAY)
-- Dipakai saat profile card dibuka
-- ==============================
function GiveRoleClient:CheckPlayerRoleAsync(targetPlayer, callback)
	if not targetPlayer then
		if callback then callback(nil) end
		return
	end

	if self.isChecking then
		if callback then callback(nil) end
		return
	end

	self.isChecking         = true
	self._callbackMode      = true
	self._pendingCallback   = callback

	debugPrint("CheckPlayerRoleAsync userId=" .. targetPlayer.UserId)

	giveRoleRemote:FireServer({
		source       = "PlayerMenu",
		action       = "CheckPlayerRole",
		targetUserId = targetPlayer.UserId
	})
end

-- ==============================
-- OPEN OVERLAY & CHECK
-- Dipakai sebagai fallback
-- ==============================
function GiveRoleClient:CheckPlayerRole(targetPlayer)
	if not targetPlayer then return end
	if self.isChecking then return end
	if not self._initialized then
		warn("[GiveRoleClient] Not initialized!")
		return
	end

	self.isChecking            = true
	self._callbackMode         = false
	self._pendingCallback      = nil
	self.currentTargetPlayer   = targetPlayer

	if self.giveFrame then
		self.giveFrame.Visible = true
	end

	setButtonState(false, "Memeriksa...")
	setLoadingText("Memeriksa status VIP...", Color3.new(1, 1, 1))

	debugPrint("CheckPlayerRole userId=" .. targetPlayer.UserId)

	giveRoleRemote:FireServer({
		source       = "PlayerMenu",
		action       = "CheckPlayerRole",
		targetUserId = targetPlayer.UserId
	})
end

-- ==============================
-- TAMPILKAN OVERLAY (DATA SUDAH ADA)
-- Dipakai saat tombol Hadiah diklik
-- ==============================
function GiveRoleClient:ShowOverlayForPlayer(targetPlayer)
	if not self._initialized then
		warn("[GiveRoleClient] Not initialized!")
		return
	end

	if not targetPlayer then return end

	local stillHere = Players:GetPlayerByUserId(targetPlayer.UserId)
	if not stillHere then
		warn("[GiveRoleClient] Target player left")
		return
	end

	self.currentTargetPlayer = targetPlayer

	if self.giveFrame then
		self.giveFrame.Visible = true
	end

	if self.currentRoleInfo and self.currentRoleInfo.canReceive then
		setLoadingText(
			"Klik tombol di bawah untuk kirim hadiah VIP",
			Color3.fromRGB(100, 200, 255)
		)
		setButtonState(
			true,
			"VIP - " .. GiveRoleConfig.Prices.VIP .. " R$"
		)
	else
		-- Fallback: cek ulang
		self:CheckPlayerRole(targetPlayer)
	end
end

-- ==============================
-- HANDLE HASIL CEK DARI SERVER
-- ==============================
function GiveRoleClient:HandleCheckResult(roleInfo)
	self.isChecking    = false
	self.currentRoleInfo = roleInfo

	-- Mode background -> panggil callback, jangan update overlay
	if self._callbackMode and self._pendingCallback then
		local cb              = self._pendingCallback
		self._pendingCallback = nil
		self._callbackMode    = false
		debugPrint("CheckResult via callback, canReceive=" .. tostring(roleInfo.canReceive))
		cb(roleInfo)
		return
	end

	-- Mode overlay -> update UI
	if not roleInfo.canReceive then
		if roleInfo.reason == "has_vip" then
			setLoadingText(
				"Player sudah memiliki VIP",
				Color3.fromRGB(255, 200, 100)
			)
			setButtonState(false, "Sudah VIP")
		elseif roleInfo.reason == "staff" then
			setLoadingText(
				"Player adalah " .. (roleInfo.currentRole or "Staff"),
				Color3.fromRGB(255, 100, 100)
			)
			setButtonState(false, "Tidak Tersedia")
			task.delay(2, function()
				if self.giveFrame then
					self.giveFrame.Visible = false
				end
				if self.closeCallback then
					self.closeCallback()
				end
			end)
		else
			setLoadingText(
				roleInfo.message or "Tidak dapat memberikan role",
				Color3.fromRGB(255, 100, 100)
			)
			setButtonState(false, "Tidak Tersedia")
		end
	else
		setLoadingText(
			"Player belum memiliki VIP\nKlik untuk memberikan hadiah",
			Color3.fromRGB(100, 200, 255)
		)
		setButtonState(
			true,
			"VIP - " .. GiveRoleConfig.Prices.VIP .. " R$"
		)
	end
end

-- ==============================
-- INITIATE PURCHASE
-- ==============================
function GiveRoleClient:InitiatePurchase()
	if not self.currentTargetPlayer then
		warn("[GiveRoleClient] No target")
		return
	end

	if not self.currentRoleInfo or not self.currentRoleInfo.canReceive then
		warn("[GiveRoleClient] Target cannot receive VIP")
		return
	end

	local targetUserId = self.currentTargetPlayer.UserId
	local stillHere    = Players:GetPlayerByUserId(targetUserId)
	if not stillHere then
		setLoadingText("Player sudah keluar dari game", Color3.fromRGB(255, 100, 100))
		task.delay(1.5, function()
			if self.giveFrame then self.giveFrame.Visible = false end
			if self.closeCallback then self.closeCallback() end
		end)
		return
	end

	setLoadingText("Membuka pembayaran...", Color3.fromRGB(255, 255, 100))
	setButtonState(false, "Memproses...")

	debugPrint("InitiatePurchase targetUserId=" .. targetUserId)

	giveRoleRemote:FireServer({
		source       = "PlayerMenu",
		action       = "InitiatePurchase",
		targetUserId = targetUserId,
		roleType     = "VIP"
	})
end

-- ==============================
-- HANDLE PURCHASE RESULT
-- ==============================
function GiveRoleClient:HandlePurchaseComplete(success, message)
	if success then
		setLoadingText("✓ " .. (message or "VIP berhasil dikirim!"), Color3.fromRGB(100, 255, 100))
		setButtonState(false, "✓ Berhasil")

		if self.currentRoleInfo then
			self.currentRoleInfo.canReceive = false
			self.currentRoleInfo.reason     = "has_vip"
		end

		task.delay(2, function()
			self:Reset()
		end)
	else
		setLoadingText("✗ " .. (message or "Gagal"), Color3.fromRGB(255, 100, 100))

		task.delay(1.5, function()
			if self.currentRoleInfo and self.currentRoleInfo.canReceive then
				setLoadingText(
					"Player belum memiliki VIP\nKlik untuk memberikan hadiah",
					Color3.fromRGB(100, 200, 255)
				)
				setButtonState(
					true,
					"VIP - " .. GiveRoleConfig.Prices.VIP .. " R$"
				)
			end
		end)
	end
end

-- ==============================
-- RESET SEMUA STATE
-- ==============================
function GiveRoleClient:Reset()
	self.isChecking          = false
	self.currentTargetPlayer = nil
	self.currentRoleInfo     = nil
	self._callbackMode       = false
	self._pendingCallback    = nil

	if self.giveFrame then
		self.giveFrame.Visible = false
	end

	if self.closeCallback then
		self.closeCallback()
	end

	debugPrint("Reset")
end

-- ==============================
-- REMOTE LISTENER
-- ==============================
giveRoleRemote.OnClientEvent:Connect(function(data)
	if typeof(data) ~= "table" then return end
	if data.source ~= "PlayerMenu" then return end

	debugPrint("Received action=" .. tostring(data.action))

	if data.action == "CheckResult" then
		if data.success then
			GiveRoleClient:HandleCheckResult(data.roleInfo)
		else
			GiveRoleClient.isChecking  = false
			GiveRoleClient._callbackMode = false
			if GiveRoleClient._pendingCallback then
				local cb = GiveRoleClient._pendingCallback
				GiveRoleClient._pendingCallback = nil
				cb(nil)
			else
				GiveRoleClient:HandlePurchaseComplete(false, data.message)
			end
		end

	elseif data.action == "PurchaseComplete" then
		GiveRoleClient:HandlePurchaseComplete(data.success, data.message)

	elseif data.action == "PurchaseError" then
		GiveRoleClient:HandlePurchaseComplete(false, data.message)
	end
end)

return GiveRoleClient

-- ====================================
-- GIVE ROLE CONFIG
