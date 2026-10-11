-- Place in: ReplicatedStorage > GiveModule(Folder) > GiveRoleConfig(ModuleScript)
-- ====================================

local GiveRoleConfig = {}

-- For GiveRoleClient (PlayerMenu) - VIP only with payment
GiveRoleConfig.DeveloperProducts = {
	VIP_GIFT = 3579405556 -- Replace with actual product ID
}

GiveRoleConfig.Prices = {
	VIP = 1 -- Replace with actual price
}

GiveRoleConfig.DataStores = {
	TRANSACTION_HISTORY = "GiveRoleTransactions_v1",
	PENDING_GIFTS = "PendingGifts_v1"
}

GiveRoleConfig.Settings = {
	ENABLE_NOTIFICATIONS = true,
	MAX_RETRY_ATTEMPTS = 3,
	RETRY_DELAY = 1,

	-- Protected roles cannot receive roles
	PROTECTED_ROLES = {
		Owner     = true,
		Developer = true,
		Admin     = true
	}
}

-- Roles available in Admin Panel (RoleGiveClient)
GiveRoleConfig.AdminPanelRoles = {
	"VIP",
	"Streamer",
	"Creator"
}

-- Roles available in PlayerMenu (GiveRoleClient module) - VIP only
GiveRoleConfig.PlayerMenuRoles = {
	"VIP"
}

-- Role display configuration
GiveRoleConfig.RoleDisplay = {
	VIP = {
		Icon = "👑",
		Color = Color3.fromRGB(255, 215, 0),
		Description = "Akses VIP dengan benefit eksklusif",
		RequiresPayment = true
	},
	Streamer = {
		Icon = "📺",
		Color = Color3.fromRGB(138, 43, 226),
		Description = "Role untuk content creator streaming",
		RequiresPayment = false -- Free, admin only
	},
	Creator = {
		Icon = "🎨",
		Color = Color3.fromRGB(255, 105, 180),
		Description = "Role untuk content creator",
		RequiresPayment = false -- Free, admin only
	}
}

-- ====================================
-- DEBUG SETTINGS
-- ====================================
GiveRoleConfig.Debug = {
	ENABLE_DEBUG = false,
	SHOW_CLIENT_LOGS = true,
	SHOW_SERVER_LOGS = true,
	SHOW_DISPATCH_LOGS = true,
	SHOW_RECEIPT_LOGS = true
}

return GiveRoleConfig

-- ========================================
-- ADMIN CONFIG MODULE
