--[[
Aviso de recetas distintas en el juego
======================================

Cuando Core/RecipeScan.lua lee una receta que no coincide con los datos del
addon (cambiada en Forever, o nueva), lo cuenta en el chat una vez, con lo
que gasta y da según el juego. Las que coinciden no dicen nada: leerlas por
primera vez solo confirma que los datos están bien.

Con esto basta para saber qué hay que poner al día en Data/Recipes.lua;
mientras tanto, los cálculos ya usan la del juego. /fundir recetas lo
vuelve a enseñar.
]]

local _, ns = ...
local Const, Util, Recipes, PlanText = ns.Const, ns.Util, ns.Recipes, ns.PlanText
local STATUS = Recipes.STATUS

local RecipeNotice = {}
ns.RecipeNotice = RecipeNotice

-- Explicación de cada estado que merece aviso.
local MESSAGES = {
    [STATUS.CHANGED] = "ha cambiado en el juego",
    [STATUS.NEW] = "es nueva (no estaba en el addon)",
}

-- Texto del aviso de una receta, o nil si no hay nada que contar.
function RecipeNotice.Text(recipe)
    local message = MESSAGES[Recipes.Status(recipe)]
    if not message then return nil end
    return ("%s %s: %s. Se usa la del juego."):format(PlanText.RecipeName(recipe), message, PlanText.Recipe(recipe))
end

local function announce(spells)
    for _, spell in ipairs(spells) do
        local text = RecipeNotice.Text(Recipes.BySpell(spell))
        if text then Util.Print("%s", text) end
    end
end

Util.Listen(Const.MSG.RECIPES_READ, announce)
