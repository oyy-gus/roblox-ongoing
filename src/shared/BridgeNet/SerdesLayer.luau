--!strict
local HttpService = game:GetService("HttpService")
local ReplicatedStorage: ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService: RunService = game:GetService("RunService")

local receiveDict: { [string]: string? } = {}
local sendDict: { [string]: string? } = {}
local numOfSerials: number = 0

local SerdesLayer = {}

local AutoSerde: Folder = nil
local isServer = RunService:IsServer()

type toSend = string

SerdesLayer.NilIdentifier = "null"

local function fromHex(toConvert: string): string
	return string.gsub(toConvert, "..", function(cc)
		return string.char(tonumber(cc, 16))
	end) :: string
end

local function toHex(toConvert: string): string
	return string.gsub(toConvert, ".", function(c)
		return string.format("%02X", string.byte(c :: any))
	end) :: string
end

function SerdesLayer._start()
	if RunService:IsClient() then
		AutoSerde = ReplicatedStorage:WaitForChild("AutoSerde")
		for _, v in AutoSerde:GetChildren() do
			local strValue = v :: StringValue
			sendDict[strValue.Name] = strValue.Value
			receiveDict[strValue.Value] = strValue.Name
		end
		AutoSerde.ChildAdded:Connect(function(child: Instance)
			local strValue = child :: StringValue
			sendDict[strValue.Name] = strValue.Value
			receiveDict[strValue.Value] = strValue.Name
		end)
		AutoSerde.ChildRemoved:Connect(function(child: Instance)
			local strValue = child :: StringValue
			sendDict[strValue.Name] = nil
			receiveDict[strValue.Value] = nil
		end)
	else
		AutoSerde = Instance.new("Folder")
		AutoSerde.Name = "AutoSerde"
		AutoSerde.Parent = ReplicatedStorage
	end
end

function SerdesLayer._destroy()
	AutoSerde:Destroy()
end

function SerdesLayer.CreateIdentifier(id: string): string
	assert(type(id) == "string", "ID must be a string")

	if not sendDict[id] and not isServer then
		return SerdesLayer.WaitForIdentifier(id)
	elseif sendDict[id] and not isServer then
		return sendDict[id]
	end

	if numOfSerials >= 65536 then
		error("Over the identification cap: " .. id)
	end
	numOfSerials += 1

	local StringValue: StringValue = Instance.new("StringValue")
	StringValue.Name = id
	StringValue.Value = string.pack("H", numOfSerials)
	StringValue.Parent = AutoSerde

	sendDict[id] = StringValue.Value
	receiveDict[StringValue.Value] = id

	return StringValue.Value
end

function SerdesLayer.WaitForIdentifier(id: string): string
	while sendDict[id] == nil do
		task.wait()
	end
	return sendDict[id]
end

function SerdesLayer.FromCompressed(compressed: string)
	return receiveDict[compressed]
end

function SerdesLayer.FromIdentifier(identifier: string)
	return sendDict[identifier]
end

function SerdesLayer.DestroyIdentifier(id: string): nil
	assert(isServer, "You cannot destroy identifiers on the client.")
	assert(type(id) == "string", "ID must be a string")

	receiveDict[sendDict[id]] = nil
	sendDict[id] = nil

	numOfSerials -= 1

	AutoSerde:FindFirstChild(id):Destroy()
	return nil
end

function SerdesLayer.CreateUUID(): string
	return string.gsub(HttpService:GenerateGUID(false), "-", "") :: string
end

function SerdesLayer.PackUUID(uuid: string): string
	assert(typeof(uuid) == "string", "[BridgeNet] uuid must be a string")
	return fromHex(uuid)
end

function SerdesLayer.UnpackUUID(uuid: string): string
	assert(typeof(uuid) == "string", "[BridgeNet] uuid must be a string")
	return toHex(uuid)
end

function SerdesLayer.DictionaryToTable(dict: { [string]: any })
	assert(typeof(dict) == "table", "[BridgeNet] dict must be a dictionary")
	assert(getmetatable(dict) == nil, "[BridgeNet] Passed dictionary may not have a metatable")

	local keys = {}
	for key, _ in dict do
		table.insert(keys, key)
	end

	table.sort(keys, function(a, b)
		return string.lower(a) < string.lower(b)
	end)

	local toReturn = {}
	for _, v in keys do
		table.insert(toReturn, dict[v])
	end

	return toReturn
end

return SerdesLayer
