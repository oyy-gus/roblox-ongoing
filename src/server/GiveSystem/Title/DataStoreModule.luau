-- ============================================================
-- DataStoreModule
-- Place in: ServerScriptService > GiveSystem(Folder) > Title(Folder) > DataStoreModule(ModuleScript)
-- ============================================================

local DataStoreService = game:GetService("DataStoreService")

local DataStoreModule = {}
local TitleStore = DataStoreService:GetDataStore("PlayerCustomTitle_v1")

function DataStoreModule:Set(key, value)
	local ok, err = pcall(function()
		TitleStore:SetAsync(key, value)
	end)
	if not ok then
		warn("[DataStoreModule] SetAsync error:", err)
	end
end

function DataStoreModule:Remove(key)
	local ok, err = pcall(function()
		TitleStore:RemoveAsync(key)
	end)
	if not ok then
		warn("[DataStoreModule] RemoveAsync error:", err)
	end
end

function DataStoreModule:Get(key)
	local ok, res = pcall(function()
		return TitleStore:GetAsync(key)
	end)
	if ok then return res end
	warn("[DataStoreModule] GetAsync failed for key:", key)
	return nil
end

function DataStoreModule:SaveTitlesForUserId(userId, titlesTable)
	local key = "title_" .. tostring(userId)

	if titlesTable then
		for i = 1, 14 do
			local v = titlesTable[i]
			if v and v.Text and v.Text ~= "" then
				self:Set(key, titlesTable)
				return
			end
		end
	end

	self:Remove(key)
end

function DataStoreModule:LoadTitlesForUserId(userId)
	return self:Get("title_" .. tostring(userId)) or {}
end

return DataStoreModule
