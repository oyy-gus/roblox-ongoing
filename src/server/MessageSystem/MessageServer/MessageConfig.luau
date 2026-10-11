-- Place in: StarterScriptService > MessageSystem(Folder) > MessageServer(Script) > MessageConfig(ModuleScript)

local MessageConfig = {}

-- ====================================
-- ACCESS CONFIGURATION
-- ====================================
MessageConfig.Access = {
	MinimumRole = "Admin",

	RoleHierarchy = {
		Owner = 7,
		Developer = 6,
		Admin = 5,
		Streamer = 4,
		Creator = 3,
		VIP = 2,
		Player = 1
	}
}

-- ====================================
-- ROLE DISPLAY CONFIGURATION
-- ====================================
MessageConfig.RoleDisplay = {
	Owner = {
		Text = "Owner",
		Color = Color3.fromRGB(255, 170, 90),
	},
	Developer = {
		Text = "Developer",
		Color = Color3.fromRGB(120, 200, 140),
	},
	Admin = {
		Text = "Admin",
		Color = Color3.fromRGB(200, 80, 80),
	},
	Streamer = {
		Text = "Streamer",
		Color = Color3.fromRGB(170, 140, 255), 
	},
	Creator = {
		Text = "Creator",
		Color = Color3.fromRGB(120, 220, 220), 
	},
	VIP = {
		Text = "VIP",
		Color = Color3.fromRGB(255, 210, 120), 
	},
	Player = {
		Text = "Player",
		Color = Color3.fromRGB(220, 235, 255),
	}
}

-- ====================================
-- NOTIFICATION CONFIGURATION
-- ====================================
MessageConfig.Notification = {
	Duration = 5,
	MaxVisible = 3,
	Spacing = 10,

	Animation = {
		DropSpeed = 0.5,
		EasingStyle = Enum.EasingStyle.Back,
		EasingDirection = Enum.EasingDirection.Out
	},

	Sound = {
		Enabled = true,
		SoundId = "rbxassetid://17208361335",
		Volume = 1,
		PlaybackSpeed = 1
	}
}

-- ====================================
-- MESSAGE VALIDATION
-- ====================================
MessageConfig.Validation = {
	MinLength = 1,
	MaxLength = 200,
	Cooldown = 3,
	EnableFilter = true,
	MaxMessagesPerMinute = 10
}

-- ====================================
-- UI CONFIGURATION
-- ====================================
MessageConfig.UI = {
	Icon = {
		Image = "rbxassetid://7733992901",
		Name = "BroadcastMessage",
		Tip = "Send Broadcast Message"
	}
}

return MessageConfig
