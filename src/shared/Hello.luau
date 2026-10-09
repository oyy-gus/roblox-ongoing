-- Shared constants and type definitions for the music system
-- Used by both Server and Client

local MusicConfig = {}

-- API endpoint
MusicConfig.PLAYLIST_URL = "https://oyy-gus.github.io/api/v1/roblox/music/playlist.json"

-- How often the server broadcasts sync to all clients (seconds)
MusicConfig.SYNC_INTERVAL = 5

-- Threshold (seconds) before client re-seeks to correct drift
MusicConfig.SEEK_THRESHOLD = 0.3

-- Max seek correction to prevent jarring jumps (seconds)
MusicConfig.MAX_SEEK_JUMP = 30

-- Default volume for all clients
MusicConfig.DEFAULT_VOLUME = 0.6

--[[
	SyncState shape (sent from Server → Client):
	{
		loaded      : boolean,
		index       : number,        -- current song index (1-based)
		total       : number,        -- total songs in playlist
		soundId     : string,        -- Roblox asset ID string
		title       : string,        -- display name
		position    : number,        -- server's playback position in seconds at serverClock
		serverClock : number,        -- os.clock() on server when packet was built
		isPlaying   : boolean,
	}
]]

return MusicConfig
