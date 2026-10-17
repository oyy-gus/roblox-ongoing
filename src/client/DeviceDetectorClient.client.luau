local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local getDeviceRemote = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("GetDevice", 10)

if getDeviceRemote then
	getDeviceRemote.OnClientInvoke = function()

		local isMobile = UserInputService.TouchEnabled
			and not UserInputService.KeyboardEnabled
			and not UserInputService.MouseEnabled

		return isMobile
	end

	print("✅ [DeviceDetectorClient] Siap")
end
