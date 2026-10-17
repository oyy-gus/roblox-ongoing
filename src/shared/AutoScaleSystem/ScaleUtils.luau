local Config     = require(script.Parent:WaitForChild("Config"))
local ScaleUtils = {}

function ScaleUtils.computeRawScale(viewportSize: Vector2, baseResolution: Vector2): number
	local scaleX = viewportSize.X / baseResolution.X
	local scaleY = viewportSize.Y / baseResolution.Y
	return math.min(scaleX, scaleY)
end

function ScaleUtils.applyBoostCurve(rawScale: number): number
	if rawScale < 1 then

		local boost = 1 + (1 - rawScale) * Config.SMALL_SCREEN_BOOST
		return rawScale * boost
	elseif rawScale > 1 then

		return rawScale * Config.LARGE_SCREEN_SHRINK
	else
		return 1
	end
end

function ScaleUtils.debugInfo(viewportSize: Vector2, baseResolution: Vector2): {}
	local raw     = ScaleUtils.computeRawScale(viewportSize, baseResolution)
	local boosted = ScaleUtils.applyBoostCurve(raw)
	local clamped = math.clamp(boosted, Config.MIN_SCALE, Config.MAX_SCALE)

	return {
		rawScale     = raw,
		boostedScale = boosted,
		clampedScale = clamped,
		viewportSize = viewportSize,
	}
end

return ScaleUtils
