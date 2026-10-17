local RunService = game:GetService("RunService")
local LocalizationService = game:GetService("LocalizationService")
local Players = game:GetService("Players")

local Data = require(script.Data)
local Country = require(script.Country)

local COUNTRY_ATTRIBUTE: string = "Country_Code"
local DEFAULT_COUNTRY_CODE: string = "US"
local MAXIMUM_ATTEMPTS: number = 5
local TIMEOUT: number = 5

local CountryService = {}

CountryService.Country = Country
CountryService.__index = CountryService

CountryService._cachedCodes = {} :: {[Player]: string}

function CountryService:_Init(): ()
    for countryCode: string, country: Country in Data do
        country.Code = countryCode

        for key: string, value: string in country do
            country[string.lower(key)] = value
        end
    end

    if RunService:IsClient() then
        self:_InitClient()
    elseif RunService:IsServer() then
        self:_InitServer()
    end
end

function CountryService:_InitServer()
    Players.PlayerAdded:Connect(function(player: Player)
        self:_ServerPlayerAdded(player)
    end)

    Players.PlayerRemoving:Connect(function(player: Player)
        self:_ServerPlayerAdded(player)
    end)

    for _, player: Player in Players:GetPlayers() do
        self:_ServerPlayerAdded(player)
    end
end

function CountryService:_InitClient(): ()
    Players.PlayerAdded:Connect(function(player: Player)
        self:_ClientPlayerAdded(player)
    end)

    Players.PlayerRemoving:Connect(function(player: Player)
        self:_ClientPlayerAdded(player)
    end)

    for _, player: Player in Players:GetPlayers() do
        self:_ClientPlayerAdded(player)
    end
end

function CountryService:GetCountryByCode(countryCode: string): Country
    return Data[countryCode] or Data[DEFAULT_COUNTRY_CODE]
end

function CountryService:GetAllCountries(): {[string]: Country}
    return Data
end

function CountryService:GetMyCountry(): Country?
    if RunService:IsServer() then
        return error(":GetMyCountry() can only be called from a local script", 2)
    end

    return self:GetPlayerCountry(Players.LocalPlayer)
end

function CountryService:GetMyCountryCode(): string
    return self:GetPlayerCountryCode(Players.LocalPlayer)
end

function CountryService:GetPlayerCountryCode(player: Player): string
    return self:GetPlayerCountry(player).Code
end

function CountryService:GetPlayerCountry(player: Player): Country?
    return self:GetCountryByCode(self:_WaitForPlayerCode(player))
end

function CountryService:_ServerPlayerAdded(player: Player): ()
    self._cachedCodes[player] = self:_GetCountryCode(player)
    player:SetAttribute(COUNTRY_ATTRIBUTE, self._cachedCodes[player])
end

function CountryService:_ClientPlayerAdded(player: Player): ()
    local countryCode: string? = player:GetAttribute(COUNTRY_ATTRIBUTE)

    if countryCode then
        self._cachedCodes[player] = countryCode
        return
    end

    player:GetAttributeChangedSignal(COUNTRY_ATTRIBUTE):Once(function()
        self._cachedCodes[player] = player:GetAttribute(COUNTRY_ATTRIBUTE)
    end)
end

function CountryService:_PlayerRemoved(player: Player): ()
    self._cachedCodes[player] = nil
end

function CountryService:_GetCountryCode(player: Player): string
    local finalCode: string? = nil
    local attempts: number = 0

    while not finalCode do
        local success: boolean, code: string? = pcall(function()
            return LocalizationService:GetCountryRegionForPlayerAsync(player)
        end)

        attempts += 1

        if success or attempts >= MAXIMUM_ATTEMPTS then
            if tonumber(code) ~= nil then
                finalCode = DEFAULT_COUNTRY_CODE
            else
                finalCode = code
            end

            break
        end
    end

    return finalCode or DEFAULT_COUNTRY_CODE
end

function CountryService:_WaitForPlayerCode(player: Player): string?
    local timer: number = 0
    repeat
        if not Players:FindFirstChild(player.Name) then
            return nil
        end

        if self._cachedCodes[player] then
            return self._cachedCodes[player]
        end

        timer += task.wait()
    until
        timer >= TIMEOUT

    return nil
end

CountryService:_Init()

export type Country = Country.Country

return CountryService
