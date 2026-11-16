--[[
Recetas que puedes usar
=======================

Las recetas salen de dos sitios:

  * Data/Recipes.lua, escritas a mano y comprobadas en Wowhead. Sirven desde
    el primer momento, aunque no se haya abierto ninguna profesión.
  * Lo que dice el juego al abrir la ventana de minería o de alquimia
    (Core/RecipeScan.lua las guarda). Manda sobre los datos: si Forever
    cambia una receta o añade otra, se usa lo que dice el juego.

De los datos se toma siempre la profesión y el tiempo de reutilización, que
la ventana no da. Una receta nueva del juego, que no está en los datos, se
trata como si no tuviera tiempo de reutilización.

Qué recetas sabe el personaje se apunta también al abrir la ventana: la API
de hechizos no es fiable con las de profesión en todos los clientes, así que
solo se usa hasta que la abra una vez.

  Recipes.All()                    todas las recetas, ya combinadas
  Recipes.BySpell(id)              una por su ID de hechizo
  Recipes.UsesOf(itemID)           recetas que gastan ese objeto
  Recipes.QuantityOf(recipe, id)   cuántos gasta la receta de ese objeto
  Recipes.IsMaterial(itemID)       si es una mena o lingote de los que se decide
  Recipes.IsKnown(recipe)          si este personaje la sabe
  Recipes.HasAnyKnown()            si ya se sabe alguna (para avisar de que
                                   abra la ventana de minería)
  Recipes.Same(a, b)               si gastan y dan lo mismo
  Recipes.Status(recipe)           de dónde sale: ver STATUS
  Recipes.Reload()                 rehacer la lista tras leer el juego
]]

local _, ns = ...
local Api, Storage, Data = ns.Api, ns.Storage, ns.Data

local Recipes = {}
ns.Recipes = Recipes

-- De dónde sale una receta, comparando el juego con los datos.
local STATUS = {
    DATA = "data",          -- solo de los datos: aún no se ha visto en el juego
    SAME = "same",          -- el juego dice lo mismo que los datos
    CHANGED = "changed",    -- el juego dice otra cosa: se usa la del juego
    NEW = "new",            -- solo del juego: no está en los datos
}
Recipes.STATUS = STATUS

local dataBySpell, isMaterial = {}, {}
for _, recipe in ipairs(Data.RECIPES) do dataBySpell[recipe.spell] = recipe end
for _, id in ipairs(Data.MATERIALS) do isMaterial[id] = true end

--------------------------------------------------------------------------------
-- Comparar recetas
--------------------------------------------------------------------------------

-- "objeto x cantidad". %g escribe igual 2 y 2.0: la cantidad puede llegar
-- como decimal (la media de un mínimo y un máximo) y no por eso es otra.
local function entryKey(entry)
    return ("%dx%g"):format(entry[1], entry[2])
end

-- Texto que resume lo que gasta y lo que da, sin depender del orden de los
-- ingredientes: dos recetas son iguales si su firma lo es.
local function signature(recipe)
    local parts = {}
    for _, reagent in ipairs(recipe.reagents) do parts[#parts + 1] = entryKey(reagent) end
    table.sort(parts)
    local output = recipe.output and entryKey(recipe.output) or "-"
    return table.concat(parts, "+") .. ">" .. output
end

function Recipes.Same(a, b)
    return signature(a) == signature(b)
end

--------------------------------------------------------------------------------
-- Lista combinada
--------------------------------------------------------------------------------

-- La receta del juego encima de la de los datos.
local function combine(spell, data, game)
    if not game then return data end
    return {
        spell = spell,
        profession = data and data.profession,
        cooldown = data and data.cooldown,
        reagents = game.reagents,
        output = game.output,
    }
end

-- Recetas nuevas del juego (no están en los datos), en orden de ID para
-- que la lista salga siempre igual.
local function newGameSpells(game)
    local spells = {}
    for spell in pairs(game) do
        if not dataBySpell[spell] then spells[#spells + 1] = spell end
    end
    table.sort(spells)
    return spells
end

-- La lista se hace la primera vez que se pide: las recetas del juego están
-- en las SavedVariables, que no existen hasta que carga el addon.
local list, bySpell, usesOf

local function add(recipe)
    list[#list + 1] = recipe
    bySpell[recipe.spell] = recipe
    for _, reagent in ipairs(recipe.reagents) do
        local id = reagent[1]
        usesOf[id] = usesOf[id] or {}
        table.insert(usesOf[id], recipe)
    end
end

local function build()
    if list then return end
    list, bySpell, usesOf = {}, {}, {}
    local game = Storage.GameRecipes()
    for _, data in ipairs(Data.RECIPES) do add(combine(data.spell, data, game[data.spell])) end
    for _, spell in ipairs(newGameSpells(game)) do add(combine(spell, nil, game[spell])) end
end

function Recipes.Reload()
    list = nil
end

function Recipes.All()
    build()
    return list
end

function Recipes.BySpell(spell)
    build()
    return bySpell[spell]
end

function Recipes.UsesOf(itemID)
    build()
    return usesOf[itemID] or {}
end

function Recipes.Status(recipe)
    local data, game = dataBySpell[recipe.spell], Storage.GameRecipes()[recipe.spell]
    if not game then return STATUS.DATA end
    if not data then return STATUS.NEW end
    return Recipes.Same(data, game) and STATUS.SAME or STATUS.CHANGED
end

--------------------------------------------------------------------------------
-- Consultas
--------------------------------------------------------------------------------

function Recipes.QuantityOf(recipe, itemID)
    for _, reagent in ipairs(recipe.reagents) do
        if reagent[1] == itemID then return reagent[2] end
    end
    return 0
end

-- Si es una de las menas o lingotes que el addon ayuda a decidir.
function Recipes.IsMaterial(itemID)
    return isMaterial[itemID] == true
end

-- Si la receta está en los datos del addon.
function Recipes.InData(spell)
    return dataBySpell[spell] ~= nil
end

-- Lo leído de la ventana manda (también un "no la sabe"); hasta abrirla, la
-- API de hechizos.
function Recipes.IsKnown(recipe)
    local known = Storage.KnownRecipes()[recipe.spell]
    if known ~= nil then return known end
    return Api.IsSpellKnown(recipe.spell)
end

function Recipes.HasAnyKnown()
    for _, recipe in ipairs(Recipes.All()) do
        if Recipes.IsKnown(recipe) then return true end
    end
    return false
end
