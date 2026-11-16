--[[
Tabla de materiales (/fundir tabla)
===================================

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
La ventana se crea la primera vez que se abre y se pone al día sola. Lo que
comparte con el informe (marco, casilla, tooltip) está en UI/BaseWindow.lua.
]]

local _, ns = ...
local Const, Api, Data, Planner, PlanText = ns.Const, ns.Api, ns.Data, ns.Planner, ns.PlanText
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

--------------------------------------------------------------------------------
-- Construcción
--------------------------------------------------------------------------------

local function tableWidth()
    local width = 0
    for _, column in ipairs(W.COLUMNS) do width = width + column.width end
    return width
end

local function createFrame()
    return ns.BaseWindow.Create({
        name = W.NAME,
        width = tableWidth() + 2 * W.PADDING,
        height = -W.TOP + W.ROW_HEIGHT * (#Data.MATERIALS + 1) + W.FOOTER_HEIGHT,
        savedPoint = W.SAVED_POINT,
        onShow = function() Window.Refresh() end,
    })
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
    ns.BaseWindow.AttachItemTooltip(row)
    return row
end

local function createFooter(f)
    local check = ns.BaseWindow.AllRecipesCheck(f)
    check:SetPoint("BOTTOMLEFT", W.PADDING - 4, W.PADDING + 14)
    local text = f:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    text:SetPoint("BOTTOMLEFT", W.PADDING, W.PADDING - 4)
    text:SetWidth(tableWidth())
    text:SetJustifyH("LEFT")
    f.check, f.footer = check, text
end

local function create()
    frame = createFrame()
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
    frame.footer:SetText(PlanText.Sources())
end

function Window.Toggle()
    if not frame then create() end
    frame:SetShown(not frame:IsShown())
end

function Window.IsShown()
    return frame ~= nil and frame:IsShown()
end

ns.BaseWindow.RefreshOn(Window.Refresh)
