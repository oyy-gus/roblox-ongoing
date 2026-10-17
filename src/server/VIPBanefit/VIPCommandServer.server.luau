local ServerStorage      = game:GetService("ServerStorage")
local Players            = game:GetService("Players")
local ReplicatedStorage  = game:GetService("ReplicatedStorage")
local InsertService      = game:GetService("InsertService")
local MarketplaceService = game:GetService("MarketplaceService")

local RoleSystem = require(ServerStorage.Modules.RoleSystem)

local Config = {
	DebugMode          = true,
	RequiredRole       = "VIP",
	IncludeHigherRoles = true,

	TagPrefix        = "VIPHat_",
	MaxEquipped      = 10,
	MaxHatPerCommand = 5,

	SizeMin = 0.3,
	SizeMax = 1.0,

	RoleCheckDelay   = 1,
	ShowIconRetries  = 3,
	ShowIconRetryGap = 0.5,
}

local RefreshOverheadEvent = ServerStorage:FindFirstChild("RefreshOverheadEvent")
if not RefreshOverheadEvent then
	RefreshOverheadEvent = Instance.new("BindableEvent")
	RefreshOverheadEvent.Name   = "RefreshOverheadEvent"
	RefreshOverheadEvent.Parent = ServerStorage
end

local Folder = ReplicatedStorage:FindFirstChild("VIPRemotes") or Instance.new("Folder")
Folder.Name   = "VIPRemotes"
Folder.Parent = ReplicatedStorage

local function remote(cls, name)
	local r = Folder:FindFirstChild(name) or Instance.new(cls)
	r.Name   = name
	r.Parent = Folder
	return r
end

local RE = {
	ShowIcon    = remote("RemoteEvent",    "ShowIcon"),
	RequestIcon = remote("RemoteEvent",    "RequestIcon"),
	ResetAvatar = remote("RemoteEvent",    "ResetAvatar"),
	HatTryOn    = remote("RemoteEvent",    "HatTryOn"),
	HatInfo     = remote("RemoteFunction", "HatInfo"),
	SetSize     = remote("RemoteEvent",    "SetSize"),
	Result      = remote("RemoteEvent",    "Result"),
	SyncData    = remote("RemoteEvent",    "SyncData"),
}

local function log(msg, ok)
	if not Config.DebugMode then return end
	print((ok and "🟢 [✓]" or "🔴 [✗]") .. " [VIPCmd] " .. msg)
end

local function hasAccess(player)
	local role = RoleSystem:GetPlayerRole(player)
	if Config.IncludeHigherRoles then
		local lv  = RoleSystem.Config.RoleHierarchy[role] or 0
		local req = RoleSystem.Config.RoleHierarchy[Config.RequiredRole] or 0
		return lv >= req, role
	end
	return role == Config.RequiredRole, role
end

local PlayerData = {}

local function getData(player)
	if not PlayerData[player.UserId] then
		PlayerData[player.UserId] = {
			equipped    = {},
			currentSize = 1.0,
		}
	end
	return PlayerData[player.UserId]
end

local InfoCache = {}

local function getItemInfo(assetId)
	if InfoCache[assetId] then return InfoCache[assetId] end
	local ok, info = pcall(function()
		return MarketplaceService:GetProductInfo(assetId, Enum.InfoType.Asset)
	end)
	if ok and info then
		local typeNames = {
			[8]="Topi",[41]="Aksesori Rambut",[42]="Aksesori Wajah",
			[43]="Aksesori Leher",[44]="Aksesori Pundak",[45]="Aksesori Depan",
			[46]="Aksesori Belakang",[47]="Aksesori Pinggang",[17]="Kepala",[18]="Wajah",
			[27]="Badan",[11]="Baju",[12]="Celana",[2]="Kaos",
		}
		local result = {
			name     = info.Name or ("Item "..assetId),
			assetType= info.AssetTypeId or 0,
			creator  = (info.Creator and info.Creator.Name) or "Tidak Diketahui",
			typeName = typeNames[info.AssetTypeId] or ("Tipe "..tostring(info.AssetTypeId)),
		}
		InfoCache[assetId] = result
		return result
	end
	return { name="Item Tidak Diketahui", assetType=0, creator="Tidak Diketahui", typeName="Tidak Diketahui" }
end

local function syncClient(player)
	local d = getData(player)
	RE.SyncData:FireClient(player, {
		equipped    = d.equipped,
		currentSize = d.currentSize,
	})
end

local function applySize(hum, sizeVal)
	hum.BodyDepthScale.Value  = sizeVal
	hum.BodyHeightScale.Value = sizeVal
	hum.BodyWidthScale.Value  = sizeVal
	hum.HeadScale.Value       = sizeVal
end

local function showIconForPlayer(player, shouldShow)
	RE.ShowIcon:FireClient(player, shouldShow)
	log(player.Name .. " icon=" .. tostring(shouldShow) .. " (attempt 1)", shouldShow)
	if shouldShow then
		task.spawn(function()
			for i = 2, Config.ShowIconRetries do
				task.wait(Config.ShowIconRetryGap)
				if not player.Parent then return end
				RE.ShowIcon:FireClient(player, shouldShow)
				log(player.Name .. " icon=" .. tostring(shouldShow) .. " (retry " .. i .. ")", shouldShow)
			end
		end)
	end
end

local function cmdReset(player)
	local char = player.Character
	if not char then return false, "Karakter tidak ditemukan" end

	local humanoid = char:FindFirstChildOfClass("Humanoid")
	local root     = char:FindFirstChild("HumanoidRootPart")
	if not humanoid or not root then return false, "Humanoid/HumanoidRootPart tidak ditemukan" end

	local lastCFrame = root.CFrame
	local lastHealth = humanoid.Health

	local success, desc = pcall(function()
		return Players:GetHumanoidDescriptionFromUserId(player.UserId)
	end)
	if not success or not desc then
		return false, "Gagal mengambil deskripsi avatar"
	end

	root.Anchored = true
	humanoid:ApplyDescription(desc)
	task.wait()

	root.CFrame     = lastCFrame
	humanoid.Health = lastHealth
	root.Anchored   = false

	local d = getData(player)
	d.equipped    = {}
	d.currentSize = 1.0
	syncClient(player)

	task.wait(0.1)
	RefreshOverheadEvent:Fire(player)

	log(player.Name .. " /re done (avatar + hat reset)", true)
	return true, "Avatar & aksesoris direset ke tampilan asli!"
end

local function cmdHatTryOnSingle(player, assetId)
	local d    = getData(player)
	local char = player.Character
	if not char then return false, "Karakter tidak ditemukan, coba lagi" end

	local tag = Config.TagPrefix .. tostring(assetId)

	if d.equipped[tag] then
		local item = char:FindFirstChild(tag)
		if item then pcall(function() item:Destroy() end) end
		d.equipped[tag] = nil
		local info = getItemInfo(assetId)
		log(player.Name.." hat off: "..info.name.." ("..assetId..")", true)
		return true, "🗑️ Lepas: "..info.name
	end

	local count = 0
	for _ in pairs(d.equipped) do count = count + 1 end
	if count >= Config.MaxEquipped then
		return false, "Maks "..Config.MaxEquipped.." item. Gunakan /re untuk reset semua"
	end

	local info = getItemInfo(assetId)

	local ok, result = pcall(function()
		return InsertService:LoadAsset(assetId)
	end)
	if not ok then
		log("LoadAsset failed id="..assetId..": "..tostring(result), false)
		return false, "Gagal load item "..assetId..". Pastikan ID valid"
	end

	local model = result
	local item
	for _, child in ipairs(model:GetDescendants()) do
		if child:IsA("Accessory") or child:IsA("Shirt")
			or child:IsA("Pants") or child:IsA("ShirtGraphic") then
			item = child; break
		end
	end

	if not item then
		model:Destroy()
		return false, "Item "..assetId.." tidak kompatibel (bukan aksesoris/pakaian)"
	end

	item.Name   = tag
	item.Parent = char
	model:Destroy()

	d.equipped[tag] = assetId

	log(player.Name.." hat on: "..info.name.." ("..assetId..")", true)
	return true, "✅ Pakai: "..info.name.." ["..info.typeName.."]"
end

local function cmdHatTryOn(player, ids)
	if type(ids) == "number" then ids = { ids } end

	local limited = {}
	for i = 1, math.min(#ids, Config.MaxHatPerCommand) do
		table.insert(limited, ids[i])
	end

	local results    = {}
	local anySuccess = false

	for _, assetId in ipairs(limited) do
		local ok, msg = cmdHatTryOnSingle(player, assetId)
		if ok then anySuccess = true end
		table.insert(results, msg)
	end

	syncClient(player)

	if #results == 1 then
		return anySuccess, results[1]
	end

	local successCount = 0
	for _, msg in ipairs(results) do
		if msg:find("✅") or msg:find("🗑️") then successCount = successCount + 1 end
	end

	if not anySuccess then
		return false, "❌ Semua item gagal dimuat"
	end
	return true, string.format("🎩 %d/%d item diproses", successCount, #results)
end

local function cmdSize(player, sizeVal)
	sizeVal = math.clamp(sizeVal, Config.SizeMin, Config.SizeMax)

	local char = player.Character
	if not char then return false, "Karakter tidak ditemukan" end

	local hum = char:FindFirstChildWhichIsA("Humanoid")
	if not hum then return false, "Humanoid tidak ditemukan" end

	applySize(hum, sizeVal)
	getData(player).currentSize = sizeVal
	syncClient(player)
	log(player.Name.." size set to "..sizeVal, true)

	if sizeVal == 1.0 then
		return true, "Ukuran dikembalikan ke normal (1.0)"
	end
	return true, string.format("Ukuran diubah ke %.2fx", sizeVal)
end

local function parseChat(player, message)
	local ok, _ = hasAccess(player)
	if not ok then return end

	message = message:lower():match("^%s*(.-)%s*$")

	if message == "/re" then
		local success, msg = cmdReset(player)
		RE.Result:FireClient(player, success, msg)
		return
	end

	local hatArgs = message:match("^/hat%s+(.+)$")
	if hatArgs then
		local ids = {}
		for idStr in hatArgs:gmatch("%d+") do
			local num = tonumber(idStr)
			if num then
				table.insert(ids, num)
				if #ids >= Config.MaxHatPerCommand then break end
			end
		end

		if #ids == 0 then
			RE.Result:FireClient(player, false, "Format: /hat id1 id2 ... (maks "..Config.MaxHatPerCommand..")")
			return
		end

		local success, msg = cmdHatTryOn(player, ids)
		RE.Result:FireClient(player, success, msg)
		return
	end

	local sizeStr = message:match("^/size%s+([%d%.]+)$")
	if sizeStr then
		local sizeVal = tonumber(sizeStr)
		if not sizeVal then
			RE.Result:FireClient(player, false, "Format salah. Contoh: /size 0.5")
			return
		end
		local success, msg = cmdSize(player, sizeVal)
		RE.Result:FireClient(player, success, msg)
		return
	end
end

RE.ResetAvatar.OnServerEvent:Connect(function(player)
	if not hasAccess(player) then return end
	local ok, msg = cmdReset(player)
	RE.Result:FireClient(player, ok, msg)
end)

RE.HatTryOn.OnServerEvent:Connect(function(player, payload)
	if not hasAccess(player) then return end

	local ids = {}
	if typeof(payload) == "number" then
		ids = { payload }
	elseif typeof(payload) == "table" then
		for _, v in ipairs(payload) do
			if typeof(v) == "number" then
				table.insert(ids, v)
				if #ids >= Config.MaxHatPerCommand then break end
			end
		end
	else
		return
	end

	if #ids == 0 then return end
	local ok, msg = cmdHatTryOn(player, ids)
	RE.Result:FireClient(player, ok, msg)
end)

RE.HatInfo.OnServerInvoke = function(player, assetId)
	if not hasAccess(player) then return nil end
	if typeof(assetId) ~= "number" then return nil end
	return getItemInfo(assetId)
end

RE.SetSize.OnServerEvent:Connect(function(player, sizeVal)
	if not hasAccess(player) then return end
	if typeof(sizeVal) ~= "number" then return end
	local ok, msg = cmdSize(player, sizeVal)
	RE.Result:FireClient(player, ok, msg)
end)

RE.RequestIcon.OnServerEvent:Connect(function(player)
	local ok, _ = hasAccess(player)
	RE.ShowIcon:FireClient(player, ok)
	log(player.Name .. " requested icon state → " .. tostring(ok), ok)
end)

local function onCharacterAdded(character, player)
	local d = getData(player)
	d.equipped    = {}
	d.currentSize = 1.0
	syncClient(player)

	local ok, _ = hasAccess(player)
	showIconForPlayer(player, ok)
end

local function onPlayerAdded(player)
	task.wait(Config.RoleCheckDelay)

	local ok, role = hasAccess(player)
	showIconForPlayer(player, ok)

	if ok then
		log(player.Name.." ("..role..") → icon shown", true)
	else
		log(player.Name.." ("..role..") → no access", false)
	end

	if player.Character then
		onCharacterAdded(player.Character, player)
	end

	player.CharacterAdded:Connect(function(char)
		onCharacterAdded(char, player)
	end)

	player.Chatted:Connect(function(message)
		parseChat(player, message)
	end)
end

for _, player in ipairs(Players:GetPlayers()) do
	task.spawn(onPlayerAdded, player)
end

Players.PlayerAdded:Connect(onPlayerAdded)

Players.PlayerRemoving:Connect(function(player)
	PlayerData[player.UserId] = nil
end)

RoleSystem.RoleChanged:Connect(function(player, oldRole, newRole)
	local ok, _ = hasAccess(player)
	showIconForPlayer(player, ok)
	if not ok then
		if player.Character then
			cmdReset(player)
		end
	end
	log(player.Name.." role: "..oldRole.." → "..newRole.." | access:"..tostring(ok), ok)
end)

log("VIPCommandServer loaded | Role: "..Config.RequiredRole, true)
