--[[
Planes en texto
===============

Convierte un plan (Core/Planner.lua) en lo que lee el jugador, igual en el
tooltip y en la ventana:

  PlanText.Money(cobre)        "1o 20p", con signo si es negativo
  PlanText.Gain(cobre)         "+20p" en verde (lo que ganas sobre vender)
  PlanText.Steps(plan[, n])    "Cobre fundido › Bronce fundido › vender
                               Lingote de bronce" (con n, "vender 40 ...")
  PlanText.Short(plan)         "Vender" o "Lingote de bronce": cómo acaba
  PlanText.Wait(recipe)        "cada 1 h", "cada 2 días"
  PlanText.RecipeName(recipe)  "Bronce fundido"
  PlanText.Recipe(recipe)      "Lingote de cobre + Lingote de estaño →
                               2 Lingote de bronce"
  PlanText.Amount(id, n)       "20 Mena de cobre" ("Mena de cobre" si es 1)
  PlanText.Sources()           de dónde salen los precios (o que falta TSM)

Los nombres de recetas y objetos los da el juego, en su idioma.
]]

local _, ns = ...
local Const, Util, Api, Tsm, Prices, Planner = ns.Const, ns.Util, ns.Api, ns.Tsm, ns.Prices, ns.Planner

local PlanText = {}
ns.PlanText = PlanText

local SEPARATOR = " › "
local HOUR, DAY = 3600, 86400

function PlanText.Money(copper)
    local rounded = math.floor(math.abs(copper) + 0.5)
    local text = Api.MoneyText(rounded)
    return copper < 0 and ("-" .. text) or text
end

function PlanText.Gain(copper)
    return Util.Colorize(Const.TOOLTIP.GAIN_COLOR, "+" .. PlanText.Money(copper))
end

local function itemName(id)
    return (Api.ItemName(id))
end

-- Nombre de la receta; si el juego aún no lo da, su ID.
function PlanText.RecipeName(recipe)
    return Api.SpellName(recipe.spell) or ("hechizo " .. recipe.spell)
end

-- "2 Mena de hierro negro" o "Lingote de cobre" (la cantidad, solo si no es 1).
-- %g: una cantidad media (1,5 de una receta que da 1 o 2) se escribe tal cual.
function PlanText.Amount(id, quantity)
    if quantity == 1 then return itemName(id) end
    return ("%g %s"):format(quantity, itemName(id))
end

local function amount(entry)
    return PlanText.Amount(entry[1], entry[2])
end

-- Lo que gasta y lo que da: "Lingote de cobre + Lingote de estaño → 2 Lingote de bronce".
function PlanText.Recipe(recipe)
    local reagents = {}
    for i, reagent in ipairs(recipe.reagents) do reagents[i] = amount(reagent) end
    return table.concat(reagents, " + ") .. " → " .. amount(recipe.output)
end

-- Pasos del plan: cada receta por su nombre y, al final, qué se vende (con
-- cuántos, si se sabe).
function PlanText.Steps(plan, finalCount)
    local steps = {}
    while plan.next do
        steps[#steps + 1] = PlanText.RecipeName(plan.recipe)
        plan = plan.next
    end
    local sold = finalCount and PlanText.Amount(plan.item, finalCount) or itemName(plan.item)
    steps[#steps + 1] = "vender " .. sold
    return table.concat(steps, SEPARATOR)
end

function PlanText.Short(plan)
    if not Planner.FirstRecipe(plan) then return "Vender" end
    return itemName(Planner.FinalItem(plan))
end

-- Tiempo de reutilización redondeado a lo que se entiende de un vistazo.
function PlanText.Wait(recipe)
    local seconds = recipe.cooldown
    if seconds >= DAY then
        return ("cada %d días"):format(math.floor(seconds / DAY + 0.5))
    end
    return ("cada %d h"):format(math.max(1, math.floor(seconds / HOUR + 0.5)))
end

-- Pie de las ventanas: qué precios de TSM se usan.
function PlanText.Sources()
    if not Tsm.IsAvailable() then return Const.TEXT.NO_TSM end
    return ("Precios de TSM. Venta: %s (menos el %d%% de comisión). Compra: %s."):format(
        Prices.Source("sell"), math.floor(Const.AH_CUT * 100 + 0.5), Prices.Source("buy"))
end
