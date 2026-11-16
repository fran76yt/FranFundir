--[[
Precios
=======

Lo que vale cada objeto para el cálculo, con los precios de TSM:

  Prices.Sell(id)   lo que te queda por unidad al venderla: en la casa de
                    subastas, menos su comisión, o al vendedor si da más
  Prices.Buy(id)    lo que cuesta comprar una unidad (lo que pide una receta
                    además del material: el carbón del acero...)

Las fuentes de TSM se pueden cambiar (/fundir venta, /fundir compra) y se
guardan solo si no son las de por defecto.
]]

local _, ns = ...
local Const, Util, Api, Storage, Tsm = ns.Const, ns.Util, ns.Api, ns.Storage, ns.Tsm

local Prices = {}
ns.Prices = Prices

--------------------------------------------------------------------------------
-- Fuentes de precio
--------------------------------------------------------------------------------

-- which = "sell" o "buy".
local SETTING = { sell = "sellSource", buy = "buySource" }
local DEFAULT = { sell = Const.PRICE.SELL, buy = Const.PRICE.BUY }

function Prices.Source(which)
    return Storage.Settings()[SETTING[which]] or DEFAULT[which]
end

-- Cambia una fuente si TSM la acepta. Devuelve true, o false y el motivo.
-- Con una vacía vuelve a la de por defecto.
function Prices.SetSource(which, source)
    source = source ~= "" and source or DEFAULT[which]
    local valid, reason = Tsm.IsValidSource(source)
    if not valid then return false, reason end
    Util.SetOverride(Storage.Settings(), SETTING[which], source, DEFAULT[which])
    Util.Fire(Const.MSG.SETTINGS_CHANGED)
    return true
end

--------------------------------------------------------------------------------
-- Precios
--------------------------------------------------------------------------------

local function afterCut(price)
    return math.floor(price * (1 - Const.AH_CUT))
end

function Prices.Sell(id)
    local market = Tsm.Price(Prices.Source("sell"), id)
    local vendor = Api.SellPrice(id)
    local auction = market and afterCut(market)
    if auction and (not vendor or auction >= vendor) then return auction end
    if vendor and vendor > 0 then return vendor end
    return auction
end

function Prices.Buy(id)
    return Tsm.Price(Prices.Source("buy"), id)
end
