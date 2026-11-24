--[[
Qué hacer con cada material
===========================

Para una mena o un lingote, busca lo que más te deja por unidad:

  * venderlo tal cual (Prices.Sell), o
  * gastarlo en una receta y hacer lo mejor con lo que sale, que a su vez
    puede ser venderlo o gastarlo en otra receta.

Así una mena de cobre puede valer más fundida y hecha bronce que vendida: el
lingote de cobre vale lo que dejan los dos lingotes de bronce que salen con
él, menos lo que cuesta el lingote de estaño que también pide la receta.

  valor(material) = el mayor de
      vender(material)
      para cada receta que lo gasta:
          (cantidad que sale × valor(lo que sale)
           − precio de compra de lo demás que pide)
          / cantidad del material que gasta

Lo demás que pide una receta (el estaño del bronce, el carbón del acero) se
valora a precio de compra: es lo que cuesta tenerlo, o lo que dejas de
ganar si ya lo tienes y lo vendieras.

Las recetas con tiempo de reutilización (las transmutaciones) no sirven para
un montón de menas: se calculan aparte (Planner.Compare).

Un plan es { item, value, recipe, next }: el objeto, lo que deja por unidad,
la receta que se usa (nil = venderlo) y el plan de lo que sale de ella.
]]

local _, ns = ...
local Const, Util, Storage, Recipes, Prices = ns.Const, ns.Util, ns.Storage, ns.Recipes, ns.Prices

local Planner = {}
ns.Planner = Planner

--------------------------------------------------------------------------------
-- Preferencias
--------------------------------------------------------------------------------

-- Si cuenta también las recetas que este personaje no sabe (para ver qué
-- daría aprenderlas o usar a otro personaje).
function Planner.CountsAllRecipes()
    return Storage.Settings().allRecipes == true
end

function Planner.SetCountsAllRecipes(on)
    Storage.Settings().allRecipes = on or nil
    Util.Fire(Util.SETTINGS_CHANGED)
end

--------------------------------------------------------------------------------
-- Cálculo
--------------------------------------------------------------------------------

local best

-- Lo que cuesta lo demás que pide la receta, o nil si falta algún precio.
local function extrasCost(recipe, itemID)
    local total = 0
    for _, reagent in ipairs(recipe.reagents) do
        if reagent[1] ~= itemID then
            local price = Prices.Buy(reagent[1])
            if not price then return nil end
            total = total + price * reagent[2]
        end
    end
    return total
end

local function usable(recipe, opts)
    if recipe.cooldown and not opts.cooldown then return false end
    return opts.all or Recipes.IsKnown(recipe)
end

-- Plan de gastar itemID en la receta, o nil si falta algún precio.
local function craftPlan(recipe, itemID, opts, memo)
    local after = best(recipe.output[1], opts, memo)
    local cost = extrasCost(recipe, itemID)
    if not after or not cost then return nil end
    local value = (recipe.output[2] * after.value - cost) / Recipes.QuantityOf(recipe, itemID)
    return { item = itemID, value = value, recipe = recipe, next = after }
end

-- memo guarda el resultado de cada objeto en este cálculo (false = sin plan):
-- un mismo lingote sale en varios caminos y no hace falta repetirlo.
-- Con los datos del addon no hay ciclos, pero una receta leída del juego
-- podría volver a dar algo de lo que sale: mientras se calcula un objeto se
-- marca como "sin plan", y un camino que vuelve a él se descarta en lugar de
-- dar vueltas sin fin.
best = function(itemID, opts, memo)
    if memo[itemID] ~= nil then return memo[itemID] or nil end
    memo[itemID] = false
    local sell = Prices.Sell(itemID)
    local plan = sell and { item = itemID, value = sell } or nil
    for _, recipe in ipairs(Recipes.UsesOf(itemID)) do
        if usable(recipe, opts) then
            local option = craftPlan(recipe, itemID, opts, memo)
            -- Solo se cambia de opción si deja algo más: con un empate, mejor
            -- no complicarse.
            if option and (not plan or option.value >= plan.value + Const.MIN_GAIN) then plan = option end
        end
    end
    memo[itemID] = plan or false
    return plan
end

-- Mejor plan para un objeto, o nil si no hay precios. opts.cooldown cuenta
-- también las recetas con tiempo de reutilización.
function Planner.Best(itemID, opts)
    opts = opts or {}
    return best(itemID, { cooldown = opts.cooldown, all = Planner.CountsAllRecipes() }, {})
end

-- Lo que interesa enseñar de un material:
--   sell      lo que deja venderlo (o nil sin precio)
--   bulk      el mejor plan sin recetas con tiempo de reutilización
--   cooldown  el mejor con ellas, solo si deja más que bulk
function Planner.Compare(itemID)
    local bulk = Planner.Best(itemID)
    local withCooldown = Planner.Best(itemID, { cooldown = true })
    local better = withCooldown and (not bulk or withCooldown.value >= bulk.value + Const.MIN_GAIN)
    return {
        sell = Prices.Sell(itemID),
        bulk = bulk,
        cooldown = better and withCooldown or nil,
    }
end

-- Lo primero que hay que hacer en el plan: la receta (nil = venderlo).
function Planner.FirstRecipe(plan)
    return plan and plan.recipe
end

-- Lo que se vende al final del plan.
function Planner.FinalItem(plan)
    while plan.next do plan = plan.next end
    return plan.item
end

-- Receta con tiempo de reutilización dentro del plan (la primera), o nil.
function Planner.CooldownRecipe(plan)
    while plan do
        if plan.recipe and plan.recipe.cooldown then return plan.recipe end
        plan = plan.next
    end
end
