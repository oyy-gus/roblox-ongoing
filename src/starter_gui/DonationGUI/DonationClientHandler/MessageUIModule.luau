local replicatedStorage = game:GetService("ReplicatedStorage")
local ClientConfig = require(script.Parent.ClientConfig)
local ClientDebug = require(script.Parent.ClientDebug)
local UIModule = require(script.Parent.UIModule)

local MessageUIModule = {}

function MessageUIModule.showMessageFrame(elements, state, donationAmount)
	state.lastPurchasedAmount = donationAmount
	state.canSendMessage = true

	elements.mainframe.Visible = false
	ClientDebug.log("UI", "Auto-closed mainframe")

	elements.MessageFrame.Visible = true

	local textbox = elements.MessageFrame:WaitForChild("TextBox")
	textbox.Text = ""
	textbox:CaptureFocus()

	ClientDebug.log("UI", "Message frame opened for donation:", donationAmount)
end

local function hideMessageFrame(elements, state)
	elements.MessageFrame.Visible = false
	state.canSendMessage = false

	local textbox = elements.MessageFrame:WaitForChild("TextBox")
	textbox.Text = ""

	ClientDebug.log("UI", "Message frame closed")
end

local function sendMessage(elements, state)
	local textbox = elements.MessageFrame:WaitForChild("TextBox")
	local message = textbox.Text:gsub("^%s+", ""):gsub("%s+$", "")

	if #message < 1 then
		UIModule.notify("Error", ClientConfig.MESSAGES.MESSAGE_TOO_SHORT, ClientConfig.NOTIFICATIONS.DURATION.ERROR)
		return
	end

	if #message > ClientConfig.MESSAGE.MAX_LENGTH then
		UIModule.notify("Error", ClientConfig.MESSAGES.MESSAGE_TOO_LONG, ClientConfig.NOTIFICATIONS.DURATION.ERROR)
		return
	end

	local currentTime = tick()
	if currentTime - state.lastMessageTime < ClientConfig.MESSAGE.COOLDOWN then
		local remaining = math.ceil(ClientConfig.MESSAGE.COOLDOWN - (currentTime - state.lastMessageTime))
		UIModule.notify("Cooldown", "Tunggu " .. remaining .. " detik lagi", ClientConfig.NOTIFICATIONS.DURATION.INFO)
		return
	end

	local remote = replicatedStorage:WaitForChild("BroadcastDonationMessage", 5)
	if not remote then
		UIModule.notify("Error", "Server tidak tersedia", ClientConfig.NOTIFICATIONS.DURATION.ERROR)
		return
	end

	local success, result = pcall(function()
		return remote:InvokeServer(message, state.lastPurchasedAmount)
	end)

	if success and result then
		UIModule.notify(
			ClientConfig.MESSAGES.MESSAGE_SENT,
			ClientConfig.MESSAGES.MESSAGE_SENT_DESC,
			ClientConfig.NOTIFICATIONS.DURATION.SUCCESS
		)
		state.lastMessageTime = currentTime
		hideMessageFrame(elements, state)
		ClientDebug.log("PURCHASE", "Pesan berhasil dikirim")
	else
		UIModule.notify("Error", "Gagal mengirim pesan", ClientConfig.NOTIFICATIONS.DURATION.ERROR)
		ClientDebug.warn("KESALAHAN", "Gagal mengirim pesan:", result)
	end
end

function MessageUIModule.setupMessageFrame(elements, state)
	local MessageFrame = elements.MessageFrame
	local mcloseBtn = MessageFrame:WaitForChild("Header"):WaitForChild("CloseBtn")
	local textbox = MessageFrame:WaitForChild("TextBox")
	local sendBtn = MessageFrame:WaitForChild("SendBtn")
	local cancelbtn = MessageFrame:WaitForChild("CancelBtn")

	mcloseBtn.MouseButton1Click:Connect(function()
		hideMessageFrame(elements, state)
	end)

	cancelbtn.MouseButton1Click:Connect(function()
		hideMessageFrame(elements, state)
	end)

	sendBtn.MouseButton1Click:Connect(function()
		sendMessage(elements, state)
	end)

	textbox.FocusLost:Connect(function(enterPressed)
		if enterPressed and state.canSendMessage then
			sendMessage(elements, state)
		end
	end)
end

return MessageUIModule
