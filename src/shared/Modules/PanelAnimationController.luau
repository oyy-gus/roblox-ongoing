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
	Mode = "Size",
	OpenDuration = 0.25,
	CloseDuration = 0.18,
	OpenEasingStyle = Enum.EasingStyle.Quart,
	OpenEasingDirection = Enum.EasingDirection.Out,
	CloseEasingStyle = Enum.EasingStyle.Quart,
	CloseEasingDirection = Enum.EasingDirection.In,
	CollapsedHeight = 44,
	ScaleStart = 0.9,
	ScaleEnd = 1.0,
	SlideOffsetY = 20,
}

function PanelAnimationController.new(panelInstance, config)
	local self = setmetatable({}, PanelAnimationController)
	self.Panel = panelInstance
	self.Config = setmetatable(config or {}, { __index = DEFAULT_CONFIG })
	self.Container = self.Config.Container
	self.UIScale = self.Config.UIScale or (panelInstance and panelInstance:FindFirstChildOfClass("UIScale"))
	self.Stroke = self.Config.Stroke or (panelInstance and panelInstance:FindFirstChildOfClass("UIStroke"))
	self.CurrentState = PanelAnimationController.State.Closed
	self.ActiveTweens = {}
	self.OnStateChanged = Instance.new("BindableEvent")
	self.IsCanvasGroup = panelInstance and panelInstance:IsA("CanvasGroup")
	self._token = 0
	self._syncingIcon = false

	if panelInstance then
		self.TargetSize = panelInstance.Size
		self.TargetPosition = panelInstance.Position
	end

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
	self._token += 1
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
	if self.CurrentState == PanelAnimationController.State.Open or self.CurrentState == PanelAnimationController.State.Opening then
		return
	end

	local panel = self.Panel
	if not panel then return end

	local wasClosed = (self.CurrentState == PanelAnimationController.State.Closed)
	self:_CancelTweens()
	local myToken = self._token
	self:_SetState(PanelAnimationController.State.Opening)

	if self.Container then
		self.Container.Visible = true
	end
	panel.Visible = true

	local mode = self.Config.Mode or "Size"
	local openInfo = TweenInfo.new(
		self.Config.OpenDuration,
		self.Config.OpenEasingStyle,
		self.Config.OpenEasingDirection
	)

	if mode == "CanvasGroup" then
		local targetPos = self.TargetPosition or panel.Position
		if self.Config.GetResetPosition then
			local ok, resX, resY = pcall(self.Config.GetResetPosition)
			if ok and typeof(resX) == "UDim2" then
				targetPos = resX
			elseif ok and typeof(resX) == "number" and typeof(resY) == "number" then
				targetPos = UDim2.new(0.5, resX, 0.5, resY)
			end
		end

		if wasClosed then
			panel.Position = UDim2.new(targetPos.X.Scale, targetPos.X.Offset, targetPos.Y.Scale, targetPos.Y.Offset - (self.Config.SlideOffsetY or 20))
			if self.UIScale then
				self.UIScale.Scale = self.Config.ScaleStart or 0.9
			end
			if self.IsCanvasGroup then
				panel.GroupTransparency = 1
			end
			if self.Stroke then
				self.Stroke.Transparency = 1
			end
		end

		local fadeInfo = TweenInfo.new(
			self.Config.OpenDuration * 0.7,
			Enum.EasingStyle.Quad,
			Enum.EasingDirection.Out
		)

		local tPos = TweenService:Create(panel, openInfo, { Position = targetPos })
		table.insert(self.ActiveTweens, tPos)
		tPos:Play()

		if self.UIScale then
			local tScale = TweenService:Create(self.UIScale, openInfo, { Scale = self.Config.ScaleEnd or 1.0 })
			table.insert(self.ActiveTweens, tScale)
			tScale:Play()
		end

		if self.IsCanvasGroup then
			local tFade = TweenService:Create(panel, fadeInfo, { GroupTransparency = 0 })
			table.insert(self.ActiveTweens, tFade)
			tFade:Play()
		end

		if self.Stroke then
			local tStroke = TweenService:Create(self.Stroke, fadeInfo, { Transparency = 0 })
			table.insert(self.ActiveTweens, tStroke)
			tStroke:Play()
		end

		tPos.Completed:Connect(function(status)
			if self._token == myToken and self.CurrentState == PanelAnimationController.State.Opening then
				self:_SetState(PanelAnimationController.State.Open)
			end
		end)
	else
		local fullSize = self.TargetSize or panel.Size
		if targetHeight then
			fullSize = UDim2.new(fullSize.X.Scale, fullSize.X.Offset, 0, targetHeight)
		end

		local collapsedHeight = self.Config.CollapsedHeight or 44
		local collapsedSize = UDim2.new(fullSize.X.Scale, fullSize.X.Offset, 0, collapsedHeight)

		if wasClosed then
			panel.Size = collapsedSize
			if self.IsCanvasGroup then
				panel.GroupTransparency = 1
			end
		end

		local targetProps = {
			Size = fullSize,
		}
		if self.IsCanvasGroup then
			targetProps.GroupTransparency = 0
		end

		local openTween = TweenService:Create(panel, openInfo, targetProps)
		table.insert(self.ActiveTweens, openTween)

		openTween.Completed:Connect(function(status)
			if self._token == myToken and self.CurrentState == PanelAnimationController.State.Opening then
				self:_SetState(PanelAnimationController.State.Open)
			end
		end)

		openTween:Play()
	end
end

function PanelAnimationController:Close()
	if self.CurrentState == PanelAnimationController.State.Closed or self.CurrentState == PanelAnimationController.State.Closing then
		return
	end

	local panel = self.Panel
	if not panel then return end

	self:_CancelTweens()
	local myToken = self._token
	self:_SetState(PanelAnimationController.State.Closing)

	local mode = self.Config.Mode or "Size"
	local closeInfo = TweenInfo.new(
		self.Config.CloseDuration,
		self.Config.CloseEasingStyle,
		self.Config.CloseEasingDirection
	)

	if mode == "CanvasGroup" then
		local currentPos = panel.Position
		local targetPos = UDim2.new(
			currentPos.X.Scale,
			currentPos.X.Offset,
			currentPos.Y.Scale,
			currentPos.Y.Offset - (self.Config.SlideOffsetY or 20)
		)

		local tPos = TweenService:Create(panel, closeInfo, { Position = targetPos })
		table.insert(self.ActiveTweens, tPos)
		tPos:Play()

		if self.UIScale then
			local tScale = TweenService:Create(self.UIScale, closeInfo, { Scale = self.Config.ScaleStart or 0.9 })
			table.insert(self.ActiveTweens, tScale)
			tScale:Play()
		end

		if self.IsCanvasGroup then
			local tFade = TweenService:Create(panel, closeInfo, { GroupTransparency = 1 })
			table.insert(self.ActiveTweens, tFade)
			tFade:Play()
		end

		if self.Stroke then
			local tStroke = TweenService:Create(self.Stroke, closeInfo, { Transparency = 1 })
			table.insert(self.ActiveTweens, tStroke)
			tStroke:Play()
		end

		tPos.Completed:Connect(function(status)
			if self._token == myToken and self.CurrentState == PanelAnimationController.State.Closing then
				panel.Visible = false
				if self.Container then
					self.Container.Visible = false
				end
				if self.UIScale then
					self.UIScale.Scale = self.Config.ScaleEnd or 1.0
				end
				if self.IsCanvasGroup then
					panel.GroupTransparency = 0
				end
				if self.Stroke then
					self.Stroke.Transparency = 0
				end
				if self.Config.GetResetPosition then
					local ok, resX, resY = pcall(self.Config.GetResetPosition)
					if ok and typeof(resX) == "UDim2" then
						panel.Position = resX
					elseif ok and typeof(resX) == "number" and typeof(resY) == "number" then
						panel.Position = UDim2.new(0.5, resX, 0.5, resY)
					end
				elseif self.TargetPosition then
					panel.Position = self.TargetPosition
				end
				self:_SetState(PanelAnimationController.State.Closed)
			end
		end)
	else
		local collapsedHeight = self.Config.CollapsedHeight or 44
		local collapsedSize = UDim2.new(panel.Size.X.Scale, panel.Size.X.Offset, 0, collapsedHeight)

		local targetProps = {
			Size = collapsedSize,
		}
		if self.IsCanvasGroup then
			targetProps.GroupTransparency = 1
		end

		local closeTween = TweenService:Create(panel, closeInfo, targetProps)
		table.insert(self.ActiveTweens, closeTween)

		closeTween.Completed:Connect(function(status)
			if self._token == myToken and self.CurrentState == PanelAnimationController.State.Closing then
				panel.Visible = false
				if self.Container then
					self.Container.Visible = false
				end
				self:_SetState(PanelAnimationController.State.Closed)
			end
		end)

		closeTween:Play()
	end
end

function PanelAnimationController:ForceClose()
	self:_CancelTweens()
	local panel = self.Panel
	if self.Container then
		self.Container.Visible = false
	end
	if panel then
		panel.Visible = false
		if self.IsCanvasGroup then
			panel.GroupTransparency = 0
		end
		if self.Stroke then
			self.Stroke.Transparency = 0
		end
		if self.UIScale then
			self.UIScale.Scale = self.Config.ScaleEnd or 1.0
		end
		if self.Config.GetResetPosition then
			local ok, resX, resY = pcall(self.Config.GetResetPosition)
			if ok and typeof(resX) == "UDim2" then
				panel.Position = resX
			elseif ok and typeof(resX) == "number" and typeof(resY) == "number" then
				panel.Position = UDim2.new(0.5, resX, 0.5, resY)
			end
		elseif self.TargetPosition then
			panel.Position = self.TargetPosition
		end
	end
	self:_SetState(PanelAnimationController.State.Closed)
	if self.Icon and self.Icon.isSelected then
		pcall(function()
			self._syncingIcon = true
			self.Icon:deselect()
			self._syncingIcon = false
		end)
	end
end

function PanelAnimationController:Toggle(targetHeight)
	if self:IsOpen() then
		self:Close()
	else
		self:Open(targetHeight)
	end
end

function PanelAnimationController:BindTopbarIcon(icon)
	if not icon then return end
	self.Icon = icon

	icon.selected:Connect(function()
		if self._syncingIcon then return end
		self._syncingIcon = true
		self:Open()
		self._syncingIcon = false
	end)

	icon.deselected:Connect(function()
		if self._syncingIcon then return end
		self._syncingIcon = true
		self:Close()
		self._syncingIcon = false
	end)

	self.OnStateChanged.Event:Connect(function(newState)
		if self._syncingIcon or not self.Icon then return end
		self._syncingIcon = true
		if newState == PanelAnimationController.State.Open then
			if not self.Icon.isSelected then
				pcall(function() self.Icon:select() end)
			end
		elseif newState == PanelAnimationController.State.Closed then
			if self.Icon.isSelected then
				pcall(function() self.Icon:deselect() end)
			end
		end
		self._syncingIcon = false
	end)
end

function PanelAnimationController:Destroy()
	self:_CancelTweens()
	if self.OnStateChanged then
		self.OnStateChanged:Destroy()
		self.OnStateChanged = nil
	end
	self.Panel = nil
	self.Container = nil
	self.UIScale = nil
	self.Stroke = nil
	self.Icon = nil
end

return PanelAnimationController
