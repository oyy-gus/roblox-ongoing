--[[
	TopbarController.lua
	Tujuan: Pengendali TopbarPlus (ReplicatedStorage > Icon) + Hotkey [M].
	Posisi Ikon TopbarPlus di POJOK KANAN (icon:setRight()).
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local TopbarController = {}
local menuIcon = nil
local isUpdatingState = false

local function isIconSelected(icon)
	if not icon then return false end
	if type(icon.getIsSelected) == "function" then
		local ok, val = pcall(function() return icon:getIsSelected() end)
		if ok and type(val) == "boolean" then return val end
	end
	if icon.isSelected ~= nil then
		return icon.isSelected == true
	end
	return false
end

function TopbarController.Init()
	if menuIcon then return end

	-- 1. Hotkey Keyboard [M] untuk toggle menu
	UserInputService.InputBegan:Connect(function(input, gameProcessed)
		if gameProcessed then return end
		if input.KeyCode == Enum.KeyCode.M then
			local ok, MenuController = pcall(function() return require(script.Parent.MenuController) end)
			if ok and MenuController then
				MenuController.ToggleMenu()
			end
		end
	end)

	-- 2. Cari & muat modul Icon dari ReplicatedStorage > Icon
	local iconModule = ReplicatedStorage:WaitForChild("Icon", 10)
	if not iconModule then
		warn("[TopbarController] Modul 'ReplicatedStorage > Icon' tidak ditemukan!")
		return
	end

	local ok, Icon = pcall(require, iconModule)
	if not ok or not Icon then
		warn("[TopbarController] Gagal memuat modul Icon TopbarPlus:", Icon)
		return
	end

	-- 3. Buat 1 ikon TopbarPlus bernama "Menu" di POJOK KANAN
	local success, iconInstance = pcall(function()
		local icon = Icon.new()
		
		-- Posisikan di POJOK KANAN Topbar
		if type(icon.setRight) == "function" then
			pcall(function() icon:setRight() end)
		elseif type(icon.setAlignment) == "function" then
			pcall(function() icon:setAlignment("Right") end)
		elseif type(icon.right) == "function" then
			pcall(function() icon:right() end)
		end

		if type(icon.setName) == "function" then pcall(function() icon:setName("MainMenuIcon") end) end
		if type(icon.setLabel) == "function" then pcall(function() icon:setLabel("Menu") end) end
		if type(icon.setCaption) == "function" then pcall(function() icon:setCaption("Buka Menu Utama [M]") end) end

		local function handleStateChange(isSelected)
			if isUpdatingState then return end
			local okMenu, MenuController = pcall(function() return require(script.Parent.MenuController) end)
			if okMenu and MenuController then
				if isSelected then
					MenuController.OpenMenu()
				else
					MenuController.CloseMenu()
				end
			end
		end

		-- Event handling presisi untuk TopbarPlus v2 / v3
		if icon.toggled and type(icon.toggled.Connect) == "function" then
			icon.toggled:Connect(handleStateChange)
		else
			if icon.selected and type(icon.selected.Connect) == "function" then
				icon.selected:Connect(function() handleStateChange(true) end)
			end
			if icon.deselected and type(icon.deselected.Connect) == "function" then
				icon.deselected:Connect(function() handleStateChange(false) end)
			end
		end

		return icon
	end)

	if success and iconInstance then
		menuIcon = iconInstance
		print("[TopbarController] Ikon Menu TopbarPlus di POJOK KANAN berhasil diaktifkan.")
	else
		warn("[TopbarController] Gagal menginisialisasi ikon TopbarPlus:", iconInstance)
	end
end

function TopbarController.OnMenuOpened()
	if menuIcon then
		if not isIconSelected(menuIcon) then
			isUpdatingState = true
			if type(menuIcon.select) == "function" then
				pcall(function() menuIcon:select() end)
			end
			task.delay(0.05, function()
				isUpdatingState = false
			end)
		end
	end
end

function TopbarController.OnMenuClosed()
	if menuIcon then
		if isIconSelected(menuIcon) then
			isUpdatingState = true
			if type(menuIcon.deselect) == "function" then
				pcall(function() menuIcon:deselect() end)
			end
			task.delay(0.05, function()
				isUpdatingState = false
			end)
		end
	end
end

return TopbarController

