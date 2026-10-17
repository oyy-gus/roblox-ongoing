local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local SerdesLayer = require(script.Parent.SerdesLayer)

type queueSendPacket = {
	plrs: string | Player | { Player },
	remote: string,
	args: { any },
	replRate: number,
	invokeReply: any?,
	uuid: string?,
}
type queueReceivePacket = { plr: Player, remote: string, args: { any } }

local SendQueue: { queueSendPacket } = {}
local ReceiveQueue: { queueReceivePacket } = {}
local replTicksSignal = {}

local BridgeObjects = {}

local RemoteEvent
local Invoke
local InvokeReply

local function deepCopy<originalType>(tbl): originalType
	local result: originalType = {}
	for key: number, v in tbl do
		if typeof(v) == "table" then
			result[key] = deepCopy(v)
		elseif typeof(v) == "userdata" then
			warn("warning: copying userdata? you should never see this.")
			result[key] = v
		else
			result[key] = v
		end
	end
	return result
end

local ServerBridge = {}
ServerBridge.__index = ServerBridge

function ServerBridge._start(): nil
	RemoteEvent = Instance.new("RemoteEvent")
	RemoteEvent.Name = "RemoteEvent"
	RemoteEvent.Parent = ReplicatedStorage

	Invoke = SerdesLayer.CreateIdentifier("Invoke")
	InvokeReply = SerdesLayer.CreateIdentifier("InvokeReply")

	local replTicks = {}

	RunService.Heartbeat:Connect(function()
		debug.profilebegin("ServerBridge")
		local currentTime = os.clock()

		for _, v in ReceiveQueue do
			for i = 1, #v.args do
				if v.args[i] == SerdesLayer.NilIdentifier then
					v.args[i] = nil
				end
			end

			local obj = BridgeObjects[SerdesLayer.FromCompressed(v.remote)]
			if obj == nil then

				continue
			end
			if v.args[1] == Invoke then
				if obj._onInvoke ~= nil then
					task.spawn(function()
						local args = v.args
						local uuid = args[2]

						table.remove(args, 1)
						table.remove(args, 1)
						table.insert(SendQueue, {
							plrs = v.plr,
							remote = obj._id,
							uuid = uuid,
							invokeReply = true,
							replRate = 60,
							args = { obj._onInvoke(v.plr, unpack(v.args)) },
						})
					end)
				else

					local args = v.args
					local uuid = args[2]

					table.remove(args, 1)
					table.remove(args, 1)
					table.insert(SendQueue, {
						plrs = v.plr,
						remote = obj._id,
						uuid = uuid,
						invokeReply = true,
						replRate = 60,
						args = { "err", "onInvoke has not yet been registered on the server for " .. obj._name },
					})
				end
			else
				debug.profilebegin(string.format("connections_%s", obj._name))

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

							callback(v.plr, table.unpack(result))
						else
							callback(v.plr, table.unpack(v.args))
						end
					end)
				end

				debug.profileend()
			end
		end

		table.clear(ReceiveQueue)

		local toSendAll = {}
		local toSendPlayers = {}
		local remainingQueue = {}
		local passingReplRates = {}

		for i, v in remainingQueue do
			if (currentTime - replTicks[v.replRate]) <= (1 / v.replRate - 0.003) then
				table.insert(SendQueue, v)
				continue
			else
				table.remove(remainingQueue, i)
			end
		end

		for _, v: queueSendPacket in SendQueue do
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

			for i = 1, #v.args do
				if v.args[i] == nil then
					v.args[i] = SerdesLayer.NilIdentifier
				end
			end

			if not v.invokeReply then
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

				if v.plrs == "all" then
					table.insert(toSendAll, tbl)
				elseif typeof(v.plrs) == "table" then
					for _, l in v.plrs do
						if toSendPlayers[l] == nil then
							toSendPlayers[l] = {}
						end

						table.insert(toSendPlayers[l], tbl)
					end
				else
					if toSendPlayers[v.plrs] == nil then
						toSendPlayers[v.plrs] = { tbl }
					else
						table.insert(toSendPlayers[v.plrs], tbl)
					end
				end
			elseif v.invokeReply then
				if toSendPlayers[v.plrs] == nil then
					toSendPlayers[v.plrs] = {}
				end

				local tbl = { v.remote, InvokeReply, v.uuid }

				for _, k in v.args do
					table.insert(tbl, k)
				end

				table.insert(toSendAll, tbl)
			end
		end

		if #toSendAll ~= 0 then
			RemoteEvent:FireAllClients(toSendAll)
		end
		for l, k in toSendPlayers do
			RemoteEvent:FireClient(l, k)
		end
		table.clear(SendQueue)

		for key, _ in passingReplRates do
			passingReplRates[key] = false
		end

		debug.profileend()
	end)

	RemoteEvent.OnServerEvent:Connect(function(plr, tbl)
		for _, v in tbl do
			local args = v
			local remote = args[1]
			table.remove(args, 1)
			local toInsert = {
				remote = remote,
				plr = plr,
				args = args,
			}
			table.insert(ReceiveQueue, toInsert)
		end
	end)

	return nil
end

function ServerBridge._getReplicationStepSignal(rate: number, callback: () -> nil)
	if replTicksSignal[rate] == nil then
		replTicksSignal[rate] = {
			callback,
		}
	else
		table.insert(replTicksSignal[rate], callback)
	end
end

function ServerBridge._returnQueue()
	return SendQueue, ReceiveQueue
end

function ServerBridge._destroy()
	RemoteEvent:Destroy()
end

function ServerBridge.new(remoteName: string)
	assert(type(remoteName) == "string", "[BridgeNet] Remote name must be a string")

	local found = ServerBridge.from(remoteName)
	if found ~= nil then
		return found
	end

	local self = setmetatable({}, ServerBridge)

	self._name = remoteName

	self._onInvoke = nil
	self._connections = {}

	self._replRate = 60

	self._rateLimit = nil
	self._rateHandler = nil
	self._rateInThisMinute = {
		num = 0,
		min = 0,
	}

	self._id = SerdesLayer.CreateIdentifier(remoteName)

	self._outboundMiddleware = {}
	self._inboundMiddleware = {}

	BridgeObjects[self._name] = self
	return self
end

function ServerBridge.from(remoteName: string)
	return BridgeObjects[remoteName]
end

function ServerBridge.waitForBridge(remoteName: string)
	while true do
		local bridge = BridgeObjects[remoteName]
		if bridge then
			return bridge
		end
		task.wait()
	end
end

function ServerBridge:FireTo(plr: Player, ...: any)
	local args: { any } = { ... }
	local toSend: queueSendPacket = {
		plrs = plr,
		remote = self._id,
		args = args,
		replRate = self._replRate,
	}
	table.insert(SendQueue, toSend)
end

function ServerBridge:OnInvoke(callback: (...any) -> nil)
	local function wrappedCallback(...)
		local success, args = pcall(function(...)
			return table.pack(callback(...))
		end, ...)

		if success == true then
			return table.unpack(args)
		else
			return "err", args
		end
	end

	self._onInvoke = wrappedCallback
end

function ServerBridge:FireToAllExcept(blacklistedPlrs: Player | { Player }, ...: any): { Player }
	local toSend = {}
	for _, v: Player in Players:GetPlayers() do
		if typeof(blacklistedPlrs) == "table" then
			if table.find(blacklistedPlrs, v) then
				continue
			end
		else
			if blacklistedPlrs == v then
				continue
			end
		end
		table.insert(toSend, v)
	end

	local toSendPacket: queueSendPacket = {
		plrs = toSend,
		remote = self._id,
		args = { ... },
		replRate = self._replRate,
	}
	table.insert(SendQueue, toSendPacket)

	return toSend :: { Player }
end

function ServerBridge:FireAllInRangeExcept(
	blacklistedPlrs: Player | { Player },
	point: Vector3,
	range: number,
	...: any
)
	local toSend = {}
	for _, v: Player in Players:GetPlayers() do
		if v:DistanceFromCharacter(point) <= range then
			if typeof(blacklistedPlrs) == "table" then
				if table.find(blacklistedPlrs, v) then
					continue
				end
			else
				if blacklistedPlrs == v then
					continue
				end
			end
			table.insert(toSend, v)
		end
	end

	local toSendPacket: queueSendPacket = {
		plrs = toSend,
		remote = self._id,
		args = { ... },
		replRate = self._replRate,
	}
	table.insert(SendQueue, toSendPacket)

	return toSend
end

function ServerBridge:FireAllInRange(point: Vector3, range: number, ...: any): { Player }
	assert(typeof(point) == "Vector3", "[BridgeNet] point must be a Vector3")
	assert(typeof(range) == "number", "[BridgeNet] range must be a number")

	local toSend = {}
	for _, v: Player in Players:GetPlayers() do
		if v:DistanceFromCharacter(point) <= range then
			table.insert(toSend, v)
		end
	end

	local toSendPacket: queueSendPacket = {
		plrs = toSend,
		remote = self._id,
		args = { ... },
		replRate = self._replRate,
	}
	table.insert(SendQueue, toSendPacket)

	return toSend :: { Player }
end

function ServerBridge:FireAll(...: any): nil
	local args: { any } = { ... }
	local toSend: queueSendPacket = {
		plrs = "all",
		remote = self._id,
		args = args,
		replRate = self._replRate,
	}
	table.insert(SendQueue, toSend)
	return nil
end

function ServerBridge:FireToMultiple(plrs: { Player }, ...: any): nil
	assert(type(plrs) == "table", "[BridgeNet] First argument must be a table!")

	local args: { any } = { ... }
	local toSend: queueSendPacket = {
		plrs = plrs,
		remote = self._id,
		args = args,
		replRate = self._replRate,
	}
	table.insert(SendQueue, toSend)
	return nil
end

function ServerBridge:SetInboundMiddleware(middlewareTable: { (...any) -> nil })
	assert(typeof(middlewareTable) == "table", "[BridgeNet] middlewareTable must be a table")
	self._inboundMiddleware = middlewareTable or {}
end

function ServerBridge:SetOutboundMiddleware(middlewareTable: { (...any) -> nil })
	assert(typeof(middlewareTable) == "table", "[BridgeNet] middlewareTable must be a table")
	self._outboundMiddleware = middlewareTable or {}
end

function ServerBridge:Once(func: (...any) -> nil)
	local connection
	connection = self:Connect(function(...)
		connection:Disconnect()
		func(...)
	end)
end

function ServerBridge:Connect(func: (...any) -> nil)
	assert(type(func) == "function", "[BridgeNet] attempt to connect non-function to a Bridge")
	local connectionUUID = SerdesLayer.CreateUUID()
	self._connections[connectionUUID] = func

	local connection = {}

	function connection.Disconnect()
		self._connections[connectionUUID] = nil
		connectionUUID = nil
	end

	return connection
end

function ServerBridge:GetName()
	return self._name
end

function ServerBridge:SetReplicationRate(number)
	self._replRate = number
end

function ServerBridge:Destroy()
	BridgeObjects[self._name] = nil
	SerdesLayer.DestroyIdentifier(self.Name)
	for k, v in self do
		if v.Destroy ~= nil then
			v:Destroy()
		else
			self[k] = nil
		end
	end
	setmetatable(self, nil)
end

export type ServerObject = typeof(ServerBridge.new(""))

return ServerBridge
