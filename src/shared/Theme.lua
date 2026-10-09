--[[
	Theme.lua
	Tujuan: Tema HITAM-PUTIH MURNI premium.
	Gradient bergerak memutar berdasarkan beat di semua elemen.
]]

local Theme = {
	Colors = {
		-- === BACKGROUNDS: Hitam Total ===
		Background      = Color3.fromRGB(5, 5, 5),         -- Hitam pekat
		BackgroundGrad1 = Color3.fromRGB(15, 15, 15),      -- Hitam soft
		BackgroundGrad2 = Color3.fromRGB(0, 0, 0),         -- Hitam murni
		BackgroundGrad3 = Color3.fromRGB(30, 30, 30),      -- Abu-abu sangat gelap
		Surface         = Color3.fromRGB(18, 18, 18),      -- Surface gelap
		SurfaceHover    = Color3.fromRGB(35, 35, 35),      -- Hover sedikit terang
		SurfaceActive   = Color3.fromRGB(55, 55, 55),      -- Active abu tua
		Header          = Color3.fromRGB(10, 10, 10),      -- Header hitam
		CardBackground  = Color3.fromRGB(12, 12, 12),      -- Card hitam

		-- === BRAND: Putih + Abu-abu ===
		Primary         = Color3.fromRGB(255, 255, 255),   -- Putih murni (aksen utama)
		PrimaryHover    = Color3.fromRGB(210, 210, 210),   -- Abu cerah
		PrimaryDeep     = Color3.fromRGB(80, 80, 80),      -- Abu gelap
		Accent          = Color3.fromRGB(200, 200, 200),   -- Abu muda/silver
		AccentBright    = Color3.fromRGB(255, 255, 255),   -- Putih
		Gold            = Color3.fromRGB(255, 255, 255),   -- Putih (ganti emas)
		GoldHover       = Color3.fromRGB(200, 200, 200),   -- Abu muda
		Success         = Color3.fromRGB(180, 255, 180),   -- Hijau sangat pucat
		Danger          = Color3.fromRGB(255, 80, 80),     -- Merah (satu-satunya warna selain B&W)

		-- === TYPOGRAPHY ===
		Text            = Color3.fromRGB(255, 255, 255),   -- Putih
		TextMuted       = Color3.fromRGB(160, 160, 160),   -- Abu sedang
		TextSubtle      = Color3.fromRGB(90, 90, 90),      -- Abu gelap
		TextDark        = Color3.fromRGB(5, 5, 5),         -- Hitam

		-- === VISUAL ELEMENTS ===
		Stroke          = Color3.fromRGB(45, 45, 45),      -- Border abu gelap
		StrokeHighlight = Color3.fromRGB(130, 130, 130),   -- Border abu terang
		StrokeBright    = Color3.fromRGB(255, 255, 255),   -- Border putih (neon)
		ProgressTrack   = Color3.fromRGB(25, 25, 25),      -- Track gelap
		ProgressFill    = Color3.fromRGB(255, 255, 255),   -- Fill putih

		-- === BEAT GRADIENT (Hitam → Abu → Putih) ===
		BeatBlack       = Color3.fromRGB(0, 0, 0),
		BeatDark        = Color3.fromRGB(20, 20, 20),
		BeatMid         = Color3.fromRGB(70, 70, 70),
		BeatLight       = Color3.fromRGB(160, 160, 160),
		BeatWhite       = Color3.fromRGB(255, 255, 255),
	},

	Fonts = {
		Title       = Enum.Font.GothamBold,
		Header      = Enum.Font.GothamBold,
		Body        = Enum.Font.GothamMedium,
		BodyBold    = Enum.Font.GothamBold,
		BodyRegular = Enum.Font.Gotham,
		Code        = Enum.Font.Code,
	},

	TextSizes = {
		Title   = 15,
		Header  = 13,
		Body    = 12,
		Caption = 11,
		Small   = 10,
	},

	Dimensions = {
		CornerRadius      = 10,
		CornerRadiusSmall = 6,
		CornerRadiusLarge = 14,
		PanelPadding      = 12,
		Spacing           = 8,
		ItemSpacing       = 5,
		MinMenuSize       = Vector2.new(310, 360),
		MaxMenuSize       = Vector2.new(600, 500),
	},

	Animation = {
		Fast         = 0.1,
		Normal       = 0.2,
		Slow         = 0.35,
		BeatFade     = 0.06,
		EasingStyle  = Enum.EasingStyle.Quart,
	},
}

return Theme
