local TweenService = game:GetService("TweenService")

local PanelAnimationController = {}
PanelAnimationController.__index = PanelAnimationController

PanelAnimationController.State = {
	Closed = "Closed",
	Opening = "Opening",
	Open = "Open",
	Closing = "Closing",
}

local DEFAULT_CONFIG = {
	OpenDuration = 0.25,
	CloseDuration = 0.18,
	OpenEasingStyle = Enum.EasingStyle.Quart,
	OpenEasingDirection = Enum.EasingDirection.Out,
	CloseEasingStyle = Enum.EasingStyle.Quart,
	CloseEasingDirection = Enum.EasingDirection.In,
	CollapsedHeight = 44,
}

function PanelAnimationController.new(panelInstance, config)
	local self = setmetatable({}, PanelAnimationController)
	self.Panel = panelInstance
	self.Config = setmetatable(config or {}, { __index = DEFAULT_CONFIG })
	self.CurrentState = PanelAnimationController.State.Closed
	self.ActiveTweens = {}
	self.OnStateChanged = Instance.new("BindableEvent")
	self.IsCanvasGroup = panelInstance:IsA("CanvasGroup")

	self.TargetSize = panelInstance.Size
	self.TargetPosition = panelInstance.Position

	return self
end

function PanelAnimationController:SetTargetSize(size)
	self.TargetSize = size
end

function PanelAnimationController:SetTargetPosition(pos)
	self.TargetPosition = pos
end

function PanelAnimationController:GetState()
	return self.CurrentState
end

function PanelAnimationController:IsOpen()
	return self.CurrentState == PanelAnimationController.State.Open or self.CurrentState == PanelAnimationController.State.Opening
end

function PanelAnimationController:_CancelTweens()
	for _, tween in ipairs(self.ActiveTweens) do
		pcall(function()
			tween:Cancel()
		end)
	end
	self.ActiveTweens = {}
end

function PanelAnimationController:_SetState(newState)
	local oldState = self.CurrentState
	if oldState == newState then return end
	self.CurrentState = newState
	self.OnStateChanged:Fire(newState, oldState)
end

function PanelAnimationController:Open(targetHeight)
	if self.CurrentState == PanelAnimationController.State.Open then return end

	self:_CancelTweens()
	self:_SetState(PanelAnimationController.State.Opening)

	local panel = self.Panel
	if not panel then return end

	local fullSize = self.TargetSize
	if targetHeight then
		fullSize = UDim2.new(self.TargetSize.X.Scale, self.TargetSize.X.Offset, 0, targetHeight)
	end

	local collapsedSize = UDim2.new(fullSize.X.Scale, fullSize.X.Offset, 0, self.Config.CollapsedHeight)

	if self.CurrentState == PanelAnimationController.State.Opening and not panel.Visible then
		panel.Size = collapsedSize
		if self.IsCanvasGroup then
			panel.GroupTransparency = 1
		else
			panel.BackgroundTransparency = 1
		end
	end

	panel.Visible = true

	local tweenInfo = TweenInfo.new(
		self.Config.OpenDuration,
		self.Config.OpenEasingStyle,
		self.Config.OpenEasingDirection
	)

	local targetProps = {
		Size = fullSize,
	}

	if self.IsCanvasGroup then
		targetProps.GroupTransparency = 0
	else
		targetProps.BackgroundTransparency = 0
	end

	local openTween = TweenService:Create(panel, tweenInfo, targetProps)
	table.insert(self.ActiveTweens, openTween)

	openTween.Completed:Connect(function(status)
		if status == Enum.PlaybackState.Completed and self.CurrentState == PanelAnimationController.State.Opening then
			self:_SetState(PanelAnimationController.State.Open)
		end
	end)

	openTween:Play()
end

function PanelAnimationController:Close()
	if self.CurrentState == PanelAnimationController.State.Closed then return end

	self:_CancelTweens()
	self:_SetState(PanelAnimationController.State.Closing)

	local panel = self.Panel
	if not panel then return end

	local collapsedSize = UDim2.new(panel.Size.X.Scale, panel.Size.X.Offset, 0, self.Config.CollapsedHeight)

	local tweenInfo = TweenInfo.new(
		self.Config.CloseDuration,
		self.Config.CloseEasingStyle,
		self.Config.CloseEasingDirection
	)

	local targetProps = {
		Size = collapsedSize,
	}

	if self.IsCanvasGroup then
		targetProps.GroupTransparency = 1
	else
		targetProps.BackgroundTransparency = 1
	end

	local closeTween = TweenService:Create(panel, tweenInfo, targetProps)
	table.insert(self.ActiveTweens, closeTween)

	closeTween.Completed:Connect(function(status)
		if status == Enum.PlaybackState.Completed and self.CurrentState == PanelAnimationController.State.Closing then
			panel.Visible = false
			self:_SetState(PanelAnimationController.State.Closed)
		end
	end)

	closeTween:Play()
end

function PanelAnimationController:Toggle(targetHeight)
	if self:IsOpen() then
		self:Close()
	else
		self:Open(targetHeight)
	end
end

function PanelAnimationController:Destroy()
	self:_CancelTweens()
	if self.OnStateChanged then
		self.OnStateChanged:Destroy()
		self.OnStateChanged = nil
	end
	self.Panel = nil
end

return PanelAnimationController
