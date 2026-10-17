local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local gui = script.Parent

local DisplayGUIBuilder = require(script.DisplayGUIBuilder)
local elements = DisplayGUIBuilder.build(gui)

local Frame = elements.Frame
local nameLabel = elements.nameLabel
local infoLabel = elements.infoLabel
local typeLabel = elements.typeLabel
local avatarImage = elements.avatarImage

local showDonationGUI = RS:WaitForChild("Remotes"):WaitForChild("ShowDonationGUI")

local GUI_DISPLAY_DURATION = 5

local visiblePosition = UDim2.new(1, -15, 1, -15)
local hiddenPosition = UDim2.new(1.3, 0, 1, -15)

Frame.Position = hiddenPosition
Frame.Visible = false

local donationQueue = {}
local isDisplaying = false

local function loadAvatar(userId)
	if not userId then return end

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
		end
	end)
end

local function getDonorUserId(donorName)
	for _, p in ipairs(Players:GetPlayers()) do
		if p.DisplayName == donorName or p.Name == donorName then
			return p.UserId
		end
	end
	return nil
end

local function displayDonation(donorName, amount, donationType)
	nameLabel.Text = donorName
	infoLabel.Text = "donated " .. tostring(amount) .. " Robux!"
	typeLabel.Text = donationType or "Thank You!"

	avatarImage.Image = ""

	local userId = getDonorUserId(donorName)
	if userId then
		loadAvatar(userId)
	end

	Frame.Visible = true

	local tweenInfoIn = TweenInfo.new(
		0.5,
		Enum.EasingStyle.Back,
		Enum.EasingDirection.Out
	)

	local slideIn = TweenService:Create(Frame, tweenInfoIn, {
		Position = visiblePosition
	})

	slideIn:Play()
	slideIn.Completed:Wait()

	task.wait(GUI_DISPLAY_DURATION)

	local tweenInfoOut = TweenInfo.new(
		0.4,
		Enum.EasingStyle.Back,
		Enum.EasingDirection.In
	)

	local slideOut = TweenService:Create(Frame, tweenInfoOut, {
		Position = hiddenPosition
	})

	slideOut:Play()
	slideOut.Completed:Wait()

	Frame.Visible = false
end

local function processDonationQueue()
	if isDisplaying then return end

	while #donationQueue > 0 do
		isDisplaying = true

		local donation = table.remove(donationQueue, 1)
		displayDonation(donation.donorName, donation.amount, donation.donationType)

		task.wait(0.3)
	end

	isDisplaying = false
end

showDonationGUI.OnClientEvent:Connect(function(donorName, amount, donationType)
	table.insert(donationQueue, {
		donorName = donorName,
		amount = amount,
		donationType = donationType
	})

	task.spawn(processDonationQueue)
end)

print("✅ [DonationDisplayClient] Initialized!")
