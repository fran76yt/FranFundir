--[[
Acceso a TradeSkillMaster
=========================

Única puerta a TSM. TSM publica para otros addons una API (TSM_API, en su
App/API.lua) con la que se pide el valor de una "fuente de precio" o de una
fórmula ("dbmarket", "min(vendorbuy, dbmarket)"...) para un objeto. Aquí se
envuelve para que:

  * sin TSM, o con una fórmula que no vale, se devuelva nil en lugar de dar
    un error de Lua (la API de TSM lanza errores si algo no le gusta);
  * el resto del addon hable de IDs de objeto y no de las cadenas de TSM
    ("i:2770").
]]

local _, ns = ...

local Tsm = {}
ns.Tsm = Tsm

function Tsm.IsAvailable()
    return type(TSM_API) == "table" and type(TSM_API.GetCustomPriceValue) == "function"
end

local function itemString(itemID)
    return "i:" .. itemID
end

-- Precio en cobre de un objeto según una fuente o fórmula de TSM, o nil si
-- no hay (sin datos de ese objeto, sin TSM o fórmula no válida).
function Tsm.Price(source, itemID)
    if not Tsm.IsAvailable() then return nil end
    local ok, value = pcall(TSM_API.GetCustomPriceValue, source, itemString(itemID))
    if ok and type(value) == "number" and value > 0 then return value end
    return nil
end

-- Si TSM acepta una fuente o fórmula. Devuelve true, o false y el motivo.
function Tsm.IsValidSource(source)
    if not Tsm.IsAvailable() then return false, "TradeSkillMaster no está cargado" end
    local ok, valid, reason = pcall(TSM_API.IsCustomPriceValid, source)
    if not ok then return false, tostring(valid) end
    return valid and true or false, reason
end
