local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")

local WEBHOOK_URL = "https://discord.com/api/webhooks/1493636301478428712/1Ntmruw1a7GlmCzoYLTX46d7viKK8KnQw1qrw40mILWUKUMwLVuCq6w-XSG1drhXB6l1"

local Modules = ReplicatedStorage:WaitForChild("Modules", 30)
if not Modules then
	return
end

local BugReportConfig = require(Modules:WaitForChild("BugReportConfig", 30))
if not BugReportConfig then
	return
end

local remoteFolder = ReplicatedStorage:FindFirstChild("Remotes")
if not remoteFolder then
	remoteFolder = Instance.new("Folder")
	remoteFolder.Name = "Remotes"
	remoteFolder.Parent = ReplicatedStorage
end

local bugReportRemote = remoteFolder:FindFirstChild(BugReportConfig.RemoteName)
if not bugReportRemote then
	bugReportRemote = Instance.new("RemoteEvent")
	bugReportRemote.Name = BugReportConfig.RemoteName
	bugReportRemote.Parent = remoteFolder
end

local playerRateLimits = {}

Players.PlayerRemoving:Connect(function(player)
	playerRateLimits[player.UserId] = nil
end)

local function checkRateLimit(player)
	local userId = player.UserId
	local cfg = BugReportConfig.RateLimit
	local now = tick()

	if not playerRateLimits[userId] then
		playerRateLimits[userId] = {
			lastReport = 0,
			count = 0,
		}
	end

	local data = playerRateLimits[userId]

	if data.count >= cfg.MaxReportsPerSession then
		return false, -1
	end

	local elapsed = now - data.lastReport
	local remaining = math.ceil(cfg.CooldownSeconds - elapsed)

	if data.lastReport > 0 and elapsed < cfg.CooldownSeconds then
		return false, remaining
	end

	data.count = data.count + 1
	data.lastReport = now
	return true, 0
end

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

local SEVERITY_MAP = {
	low = { label = "🟢 Rendah", colorKey = "Low", emoji = "🟢" },
	medium = { label = "🟡 Sedang", colorKey = "Medium", emoji = "🟡" },
	high = { label = "🔴 Tinggi", colorKey = "High", emoji = "🔴" },
	critical = { label = "🟣 Kritis", colorKey = "Critical", emoji = "🟣" },
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
			name = "👤 Pelapor",
			value = string.format(
				"%s\n`@%s` | ID: `%d`",
				playerInfo,
				escapeMarkdown(player.Name),
				player.UserId
			),
			inline = true
		},
		{
			name = "📂 Kategori",
			value = categoryLabel,
			inline = true
		},
		{
			name = "⚡ Severity",
			value = severityLabel,
			inline = true
		},
		{
			name = "📝 Deskripsi",
			value = string.format(
				"```\n%s\n```",
				truncate(escapeMarkdown(reportData.description), 900)
			),
			inline = false
		},
	}

	if reportData.steps and type(reportData.steps) == "string" and #reportData.steps > 5 then
		table.insert(fields, {
			name = "🔁 Langkah Reproduksi",
			value = string.format(
				"```\n%s\n```",
				truncate(escapeMarkdown(reportData.steps), 490)
			),
			inline = false
		})
	end

	local jobId = game.JobId ~= "" and game.JobId or "Studio"
	table.insert(fields, {
		name = "🖥️ Info Server",
		value = string.format(
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
		color = embedColor,
		fields = fields,
		footer = {
			text = string.format(
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
		username = cfg.BotUsername,
		avatar_url = cfg.AvatarURL,
		embeds = { embed },
	}

	return HttpService:JSONEncode(payload)
end

local function sendToDiscord(player, reportData)
	if not WEBHOOK_URL or WEBHOOK_URL == "" or not WEBHOOK_URL:find("discord%.com/api/webhooks/") then
		return false, "Webhook URL tidak valid"
	end

	local buildOk, jsonPayload = pcall(buildDiscordPayload, player, reportData)
	if not buildOk then
		return false, "Gagal membuat payload"
	end

	local ok, result = pcall(function()
		return HttpService:RequestAsync({
			Url = WEBHOOK_URL,
			Method = "POST",
			Headers = { ["Content-Type"] = "application/json" },
			Body = jsonPayload
		})
	end)

	if not ok then
		return false, tostring(result)
	end

	if result.StatusCode == 204 or result.StatusCode == 200 then
		return true, nil
	else
		local errMsg = string.format(
			"HTTP %d: %s",
			result.StatusCode or 0,
			truncate(result.Body or "No body", 200)
		)
		return false, errMsg
	end
end

local function validateReportData(data)
	local val = BugReportConfig.Validation

	if type(data) ~= "table" then
		return false, "Data tidak valid"
	end

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

bugReportRemote.OnServerEvent:Connect(function(player, reportData)
	if type(reportData) ~= "table" then
		bugReportRemote:FireClient(player, {
			success = false,
			message = "❌ Data laporan tidak valid."
		})
		return
	end

	local allowed, waitTime = checkRateLimit(player)
	if not allowed then
		local msg
		if waitTime == -1 then
			msg = "❌ Kamu sudah mencapai batas maksimal laporan untuk sesi ini."
		else
			msg = "⏱️ " .. string.format(BugReportConfig.RateLimit.CooldownMessage, waitTime)
		end
		bugReportRemote:FireClient(player, {
			success = false,
			message = msg
		})
		return
	end

	local valid, validError = validateReportData(reportData)
	if not valid then
		bugReportRemote:FireClient(player, {
			success = false,
			message = "❌ " .. validError
		})
		return
	end

	task.spawn(function()
		local sent, sendError = sendToDiscord(player, reportData)

		if not player or not player.Parent then
			return
		end

		if sent then
			bugReportRemote:FireClient(player, {
				success = true,
				message = "✅ Laporan bug berhasil dikirim! Terima kasih atas laporanmu."
			})
		else
			bugReportRemote:FireClient(player, {
				success = false,
				message = "❌ Gagal mengirim laporan: " .. (sendError or "Unknown error")
			})
		end
	end)
end)
