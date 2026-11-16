--[[
Comandos de chat
================

  /fundir               abrir o cerrar el informe de lo que llevas
  /fundir tabla         abrir o cerrar la tabla de todas las menas y lingotes
  /fundir minimapa      ocultar o mostrar el botón del minimapa
  /fundir venta <TSM>   precio de venta de TSM ("dbmarket", "dbminbuyout"...);
                        sin nada, vuelve al de por defecto
  /fundir compra <TSM>  precio de compra de lo demás que piden las recetas
  /fundir recetas       qué recetas sabe este personaje
  /fundir errores       errores de Lua apuntados (con un número, uno entero;
                        con borrar, vacía la lista)
  /fundir ayuda         versión y lista de comandos (también con cualquier
                        otro texto)

Cada subcomando es una función en la tabla "commands", que recibe el texto
que va detrás: añadir uno nuevo es añadir una entrada.
]]

local _, ns = ...
local Util, Api, Recipes, Prices, PlanText = ns.Util, ns.Api, ns.Recipes, ns.Prices, ns.PlanText

local commands = {}

local function setSource(which, label)
    return function(source)
        local ok, reason = Prices.SetSource(which, source)
        if ok then
            Util.Print("precio de %s: %s", label, Prices.Source(which))
        else
            Util.Print("TSM no acepta ese precio: %s", tostring(reason))
        end
    end
end

commands.venta = setSource("sell", "venta")
commands.compra = setSource("buy", "compra")

-- Qué dice /fundir recetas de dónde sale cada receta.
local STATUS_NOTES = {
    [Recipes.STATUS.DATA] = " (aún sin ver en el juego)",
    [Recipes.STATUS.SAME] = "",
    [Recipes.STATUS.CHANGED] = " (cambiada en el juego: %s)",
    [Recipes.STATUS.NEW] = " (nueva del juego: %s)",
}

function commands.recetas()
    Util.Print("recetas (sí = la sabe este personaje):")
    for _, recipe in ipairs(Recipes.All()) do
        local known = Recipes.IsKnown(recipe)
        local note = STATUS_NOTES[Recipes.Status(recipe)]:format(PlanText.Recipe(recipe))
        print(("  %s %s%s"):format(known and "sí" or "no", PlanText.RecipeName(recipe), note))
    end
    print("  Se leen del juego al abrir la ventana de minería o de alquimia.")
end

function commands.tabla()
    ns.Window.Toggle()
end

function commands.minimapa()
    local shown = ns.Minimap:ToggleShown()
    Util.Print(shown and "botón del minimapa visible." or "botón del minimapa oculto. /fundir minimapa para recuperarlo.")
end

function commands.errores(arg)
    ns.ErrorLog.Command(arg)
end

function commands.ayuda()
    Util.Print("versión %s. Comandos:", Api.AddOnVersion())
    print("  /fundir  -  qué hacer con las menas y lingotes que llevas")
    print("  /fundir tabla  -  tabla de precios de todas las menas y lingotes")
    print("  /fundir minimapa  -  ocultar o mostrar el botón del minimapa")
    print(("  /fundir venta <precio de TSM>  -  con qué precio de TSM se vende (ahora %s)"):format(Prices.Source("sell")))
    print(("  /fundir compra <precio de TSM>  -  con qué precio se compra lo que piden las recetas (ahora %s)"):format(Prices.Source("buy")))
    print("  /fundir recetas  -  qué recetas sabe este personaje")
    print("  /fundir errores  -  errores de Lua apuntados (con un número, uno entero; borrar, vaciar la lista)")
    print("  /fundir ayuda  -  esta ayuda")
end

-- Sin argumentos: el informe, lo que más se usa.
commands[""] = function() ns.ReportWindow.Toggle() end

local Commands = {}
ns.Commands = Commands

-- Ejecuta el subcomando escrito tras /fundir, pasándole el resto del texto.
-- Un subcomando desconocido muestra la ayuda.
function Commands.Run(msg)
    local name, rest = (msg or ""):match("^%s*(%S*)%s*(.-)%s*$")
    local run = commands[name:lower()] or commands.ayuda
    run(rest)
end

-- WoW registra comandos con la convención SLASH_<NOMBRE>1 + SlashCmdList.<NOMBRE>.
SLASH_FRANFUNDIR1 = "/fundir"
SlashCmdList.FRANFUNDIR = Commands.Run
