--[[
Almacenamiento (SavedVariables)
===============================

Único módulo que toca las variables guardadas de preferencias y recetas
(declaradas en el .toc). WoW las carga desde disco antes de PLAYER_LOGIN y
las escribe al hacer /reload, al cerrar sesión o al salir. Solo se guarda lo
que el jugador ha cambiado:

  FranFundirDB (toda la cuenta)
    sellSource   precio de venta de TSM, si no es el de por defecto
    buySource    precio de compra de TSM, si no es el de por defecto
    allRecipes   true si cuenta también las recetas que este personaje no sabe
    point        posición de la ventana: { punto, punto relativo, x, y }
    gameRecipes  recetas tal y como las da el juego, por ID de hechizo:
                 { [2659] = { reagents = { { 2840, 1 }, { 3576, 1 } },
                 output = { 2841, 2 } }, ... }. Son iguales para todos los
                 personajes, por eso van en la cuenta (Core/RecipeScan.lua)

  FranFundirChar (cada personaje)
    known        recetas leídas de su ventana de profesión, por ID: true si
                 la sabe y false si sale en la ventana pero aún no la ha
                 aprendido: { [2657] = true, [3569] = false, ... }

(FranFundirLog, la de los errores, es de Core/ErrorLog.lua.)
]]

local _, ns = ...

local Storage = {}
ns.Storage = Storage

-- La primera vez que se usa el addon las variables no existen: se crean.
local function account()
    FranFundirDB = FranFundirDB or {}
    return FranFundirDB
end

local function character()
    FranFundirChar = FranFundirChar or {}
    return FranFundirChar
end

-- Preferencias de toda la cuenta. Devuelve la tabla misma: quien la recibe
-- la modifica y WoW la guardará al escribir las SavedVariables.
function Storage.Settings()
    return account()
end

-- Recetas que sabe (o no) este personaje.
function Storage.KnownRecipes()
    local c = character()
    c.known = c.known or {}
    return c.known
end

-- Recetas leídas del juego.
function Storage.GameRecipes()
    local a = account()
    a.gameRecipes = a.gameRecipes or {}
    return a.gameRecipes
end
