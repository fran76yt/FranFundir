--[[
Planes en texto
===============

Convierte un plan (Core/Planner.lua) en lo que lee el jugador, igual en el
tooltip y en la ventana:

  PlanText.Money(cobre)        "1o 20p", con signo si es negativo
  PlanText.Gain(cobre)         "+20p" en verde (lo que ganas sobre vender)
  PlanText.Steps(plan)         "Cobre fundido › Bronce fundido › vender
                               Lingote de bronce"
  PlanText.Short(plan)         "Vender" o "Lingote de bronce": cómo acaba
  PlanText.Wait(recipe)        "cada 1 h", "cada 2 días"
  PlanText.RecipeName(recipe)  "Bronce fundido"
  PlanText.Recipe(recipe)      "Lingote de cobre + Lingote de estaño →
                               2 Lingote de bronce"

Los nombres de recetas y objetos los da el juego, en su idioma.
]]

local _, ns = ...
local Const, Util, Api, Planner = ns.Const, ns.Util, ns.Api, ns.Planner

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
local function amount(entry)
    if entry[2] == 1 then return itemName(entry[1]) end
    return ("%g %s"):format(entry[2], itemName(entry[1]))
end

-- Lo que gasta y lo que da: "Lingote de cobre + Lingote de estaño → 2 Lingote de bronce".
function PlanText.Recipe(recipe)
    local reagents = {}
    for i, reagent in ipairs(recipe.reagents) do reagents[i] = amount(reagent) end
    return table.concat(reagents, " + ") .. " → " .. amount(recipe.output)
end

-- Pasos del plan: cada receta por su nombre y, al final, qué se vende.
function PlanText.Steps(plan)
    local steps = {}
    while plan.next do
        steps[#steps + 1] = PlanText.RecipeName(plan.recipe)
        plan = plan.next
    end
    steps[#steps + 1] = "vender " .. itemName(plan.item)
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
