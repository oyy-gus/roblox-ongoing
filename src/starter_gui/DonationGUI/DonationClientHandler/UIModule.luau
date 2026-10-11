-- MODULE: UIModule (FINAL)
-- Letakkan sebagai child dari DonationClientHandler
-- ========================================

local starterGui = game:GetService("StarterGui")
local ClientConfig = require(script.Parent.ClientConfig)

local UIModule = {}

function UIModule.initializeUI(elements)
	elements.mainframe.Visible = false
	elements.templateframe.Visible = false
	elements.MessageFrame.Visible = false
	elements.notificationframe.Visible = false
end

function UIModule.notify(title, text, duration)
	if not ClientConfig.NOTIFICATIONS.ENABLED then return end

	pcall(function()
		starterGui:SetCore("SendNotification", {
			Title = title,
			Text = text,
			Duration = duration or ClientConfig.NOTIFICATIONS.DURATION.DEFAULT
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
		errorLabel.TextSize = 14
		errorLabel.Font = Enum.Font.Gotham
		errorLabel.TextWrapped = true
		errorLabel.Parent = container
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
			loading.TextSize = 16
			loading.Font = Enum.Font.GothamSemibold
			loading.TextWrapped = true
			loading.Parent = container
		end
		loading.Visible = true
	elseif loading then
		loading.Visible = false
	end
end

return UIModule

-- ========================================
-- LOCALSCRIPT - DonationDisplayClient
