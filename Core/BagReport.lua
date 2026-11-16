--[[
Informe de lo que llevas
========================

Mira las menas y lingotes de las bolsas y dice qué hacer con todo junto
(Core/Production.lua): lo que llevas de un material sirve para la receta de
otro (tus lingotes de estaño, para el bronce del cobre) y solo se compra lo
que falta.

  steps     lo que hay que hacer, por orden (los pasos de Production)
  sales     lo que se vende al final: { id, count, price, total, short,
            recipe }, lo que más deja arriba. short: cuántos faltan para
            la receta de su plan (recipe), si no llega para una
  buys      lo que hay que comprar: { id, quantity, price, cost }
  noPrice   lo que queda sin precio de TSM: { id, count }
  cooldown  materiales que dejan aún más con una receta con espera
            (transmutar), por unidad: { id, plan, base }. Aparte porque no
            sirve para todo el montón
  totals    sell: venderlo todo tal cual; plan: seguir los consejos (lo que
            se vende al final menos lo que se compra); gain: la diferencia

BagReport.Build() no toca la interfaz: así se puede probar.
]]

local _, ns = ...
local Api, Data, Planner, Prices, Production = ns.Api, ns.Data, ns.Planner, ns.Prices, ns.Production

local BagReport = {}
ns.BagReport = BagReport

-- Materiales que hay en las bolsas, en el orden de Data.MATERIALS.
local function carriedMaterials()
    local carried = {}
    for _, id in ipairs(Data.MATERIALS) do
        local count = Api.ItemCount(id)
        if count > 0 then carried[#carried + 1] = { id, count } end
    end
    return carried
end

--------------------------------------------------------------------------------
-- Qué vender y qué comprar
--------------------------------------------------------------------------------

local function byTotal(a, b) return a.total > b.total end

-- Lo que queda en el montón: con precio se vende; sin él, se dice.
local function salesOf(state)
    local sales, noPrice = {}, {}
    for _, id in ipairs(state.order) do
        local count = state.pool[id]
        if count > 0 then
            local price = Prices.Sell(id)
            if price then
                sales[#sales + 1] = {
                    id = id, count = count, price = price, total = price * count,
                    short = Production.Short(state, id), recipe = Production.RecipeOf(state, id),
                }
            else
                noPrice[#noPrice + 1] = { id = id, count = count }
            end
        end
    end
    table.sort(sales, byTotal)
    return sales, noPrice
end

-- Lo que hay que comprar, en el orden en que lo piden los pasos.
local function buysOf(state)
    local buys, seen = {}, {}
    for _, step in ipairs(state.steps) do
        for _, extra in ipairs(step.extras) do
            local id = extra.id
            if state.bought[id] and not seen[id] then
                seen[id] = true
                local price = Prices.Buy(id)
                local quantity = state.bought[id]
                buys[#buys + 1] = { id = id, quantity = quantity, price = price, cost = price and price * quantity }
            end
        end
    end
    return buys
end

-- Materiales que dejan aún más con una receta con espera.
local function cooldownsOf(carried)
    local list = {}
    for _, entry in ipairs(carried) do
        local compare = Planner.Compare(entry[1])
        if compare.cooldown then
            list[#list + 1] = { id = entry[1], plan = compare.cooldown, base = compare.bulk and compare.bulk.value or 0 }
        end
    end
    return list
end

--------------------------------------------------------------------------------
-- Totales
--------------------------------------------------------------------------------

local function sellValue(id, count)
    return (Prices.Sell(id) or 0) * count
end

-- Venderlo todo tal cual: los materiales y lo que se gasta de las bolsas
-- sin ser material (el carbón que llevas también se podría vender).
local function sellTotal(carried, state)
    local total = 0
    for _, entry in ipairs(carried) do total = total + sellValue(entry[1], entry[2]) end
    for id, count in pairs(state.taken) do total = total + sellValue(id, count) end
    return total
end

local function planTotal(sales, buys)
    local total = 0
    for _, sale in ipairs(sales) do total = total + sale.total end
    for _, buy in ipairs(buys) do total = total - (buy.cost or 0) end
    return total
end

--------------------------------------------------------------------------------
-- Informe
--------------------------------------------------------------------------------

function BagReport.Build()
    local carried = carriedMaterials()
    local state = Production.Run(carried)
    local sales, noPrice = salesOf(state)
    local buys = buysOf(state)
    local sell, plan = sellTotal(carried, state), planTotal(sales, buys)
    return {
        empty = #carried == 0,
        steps = state.steps,
        sales = sales,
        buys = buys,
        noPrice = noPrice,
        cooldown = cooldownsOf(carried),
        totals = { sell = sell, plan = plan, gain = plan - sell },
    }
end
