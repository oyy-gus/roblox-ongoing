-- ====================================
-- DEVICE DETECTOR CLIENT
-- Place in: StarterPlayerScripts > DeviceDetectorClient
-- ====================================

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local getDeviceRemote = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("GetDevice", 10)

if getDeviceRemote then
	getDeviceRemote.OnClientInvoke = function()
		-- Check if mobile/touch device
		local isMobile = UserInputService.TouchEnabled 
			and not UserInputService.KeyboardEnabled 
			and not UserInputService.MouseEnabled

		return isMobile
	end

	print("✅ [DeviceDetectorClient] Ready")
end

--[[
    ╔═══════════════════════════════════════════════════════════════════════════╗
