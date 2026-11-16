--[[
Leer las recetas del juego
==========================

Cada vez que se abre la ventana de una profesión (minería o alquimia), lee
sus recetas tal y como las da el juego y apunta:

  * cuáles sabe este personaje (y cuáles no: las que salen en la ventana sin
    aprender, o las que deja de saber si olvida la profesión y la vuelve a
    aprender);
  * lo que gasta y lo que da cada una, para toda la cuenta. Así, si Forever
    cambia una receta o añade una nueva, los cálculos usan la del juego sin
    esperar a que se actualicen los datos del addon (Core/Recipes.lua).

Solo se guardan las recetas que importan aquí: las de Data/Recipes.lua y
cualquier otra que gaste o dé una mena o lingote de los que se decide.

Al terminar, avisa con Const.MSG.RECIPES_READ y la lista de recetas que
han cambiado respecto a la última vez (UI/RecipeNotice.lua lo cuenta en el
chat), y con RECIPES_CHANGED si cambia algo de lo que se calcula.
]]

local _, ns = ...
local Const, Util, Api, Storage, Recipes = ns.Const, ns.Util, ns.Api, ns.Storage, ns.Recipes

local RecipeScan = {}
ns.RecipeScan = RecipeScan

-- Si la receta gasta o da una mena o lingote de los que se decide.
local function touchesMaterial(recipe)
    if recipe.output and Recipes.IsMaterial(recipe.output[1]) then return true end
    for _, reagent in ipairs(recipe.reagents) do
        if Recipes.IsMaterial(reagent[1]) then return true end
    end
    return false
end

local function relevant(recipe)
    return Recipes.InData(recipe.id) or touchesMaterial(recipe)
end

-- Sin ingredientes o sin lo que da no se puede calcular nada: puede pasar si
-- el juego aún no ha cargado la receta del todo. Se ignora hasta la próxima.
local function complete(recipe)
    return recipe.output ~= nil and #recipe.reagents > 0
end

-- Apunta si la sabe. true si ha cambiado.
local function rememberKnown(recipe)
    local known = Storage.KnownRecipes()
    if known[recipe.id] == recipe.learned then return false end
    known[recipe.id] = recipe.learned
    return true
end

-- Guarda lo que gasta y da. true si es nueva o distinta de la guardada.
local function rememberShape(recipe)
    local game = Storage.GameRecipes()
    local entry = { reagents = recipe.reagents, output = recipe.output }
    local before = game[recipe.id]
    if before and Recipes.Same(before, entry) then return false end
    game[recipe.id] = entry
    return true
end

function RecipeScan.ScanOpenWindow()
    local changed, reshaped = false, {}
    for _, recipe in ipairs(Api.OpenTradeSkillRecipes()) do
        if relevant(recipe) and complete(recipe) then
            if rememberKnown(recipe) then changed = true end
            if rememberShape(recipe) then reshaped[#reshaped + 1] = recipe.id end
        end
    end
    if #reshaped > 0 then
        Recipes.Reload()
        changed = true
    end
    if changed then Util.Fire(Const.MSG.RECIPES_CHANGED) end
    Util.Fire(Const.MSG.RECIPES_READ, reshaped)
end

-- La lista de recetas llega poco a poco al abrir la ventana: se lee al
-- terminar la ráfaga de eventos.
local scanSoon = Util.Debounce(Const.FRAME.UPDATE_DELAY, RecipeScan.ScanOpenWindow)
for _, event in ipairs({ "TRADE_SKILL_SHOW", "TRADE_SKILL_LIST_UPDATE", "TRADE_SKILL_UPDATE" }) do
    Util.On(event, scanSoon)
end
