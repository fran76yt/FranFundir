--[[
Piezas comunes de las ventanas
==============================

La tabla de materiales (UI/Window.lua) y el informe de lo que llevas
(UI/ReportWindow.lua) se abren, se mueven y se ponen al día igual:

  BaseWindow.Create(spec)           marco con título, que se arrastra,
                                    recuerda su sitio y se cierra con Escape
  BaseWindow.RefreshOn(fn)          llama a fn (agrupando ráfagas) cuando
                                    cambia lo que llevas, lo que sabes o una
                                    preferencia
  BaseWindow.AttachItemTooltip(f)   tooltip del objeto f.itemID al pasar el
                                    ratón (con las líneas de este addon)
  BaseWindow.AllRecipesCheck(f)     casilla "contar también las recetas que
                                    no sé"

spec = { name, title, width, height, savedPoint, onShow }: name es el nombre
global (lo pide Escape), savedPoint la clave de Storage.Settings() donde se
guarda la posición y onShow lo que se hace al abrirla.
]]

local _, ns = ...
local Const, Util, Api, Storage, Planner = ns.Const, ns.Util, ns.Api, ns.Storage, ns.Planner

local BaseWindow = {}
ns.BaseWindow = BaseWindow

--------------------------------------------------------------------------------
-- Posición
--------------------------------------------------------------------------------

local function savePoint(f, key)
    local point, _, relPoint, x, y = f:GetPoint()
    Storage.Settings()[key] = { point, relPoint, x, y }
end

local function restorePoint(f, key)
    local p = Storage.Settings()[key]
    f:ClearAllPoints()
    if p then f:SetPoint(p[1], UIParent, p[2], p[3], p[4]) else f:SetPoint("CENTER") end
end

local function makeMovable(f, key)
    f:SetMovable(true)
    f:EnableMouse(true)
    f:RegisterForDrag("LeftButton")
    f:SetScript("OnDragStart", f.StartMoving)
    f:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        savePoint(self, key)
    end)
    restorePoint(f, key)
end

--------------------------------------------------------------------------------
-- Marco
--------------------------------------------------------------------------------

-- La plantilla trae su propio texto de título; en clientes que no lo traen se
-- crea uno igual.
local function setTitle(f, text)
    local title = f.TitleText
    if not title then
        title = f:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
        title:SetPoint("TOP", 0, -5)
    end
    title:SetText(text)
end

local function titleText(subtitle)
    local base = ("%s  %s"):format(Const.FRAME.TITLE, Api.AddOnVersion())
    return subtitle and (base .. "  ·  " .. subtitle) or base
end

function BaseWindow.Create(spec)
    local f = CreateFrame("Frame", spec.name, UIParent, "BasicFrameTemplateWithInset")
    f:SetSize(spec.width, spec.height)
    f:SetFrameStrata("DIALOG")
    makeMovable(f, spec.savedPoint)
    setTitle(f, titleText(spec.subtitle))
    if spec.onShow then f:SetScript("OnShow", spec.onShow) end
    -- Las ventanas de esta lista se cierran con Escape.
    table.insert(UISpecialFrames, spec.name)
    f:Hide()
    return f
end

--------------------------------------------------------------------------------
-- Poner al día
--------------------------------------------------------------------------------

-- Se pone al día al cambiar lo que lleva, lo que sabe, una preferencia o al
-- llegar los datos de un objeto (su nombre e icono).
function BaseWindow.RefreshOn(fn)
    local soon = Util.Debounce(Const.FRAME.UPDATE_DELAY, fn)
    for _, event in ipairs({ "BAG_UPDATE_DELAYED", "GET_ITEM_INFO_RECEIVED" }) do Util.On(event, soon) end
    Util.Listen(Const.MSG.SETTINGS_CHANGED, soon)
    Util.Listen(Const.MSG.RECIPES_CHANGED, soon)
end

--------------------------------------------------------------------------------
-- Piezas
--------------------------------------------------------------------------------

function BaseWindow.AttachItemTooltip(f)
    f:EnableMouse(true)
    f:SetScript("OnEnter", function(self)
        if not self.itemID then return end
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetItemByID(self.itemID)
        GameTooltip:Show()
    end)
    f:SetScript("OnLeave", GameTooltip_Hide)
end

function BaseWindow.AllRecipesCheck(parent)
    return ns.Checkbox.Create(parent, {
        label = "Contar también las recetas que no sé",
        tooltip = {
            "Recetas que no sabes",
            "Calcula como si supieras todas: para ver qué daría aprenderlas, o qué hacer con otro personaje.",
            "Las que sabes se leen al abrir la ventana de minería o de alquimia.",
        },
        get = Planner.CountsAllRecipes,
        set = Planner.SetCountsAllRecipes,
    })
end
