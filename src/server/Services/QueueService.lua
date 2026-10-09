--[[
	QueueService.lua
	Tujuan: Mengelola antrean lagu yang diminta oleh pemain.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TitleCleaner = require(ReplicatedStorage.Shared.Utils.TitleCleaner)
local UIStrings = require(ReplicatedStorage.Shared.UIStrings)

local QueueService = {}
local queue = {}
local MAX_QUEUE_SIZE = 20

function QueueService.AddSong(songData, requester)
	if not songData or not songData.sound_id then return false end
	local cleanTitle = TitleCleaner.CleanTitle(songData.title)
	if #queue >= MAX_QUEUE_SIZE then
		warn(string.format("[QueueService] Antrean penuh (%d/%d), lagu '%s' tidak ditambahkan.", #queue, MAX_QUEUE_SIZE, cleanTitle))
		return false
	end
	table.insert(queue, {
		title = cleanTitle,
		sound_id = songData.sound_id,
		artist = songData.artist or UIStrings.Music.UnknownArtist,
		requestedBy = requester and requester.Name or "Sistem",
	})
	return true
end

function QueueService.PopNextSong()
	if #queue > 0 then
		return table.remove(queue, 1)
	end
	return nil
end

function QueueService.GetQueue()
	return queue
end

function QueueService.Clear()
	table.clear(queue)
end

return QueueService
