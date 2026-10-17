local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local SerdesLayer = require(script.Parent.SerdesLayer)

local RemoteEvent: RemoteEvent
local Invoke: string
local InvokeReply: string

type sendPacketQueue = { remote: string, args: { any }, requestType: string, replRate: number, uuid: string? }
type receivePacketQueue = { remote: string, args: { any } }

local SendQueue: { sendPacketQueue } = {}
local ReceiveQueue: { receivePacketQueue } = {}

local BridgeObjects = {}

local threads: { thread? } = {}
local replTicksSignal = {}

local ClientBridge = {}
ClientBridge.__index = ClientBridge

function ClientBridge._start()
	RemoteEvent = ReplicatedStorage:WaitForChild("RemoteEvent")

	Invoke = SerdesLayer.FromIdentifier("Invoke")
	InvokeReply = SerdesLayer.FromIdentifier("InvokeReply")

	local passingReplRates = {}

	RunService.Heartbeat:Connect(function()
		debug.profilebegin("ClientBridge")
		local currentTime = os.clock()

		local toSend = {}
		local replTicks = {}
		local remainingQueue = {}

		for i, v in remainingQueue do
			if (currentTime - replTicks[v.replRate]) <= (1 / v.replRate - 0.003) then
				table.insert(SendQueue, v)
				continue
			else
				table.remove(remainingQueue, i)
			end
		end

		for _, v: sendPacketQueue in SendQueue do
			if replTicks[v.replRate] then

				if (currentTime - replTicks[v.replRate]) <= (1 / v.replRate - 0.003) then
					passingReplRates[v.replRate] = true
					if not passingReplRates[v.replRate] then
						table.insert(remainingQueue, v)
						continue
					end
				end
			end

			if replTicksSignal[v.replRate] == nil then
				replTicksSignal[v.replRate] = {}
			else
				for _, callback: () -> nil in replTicksSignal[v.replRate] do
					task.spawn(callback)
				end
			end

			replTicks[v.replRate] = currentTime

			for i = 1, #v.args do
				if v.args[i] == nil then
					v.args[i] = SerdesLayer.NilIdentifier
				end
			end

			if v.requestType == "invoke" then
				local tbl = { v.remote, Invoke, v.uuid }

				for _, k in v.args do
					table.insert(tbl, k)
				end

				table.insert(toSend, tbl)
			elseif v.requestType == "send" then
				local tbl = { v.remote }
				local bridgeObj = BridgeObjects[SerdesLayer.FromCompressed(v.remote)]

				if not (#bridgeObj._outboundMiddleware == 0) then
					local result
					for _, func in bridgeObj._outboundMiddleware do
						if result then
							local potential = { func(table.unpack(result)) }
							if #potential == 0 then
								continue
							end
							result = potential
						else
							result = { func(table.unpack(v.args)) }
						end
					end

					if result == nil then
						result = v.args
					end

					for _, k in result do
						table.insert(tbl, k)
					end
				else
					for _, k in v.args do
						table.insert(tbl, k)
					end
				end

				table.insert(toSend, tbl)
			end
		end
		if #toSend ~= 0 then
			RemoteEvent:FireServer(toSend)
		end
		SendQueue = remainingQueue

		for _, v in ReceiveQueue do
			local args = v.args
			local argCount = #args

			local obj = BridgeObjects[SerdesLayer.FromCompressed(v.remote)]
			if obj == nil then
				continue
			end

			for i = 1, #args do
				if args[i] == SerdesLayer.NilIdentifier then
					args[i] = nil
				end
			end

			if args[1] ~= InvokeReply then
				for _, callback in obj._connections do

					task.spawn(function()
						if #obj._inboundMiddleware ~= 0 then
							local result
							for _, func in obj._inboundMiddleware do
								if result then
									local potential = { func(table.unpack(result)) }
									if #potential == 0 then
										continue
									end
									result = potential
								else
									result = { func(table.unpack(v.args)) }
								end
							end

							if result == nil then
								result = v.args
							end

							callback(table.unpack(result))
						else
							callback(table.unpack(v.args))
						end
					end)
				end
			elseif args[1] == InvokeReply then
				local uuid = SerdesLayer.UnpackUUID(args[2])
				table.remove(args, 1)
				table.remove(args, 1)
				argCount -= 2
				task.spawn(threads[uuid], unpack(args, 1, argCount))
				threads[uuid] = nil
			end
		end

		ReceiveQueue = {}

		debug.profileend()
	end)

	RemoteEvent.OnClientEvent:Connect(function(tbl)
		for _, v in tbl do
			local params = v
			local remote = params[1]
			table.remove(params, 1)
			table.insert(ReceiveQueue, {
				remote = remote,
				args = params,
			})
		end
	end)
end

function ClientBridge.new(remoteName: string)
	assert(type(remoteName) == "string", "[BridgeNet] remote name must be a string")

	local found = ClientBridge.from(remoteName)
	if found ~= nil then
		return found
	end

	local self = setmetatable({}, ClientBridge)

	self._name = remoteName
	self._connections = {}

	self._replRate = 60

	self._inboundMiddleware = {}
	self._outboundMiddleware = {}

	self._id = SerdesLayer.FromIdentifier(self._name)
	if self._id == nil then
		task.spawn(function()
			local timer = 0
			local nextOutput = timer + 0.1
			repeat
				timer += task.wait()
				self._id = SerdesLayer.FromIdentifier(self._name)
				if timer > nextOutput then
					nextOutput += 0.1
					print("[BridgeNet] waiting for (" .. self._name .. ") to be replicated to the client")
				end
			until self._id ~= nil or timer >= 10
		end)
	end

	BridgeObjects[self._name] = self
	return self
end

function ClientBridge._getReplicationStepSignal(rate: number, callback: () -> nil)
	if replTicksSignal[rate] == nil then
		replTicksSignal[rate] = {
			callback,
		}
	else
		table.insert(replTicksSignal[rate], callback)
	end
end

function ClientBridge.from(remoteName: string)
	assert(type(remoteName) == "string", "[BridgeNet] Remote name must be a string")
	return BridgeObjects[remoteName]
end

function ClientBridge.waitForBridge(remoteName: string)
	while not BridgeObjects[remoteName] do
		task.wait()
	end
	return BridgeObjects[remoteName]
end

function ClientBridge._returnQueue()
	return SendQueue, ReceiveQueue
end

function ClientBridge:Fire(...: any)
	if self._id == nil then
		self._id = SerdesLayer.FromIdentifier(self._name)
	end
	table.insert(SendQueue, {
		remote = self._id,
		requestType = "send",
		args = { ... },
		replRate = self._replRate,
	})
end

function ClientBridge:InvokeServerAsync(...: any)
	if self._id == nil then
		self._id = SerdesLayer.FromIdentifier(self._name)
	end

	local thread = coroutine.running()
	local uuid = SerdesLayer.CreateUUID()

	threads[uuid] = thread

	table.insert(SendQueue, {
		remote = self._id,
		requestType = "invoke",
		uuid = SerdesLayer.PackUUID(uuid),
		args = { ... },
		replRate = self._replRate,
	})

	local response = { coroutine.yield() }
	if response[1] == "err" then
		error(response[2], 2)
	end

	return table.unpack(response)
end

function ClientBridge:Connect(func: (...any) -> nil)
	assert(type(func) == "function", "[BridgeNet] Attempt to connect non-function to a Bridge")
	local connectionUUID = SerdesLayer.CreateUUID()
	self._connections[connectionUUID] = func

	local connection = {}

	function connection.Disconnect()
		self._connections[connectionUUID] = nil
		connectionUUID = nil
	end

	return connection
end

function ClientBridge:GetName()
	return self._name
end

function ClientBridge:Once(func: (...any) -> nil)
	local connection
	connection = self:Connect(function(...)
		connection:Disconnect()
		func(...)
	end)
end

function ClientBridge:SetReplicationRate(replRate: number)
	assert(typeof(replRate) == "number", "[BridgeNet] replication rate must be a number")
	self._replRate = replRate
end

function ClientBridge:SetOutboundMiddleware(middlewareTbl: { (plr: Player, ...any) -> ...any })
	assert(typeof(middlewareTbl) == "table", "[BridgeNet] outbound middleware must be a table")
	self._outboundMiddleware = middlewareTbl
end

function ClientBridge:SetInboundMiddleware(middlewareTbl: { (plr: Player, ...any) -> ...any })
	assert(typeof(middlewareTbl) == "table", "[BridgeNet] inbound middleware must be a table")
	self._inboundMiddleware = middlewareTbl
end

function ClientBridge:Destroy()
	BridgeObjects[self._name] = nil
	for k, v in self do
		if v.Destroy ~= nil then
			v:Destroy()
		else
			self[k] = nil
		end
	end
	setmetatable(self, nil)
end

export type ClientObject = typeof(ClientBridge.new(""))

return ClientBridge
