local CarryConfig = {}

CarryConfig.DEBUG_ENABLED = false
CarryConfig.DEBUG_PREFIX = "[CARRY]"

function CarryConfig.debugPrint(category, ...)
	if not CarryConfig.DEBUG_ENABLED then return end
	print(CarryConfig.DEBUG_PREFIX, "[" .. category .. "]", ...)
end

CarryConfig.REMOTE_FOLDER = "CarryRemotes"
CarryConfig.REQUEST_TIMEOUT = 10
CarryConfig.MAX_DISTANCE = 20
CarryConfig.MAX_CARRY_PER_PLAYER = 5

CarryConfig.STYLES = {
	piggyback = {
		name = "piggyback",
		displayName = "Gendong Belakang",
		maxCarry = 1,
		offsetFunction = function(slotIndex)
			local BASE_Z = 1.6
			local SPACING_Z = 1.1
			local Y_OFFSET = 0.9
			local SLOT1_ADJ_Z = -0.2
			local SLOT2_ADJ_Z = 0.2
			local STEP_Y_FIRST = 0.55
			local STEP_Y_NEXT = 0.30
			local MAX_EXTRA_Y = 6.0

			local z = BASE_Z + (slotIndex - 1) * SPACING_Z
			if slotIndex == 1 then
				z = z + SLOT1_ADJ_Z
			elseif slotIndex == 2 then
				z = z + SLOT2_ADJ_Z
			end

			local elevIndex = math.max(0, slotIndex - 1)
			local extraY = (elevIndex > 0) and (STEP_Y_FIRST + (elevIndex - 1) * STEP_Y_NEXT) or 0
			extraY = math.min(extraY, MAX_EXTRA_Y)

			return CFrame.new(0, Y_OFFSET + extraY, z)
		end,
		carrierAnimId = 96834741687694,
		carriedAnimId = 139266218573144
	},

	bridal = {
		name = "bridal",
		displayName = "Gendong Pengantin",
		maxCarry = 1,
		offsetFunction = function(slotIndex)
			return CFrame.new(1, 0.5, -1.0) * CFrame.fromEulerAnglesXYZ(
				math.rad(15),
				math.rad(-5),
				math.rad(-20)
			)
		end,
		carrierAnimId = 137200064144120,
		carriedAnimId = 85856178266530
	},

	couplehug = {
		name = "couplehug",
		displayName = "Pelukan Pasangan",
		maxCarry = 1,
		offsetFunction = function(slotIndex)
			return CFrame.new(0, 0.6, -1.2) * CFrame.fromEulerAnglesXYZ(
				-25,
				math.rad(165),
				0
			)
		end,
		carrierAnimId = 130904642139077,
		carriedAnimId = 98438793480171
	},

	pasakal = {
		name = "pasakal",
		displayName = "Pasakal",
		maxCarry = 1,
		offsetFunction = function(slotIndex)
			return CFrame.new(0, 0.5, -1.7) * CFrame.fromEulerAnglesXYZ(
				-25,
				math.rad(175),
				0
			)
		end,
		carrierAnimId = 82497931907439,
		carriedAnimId = 132809472797685
	},

	piggyupperback = {
		name = "piggyupperback",
		displayName = "Gendong Atas",
		maxCarry = 1,
		offsetFunction = function(slotIndex)
			return CFrame.new(0, 2.5, 1.13)
		end,
		carrierAnimId = 116734113601276,
		carriedAnimId = 120268601721431
	}
}

function CarryConfig.getStyle(styleName)
	return CarryConfig.STYLES[styleName]
end

function CarryConfig.isValidStyle(styleName)
	return CarryConfig.STYLES[styleName] ~= nil
end

function CarryConfig.getStyleOffset(styleName, slotIndex)
	local style = CarryConfig.STYLES[styleName]
	if not style then
		warn("Gaya tidak valid:", styleName)
		return CFrame.new(0, 0, 0)
	end
	return style.offsetFunction(slotIndex)
end

function CarryConfig.getMaxCarryForStyle(styleName)
	local style = CarryConfig.STYLES[styleName]
	return style and style.maxCarry or 1
end

CarryConfig.ANIM_IDS = {
	piggyback = {
		carrier = {
			R15 = 96834741687694,
			R6 = 139266218573144
		},
		carried = {
			R15 = 96834741687694,
			R6 = 139266218573144
		}
	},

	bridal = {
		carrier = 137200064144120,
		carried = 85856178266530
	},

	couplehug = {
		carrier = 130904642139077,
		carried = 98438793480171
	},

	pasakal = {
		carrier = 82497931907439,
		carried = 132809472797685
	},

	piggyupperback = {
		carrier = 116734113601276,
		carried = 120268601721431
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
