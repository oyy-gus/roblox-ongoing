local ConfigData = {}

ConfigData.ColorTemplates = {
	Sunset = {
		Color3.fromRGB(255, 0, 18),
		Color3.fromRGB(243, 0, 207),
		Color3.fromRGB(162, 0, 255),
		Color3.fromRGB(51, 1, 255),
	},
	Ocean = {
		Color3.fromRGB(255, 203, 0),
		Color3.fromRGB(255, 129, 0),
		Color3.fromRGB(252, 186, 68),
		Color3.fromRGB(254, 242, 144),
	},
	Forest = {
		Color3.fromRGB(0, 253, 150),
		Color3.fromRGB(9, 222, 63),
		Color3.fromRGB(0, 167, 39),
		Color3.fromRGB(1, 95, 43),
	},
	Purple = {
		Color3.fromRGB(31, 165, 255),
		Color3.fromRGB(19, 216, 250),
		Color3.fromRGB(100, 238, 224),
		Color3.fromRGB(161, 254, 205),
	},
	Fire = {
		Color3.fromRGB(150, 150, 243),
		Color3.fromRGB(204, 146, 250),
		Color3.fromRGB(239, 144, 243),
		Color3.fromRGB(255, 119, 201),
		Color3.fromRGB(255, 106, 169),
	},
}

ConfigData.ColorPresets = {
	Red        = Color3.fromRGB(255, 77, 77),
	DarkRed    = Color3.fromRGB(180, 0, 0),
	Crimson    = Color3.fromRGB(220, 20, 60),
	Coral      = Color3.fromRGB(255, 127, 170),
	Blue       = Color3.fromRGB(77, 136, 255),
	DarkBlue   = Color3.fromRGB(0, 0, 139),
	SkyBlue    = Color3.fromRGB(135, 206, 235),
	Navy       = Color3.fromRGB(0, 0, 128),
	Cyan       = Color3.fromRGB(0, 255, 255),
	Aqua       = Color3.fromRGB(127, 255, 212),
	Green      = Color3.fromRGB(77, 255, 136),
	DarkGreen  = Color3.fromRGB(0, 100, 0),
	Lime       = Color3.fromRGB(50, 205, 50),
	Mint       = Color3.fromRGB(152, 255, 152),
	Emerald    = Color3.fromRGB(80, 200, 120),
	Purple     = Color3.fromRGB(191, 77, 255),
	DarkPurple = Color3.fromRGB(75, 0, 130),
	Violet     = Color3.fromRGB(138, 43, 226),
	Lavender   = Color3.fromRGB(230, 230, 250),
	Magenta    = Color3.fromRGB(255, 0, 255),
	Yellow     = Color3.fromRGB(255, 214, 77),
	Gold       = Color3.fromRGB(255, 215, 0),
	Orange     = Color3.fromRGB(255, 165, 0),
	DarkOrange = Color3.fromRGB(255, 140, 0),
	Amber      = Color3.fromRGB(255, 191, 0),
	Pink       = Color3.fromRGB(255, 105, 180),
	HotPink    = Color3.fromRGB(255, 20, 147),
	LightPink  = Color3.fromRGB(255, 182, 193),
	Rose       = Color3.fromRGB(255, 0, 127),
	Brown      = Color3.fromRGB(139, 69, 19),
	Tan        = Color3.fromRGB(210, 180, 140),
	Beige      = Color3.fromRGB(245, 245, 220),
	White      = Color3.fromRGB(255, 255, 255),
	Silver     = Color3.fromRGB(192, 192, 192),
	Gray       = Color3.fromRGB(128, 128, 128),
	Black      = Color3.fromRGB(0, 0, 0),
	Peach      = Color3.fromRGB(255, 218, 185),
	Turquoise  = Color3.fromRGB(64, 224, 208),
	Indigo     = Color3.fromRGB(75, 0, 130),
	Maroon     = Color3.fromRGB(128, 0, 0),
	Olive      = Color3.fromRGB(128, 128, 0),
	Teal       = Color3.fromRGB(0, 128, 128),
}

ConfigData.FontMap = {
	Gotham  = Enum.Font.GothamBold,
	Source  = Enum.Font.SourceSansBold,
	Fantasy = Enum.Font.Fantasy,
	Arcade  = Enum.Font.Arcade,
	SciFi   = Enum.Font.SciFi,
	Code    = Enum.Font.Code,
}

ConfigData.BasicColors = {
	"Red", "DarkRed", "Crimson", "Coral", "Rose", "HotPink", "Pink",
	"Blue", "DarkBlue", "SkyBlue", "Navy", "Cyan", "Aqua", "Turquoise",
	"Green", "DarkGreen", "Lime", "Mint", "Emerald", "Olive", "Teal",
	"Purple", "DarkPurple", "Violet", "Lavender", "Magenta", "Indigo",
	"Yellow", "Gold", "Orange", "DarkOrange", "Amber", "Peach",
	"White", "Silver", "Gray", "Black", "Brown", "Tan", "Beige", "Maroon", "LightPink",
}

function ConfigData.getColorByName(name)
	return ConfigData.ColorPresets[tostring(name or "White")] or Color3.new(1, 1, 1)
end

function ConfigData.getFontByName(name)
	return ConfigData.FontMap[tostring(name or "Gotham")] or Enum.Font.GothamBold
end

return ConfigData
