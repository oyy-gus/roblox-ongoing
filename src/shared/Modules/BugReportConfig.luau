local BugReportConfig = {}

BugReportConfig.Webhook = {

	BotUsername = "🐛 Bug Reporter",
	AvatarURL = "https://cdn.discordapp.com/attachments/1162658783353385051/1493659081364345004/file_00000000592871faa5b267c838293de4.jpg",

	Colors = {
		Low      = 3394611,
		Medium   = 16763904,
		High     = 16711680,
		Critical = 9109759,
	},

	Emoji = {
		Low      = "🟢",
		Medium   = "🟡",
		High     = "🔴",
		Critical = "🟣",
	}
}

BugReportConfig.RateLimit = {
	CooldownSeconds = 60,
	MaxReportsPerSession = 10,
	CooldownMessage = "Harap tunggu %d detik sebelum mengirim laporan lagi.",
}

BugReportConfig.Categories = {
	{ id = "gameplay",  label = "🎮 Gameplay",      desc = "Bug terkait mekanisme permainan" },
	{ id = "ui",        label = "🖥️ UI/Interface",   desc = "Bug pada tampilan atau menu" },
	{ id = "audio",     label = "🔊 Audio",          desc = "Bug suara atau musik" },
	{ id = "map",       label = "🗺️ Peta/Map",       desc = "Bug pada desain peta" },
	{ id = "crash",     label = "💥 Crash/Error",    desc = "Game crash atau error kritis" },
	{ id = "exploit",   label = "⚠️ Exploit",        desc = "Celah keamanan atau exploit" },
	{ id = "other",     label = "❓ Lainnya",         desc = "Bug yang tidak masuk kategori lain" },
}

BugReportConfig.Severities = {
	{ id = "low",      label = "🟢 Rendah",  desc = "Bug kecil, tidak mengganggu gameplay" },
	{ id = "medium",   label = "🟡 Sedang",  desc = "Mengganggu tapi masih bisa dimainkan" },
	{ id = "high",     label = "🔴 Tinggi",  desc = "Sangat mengganggu gameplay" },
	{ id = "critical", label = "🟣 Kritis",  desc = "Game tidak bisa dimainkan / exploit" },
}

BugReportConfig.Validation = {
	TitleMinLength  = 5,
	TitleMaxLength  = 100,
	DescMinLength   = 20,
	DescMaxLength   = 1000,
	StepsMaxLength  = 500,
}

BugReportConfig.RemoteName = "SendBugReport"

return BugReportConfig
