--[[
Ventana de materiales (/fundir)
===============================

Una tabla con cada mena y lingote (Data.MATERIALS), una fila por material:

  Material | Vender | Mejor opción | Te deja | Llevas | Ganas

"Te deja" es lo que da por unidad la mejor opción (sin las recetas con
tiempo de reutilización, que no sirven para un montón: esas salen en el
tooltip) y "Ganas", lo que sacas de más con lo que llevas en las bolsas
respecto a venderlo. Al pasar el ratón por una fila sale el tooltip del
objeto, con el detalle de los pasos.

Abajo, una casilla para contar también las recetas que este personaje no
sabe y las fuentes de precio de TSM que se usan.

Window.Rows() calcula las filas sin tocar la interfaz: así se pueden probar.
La ventana se crea la primera vez que se abre y se pone al día sola.
]]

local _, ns = ...
local Const, Util, Api, Storage, Data, Tsm, Planner, Prices, PlanText =
    ns.Const, ns.Util, ns.Api, ns.Storage, ns.Data, ns.Tsm, ns.Planner, ns.Prices, ns.PlanText
local W = Const.WINDOW

local Window = {}
ns.Window = Window

local frame          -- la ventana (nil hasta que se abre)
local rowFrames = {}

--------------------------------------------------------------------------------
-- Datos de las filas
--------------------------------------------------------------------------------

local function rowFor(id)
    local compare = Planner.Compare(id)
    local plan, sell = compare.bulk, compare.sell
    local count = Api.ItemCount(id)
    local row = { id = id, icon = Api.ItemIcon(id), name = (Api.ItemName(id)), count = count }
    row.sell = sell and PlanText.Money(sell) or "—"
    row.best = plan and PlanText.Short(plan) or "sin precio"
    row.value = plan and PlanText.Money(plan.value) or "—"
    local gain = plan and sell and Planner.FirstRecipe(plan) and (plan.value - sell) * count or 0
    row.gain = gain > 0 and PlanText.Gain(gain) or ""
    row.count = count > 0 and tostring(count) or ""
    return row
end

function Window.Rows()
    local rows = {}
    for i, id in ipairs(Data.MATERIALS) do rows[i] = rowFor(id) end
    return rows
end

local function footerText()
    if not Tsm.IsAvailable() then return "Sin precios: hace falta TradeSkillMaster." end
    return ("Precios de TSM. Venta: %s (menos el %d%% de comisión). Compra: %s."):format(
        Prices.Source("sell"), math.floor(Const.AH_CUT * 100 + 0.5), Prices.Source("buy"))
end

--------------------------------------------------------------------------------
-- Construcción
--------------------------------------------------------------------------------

local function tableWidth()
    local width = 0
    for _, column in ipairs(W.COLUMNS) do width = width + column.width end
    return width
end

local function savePoint(f)
    local point, _, relPoint, x, y = f:GetPoint()
    Storage.Settings().point = { point, relPoint, x, y }
end

local function restorePoint(f)
    local p = Storage.Settings().point
    f:ClearAllPoints()
    if p then f:SetPoint(p[1], UIParent, p[2], p[3], p[4]) else f:SetPoint("CENTER") end
end

local function createFrame()
    local height = -W.TOP + W.ROW_HEIGHT * (#Data.MATERIALS + 1) + W.FOOTER_HEIGHT
    local f = CreateFrame("Frame", W.NAME, UIParent, "BasicFrameTemplateWithInset")
    f:SetSize(tableWidth() + 2 * W.PADDING, height)
    f:SetMovable(true)
    f:EnableMouse(true)
    f:RegisterForDrag("LeftButton")
    f:SetScript("OnDragStart", f.StartMoving)
    f:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        savePoint(self)
    end)
    f:SetScript("OnShow", function() Window.Refresh() end)
    table.insert(UISpecialFrames, W.NAME)
    restorePoint(f)
    f:Hide()
    return f
end

local function createTitle(f)
    local title = f.TitleText
    if not title then
        title = f:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
        title:SetPoint("TOP", 0, -5)
    end
    title:SetText(("%s  %s"):format(W.TITLE, Api.AddOnVersion()))
end

-- Una celda por columna, de izquierda a derecha. Devuelve celda por clave.
local function createCells(parent, y, font)
    local cells, x = {}, W.PADDING
    for _, column in ipairs(W.COLUMNS) do
        local cell = parent:CreateFontString(nil, "OVERLAY", font)
        cell:SetPoint("TOPLEFT", x, y)
        cell:SetWidth(column.width)
        cell:SetJustifyH("LEFT")
        cells[column.key] = cell
        x = x + column.width
    end
    return cells
end

local function createHeader(f)
    local cells = createCells(f, W.TOP, "GameFontNormalSmall")
    for _, column in ipairs(W.COLUMNS) do
        cells[column.key]:SetText(column.title)
        cells[column.key]:SetTextColor(unpack(W.HEADER_COLOR))
    end
end

-- Fila: celdas, el icono delante del nombre y el tooltip del objeto al pasar
-- el ratón (con las líneas de este addon).
local function createRow(f, index)
    local y = W.TOP - W.ROW_HEIGHT * index
    local row = CreateFrame("Frame", nil, f)
    row:SetPoint("TOPLEFT", W.PADDING, y)
    row:SetSize(tableWidth(), W.ROW_HEIGHT)
    row.cells = createCells(f, y, "GameFontHighlightSmall")
    row.icon = f:CreateTexture(nil, "OVERLAY")
    row.icon:SetSize(W.ICON_SIZE, W.ICON_SIZE)
    row.icon:SetPoint("TOPLEFT", W.PADDING, y + 2)
    row.cells.name:SetPoint("TOPLEFT", W.PADDING + W.ICON_SIZE + 4, y)
    row:EnableMouse(true)
    row:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetItemByID(self.itemID)
        GameTooltip:Show()
    end)
    row:SetScript("OnLeave", GameTooltip_Hide)
    return row
end

local function createFooter(f)
    local check = ns.Checkbox.Create(f, {
        label = "Contar también las recetas que no sé",
        tooltip = {
            "Recetas que no sabes",
            "Calcula como si supieras todas: para ver qué daría aprenderlas, o qué hacer con otro personaje.",
            "Las que sabes se leen al abrir la ventana de minería o de alquimia.",
        },
        get = Planner.CountsAllRecipes,
        set = Planner.SetCountsAllRecipes,
    })
    check:SetPoint("BOTTOMLEFT", W.PADDING - 4, W.PADDING + 14)
    local text = f:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    text:SetPoint("BOTTOMLEFT", W.PADDING, W.PADDING - 4)
    text:SetWidth(tableWidth())
    text:SetJustifyH("LEFT")
    f.check, f.footer = check, text
end

local function create()
    frame = createFrame()
    createTitle(frame)
    createHeader(frame)
    for i = 1, #Data.MATERIALS do rowFrames[i] = createRow(frame, i) end
    createFooter(frame)
end

--------------------------------------------------------------------------------
-- Poner al día
--------------------------------------------------------------------------------

local function fillRow(rowFrame, row)
    rowFrame.itemID = row.id
    rowFrame.icon:SetTexture(row.icon)
    for _, column in ipairs(W.COLUMNS) do rowFrame.cells[column.key]:SetText(row[column.key]) end
end

function Window.Refresh()
    if not frame or not frame:IsShown() then return end
    for i, row in ipairs(Window.Rows()) do fillRow(rowFrames[i], row) end
    frame.check:Update()
    frame.footer:SetText(footerText())
end

function Window.Toggle()
    if not frame then create() end
    frame:SetShown(not frame:IsShown())
end

function Window.IsShown()
    return frame ~= nil and frame:IsShown()
end

-- Se pone al día al cambiar lo que lleva, lo que sabe, una preferencia o al
-- llegar los datos de un objeto (su nombre e icono).
local refreshSoon = Util.Debounce(W.UPDATE_DELAY, Window.Refresh)
for _, event in ipairs({ "BAG_UPDATE_DELAYED", "GET_ITEM_INFO_RECEIVED" }) do Util.On(event, refreshSoon) end
Util.Listen(Const.MSG.SETTINGS_CHANGED, refreshSoon)
Util.Listen(Const.MSG.RECIPES_CHANGED, refreshSoon)
