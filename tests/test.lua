--[[
Pruebas de FranFundir
=====================

Las ejecuta tests/run.js después de cargar la API simulada
(tests/api_stubs.lua) y el addon. Cada check() que pasa escribe "ok" y el
primero que falla para con un error. Al final, __SV guarda las
SavedVariables del personaje para revisarlas (tests/out/).
]]

local ns = FranFundir
local function check(cond, msg) if not cond then error("FALLO: " .. msg) end io.write("ok  ", msg, "\n") end
local function hasPrinted(text) for _, l in ipairs(printed) do if l:find(text, 1, true) then return true end end end
local function step(event, ...) fire(event, ...) runTimers() end
local I = ns.Data.ITEMS

fire("ADDON_LOADED", __ADDON)
loggedIn = true

-- datos: cada material lo gasta alguna receta, y cada receta da algo
local usedSomewhere = true
for _, id in ipairs(ns.Data.MATERIALS) do
  if #ns.Recipes.UsesOf(id) == 0 then usedSomewhere = false end
end
check(usedSomewhere and #ns.Data.RECIPES == 15, "15 recetas y cada material lo gasta alguna")
check(ns.Recipes.QuantityOf(ns.Recipes.UsesOf(I.DARK_IRON_ORE)[1], I.DARK_IRON_ORE) == 8, "el hierro negro gasta 8 menas")

-- nombres y precios
spellnames[2657], spellnames[3304], spellnames[2659] = "Cobre fundido", "Chapa fundida", "Bronce fundido"
spellnames[3307], spellnames[11479], spellnames[14891] = "Hierro fundido", "Transmutar: hierro a oro", "Hierro negro fundido"
names[I.BRONZE_BAR], names[I.COPPER_BAR], names[I.GOLD_BAR], names[I.IRON_BAR] = "Lingote de bronce", "Lingote de cobre", "Lingote de oro", "Lingote de hierro"
names[I.COPPER_ORE], names[I.DARK_IRON_BAR], names[I.DARK_IRON_ORE] = "Mena de cobre", "Lingote de hierro negro", "Mena de hierro negro"
tsm.dbmarket = {
  [I.COPPER_ORE] = 100, [I.COPPER_BAR] = 120, [I.TIN_ORE] = 80, [I.TIN_BAR] = 90, [I.BRONZE_BAR] = 150,
  [I.IRON_ORE] = 300, [I.IRON_BAR] = 400, [I.GOLD_BAR] = 1000, [I.STEEL_BAR] = 380,
  [I.DARK_IRON_ORE] = 500, [I.DARK_IRON_BAR] = 8000,
}
tsm["min(vendorbuy, dbmarket)"] = { [I.TIN_BAR] = 90, [I.COPPER_BAR] = 120, [I.COAL] = 500 }

local P = ns.Prices
check(P.Sell(I.COPPER_ORE) == 95 and P.Sell(I.BRONZE_BAR) == 142, "vender: precio de TSM menos el 5 % de comisión")
prices[I.TIN_ORE] = 90
check(P.Sell(I.TIN_ORE) == 90, "si el vendedor paga más que la subasta, cuenta el vendedor")
prices[I.TIN_ORE] = nil

-- sin recetas sabidas: vender
local Planner = ns.Planner
check(Planner.Best(I.COPPER_ORE).recipe == nil and Planner.Best(I.COPPER_ORE).value == 95, "sin saber fundir, lo mejor es vender la mena")
local tt = { lines = {} }
function tt:AddLine(text) self.lines[#self.lines + 1] = text end
function tt:Show() self.shown = true end
-- Texto del tooltip sin los códigos de color.
local function tooltipFor(id)
  tt.lines = {}
  tooltipCallbacks[1](tt, { id = id })
  return (table.concat(tt.lines, "\n"):gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", ""))
end
local text = tooltipFor(I.COPPER_ORE)
check(text:find("FranFundir", 1, true) and text:find("Vender: 95c", 1, true) and text:find("venderlo tal cual", 1, true), "tooltip: vender, sin recetas")
check(text:find("Abre la ventana de minería", 1, true), "y pide abrir la ventana de minería")
check(tooltipFor(6948) == "", "un objeto que no es material no lleva nada")
tooltipCallbacks[1](tt, { id = SECRET })
check(true, "un ID oculto (valor secreto) no rompe nada")

-- el juego da las mismas recetas que los datos
local function schematic(reagents, output)
  local slots = {}
  for i, r in ipairs(reagents) do slots[i] = { reagents = { { itemID = r[1] } }, quantityRequired = r[2], required = true } end
  return { outputItemID = output[1], quantityMin = output[2], quantityMax = output[2], reagentSlotSchematics = slots }
end
for _, r in ipairs(ns.Data.RECIPES) do schematics[r.spell] = schematic(r.reagents, r.output) end

-- se abren las ventanas de minería y de alquimia
tradeSkill = { 2657, 3304, 2659, 3307, 99999 }
step("TRADE_SKILL_SHOW")
check(FranFundirChar.known[2657] and FranFundirChar.known[2659] and not FranFundirChar.known[99999], "apunta las recetas de minería que sabe (solo las del addon)")
tradeSkill = { 11479 }
step("TRADE_SKILL_LIST_UPDATE")
check(FranFundirChar.known[11479] and FranFundirChar.known[2657], "y las de alquimia, sin olvidar las de minería")
check(FranFundirDB.gameRecipes[2659].output[2] == 2 and not hasPrinted("cambiado"), "guarda lo que da el juego y, si coincide con los datos, no avisa")
check(ns.Recipes.Status(ns.Recipes.BySpell(2659)) == "same" and ns.Recipes.Status(ns.Recipes.BySpell(14891)) == "data", "estado: comprobada en el juego o solo de los datos")

-- cobre: fundir y hacer bronce
local best = Planner.Best(I.COPPER_ORE)
-- lingote de cobre = 2 bronces (142 cada uno) - un lingote de estaño (90) = 194
check(best.recipe.spell == 2657 and best.next.recipe.spell == 2659 and best.value == 194, "mena de cobre: fundir y hacer bronce, 194 por mena")
text = tooltipFor(I.COPPER_ORE)
check(text:find("Mejor: Cobre fundido › Bronce fundido › vender Lingote de bronce — 1p 94c (+99c)", 1, true), "tooltip: los pasos, lo que deja y lo que ganas")
check(not text:find("Abre la ventana", 1, true), "ya no pide abrir la ventana")
-- estaño: el lingote de cobre se compra a 120
check(Planner.Best(I.TIN_ORE).value == 164, "mena de estaño: 2 bronces - un lingote de cobre = 164")

-- hierro: fundir en bulto; transmutar a oro solo como opción con espera
local cmp = Planner.Compare(I.IRON_ORE)
check(cmp.bulk.recipe.spell == 3307 and cmp.bulk.next.recipe == nil and cmp.bulk.value == 380, "mena de hierro: fundir y vender el lingote")
check(cmp.cooldown and cmp.cooldown.next.recipe.spell == 11479 and cmp.cooldown.value == 950, "con espera: transmutar a oro deja más")
text = tooltipFor(I.IRON_ORE)
check(text:find("Con espera (cada 1 h): Hierro fundido › Transmutar: hierro a oro › vender Lingote de oro", 1, true), "tooltip: la transmutación aparte, con su espera")
check(ns.PlanText.Wait({ cooldown = 169200 }) == "cada 2 días", "la arcanita: cada 2 días")
-- el acero (que no sabe) no cuenta; y con carbón a 500 no saldría a cuenta
check(Planner.Best(I.IRON_BAR).recipe == nil, "lingote de hierro: venderlo")

-- recetas que no sabe
check(Planner.Best(I.DARK_IRON_ORE).recipe == nil, "hierro negro sin saber fundirlo: vender la mena")
Planner.SetCountsAllRecipes(true)
check(FranFundirDB.allRecipes == true and Planner.Best(I.DARK_IRON_ORE).value == 950, "contando todas: 8 menas por lingote, 950 cada mena")
Planner.SetCountsAllRecipes(false)
check(FranFundirDB.allRecipes == nil, "y se quita sin dejar nada guardado")

-- sin precios
check(tooltipFor(I.ELEMENTIUM_ORE):find("TSM aún no tiene precio", 1, true), "sin precio de TSM lo dice")
local savedTsm = TSM_API
TSM_API = nil
check(tooltipFor(I.COPPER_ORE):find("hace falta TradeSkillMaster", 1, true), "sin TSM lo dice")
TSM_API = savedTsm

-- tabla de precios
bags[I.COPPER_ORE] = 10
SlashCmdList.FRANFUNDIR("tabla")
runTimers()
local win = _G.FranFundirWindow
check(win and rawget(win, "_shown") == true, "/fundir tabla abre la tabla")
local rows = ns.Window.Rows()
check(#rows == #ns.Data.MATERIALS, "una fila por material")
check(rows[1].name == "Mena de cobre" and rows[1].best == "Lingote de bronce" and rows[1].sell == "95c" and rows[1].value == "1p 94c", "fila del cobre: vender, mejor opción y lo que deja")
check(rows[1].count == "10" and rows[1].gain:find("9p 90c", 1, true), "con 10 menas ganas 9p 90c sobre venderlas")
check(rows[7].best == "Vender" and rows[7].gain == "", "lingote de hierro: vender, sin ganancia")
SlashCmdList.FRANFUNDIR("tabla")
check(rawget(win, "_shown") == false, "otra vez la cierra")

-- informe de las bolsas: todo junto, como si lo fabricaras
names[I.TIN_BAR], names[I.IRON_ORE], names[I.ELEMENTIUM_ORE] = "Lingote de estaño", "Mena de hierro", "Mena de elementium"
names[I.TIN_ORE], names[I.COAL], names[I.STEEL_BAR] = "Mena de estaño", "Carbón", "Lingote de acero"
spellnames[3569] = "Acero fundido"
bags[I.IRON_ORE], bags[I.IRON_BAR], bags[I.TIN_BAR], bags[I.ELEMENTIUM_ORE] = 5, 3, 4, 2
local report = ns.BagReport.Build()
local steps = report.steps
check(#steps == 3 and steps[1].recipe.spell == 2657 and steps[2].recipe.spell == 2659 and steps[3].recipe.spell == 3307, "pasos: fundir el cobre, hacer bronce y fundir el hierro")
local bronze = steps[2]
check(bronze.item == I.COPPER_BAR and bronze.used == 10 and bronze.made[2] == 20, "el bronce, en un solo paso con los 10 lingotes de cobre")
check(bronze.extras[1].id == I.TIN_BAR and bronze.extras[1].own == 4 and bronze.extras[1].buy == 6, "con los 4 lingotes de estaño que llevas y 6 comprados")
check(#report.buys == 1 and report.buys[1].quantity == 6 and report.buys[1].cost == 540, "solo hay que comprar 6 de estaño: 540")
check(#report.sales == 2 and report.sales[1].id == I.IRON_BAR and report.sales[1].count == 8 and report.sales[2].id == I.BRONZE_BAR, "vender: 8 lingotes de hierro (3 + 5 fundidos) y el bronce")
check(#report.noPrice == 1 and report.noPrice[1].id == I.ELEMENTIUM_ORE and #report.cooldown == 2, "el elementium, sin precio; el hierro, mejor aún transmutando")
-- vendiéndolo: 10 cobre a 95, 4 estaño a 85, 5 hierro a 285, 3 lingotes de hierro a 380 = 3855
-- con los consejos: 8 lingotes de hierro a 380 + 20 bronces a 142 - 6 de estaño a 90 = 5340
check(report.totals.sell == 3855 and report.totals.plan == 5340 and report.totals.gain == 1485, "totales: 38p 55c vendiéndolo, 53p 40c con los consejos, ganas 14p 85c")

local blocks = ns.ReportWindow.Blocks()
local function kinds() local k = {} for i, b in ipairs(blocks) do k[i] = b.kind end return table.concat(k, ",") end
check(kinds() == "summary,section,item,item,item,section,item,item,section,item,section,item,item,section,item", "bloques: resumen y cinco secciones")
check(blocks[1].cells[3].value:find("14p 85c", 1, true), "el resumen dice lo que ganas")
check(blocks[2].title == "Qué hacer, por orden", "primero, qué hacer")
check(blocks[3].title == "Cobre fundido: 10 Mena de cobre" and blocks[3].detail == "→ 10 Lingote de cobre" and blocks[3].right == "11p 40c", "fundir: lo que gasta, lo que sale y lo que vale")
check(blocks[4].title == "Bronce fundido: 10 Lingote de cobre" and blocks[4].detail == "con 10 Lingote de estaño (llevas 4, compras 6) → 20 Lingote de bronce" and blocks[4].right == "28p 40c", "bronce: con tus lingotes de estaño y los que faltan")
check(blocks[7].title == "8 Lingote de hierro" and blocks[7].detail == "a 3p 80c cada uno" and blocks[7].right == "30p 40c", "vender: cuántos, a cuánto y lo que deja")
check(blocks[10].title == "6 Lingote de estaño" and blocks[10].detail == "a 90c cada uno" and blocks[10].right == "5p 40c", "comprar: cuántos y lo que cuesta")
check(blocks[12].detail:find("Transmutar: hierro a oro", 1, true) and blocks[12].detail:find("cada 1 h", 1, true), "con espera: la transmutación y cada cuánto")
check(blocks[15].detail == "TSM aún no tiene precio de esto.", "sin precio lo dice")

-- con menas de cobre y de estaño, el estaño se funde antes de hacer bronce
local savedBags = bags
bags = { [I.COPPER_ORE] = 10, [I.TIN_ORE] = 6 }
report = ns.BagReport.Build()
steps = report.steps
check(#steps == 3 and steps[2].recipe.spell == 3304 and steps[3].recipe.spell == 2659, "cobre y estaño: fundir los dos y luego el bronce")
check(steps[3].extras[1].own == 6 and steps[3].extras[1].buy == 4 and report.buys[1].quantity == 4, "el bronce usa los 6 lingotes de estaño fundidos y compra 4")
-- 10 cobre a 95 + 6 estaño a 76 = 1406; 20 bronces a 142 - 4 de estaño a 90 = 2480
check(report.totals.sell == 1406 and report.totals.plan == 2480 and #report.sales == 1, "y solo queda vender el bronce")

-- lo que llevas sin ser material (el carbón) también se usa, y cuenta al vender
Planner.SetCountsAllRecipes(true)
tsm.dbmarket[I.STEEL_BAR], tsm.dbmarket[I.COAL] = 2000, 100
bags = { [I.IRON_BAR] = 3, [I.COAL] = 2 }
report = ns.BagReport.Build()
check(#report.steps == 1 and report.steps[1].recipe.spell == 3569 and report.steps[1].extras[1].own == 2, "acero: con los 2 de carbón que llevas")
check(report.buys[1].id == I.COAL and report.buys[1].quantity == 1, "y compra el que falta")
-- 3 lingotes de hierro a 380 + 2 de carbón a 95 = 1330; 3 aceros a 1900 - 1 carbón a 500 = 5200
check(report.totals.sell == 1330 and report.totals.plan == 5200, "el carbón que llevas cuenta en lo que sacarías vendiéndolo")
tsm.dbmarket[I.STEEL_BAR], tsm.dbmarket[I.COAL] = 380, nil

-- si no llega para una receta, se vende y dice cuántas faltan
bags = { [I.DARK_IRON_ORE] = 5 }
local function blockFor(id) for _, b in ipairs(ns.ReportWindow.Blocks()) do if b.id == id then return b end end end
check(blockFor(I.DARK_IRON_ORE).detail == "a 4p 75c cada uno · faltan 3 para Hierro negro fundido", "5 menas de hierro negro: venderlas, faltan 3 para el lingote")
Planner.SetCountsAllRecipes(false)
bags = savedBags

-- la ventana del informe
SlashCmdList.FRANFUNDIR("")
local rep = _G.FranFundirReport
check(rep and rawget(rep, "_shown") == true, "/fundir abre el informe")
-- Si algún texto de la interfaz dice esto (los marcos simulados se apuntan en frames).
local function painted(text) for _, f in ipairs(frames) do if rawget(f, "_text") == text then return true end end end
check(painted("Cobre fundido: 10 Mena de cobre") and painted("Qué hacer, por orden") and painted("Tabla de precios"), "pinta las filas, las secciones y el botón")
bags[I.COPPER_ORE] = 12
step("BAG_UPDATE_DELAYED")
check(painted("Cobre fundido: 12 Mena de cobre"), "se pone al día al cambiar las bolsas")
bags[I.COPPER_ORE] = 10
SlashCmdList.FRANFUNDIR("")
check(rawget(rep, "_shown") == false, "otra vez lo cierra")

bags = {}
local empty = ns.ReportWindow.Blocks()
check(#empty == 1 and empty[1].text == "No llevas menas ni lingotes en las bolsas.", "sin nada en las bolsas lo dice")
bags = savedBags

-- botón del minimapa
fire("PLAYER_LOGIN")
local button = _G.FranFundirMinimapButton
check(button ~= nil, "crea el botón del minimapa")
rawget(button, "_OnClick")(button, "LeftButton")
check(rawget(rep, "_shown") == true, "clic: el informe")
rawget(button, "_OnClick")(button, "RightButton")
check(rawget(win, "_shown") == true, "clic derecho: la tabla")
rawget(button, "_OnClick")(button, "LeftButton")
rawget(button, "_OnClick")(button, "RightButton")
printed = {}
SlashCmdList.FRANFUNDIR("minimapa")
check(FranFundirChar.minimap.hidden == true and rawget(button, "_shown") == false and hasPrinted("oculto"), "/fundir minimapa lo oculta")
SlashCmdList.FRANFUNDIR("minimapa")
check(not FranFundirChar.minimap.hidden and rawget(button, "_shown") == true, "y lo vuelve a mostrar")

-- comandos
printed = {}
SlashCmdList.FRANFUNDIR("venta dbminbuyout")
check(hasPrinted("TSM no acepta ese precio") and FranFundirDB.sellSource == nil, "un precio que TSM no acepta no se guarda")
tsm.dbminbuyout = { [I.COPPER_ORE] = 200 }
SlashCmdList.FRANFUNDIR("venta dbminbuyout")
check(FranFundirDB.sellSource == "dbminbuyout" and P.Sell(I.COPPER_ORE) == 190, "/fundir venta cambia la fuente de venta")
SlashCmdList.FRANFUNDIR("venta")
check(FranFundirDB.sellSource == nil and P.Source("sell") == "dbmarket", "sin nada vuelve a la de por defecto")
printed = {}
SlashCmdList.FRANFUNDIR("recetas")
check(hasPrinted("sí Cobre fundido") and hasPrinted("no Hierro negro fundido"), "/fundir recetas")
printed = {}
SlashCmdList.FRANFUNDIR("xyz")
check(hasPrinted("versión 0.1.0") and hasPrinted("/fundir venta"), "subcomando desconocido: ayuda")

-- recetas en la ventana sin aprender
unlearned[3569] = true
tradeSkill = { 3307, 3569 }
step("TRADE_SKILL_LIST_UPDATE")
check(FranFundirChar.known[3569] == false and not ns.Recipes.IsKnown(ns.Recipes.BySpell(3569)), "apunta las que salen sin aprender como no sabidas")

-- Forever cambia una receta: el hierro negro pasa a gastar 6 menas
Planner.SetCountsAllRecipes(true)
printed = {}
unlearned[14891] = true
schematics[14891] = schematic({ { I.DARK_IRON_ORE, 6 } }, { I.DARK_IRON_BAR, 1 })
tradeSkill = { 14891 }
step("TRADE_SKILL_LIST_UPDATE")
check(ns.Recipes.QuantityOf(ns.Recipes.BySpell(14891), I.DARK_IRON_ORE) == 6, "una receta cambiada en el juego manda sobre los datos")
check(math.abs(Planner.Best(I.DARK_IRON_ORE).value - 7600 / 6) < 0.01, "y el cálculo la usa: 6 menas por lingote")
check(hasPrinted("Hierro negro fundido ha cambiado en el juego: 6 Mena de hierro negro → Lingote de hierro negro"), "avisa en el chat de lo que ha cambiado")
printed = {}
step("TRADE_SKILL_LIST_UPDATE")
check(not hasPrinted("ha cambiado"), "y solo una vez")

-- una receta nueva que gasta un lingote (y otra que no tiene que ver)
spellnames[99001] = "Receta nueva"
schematics[99001] = schematic({ { I.COPPER_BAR, 1 } }, { I.GOLD_BAR, 1 })
schematics[99002] = schematic({ { 6948, 1 } }, { 6948, 1 })
tradeSkill = { 99001, 99002 }
step("TRADE_SKILL_LIST_UPDATE")
check(hasPrinted("Receta nueva es nueva (no estaba en el addon): Lingote de cobre → Lingote de oro"), "avisa de una receta nueva")
check(FranFundirDB.gameRecipes[99001] and not FranFundirDB.gameRecipes[99002], "guarda solo las que tocan menas o lingotes")
check(Planner.Best(I.COPPER_ORE).next.recipe.spell == 99001 and Planner.Best(I.COPPER_ORE).value == 950, "y el cálculo la usa")

-- una receta que vuelve atrás no deja el cálculo dando vueltas
schematics[99003] = schematic({ { I.GOLD_BAR, 1 } }, { I.COPPER_BAR, 1 })
spellnames[99003] = "Receta circular"
tradeSkill = { 99003 }
step("TRADE_SKILL_LIST_UPDATE")
check(Planner.Best(I.COPPER_ORE).value == 950, "un ciclo entre recetas no se queda colgado")
printed = {}
SlashCmdList.FRANFUNDIR("recetas")
check(hasPrinted("sí Receta nueva (nueva del juego: Lingote de cobre → Lingote de oro)") and hasPrinted("no Hierro negro fundido (cambiada en el juego"), "/fundir recetas dice de dónde sale cada una")
Planner.SetCountsAllRecipes(false)

-- cliente antiguo: la ventana se lee una a una por su posición
local modern = C_TradeSkillUI
C_TradeSkillUI = nil
FranFundirChar.known[3304] = nil
GetNumTradeSkills = function() return 2 end
GetTradeSkillRecipeLink = function(i) if i == 2 then return "|cffffd000|Henchant:3304|h[Chapa fundida]|h|r" end end
GetTradeSkillItemLink = function() return "|cffffffff|Hitem:3576::::::::|h[Lingote de estaño]|h|r" end
GetTradeSkillNumMade = function() return 1, 1 end
GetTradeSkillNumReagents = function() return 1 end
GetTradeSkillReagentItemLink = function() return "|cffffffff|Hitem:2771::::::::|h[Mena de estaño]|h|r" end
GetTradeSkillReagentInfo = function() return "Mena de estaño", nil, 1 end
step("TRADE_SKILL_LIST_UPDATE")
check(FranFundirChar.known[3304] == true and ns.Recipes.Status(ns.Recipes.BySpell(3304)) == "same", "cliente antiguo: lee la receta y lo que gasta")
C_TradeSkillUI = modern

check(#ns.ErrorLog.Entries() == 0, "ningún error apuntado")
check(not hasPrinted("ERROR"), "sin errores de Lua")
__SV = dumpSV()
