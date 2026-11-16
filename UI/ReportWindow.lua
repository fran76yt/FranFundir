--[[
Informe de lo que llevas (/fundir y el botón del minimapa)
==========================================================

Pinta los bloques de UI/ReportLayout.lua uno debajo de otro y ajusta el alto
de la ventana a lo que ocupan:

  ┌──────────────────────────────────────────────────────────┐
  │ Venderlo tal cual │ Siguiendo los consejos │    Ganas    │  resumen
  │      12o 30p      │        15o 80p         │   +3o 50p   │
  ├──────────────────────────────────────────────────────────┤
  │ Qué hacer, por orden                     Vale lo que sale│  sección
  │ [ico] Cobre fundido: 20 Mena de cobre           22p 80c  │  fila
  │       → 20 Lingote de cobre                              │
  │ ...                                                      │
  │ [x] Contar también las recetas...    [Tabla de precios]  │  pie
  │ Precios de TSM. Venta: dbmarket ...                      │
  └──────────────────────────────────────────────────────────┘

Cada tipo de bloque tiene un constructor (BUILDERS) que crea su marco con
Fill(block) para rellenarlo y BlockHeight() para saber cuánto ocupa. Los
marcos se reutilizan de una vez para otra (pools): al ponerse al día se
esconden todos y se sacan los que hacen falta, sin crear marcos nuevos cada
vez que cambian las bolsas.
]]

local _, ns = ...
local Const, Api, BagReport, ReportLayout, PlanText, BaseWindow =
    ns.Const, ns.Api, ns.BagReport, ns.ReportLayout, ns.PlanText, ns.BaseWindow
local R = Const.REPORT
local C = R.COLORS
local CONTENT_WIDTH = R.WIDTH - 2 * R.PADDING
local TEXT_LEFT = R.ICON_SIZE + 8          -- donde empieza el texto de las filas

local ReportWindow = {}
ns.ReportWindow = ReportWindow

local frame          -- la ventana (nil hasta que se abre)

--------------------------------------------------------------------------------
-- Piezas sueltas
--------------------------------------------------------------------------------

local function text(parent, font, justify)
    local fs = parent:CreateFontString(nil, "OVERLAY", font)
    fs:SetJustifyH(justify or "LEFT")
    return fs
end

-- Texto de una línea: lo que no cabe se corta con puntos suspensivos (el
-- tooltip del objeto tiene el detalle completo).
local function singleLine(fs, width)
    fs:SetWidth(width)
    fs:SetWordWrap(false)
    return fs
end

local function fill(parent, layer, color)
    local t = parent:CreateTexture(nil, layer)
    t:SetColorTexture(unpack(color))
    return t
end

local function fixedHeight(height)
    return function() return height end
end

local function block(height)
    local w = CreateFrame("Frame", nil, frame)
    w:SetSize(CONTENT_WIDTH, height)
    w.BlockHeight = fixedHeight(height)
    return w
end

--------------------------------------------------------------------------------
-- Constructores, uno por tipo de bloque
--------------------------------------------------------------------------------

local BUILDERS = {}

-- Los totales en celdas iguales, la etiqueta en gris y la cifra en grande.
function BUILDERS.summary()
    local w = block(R.SUMMARY_HEIGHT)
    fill(w, "BACKGROUND", C.SUMMARY_BG):SetAllPoints()
    local cellWidth = CONTENT_WIDTH / R.SUMMARY_CELLS
    w.cells = {}
    for i = 1, R.SUMMARY_CELLS do
        local x = (i - 1) * cellWidth
        local label = text(w, "GameFontNormalSmall", "CENTER")
        label:SetPoint("TOPLEFT", x, -7)
        label:SetWidth(cellWidth)
        label:SetTextColor(unpack(C.LABEL))
        local value = text(w, "GameFontHighlightLarge", "CENTER")
        value:SetPoint("TOPLEFT", x, -22)
        value:SetWidth(cellWidth)
        w.cells[i] = { label = label, value = value }
    end
    function w:Fill(b)
        for i, cell in ipairs(self.cells) do
            local data = b.cells[i]
            cell.label:SetText(data and data.label or "")
            cell.value:SetText(data and data.value or "")
        end
    end
    return w
end

-- Título dorado, a la derecha qué es la columna del dinero, y una raya
-- debajo que separa la sección de lo de arriba.
function BUILDERS.section()
    local w = block(R.SECTION_HEIGHT)
    w.title = text(w, "GameFontNormal")
    w.title:SetPoint("TOPLEFT", 0, -2)
    w.title:SetTextColor(unpack(C.SECTION))
    w.hint = text(w, "GameFontNormalSmall", "RIGHT")
    w.hint:SetPoint("TOPRIGHT", -4, -4)
    w.hint:SetTextColor(unpack(C.LABEL))
    local line = fill(w, "ARTWORK", C.DIVIDER)
    line:SetHeight(1)
    line:SetPoint("BOTTOMLEFT")
    line:SetPoint("BOTTOMRIGHT")
    function w:Fill(b)
        self.title:SetText(b.title)
        self.hint:SetText(b.hint)
    end
    return w
end

-- Icono, dos líneas a la izquierda (qué y qué hacer) y dos a la derecha
-- (dinero y ganancia). Fondo una fila sí y otra no.
function BUILDERS.item()
    local w = block(R.ITEM_HEIGHT)
    w.stripe = fill(w, "BACKGROUND", C.ROW_BG)
    w.stripe:SetAllPoints()
    w.icon = w:CreateTexture(nil, "ARTWORK")
    w.icon:SetSize(R.ICON_SIZE, R.ICON_SIZE)
    w.icon:SetPoint("LEFT", 2, 0)
    local leftWidth = CONTENT_WIDTH - TEXT_LEFT - R.RIGHT_WIDTH
    w.title = singleLine(text(w, "GameFontHighlight"), leftWidth)
    w.title:SetPoint("TOPLEFT", TEXT_LEFT, -3)
    w.detail = singleLine(text(w, "GameFontHighlightSmall"), leftWidth)
    w.detail:SetPoint("TOPLEFT", TEXT_LEFT, -18)
    w.detail:SetTextColor(unpack(C.DETAIL))
    w.right = singleLine(text(w, "GameFontHighlight", "RIGHT"), R.RIGHT_WIDTH)
    w.right:SetPoint("TOPRIGHT", -4, -3)
    w.rightDetail = singleLine(text(w, "GameFontHighlightSmall", "RIGHT"), R.RIGHT_WIDTH)
    w.rightDetail:SetPoint("TOPRIGHT", -4, -18)
    BaseWindow.AttachItemTooltip(w)
    function w:Fill(b, striped)
        self.itemID = b.id
        self.icon:SetTexture(Api.ItemIcon(b.id))
        self.title:SetText(b.title)
        self.detail:SetText(b.detail)
        self.right:SetText(b.right)
        self.rightDetail:SetText(b.rightDetail)
        self.stripe:SetShown(striped)
    end
    return w
end

-- Aviso en gris; mide lo que ocupe su texto.
function BUILDERS.note()
    local w = CreateFrame("Frame", nil, frame)
    w:SetWidth(CONTENT_WIDTH)
    w.text = text(w, "GameFontDisable")
    w.text:SetPoint("TOPLEFT", 0, -2)
    w.text:SetWidth(CONTENT_WIDTH)
    function w:Fill(b)
        self.text:SetText(b.text)
        self:SetHeight(self:BlockHeight())
    end
    function w:BlockHeight()
        return self.text:GetStringHeight() + 6
    end
    return w
end

--------------------------------------------------------------------------------
-- Marcos reutilizados
--------------------------------------------------------------------------------

local pools = {}
for kind in pairs(BUILDERS) do pools[kind] = { widgets = {}, used = 0 } end

local function acquire(kind)
    local pool = pools[kind]
    pool.used = pool.used + 1
    local w = pool.widgets[pool.used]
    if not w then
        w = BUILDERS[kind]()
        pool.widgets[pool.used] = w
    end
    w:Show()
    return w
end

local function releaseAll()
    for _, pool in pairs(pools) do
        for _, w in ipairs(pool.widgets) do w:Hide() end
        pool.used = 0
    end
end

--------------------------------------------------------------------------------
-- Pintar
--------------------------------------------------------------------------------

-- Coloca un bloque en y y devuelve dónde empieza el siguiente.
local function place(b, y, striped)
    local w = acquire(b.kind)
    w:ClearAllPoints()
    w:SetPoint("TOPLEFT", R.PADDING, y)
    w:Fill(b, striped)
    return y - w:BlockHeight() - R.GAP
end

-- Las filas alternan el fondo dentro de cada sección.
local function render(blocks)
    releaseAll()
    local y, striped = R.TOP, false
    for i, b in ipairs(blocks) do
        if b.kind == "section" and i > 1 then y = y - R.SECTION_GAP end
        striped = b.kind == "item" and not striped
        y = place(b, y, striped)
    end
    frame:SetHeight(-y + R.FOOTER_HEIGHT)
end

--------------------------------------------------------------------------------
-- Construcción
--------------------------------------------------------------------------------

local function createButton(f)
    local button = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
    button:SetSize(R.BUTTON_WIDTH, R.BUTTON_HEIGHT)
    button:SetPoint("BOTTOMRIGHT", -R.PADDING, R.PADDING + 14)
    button:SetText("Tabla de precios")
    button:SetScript("OnClick", function() ns.Window.Toggle() end)
end

local function createFooter(f)
    f.check = BaseWindow.AllRecipesCheck(f)
    f.check:SetPoint("BOTTOMLEFT", R.PADDING - 4, R.PADDING + 14)
    createButton(f)
    f.footer = text(f, "GameFontDisableSmall")
    f.footer:SetPoint("BOTTOMLEFT", R.PADDING, R.PADDING - 4)
    f.footer:SetWidth(CONTENT_WIDTH)
end

local function create()
    frame = BaseWindow.Create({
        name = R.NAME,
        subtitle = R.SUBTITLE,
        width = R.WIDTH,
        height = -R.TOP + R.FOOTER_HEIGHT,
        savedPoint = R.SAVED_POINT,
        onShow = function() ReportWindow.Refresh() end,
    })
    createFooter(frame)
end

--------------------------------------------------------------------------------
-- API
--------------------------------------------------------------------------------

-- Los bloques que se pintarían ahora (para las pruebas y para depurar con
-- /dump FranFundir.ReportWindow.Blocks()).
function ReportWindow.Blocks()
    return ReportLayout.Blocks(BagReport.Build())
end

function ReportWindow.Refresh()
    if not frame or not frame:IsShown() then return end
    render(ReportWindow.Blocks())
    frame.check:Update()
    frame.footer:SetText(PlanText.Sources())
end

function ReportWindow.Toggle()
    if not frame then create() end
    frame:SetShown(not frame:IsShown())
end

function ReportWindow.IsShown()
    return frame ~= nil and frame:IsShown()
end

BaseWindow.RefreshOn(ReportWindow.Refresh)
