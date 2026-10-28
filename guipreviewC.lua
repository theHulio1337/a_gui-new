-- /guipreview – teljes tesztpanel minden a_gui funkcióhoz (exportokon keresztül, ahogy egy külső resource használná)
local gui = exports.a_gui
local sx, sy = guiGetScreenSize()

local W, H = 920, 620
local SIDEBAR = 200
local CONTENT_X, CONTENT_Y = SIDEBAR + 20, 64
local CONTENT_W, CONTENT_H = W - SIDEBAR - 40, H - 84

local preview = nil
local actions = {}
local tabs = {}
local tabButtons = {}
local currentTab = nil
local live = {}
local easingList = {"OutQuad", "OutBack", "OutElastic", "OutBounce", "InOutQuad", "Linear"}
local easingIndex = 1

addEvent("guipreview:click", true)
addEvent("guipreview:hover", true)
addEvent("guipreview:input", true)
addEvent("guipreview:slider", true)

addEventHandler("guipreview:click", root, function(el)
    if actions[el] then actions[el](el) end
end)

-- Segédfüggvények ----------------------------------------------------------
local function label(parent, x, y, w, h, text, font, alignX, color)
    local l = gui:createGuiElement("label", x, y, w, h, parent)
    gui:setLabelText(l, text)
    gui:setLabelFont(l, font or "14/BebasNeueBold")
    gui:setLabelAlignment(l, alignX or "left", "center")
    gui:setLabelColor(l, color or "#e6eaf0")
    return l
end

local function heading(parent, x, y, text)
    label(parent, x, y, 400, 22, text, "16/BebasNeueBold", "left", "primary")
    local line = gui:createGuiElement("rectangle", x, y + 24, CONTENT_W - x - 10, 1, parent)
    gui:setGuiBackground(line, "solid", "grey4")
end

local function button(parent, x, y, w, h, text, bg, hover, onClick, opts)
    opts = opts or {}
    local b = gui:createGuiElement("button", x, y, w, h, parent)
    if type(bg) == "table" then
        gui:setGuiBackground(b, "gradient", bg, opts.rotation or 0)
    else
        gui:setGuiBackground(b, "solid", bg or "grey3")
    end
    if hover then
        if type(hover) == "table" then
            gui:setGuiHover(b, "gradient", hover, opts.rotation or 0)
        else
            gui:setGuiHover(b, "solid", hover)
        end
    end
    gui:setButtonFont(b, opts.font or "14/BebasNeueBold")
    gui:setButtonText(b, text)
    if opts.textColor then gui:setButtonTextColor(b, opts.textColor) end
    if opts.icon then gui:setButtonIcon(b, opts.icon) end
    if opts.align then gui:setButtonTextAlign(b, opts.align, "center") end
    if opts.padding then gui:setButtonTextPadding(b, opts.padding[1], opts.padding[2]) end
    if opts.tooltip then gui:setGuiTooltip(b, opts.tooltip) end
    if opts.sound ~= false then gui:setClickSound(b, opts.sound or "sounds/click1.wav") end
    if onClick then
        gui:setClickEvent(b, "guipreview:click")
        actions[b] = onClick
    end
    return b
end

local function box(parent, x, y, w, h, color)
    local r = gui:createGuiElement("rectangle", x, y, w, h, parent)
    if type(color) == "table" then
        gui:setGuiBackground(r, "gradient", color, 0)
    else
        gui:setGuiBackground(r, "solid", color or "grey2")
    end
    return r
end

local function newTab(name, icon, builder)
    local container = gui:createGuiElement("rectangle", CONTENT_X, CONTENT_Y, CONTENT_W, CONTENT_H, preview)
    builder(container)
    table.insert(tabs, {name = name, icon = icon, container = container})
end

local function selectTab(index)
    gui:setActiveInput(false)
    for i, tab in ipairs(tabs) do
        local active = i == index
        gui:setGuiRenderDisabled(tab.container, not active)
        local b = tabButtons[i]
        gui:setGuiBackground(b, "solid", active and "primary" or "grey2")
        gui:setGuiHover(b, "solid", active and "primary2" or "grey3")
        gui:setButtonTextColor(b, active and "#0e1117" or "#c8cfdb")
    end
    currentTab = index
end

-- Fülek --------------------------------------------------------------------
local function buildButtons(c)
    heading(c, 0, 0, "Gomb változatok")
    button(c, 0, 36, 150, 36, "Elsődleges", "primary", "primary2", nil, {textColor = "#0e1117", tooltip = "solid: primary / hover: primary2"})
    button(c, 160, 36, 150, 36, "Másodlagos", "grey3", "grey4", nil, {tooltip = "solid: grey3 / hover: grey4"})
    button(c, 320, 36, 150, 36, "Veszély", "red", "red2", nil, {tooltip = "solid: red / hover: red2"})
    button(c, 480, 36, 170, 36, "Színátmenet", {"primary", "accent"}, {"accent", "primary"}, nil, {textColor = "#0e1117", tooltip = "gradient hover is"})

    heading(c, 0, 90, "Ikon + igazítás + padding")
    button(c, 0, 126, 150, 36, "Mentés", "grey3", "grey4", nil, {icon = "fa:save"})
    button(c, 160, 126, 150, 36, "Balra", "grey3", "grey4", nil, {icon = "fa:align-left", align = "left"})
    button(c, 320, 126, 150, 36, "Jobbra", "grey3", "grey4", nil, {icon = "fa:align-right", align = "right"})
    button(c, 480, 126, 36, 36, "", "grey3", "grey4", nil, {icon = "fa:cog", tooltip = "Csak ikon"})
    button(c, 526, 126, 124, 36, "Padding 20", "grey3", "grey4", nil, {align = "left", padding = {20, 0}})

    heading(c, 0, 180, "Méretek és színkódolt szöveg")
    button(c, 0, 216, 90, 26, "Kicsi", "grey3", "grey4", nil, {font = "10/Ubuntu"})
    button(c, 100, 216, 140, 34, "Közepes", "grey3", "grey4")
    button(c, 250, 216, 200, 46, "Nagy gomb", "primary", "primary2", nil, {font = "14/UbuntuB", textColor = "#0e1117"})
    button(c, 460, 216, 190, 34, "Szín [color=accent]kiemelés", "grey3", "grey4")

    heading(c, 0, 280, "Kattintás, hang, hover esemény")
    local counter = 0
    local counterLabel = label(c, 170, 316, 200, 34, "Kattintások: 0")
    button(c, 0, 316, 160, 34, "Kattints rám", "primary", "primary2", function()
        counter = counter + 1
        gui:setLabelText(counterLabel, "Kattintások: [color=accent]" .. counter)
    end, {textColor = "#0e1117", sound = "sounds/click2.wav"})

    local hoverBox = box(c, 380, 316, 270, 34, "grey3")
    gui:setGuiHover(hoverBox, "solid", "grey4")
    gui:setHoverEvent(hoverBox, "guipreview:hover")
    live.hoverLabel = label(hoverBox, 0, 0, 270, 34, "Vidd fölém az egeret", "11/Ubuntu", "center")
    live.hoverBox = hoverBox

    heading(c, 0, 370, "Kép elem (FontAwesome ikon, szín, hover)")
    local icons = {"star", "heart", "bolt", "car", "user", "bell", "home", "trophy"}
    for i, name in ipairs(icons) do
        local img = gui:createGuiElement("image", (i - 1) * 56, 406, 40, 40, c)
        gui:setImageFile(img, gui:getFaIconFilename(name, 40))
        gui:setImageColor(img, i % 2 == 0 and "accent" or "primary")
        gui:setGuiHover(img, "solid", "#ffffff")
        gui:setGuiTooltip(img, "fa:" .. name)
    end
end

local function buildInputs(c)
    heading(c, 0, 0, "Beviteli mezők")
    local i1 = gui:createGuiElement("input", 0, 36, 320, 38, c)
    gui:setInputPlaceholder(i1, "Sima szöveg...")
    gui:setInputFont(i1, "11/Ubuntu")
    gui:setInputChangeEvent(i1, "guipreview:input")

    local i2 = gui:createGuiElement("input", 330, 36, 320, 38, c)
    gui:setInputPlaceholder(i2, "Felhasználónév")
    gui:setInputFont(i2, "11/Ubuntu")
    gui:setInputIcon(i2, "fa:user")

    local i3 = gui:createGuiElement("input", 0, 86, 320, 38, c)
    gui:setInputPlaceholder(i3, "Jelszó")
    gui:setInputFont(i3, "11/Ubuntu")
    gui:setInputIcon(i3, "fa:lock")
    gui:setInputPassword(i3, true)

    local i4 = gui:createGuiElement("input", 330, 86, 320, 38, c)
    gui:setInputPlaceholder(i4, "Csak szám (max 6)")
    gui:setInputFont(i4, "11/Ubuntu")
    gui:setInputNumberOnly(i4, true)
    gui:setInputMaxLength(i4, 6)

    local i5 = gui:createGuiElement("input", 0, 136, 320, 38, c)
    gui:setInputPlaceholder(i5, "Csak kisbetű (setInputType)")
    gui:setInputFont(i5, "11/Ubuntu")
    gui:setInputType(i5, "[a-z]")

    local i6 = gui:createGuiElement("input", 330, 136, 320, 38, c)
    gui:setGuiBackground(i6, "solid", "grey3")
    gui:setInputPlaceholder(i6, "Előre kitöltött érték")
    gui:setInputFont(i6, "11/Ubuntu")
    gui:setInputValue(i6, "a_gui előnézet")

    heading(c, 0, 196, "Élő értékek (getInputValue / getActiveInput)")
    live.inputs = {i1, i2, i3, i4, i5, i6}
    live.inputLabels = {}
    local names = {"Sima", "Felhasználó", "Jelszó", "Szám", "Kisbetű", "Kitöltött"}
    for i = 1, 6 do
        live.inputLabels[i] = label(c, 0, 230 + (i - 1) * 24, 650, 22, names[i] .. ": -", "11/Ubuntu")
    end
    live.activeLabel = label(c, 0, 380, 650, 22, "Aktív mező: nincs", "11/UbuntuM")
    live.changeLabel = label(c, 0, 404, 650, 22, "Változás esemény (Sima mező): -", "11/Ubuntu", "left", "#9aa3b5")

    button(c, 0, 440, 160, 34, "Mezők ürítése", "grey3", "grey4", function()
        for _, inp in ipairs(live.inputs) do gui:setInputValue(inp, "") end
    end, {icon = "fa:eraser"})
    button(c, 170, 440, 200, 34, "Fókusz a jelszóra", "grey3", "grey4", function()
        gui:setActiveInput(i3)
    end, {icon = "fa:key"})
end

local function buildSelectors(c)
    heading(c, 0, 0, "Jelölőnégyzetek")
    live.checkboxes = {}
    local texts = {"Emlékezz rám", "Értesítések bekapcsolva", "Bekapcsolt alapból", "Negyedik opció"}
    for i, text in ipairs(texts) do
        local cb = gui:createGuiElement("checkbox", 0, 36 + (i - 1) * 32, 300, 22, c)
        gui:setCheckboxIcon(cb, "fa:check")
        gui:setCheckboxText(cb, text)
        gui:setCheckboxFont(cb, "11/Ubuntu")
        if i == 3 then gui:setCheckboxChecked(cb, true) end
        live.checkboxes[i] = cb
    end
    exports.a_gui:setGuiTooltip(live.checkboxes[1], "isCheckboxChecked() élőben jobbra")
    live.checkboxLabel = label(c, 320, 36, 330, 120, "", "11/Ubuntu")
    gui:setLabelAlignment(live.checkboxLabel, "left", "top")
    gui:setLabelWordBreak(live.checkboxLabel, true)

    button(c, 320, 136, 160, 30, "Összes be", "grey3", "grey4", function()
        for _, cb in ipairs(live.checkboxes) do gui:setCheckboxChecked(cb, true) end
    end)
    button(c, 490, 136, 160, 30, "Összes ki", "grey3", "grey4", function()
        for _, cb in ipairs(live.checkboxes) do gui:setCheckboxChecked(cb, false) end
    end)

    heading(c, 0, 186, "Csúszkák")
    live.sliders = {}
    local colors = {"primary", "accent", "red", "green"}
    for i, color in ipairs(colors) do
        local y = 226 + (i - 1) * 44
        local s = gui:createGuiElement("slider", 0, y, 420, 14, c)
        gui:setGuiBackground(s, "solid", "grey4")
        gui:setSliderColor(s, color)
        gui:setSliderValue(s, i * 0.2)
        gui:setSliderChangeEvent(s, "guipreview:slider")
        live.sliders[i] = {s, label(c, 440, y - 4, 210, 22, "", "11/UbuntuM")}
    end
    button(c, 0, 410, 200, 30, "Értékek alaphelyzetbe", "grey3", "grey4", function()
        for i, data in ipairs(live.sliders) do gui:setSliderValue(data[1], i * 0.2) end
    end)
    live.sliderEventLabel = label(c, 220, 410, 430, 30, "Csúszka esemény: -", "11/Ubuntu", "left", "#9aa3b5")
end

local function buildLabels(c)
    heading(c, 0, 0, "Betűtípusok")
    local fontsList = {"10/BebasNeueBold", "12/BebasNeueBold", "14/BebasNeueBold", "16/BebasNeueBold", "16/Ubuntu", "16/UbuntuL", "16/Poppins", "16/Pricedown"}
    for i, f in ipairs(fontsList) do
        local col, row = (i - 1) % 2, math.floor((i - 1) / 2)
        label(c, col * 330, 34 + row * 32, 320, 30, f .. "  Árvíztűrő", f)
    end

    heading(c, 0, 170, "Igazítás, árnyék, szín, forgatás")
    local frame = box(c, 0, 206, 320, 90, "grey3")
    local aligns = {{"left", "top"}, {"center", "center"}, {"right", "bottom"}}
    for _, al in ipairs(aligns) do
        local l = label(frame, 8, 6, 304, 78, al[1] .. "/" .. al[2], "10/Ubuntu")
        gui:setLabelAlignment(l, al[1], al[2])
    end
    local sh = label(c, 340, 206, 310, 26, "Árnyékolt felirat (setLabelShadow)", "13/UbuntuB")
    gui:setLabelShadow(sh, true)
    label(c, 340, 236, 310, 26, "[color=primary]Primary [color=accent]Accent [color=red]Red [color=green]Green", "12/UbuntuM")
    label(c, 340, 266, 310, 26, "Egyedi hex szín", "12/UbuntuM", "left", "#ff7de9")
    local rot = label(c, 560, 300, 90, 90, "Forgatva", "12/UbuntuB", "center", "accent")
    gui:setLabelAlignment(rot, "center", "center")
    gui:setLabelRotation(rot, -20)

    heading(c, 0, 316, "Sortörés és vágás")
    local wb = label(c, 0, 350, 260, 80, "Ez egy hosszabb szöveg, ami setLabelWordBreak segítségével automatikusan több sorba törik a megadott szélességen belül.", "10/Ubuntu")
    gui:setLabelAlignment(wb, "left", "top")
    gui:setLabelWordBreak(wb, true)
    local clipBox = box(c, 280, 350, 260, 30, "grey3")
    local cl = label(clipBox, 8, 0, 244, 30, "Ez a szöveg túl hosszú, ezért setLabelClip levágja a végét...", "10/Ubuntu")
    gui:setLabelClip(cl, true)
    local tw = label(c, 280, 390, 370, 22, "Árvíztűrő", "12/UbuntuM")
    label(c, 280, 412, 370, 22, ("getLabelTextWidth: %d px, getLabelFontHeight: %d px"):format(gui:getLabelTextWidth(tw), gui:getLabelFontHeight(tw)), "10/Ubuntu", "left", "#9aa3b5")
    label(c, 0, 448, 650, 26, "Alapszín [color=accent]Kiemelt [color=green]Zöld[/color] Kiemelt[/color] Alapszín", "14/BebasNeueBold")
    label(c, 0, 480, 650, 26, "ÁRVÍZTŰRŐ TÜKÖRFÚRÓGÉP — árvíztűrő tükörfúrógép", "16/BebasNeueBold")
end

local function buildAnimations(c)
    heading(c, 0, 0, "Animációk (pozíció / méret / áttetszőség)")
    local stage = box(c, 0, 36, CONTENT_W, 220, "grey")
    local demo = box(stage, 20, 20, 140, 90, {"primary", "accent"})
    local child = box(demo, 10, 10, 40, 40, "grey2")
    label(demo, 0, 60, 140, 26, "Demó + gyerek", "10/UbuntuB", "center", "#0e1117")
    live.easingLabel = label(c, 0, 266, 300, 30, "", "11/UbuntuM")

    local moved, grown, faded, childMoved = false, false, false, false
    local function easing() return easingList[easingIndex] end
    local function refresh() gui:setLabelText(live.easingLabel, "Easing: [color=accent]" .. easing()) end
    refresh()

    button(c, 310, 266, 160, 30, "Easing váltás", "grey3", "grey4", function()
        easingIndex = easingIndex % #easingList + 1
        refresh()
    end, {icon = "fa:sync"})

    local y = 306
    button(c, 0, y, 155, 34, "Mozgatás", "primary", "primary2", function()
        moved = not moved
        gui:setGuiPositionAnimated(demo, moved and 480 or 20, moved and 110 or 20, 700, easing())
    end, {textColor = "#0e1117", icon = "fa:arrows-alt"})
    button(c, 165, y, 155, 34, "Méretezés", "grey3", "grey4", function()
        grown = not grown
        gui:setGuiSizeAnimated(demo, grown and 200 or 140, grown and 110 or 90, 600, easing())
    end, {icon = "fa:expand"})
    button(c, 330, y, 155, 34, "Áttetszőség", "grey3", "grey4", function()
        faded = not faded
        gui:setGuiAlphaAnimatedOnChilds(demo, faded and 50 or 255, 500, easing())
    end, {icon = "fa:adjust"})
    button(c, 495, y, 155, 34, "Gyerek mozgatás", "grey3", "grey4", function()
        childMoved = not childMoved
        gui:setGuiPositionAnimated(child, childMoved and 90 or 10, 10, 500, easing())
    end, {icon = "fa:child"})

    y = y + 46
    button(c, 0, y, 155, 34, "Eltolás +40 (childs)", "grey3", "grey4", function()
        gui:setGuiPositionAnimatedOnChilds(demo, 40, 0, 400, easing())
    end, {font = "10/UbuntuM"})
    button(c, 165, y, 155, 34, "Alaphelyzet", "grey3", "grey4", function()
        moved, grown, faded, childMoved = false, false, false, false
        gui:setGuiPosition(demo, 20, 20)
        gui:setGuiSize(demo, 140, 90)
        gui:setGuiPosition(child, 10, 10)
        gui:setGuiAlpha(demo, 255)
        for _, ch in ipairs(gui:getGuiChildsAll(demo)) do gui:setGuiAlpha(ch, 255) end
    end, {icon = "fa:undo"})
    button(c, 330, y, 155, 34, "Elrejt / mutat", "grey3", "grey4", function()
        gui:setGuiRenderDisabled(demo, not gui:isGuiRenderDisabled(demo))
    end, {icon = "fa:eye-slash"})
    live.animInfo = label(c, 495, y, 160, 34, "", "10/Ubuntu", "left", "#9aa3b5")
    live.demo = demo

    heading(c, 0, 410, "Rétegek (guiToFront / guiToBack)")
    local a = box(c, 0, 446, 120, 60, "primary")
    local b = box(c, 60, 466, 120, 60, "accent")
    button(c, 200, 456, 150, 30, "Türkiz előre", "grey3", "grey4", function() gui:guiToFront(a) end)
    button(c, 360, 456, 150, 30, "Türkiz hátra", "grey3", "grey4", function() gui:guiToBack(a) end)
    button(c, 200, 492, 150, 30, "Narancs előre", "grey3", "grey4", function() gui:guiToFront(b) end)
end

local function buildAlerts(c)
    heading(c, 0, 0, "Értesítések (createAlert)")
    local types = {
        {"error", "Hiba", "red", "red2", "fa:times-circle", "Valami hiba történt!"},
        {"success", "Siker", "green", "green", "fa:check-circle", "Sikeres mentés."},
        {"warning", "Figyelmeztetés", "accent", "accent2", "fa:exclamation-triangle", "Figyelem, alacsony az egyenleged."},
        {"info", "Info", "primary", "primary2", "fa:info-circle", "Új üzeneted érkezett."},
    }
    for i, t in ipairs(types) do
        button(c, (i - 1) * 165, 36, 155, 38, t[2], t[3], t[4], function()
            gui:createAlert(t[1], t[6])
        end, {textColor = "#0e1117", icon = t[5], sound = "sounds/noti.wav"})
    end
    button(c, 0, 86, 320, 34, "Egymásra halmozás (5 db)", "grey3", "grey4", function()
        for i = 1, 5 do
            local t = types[(i - 1) % 4 + 1]
            gui:createAlert(t[1], i .. ". értesítés: " .. t[6])
        end
    end, {icon = "fa:layer-group"})
    button(c, 330, 86, 320, 34, "Hosszú üzenet", "grey3", "grey4", function()
        gui:createAlert("info", "Ez egy jóval hosszabb értesítés, hogy lásd hogyan nő a doboz a szöveggel.")
    end)
    label(c, 0, 130, 650, 22, "Szerver oldalról: exports.a_gui:createAlert(player, \"success\", \"Üzenet\")", "10/Ubuntu", "left", "#9aa3b5")

    heading(c, 0, 176, "Tooltip (setGuiTooltip)")
    local tips = {"Rövid", "Kicsit hosszabb tooltip szöveg", "A képernyő szélén sem lóg ki"}
    for i, tip in ipairs(tips) do
        local b = box(c, (i - 1) * 220, 212, 210, 60, "grey3")
        gui:setGuiHover(b, "solid", "grey4")
        gui:setGuiTooltip(b, tip)
        label(b, 0, 0, 210, 60, "Vidd fölém (" .. i .. ")", "11/Ubuntu", "center")
    end

    heading(c, 0, 296, "Mozgatható elem (setGuiMoveable)")
    local mv = box(c, 0, 332, 260, 120, "grey2")
    local bar = box(mv, 0, 0, 260, 30, "grey4")
    label(bar, 10, 0, 240, 30, "Fogd meg itt és húzd", "10/UbuntuB")
    label(mv, 10, 40, 240, 70, "Csak a fejléc (0, 0, 260, 30) a fogópont.", "10/Ubuntu", "left", "#9aa3b5")
    gui:setGuiMoveable(mv, {0, 0, 260, 30})
end

local function buildColors(c)
    heading(c, 0, 0, "Színséma (getColorSchemes)")
    local order = {"grey", "grey2", "grey3", "grey4", "primary", "primary2", "accent", "accent2", "red", "red2", "green"}
    local schemes = gui:getColorSchemes()
    for i, name in ipairs(order) do
        local col, row = (i - 1) % 4, math.floor((i - 1) / 4)
        local x, y = col * 165, 36 + row * 82
        local sw = box(c, x, y, 155, 44, name)
        gui:setGuiTooltip(sw, name .. " " .. (schemes[name] and schemes[name].hex or ""))
        label(c, x, y + 46, 155, 20, name, "10/UbuntuB")
        label(c, x, y + 46, 155, 20, schemes[name] and schemes[name].hex or "", "10/Ubuntu", "right", "#9aa3b5")
    end

    heading(c, 0, 290, "Színátmenetek (gradient + forgatás)")
    local grads = {{{"primary", "accent"}, 0}, {{"primary", "accent"}, 45}, {{"primary", "accent"}, 90}, {{"red", "accent"}, 0}, {{"grey4", "primary"}, 180}, {{{40, 90, 255}, {255, 70, 160}}, 30}}
    for i, g in ipairs(grads) do
        local col, row = (i - 1) % 3, math.floor((i - 1) / 3)
        local r = gui:createGuiElement("rectangle", col * 220, 326 + row * 80, 210, 60, c)
        gui:setGuiBackground(r, "gradient", g[1], g[2])
        label(r, 0, 0, 210, 60, g[2] .. "°", "11/UbuntuB", "center", "#0e1117")
    end
end

local function buildLogo(c)
    heading(c, 0, 0, "Logó animáció")
    local logos = {}
    local function spawn()
        for _, l in ipairs(logos) do if isElement(l) then destroyElement(l) end end
        logos = {}
        local sizes = {32, 64, 128, 220}
        local x = 0
        for _, s in ipairs(sizes) do
            table.insert(logos, gui:createGuiElement("logo", x, 60 + (220 - s) / 2, s, s, c))
            x = x + s + 30
        end
    end
    spawn()
    label(c, 0, 290, 650, 22, "32 / 64 / 128 / 220 px – a megfelelő felbontású kép automatikusan töltődik be.", "10/Ubuntu", "left", "#9aa3b5")
    button(c, 0, 320, 200, 34, "Animáció újraindítása", "primary", "primary2", spawn, {textColor = "#0e1117", icon = "fa:redo"})
end

-- Ablak ---------------------------------------------------------------------
local function closePreview()
    if preview and isElement(preview) then
        destroyElement(preview)
    end
    preview = nil
    actions, tabs, tabButtons, live = {}, {}, {}, {}
    gui:setActiveInput(false)
    showCursor(false)
end

local function openPreview()
    preview = gui:createGuiElement("rectangle", sx / 2 - W / 2, sy / 2 - H / 2, W, H)
    gui:setGuiBackground(preview, "solid", "grey2")
    gui:setGuiMoveable(preview, {0, 0, W, 52})

    local logo = gui:createGuiElement("logo", 16, 10, 32, 32, preview)
    label(preview, 58, 6, 300, 22, "a_gui előnézet", "18/BebasNeueBold")
    label(preview, 58, 26, 400, 18, "Minden elem és export egy helyen • /guipreview", "9/Ubuntu", "left", "#9aa3b5")
    button(preview, W - 46, 10, 32, 32, "", "grey3", "red", closePreview, {icon = "fa:times", tooltip = "Bezárás"})

    local sep = gui:createGuiElement("rectangle", 0, 52, W, 1, preview)
    gui:setGuiBackground(sep, "solid", "grey4")
    local side = gui:createGuiElement("rectangle", 10, 62, SIDEBAR - 10, H - 72, preview)
    gui:setGuiBackground(side, "solid", "grey")

    newTab("Gombok", "fa:hand-pointer", buildButtons)
    newTab("Beviteli mezők", "fa:keyboard", buildInputs)
    newTab("Választók", "fa:sliders-h", buildSelectors)
    newTab("Szövegek", "fa:font", buildLabels)
    newTab("Animációk", "fa:magic", buildAnimations)
    newTab("Értesítés / Tooltip", "fa:bell", buildAlerts)
    newTab("Színek", "fa:palette", buildColors)
    newTab("Logó", "fa:star", buildLogo)

    for i, tab in ipairs(tabs) do
        local index = i
        tabButtons[i] = button(side, 8, 8 + (i - 1) * 44, SIDEBAR - 26, 38, tab.name, "grey2", "grey3", function()
            selectTab(index)
        end, {icon = tab.icon, align = "left", sound = "sounds/click3.wav"})
    end
    label(preview, 18, H - 44, SIDEBAR - 26, 30, "Kurzor: M gomb", "9/Ubuntu", "center", "#6b7488")

    selectTab(1)
    showCursor(true)
end

addCommandHandler("guipreview", function()
    if preview and isElement(preview) then
        closePreview()
    else
        openPreview()
    end
end)

-- Élő visszajelzések ---------------------------------------------------------
addEventHandler("guipreview:hover", root, function(el, state)
    if live.hoverBox == el and live.hoverLabel then
        gui:setLabelText(live.hoverLabel, state and "Hover esemény: [color=green]IGEN" or "Hover esemény: [color=red]NEM")
    end
end)

addEventHandler("guipreview:input", root, function(value)
    if live.changeLabel then
        gui:setLabelText(live.changeLabel, "Változás esemény (Sima mező): " .. tostring(value or "(törlés)"))
    end
end)

addEventHandler("guipreview:slider", root, function()
    if live.sliderEventLabel then
        gui:setLabelText(live.sliderEventLabel, "Csúszka esemény: " .. getTickCount())
    end
end)

local lastUpdate = 0
addEventHandler("onClientRender", root, function()
    if not preview or getTickCount() - lastUpdate < 100 then return end
    lastUpdate = getTickCount()

    if live.inputs then
        local names = {"Sima", "Felhasználó", "Jelszó", "Szám", "Kisbetű", "Kitöltött"}
        local active = gui:getActiveInput()
        local activeName = "nincs"
        for i, inp in ipairs(live.inputs) do
            gui:setLabelText(live.inputLabels[i], names[i] .. ": [color=accent]" .. tostring(gui:getInputValue(inp) or ""))
            if active == inp then activeName = names[i] end
        end
        gui:setLabelText(live.activeLabel, "Aktív mező: [color=primary]" .. activeName)
    end

    if live.checkboxes then
        local lines = {}
        for i, cb in ipairs(live.checkboxes) do
            lines[i] = i .. ". " .. (gui:isCheckboxChecked(cb) and "[color=green]bejelölve" or "[color=red]üres")
        end
        gui:setLabelText(live.checkboxLabel, table.concat(lines, "\n"))
    end

    if live.sliders then
        for i, data in ipairs(live.sliders) do
            gui:setLabelText(data[2], ("Érték: [color=accent]%.2f"):format(gui:getSliderValue(data[1]) or 0))
        end
    end

    if live.demo and isElement(live.demo) then
        local x, y = gui:getGuiPosition(live.demo)
        local w, h = gui:getGuiSize(live.demo)
        gui:setLabelText(live.animInfo, ("pos %d,%d\nsize %dx%d"):format(x, y, w, h))
    end
end)
