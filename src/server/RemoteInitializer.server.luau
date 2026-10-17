local ReplicatedStorage = game:GetService("ReplicatedStorage")

local function getOrCreateFolder(parent: Instance, name: string): Folder
	local folder = parent:FindFirstChild(name)
	if not folder then
		folder = Instance.new("Folder")
		folder.Name = name
		folder.Parent = parent
	end
	return folder
end

local function ensureRemoteEvent(parent: Instance, name: string): RemoteEvent
	local remote = parent:FindFirstChild(name)
	if not remote then
		remote = Instance.new("RemoteEvent")
		remote.Name = name
		remote.Parent = parent
	end
	return remote
end

local function ensureRemoteFunction(parent: Instance, name: string): RemoteFunction
	local remote = parent:FindFirstChild(name)
	if not remote then
		remote = Instance.new("RemoteFunction")
		remote.Name = name
		remote.Parent = parent
	end
	return remote
end

local Remotes = getOrCreateFolder(ReplicatedStorage, "Remotes")
ensureRemoteFunction(Remotes, "GetChatTags")
ensureRemoteEvent(Remotes, "TagsUpdated")
ensureRemoteFunction(Remotes, "GetDevice")
ensureRemoteEvent(Remotes, "ShowDonationGUI")
ensureRemoteEvent(Remotes, "SyncNotification")
ensureRemoteEvent(Remotes, "SendBugReport")
ensureRemoteFunction(Remotes, "GetFollowerCount")
ensureRemoteFunction(Remotes, "GetFollowingCount")
ensureRemoteFunction(Remotes, "GetSocialCounts")
ensureRemoteFunction(Remotes, "GetFriendCountServer")

local SyncRemotes = getOrCreateFolder(ReplicatedStorage, "SyncRemotes")
ensureRemoteFunction(SyncRemotes, "animationStart")
ensureRemoteEvent(SyncRemotes, "startSync")
ensureRemoteEvent(SyncRemotes, "changeSpeed")
ensureRemoteEvent(SyncRemotes, "updateFavoritedAnimationsEvent")
ensureRemoteEvent(SyncRemotes, "RequestSync")
ensureRemoteEvent(SyncRemotes, "StoredAnimations")
ensureRemoteEvent(SyncRemotes, "SyncNotification")

local ConfigRemotes = getOrCreateFolder(ReplicatedStorage, "ConfigRemotes")
ensureRemoteFunction(ConfigRemotes, "LoadSettings")
ensureRemoteEvent(ConfigRemotes, "SaveSetting")
ensureRemoteEvent(ConfigRemotes, "ResetSettings")

local MusicRemotes = getOrCreateFolder(ReplicatedStorage, "MusicRemotes")
ensureRemoteEvent(MusicRemotes, "MusicBroadcast")
ensureRemoteEvent(MusicRemotes, "MusicUpdate")
ensureRemoteFunction(MusicRemotes, "GetPlaylist")
ensureRemoteEvent(MusicRemotes, "DispatchAction")
ensureRemoteEvent(MusicRemotes, "DispatchEvent")
ensureRemoteEvent(MusicRemotes, "RequestSync")

local VIPRemotes = getOrCreateFolder(ReplicatedStorage, "VIPRemotes")
ensureRemoteEvent(VIPRemotes, "ShowIcon")
ensureRemoteEvent(VIPRemotes, "RequestIcon")
ensureRemoteEvent(VIPRemotes, "ResetAvatar")
ensureRemoteEvent(VIPRemotes, "HatTryOn")
ensureRemoteFunction(VIPRemotes, "HatInfo")
ensureRemoteEvent(VIPRemotes, "SetSize")
ensureRemoteEvent(VIPRemotes, "Result")
ensureRemoteEvent(VIPRemotes, "SyncData")

local CarryRemotes = getOrCreateFolder(ReplicatedStorage, "CarryRemotes")
ensureRemoteEvent(CarryRemotes, "CarryRequest")
ensureRemoteEvent(CarryRemotes, "CarryResponse")
ensureRemoteEvent(CarryRemotes, "CarryEnd")

local Message = getOrCreateFolder(ReplicatedStorage, "Message")
ensureRemoteFunction(Message, "CheckAccess")
ensureRemoteEvent(Message, "SendMessage")
ensureRemoteEvent(Message, "ReceiveMessage")

local Gamepass = getOrCreateFolder(ReplicatedStorage, "Gamepass")
ensureRemoteFunction(Gamepass, "ShopRequest")
ensureRemoteEvent(Gamepass, "PlayerDataUpdated")
ensureRemoteEvent(Gamepass, "RefreshRole")

ensureRemoteEvent(ReplicatedStorage, "TitleEvent")
ensureRemoteEvent(ReplicatedStorage, "GiveRoleRemote")
ensureRemoteFunction(ReplicatedStorage, "GetDeveloperProducts")
ensureRemoteFunction(ReplicatedStorage, "BroadcastDonationMessage")
ensureRemoteEvent(ReplicatedStorage, "ReceiveDonationBroadcast")

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

getOrCreateFolder(ReplicatedStorage, "UI")
