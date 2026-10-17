local Country = {}
Country.__index = Country

Country.Code = ""

Country.Name = ""

Country.Emoji = ""

Country.Decal = ""

function Country.new(): Country
    local self = setmetatable({}, Country)

    self.name = ""
    self.emoji = ""
    self.decal = ""

    return self
end

export type Country = typeof(Country)

return Country
