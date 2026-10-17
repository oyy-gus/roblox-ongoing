local RunService = game:GetService("RunService")

local SerdesLayer = require(script.SerdesLayer)
local ServerBridge = require(script.ServerBridge)
local ClientBridge = require(script.ClientBridge)
local CreateBridgeTree = require(script.CreateBridgeTree)
local Bridge = require(script.Bridge)

local isServer = RunService:IsServer()

export type ServerBridge = ServerBridge.ServerObject
export type ClientBridge = ClientBridge.ClientObject

export type Bridge = ServerBridge | ClientBridge

script.Destroying:Connect(function()
	SerdesLayer._destroy()
	if isServer then
		ServerBridge._destroy()
	end
end)

SerdesLayer._start()
if isServer then
	ServerBridge._start()
else
	ClientBridge._start()
end

return {
	CreateBridgeTree = CreateBridgeTree,
	Bridge = Bridge,

	Identifiers = function(tbl: { string })
		local ReturnValue = {}

		for _, v in tbl do
			ReturnValue[v] = SerdesLayer.CreateIdentifier(v)
		end

		return ReturnValue :: { [string]: string }
	end,

	CreateIdentifier = SerdesLayer.CreateIdentifier,
	DestroyIdentifier = SerdesLayer.DestroyIdentifier,

	CreateUUID = SerdesLayer.CreateUUID,
	PackUUID = SerdesLayer.PackUUID,
	UnpackUUID = SerdesLayer.UnpackUUID,

	DictionaryToTable = SerdesLayer.DictionaryToTable,

	ReplicationStep = function(rate: number, func: () -> nil)
		if isServer then
			return ServerBridge._getReplicationStepSignal(rate, func)
		else
			return ClientBridge._getReplicationStepSignal(rate, func)
		end
	end,

	GetQueue = function()
		if isServer then
			local send, receive = ServerBridge._returnQueue()
			return send, receive
		else
			local send, receive = ClientBridge._returnQueue()
			return send, receive
		end
	end,

	CreateBridge = function(str)
		if isServer then
			return ServerBridge.new(str)
		else
			return ClientBridge.new(str)
		end
	end,
}
