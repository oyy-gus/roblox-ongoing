local starterGui        = game:GetService("StarterGui")
local replicatedStorage = game:GetService("ReplicatedStorage")
local ClientConfig      = require(script.Parent.ClientConfig)
local UIStrings         = require(replicatedStorage:WaitForChild("Modules"):WaitForChild("UIStrings"))

local NotifModule = nil
pcall(function()
	local modules = replicatedStorage:WaitForChild("Modules", 5)
	if modules then
		NotifModule = require(modules:WaitForChild("NotifModule", 5))
	end
end)

local UIModule = {}

function UIModule.initializeUI(elements)
	elements.mainframe.Visible = false
	elements.templateframe.Visible = false
	elements.MessageFrame.Visible = false
	elements.notificationframe.Visible = false
end

function UIModule.notify(title, text, duration)
	if not ClientConfig.NOTIFICATIONS.ENABLED then return end

	local dur = duration or ClientConfig.NOTIFICATIONS.DURATION.DEFAULT or 3

	if NotifModule then
		local tLower = tostring(title):lower()
		if tLower:find("error") or tLower:find("gagal") or tLower:find("failed") then
			NotifModule.Error(title, text, dur)
		elseif tLower:find("warning") or tLower:find("cooldown") or tLower:find("peringatan") then
			NotifModule.Warning(title, text, dur)
		elseif tLower:find("sukses") or tLower:find("success") or tLower:find("berhasil") then
			NotifModule.Success(title, text, dur)
		else
			NotifModule.Info(title, text, dur)
		end
		return
	end

	pcall(function()
		starterGui:SetCore("SendNotification", {
			Title = title,
			Text = text,
			Duration = dur
		})
	end)
end

function UIModule.formatNumber(num)
	num = tonumber(num) or 0
	local formatted = tostring(num)
	while true do
		local k
		formatted, k = string.gsub(formatted, "^(-?%d+)(%d%d%d)", '%1,%2')
		if k == 0 then break end
	end
	return formatted
end

function UIModule.showError(container, message)
	local errorLabel = container:FindFirstChild("ErrorLabel")

	if not errorLabel then
		errorLabel = Instance.new("TextLabel")
		errorLabel.Name = "ErrorLabel"
		errorLabel.Size = UDim2.new(1, -20, 0, 100)
		errorLabel.Position = UDim2.new(0, 10, 0, 50)
		errorLabel.BackgroundTransparency = 1
		errorLabel.TextColor3 = Color3.fromRGB(255, 100, 100)
		errorLabel.TextSize = 11
		errorLabel.Font = Enum.Font.Gotham
		errorLabel.TextWrapped = true
		errorLabel.Parent = container
		UIStrings.LockTextSize(errorLabel, 11)
	end

	errorLabel.Text = message
	errorLabel.Visible = true
end

function UIModule.hideError(container)
	local errorLabel = container:FindFirstChild("ErrorLabel")
	if errorLabel then
		errorLabel.Visible = false
	end
end

function UIModule.setLoading(container, show)
	local loading = container:FindFirstChild("LoadingLabel")

	if show then
		if not loading then
			loading = Instance.new("TextLabel")
			loading.Name = "LoadingLabel"
			loading.Size = UDim2.new(1, -20, 0, 60)
			loading.Position = UDim2.new(0, 10, 0, 20)
			loading.BackgroundTransparency = 1
			loading.Text = ClientConfig.UI.LOADING_TEXT
			loading.TextColor3 = Color3.fromRGB(255, 255, 255)
			loading.TextSize = 12
			loading.Font = Enum.Font.GothamSemibold
			loading.TextWrapped = true
			loading.Parent = container
			UIStrings.LockTextSize(loading, 12)
		end
		loading.Visible = true
	elseif loading then
		loading.Visible = false
	end
end

return UIModule
