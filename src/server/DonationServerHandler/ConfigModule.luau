-- MODULE: ConfigModule
-- Letakkan sebagai child dari DonationServerHandler
-- ========================================

local ConfigModule = {}

-- ============================================
-- 📋 KONFIGURASI
-- ============================================
ConfigModule.DEBUG = {
	ENABLED = false,
	SHOW_PLAYER_REQUESTS = false,
	SHOW_PRODUCT_LOADING = false,
	SHOW_CACHE_INFO = false,
	SHOW_VALIDATION = true,
	SHOW_ERRORS = true,
}

ConfigModule.CACHE = {
	DURATION = 300, -- 5 menit
}

ConfigModule.PRODUCTS = {
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

return ConfigModule
