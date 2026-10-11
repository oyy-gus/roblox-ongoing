local CarryConfig = {}

-- ============================================
-- DEBUG SETTINGS
-- ============================================

CarryConfig.DEBUG_ENABLED = false
CarryConfig.DEBUG_PREFIX = "[CARRY]"

function CarryConfig.debugPrint(category, ...)
	if not CarryConfig.DEBUG_ENABLED then return end
	print(CarryConfig.DEBUG_PREFIX, "[" .. category .. "]", ...)
end

-- ============================================
-- SYSTEM SETTINGS
-- ============================================

CarryConfig.REMOTE_FOLDER = "CarryRemotes"
CarryConfig.REQUEST_TIMEOUT = 10
CarryConfig.MAX_DISTANCE = 20

-- ============================================
-- CARRY STYLES DEFINITION (Single Carry Only)
-- ============================================

CarryConfig.STYLES = {
	piggyback = {
		name = "piggyback",
		displayName = "Piggy Back",
		offsetFunction = function()
			return CFrame.new(0, 1.5, 1.0)
		end,
		carrierAnimId = 138645036444061,
		carriedAnimId = 70539173862851
	},

	bridal = {
		name = "bridal",
		displayName = "Bridal Carry",
		offsetFunction = function()
			return CFrame.new(1, 0.5, -1.0) * CFrame.fromEulerAnglesXYZ(
				math.rad(15),
				math.rad(-5),
				math.rad(-20)
			)
		end,
		carrierAnimId = 105855542367559,
		carriedAnimId = 130768642698188
	},

	couplehug = {
		name = "couplehug",
		displayName = "Couple Hug",
		offsetFunction = function()
			return CFrame.new(0, 0.6, -1.2) * CFrame.fromEulerAnglesXYZ(
				-25, 
				math.rad(165), 
				0
			)
		end,
		carrierAnimId = 126450044101359,
		carriedAnimId = 122812566406462
	},

	pasakal = {
		name = "pasakal",
		displayName = "Pasakal",
		offsetFunction = function()
			return CFrame.new(0, 0.5, -1.7) * CFrame.fromEulerAnglesXYZ(
				-25, 
				math.rad(175), 
				0
			)
		end,
		carrierAnimId = 123674495686114,
		carriedAnimId = 75278969845779
	},

	piggyupperback = {
		name = "piggyupperback",
		displayName = "Piggy Upper Back",
		offsetFunction = function()
			return CFrame.new(0, 2.5, 1.13)
		end,
		carrierAnimId = 123128713733683,
		carriedAnimId = 111497823721087
	}
}

-- ============================================
-- STYLE UTILITIES
-- ============================================

function CarryConfig.getStyle(styleName)
	return CarryConfig.STYLES[styleName]
end

function CarryConfig.isValidStyle(styleName)
	return CarryConfig.STYLES[styleName] ~= nil
end

function CarryConfig.getStyleOffset(styleName)
	local style = CarryConfig.STYLES[styleName]
	if not style then 
		warn("Invalid style:", styleName)
		return CFrame.new(0, 0, 0)
	end
	return style.offsetFunction()
end

-- ============================================
-- ANIMATION IDs
-- ============================================

CarryConfig.ANIM_IDS = {
	piggyback = {
		carrier = {
			R15 = 138645036444061,
			R6 = 70539173862851
		},
		carried = {
			R15 = 138645036444061,
			R6 = 70539173862851
		}
	},

	bridal = {
		carrier = 105855542367559,
		carried = 130768642698188
	},

	couplehug = {
		carrier = 126450044101359,
		carried = 122812566406462
	},

	pasakal = {
		carrier = 123674495686114,
		carried = 75278969845779
	},

	piggyupperback = {
		carrier = 123128713733683,
		carried = 111497823721087
	}
}

function CarryConfig.getAnimationId(styleName, role, rigType)
	local anims = CarryConfig.ANIM_IDS[styleName]
	if not anims then return 0 end

	if styleName == "piggyback" and rigType then
		return anims[role][rigType] or 0
	end

	return anims[role] or 0
end

return CarryConfig
