--[[
Constantes y configuración
==========================

WoW ejecuta cada archivo del addon pasándole dos valores: el nombre del addon
y una tabla privada que comparten todos sus archivos. Usamos esa tabla (ns,
"namespace") para repartir el código en módulos sin crear variables globales,
que podrían chocar con otros addons.

El código común con los otros addons (utilidades, API del juego, registro
de errores, tooltips, casillas y botón del minimapa) está en la librería
FranLib, incrustada en Libs/FranLib. Lo que necesita saber de este addon se
lo dice ns.FranLibConfig, al final de este archivo.
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

-- Avisos que salen en más de un sitio (tooltip, ventanas).
Const.TEXT = {
    NO_TSM = "Sin precios: hace falta TradeSkillMaster.",
    OPEN_PROFESSION = "Abre la ventana de minería una vez para que sepa tus recetas.",
    NO_PRICE = "TSM aún no tiene precio de esto.",
}

-- Interfaz.
Const.UI = {
    -- Casillas (UI/Checkbox.lua, compartido).
}

-- Líneas que se añaden al tooltip de las menas y lingotes.
Const.TOOLTIP = {
    TITLE_COLOR = { 0.2, 1, 0.6 },
    TEXT_COLOR = { 1, 1, 1 },
    HINT_COLOR = { 0.6, 0.6, 0.6 },
    GAIN_COLOR = "33ff66",     -- lo que ganas respecto a vender, en verde
}

-- Lo común a las dos ventanas (UI/BaseWindow.lua).
Const.FRAME = {
    TITLE = "FranFundir",
    UPDATE_DELAY = 0.5,          -- agrupa las ráfagas de BAG_UPDATE
}

-- Ventana con la tabla de todos los materiales (/fundir tabla).
Const.WINDOW = {
    NAME = "FranFundirWindow",   -- nombre global (necesario para cerrar con Escape)
    SAVED_POINT = "point",       -- dónde guarda su posición (Storage.Settings)
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
}

-- Informe de lo que llevas en las bolsas (/fundir y el botón del minimapa).
-- Se compone de bloques, uno debajo de otro; la ventana mide lo que ocupan.
Const.REPORT = {
    NAME = "FranFundirReport",
    SAVED_POINT = "reportPoint",
    SUBTITLE = "Lo que llevas",
    WIDTH = 600,                 -- que quepa el detalle de los pasos en una línea
    PADDING = 14,
    TOP = -30,                   -- primer bloque, bajo la barra de título
    GAP = 4,                     -- espacio entre bloques
    SECTION_GAP = 10,            -- y antes de cada sección
    FOOTER_HEIGHT = 64,          -- casilla, botón y texto de los precios
    -- Alto de cada tipo de bloque (las notas miden su texto).
    SUMMARY_HEIGHT = 46,
    SUMMARY_CELLS = 3,           -- venderlo, seguir los consejos, ganas
    SECTION_HEIGHT = 20,
    ITEM_HEIGHT = 32,
    ICON_SIZE = 26,
    RIGHT_WIDTH = 110,           -- columna de la derecha (dinero)
    BUTTON_WIDTH = 130,          -- botón "Tabla de precios"
    BUTTON_HEIGHT = 22,
    COLORS = {
        SUMMARY_BG = { 0, 0, 0, 0.35 },
        SECTION = { 1, 0.82, 0 },
        DIVIDER = { 1, 0.82, 0, 0.25 },
        LABEL = { 0.65, 0.65, 0.65 },
        DETAIL = { 0.75, 0.75, 0.75 },
        ROW_BG = { 1, 1, 1, 0.04 },   -- una fila sí y otra no, para seguirlas
    },
}

-- Lo que FranLib (Libs/FranLib, ver su Config.lua) necesita saber de este
-- addon: con qué icono y prefijo habla en el chat, dónde apunta sus errores y
-- cómo se llama su botón del minimapa.
ns.FranLibConfig = {
    icon = Const.ICON,
    chatPrefix = Const.CHAT_PREFIX,
    errorLog = { savedVar = "FranFundirLog", command = "/fundir errores" },
    minimap = { buttonName = "FranFundirMinimapButton", defaultAngle = 195 },
}
