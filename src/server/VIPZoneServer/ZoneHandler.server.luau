-- ====================================
-- MAIN INIT SCRIPT (FIXED - NO CONFLICT)
-- Place in: StarterScriptService > VIPZoneServer(Folder) > ZoneHandler(Script)
-- ====================================
local ServerStorage = game:GetService("ServerStorage")

-- ====================================
-- CONFIGURATION
-- ====================================
local CONFIG = {
	ENABLE_DEBUG = false,
	MODULE_INIT_DELAY = 0.5
}

-- ====================================
-- DEBUG SYSTEM
-- ====================================
local function debugPrint(message, level)
	if not CONFIG.ENABLE_DEBUG then return end
	local prefix = {
		info = "ℹ️",
		success = "✅",
		warning = "⚠️",
		error = "❌"
	}
	print((prefix[level] or "📝") .. " [INIT] " .. message)
end

-- ====================================
-- VIPZONE MODULE
-- ====================================
local function initVIPZoneModule()
	task.wait(CONFIG.MODULE_INIT_DELAY)

	local success, result = pcall(function()
		local VIPZone = require(ServerStorage.Modules.VIPZoneModule)
		return VIPZone
	end)

	if not success then
		debugPrint("Failed to load VIPZone module: " .. tostring(result), "error")
		return
	end

	local initSuccess, initError = pcall(function()
		result.Init()
	end)

	if initSuccess then
		debugPrint("VIPZone module initialized", "success")
	else
		debugPrint("Failed to initialize VIPZone: " .. tostring(initError), "error")
	end
end

-- ====================================
-- MAIN INITIALIZATION
-- ====================================
debugPrint("Starting server initialization...", "info")
initVIPZoneModule()
debugPrint("All systems ready", "success")

-- ========================================
-- BUG REPORT HANDLER (SERVER) - FULLY FIXED
-- Path: ServerScriptService > BugReportHandler
-- ========================================

local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService       = game:GetService("HttpService")

-- ========================================
-- WEBHOOK URL (SERVER-SIDE ONLY - AMAN)
-- ========================================
local WEBHOOK_URL = "https://discord.com/api/webhooks/1493636301478428712/1Ntmruw1a7GlmCzoYLTX46d7viKK8KnQw1qrw40mILWUKUMwLVuCq6w-XSG1drhXB6l1"

-- ========================================
-- LOAD CONFIG
-- ========================================
local Modules         = ReplicatedStorage:WaitForChild("Modules", 30)
if not Modules then
	error("❌ BugReportHandler: Modules folder tidak ditemukan!")
	return
end

local BugReportConfig = require(Modules:WaitForChild("BugReportConfig", 30))
if not BugReportConfig then
	error("❌ BugReportHandler: BugReportConfig tidak bisa di-require!")
	return
end

print("📦 BugReportHandler: Config loaded successfully")

-- ========================================
-- SETUP REMOTE EVENT
-- Buat SEBELUM client load agar client bisa WaitForChild
-- ========================================
local remoteFolder = ReplicatedStorage:FindFirstChild("Remotes")
if not remoteFolder then
	remoteFolder = Instance.new("Folder")
	remoteFolder.Name = "Remotes"
	remoteFolder.Parent = ReplicatedStorage
end

-- Hapus yang lama kalau ada (prevent duplicate)
local existing = remoteFolder:FindFirstChild(BugReportConfig.RemoteName)
if existing then
	existing:Destroy()
end

local bugReportRemote = Instance.new("RemoteEvent")
bugReportRemote.Name = BugReportConfig.RemoteName
bugReportRemote.Parent = remoteFolder

print("📡 BugReportHandler: RemoteEvent '" .. BugReportConfig.RemoteName .. "' created")

-- ========================================
-- RATE LIMIT TRACKER - FIXED
-- ========================================
local playerRateLimits = {}

Players.PlayerRemoving:Connect(function(player)
	playerRateLimits[player.UserId] = nil
end)

local function checkRateLimit(player)
	local userId = player.UserId
	local cfg    = BugReportConfig.RateLimit
	local now    = tick()

	if not playerRateLimits[userId] then
		playerRateLimits[userId] = {
			lastReport = 0,      -- timestamp laporan terakhir
			count      = 0,      -- total laporan sesi ini
		}
	end

	local data = playerRateLimits[userId]

	-- FIX: Cek max per sesi DULU
	if data.count >= cfg.MaxReportsPerSession then
		return false, -1
	end

	-- FIX: Cek cooldown dari LAPORAN TERAKHIR, bukan window
	local elapsed   = now - data.lastReport
	local remaining = math.ceil(cfg.CooldownSeconds - elapsed)

	if data.lastReport > 0 and elapsed < cfg.CooldownSeconds then
		return false, remaining
	end

	-- Lolos semua cek, izinkan
	data.count      = data.count + 1
	data.lastReport = now
	return true, 0
end

-- ========================================
-- HELPER: ESCAPE DISCORD MARKDOWN
-- ========================================
local function escapeMarkdown(text)
	if type(text) ~= "string" then return tostring(text) end
	text = text:gsub("([`*_~>|\\])", "\\%1")
	return text
end

local function truncate(text, maxLen)
	if type(text) ~= "string" then return "" end
	if #text > maxLen then
		return text:sub(1, maxLen - 3) .. "..."
	end
	return text
end

-- ========================================
-- SEVERITY INFO
-- ========================================
local SEVERITY_MAP = {
	low      = { label = "🟢 Rendah",  colorKey = "Low",      emoji = "🟢" },
	medium   = { label = "🟡 Sedang",  colorKey = "Medium",   emoji = "🟡" },
	high     = { label = "🔴 Tinggi",  colorKey = "High",     emoji = "🔴" },
	critical = { label = "🟣 Kritis",  colorKey = "Critical", emoji = "🟣" },
}

local function getSeverityInfo(severityId)
	local info = SEVERITY_MAP[severityId]
	if info then
		local color = BugReportConfig.Webhook.Colors[info.colorKey]
			or BugReportConfig.Webhook.Colors.Medium
		return info.label, color, info.emoji
	end
	return "🟡 Sedang", BugReportConfig.Webhook.Colors.Medium, "🟡"
end

local function getCategoryLabel(categoryId)
	for _, cat in ipairs(BugReportConfig.Categories) do
		if cat.id == categoryId then
			return cat.label
		end
	end
	return "❓ Lainnya"
end

-- ========================================
-- BUILD DISCORD EMBED PAYLOAD
-- ========================================
local function buildDiscordPayload(player, reportData)
	local cfg = BugReportConfig.Webhook
	local severityLabel, embedColor, severityEmoji = getSeverityInfo(reportData.severity)
	local categoryLabel = getCategoryLabel(reportData.category)
	local timestamp = os.date("!%Y-%m-%dT%H:%M:%SZ")

	local playerInfo = string.format(
		"[%s](https://www.roblox.com/users/%d/profile)",
		escapeMarkdown(player.DisplayName),
		player.UserId
	)

	local fields = {
		{
			name   = "👤 Pelapor",
			value  = string.format(
				"%s\n`@%s` | ID: `%d`",
				playerInfo,
				escapeMarkdown(player.Name),
				player.UserId
			),
			inline = true
		},
		{
			name   = "📂 Kategori",
			value  = categoryLabel,
			inline = true
		},
		{
			name   = "⚡ Severity",
			value  = severityLabel,
			inline = true
		},
		{
			name   = "📝 Deskripsi",
			value  = string.format(
				"```\n%s\n```",
				truncate(escapeMarkdown(reportData.description), 900)
			),
			inline = false
		},
	}

	-- Steps (opsional)
	if reportData.steps and type(reportData.steps) == "string" and #reportData.steps > 5 then
		table.insert(fields, {
			name   = "🔁 Langkah Reproduksi",
			value  = string.format(
				"```\n%s\n```",
				truncate(escapeMarkdown(reportData.steps), 490)
			),
			inline = false
		})
	end

	-- Server info
	local jobId = game.JobId ~= "" and game.JobId or "Studio"
	table.insert(fields, {
		name   = "🖥️ Info Server",
		value  = string.format(
			"**Job ID:** `%s`\n**Players:** `%d/%d`\n**Place ID:** `%d`",
			jobId,
			#Players:GetPlayers(),
			Players.MaxPlayers,
			game.PlaceId
		),
		inline = false
	})

	local embed = {
		title = string.format(
			"%s Bug Report — %s",
			severityEmoji,
			truncate(escapeMarkdown(reportData.title), 90)
		),
		description = string.format(
			"> Laporan bug baru diterima dari **%s**",
			escapeMarkdown(player.DisplayName)
		),
		color     = embedColor,
		fields    = fields,
		footer    = {
			text     = string.format(
				"🐛 Bug Reporter System • %s • v1.0",
				os.date("!%d %b %Y %H:%M UTC")
			),
			icon_url = string.format(
				"https://www.roblox.com/headshot-thumbnail/image?userId=%d&width=48&height=48&format=png",
				player.UserId
			)
		},
		timestamp = timestamp,
		thumbnail = {
			url = string.format(
				"https://www.roblox.com/headshot-thumbnail/image?userId=%d&width=150&height=150&format=png",
				player.UserId
			)
		}
	}

	local payload = {
		username   = cfg.BotUsername,
		avatar_url = cfg.AvatarURL,
		embeds     = { embed },
	}

	return HttpService:JSONEncode(payload)
end

-- ========================================
-- SEND TO DISCORD - FULLY FIXED
-- ========================================
local function sendToDiscord(player, reportData)
	-- Validasi webhook URL
	if not WEBHOOK_URL
		or WEBHOOK_URL == ""
		or WEBHOOK_URL:find("YOUR_WEBHOOK") then
		warn("⚠️ BugReportHandler: Webhook URL belum dikonfigurasi!")
		return false, "Webhook belum dikonfigurasi"
	end

	if not WEBHOOK_URL:find("discord%.com/api/webhooks/") then
		warn("⚠️ BugReportHandler: Webhook URL format tidak valid!")
		return false, "Webhook URL tidak valid"
	end

	print(string.format("📤 Membangun payload untuk %s...", player.Name))

	-- Build payload
	local buildOk, jsonPayload = pcall(buildDiscordPayload, player, reportData)
	if not buildOk then
		warn("❌ Gagal build payload: " .. tostring(jsonPayload))
		return false, "Gagal membuat payload"
	end

	print(string.format("📤 Mengirim ke Discord... (payload size: %d bytes)", #jsonPayload))

	-- Kirim HTTP request
	local ok, result = pcall(function()
		return HttpService:RequestAsync({
			Url     = WEBHOOK_URL,
			Method  = "POST",
			Headers = { ["Content-Type"] = "application/json" },
			Body    = jsonPayload
		})
	end)

	if not ok then
		warn(string.format("❌ HTTP request error: %s", tostring(result)))
		-- Cek apakah HttpService disabled
		if tostring(result):find("not enabled") or tostring(result):find("Http requests are not enabled") then
			warn("⚠️ PENTING: Aktifkan HttpService di Game Settings > Security > Allow HTTP Requests!")
		end
		return false, tostring(result)
	end

	-- Cek response
	print(string.format("��� Discord response: Status %d", result.StatusCode or 0))

	if result.StatusCode == 204 or result.StatusCode == 200 then
		print(string.format(
			"✅ Bug report dari %s (@%s) berhasil dikirim!",
			player.DisplayName, player.Name
			))
		return true, nil
	else
		local errMsg = string.format(
			"HTTP %d: %s",
			result.StatusCode or 0,
			truncate(result.Body or "No body", 200)
		)
		warn(string.format("❌ Discord menolak: %s", errMsg))
		return false, errMsg
	end
end

-- ========================================
-- VALIDASI DATA DARI CLIENT
-- ========================================
local function validateReportData(data)
	local val = BugReportConfig.Validation

	if type(data) ~= "table" then
		return false, "Data tidak valid"
	end

	-- Title
	if type(data.title) ~= "string" then
		return false, "Judul tidak valid"
	end
	local titleLen = #data.title
	if titleLen < val.TitleMinLength then
		return false, string.format("Judul terlalu pendek (min %d karakter)", val.TitleMinLength)
	end
	if titleLen > val.TitleMaxLength then
		return false, string.format("Judul terlalu panjang (max %d karakter)", val.TitleMaxLength)
	end

	-- Description
	if type(data.description) ~= "string" then
		return false, "Deskripsi tidak valid"
	end
	local descLen = #data.description
	if descLen < val.DescMinLength then
		return false, string.format("Deskripsi terlalu pendek (min %d karakter)", val.DescMinLength)
	end
	if descLen > val.DescMaxLength then
		return false, string.format("Deskripsi terlalu panjang (max %d karakter)", val.DescMaxLength)
	end

	-- Category
	local validCategory = false
	for _, cat in ipairs(BugReportConfig.Categories) do
		if cat.id == data.category then
			validCategory = true
			break
		end
	end
	if not validCategory then
		return false, "Kategori tidak valid"
	end

	-- Severity
	local validSeverity = false
	for _, sev in ipairs(BugReportConfig.Severities) do
		if sev.id == data.severity then
			validSeverity = true
			break
		end
	end
	if not validSeverity then
		return false, "Severity tidak valid"
	end

	-- Steps (opsional)
	if data.steps and type(data.steps) == "string" then
		if #data.steps > val.StepsMaxLength then
			return false, string.format(
				"Steps terlalu panjang (max %d karakter)",
				val.StepsMaxLength
			)
		end
	end

	return true, nil
end

-- ========================================
-- REMOTE EVENT HANDLER - FIXED
-- ========================================
bugReportRemote.OnServerEvent:Connect(function(player, reportData)
	print("========================================")
	print(string.format("📩 BugReport diterima dari: %s (@%s) [ID: %d]",
		player.DisplayName, player.Name, player.UserId))
	print("========================================")

	-- Debug: print data yang diterima
	if type(reportData) == "table" then
		print("📋 Data diterima:")
		print("  - title:", reportData.title)
		print("  - category:", reportData.category)
		print("  - severity:", reportData.severity)
		print("  - description length:", reportData.description and #reportData.description or "nil")
		print("  - steps length:", reportData.steps and #reportData.steps or "nil/empty")
	else
		warn("⚠️ reportData bukan table! Type:", type(reportData), "Value:", tostring(reportData))
		bugReportRemote:FireClient(player, {
			success = false,
			message = "❌ Data laporan tidak valid."
		})
		return
	end

	-- Rate limit check
	local allowed, waitTime = checkRateLimit(player)
	if not allowed then
		local msg
		if waitTime == -1 then
			msg = "❌ Kamu sudah mencapai batas maksimal laporan untuk sesi ini."
		else
			msg = "⏱️ " .. string.format(BugReportConfig.RateLimit.CooldownMessage, waitTime)
		end
		print("🚫 Rate limited:", msg)
		bugReportRemote:FireClient(player, {
			success = false,
			message = msg
		})
		return
	end

	-- Validasi data
	local valid, validError = validateReportData(reportData)
	if not valid then
		print("🚫 Validasi gagal:", validError)
		bugReportRemote:FireClient(player, {
			success = false,
			message = "❌ " .. validError
		})
		return
	end

	print("✅ Data valid, mengirim ke Discord...")

	-- Kirim ke Discord di thread terpisah
	task.spawn(function()
		local sent, sendError = sendToDiscord(player, reportData)

		-- Pastikan player masih ada di game
		if not player or not player.Parent then
			warn("⚠️ Player sudah leave sebelum response dikirim")
			return
		end

		if sent then
			print("✅ Berhasil! Mengirim response sukses ke client...")
			bugReportRemote:FireClient(player, {
				success = true,
				message = "✅ Laporan bug berhasil dikirim! Terima kasih atas laporanmu."
			})
		else
			print("❌ Gagal! Error:", sendError)
			bugReportRemote:FireClient(player, {
				success = false,
				message = "❌ Gagal mengirim laporan: " .. (sendError or "Unknown error")
			})
		end
	end)
end)

-- ========================================
-- TEST: Verifikasi HttpService
-- ========================================
task.spawn(function()
	local httpOk, httpErr = pcall(function()
		-- Test sederhana untuk cek apakah HTTP enabled
		HttpService:JSONEncode({test = true})
	end)

	if httpOk then
		print("✅ HttpService JSON encoding works")
	else
		warn("❌ HttpService error:", httpErr)
	end

	-- Cek webhook URL
	if WEBHOOK_URL and WEBHOOK_URL:find("discord%.com/api/webhooks/") then
		print("✅ Webhook URL configured")
	else
		warn("⚠️ Webhook URL belum dikonfigurasi!")
	end
end)

local RS = game:GetService("ReplicatedStorage")
local SS = game:GetService("ServerStorage")
local Players = game:GetService("Players")
local Market = game:GetService("MarketplaceService")

local showDonationGUI = RS:FindFirstChild("Remotes"):FindFirstChild("ShowDonationGUI")

showDonationGUI.OnServerEvent:Connect(function(player)
	player:Kick("Exploit Detection: Unauthorized RemoteEvent call")
end)

local DISPLAY_DURATION = 5

local recentPurchases = {}
local processedReceipts = {}
local PURCHASE_COOLDOWN = 5

local PRICE_RANGES = {
	{
		name = "Level 1",
		minPrice = 50,
		maxPrice = 99,
		templatePath = SS.TemplateDonation.Level1
	},
	{
		name = "Level 2",
		minPrice = 100,
		maxPrice = 199,
		templatePath = SS.TemplateDonation.Level2
	},
	{
		name = "Level 3",
		minPrice = 200,
		maxPrice = 9999999,
		templatePath = SS.TemplateDonation.Level3
	},
}

local function getProductPrice(productId)
	local success, result = pcall(function()
		return Market:GetProductInfo(productId, Enum.InfoType.Product)
	end)

	if success and result and result.PriceInRobux then
		return result.PriceInRobux
	end

	return 0
end

local function canProcessPurchase(userId, productId)
	local key = tostring(userId) .. "_" .. tostring(productId) .. "_" .. tostring(tick())

	for existingKey, timestamp in pairs(recentPurchases) do
		if existingKey:match("^" .. tostring(userId) .. "_" .. tostring(productId)) then
			if (tick() - timestamp) < PURCHASE_COOLDOWN then
				return false
			end
		end
	end

	recentPurchases[key] = tick()

	task.delay(PURCHASE_COOLDOWN + 1, function()
		recentPurchases[key] = nil
	end)

	return true
end

local function getPlayerName(userId)
	local player = Players:GetPlayerByUserId(userId)
	if player then
		return player.DisplayName
	end

	local success, username = pcall(function()
		return Players:GetNameFromUserIdAsync(userId)
	end)

	if success and username then
		return username
	end

	return "Player" .. tostring(userId)
end

local function getTemplateByPrice(price)
	for _, range in ipairs(PRICE_RANGES) do
		if price >= range.minPrice and price <= range.maxPrice then
			return range.templatePath, range.name
		end
	end
	return nil, nil
end

local function displayDonationObject(player, template, donationName)
	local character = player.Character
	if not character then return end

	local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
	if not humanoidRootPart then return end

	if not template then return end

	local donationObject = template:Clone()

	if donationObject:IsA("Model") then
		if donationObject.PrimaryPart then
			donationObject:SetPrimaryPartCFrame(humanoidRootPart.CFrame)
		else
			donationObject:Destroy()
			return
		end
	else
		donationObject.CFrame = humanoidRootPart.CFrame
	end

	local weld = Instance.new("WeldConstraint")
	weld.Part0 = humanoidRootPart

	if donationObject:IsA("Model") and donationObject.PrimaryPart then
		weld.Part1 = donationObject.PrimaryPart
	elseif donationObject:IsA("BasePart") then
		weld.Part1 = donationObject
	end

	weld.Parent = donationObject
	donationObject.Parent = workspace

	task.delay(DISPLAY_DURATION, function()
		if donationObject and donationObject.Parent then
			donationObject:Destroy()
		end
	end)
end

local function grantDonationEffect(userId, productId, price)
	if not canProcessPurchase(userId, productId) then
		return false
	end

	local player = Players:GetPlayerByUserId(userId)
	if not player then
		return false
	end

	local template, donationName = getTemplateByPrice(price)

	if not template then
		return false
	end

	local success = pcall(function()
		displayDonationObject(player, template, donationName)
	end)

	if not success then
		return false
	end

	local playerName = getPlayerName(userId)
	showDonationGUI:FireAllClients(playerName, price, donationName)

	return true
end

local function processPurchaseByPrice(userId, productId)
	local price = getProductPrice(productId)

	if price == 0 then
		return false
	end

	return grantDonationEffect(userId, productId, price)
end

Market.ProcessReceipt = function(receipt)
	if not receipt or not receipt.PlayerId or not receipt.ProductId then
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end

	local receiptKey = tostring(receipt.PlayerId) .. "_" .. tostring(receipt.ProductId) .. "_" .. tostring(receipt.PurchaseId or os.time())

	if processedReceipts[receiptKey] then
		return Enum.ProductPurchaseDecision.PurchaseGranted
	end

	processedReceipts[receiptKey] = true

	local userId = receipt.PlayerId
	local productId = receipt.ProductId

	processPurchaseByPrice(userId, productId)

	task.delay(60, function()
		processedReceipts[receiptKey] = nil
	end)

	return Enum.ProductPurchaseDecision.PurchaseGranted
end

Market.PromptProductPurchaseFinished:Connect(function(playerOrUserId, productId, wasPurchased)
	if not wasPurchased then return end

	local userId

	if type(playerOrUserId) == "number" then
		userId = playerOrUserId
	elseif typeof(playerOrUserId) == "Instance" and playerOrUserId:IsA("Player") then
		userId = playerOrUserId.UserId
	else
		return
	end

	task.wait(1)
	processPurchaseByPrice(userId, productId)
end)
