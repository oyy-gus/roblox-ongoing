-- MODULE: BroadcastConfig
-- Letakkan sebagai child dari DonationBroadcastHandler
-- ========================================

local BroadcastConfig = {}

-- Debug Settings
BroadcastConfig.DEBUG = {
	ENABLED = false,
	SHOW_BROADCAST = true,
	SHOW_QUEUE = true,
	SHOW_ERRORS = true,
	SHOW_SECURITY = true,
}

-- Broadcast Settings
BroadcastConfig.BROADCAST = {
	MIN_DONATION = 50,
	DISPLAY_DURATION = 5,
	MAX_MESSAGE_LENGTH = 200,
	QUEUE_DELAY = 0.5,
	-- NEW: Auto message untuk donasi kecil
	AUTO_MESSAGE_ENABLED = true,
	AUTO_MESSAGE_THRESHOLD = 50, -- Donasi < 50 Robux akan dapat pesan otomatis
}

-- Auto Messages (random pilih salah satu)
BroadcastConfig.AUTO_MESSAGES = {
	"Terima kasih atas dukungannya!",
	"Setiap donasi sangat berarti!",
	"Terima kasih telah berdonasi!",
	"Dukungan kamu sangat membantu!",
	"Terima kasih banyak!",
	"Apresiasi untuk donasi kamu!",
}

-- Anti-Spam
BroadcastConfig.ANTISPAM = {
	ENABLED = true,
	COOLDOWN = 10,
	MAX_QUEUE = 50,
	MAX_QUEUE_PER_PLAYER = 3,
}

-- Security
BroadcastConfig.SECURITY = {
	TRACK_PURCHASES = false,
	PURCHASE_TIMEOUT = 300,
	KICK_ON_FAKE = false,
}

-- Product Prices (sync dengan DonationServerHandler)
BroadcastConfig.PRODUCT_PRICES = {
	{id = 3569205896, name = "10 Robux", price = 10},
	{id = 3575392550, name = "25 Robux", price = 25},
	{id = 3579402644, name = "50 Robux", price = 50},
	{id = 3579402645, name = "75 Robux", price = 75},
	{id = 3579402646, name = "100 Robux", price = 100},
	{id = 3579402647, name = "250 Robux", price = 250},
	{id = 3579402648, name = "500 Robux", price = 500},
	{id = 3579402649, name = "750 Robux", price = 750},
	{id = 3579402650, name = "1000 Robux", price = 1000},
	{id = 3579402651, name = "2500 Robux", price = 2500},
	{id = 3579402652, name = "5000 Robux", price = 5000},
	{id = 3579402653, name = "7500 Robux", price = 7500},
	{id = 3579402654, name = "10000 Robux", price = 10000},
	{id = 3579402655, name = "25000 Robux", price = 25000},
	{id = 3579405557, name = "50000 Robux", price = 50000},

}

return BroadcastConfig
