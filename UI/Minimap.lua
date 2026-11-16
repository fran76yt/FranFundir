--[[
Botón del minimapa de FranFundir
================================

El botón compartido (UI/MinimapButton.lua) con lo propio de este addon:
  clic              informe de lo que llevas en las bolsas
  clic derecho      tabla de precios de todas las menas y lingotes
  arrastrar         moverlo alrededor del minimapa
  /fundir minimapa  ocultarlo o volver a mostrarlo
]]

local _, ns = ...

ns.Minimap = ns.MinimapButton.Create({
    settings = ns.Storage.Minimap,
    tooltip = {
        ns.Const.FRAME.TITLE,
        "Clic: qué hacer con lo que llevas",
        "Clic derecho: tabla de precios",
        "Arrastrar: mover este botón",
        "/fundir minimapa: ocultarlo",
    },
    -- Las ventanas se buscan en ns al hacer clic, no al cargar.
    onClick = {
        LeftButton = function() ns.ReportWindow.Toggle() end,
        RightButton = function() ns.Window.Toggle() end,
    },
})
