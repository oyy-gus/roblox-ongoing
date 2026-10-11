-- Services
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Config
local CarryConfig = require(ReplicatedStorage:WaitForChild("ContextModule"):WaitForChild("CarryConfig"))

-- Remotes Setup
local remoteFolder = ReplicatedStorage:FindFirstChild(CarryConfig.REMOTE_FOLDER)
if not remoteFolder then
	remoteFolder = Instance.new("Folder")
	remoteFolder.Name = CarryConfig.REMOTE_FOLDER
	remoteFolder.Parent = ReplicatedStorage
end

local function createRemote(name)
	local remote = remoteFolder:FindFirstChild(name)
	if not remote then
		remote = Instance.new("RemoteEvent")
		remote.Name = name
		remote.Parent = remoteFolder
	end
	return remote
end

local RequestRemote = createRemote("CarryRequest")
local ResponseRemote = createRemote("CarryResponse")
local EndRemote = createRemote("CarryEnd")

-- ============================================
-- STATE MANAGEMENT
-- ============================================

local pendingRequests = {} -- [targetUserId] = {carrier, style, time}
local activeCarries = {} -- [carrierId] = targetId, [targetId] = carrierId (bidirectional mapping)

-- ============================================
-- UTILITY FUNCTIONS
-- ============================================

local function getCharHRP(p)
	if not p or not p.Character then return nil end
	local hrp = p.Character:FindFirstChild("HumanoidRootPart")
	local hum = p.Character:FindFirstChildOfClass("Humanoid")
	if not hrp or not hum then return nil end
	return p.Character, hrp, hum
end

local function getRigType(character)
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if humanoid then
		return humanoid.RigType == Enum.HumanoidRigType.R15 and "R15" or "R6"
	end
	return "R15"
end

local function getAttachmentPart(character)
	local rigType = getRigType(character)

	if rigType == "R15" then
		-- R15: Gunakan UpperTorso karena ini yang bergerak saat animasi
		return character:FindFirstChild("UpperTorso") or character:FindFirstChild("HumanoidRootPart")
	else
		-- R6: Gunakan Torso
		return character:FindFirstChild("Torso") or character:FindFirstChild("HumanoidRootPart")
	end
end

local function isCarrying(character)
	if not character then return false end
	local carryable = character:FindFirstChild("Carryable")
	return carryable and carryable.Value == false
end

local function canAskCarry(player)
	local canAsk = player:FindFirstChild("CanAskCarry")
	return canAsk and canAsk.Value == true
end

-- ============================================
-- WELD MANAGEMENT (FIXED)
-- ============================================

local function clearCarryWeld(char)
	if not char then return end

	for _, desc in ipairs(char:GetDescendants()) do
		if desc:IsA("Weld") or desc:IsA("WeldConstraint") or desc:IsA("Motor6D") then
			if desc.Name == "CarryWeld" or desc.Name:find("Carry") then
				desc:Destroy()
			end
		end
	end
end

local function createCarryWeld(carrierChar, targetChar, offset)
	-- Dapatkan part yang tepat untuk attachment
	local carrierPart = getAttachmentPart(carrierChar)
	local targetHRP = targetChar:FindFirstChild("HumanoidRootPart")

	if not carrierPart or not targetHRP then
		warn("[CARRY] Failed to get attachment parts")
		return nil
	end

	-- Create weld ke part yang bergerak saat animasi (bukan HRP!)
	local weld = Instance.new("Weld")
	weld.Name = "CarryWeld"
	weld.Part0 = carrierPart  -- UpperTorso/Torso yang bergerak saat emote
	weld.Part1 = targetHRP     -- HRP target

	-- Adjust offset jika perlu
	local rigType = getRigType(carrierChar)
	local adjustedOffset = offset

	-- Untuk R15, UpperTorso posisinya sedikit lebih tinggi dari HRP
	if rigType == "R15" and carrierPart.Name == "UpperTorso" then
		-- Kompensasi perbedaan posisi UpperTorso dengan HRP
		local hrp = carrierChar:FindFirstChild("HumanoidRootPart")
		if hrp then
			local heightDiff = carrierPart.Position.Y - hrp.Position.Y
			adjustedOffset = CFrame.new(0, -heightDiff, 0) * offset
		end
	end

	weld.C0 = adjustedOffset
	weld.C1 = CFrame.new(0, 0, 0)
	weld.Parent = targetHRP

	CarryConfig.debugPrint("WELD", "Weld created:", carrierPart.Name, "->", targetHRP.Name, "RigType:", rigType)
	return weld
end

-- ============================================
-- PHYSICS MANAGEMENT
-- ============================================

local savedPhysics = {}

local function makeCarriedWeightless(char, userId)
	local properties = {}

	for _, part in ipairs(char:GetDescendants()) do
		if part:IsA("BasePart") then
			properties[part] = {
				CanCollide = part.CanCollide,
				Massless = part.Massless
			}

			part.CanCollide = false
			part.Massless = true
		end
	end

	savedPhysics[userId] = properties
	CarryConfig.debugPrint("PHYSICS", "Made weightless for user:", userId)
end

local function restorePhysics(userId)
	local properties = savedPhysics[userId]
	if not properties then return end

	for part, props in pairs(properties) do
		if part and part.Parent then
			part.CanCollide = props.CanCollide
			part.Massless = props.Massless
		end
	end

	savedPhysics[userId] = nil
	CarryConfig.debugPrint("PHYSICS", "Restored for user:", userId)
end

-- ============================================
-- HUMANOID STATE MANAGEMENT
-- ============================================

local savedHumanoidStates = {}

local function saveHumanoidState(userId, hum)
	savedHumanoidStates[userId] = {
		WalkSpeed = hum.WalkSpeed,
		JumpPower = hum.JumpPower,
		JumpHeight = hum.JumpHeight,
		UseJumpPower = hum.UseJumpPower,
		AutoRotate = hum.AutoRotate
	}
end

local function applyCarriedState(hum)
	hum.WalkSpeed = 0
	hum.AutoRotate = false

	if hum.UseJumpPower then
		hum.JumpPower = 0
	else
		hum.JumpHeight = 0
	end

	hum.Sit = true
	hum:SetStateEnabled(Enum.HumanoidStateType.Jumping, false)
	hum:SetStateEnabled(Enum.HumanoidStateType.Climbing, false)
	hum:SetStateEnabled(Enum.HumanoidStateType.Swimming, false)
end

local function restoreHumanoidState(userId, hum)
	local state = savedHumanoidStates[userId]

	if state then
		hum.WalkSpeed = state.WalkSpeed
		hum.AutoRotate = state.AutoRotate

		if state.UseJumpPower then
			hum.JumpPower = state.JumpPower
		else
			hum.JumpHeight = state.JumpHeight
		end

		savedHumanoidStates[userId] = nil
	else
		hum.WalkSpeed = 16
		hum.AutoRotate = true

		if hum.UseJumpPower then
			hum.JumpPower = 50
		else
			hum.JumpHeight = 7.2
		end
	end

	hum.Sit = false
	hum:SetStateEnabled(Enum.HumanoidStateType.Jumping, true)
	hum:SetStateEnabled(Enum.HumanoidStateType.Climbing, true)
	hum:SetStateEnabled(Enum.HumanoidStateType.Swimming, true)
end

-- ============================================
-- START CARRY
-- ============================================

local function startCarry(carrier, target, style)
	CarryConfig.debugPrint("START", carrier.Name, "->", target.Name, "Style:", style)

	if not CarryConfig.isValidStyle(style) then
		return false, "Invalid style"
	end

	local cChar, cHRP, cHum = getCharHRP(carrier)
	local tChar, tHRP, tHum = getCharHRP(target)

	if not (cChar and cHRP and cHum and tChar and tHRP and tHum) then
		return false, "Character not found"
	end

	if (cHRP.Position - tHRP.Position).Magnitude > CarryConfig.MAX_DISTANCE then
		return false, "Too far"
	end

	if isCarrying(cChar) or isCarrying(tChar) then
		return false, "Player busy"
	end

	local success, err = pcall(function()
		-- STEP 1: Make target weightless FIRST
		makeCarriedWeightless(tChar, target.UserId)

		-- STEP 2: Save humanoid state
		saveHumanoidState(target.UserId, tHum)

		-- STEP 3: Apply carried state (disable movement)
		applyCarriedState(tHum)

		-- STEP 4: Get offset
		local offset = CarryConfig.getStyleOffset(style)

		-- STEP 5: Position target initially
		local carrierPart = getAttachmentPart(cChar)
		if carrierPart then
			tHRP.CFrame = carrierPart.CFrame * offset
		else
			tHRP.CFrame = cHRP.CFrame * offset
		end

		-- STEP 6: Create weld (ini yang penting - weld ke part yang bergerak!)
		createCarryWeld(cChar, tChar, offset)

		-- STEP 7: Update BoolValues
		cChar.Carryable.Value = false
		tChar.Carryable.Value = false
		carrier.CanAskCarry.Value = true
		target.CanAskCarry.Value = true

		-- STEP 7.5: Register active carry (bidirectional mapping)
		activeCarries[carrier.UserId] = target.UserId
		activeCarries[target.UserId] = carrier.UserId

		-- STEP 8: Setup cleanup on death
		local cleanupDone = false
		local function cleanup()
			if cleanupDone then return end
			cleanupDone = true

			task.defer(function()
				CarryConfig.debugPrint("CLEANUP", "Starting cleanup")

				-- Clear active carry mapping
				activeCarries[carrier.UserId] = nil
				activeCarries[target.UserId] = nil

				clearCarryWeld(cChar)
				clearCarryWeld(tChar)

				if cChar and cChar:FindFirstChild("Carryable") then
					cChar.Carryable.Value = true
				end
				if tChar and tChar:FindFirstChild("Carryable") then
					tChar.Carryable.Value = true
				end

				if tHum and tHum.Parent then
					restoreHumanoidState(target.UserId, tHum)
				end

				restorePhysics(target.UserId)

				EndRemote:FireClient(carrier, {cmd = "CarryEnded"})
				EndRemote:FireClient(target, {cmd = "CarryEnded"})

				CarryConfig.debugPrint("CLEANUP", "Complete")
			end)
		end

		cHum.Died:Once(cleanup)
		tHum.Died:Once(cleanup)

		cChar.AncestryChanged:Connect(function(_, parent)
			if not parent then cleanup() end
		end)
		tChar.AncestryChanged:Connect(function(_, parent)
			if not parent then cleanup() end
		end)
	end)

	if not success then
		CarryConfig.debugPrint("ERROR", "Start failed:", err)

		if tChar then
			clearCarryWeld(tChar)
			if tChar:FindFirstChild("Carryable") then
				tChar.Carryable.Value = true
			end
		end
		if cChar and cChar:FindFirstChild("Carryable") then
			cChar.Carryable.Value = true
		end

		restorePhysics(target.UserId)

		return false, tostring(err)
	end

	RequestRemote:FireClient(carrier, {
		cmd = "CarryStarted",
		targetId = target.UserId,
		targetName = target.DisplayName,
		style = style
	})

	RequestRemote:FireClient(target, {
		cmd = "BeingCarried",
		carrierId = carrier.UserId,
		carrierName = carrier.DisplayName,
		style = style
	})

	CarryConfig.debugPrint("SUCCESS", "Carry started successfully")
	return true
end

-- ============================================
-- END CARRY (FIXED)
-- ============================================

local function endCarry(player1, player2)
	CarryConfig.debugPrint("END", "Manual end carry between", player1.Name, "and", player2.Name)

	if not player1 or not player2 then return end

	local char1 = player1.Character
	local char2, hrp2, hum2 = getCharHRP(player2)

	if not (char1 and char2) then return end

	-- Only end if actually carrying
	if not isCarrying(char1) and not isCarrying(char2) then
		return
	end

	-- Clear active carry mapping
	activeCarries[player1.UserId] = nil
	activeCarries[player2.UserId] = nil

	clearCarryWeld(char1)
	clearCarryWeld(char2)

	if char1:FindFirstChild("Carryable") then
		char1.Carryable.Value = true
	end
	if char2:FindFirstChild("Carryable") then
		char2.Carryable.Value = true
	end

	-- Restore humanoid for both (in case either was carried)
	if hum2 then
		restoreHumanoidState(player2.UserId, hum2)
	end

	local _, _, hum1 = getCharHRP(player1)
	if hum1 then
		restoreHumanoidState(player1.UserId, hum1)
	end

	-- Restore physics for both
	restorePhysics(player1.UserId)
	restorePhysics(player2.UserId)

	-- Notify both clients
	EndRemote:FireClient(player1, {cmd = "CarryEnded"})
	EndRemote:FireClient(player2, {cmd = "CarryEnded"})

	CarryConfig.debugPrint("CLEANUP", "Manual end complete")
end

-- ============================================
-- PLAYER ADDED FUNCTION
-- ============================================

local function PlayerAddedFunction(plr)
	local CanAskCarry = Instance.new("BoolValue")
	CanAskCarry.Name = "CanAskCarry"
	CanAskCarry.Value = true
	CanAskCarry.Parent = plr

	plr.CharacterAdded:Connect(function(character)
		local Carryable = Instance.new("BoolValue")
		Carryable.Name = "Carryable"
		Carryable.Value = true
		Carryable.Parent = character

		local humanoid = character:WaitForChild("Humanoid")

		humanoid.Died:Connect(function()
			clearCarryWeld(character)
			Carryable.Value = true
			CanAskCarry.Value = true
			restorePhysics(plr.UserId)
		end)
	end)
end

for _, player in ipairs(Players:GetPlayers()) do
	task.spawn(PlayerAddedFunction, player)
end

Players.PlayerAdded:Connect(PlayerAddedFunction)

-- ============================================
-- PENDING REQUESTS TIMEOUT
-- ============================================

task.spawn(function()
	while true do
		task.wait(2)
		local now = os.clock()

		for targetId, data in pairs(pendingRequests) do
			if now - data.time > CarryConfig.REQUEST_TIMEOUT then
				local target = Players:GetPlayerByUserId(targetId)

				if data.carrier and data.carrier.Parent == Players then
					RequestRemote:FireClient(data.carrier, {
						cmd = "RequestExpired"
					})
				end

				if target and target.Parent == Players then
					ResponseRemote:FireClient(target, {
						cmd = "RequestExpired"
					})
					target.CanAskCarry.Value = true
				end

				pendingRequests[targetId] = nil
				CarryConfig.debugPrint("TIMEOUT", "Request expired for:", targetId)
			end
		end
	end
end)

-- ============================================
-- REMOTE HANDLERS
-- ============================================

RequestRemote.OnServerEvent:Connect(function(carrier, data)
	if not data or type(data) ~= "table" then return end

	local cmd = data.cmd

	if cmd == "RequestCarry" then
		local targetId = data.targetId
		local style = data.style

		CarryConfig.debugPrint("REQUEST", carrier.Name, "->", targetId, "Style:", style)

		if not targetId or not style then return end

		if not CarryConfig.isValidStyle(style) then
			RequestRemote:FireClient(carrier, {
				cmd = "RequestFailed",
				reason = "Invalid style"
			})
			return
		end

		local target = Players:GetPlayerByUserId(targetId)
		if not target or target == carrier then
			RequestRemote:FireClient(carrier, {
				cmd = "RequestFailed",
				reason = "Invalid target"
			})
			return
		end

		if not carrier.Character or not target.Character then
			RequestRemote:FireClient(carrier, {
				cmd = "RequestFailed",
				reason = "Character not ready"
			})
			return
		end

		if not canAskCarry(target) or isCarrying(target.Character) or isCarrying(carrier.Character) then
			RequestRemote:FireClient(carrier, {
				cmd = "RequestFailed",
				reason = "Player busy"
			})
			return
		end

		local _, cHRP = getCharHRP(carrier)
		local _, tHRP = getCharHRP(target)
		if not (cHRP and tHRP) then
			RequestRemote:FireClient(carrier, {
				cmd = "RequestFailed",
				reason = "Character not ready"
			})
			return
		end

		if (cHRP.Position - tHRP.Position).Magnitude > CarryConfig.MAX_DISTANCE then
			RequestRemote:FireClient(carrier, {
				cmd = "RequestFailed",
				reason = "Too far"
			})
			return
		end

		if pendingRequests[target.UserId] then
			RequestRemote:FireClient(carrier, {
				cmd = "RequestFailed",
				reason = "Target has pending request"
			})
			return
		end

		target.CanAskCarry.Value = false

		pendingRequests[target.UserId] = {
			carrier = carrier,
			style = style,
			time = os.clock()
		}

		ResponseRemote:FireClient(target, {
			cmd = "ShowRequest",
			carrierId = carrier.UserId,
			carrierName = carrier.DisplayName,
			style = style
		})

		CarryConfig.debugPrint("PENDING", "Request sent to", target.Name)
	end
end)

ResponseRemote.OnServerEvent:Connect(function(target, data)
	if not data or type(data) ~= "table" then return end

	local cmd = data.cmd

	if cmd == "AcceptCarry" then
		local pending = pendingRequests[target.UserId]
		if not pending then return end

		local carrier = pending.carrier
		local style = pending.style

		pendingRequests[target.UserId] = nil

		CarryConfig.debugPrint("ACCEPTED", target.Name, "accepted", carrier.Name)

		local success, err = startCarry(carrier, target, style)

		if not success then
			target.CanAskCarry.Value = true

			RequestRemote:FireClient(carrier, {
				cmd = "RequestFailed",
				reason = err
			})

			ResponseRemote:FireClient(target, {
				cmd = "CarryFailed",
				reason = err
			})
		end

	elseif cmd == "RejectCarry" then
		local pending = pendingRequests[target.UserId]
		if not pending then return end

		local carrier = pending.carrier

		pendingRequests[target.UserId] = nil

		target.CanAskCarry.Value = true

		CarryConfig.debugPrint("REJECTED", target.Name, "rejected", carrier.Name)

		RequestRemote:FireClient(carrier, {
			cmd = "RequestRejected",
			targetName = target.DisplayName
		})
	end
end)

EndRemote.OnServerEvent:Connect(function(player, data)
	CarryConfig.debugPrint("END_REQUEST", player.Name)

	local char = player.Character
	if not char then return end

	-- Check if player is carrying or being carried
	if not isCarrying(char) then return end

	-- Find partner using activeCarries mapping
	local partnerUserId = activeCarries[player.UserId]

	if not partnerUserId then
		CarryConfig.debugPrint("ERROR", "No active carry found for", player.Name)
		return
	end

	local partner = Players:GetPlayerByUserId(partnerUserId)

	if not partner then
		CarryConfig.debugPrint("ERROR", "Partner not found for", player.Name)
		-- Clean up orphaned carry
		activeCarries[player.UserId] = nil
		return
	end

	-- End carry between player and partner
	endCarry(player, partner)
end)

-- ============================================
-- PLAYER EVENTS
-- ============================================

Players.PlayerRemoving:Connect(function(player)
	pendingRequests[player.UserId] = nil

	-- Find and end active carry if exists
	local partnerUserId = activeCarries[player.UserId]
	if partnerUserId then
		local partner = Players:GetPlayerByUserId(partnerUserId)
		if partner then
			endCarry(player, partner)
		else
			-- Clean up orphaned mapping
			activeCarries[player.UserId] = nil
			activeCarries[partnerUserId] = nil
		end
	end

	if player.Character then
		clearCarryWeld(player.Character)
	end

	restorePhysics(player.UserId)
end)

-- ============================================
-- INITIALIZATION
-- ============================================

CarryConfig.debugPrint("SERVER", "Enhanced Carry System Initialized")
