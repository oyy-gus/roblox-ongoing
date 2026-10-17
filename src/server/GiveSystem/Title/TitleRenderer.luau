local TitleRenderer = {}
local ConfigData = require(script.Parent.ConfigData)

local animThreads = {}

local function cancelAnims(userId)
	if animThreads[userId] then
		for _, thread in pairs(animThreads[userId]) do
			task.cancel(thread)
		end
	end
	animThreads[userId] = {}
end

local function getCustomFrame(character)
	local head = character:FindFirstChild("Head")
	if not head then return nil end

	for _, child in ipairs(head:GetChildren()) do
		if child:IsA("BillboardGui") then
			local canvas = child:FindFirstChild("Canvas")
			if canvas then
				local custom = canvas:FindFirstChild("Custom")
				if custom then return custom end
			end
		end
	end

	return nil
end

function TitleRenderer:ClearTitles(character, userId)
	local customFrame = getCustomFrame(character)
	if not customFrame then return end

	cancelAnims(userId or 0)

	for i = 1, 14 do
		local label = customFrame:FindFirstChild("TitleLabel" .. i)
		if label then
			for _, child in ipairs(label:GetChildren()) do
				if child:IsA("UIGradient") then child:Destroy() end
			end
			label.Text = ""
			label.Visible = false
			label.TextColor3 = Color3.new(1, 1, 1)
		end
	end
end

local function applyColorMode(label, mode, colorTemplate, userId, slot)
	mode = tostring(mode or "fixed"):lower()

	for _, child in ipairs(label:GetChildren()) do
		if child:IsA("UIGradient") then child:Destroy() end
	end

	if mode == "fixed" then
		label.TextColor3 = ConfigData.getColorByName(colorTemplate)

	elseif mode == "rgb" then
		label.TextColor3 = Color3.new(1, 1, 1)
		local thread = task.spawn(function()
			local t0 = tick()
			while label and label.Parent do
				label.TextColor3 = Color3.fromHSV(((tick() - t0) % 6) / 6, 1, 1)
				task.wait(0.08)
			end
		end)
		animThreads[userId] = animThreads[userId] or {}
		animThreads[userId][slot] = thread

	elseif mode == "rainbow" or mode == "gradient" or mode == "twotone" then
		label.TextColor3 = Color3.new(1, 1, 1)

		local grad = Instance.new("UIGradient")
		local colors = ConfigData.ColorTemplates[colorTemplate] or ConfigData.ColorTemplates.Sunset
		local keypoints = {}
		for i, color in ipairs(colors) do
			local pos = (i - 1) / math.max(#colors - 1, 1)
			table.insert(keypoints, ColorSequenceKeypoint.new(pos, color))
		end
		grad.Color = ColorSequence.new(keypoints)
		grad.Parent = label

		local thread
		if mode == "rainbow" then
			thread = task.spawn(function()
				local t = 0
				while grad and grad.Parent do
					t += 0.04
					grad.Rotation = 90 + math.sin(t * 1.2) * 135
					task.wait(0.03)
				end
			end)
		elseif mode == "gradient" then
			thread = task.spawn(function()
				local t = 0
				while grad and grad.Parent do
					t += 0.05
					grad.Rotation = 90 + math.sin(t * 2) * 60 + math.cos(t * 1.5) * 40
					task.wait(0.03)
				end
			end)
		elseif mode == "twotone" then
			grad.Rotation = 0
			thread = task.spawn(function()
				local t = 0
				while grad and grad.Parent do
					t += 0.02
					grad.Offset = Vector2.new((math.sin(t * 1.5) + 1) / 2 * 2 - 1, 0)
					task.wait(0.03)
				end
			end)
		end

		animThreads[userId] = animThreads[userId] or {}
		animThreads[userId][slot] = thread
	end
end

function TitleRenderer:RenderAllTitles(player, character, titles)
	if not character then return end

	local userId = player.UserId
	local customFrame = getCustomFrame(character)
	if not customFrame then
		warn("[TitleRenderer] Canvas > Custom tidak ditemukan untuk:", player.Name)
		return
	end

	cancelAnims(userId)

	for i = 1, 14 do
		local label = customFrame:FindFirstChild("TitleLabel" .. i)
		if not label then continue end

		for _, child in ipairs(label:GetChildren()) do
			if child:IsA("UIGradient") then child:Destroy() end
		end
		label.TextColor3 = Color3.new(1, 1, 1)

		local titleData = titles[i]
		if titleData and titleData.Text and titleData.Text ~= "" then
			label.Text    = titleData.Text:gsub("\\n", "\n")
			label.Font    = ConfigData.getFontByName(titleData.Font)
			label.Visible = true
			applyColorMode(label, titleData.Mode, titleData.ColorTemplate, userId, i)
		else
			label.Text    = ""
			label.Visible = false
		end
	end
end

function TitleRenderer:OnPlayerRemoving(userId)
	cancelAnims(userId)
	animThreads[userId] = nil
end

return TitleRenderer
