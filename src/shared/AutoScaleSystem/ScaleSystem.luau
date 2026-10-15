-- ============================================================
--  Lokasi : ReplicatedStorage > AutoScaleSystem > ScaleSystem(ModuleScript)
--  VERSI DIPERBAIKI - Mencegah bug full screen
-- ============================================================

local ScaleSystem = {}
ScaleSystem.__index = ScaleSystem

local RunService   = game:GetService("RunService")
local Config       = require(script.Parent:WaitForChild("Config"))
local ScaleUtils   = require(script.Parent:WaitForChild("ScaleUtils"))

-- ══════════════════════════════════════════
-- PRIVATE HELPERS
-- ══════════════════════════════════════════

local function getOrCreateUIScale(targetGui: ScreenGui): UIScale
	-- ★ PENTING: Hapus UIScale lama jika ada (mencegah duplikat)
	local existing = targetGui:FindFirstChildOfClass("UIScale")
	if existing then 
		-- Jika sudah ada AutoUIScale, gunakan itu
		if existing.Name == "AutoUIScale" then
			return existing
		end
		-- Jika ada UIScale lain, hapus untuk mencegah konflik
		warn("[ScaleSystem] Menghapus UIScale duplikat:", existing.Name)
		existing:Destroy()
	end

	local uiScale    = Instance.new("UIScale")
	uiScale.Name     = "AutoUIScale"
	uiScale.Scale    = 1 -- ★ Default ke 1, bukan 0
	uiScale.Parent   = targetGui
	return uiScale
end

local function applyScale(uiScale: UIScale)
	local camera = workspace.CurrentCamera
	if not camera then 
		warn("[ScaleSystem] Camera tidak tersedia")
		return 
	end

	local viewportSize = camera.ViewportSize

	if viewportSize.X == 0 or viewportSize.Y == 0 then
		warn("[ScaleSystem] ViewportSize 0, menunggu...")

		local startTime = tick()
		while viewportSize.X == 0 or viewportSize.Y == 0 do
			if tick() - startTime > 2 then
				warn("[ScaleSystem] Timeout menunggu viewport, gunakan default scale 1")
				uiScale.Scale = 1
				return
			end
			task.wait(0.1)
			viewportSize = camera.ViewportSize
		end
	end

	local rawScale = ScaleUtils.computeRawScale(
		viewportSize,
		Vector2.new(Config.BASE_RESOLUTION_X, Config.BASE_RESOLUTION_Y)
	)

	local finalScale = ScaleUtils.applyBoostCurve(rawScale)

	finalScale = math.clamp(finalScale, Config.MIN_SCALE, Config.MAX_SCALE)

	if finalScale ~= finalScale then -- NaN check
		warn("[ScaleSystem] Scale NaN detected, reset ke 1")
		finalScale = 1
	end

	if finalScale <= 0 then
		warn("[ScaleSystem] Scale <= 0 detected, reset ke 1")
		finalScale = 1
	end

	uiScale.Scale = finalScale

	-- Debug info
	if Config.DEBUG_MODE then
		print(string.format(
			"[ScaleSystem] Viewport: %dx%d | Raw: %.3f | Final: %.3f",
			viewportSize.X, viewportSize.Y, rawScale, finalScale
			))
	end
end

-- ══════════════════════════════════════════
-- CONSTRUCTOR
-- ══════════════════════════════════════════

function ScaleSystem.new(targetGui: ScreenGui)
	assert(typeof(targetGui) == "Instance" and targetGui:IsA("ScreenGui"),
		"[ScaleSystem] targetGui harus berupa ScreenGui")

	local self = setmetatable({}, ScaleSystem)

	self._gui        = targetGui
	self._uiScale    = getOrCreateUIScale(targetGui)
	self._connections= {}
	self._active     = false

	self:Start()
	return self
end

-- ══════════════════════════════════════════
-- PUBLIC METHODS
-- ══════════════════════════════════════════

function ScaleSystem:Start()
	if self._active then return end
	self._active = true

	-- ★ Delay sedikit untuk memastikan viewport ready
	task.defer(function()
		applyScale(self._uiScale)
	end)

	local function connectCamera()
		local camera = workspace.CurrentCamera
		if not camera then return end

		local conn = camera:GetPropertyChangedSignal("ViewportSize"):Connect(function()
			-- ★ Debounce untuk mencegah spam
			task.defer(function()
				if self._active then
					applyScale(self._uiScale)
				end
			end)
		end)
		table.insert(self._connections, conn)
	end

	connectCamera()

	local camConn = workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(function()
		for _, c in ipairs(self._connections) do c:Disconnect() end
		self._connections = {}
		connectCamera()
	end)
	table.insert(self._connections, camConn)

	local destroyConn = self._gui.Destroying:Connect(function()
		self:Destroy()
	end)
	table.insert(self._connections, destroyConn)
end

function ScaleSystem:ForceUpdate()
	if self._uiScale then
		applyScale(self._uiScale)
	end
end

function ScaleSystem:GetCurrentScale(): number
	return self._uiScale and self._uiScale.Scale or 1
end

-- ★ BARU: Set scale manual (untuk testing)
function ScaleSystem:SetScale(scale: number)
	if self._uiScale then
		self._uiScale.Scale = math.clamp(scale, Config.MIN_SCALE, Config.MAX_SCALE)
	end
end

-- ★ BARU: Reset ke scale default
function ScaleSystem:Reset()
	if self._uiScale then
		self._uiScale.Scale = 1
	end
end

function ScaleSystem:Destroy()
	if not self._active then return end
	self._active = false

	for _, conn in ipairs(self._connections) do
		conn:Disconnect()
	end
	self._connections = {}

	if self._uiScale and self._uiScale.Name == "AutoUIScale" then
		self._uiScale:Destroy()
	end

	self._uiScale = nil
	self._gui     = nil
end

return ScaleSystem

-- ============================================================
