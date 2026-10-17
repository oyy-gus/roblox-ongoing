local replicatedStorage = game:GetService("ReplicatedStorage")
local Players           = game:GetService("Players")

local ClientConfig       = require(script.Parent.ClientConfig)
local ClientDebug        = require(script.Parent.ClientDebug)
local UIModule           = require(script.Parent.UIModule)
local NotificationModule = require(script.Parent.NotificationModule)

local BroadcastListenerModule = {}
local localPlayer = Players.LocalPlayer

local function getDonationTier(amount)
	for _, tier in ipairs(ClientConfig.DONATION_COLORS) do
		if amount >= tier.min then
			return tier.color, tier.name, tier.emoji or "💝"
		end
	end
	local lastTier = ClientConfig.DONATION_COLORS[#ClientConfig.DONATION_COLORS]
	return lastTier.color, lastTier.name, lastTier.emoji or "💝"
end

local function colorToHex(color)
	return string.format("%02X%02X%02X",
		math.floor(color.R * 255),
		math.floor(color.G * 255),
		math.floor(color.B * 255)
	)
end

local function formatDonorInfo(displayName, amount, isSelf)
	local color = getDonationTier(amount)
	local hex = colorToHex(color)
	local nameToShow = isSelf and "Kamu" or displayName

	return string.format(
		'<font color="#%s"><b>%s</b></font> berdonasi <font color="#%s"><b>%s Robux</b></font>',
		hex, nameToShow, hex, UIModule.formatNumber(amount)
	)
end

local function loadAvatarHeadshot(userId, avatarImage, fallbackIcon, tierEmoji)
	if not userId or type(userId) ~= "number" then
		if fallbackIcon then
			fallbackIcon.Text = tierEmoji or "💝"
			fallbackIcon.Visible = true
		end
		return
	end

	if fallbackIcon then
		fallbackIcon.Visible = true
		fallbackIcon.Text = "..."
	end

	task.spawn(function()
		local success, imageUrl = pcall(function()
			return Players:GetUserThumbnailAsync(
				userId,
				Enum.ThumbnailType.HeadShot,
				Enum.ThumbnailSize.Size100x100
			)
		end)

		if success and imageUrl and avatarImage and avatarImage.Parent then
			avatarImage.Image = imageUrl
			if fallbackIcon then
				fallbackIcon.Visible = false
			end
		else
			if fallbackIcon then
				fallbackIcon.Text = tierEmoji or "💝"
				fallbackIcon.Visible = true
			end
		end
	end)
end

local function updateTierBadge(notificationframe, amount)
	local tierBadge = notificationframe:FindFirstChild("TierBadge")
	if not tierBadge then return end

	local tierText = tierBadge:FindFirstChild("TierText")
	if not tierText then return end

	local _, tierName, emoji = getDonationTier(amount)
	tierText.Text = emoji .. " " .. tierName

	local textLength = #tierText.Text
	tierBadge.Size = UDim2.new(0, math.max(65, textLength * 6 + 16), 0, 20)
end

local function updateOnlineIndicator(notificationframe, donorUserId)
	local avatarBorder = notificationframe:FindFirstChild("AvatarBorder")
	if not avatarBorder then return end

	local onlineIndicator = avatarBorder:FindFirstChild("OnlineIndicator")
	if not onlineIndicator then return end

	if not donorUserId or type(donorUserId) ~= "number" then
		onlineIndicator.Visible = false
		return
	end

	local success, donorPlayer = pcall(function()
		return Players:GetPlayerByUserId(donorUserId)
	end)

	onlineIndicator.Visible = success and (donorPlayer ~= nil)
end

local function resetAvatar(notificationframe, tierEmoji)
	local avatarBorder = notificationframe:FindFirstChild("AvatarBorder")
	if not avatarBorder then return end

	local avatarContainer = avatarBorder:FindFirstChild("AvatarContainer")
	if not avatarContainer then return end

	local avatarImage = avatarContainer:FindFirstChild("AvatarImage")
	local fallbackIcon = avatarContainer:FindFirstChild("FallbackIcon")

	if avatarImage then
		avatarImage.Image = ""
	end

	if fallbackIcon then
		fallbackIcon.Text = tierEmoji or "💝"
		fallbackIcon.Visible = true
	end
end

function BroadcastListenerModule.setupListener(notificationframe)
	local broadcastRemote = replicatedStorage:WaitForChild("ReceiveDonationBroadcast", 10)
	if not broadcastRemote then
		ClientDebug.warn("KESALAHAN", "Remote broadcast tidak ditemukan!")
		return
	end

	broadcastRemote.OnClientEvent:Connect(function(displayName, amount, message, donorUserId)
		ClientDebug.log("PURCHASE", "=== RECEIVED BROADCAST ===")
		ClientDebug.log("PURCHASE", "From:", displayName or "Unknown", "Amount:", amount or 0, "UserId:", donorUserId or "nil")

		amount = tonumber(amount) or 0
		displayName = displayName or "Seseorang"

		local isSelf = donorUserId and (donorUserId == localPlayer.UserId)
		local tierColor, tierName, tierEmoji = getDonationTier(amount)

		resetAvatar(notificationframe, tierEmoji)

		if donorUserId and type(donorUserId) == "number" then
			local avatarBorder = notificationframe:FindFirstChild("AvatarBorder")
			if avatarBorder then
				local avatarContainer = avatarBorder:FindFirstChild("AvatarContainer")
				if avatarContainer then
					local avatarImage = avatarContainer:FindFirstChild("AvatarImage")
					local fallbackIcon = avatarContainer:FindFirstChild("FallbackIcon")

					if avatarImage then
						loadAvatarHeadshot(donorUserId, avatarImage, fallbackIcon, tierEmoji)
					end
				end
			end
		end

		updateOnlineIndicator(notificationframe, donorUserId)

		updateTierBadge(notificationframe, amount)

		local contentArea = notificationframe:FindFirstChild("ContentArea")
		if contentArea then
			local headerLabel = contentArea:FindFirstChild("HeaderLabel")
			if headerLabel then
				local hex = colorToHex(tierColor)
				headerLabel.RichText = true
				headerLabel.Text = string.format(
					'<font color="#%s"><b>%s Donation!</b></font>',
					hex, tierName
				)
			end

			local infoLabel = contentArea:FindFirstChild("Infolabel")
			if infoLabel then
				infoLabel.RichText = true
				infoLabel.Text = formatDonorInfo(displayName, amount, isSelf)
			end

			local messageContainer = contentArea:FindFirstChild("MessageContainer")
			if messageContainer then
				local messageLabel = messageContainer:FindFirstChild("Message")
				local quoteMark = messageContainer:FindFirstChild("QuoteMark")

				if message and message ~= "" then
					messageContainer.Visible = true
					if messageLabel then
						messageLabel.Text = message
					end
					if quoteMark then
						quoteMark.TextColor3 = tierColor
					end
				else
					messageContainer.Visible = false
				end
			end
		end

		NotificationModule.show()

		task.delay(6, function()
			NotificationModule.hide()
		end)
	end)

	ClientDebug.log("UI", "✅ Broadcast listener setup complete")
end

return BroadcastListenerModule
