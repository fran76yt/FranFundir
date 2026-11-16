--[[
Simulaciones propias de FranFundir
==================================

tests/run.js lo carga después de la API simulada común (tests/api_stubs.lua)
y antes que el addon: TradeSkillMaster y lo que el cliente moderno da de los
tooltips y de la ventana de profesión.
]]

-- TradeSkillMaster: precios por fuente, tsm[fuente][objeto].
tsm = {}
TSM_API = {
  GetCustomPriceValue = function(source, itemString)
    local id = tonumber(itemString:match("^i:(%d+)$"))
    local t = tsm[source]
    return t and t[id] or nil
  end,
  IsCustomPriceValid = function(source) if tsm[source] then return true end return false, "fuente desconocida" end,
}
-- Tooltips del cliente moderno y ventana de profesión.
tooltipCallbacks = {}
Enum.TooltipDataType = { Item = 0 }
TooltipDataProcessor = { AddTooltipPostCall = function(_, fn) tooltipCallbacks[#tooltipCallbacks + 1] = fn end }
-- tradeSkill: IDs de la ventana abierta; unlearned[id]: sale sin aprender;
-- schematics[id]: lo que gasta y da según el juego.
tradeSkill, unlearned, schematics = nil, {}, {}
C_TradeSkillUI = {
  GetAllRecipeIDs = function() return tradeSkill end,
  GetRecipeInfo = function(id) return { learned = not unlearned[id] } end,
  GetRecipeSchematic = function(id) return schematics[id] end,
}
