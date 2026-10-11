--[[
    ╔═══════════════════════════════════════════════════════════════════════════╗
    ║                    GLights Shared Bridges (BridgeNet)                      ║
    ║     Modul shared yang digunakan oleh Server dan Client                      ║
    ╚═══════════════════════════════════════════════════════════════════════════╝
    
    Letakkan modul ini di ReplicatedStorage agar bisa di-require dari kedua sisi.
    Pastikan BridgeNet sudah ada di ReplicatedStorage.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local BridgeNet = require(ReplicatedStorage:WaitForChild("BridgeNet"))

local Bridges = BridgeNet.CreateBridgeTree({
	-- Bridge utama untuk mengirim aksi lighting dari client ke server
	GLightsAction = BridgeNet.Bridge({
		ReplicationRate = 60,
	}),

	-- Bridge untuk mengirim aksi langsung ke Panel (fire command)
	GLightsRun = BridgeNet.Bridge({
		ReplicationRate = 60,
	}),

	-- Bridge untuk whitelist status (server -> client)
	WhitelistStatus = BridgeNet.Bridge({
		ReplicationRate = 60,
	}),

	-- Bridge untuk request whitelist check (client -> server, server -> client reply)
	WhitelistCheck = BridgeNet.Bridge({
		ReplicationRate = 60,
	}),
})

return Bridges
