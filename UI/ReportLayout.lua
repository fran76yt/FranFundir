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
      Un objeto: icono (id), "20 Mena de cobre" y, debajo, qué hacer;
      a la derecha el dinero y, debajo, lo que ganas.
  { kind = "note", text }
      Un aviso en gris (sin TSM, bolsas vacías, abrir la ventana de minería).

ReportLayout.Blocks(report) no toca la interfaz: así se puede probar.
]]

local _, ns = ...
local Const, Api, Tsm, Recipes, Planner, PlanText =
    ns.Const, ns.Api, ns.Tsm, ns.Recipes, ns.Planner, ns.PlanText

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
-- Una fila por objeto, según el grupo
--------------------------------------------------------------------------------

-- Qué hacer con lo que hay. Si aún no llega para una receta, cuántas faltan.
local function craftDetail(entry)
    local route = entry.route
    if route.final[2] == 0 then
        return ("Faltan %g para la primera: %s"):format(route.per - entry.count, PlanText.Steps(entry.plan))
    end
    local text = PlanText.Steps(entry.plan, route.final[2])
    if route.leftover > 0 then text = text .. DOT .. ("sobran %g"):format(route.leftover) end
    return text
end

local function craftItem(entry)
    return {
        kind = "item", id = entry.id,
        title = PlanText.Amount(entry.id, entry.count),
        detail = craftDetail(entry),
        right = PlanText.Money(entry.planTotal),
        rightDetail = gainText(entry.gain),
    }
end

local function needDetail(need)
    if need.missing == 0 then return ("Ya lo llevas (%g)"):format(need.have) end
    return ("Llevas %g, faltan %g"):format(need.have, need.missing)
end

-- A la derecha, lo que cuesta comprar lo que falta.
local function needCost(need)
    if need.missing == 0 then return "" end
    return need.cost and PlanText.Money(need.cost) or "sin precio"
end

local function needItem(need)
    return {
        kind = "item", id = need.id,
        title = PlanText.Amount(need.id, need.quantity),
        detail = needDetail(need),
        right = needCost(need),
        rightDetail = need.missing > 0 and "comprar" or "",
    }
end

local function sellItem(entry)
    return {
        kind = "item", id = entry.id,
        title = PlanText.Amount(entry.id, entry.count),
        detail = ("Vender a %s cada uno"):format(PlanText.Money(entry.sell)),
        right = PlanText.Money(entry.sellTotal),
        rightDetail = "",
    }
end

-- La receta con espera vale para unas pocas: se dice por unidad y cuánto
-- deja de más que lo de arriba.
local function cooldownItem(entry)
    local plan = entry.cooldown
    local wait = PlanText.Wait(Planner.CooldownRecipe(plan))
    local base = entry.plan and entry.plan.value or 0
    return {
        kind = "item", id = entry.id,
        title = (Api.ItemName(entry.id)),
        detail = PlanText.Steps(plan) .. DOT .. wait,
        right = PlanText.Money(plan.value),
        rightDetail = gainText(plan.value - base),
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
    { key = "craft", title = "Fundir y fabricar", hint = "Te deja · ganas", item = craftItem },
    { key = "needs", title = "Para eso te hace falta", hint = "Cuesta lo que falta", item = needItem },
    { key = "sell", title = "Vender tal cual", hint = "Te deja", item = sellItem },
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
