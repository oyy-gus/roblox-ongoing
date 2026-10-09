--[[
	MenuController.lua
	Tujuan: Pengendali status buka/tutup menu utama dan pengelola halaman aktif.
	Mendukung auto-inisialisasi mandiri agar UI selalu dapat dibuka kapan saja.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local MenuRoot = require(script.Parent.Parent.UI.Menu.MenuRoot)
local MusicPage = require(script.Parent.Parent.UI.Menu.MusicPage)
local PageRegistry = require(script.Parent.Parent.UI.Menu.PageRegistry)

local MenuController = {}
local isMenuOpen = false
local screenGui = nil
local menuRoot = nil
local musicPage = nil
local activeCallbacks = {}

function MenuController.Init(callbacks)
	if callbacks then
		for k, v in pairs(callbacks) do
			activeCallbacks[k] = v
		end
	end

	if screenGui and menuRoot then return end

	local localPlayer = Players.LocalPlayer or Players:GetPropertyChangedSignal("LocalPlayer"):Wait()
	local playerGui = localPlayer:WaitForChild("PlayerGui")

	-- ScreenGui Utama
	screenGui = Instance.new("ScreenGui")
	screenGui.Name = "GlobalMusicMenuGui"
	screenGui.ResetOnSpawn = false
	screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	screenGui.Parent = playerGui

	-- Menu Root
	menuRoot = MenuRoot.new(function()
		MenuController.CloseMenu()
	end)
	menuRoot.Instance.Parent = screenGui

	-- Proxy Callbacks agar callback bisa diperbarui secara dinamis oleh MusicController
	local proxyCallbacks = {
		onVoteSkip = function(...)
			if activeCallbacks.onVoteSkip then activeCallbacks.onVoteSkip(...) end
		end,
		onSelectSong = function(...)
			if activeCallbacks.onSelectSong then activeCallbacks.onSelectSong(...) end
		end,
		onQueueSong = function(...)
			if activeCallbacks.onQueueSong then activeCallbacks.onQueueSong(...) end
		end,
		onFavoriteToggled = function(...)
			if activeCallbacks.onFavoriteToggled then activeCallbacks.onFavoriteToggled(...) end
		end,
		onVolumeChanged = function(...)
			if activeCallbacks.onVolumeChanged then activeCallbacks.onVolumeChanged(...) end
		end,
	}

	-- Halaman Musik
	musicPage = MusicPage.new(proxyCallbacks)
	musicPage.Instance.Parent = menuRoot.ContentArea
	PageRegistry.RegisterPage("Music", musicPage)

	-- Menu tetap tertutup saat pertama kali masuk game (hanya buka saat tombol ditekan)
	menuRoot:SetVisible(false)
end

function MenuController.EnsureInitialized()
	if not screenGui or not menuRoot then
		MenuController.Init()
	end
end

function MenuController.ToggleMenu()
	MenuController.EnsureInitialized()
	if isMenuOpen then
		MenuController.CloseMenu()
	else
		MenuController.OpenMenu()
	end
end

function MenuController.OpenMenu()
	MenuController.EnsureInitialized()
	isMenuOpen = true
	if menuRoot then
		menuRoot:SetVisible(true)
	end
	local ok, TopbarController = pcall(function() return require(script.Parent.TopbarController) end)
	if ok and TopbarController and TopbarController.OnMenuOpened then
		TopbarController.OnMenuOpened()
	end
end

function MenuController.CloseMenu()
	MenuController.EnsureInitialized()
	isMenuOpen = false
	if menuRoot then
		menuRoot:SetVisible(false)
	end
	local ok, TopbarController = pcall(function() return require(script.Parent.TopbarController) end)
	if ok and TopbarController and TopbarController.OnMenuClosed then
		TopbarController.OnMenuClosed()
	end
end

function MenuController.IsOpen()
	return isMenuOpen
end

function MenuController.SetFavorites(favList)
	MenuController.EnsureInitialized()
	if musicPage then
		musicPage:SetFavorites(favList)
	end
end

function MenuController.UpdateMusicPage(stateData)
	MenuController.EnsureInitialized()
	if musicPage then
		musicPage:Update(stateData)
	end
	-- Teruskan beat level ke MenuRoot untuk animasi border
	if menuRoot and menuRoot.SetBeatLevel then
		menuRoot:SetBeatLevel(stateData and stateData.beatLevel or 0)
	end
end

return MenuController

