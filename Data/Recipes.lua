--[[
Recetas
=======

Todas las recetas de Forever que convierten una mena o un lingote en otra
cosa: las de minería (fundir) y las transmutaciones de alquimia. Los IDs,
cantidades y tiempos de reutilización están comprobados uno a uno en Wowhead
Forever (nether.wowhead.com/forever/tooltip/spell/<ID>). Forever solo tiene
el contenido del juego original: no hay hierro vil ni cobalto.

Cada receta:
  spell       ID del hechizo (el de la receta en el libro de la profesión)
  profession  "mining" o "alchemy"
  reagents    { { objeto, cantidad }, ... } lo que gasta
  output      { objeto, cantidad } lo que da
  cooldown    segundos hasta poder repetirla (solo las que lo tienen): no
              sirven para un montón de menas y se muestran aparte

Los nombres no están aquí: se piden al juego, que los da en su idioma.

Son el punto de partida: lo que gasta y da cada receta según el juego, leído
al abrir la ventana de la profesión, manda sobre esto (Core/Recipes.lua) y
avisa si no coincide. El tiempo de reutilización sale siempre de aquí.
]]

local _, ns = ...

local Data = {}
ns.Data = Data

-- Objetos, para no repetir números sueltos.
local I = {
    COPPER_ORE = 2770, COPPER_BAR = 2840,
    TIN_ORE = 2771, TIN_BAR = 3576,
    BRONZE_BAR = 2841,
    SILVER_ORE = 2775, SILVER_BAR = 2842,
    IRON_ORE = 2772, IRON_BAR = 3575,
    COAL = 3857, STEEL_BAR = 3859,
    GOLD_ORE = 2776, GOLD_BAR = 3577,
    MITHRIL_ORE = 3858, MITHRIL_BAR = 3860,
    TRUESILVER_ORE = 7911, TRUESILVER_BAR = 6037,
    THORIUM_ORE = 10620, THORIUM_BAR = 12359,
    ARCANE_CRYSTAL = 12363, ARCANITE_BAR = 12360,
    DARK_IRON_ORE = 11370, DARK_IRON_BAR = 11371,
    ELEMENTIUM_ORE = 18562, FIERY_CORE = 17010, ELEMENTAL_FLUX = 18567, ELEMENTIUM_BAR = 17771,
}
Data.ITEMS = I

local HOUR = 3600

Data.RECIPES = {
    -- Minería: fundir
    { spell = 2657, profession = "mining", reagents = { { I.COPPER_ORE, 1 } }, output = { I.COPPER_BAR, 1 } },
    { spell = 3304, profession = "mining", reagents = { { I.TIN_ORE, 1 } }, output = { I.TIN_BAR, 1 } },
    { spell = 2659, profession = "mining", reagents = { { I.COPPER_BAR, 1 }, { I.TIN_BAR, 1 } }, output = { I.BRONZE_BAR, 2 } },
    { spell = 2658, profession = "mining", reagents = { { I.SILVER_ORE, 1 } }, output = { I.SILVER_BAR, 1 } },
    { spell = 3307, profession = "mining", reagents = { { I.IRON_ORE, 1 } }, output = { I.IRON_BAR, 1 } },
    { spell = 3569, profession = "mining", reagents = { { I.IRON_BAR, 1 }, { I.COAL, 1 } }, output = { I.STEEL_BAR, 1 } },
    { spell = 3308, profession = "mining", reagents = { { I.GOLD_ORE, 1 } }, output = { I.GOLD_BAR, 1 } },
    { spell = 10097, profession = "mining", reagents = { { I.MITHRIL_ORE, 1 } }, output = { I.MITHRIL_BAR, 1 } },
    { spell = 10098, profession = "mining", reagents = { { I.TRUESILVER_ORE, 1 } }, output = { I.TRUESILVER_BAR, 1 } },
    { spell = 16153, profession = "mining", reagents = { { I.THORIUM_ORE, 1 } }, output = { I.THORIUM_BAR, 1 } },
    -- Solo en la Forja Negra de Profundidades de Roca Negra.
    { spell = 14891, profession = "mining", reagents = { { I.DARK_IRON_ORE, 8 } }, output = { I.DARK_IRON_BAR, 1 } },
    { spell = 22967, profession = "mining",
      reagents = { { I.ELEMENTIUM_ORE, 1 }, { I.ARCANITE_BAR, 10 }, { I.FIERY_CORE, 1 }, { I.ELEMENTAL_FLUX, 3 } },
      output = { I.ELEMENTIUM_BAR, 1 } },
    -- Alquimia: transmutar
    { spell = 11479, profession = "alchemy", cooldown = HOUR, reagents = { { I.IRON_BAR, 1 } }, output = { I.GOLD_BAR, 1 } },
    { spell = 11480, profession = "alchemy", cooldown = HOUR, reagents = { { I.MITHRIL_BAR, 1 } }, output = { I.TRUESILVER_BAR, 1 } },
    -- 1,958 días según Wowhead Forever.
    { spell = 17187, profession = "alchemy", cooldown = 169200,
      reagents = { { I.THORIUM_BAR, 1 }, { I.ARCANE_CRYSTAL, 1 } }, output = { I.ARCANITE_BAR, 1 } },
}

-- Materiales de la ventana, en el orden de la tabla: cada mena y los
-- lingotes que pueden ir a otra receta. Lo demás que piden las recetas
-- (carbón, cristal arcano...) no se decide aquí: se compra.
Data.MATERIALS = {
    I.COPPER_ORE, I.COPPER_BAR, I.TIN_ORE, I.TIN_BAR, I.SILVER_ORE,
    I.IRON_ORE, I.IRON_BAR, I.GOLD_ORE, I.MITHRIL_ORE, I.MITHRIL_BAR,
    I.TRUESILVER_ORE, I.THORIUM_ORE, I.THORIUM_BAR, I.ARCANITE_BAR,
    I.DARK_IRON_ORE, I.ELEMENTIUM_ORE,
}
