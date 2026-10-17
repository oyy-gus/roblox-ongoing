local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local GuiService = game:GetService("GuiService")
local ContextActionService = game:GetService("ContextActionService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local playerScripts = player:WaitForChild("PlayerScripts")

local controls = nil
local cameraInput = nil

local function getControls()
	if not controls then
		pcall(function()
			local PlayerModule = require(playerScripts:WaitForChild("PlayerModule", 5))
			if PlayerModule and PlayerModule.GetControls then
				controls = PlayerModule:GetControls()
			end
		end)
	end
	return controls
end

local function getCameraInput()
	if not cameraInput then
		pcall(function()
			local PlayerModule = playerScripts:WaitForChild("PlayerModule", 5)
			if PlayerModule then
				local camModule = PlayerModule:FindFirstChild("CameraModule")
				if camModule then
					local ci = camModule:FindFirstChild("CameraInput")
					if ci then
						cameraInput = require(ci)
					end
				end
			end
		end)
	end
	return cameraInput
end

task.defer(function()
	getControls()
	getCameraInput()
end)

local activeGuiTouches = {}
local isLocked = false

local TARGET_GUI_NAMES = {
	["MenuGUI"] = true,
	["EmoteGui"] = true,
	["DonationGUI"] = true,
	["AdminGUI"] = true,
	["UnifiedToolGui"] = true,
}

local function isInsideObject(obj, x, y)
	if not obj or not obj.Visible then return false end
	local pos = obj.AbsolutePosition
	local size = obj.AbsoluteSize
	return (x >= pos.X and x <= pos.X + size.X and y >= pos.Y and y <= pos.Y + size.Y)
end

local function isPointInsideAnyOpenGui(x, y)

	local menuGui = playerGui:FindFirstChild("MenuGUI")
	if menuGui and menuGui.Enabled then
		local pc = menuGui:FindFirstChild("PanelContainer")
		if pc and pc.Visible then
			local mp = pc:FindFirstChild("MainPanel")
			if mp and isInsideObject(mp, x, y) then return true end
		end
		local profileSheet = menuGui:FindFirstChild("ProfileSheet", true)
		if profileSheet and isInsideObject(profileSheet, x, y) then return true end
	end

	local emoteGui = playerGui:FindFirstChild("EmoteGui")
	if emoteGui and emoteGui.Enabled then
		local mf = emoteGui:FindFirstChild("MainFrame")
		if mf and isInsideObject(mf, x, y) then return true end
	end

	local adminGui = playerGui:FindFirstChild("AdminGUI")
	if adminGui and adminGui.Enabled then
		local pc = adminGui:FindFirstChild("PanelContainer")
		if pc and pc.Visible then
			local mp = pc:FindFirstChild("MainPanel")
			if mp and isInsideObject(mp, x, y) then return true end
		end
	end

	local donationGui = playerGui:FindFirstChild("DonationGUI")
	if donationGui and donationGui.Enabled then
		local mf = donationGui:FindFirstChild("MainFrame")
		if mf and isInsideObject(mf, x, y) then return true end
		local msgFrame = donationGui:FindFirstChild("MessageFrame")
		if msgFrame and isInsideObject(msgFrame, x, y) then return true end
	end

	local toolGui = playerGui:FindFirstChild("UnifiedToolGui")
	if toolGui and toolGui.Enabled then
		local tp = toolGui:FindFirstChild("ToolPanel")
		if tp and isInsideObject(tp, x, y) then return true end
	end

	local inset = GuiService:GetGuiInset()
	local objects = playerGui:GetGuiObjectsAtPosition(x, y)
	if #objects == 0 and inset.Y > 0 then
		objects = playerGui:GetGuiObjectsAtPosition(x, y - inset.Y)
	end

	for _, obj in ipairs(objects) do
		local sg = obj:FindFirstAncestorOfClass("ScreenGui")
		if sg and sg.Enabled and obj.Visible then
			if TARGET_GUI_NAMES[sg.Name] or sg.DisplayOrder >= 100 then
				return true
			end
		end
	end

	return false
end

local function lockControlsAndCamera()
	if isLocked then return end
	isLocked = true

	local ctrl = getControls()
	if ctrl and ctrl.Disable then
		pcall(function() ctrl:Disable() end)
	end

	local ci = getCameraInput()
	if ci and ci.setInputEnabled then
		pcall(function() ci.setInputEnabled(false) end)
	end

	pcall(function()
		ContextActionService:BindActionAtPriority(
			"GuiMobileTouchSinkMouse",
			function() return Enum.ContextActionResult.Sink end,
			false,
			Enum.ContextActionPriority.High.Value + 2000,
			Enum.UserInputType.MouseMovement
		)
	end)
end

local function unlockControlsAndCamera()
	if not isLocked then return end
	isLocked = false

	local ctrl = getControls()
	if ctrl and ctrl.Enable then
		pcall(function() ctrl:Enable(true) end)
	end

	local ci = getCameraInput()
	if ci and ci.setInputEnabled then
		pcall(function() ci.setInputEnabled(true) end)
	end

	pcall(function()
		ContextActionService:UnbindAction("GuiMobileTouchSinkMouse")
	end)
end

UserInputService.TouchStarted:Connect(function(touch, gameProcessed)
	local x = touch.Position.X
	local y = touch.Position.Y
	if isPointInsideAnyOpenGui(x, y) then
		activeGuiTouches[touch] = true
		lockControlsAndCamera()
	end
end)

UserInputService.TouchEnded:Connect(function(touch)
	if activeGuiTouches[touch] then
		activeGuiTouches[touch] = nil
		if next(activeGuiTouches) == nil then
			unlockControlsAndCamera()
		end
	end
end)

UserInputService.InputEnded:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.Touch and activeGuiTouches[input] then
		activeGuiTouches[input] = nil
		if next(activeGuiTouches) == nil then
			unlockControlsAndCamera()
		end
	end
end)

player.CharacterAdded:Connect(function()
	activeGuiTouches = {}
	unlockControlsAndCamera()
end)

print("✅ [GuiMobileTouchSink] Berhasil diinisialisasi")
