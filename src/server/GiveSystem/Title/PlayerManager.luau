local Players = game:GetService("Players")

local PlayerManager = {}
local PlayerLastCharacter = {}

function PlayerManager:SetupPlayerMonitoring(player, dataStoreModule, titleRenderer)

	player.CharacterAdded:Connect(function(char)
		task.wait(0.8)
		local titles = dataStoreModule:LoadTitlesForUserId(player.UserId) or {}
		titleRenderer:RenderAllTitles(player, char, titles)
	end)

	workspace.DescendantAdded:Connect(function(descendant)
		if descendant.Name == "Head" and descendant.Parent then
			local char = descendant.Parent
			if char:IsA("Model") and Players:GetPlayerFromCharacter(char) == player then
				task.wait(0.3)
				local titles = dataStoreModule:LoadTitlesForUserId(player.UserId) or {}
				titleRenderer:RenderAllTitles(player, char, titles)
			end
		end
	end)

	task.spawn(function()
		while player.Parent do
			task.wait(2)
			local char = player.Character
			if char and char:FindFirstChild("Head") then

				local titles = dataStoreModule:LoadTitlesForUserId(player.UserId) or {}
				local shouldHaveTitles = false
				for i = 1, 14 do
					if titles[i] and titles[i].Text and titles[i].Text ~= "" then
						shouldHaveTitles = true
						break
					end
				end

				if shouldHaveTitles then

					local head = char:FindFirstChild("Head")
					local hasOverhead = false
					if head then
						for _, child in ipairs(head:GetChildren()) do
							if child:IsA("BillboardGui") then
								local canvas = child:FindFirstChild("Canvas")
								if canvas and canvas:FindFirstChild("Custom") then
									hasOverhead = true
									break
								end
							end
						end
					end

					if hasOverhead then

						local head2 = char:FindFirstChild("Head")
						local customFrame = nil
						if head2 then
							for _, child in ipairs(head2:GetChildren()) do
								if child:IsA("BillboardGui") then
									local canvas = child:FindFirstChild("Canvas")
									if canvas then
										customFrame = canvas:FindFirstChild("Custom")
										if customFrame then break end
									end
								end
							end
						end

						if customFrame then
							local needsRestore = false
							for i = 1, 14 do
								if titles[i] and titles[i].Text and titles[i].Text ~= "" then
									local label = customFrame:FindFirstChild("TitleLabel" .. i)
									if label and not label.Visible then
										needsRestore = true
										break
									end
								end
							end
							if needsRestore then
								titleRenderer:RenderAllTitles(player, char, titles)
							end
						end
					end
				end
			end
		end
	end)
end

function PlayerManager:OnPlayerRemoving(player)
	PlayerLastCharacter[player.UserId] = nil
end

function PlayerManager:ResolveUserIdByName(username)
	if not username or username == "" then return nil end
	local ok, id = pcall(function()
		return Players:GetUserIdFromNameAsync(username)
	end)
	if ok and id then return id end
	return nil
end

function PlayerManager:GetPlayerList()
	local list = {}
	for _, p in ipairs(Players:GetPlayers()) do
		table.insert(list, p.Name)
	end
	return list
end

return PlayerManager
