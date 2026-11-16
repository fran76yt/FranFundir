--[[
Seguir los consejos con lo que llevas
=====================================

El plan de cada material (Core/Planner.lua) es por unidad y lo valora por
separado: lo demás que pide una receta se cuenta como comprado. Con las
bolsas de verdad eso no basta: si llevas menas de cobre y de estaño, el
bronce se hace con los lingotes de las dos, no comprando estaño para el
cobre y cobre para el estaño.

Aquí se simula lo que harías, con todo junto en un montón (pool):

  1. Entran en el montón los materiales que llevas.
  2. Se toma un objeto del montón cuyo plan sea fabricar algo y se hacen
     todas las recetas enteras que dé. Lo demás que pide la receta sale
     primero del montón o de las bolsas (el carbón que llevas) y solo lo
     que falta se compra. Lo que sale vuelve al montón.
  3. Se repite hasta que en el montón solo queda lo que se vende (o lo que
     no llega para una receta más).

El orden importa: antes de hacer bronce con los lingotes de cobre hay que
fundir las menas de estaño, o se compraría estaño que ya llevas. Por eso
un objeto espera mientras otro del montón aún pueda dar lo que su receta
gasta (ver ready).

Production.Run(carried) devuelve:
  steps   lo que hay que hacer, por orden: { recipe, item, used, crafts,
          made = { objeto, cantidad }, extras = { { id, quantity, own, buy } } }
  pool    lo que queda al final: { [objeto] = cantidad }, en order
  order   los objetos del montón en el orden en que entraron
  bought  lo que hay que comprar: { [objeto] = cantidad }
  taken   lo que se gasta de las bolsas sin ser material: { [objeto] = cantidad }
  plans   el plan de cada objeto del montón (Planner.Best)
]]

local _, ns = ...
local Api, Recipes, Planner = ns.Api, ns.Recipes, ns.Planner

local Production = {}
ns.Production = Production

-- Tope de recetas distintas: con los datos del addon salen unas pocas, pero
-- una receta leída del juego podría devolver lo que gasta y no acabar nunca.
local MAX_STEPS = 100

--------------------------------------------------------------------------------
-- El montón
--------------------------------------------------------------------------------

local function newState()
    return { pool = {}, order = {}, plans = {}, steps = {}, bought = {}, taken = {} }
end

local function add(state, id, quantity)
    if state.pool[id] == nil then
        state.order[#state.order + 1] = id
        state.plans[id] = Planner.Best(id)
    end
    state.pool[id] = (state.pool[id] or 0) + quantity
end

-- Saca hasta "quantity" de lo que llevas: del montón si el objeto está en
-- él y, si no, de las bolsas (lo que no es material: carbón, cristal
-- arcano...). Devuelve cuántos había.
local function takeOwn(state, id, quantity)
    local available
    if state.pool[id] ~= nil then
        available = state.pool[id]
    else
        available = Api.ItemCount(id) - (state.taken[id] or 0)
    end
    local own = math.max(0, math.min(available, quantity))
    if state.pool[id] ~= nil then
        state.pool[id] = state.pool[id] - own
    elseif own > 0 then
        state.taken[id] = (state.taken[id] or 0) + own
    end
    return own
end

--------------------------------------------------------------------------------
-- Qué toca ahora
--------------------------------------------------------------------------------

-- La receta del plan de un objeto, o nil si lo mejor es venderlo.
local function recipeOf(state, id)
    local plan = state.plans[id]
    return plan and plan.recipe
end

-- Cuántas veces da para hacer la receta de su plan.
local function craftsOf(state, id)
    return math.floor(state.pool[id] / Recipes.QuantityOf(recipeOf(state, id), id))
end

-- Su plan es fabricar algo y hay bastantes para hacerlo al menos una vez.
local function canCraft(state, id)
    return recipeOf(state, id) ~= nil and craftsOf(state, id) >= 1
end

-- Todo lo que acabará saliendo de un objeto si se sigue su plan.
local function outputsOf(state, id)
    local outputs, plan = {}, state.plans[id]
    while plan and plan.recipe do
        outputs[plan.recipe.output[1]] = true
        plan = plan.next
    end
    return outputs
end

-- Un objeto puede fabricarse ya si ningún otro pendiente va a dar más de
-- él o de lo que su receta gasta.
local function ready(state, id, pending)
    for _, other in ipairs(pending) do
        if other ~= id then
            local outputs = outputsOf(state, other)
            if outputs[id] then return false end
            for _, reagent in ipairs(recipeOf(state, id).reagents) do
                if outputs[reagent[1]] then return false end
            end
        end
    end
    return true
end

local function pendingItems(state)
    local pending = {}
    for _, id in ipairs(state.order) do
        if canCraft(state, id) then pending[#pending + 1] = id end
    end
    return pending
end

-- De los que están listos, el que da más recetas: con 10 lingotes de cobre
-- y 4 de estaño, el bronce se hace en un paso con el cobre (y 6 de estaño
-- comprados) y no en dos. Si se esperan unos a otros (recetas del juego en
-- círculo), el primero sin más.
local function nextItem(state)
    local pending = pendingItems(state)
    local chosen
    for _, id in ipairs(pending) do
        if ready(state, id, pending) and (not chosen or craftsOf(state, id) > craftsOf(state, chosen)) then
            chosen = id
        end
    end
    return chosen or pending[1]
end

--------------------------------------------------------------------------------
-- Fabricar
--------------------------------------------------------------------------------

-- Lo demás que pide la receta: de lo que llevas y, lo que falte, comprado.
local function useExtras(state, recipe, id, crafts)
    local extras = {}
    for _, reagent in ipairs(recipe.reagents) do
        if reagent[1] ~= id then
            local quantity = crafts * reagent[2]
            local own = takeOwn(state, reagent[1], quantity)
            local buy = quantity - own
            if buy > 0 then state.bought[reagent[1]] = (state.bought[reagent[1]] or 0) + buy end
            extras[#extras + 1] = { id = reagent[1], quantity = quantity, own = own, buy = buy }
        end
    end
    return extras
end

-- Todas las recetas enteras que dé el objeto; lo que sale vuelve al montón.
local function craft(state, id)
    local recipe = recipeOf(state, id)
    local crafts = craftsOf(state, id)
    local used = crafts * Recipes.QuantityOf(recipe, id)
    state.pool[id] = state.pool[id] - used
    local extras = useExtras(state, recipe, id, crafts)
    local made = { recipe.output[1], crafts * recipe.output[2] }
    add(state, made[1], made[2])
    state.steps[#state.steps + 1] = {
        recipe = recipe, item = id, used = used, crafts = crafts, made = made, extras = extras,
    }
end

--------------------------------------------------------------------------------
-- API
--------------------------------------------------------------------------------

-- carried: { { objeto, cantidad }, ... } lo que llevas, en el orden en que
-- se quiere ver.
function Production.Run(carried)
    local state = newState()
    for _, entry in ipairs(carried) do add(state, entry[1], entry[2]) end
    for _ = 1, MAX_STEPS do
        local id = nextItem(state)
        if not id then break end
        craft(state, id)
    end
    return state
end

-- Cuántos faltan para poder hacer la receta del plan una vez, o nil si su
-- plan es venderlo (o ya llega).
function Production.Short(state, id)
    local recipe = recipeOf(state, id)
    if not recipe then return nil end
    local missing = Recipes.QuantityOf(recipe, id) - state.pool[id]
    return missing > 0 and missing or nil
end

function Production.RecipeOf(state, id)
    return recipeOf(state, id)
end
