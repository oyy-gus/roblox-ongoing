local ClientConfig = {}

ClientConfig.DEBUG = {
	ENABLED = true,
	SHOW_UI_EVENTS = false,
	SHOW_PRODUCT_LOADING = false,
	SHOW_BUTTON_CREATION = false,
	SHOW_PURCHASE_EVENTS = true,
	SHOW_ERRORS = true,
}

ClientConfig.UI = {
	BUTTON_SPACING = 5,
	BUTTON_CREATE_DELAY = 0.03,
	LOADING_TEXT = "Memuat produk...",
	PROCESSING_TEXT = "Sedang memproses...",
}

ClientConfig.NOTIFICATIONS = {
	ENABLED = true,
	DURATION = {
		DEFAULT = 3,
		SUCCESS = 5,
		ERROR = 3,
		INFO = 2,
	}
}

ClientConfig.NOTIFICATION_ANIMATION = {
	ENABLED = true,
	SOUND_ID = "rbxassetid://82038059105956",
	SOUND_VOLUME = 0.5,
	SLIDE_TIME = 0.4,
	SLIDE_STYLE = Enum.EasingStyle.Back,
	SLIDE_DIRECTION = Enum.EasingDirection.Out,
	FADE_IN_TIME = 0.3,
	FADE_OUT_TIME = 0.3,
	SHAKE_ENABLED = true,
	SHAKE_INTENSITY = 3,
	SHAKE_DURATION = 0.1,
}

ClientConfig.DONATION_COLORS = {
	{min = 10000, color = Color3.fromRGB(230, 33, 23),  name = "Legendary", emoji = "👑"},
	{min = 5000,  color = Color3.fromRGB(233, 30, 99),  name = "Epic",      emoji = "💎"},
	{min = 2000,  color = Color3.fromRGB(156, 39, 176), name = "Rare",      emoji = "⭐"},
	{min = 1000,  color = Color3.fromRGB(63, 81, 181),  name = "Super",     emoji = "🌟"},
	{min = 500,   color = Color3.fromRGB(33, 150, 243), name = "Great",     emoji = "✨"},
	{min = 200,   color = Color3.fromRGB(0, 188, 212),  name = "Good",      emoji = "💫"},
	{min = 100,   color = Color3.fromRGB(0, 150, 136),  name = "Nice",      emoji = "🎁"},
	{min = 0,     color = Color3.fromRGB(76, 175, 80),  name = "Thanks",    emoji = "💝"},
}

ClientConfig.MESSAGE = {
	MIN_DONATION = 50,
	MAX_LENGTH = 200,
	COOLDOWN = 10,
}

ClientConfig.MESSAGES = {
	NO_PRODUCTS = "Tidak ada produk donasi\n\nHubungi developer untuk bantuan.",
	SERVER_UNAVAILABLE = "Server tidak tersedia!\n\nSilakan refresh halaman.",
	PURCHASE_FAILED = "Gagal membuka pembelian",
	LOAD_FAILED = "Gagal memuat produk",
	SERVER_NOT_READY = "Server tidak siap",
	PURCHASE_SUCCESS = "Terima Kasih!",
	PURCHASE_SUCCESS_DESC = "Donasi berhasil!",
	LOAD_SUCCESS = "Berhasil!",
	MESSAGE_SENT = "Pesan Terkirim!",
	MESSAGE_SENT_DESC = "Pesan Anda telah dikirim ke semua pemain",
	MESSAGE_TOO_SHORT = "Pesan terlalu pendek!",
	MESSAGE_TOO_LONG = "Pesan terlalu panjang! (Maks 200 karakter)",
}

return ClientConfig
