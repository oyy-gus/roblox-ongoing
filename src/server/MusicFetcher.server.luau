-- ====================================
-- MUSIC FETCHER (TIDAK BERUBAH)
-- Place in: ServerScriptService > MusicFetcher(Script)
-- ====================================

local ServerStorage = game:GetService("ServerStorage")

print("[MusicFetcher] Starting...")

local bridge = require(ServerStorage:WaitForChild("Modules"):WaitForChild("MusicPlaylistBridge"))
local list   = bridge:FetchAsync()

if #list == 0 then
	warn("[MusicFetcher] Playlist kosong setelah fetch!")
else
	print(string.format("[MusicFetcher] Playlist siap: %d lagu", #list))
end
