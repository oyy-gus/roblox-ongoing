-- ====================================
-- MUSIC SKIP VOTE MANAGER (IMPROVED)
-- Place in: ServerScriptService > MusicServer(Folder) > MusicSystem(Script) > MusicSkipVoteManager(ModuleScript)
-- ====================================
-- Changes:
--   ✅ tick() → workspace:GetServerTimeNow()

local Players = game:GetService("Players")

local MusicSkipVoteManager = {}
MusicSkipVoteManager.__index = MusicSkipVoteManager

function MusicSkipVoteManager.new(config, roleSystem)
	local self = setmetatable({}, MusicSkipVoteManager)
	self.config     = config
	self.roleSystem = roleSystem
	self.skipVote = {
		active    = false,
		initiator = nil,
		songData  = nil,
		voters    = {},
		yesVotes  = 0,
		noVotes   = 0,
		startTime = 0,
	}
	self.skipVoteRateLimit = {}
	return self
end

-- ====================================
-- ELIGIBLE VOTERS
-- ====================================

function MusicSkipVoteManager:GetEligibleVoters()
	return Players:GetPlayers()
end

-- ====================================
-- RATE LIMITING
-- ====================================

function MusicSkipVoteManager:CheckRateLimit(player)
	local userId   = player.UserId
	local lastTime = self.skipVoteRateLimit[userId]
	if lastTime then
		local elapsed = workspace:GetServerTimeNow() - lastTime
		if elapsed < (self.config.SKIP_VOTE_COOLDOWN or 1) then
			return false
		end
	end
	self.skipVoteRateLimit[userId] = workspace:GetServerTimeNow()
	return true
end

-- ====================================
-- VOTE MANAGEMENT
-- ====================================

function MusicSkipVoteManager:IsActive()
	return self.skipVote.active == true
end

function MusicSkipVoteManager:GetVoteState()
	return {
		active    = self.skipVote.active,
		yesVotes  = self.skipVote.yesVotes,
		noVotes   = self.skipVote.noVotes,
		initiator = self.skipVote.initiator,
		songData  = self.skipVote.songData,
	}
end

function MusicSkipVoteManager:StartVote(initiatorPlayer, songData, dispatcher)
	if self.skipVote.active then
		return false, "Vote skip sudah aktif!"
	end

	local eligible = self:GetEligibleVoters()
	if #eligible < 1 then
		return false, "Tidak ada player di server."
	end

	local requiredVotes = (#eligible <= 1) and 1 or (math.floor(#eligible / 2) + 1)

	self.skipVote = {
		active    = true,
		initiator = initiatorPlayer.DisplayName,
		songData  = songData,
		voters    = {
			[initiatorPlayer.UserId] = "yes",
		},
		yesVotes  = 1,
		noVotes   = 0,
		startTime = workspace:GetServerTimeNow(),
	}

	dispatcher:SendToAll("SKIP_VOTE_START", {
		initiator   = initiatorPlayer.DisplayName,
		songTitle   = songData and songData.judul or "Unknown",
		totalVoters = #eligible,
		yesVotes    = 1,
		noVotes     = 0,
		required    = requiredVotes,
	})

	-- Jika langsung lolos (misal hanya 1 pemain di server)
	if self.skipVote.yesVotes >= requiredVotes then
		self:EndVote(dispatcher, false, true)
		return true, nil
	end

	local voteStartTime = self.skipVote.startTime
	task.delay(self.config.SKIP_VOTE_DURATION or 30, function()
		if self.skipVote.active and self.skipVote.startTime == voteStartTime then
			self:EndVote(dispatcher, false)
		end
	end)

	return true, nil
end

function MusicSkipVoteManager:CastVote(player, voteType, dispatcher)
	if not self.skipVote.active then
		return false, "Tidak ada vote yang aktif!"
	end

	local userId = player.UserId
	if self.skipVote.voters[userId] then
		return false, "Anda sudah voting!"
	end

	self.skipVote.voters[userId] = voteType
	if voteType == "yes" then
		self.skipVote.yesVotes = self.skipVote.yesVotes + 1
	else
		self.skipVote.noVotes = self.skipVote.noVotes + 1
	end

	local eligible = self:GetEligibleVoters()
	local requiredVotes = (#eligible <= 1) and 1 or (math.floor(#eligible / 2) + 1)

	dispatcher:SendToAll("SKIP_VOTE_UPDATE", {
		yesVotes    = self.skipVote.yesVotes,
		noVotes     = self.skipVote.noVotes,
		totalVoters = #eligible,
		required    = requiredVotes,
	})

	if self.skipVote.yesVotes >= requiredVotes then
		self:EndVote(dispatcher, false, true)
		return true, true
	end

	return true, false
end

function MusicSkipVoteManager:EndVote(dispatcher, forced, passedParam)
	if not self.skipVote.active then return false end

	local eligible      = #self:GetEligibleVoters()
	local requiredVotes = (eligible <= 1) and 1 or (math.floor(eligible / 2) + 1)
	local passed        = (passedParam == true) or (self.skipVote.yesVotes >= requiredVotes)

	self.skipVote = {
		active    = false,
		initiator = nil,
		songData  = nil,
		voters    = {},
		yesVotes  = 0,
		noVotes   = 0,
		startTime = 0,
	}

	dispatcher:SendToAll("SKIP_VOTE_END", {
		result = (passed and not forced) and "passed" or "failed",
	})

	return passed
end

function MusicSkipVoteManager:UpdateVoteOnPlayerLeave(userId, dispatcher)
	if not self.skipVote.active then return end

	if self.skipVote.voters[userId] then
		if self.skipVote.voters[userId] == "yes" then
			self.skipVote.yesVotes = math.max(0, self.skipVote.yesVotes - 1)
		else
			self.skipVote.noVotes = math.max(0, self.skipVote.noVotes - 1)
		end
		self.skipVote.voters[userId] = nil

		local eligible = self:GetEligibleVoters()
		local requiredVotes = (#eligible <= 1) and 1 or (math.floor(#eligible / 2) + 1)

		dispatcher:SendToAll("SKIP_VOTE_UPDATE", {
			yesVotes    = self.skipVote.yesVotes,
			noVotes     = self.skipVote.noVotes,
			totalVoters = #eligible,
			required    = requiredVotes,
		})

		if self.skipVote.yesVotes >= requiredVotes and #eligible > 0 then
			self:EndVote(dispatcher, false, true)
		end
	end
end

return MusicSkipVoteManager
