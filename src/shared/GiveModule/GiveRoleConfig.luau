local GiveRoleConfig = {}

GiveRoleConfig.DeveloperProducts = {
	VIP_GIFT = 3579405556
}

GiveRoleConfig.Prices = {
	VIP = 1
}

GiveRoleConfig.DataStores = {
	TRANSACTION_HISTORY = "GiveRoleTransactions_v1",
	PENDING_GIFTS = "PendingGifts_v1"
}

GiveRoleConfig.Settings = {
	ENABLE_NOTIFICATIONS = true,
	MAX_RETRY_ATTEMPTS = 3,
	RETRY_DELAY = 1,

	PROTECTED_ROLES = {
		Owner     = true,
		Developer = true,
		Admin     = true
	}
}

GiveRoleConfig.AdminPanelRoles = {
	"VIP",
	"Streamer",
	"Creator"
}

GiveRoleConfig.PlayerMenuRoles = {
	"VIP"
}

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
		RequiresPayment = false
	},
	Creator = {
		Icon = "🎨",
		Color = Color3.fromRGB(255, 105, 180),
		Description = "Role untuk content creator",
		RequiresPayment = false
	}
}

GiveRoleConfig.Debug = {
	ENABLE_DEBUG = false,
	SHOW_CLIENT_LOGS = true,
	SHOW_SERVER_LOGS = true,
	SHOW_DISPATCH_LOGS = true,
	SHOW_RECEIPT_LOGS = true
}

return GiveRoleConfig
