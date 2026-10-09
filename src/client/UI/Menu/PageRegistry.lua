--[[
	PageRegistry.lua
	Tujuan: Pendaftaran halaman modular yang tersedia dalam antarmuka menu utama.
]]

local PageRegistry = {}
local pages = {}

function PageRegistry.RegisterPage(name, pageObject)
	pages[name] = pageObject
end

function PageRegistry.GetPage(name)
	return pages[name]
end

function PageRegistry.GetAllPages()
	return pages
end

return PageRegistry
