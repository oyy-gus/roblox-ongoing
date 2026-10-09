--[[
	TitleCleaner.lua
	Tujuan: Membersihkan judul lagu dari teks pengganggu/sampah
	seperti (Full Album), [Official Music Video], Full Bass, Terbaru, Viral TikTok, dll.
	Serta mengonversi ALL CAPS menjadi Title Case yang rapi.
]]

local TitleCleaner = {}

-- Frasa noise yang akan dihapus dari judul
local NOISE_PATTERNS = {
	-- Ekstensi file
	"%.mp3$", "%.wav$", "%.ogg$", "%.flac$", "%.m4a$",

	-- Album & Rilis
	"[Ff][Uu][Ll][Ll]%s+[Aa][Ll][Bb][Uu][Mm]",
	"[Aa][Ll][Bb][Uu][Mm]%s+[Tt][Ee][Rr][Bb][Aa][Rr][Uu]",
	"[Ff][Uu][Ll][Ll]%s+[Vv][Ee][Rr][Ss][Ii][Oo][Nn]",
	"[Ff][Uu][Ll][Ll]%s+[Vv][Ee][Rr]",
	"[Ff][Uu][Ll][Ll]%s+[Tt][Rr][Aa][Cc][Kk]",

	-- Video & Audio Official / Lirik
	"[Oo][Ff][Ff][Ii][Cc][Ii][Aa][Ll]%s+[Mm][Uu][Ss][Ii][Cc]%s+[Vv][Ii][Dd][Ee][Oo]",
	"[Oo][Ff][Ff][Ii][Cc][Ii][Aa][Ll]%s+[Vv][Ii][Dd][Ee][Oo]",
	"[Oo][Ff][Ff][Ii][Cc][Ii][Aa][Ll]%s+[Aa][Uu][Dd][Ii][Oo]",
	"[Oo][Ff][Ff][Ii][Cc][Ii][Aa][Ll]%s+[Ll][Yy][Rr][Ii][Cc]%s+[Vv][Ii][Dd][Ee][Oo]",
	"[Oo][Ff][Ff][Ii][Cc][Ii][Aa][Ll]%s+[Ll][Yy][Rr][Ii][Cc]",
	"[Oo][Ff][Ff][Ii][Cc][Ii][Aa][Ll]",
	"[Mm][Uu][Ss][Ii][Cc]%s+[Vv][Ii][Dd][Ee][Oo]",
	"[Ll][Yy][Rr][Ii][Cc]%s+[Vv][Ii][Dd][Ee][Oo]",
	"[Ll][Yy][Rr][Ii][Cc][Ss]",
	"[Ll][Ii][Rr][Ii][Kk]%s+[Ll][Aa][Gg][Uu]",
	"[Ll][Ii][Rr][Ii][Kk]",

	-- Kualitas & Format Audio
	"[Aa][Uu][Dd][Ii][Oo]%s+[Hh][Qq]",
	"[Hh][Ii][Gg][Hh]%s+[Qq][Uu][Aa][Ll][Ii][Tt][Yy]",
	"[Aa][Uu][Dd][Ii][Oo]%s+[Oo][Rr][Ii]",
	"[Oo][Rr][Ii][Gg][Ii][Nn][Aa][Ll]%s+[Aa][Uu][Dd][Ii][Oo]",
	"[Oo][Rr][Ii][Gg][Ii][Nn][Aa][Ll]%s+[Ss][Oo][Uu][Nn][Dd]",

	-- Sound / Bass / DJ Extras
	"[Ff][Uu][Ll][Ll]%s+[Bb][Aa][Ss][Ss]",
	"[Bb][Aa][Ss][Ss]%s+[Gg][Ll][Ee][Rr][Rr]?",
	"[Bb][Aa][Ss][Ss]%s+[Mm][Ee][Nn][Gg][Ee][Nn][Tt][Aa][Kk]",
	"[Bb][Aa][Ss][Ss]%s+[Bb][Oo][Oo][Ss][Tt][Ee][Dd]",
	"[Jj][Ee][Dd][Aa][Gg]%s+[Jj][Ee][Dd][Uu][Gg]",
	"[Jj][Jj]%s+[Vv][Ii][Rr][Aa][Ll]",
	"[Ss][Ll][Oo][Ww]%s+[Bb][Aa][Ss][Ss]",
	"[Ss][Ll][Oo][Ww][Ee][Dd]%s+[%+%s]*%s*[Rr][Ee][Vv][Ee][Rr][Bb]",
	"[Ss][Pp][Ee][Ee][Dd]%s+[Uu][Pp]",
	"[Nn][Ii][Gg][Hh][Tt][Cc][Oo][Rr][Ee]",

	-- Viral & Trending Tags
	"[Vv][Ii][Rr][Aa][Ll]%s+[Tt][Ii][Kk][Tt][Oo][Kk]",
	"[Tt][Ii][Kk][Tt][Oo][Kk]%s+[Vv][Ii][Rr][Aa][Ll]",
	"[Vv][Ii][Rr][Aa][Ll]%s+20%d%d",
	"[Tt][Ee][Rr][Bb][Aa][Rr][Uu]%s+20%d%d",
	"[Hh][Ii][Tt][Ss]%s+20%d%d",
	"[Tt][Rr][Ee][Nn][Dd][Ii][Nn][Gg]",
	"%f[%a][Vv][Ii][Rr][Aa][Ll]%f[%A]",
	"%f[%a][Tt][Ee][Rr][Bb][Aa][Rr][Uu]%f[%A]",
	"%f[%a][Kk][Aa][Cc][Ii][Ww]%f[%A]",
}

-- Kata hubung yang tetap lowercase di Title Case (kecuali di awal kata)
local LOWER_WORDS = {
	["a"] = true, ["an"] = true, ["the"] = true,
	["and"] = true, ["but"] = true, ["or"] = true, ["for"] = true, ["nor"] = true,
	["on"] = true, ["at"] = true, ["to"] = true, ["from"] = true, ["by"] = true,
	["of"] = true, ["in"] = true, ["with"] = true, ["x"] = true, ["ft"] = true, ["feat"] = true
}

-- Kata khusus yang harus SELALU UPPERCASE
local UPPER_WORDS = {
	["DJ"] = true, ["VS"] = true, ["ID"] = true, ["HQ"] = true, ["HD"] = true, ["OK"] = true
}

-- Membersihkan tanda kurung yang berisi noise/junk
local function removeJunkBrackets(text)
	text = text:gsub("(%s*%b[])", function(match)
		local inner = match:sub(2, -2):lower()
		if inner:find("official") or inner:find("album") or inner:find("video")
			or inner:find("audio") or inner:find("lyric") or inner:find("lirik")
			or inner:find("full") or inner:find("bass") or inner:find("viral")
			or inner:find("tiktok") or inner:find("terbaru") or inner:find("remix")
			or inner:find("cover") or inner:find("hd") or inner:find("hq") then
			return ""
		end
		return match
	end)

	text = text:gsub("(%s*%b())", function(match)
		local inner = match:sub(2, -2):lower()
		if inner:find("official") or inner:find("album") or inner:find("video")
			or inner:find("audio") or inner:find("lyric") or inner:find("lirik")
			or inner:find("full") or inner:find("bass") or inner:find("viral")
			or inner:find("tiktok") or inner:find("terbaru") or inner:find("hd") or inner:find("hq") then
			return ""
		end
		return match
	end)

	return text
end

-- Mengubah string ALL CAPS ke Title Case yang rapi (misal: "DJ SAMPAI AKHIR" -> "DJ Sampai Akhir")
local function toTitleCase(text)
	-- Cek apakah string mayoritas uppercase
	local upperCount = 0
	local letterCount = 0
	for i = 1, #text do
		local char = text:sub(i, i)
		if char:find("%a") then
			letterCount = letterCount + 1
			if char == char:upper() then
				upperCount = upperCount + 1
			end
		end
	end

	-- Jika bukan all caps, kembalikan seperti awal (agar kata bercampur tidak rusak)
	if letterCount == 0 or (upperCount / letterCount) < 0.75 then
		return text
	end

	local words = {}
	local wordIdx = 0
	for word in text:gmatch("%S+") do
		wordIdx = wordIdx + 1
		local upperCheck = word:upper()
		if UPPER_WORDS[upperCheck] then
			table.insert(words, upperCheck)
		else
			local lowerWord = word:lower()
			if wordIdx > 1 and LOWER_WORDS[lowerWord] then
				table.insert(words, lowerWord)
			else
				-- Capitalize first letter
				local capitalized = lowerWord:sub(1, 1):upper() .. lowerWord:sub(2)
				table.insert(words, capitalized)
			end
		end
	end

	return table.concat(words, " ")
end

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UIStrings = require(ReplicatedStorage.Shared.UIStrings)

function TitleCleaner.CleanTitle(rawTitle)
	if type(rawTitle) ~= "string" or rawTitle == "" then
		return UIStrings.Music.UnknownTitle
	end

	local clean = rawTitle

	-- 1. Hapus kurung junk
	clean = removeJunkBrackets(clean)

	-- 2. Hapus frasa noise yang dikenal
	for _, pattern in ipairs(NOISE_PATTERNS) do
		clean = clean:gsub(pattern, "")
	end

	-- 3. Hapus karakter sampah / simbol aneh
	clean = clean:gsub("[|\\/#~%*]", " ")

	-- 4. Hapus pemisah ganda (misal "- -" atau "x x")
	clean = clean:gsub("%s*[%-_]%s*[%-_]%s*", " - ")

	-- 5. Hapus spasi ganda & trim
	clean = clean:gsub("%s+", " "):gsub("^%s+", ""):gsub("%s+$", "")

	-- 6. Hapus tanda hubung/titik dua di ujung string
	clean = clean:gsub("^[%-:%s]+", ""):gsub("[%-:%s]+$", "")

	-- 7. Ubah ke Title Case jika ALL CAPS
	clean = toTitleCase(clean)

	if clean == "" then
		return rawTitle -- Fallback jika pembersihan menghapus seluruh judul
	end

	return clean
end

return TitleCleaner
