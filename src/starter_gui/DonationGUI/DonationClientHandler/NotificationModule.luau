local tweenService = game:GetService("TweenService")
local ClientConfig = require(script.Parent.ClientConfig)
local ClientDebug  = require(script.Parent.ClientDebug)

local NotificationModule = {}

local notificationSound      = nil
local isNotificationShowing  = false
local currentHideTween       = nil
local currentShowTweens      = {}
local originalTransparencies = {}
local notificationframe      = nil

local POS_VISIBLE = UDim2.new(0.5, 0, 0, 25)
local POS_HIDDEN  = UDim2.new(0.5, 0, 0, -130)

local function setupNotificationSound()
	if notificationSound or not notificationframe then return end
	notificationSound         = Instance.new("Sound")
	notificationSound.SoundId = ClientConfig.NOTIFICATION_ANIMATION.SOUND_ID
	notificationSound.Volume  = ClientConfig.NOTIFICATION_ANIMATION.SOUND_VOLUME
	notificationSound.Parent  = notificationframe
end

local function playNotificationSound()
	if not ClientConfig.NOTIFICATION_ANIMATION.ENABLED then return end
	setupNotificationSound()
	if notificationSound then notificationSound:Play() end
end

local function shakeNotification()
	if not ClientConfig.NOTIFICATION_ANIMATION.SHAKE_ENABLED or not notificationframe then return end
	local intensity = ClientConfig.NOTIFICATION_ANIMATION.SHAKE_INTENSITY
	local duration  = ClientConfig.NOTIFICATION_ANIMATION.SHAKE_DURATION

	for i = 1, 4 do
		notificationframe.Position = UDim2.new(
			POS_VISIBLE.X.Scale, POS_VISIBLE.X.Offset + math.random(-intensity, intensity),
			POS_VISIBLE.Y.Scale, POS_VISIBLE.Y.Offset + math.random(-intensity, intensity)
		)
		task.wait(duration / 4)
	end
	notificationframe.Position = POS_VISIBLE
end

local function cancelAllTweens()
	if currentHideTween then currentHideTween:Cancel(); currentHideTween = nil end
	for _, t in ipairs(currentShowTweens) do if t then t:Cancel() end end
	currentShowTweens = {}
end

local function saveOriginalTransparencies()
	if next(originalTransparencies) or not notificationframe then return end
	originalTransparencies[notificationframe] = notificationframe.BackgroundTransparency
	for _, obj in ipairs(notificationframe:GetDescendants()) do
		if obj:IsA("GuiObject") then
			originalTransparencies[obj] = {
				Background = obj.BackgroundTransparency,
				Text  = (obj:IsA("TextLabel") or obj:IsA("TextButton")) and obj.TextTransparency or nil,
				Image = (obj:IsA("ImageLabel") or obj:IsA("ImageButton")) and obj.ImageTransparency or nil,
			}
		end
	end
end

function NotificationModule.initialize(frame)
	notificationframe             = frame
	notificationframe.AnchorPoint = Vector2.new(0.5, 0)
	notificationframe.Position    = POS_HIDDEN
	notificationframe.Visible     = false
	saveOriginalTransparencies()
	setupNotificationSound()
	ClientDebug.log("UI", "✅ NotificationModule initialized")
end

function NotificationModule.show()
	if not notificationframe then return end
	saveOriginalTransparencies()

	if isNotificationShowing then
		cancelAllTweens()
		notificationframe.Position = POS_HIDDEN
		isNotificationShowing      = false
		task.wait(0.05)
	end

	isNotificationShowing      = true
	notificationframe.Position = POS_HIDDEN
	notificationframe.Visible  = true
	playNotificationSound()

	if ClientConfig.NOTIFICATION_ANIMATION.ENABLED then
		local slideTween = tweenService:Create(
			notificationframe,
			TweenInfo.new(
				ClientConfig.NOTIFICATION_ANIMATION.SLIDE_TIME,
				ClientConfig.NOTIFICATION_ANIMATION.SLIDE_STYLE,
				ClientConfig.NOTIFICATION_ANIMATION.SLIDE_DIRECTION
			),
			{ Position = POS_VISIBLE }
		)
		table.insert(currentShowTweens, slideTween)
		slideTween:Play()
		slideTween.Completed:Connect(function()
			if isNotificationShowing then shakeNotification() end
		end)
	else
		notificationframe.Position = POS_VISIBLE
	end

	ClientDebug.log("UI", "Notification shown")
end

function NotificationModule.hide()
	if not notificationframe or not isNotificationShowing then return end
	cancelAllTweens()

	if ClientConfig.NOTIFICATION_ANIMATION.ENABLED then
		local slideOut = tweenService:Create(
			notificationframe,
			TweenInfo.new(
				ClientConfig.NOTIFICATION_ANIMATION.SLIDE_TIME,
				Enum.EasingStyle.Back,
				Enum.EasingDirection.In
			),
			{ Position = POS_HIDDEN }
		)
		currentHideTween = slideOut
		slideOut:Play()

		local done = false
		local function finish()
			if done then return end
			done                       = true
			notificationframe.Visible  = false
			notificationframe.Position = POS_HIDDEN
			isNotificationShowing      = false
			currentHideTween           = nil
		end
		slideOut.Completed:Connect(finish)
		task.delay(ClientConfig.NOTIFICATION_ANIMATION.SLIDE_TIME + 0.2, finish)
	else
		notificationframe.Visible  = false
		notificationframe.Position = POS_HIDDEN
		isNotificationShowing      = false
	end
end

function NotificationModule.cleanup()
	cancelAllTweens()
end

return NotificationModule
 