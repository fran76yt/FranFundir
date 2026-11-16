--[[
Informe de lo que llevas
========================

Mira las menas y lingotes de las bolsas y dice qué hacer con cada uno,
agrupado para leerlo de un vistazo:

  craft     lo que deja más fundido o hecho otra cosa
  sell      lo que mejor se vende tal cual
  noPrice   lo que TSM aún no sabe valorar
  cooldown  lo que deja aún más con una receta con espera (transmutar),
            aparte porque no sirve para todo el montón
  needs     lo demás que piden las recetas de "craft", sumado: cuánto hace
            falta, cuánto llevas y cuánto cuesta comprar lo que falta
  totals    sell: venderlo todo tal cual; plan: seguir los consejos;
            gain: lo que ganas con ello (solo de lo que se puede comparar)

Cada material es una entrada { id, count, sell, plan, cooldown, sellTotal,
planTotal, gain, route }: sell y plan por unidad (Planner.Compare), los
totales por lo que llevas y route, las cantidades de verdad
(Planner.Quantities).

BagReport.Build() no toca la interfaz: así se puede probar.
]]

local _, ns = ...
local Api, Data, Planner, Prices = ns.Api, ns.Data, ns.Planner, ns.Prices

local BagReport = {}
ns.BagReport = BagReport

--------------------------------------------------------------------------------
-- Entradas
--------------------------------------------------------------------------------

local function entryFor(id, count)
    local compare = Planner.Compare(id)
    local plan, sell = compare.bulk, compare.sell
    local crafts = plan and Planner.FirstRecipe(plan) ~= nil
    return {
        id = id,
        count = count,
        sell = sell,
        plan = plan,
        cooldown = compare.cooldown,
        sellTotal = sell and sell * count,
        planTotal = plan and plan.value * count,
        gain = crafts and sell and (plan.value - sell) * count or nil,
        route = crafts and Planner.Quantities(plan, count) or nil,
    }
end

-- Materiales que hay en las bolsas, en el orden de Data.MATERIALS.
local function carriedEntries()
    local entries = {}
    for _, id in ipairs(Data.MATERIALS) do
        local count = Api.ItemCount(id)
        if count > 0 then entries[#entries + 1] = entryFor(id, count) end
    end
    return entries
end

local function groupOf(entry)
    if not entry.plan then return "noPrice" end
    return entry.route and "craft" or "sell"
end

-- Lo que más deja, arriba.
local function byGain(a, b) return (a.gain or 0) > (b.gain or 0) end
local function bySellTotal(a, b) return (a.sellTotal or 0) > (b.sellTotal or 0) end

--------------------------------------------------------------------------------
-- Lo que hace falta comprar
--------------------------------------------------------------------------------

-- Suma lo que piden todas las recetas, por objeto.
local function sumNeeds(entries)
    local byItem, order = {}, {}
    for _, entry in ipairs(entries) do
        for _, need in ipairs(entry.route.needs) do
            local id, quantity = need[1], need[2]
            if quantity > 0 then
                if not byItem[id] then order[#order + 1] = id end
                byItem[id] = (byItem[id] or 0) + quantity
            end
        end
    end
    return byItem, order
end

-- Lo que falta se compra a precio de compra (nil si TSM no lo sabe).
local function needEntry(id, quantity)
    local have = Api.ItemCount(id)
    local missing = math.max(0, quantity - have)
    local price = Prices.Buy(id)
    return { id = id, quantity = quantity, have = have, missing = missing, cost = price and price * missing }
end

local function needsFor(entries)
    local byItem, order = sumNeeds(entries)
    local needs = {}
    for i, id in ipairs(order) do needs[i] = needEntry(id, byItem[id]) end
    return needs
end

--------------------------------------------------------------------------------
-- Informe
--------------------------------------------------------------------------------

local function totalsOf(entries)
    local totals = { sell = 0, plan = 0, gain = 0 }
    for _, entry in ipairs(entries) do
        totals.sell = totals.sell + (entry.sellTotal or 0)
        totals.plan = totals.plan + (entry.planTotal or 0)
        totals.gain = totals.gain + (entry.gain or 0)
    end
    return totals
end

function BagReport.Build()
    local entries = carriedEntries()
    local report = { craft = {}, sell = {}, noPrice = {}, cooldown = {}, empty = #entries == 0 }
    for _, entry in ipairs(entries) do
        local group = report[groupOf(entry)]
        group[#group + 1] = entry
        if entry.cooldown then report.cooldown[#report.cooldown + 1] = entry end
    end
    table.sort(report.craft, byGain)
    table.sort(report.sell, bySellTotal)
    report.needs = needsFor(report.craft)
    report.totals = totalsOf(entries)
    return report
end
