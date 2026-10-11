--[[
    ║              GLights Server Handler (BridgeNet Edition)                    ║
    ║     Menangani aksi dari client menggunakan BridgeNet                       ║
    ╚═══════════════════════════════════════════════════════════════════════════╝

    Letakkan script ini di ServerScriptService.
    Pastikan modul Bridges sudah ada di ReplicatedStorage.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Require shared bridges
local Bridges = require(ReplicatedStorage:WaitForChild("Bridges"))

-- Require GLights Panel module
local GLights = require(workspace:WaitForChild("GLights").Scripts.Panels.Panel)

-- ═══════════════════════════════════════════════════════════════════════════════
--                     BRIDGE: GLightsRun (Menjalankan fungsi per folder)
-- ═══════════════════════════════════════════════════════════════════════════════
Bridges.GLightsRun:Connect(function(player, folderName, action, ...)
	GLights.Run(folderName, action, ...)
end)

-- ═══════════════════════════════════════════════════════════════════════════════
--                     BRIDGE: GLightsAction (Menjalankan aksi pada Panel)
-- ═══════════════════════════════════════════════════════════════════════════════
Bridges.GLightsAction:Connect(function(player, panelModel, ...)
	-- panelModel dikirim sebagai referensi Instance
	local panelData = GLights._AllPanelsByModel and GLights._AllPanelsByModel[panelModel]
	if not panelData then
		return
	end
	if not panelData.Whitelist:isWhitelisted(player) then
		return
	end
	panelData:HandleAction(player, ...)
end)

-- ═══════════════════════════════════════════════════════════════════════════════
--                     BRIDGE: WhitelistCheck (Cek whitelist status)
-- ═══════════════════════════════════════════════════════════════════════════════
Bridges.WhitelistCheck:Connect(function(player, panelModel)
	local panelData = GLights._AllPanelsByModel and GLights._AllPanelsByModel[panelModel]
	if not panelData then
		Bridges.WhitelistCheck:FireTo(player, panelModel, false)
		return
	end
	local isWhitelisted = panelData.Whitelist:isWhitelisted(player)
	Bridges.WhitelistCheck:FireTo(player, panelModel, isWhitelisted)
end)

print("[GLights Server] ✅ BridgeNet Handler Ready!")
