--[[
Líneas en el tooltip de menas y lingotes
========================================

Al pasar el ratón por un material de Data.MATERIALS, se añade al tooltip:

  FranFundir
  Vender: 45p
  Mejor: Cobre fundido › Bronce fundido › vender Lingote de bronce — 62p (+17p)
  Con espera (cada 1 h): Transmutar: hierro a oro › vender Lingote de oro — 1o (+40p)

Todo por unidad y con la comisión de la casa de subastas descontada. Si
venderlo es lo mejor, lo dice. Sin TSM, o sin precios de ese objeto, lo dice
en lugar de calcular.

ItemTooltip.Lines(id) devuelve las líneas sin tocar ningún tooltip: así se
pueden probar y reutilizar.
]]

local _, ns = ...
local Const, Api, Tsm, Recipes, Planner, PlanText =
    ns.Const, ns.Api, ns.Tsm, ns.Recipes, ns.Planner, ns.PlanText
local T = Const.TOOLTIP

local ItemTooltip = {}
ns.ItemTooltip = ItemTooltip

local function line(text, color)
    return { text = text, color = color or T.TEXT_COLOR }
end

-- "Pasos — valor (+ganancia)". La ganancia, solo si hay precio de venta.
local function planLine(prefix, plan, sell)
    local text = ("%s: %s — %s"):format(prefix, PlanText.Steps(plan), PlanText.Money(plan.value))
    if sell then text = text .. " (" .. PlanText.Gain(plan.value - sell) .. ")" end
    return line(text)
end

local function bestLines(lines, compare)
    local bulk = compare.bulk
    if bulk and Planner.FirstRecipe(bulk) then
        lines[#lines + 1] = planLine("Mejor", bulk, compare.sell)
    else
        lines[#lines + 1] = line("Mejor: venderlo tal cual")
    end
    if compare.cooldown then
        local wait = PlanText.Wait(Planner.CooldownRecipe(compare.cooldown))
        lines[#lines + 1] = planLine(("Con espera (%s)"):format(wait), compare.cooldown, compare.sell)
    end
end

function ItemTooltip.Lines(id)
    if not Recipes.IsMaterial(id) then return {} end
    local lines = { line(Const.WINDOW.TITLE, T.TITLE_COLOR) }
    if not Tsm.IsAvailable() then
        lines[#lines + 1] = line("Sin precios: hace falta TradeSkillMaster.", T.HINT_COLOR)
        return lines
    end
    local compare = Planner.Compare(id)
    if not compare.sell and not compare.bulk then
        lines[#lines + 1] = line("TSM aún no tiene precio de esto.", T.HINT_COLOR)
        return lines
    end
    if compare.sell then lines[#lines + 1] = line("Vender: " .. PlanText.Money(compare.sell)) end
    bestLines(lines, compare)
    if not Planner.CountsAllRecipes() and not Recipes.HasAnyKnown() then
        lines[#lines + 1] = line("Abre la ventana de minería una vez para que sepa tus recetas.", T.HINT_COLOR)
    end
    return lines
end

Api.OnItemTooltip(function(tooltip, id)
    local lines = ItemTooltip.Lines(id)
    if #lines == 0 then return end
    for _, l in ipairs(lines) do tooltip:AddLine(l.text, l.color[1], l.color[2], l.color[3], true) end
    -- Vuelve a medir el tooltip para que quepan las líneas nuevas.
    tooltip:Show()
end)
