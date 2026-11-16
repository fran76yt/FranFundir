--[[
Constantes y configuración
==========================

WoW ejecuta cada archivo del addon pasándole dos valores: el nombre del addon
y una tabla privada que comparten todos sus archivos. Usamos esa tabla (ns,
"namespace") para repartir el código en módulos sin crear variables globales,
que podrían chocar con otros addons.

Los archivos compartidos con FranTools (Core/Util.lua, Core/Api.lua,
Core/ErrorLog.lua, UI/Tooltip.lua y UI/Checkbox.lua, que se editan en
FranTools y se copian con su tools/sync_shared.py) leen de aquí ADDON_NAME,
ICON, MSG.SETTINGS_CHANGED, CHAT_PREFIX, UI (TOOLTIP_HELP_COLOR y las medidas
de las casillas) y ERROR_LOG.
]]

local addonName, ns = ...

local Const = {}
ns.Const = Const

-- Para inspeccionar el addon en el juego (/dump FranFundir.Planner...).
_G.FranFundir = ns

Const.ADDON_NAME = addonName
Const.ICON = "Interface\\Icons\\INV_Ingot_Bronze"

-- Mensajes internos entre módulos (Util.Listen / Util.Fire).
Const.MSG = {
    SETTINGS_CHANGED = "FRANFUNDIR_SETTINGS_CHANGED",   -- cambia una preferencia
    RECIPES_CHANGED = "FRANFUNDIR_RECIPES_CHANGED",     -- cambian las recetas que sabes o lo que hacen
    RECIPES_READ = "FRANFUNDIR_RECIPES_READ",           -- leída una ventana de profesión (y qué recetas cambian)
}

Const.CHAT_PREFIX = "|T" .. Const.ICON .. ":14:14|t |cff33ff99FranFundir|r"

-- Comisión de la casa de subastas sobre lo que vendes. Se descuenta de todo
-- lo que se vende (la mena, el lingote o lo que salga al final), para
-- comparar lo que de verdad te queda.
Const.AH_CUT = 0.05

-- Precios de TSM por defecto ("fuentes de precio" o fórmulas de TSM).
--   SELL  lo que crees que sacas al vender en la casa de subastas
--   BUY   lo que cuesta comprar lo que pide una receta además del material
--         (el carbón del acero, el cristal arcano de la arcanita...): el
--         más barato entre el vendedor y la casa de subastas
Const.PRICE = {
    SELL = "dbmarket",
    BUY = "min(vendorbuy, dbmarket)",
}

-- Mismo valor en cobre: no vale la pena recomendar un cambio por menos.
Const.MIN_GAIN = 1

-- Interfaz.
Const.UI = {
    TOOLTIP_HELP_COLOR = { 0.8, 0.8, 0.8 },
    -- Casillas (UI/Checkbox.lua, compartido).
    CHECK_SIZE = 24,
    CHECK_LABEL_GAP = 2,
    CHECK_ICON_SIZE = 16,
}

-- Líneas que se añaden al tooltip de las menas y lingotes.
Const.TOOLTIP = {
    TITLE_COLOR = { 0.2, 1, 0.6 },
    TEXT_COLOR = { 1, 1, 1 },
    HINT_COLOR = { 0.6, 0.6, 0.6 },
    GAIN_COLOR = "33ff66",     -- lo que ganas respecto a vender, en verde
}

-- Ventana con la tabla de todos los materiales.
Const.WINDOW = {
    NAME = "FranFundirWindow",   -- nombre global (necesario para cerrar con Escape)
    TITLE = "FranFundir",
    PADDING = 14,
    TOP = -32,                   -- primera fila, bajo la barra de título
    ROW_HEIGHT = 18,
    ICON_SIZE = 16,
    HEADER_COLOR = { 1, 0.82, 0 },
    -- Columnas: clave, título y ancho. "best" es la opción que más deja.
    COLUMNS = {
        { key = "name", title = "Material", width = 150 },
        { key = "sell", title = "Vender", width = 80 },
        { key = "best", title = "Mejor opción", width = 160 },
        { key = "value", title = "Te deja", width = 80 },
        { key = "count", title = "Llevas", width = 46 },
        { key = "gain", title = "Ganas", width = 80 },
    },
    FOOTER_HEIGHT = 56,          -- casilla y texto de los precios, abajo
    UPDATE_DELAY = 0.5,          -- agrupa las ráfagas de BAG_UPDATE
}

-- Registro de errores de Lua (Core/ErrorLog.lua, compartido).
Const.ERROR_LOG = {
    SAVED_VAR = "FranFundirLog",   -- variable de la cuenta (## SavedVariables del .toc)
    COMMAND = "/fundir errores",   -- para el aviso del chat y la ayuda
    MAX_ENTRIES = 50,              -- errores distintos que se guardan como mucho
    MAX_STACK_CHARS = 2000,        -- tope de la pila de cada uno, para no inflar el archivo
    STACK_COLOR = "999999",        -- gris para la pila en el chat
}
