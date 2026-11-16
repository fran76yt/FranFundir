--[[
Maquetación del informe
=======================

Convierte el informe de las bolsas (Core/BagReport.lua) en una lista de
bloques, de arriba abajo, que UI/ReportWindow.lua solo tiene que pintar:

  { kind = "summary", cells = { { label, value }, ... } }
      Los totales, en grande: venderlo todo, seguir los consejos, ganas.
  { kind = "section", title, hint }
      Título de un grupo; hint dice qué es la columna de la derecha.
  { kind = "item", id, title, detail, right, rightDetail }
      Un objeto: icono (id), "20 Mena de cobre" y, debajo, el detalle;
      a la derecha el dinero y, debajo, una aclaración.
  { kind = "note", text }
      Un aviso en gris (sin TSM, bolsas vacías, abrir la ventana de minería).

Las secciones siguen el orden en que se hace: los pasos (fundir, hacer
bronce...), lo que se vende al final, lo que hay que comprar, y aparte las
transmutaciones y lo que no tiene precio.

ReportLayout.Blocks(report) no toca la interfaz: así se puede probar.
]]

local _, ns = ...
local Const, Api, Tsm, Recipes, Planner, Prices, PlanText =
    ns.Const, ns.Api, ns.Tsm, ns.Recipes, ns.Planner, ns.Prices, ns.PlanText

local ReportLayout = {}
ns.ReportLayout = ReportLayout

local DOT = " · "

local function note(blocks, text)
    blocks[#blocks + 1] = { kind = "note", text = text }
end

local function section(blocks, title, hint)
    blocks[#blocks + 1] = { kind = "section", title = title, hint = hint }
end

local function gainText(copper)
    return copper and copper > 0 and PlanText.Gain(copper) or ""
end

local function eachPrice(copper)
    return ("a %s cada uno"):format(PlanText.Money(copper))
end

--------------------------------------------------------------------------------
-- Resumen
--------------------------------------------------------------------------------

local function summary(totals)
    return {
        kind = "summary",
        cells = {
            { label = "Venderlo tal cual", value = PlanText.Money(totals.sell) },
            { label = "Siguiendo los consejos", value = PlanText.Money(totals.plan) },
            { label = "Ganas", value = totals.gain > 0 and PlanText.Gain(totals.gain) or "nada más" },
        },
    }
end

--------------------------------------------------------------------------------
-- Pasos
--------------------------------------------------------------------------------

-- De dónde sale lo demás que pide la receta: de lo que llevas, comprado o
-- de las dos cosas.
local function originText(extra)
    if extra.buy == 0 then return "lo llevas" end
    if extra.own == 0 then return "a comprar" end
    return ("llevas %g, compras %g"):format(extra.own, extra.buy)
end

-- "con 10 Lingote de estaño (llevas 4, compras 6) → 20 Lingote de bronce"
local function stepDetail(step)
    local parts = {}
    for _, extra in ipairs(step.extras) do
        parts[#parts + 1] = ("%s (%s)"):format(PlanText.Amount(extra.id, extra.quantity), originText(extra))
    end
    local made = "→ " .. PlanText.Amount(step.made[1], step.made[2])
    if #parts == 0 then return made end
    return "con " .. table.concat(parts, " + ") .. " " .. made
end

-- A la derecha, lo que vale lo que sale (aunque luego se gaste en otra
-- receta: así se ve lo que vale cada lingote del camino).
local function madeValue(step)
    local price = Prices.Sell(step.made[1])
    return price and PlanText.Money(price * step.made[2]) or ""
end

local function stepItem(step)
    return {
        kind = "item", id = step.item,
        title = ("%s: %s"):format(PlanText.RecipeName(step.recipe), PlanText.Amount(step.item, step.used)),
        detail = stepDetail(step),
        right = madeValue(step),
        rightDetail = "",
    }
end

--------------------------------------------------------------------------------
-- Vender, comprar y lo demás
--------------------------------------------------------------------------------

-- Si su plan era fabricar algo pero no llega para una, cuántas faltan.
local function saleDetail(sale)
    local text = eachPrice(sale.price)
    if sale.short then
        text = text .. DOT .. ("faltan %g para %s"):format(sale.short, PlanText.RecipeName(sale.recipe))
    end
    return text
end

local function saleItem(sale)
    return {
        kind = "item", id = sale.id,
        title = PlanText.Amount(sale.id, sale.count),
        detail = saleDetail(sale),
        right = PlanText.Money(sale.total),
        rightDetail = "",
    }
end

local function buyItem(buy)
    return {
        kind = "item", id = buy.id,
        title = PlanText.Amount(buy.id, buy.quantity),
        detail = buy.price and eachPrice(buy.price) or Const.TEXT.NO_PRICE,
        right = buy.cost and PlanText.Money(buy.cost) or "sin precio",
        rightDetail = "",
    }
end

-- La receta con espera vale para unas pocas: se dice por unidad y cuánto
-- deja de más que el plan de siempre.
local function cooldownItem(entry)
    local plan = entry.plan
    local wait = PlanText.Wait(Planner.CooldownRecipe(plan))
    return {
        kind = "item", id = entry.id,
        title = (Api.ItemName(entry.id)),
        detail = PlanText.Steps(plan) .. DOT .. wait,
        right = PlanText.Money(plan.value),
        rightDetail = gainText(plan.value - entry.base),
    }
end

local function noPriceItem(entry)
    return {
        kind = "item", id = entry.id,
        title = PlanText.Amount(entry.id, entry.count),
        detail = Const.TEXT.NO_PRICE,
        right = "", rightDetail = "",
    }
end

--------------------------------------------------------------------------------
-- Secciones
--------------------------------------------------------------------------------

-- Cada sección: de qué parte del informe sale, su título, qué dice la
-- columna de la derecha y cómo se pinta cada fila. Una sección vacía no sale.
local SECTIONS = {
    { key = "steps", title = "Qué hacer, por orden", hint = "Vale lo que sale", item = stepItem },
    { key = "sales", title = "Vender", hint = "Te deja", item = saleItem },
    { key = "buys", title = "Comprar", hint = "Cuesta", item = buyItem },
    { key = "cooldown", title = "Aún mejor, con espera", hint = "Por unidad · de más", item = cooldownItem },
    { key = "noPrice", title = "Sin precio", hint = "", item = noPriceItem },
}

local function addSection(blocks, spec, list)
    if #list == 0 then return end
    section(blocks, spec.title, spec.hint)
    for _, entry in ipairs(list) do blocks[#blocks + 1] = spec.item(entry) end
end

function ReportLayout.Blocks(report)
    local blocks = {}
    if not Tsm.IsAvailable() then
        note(blocks, Const.TEXT.NO_TSM)
        return blocks
    end
    if report.empty then
        note(blocks, "No llevas menas ni lingotes en las bolsas.")
        return blocks
    end
    -- Sin recetas sabidas todo sale "vender": se avisa arriba, antes de
    -- que parezca un consejo de verdad.
    if not Planner.CountsAllRecipes() and not Recipes.HasAnyKnown() then
        note(blocks, Const.TEXT.OPEN_PROFESSION)
    end
    blocks[#blocks + 1] = summary(report.totals)
    for _, spec in ipairs(SECTIONS) do addSection(blocks, spec, report[spec.key]) end
    return blocks
end
