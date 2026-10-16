-- ============================================================
-- RemoteInitializer.server.luau
-- Membuat semua Folder & Remote di ReplicatedStorage
-- agar tersedia sebelum client/server lain membutuhkannya.
-- Place in: ServerScriptService
-- ============================================================

local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Helper: buat folder jika belum ada
local function getOrCreateFolder(parent, name)
	local f = parent:FindFirstChild(name)
	if not f then
		f = Instance.new("Folder")
		f.Name = name
		f.Parent = parent
	end
	return f
end

-- Helper: buat RemoteEvent jika belum ada
local function ensureRemoteEvent(parent, name)
	if not parent:FindFirstChild(name) then
		local re = Instance.new("RemoteEvent")
		re.Name = name
		re.Parent = parent
	end
end

-- Helper: buat RemoteFunction jika belum ada
local function ensureRemoteFunction(parent, name)
	if not parent:FindFirstChild(name) then
		local rf = Instance.new("RemoteFunction")
		rf.Name = name
		rf.Parent = parent
	end
end

-- ============================================================
-- 1) Folder: Remotes
-- ============================================================
local Remotes = getOrCreateFolder(ReplicatedStorage, "Remotes")

-- ChatTag
ensureRemoteFunction(Remotes, "GetChatTags")
ensureRemoteEvent(Remotes,    "TagsUpdated")

-- Device detection
ensureRemoteFunction(Remotes, "GetDevice")

-- Donation display
ensureRemoteEvent(Remotes, "ShowDonationGUI")

-- Sync notification (dance)
ensureRemoteEvent(Remotes, "SyncNotification")

-- Bug report
ensureRemoteEvent(Remotes, "SendBugReport")

-- Friend system (RemoteFunction — FriendServer uses OnServerInvoke)
ensureRemoteFunction(Remotes, "GetFollowerCount")
ensureRemoteFunction(Remotes, "GetFollowingCount")
ensureRemoteFunction(Remotes, "GetSocialCounts")
ensureRemoteFunction(Remotes, "GetFriendCountServer")

-- ============================================================
-- 2) Folder: SyncRemotes (animasi sinkron / emote)
-- ============================================================
local SyncRemotes = getOrCreateFolder(ReplicatedStorage, "SyncRemotes")

ensureRemoteFunction(SyncRemotes, "animationStart")
ensureRemoteEvent(SyncRemotes,    "startSync")
ensureRemoteEvent(SyncRemotes,    "changeSpeed")
ensureRemoteEvent(SyncRemotes,    "updateFavoritedAnimationsEvent")
ensureRemoteEvent(SyncRemotes,    "RequestSync")
ensureRemoteEvent(SyncRemotes,    "StoredAnimations")
ensureRemoteEvent(SyncRemotes,    "SyncNotification")

-- ============================================================
-- 3) Folder: ConfigRemotes
-- ============================================================
local ConfigRemotes = getOrCreateFolder(ReplicatedStorage, "ConfigRemotes")
ensureRemoteEvent(ConfigRemotes,    "UpdateConfig")
ensureRemoteFunction(ConfigRemotes, "GetConfig")

-- ============================================================
-- 4) Folder: MusicRemotes
-- ============================================================
local MusicRemotes = getOrCreateFolder(ReplicatedStorage, "MusicRemotes")
ensureRemoteEvent(MusicRemotes,    "MusicBroadcast")
ensureRemoteEvent(MusicRemotes,    "MusicUpdate")
ensureRemoteFunction(MusicRemotes, "GetPlaylist")

-- ============================================================
-- 5) Emotes & Animations Init
-- ============================================================
local EmotesFolder = getOrCreateFolder(ReplicatedStorage, "Emotes")
getOrCreateFolder(EmotesFolder, "Pose")

pcall(function()
	local ContextModule = ReplicatedStorage:FindFirstChild("ContextModule")
	if ContextModule then
		local AnimationLoader = ContextModule:FindFirstChild("AnimationLoader")
		if AnimationLoader then
			require(AnimationLoader).loadAnimations()
		end
	end
end)

-- ============================================================
-- 6) UI Folder Init
-- ============================================================
getOrCreateFolder(ReplicatedStorage, "UI")

print("✅ [RemoteInitializer] Semua Remote & Folder berhasil dibuat.")
