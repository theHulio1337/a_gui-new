screenX, screenY = guiGetScreenSize()
_type = type
render = {}

guiElements = {}
guiResourceElements = {}
guiPriority = {}
guiTree = {}
guiHovers = {}
guiClickEvents = {}
guiHoverEvents = {}
guiClickSounds = {}
guiRenderDisabled = {}
guiMoveables = {}
guiAlphas = {}
guiTooltips = {}

movingGui = false

fonts = {}
defaultFont = false

guiAnimatedPositions = {}
guiAnimatedSizes = {}
guiAnimatedAlphas = {}

guiIds = {}
local elementId = 0

local function isGuiDescendant(element, ancestor)
    local parent = guiTree[element]
    while parent do
        if parent == ancestor then return true end
        parent = guiTree[parent]
    end
    return false
end

local function subtreeFront(parent)
    for i, element in ipairs(guiPriority) do
        if element == parent or isGuiDescendant(element, parent) then return i end
    end
    return 1
end

function createGuiElement(type, x, y, w, h, parent)
    if parent and not guiElements[parent] then return false end
    local guiElement = createElement("guiElement")
    elementId = elementId + 1
    guiIds[guiElement] = elementId

    guiElements[guiElement] = {"createGuiElement", type, x, y, w, h, parent}
    guiAlphas[guiElement] = 1
    guiResourceElements[guiElement] = sourceResourceRoot

    if type == "input" then
        setGuiHover(guiElement, "solid", "grey3")
    end

    local priority = 1
    if parent then
        guiTree[guiElement] = parent
        -- Az új gyerek a testvérek ELÉ kerül, nem a hátterük mögé.
        priority = subtreeFront(parent)
    end
    table.insert(guiPriority, priority, guiElement)

    return guiElement
end

function getGuiChilds(guiElement)
    local childs = {}
    for child, parent in pairs(guiTree) do
        if parent == guiElement then
            table.insert(childs, child)
        end
    end
    return childs
end

function getGuiChildsAll(guiElement)
    local childs = {}
    for _, element in ipairs(guiPriority) do
        if isGuiDescendant(element, guiElement) then
            table.insert(childs, element)
        end
    end
    return childs
end

function getGuiPriority(guiElement)
    for i = 1, #guiPriority do
        if guiPriority[i] == guiElement then
            return i
        end
    end
end

local function moveGuiSubtree(guiElement, toFront)
    if not guiElements[guiElement] then return false end
    local group = {}
    for _, element in ipairs(guiPriority) do
        if element == guiElement or isGuiDescendant(element, guiElement) then
            group[#group + 1] = element
        end
    end
    for i = #guiPriority, 1, -1 do
        local element = guiPriority[i]
        if element == guiElement or isGuiDescendant(element, guiElement) then
            table.remove(guiPriority, i)
        end
    end
    local parent = guiTree[guiElement]
    local index
    if parent then
        index = toFront and subtreeFront(parent) or getGuiPriority(parent)
    else
        index = toFront and 1 or (#guiPriority + 1)
    end
    for i, element in ipairs(group) do
        table.insert(guiPriority, index + i - 1, element)
    end
    return true
end

function guiToFront(guiElement)
    return moveGuiSubtree(guiElement, true)
end

function guiToBack(guiElement)
    return moveGuiSubtree(guiElement, false)
end

function setGuiBackground(guiElement, bgtype, color, gradientRotation)
    if bgtype == "gradient" then
        local w, h = guiElements[guiElement][5], guiElements[guiElement][6]
        if guiAnimatedSizes[guiElement] then
            w, h = guiAnimatedSizes[guiElement][1], guiAnimatedSizes[guiElement][2]
        end

        local r, g, b = 0, 0, 0
        local r2, g2, b2 = 0, 0, 0
        if type(color[1]) == "string" then
            r, g, b = getColor(color[1])
            r2, g2, b2 = getColor(color[2])
        elseif type(color[1]) == "table" then
            r, g, b = unpack(color[1])
            r2, g2, b2 = unpack(color[2])
        end
        local gradient = table.concat({w, h, r, g, b, r2, g2, b2, gradientRotation}, "-")
        guiElements[guiElement][8] = bgtype .. ":" .. gradient
    else
        if type(color) == "table" then
            color = RGBToHex(unpack(color))
        end
        guiElements[guiElement][8] = bgtype .. ":" .. color
    end
end

function setGuiParent(guiElement, parent)
    if not guiElements[guiElement] then return false end
    if parent and (not guiElements[parent] or parent == guiElement or isGuiDescendant(parent, guiElement)) then
        return false
    end
    guiElements[guiElement][7] = parent
    guiTree[guiElement] = parent or nil
    return guiToFront(guiElement)
end

function setGuiMoveable(guiElement, boundingBox)
    guiMoveables[guiElement] = boundingBox
end

function setGuiTooltip(guiElement, tooltip)
    guiTooltips[guiElement] = tooltip
end

function setGuiHover(guiElement, bgtype, color, gradientRotation)
    if bgtype == "gradient" then
        local w, h = guiElements[guiElement][5], guiElements[guiElement][6]
        if guiAnimatedSizes[guiElement] then
            w, h = guiAnimatedSizes[guiElement][1], guiAnimatedSizes[guiElement][2]
        end

        local r, g, b = 0, 0, 0
        local r2, g2, b2 = 0, 0, 0
        if type(color[1]) == "string" then
            r, g, b = getColor(color[1])
            r2, g2, b2 = getColor(color[2])
        elseif type(color[1]) == "table" then
            r, g, b = unpack(color[1])
            r2, g2, b2 = unpack(color[2])
        end
        local gradient = table.concat({w, h, r, g, b, r2, g2, b2, gradientRotation}, "-")
        guiElements[guiElement][9] = bgtype .. ":" .. gradient
    elseif bgtype then
        guiElements[guiElement][9] = bgtype .. ":" .. color
    end
end

function setHoverEvent(guiElement, event)
    guiHoverEvents[guiElement] = event
end

function getGuiRealPosition(guiElement)
    local x, y = guiElements[guiElement][3], guiElements[guiElement][4]
    for i = 1, #guiPriority do
        if guiTree[guiElement] then
            guiElement = guiTree[guiElement]
            x = x + guiElements[guiElement][3]
            y = y + guiElements[guiElement][4]
        else
            return x, y
        end
    end
    return x, y
end

function setClickEvent(guiElement, event)
    guiClickEvents[guiElement] = event
end

function setClickSound(guiElement, sound)
    guiClickSounds[guiElement] = sound
end

function setGuiPositionAnimated(guiElement, x, y, duration, easing)
    guiAnimatedPositions[guiElement] = {x, y, duration, easing}
end

function setGuiPositionAnimatedOnChilds(guiElement, x, y, duration, easing)
    local childs = getGuiChildsAll(guiElement)
    for i = 1, #childs do
        setGuiPositionAnimated(childs[i], guiElements[childs[i]][3] + x, guiElements[childs[i]][4] + y, duration, easing)
    end
    setGuiPositionAnimated(guiElement, guiElements[guiElement][3] + x, guiElements[guiElement][4] + y, duration, easing)
end

function setGuiSizeAnimated(guiElement, x, y, duration, easing)
    guiAnimatedSizes[guiElement] = {x, y, duration, easing}

    if type(guiElements[guiElement][8]) == "string" then
        local bgtype, color = unpack(split(guiElements[guiElement][8], ":"))
        if bgtype == "gradient" then
            local w, h, r, g, b, r2, g2, b2, gradientRotation = unpack(split(color, "-"))
            if (w and h and r and g and b and r2 and g2 and b2 and gradientRotation) then
                guiElements[guiElement][8] = "gradient:" .. table.concat({x, y, r, g, b, r2, g2, b2, gradientRotation}, "-")
            end
        end
    end

    if type(guiElements[guiElement][9]) == "string" then
        local bgtype, color = unpack(split(guiElements[guiElement][9], ":"))
        if bgtype == "gradient" then
            local w, h, r, g, b, r2, g2, b2, gradientRotation = unpack(split(color, "-"))
            if (w and h and r and g and b and r2 and g2 and b2 and gradientRotation) then
                guiElements[guiElement][9] = "gradient:" .. table.concat({x, y, r, g, b, r2, g2, b2, gradientRotation}, "-")
            end
        end
    end
end

function setGuiSizeAnimatedOnChilds(guiElement, x, y, duration, easing)
    local childs = getGuiChildsAll(guiElement)
    for i = 1, #childs do
        setGuiSizeAnimated(childs[i], guiElements[childs[i]][5] + x, guiElements[childs[i]][6] + y, duration, easing)
    end
    setGuiSizeAnimated(guiElement, guiElements[guiElement][5] + x, guiElements[guiElement][6] + y, duration, easing)
end

function setGuiAlpha(guiElement, x)
    guiAlphas[guiElement] = x/255
    guiAnimatedAlphas[guiElement] = nil
    if guiIds[guiElement] then
        colorSwitch["guiAnimatedAlpha:" .. guiIds[guiElement]] = nil
    end
end

function setGuiAlphaAnimated(guiElement, x, duration, easing)
    guiAnimatedAlphas[guiElement] = {x/255, 0, duration, easing}
end

function setGuiAlphaAnimatedOnChilds(guiElement, x, duration, easing)
    local childs = getGuiChildsAll(guiElement)
    for i = 1, #childs do
        setGuiAlphaAnimated(childs[i], x, duration, easing)
    end
    setGuiAlphaAnimated(guiElement, x, duration, easing)
end

function setGuiPosition(guiElement, x, y)
    guiElements[guiElement][3] = x
    guiElements[guiElement][4] = y
    guiAnimatedPositions[guiElement] = nil
    colorSwitch["guiAnimatedPosition:" .. guiIds[guiElement]] = nil
end

local function resizeGradient(guiElement, index, x, y)
    if type(guiElements[guiElement][index]) == "string" then
        local bgtype, color = unpack(split(guiElements[guiElement][index], ":"))
        if bgtype == "gradient" and color then
            local w, h, r, g, b, r2, g2, b2, gradientRotation = unpack(split(color, "-"))
            if (w and h and r and g and b and r2 and g2 and b2 and gradientRotation) then
                guiElements[guiElement][index] = "gradient:" .. table.concat({x, y, r, g, b, r2, g2, b2, gradientRotation}, "-")
            end
        end
    end
end

function setGuiSize(guiElement, x, y)
    guiElements[guiElement][5] = x
    guiElements[guiElement][6] = y
    guiAnimatedSizes[guiElement] = nil
    colorSwitch["guiAnimatedSize:" .. guiIds[guiElement]] = nil
    if guiElements[guiElement][2] ~= "label" then
        resizeGradient(guiElement, 8, x, y)
    end
    resizeGradient(guiElement, 9, x, y)
end

function getGuiPosition(guiElement, x)
    if x then
        if x == "x" then
            return guiElements[guiElement][3]
        elseif x == "y" then
            return guiElements[guiElement][4]
        end
    end
    return guiElements[guiElement][3], guiElements[guiElement][4]
end

function getGuiSize(guiElement, x)
    if x then
        if x == "w" then
            return guiElements[guiElement][5]
        elseif x == "h" then
            return guiElements[guiElement][6]
        end
    end
    return guiElements[guiElement][5], guiElements[guiElement][6]
end

function setGuiRenderDisabled(guiElement, disabled)
    local childs = getGuiChildsAll(guiElement)
    for i = 1, #childs do
        guiRenderDisabled[childs[i]] = disabled
    end
    guiRenderDisabled[guiElement] = disabled
end

function isGuiRenderDisabled(guiElement)
    return guiRenderDisabled[guiElement]
end

function render.rectangle(guiElement, type, x, y, w, h, parent, color, hoverColor)
    local a = guiAlphas[guiElement]
    local r = getElementRadius(guiElement, w, h)
    local isPanel = not parent and w > 40 and h > 40

    if isPanel then
        dxDrawSoftShadow(x, y, w, h, theme.shadowAlpha * a, theme.shadowSize, 3)
        if not parseGradient(color) then
            local cr, cg, cb = getColor(color)
            local br, bg, bb = lighten(cr, cg, cb, 22)
            -- üvegkeret: minden sarok egyformán lekerekítve (alul is, mint felül)
            dxDrawRoundedRect(x, y, w, h, r, tocolor(br, bg, bb, 255 * a))
            x, y, w, h, r = x + 1, y + 1, w - 2, h - 2, math.max(1, r - 1)
        end
    end

    drawElementSurface(guiElement, x, y, w, h, r, color, hoverColor, guiHovers[guiElement], "guiHover:" .. guiIds[guiElement])

    if isPanel then
        dxDrawRectangle(x + r, y, w - r * 2, 1, tocolor(255, 255, 255, 14 * a))
        -- alsó él: ugyanaz a lágy üvegcsík, lekerekített végekkel (mint felül)
        dxDrawRectangle(x + r, y + h - 41, w - r * 2, 1, tocolor(255, 255, 255, 8 * a))
    end
end

function render.image(guiElement, type, x, y, w, h, parent, color, hoverColor, image, imgColor)
    local r, g, b = getColor(imgColor)
    if hoverColor then
        local hr, hg, hb = getColor(hoverColor)
        if guiHovers[guiElement] then
            hr, hg, hb = processColorSwitchEffect(guiElement, hr, hg, hb, 255, 200, "Linear")
        else
            hr, hg, hb = processColorSwitchEffect(guiElement, r, g, b, 255, 200, "Linear")
        end
        r, g, b = hr, hg, hb
    end
    dxDrawImage(x, y, w, h, image, 0, 0, 0, tocolor(r, g, b, (imgColor[4] or 255) * guiAlphas[guiElement]))
end

function setImageFile(guiElement, img)
    guiElements[guiElement][10] = img
end

function setImageColor(guiElement, color)
    if type(color) == "table" then
        color = RGBToHex(unpack(color))
    end
    guiElements[guiElement][11] = color
end

tooltipState = false
function drawTooltip(guiElement, tooltip)
    tooltip = parseGuiText(tooltip, "#ecf0f5")
    if not tooltipState or tooltipState[1] ~= guiElement then
        tooltipState = {guiElement, getTickCount()}
    end
    local p = math.min(1, (getTickCount() - tooltipState[2]) / 180)
    local k = getEasingValue(p, "OutQuad")

    local tw = dxGetTextWidth(tooltip, 1, tooltipFont, true) + 26
    local th = dxGetFontHeight(1, tooltipFont) + 14
    local x = math.min(cx + 16, screenX - tw - 6)
    local y = math.min(cy + 18 + (1 - k) * 6, screenY - th - 6)
    local pr, pg, pb = getColor("primary")

    dxDrawSoftShadow(x, y, tw, th, 48 * k, 10, 3)
    dxDrawRoundedRect(x, y, tw, th, 6, tocolor(42, 49, 64, 245 * k))
    dxDrawRoundedRect(x + 1, y + 1, tw - 2, th - 2, 5, tocolor(14, 17, 23, 245 * k))
    dxDrawRoundedRect(x + 7, y + th / 2 - 3, 6, 6, 3, tocolor(pr, pg, pb, 255 * k))
    dxDrawText(tooltip, x + 18, y, x + tw - 6, y + th, tocolor(236, 240, 245, 255 * k), 1, tooltipFont, "left", "center", false, false, false, containsHex(tooltip), false)
end

local previousHovers = {}
addEventHandler("onClientRender", getRootElement(),
    function()
        previousHovers = guiHovers
        guiHovers = {}

        cx, cy = getCursorPosition()
        if cx and cy then 
            cx = cx * screenX
            cy = cy * screenY
        end

        for k, v in pairs(guiAnimatedAlphas) do
            if not colorSwitch["guiAnimatedAlpha:" .. guiIds[k]] then
                colorSwitch["guiAnimatedAlpha:" .. guiIds[k]] = {guiAlphas[k], 0, 0, 0}
            end

            guiAlphas[k] = processColorSwitchEffect("guiAnimatedAlpha:" .. guiIds[k], v[1], 0, 0, 0, v[3], v[4])

            if guiAlphas[k] == v[1] then
                guiAnimatedAlphas[k] = nil
            end
        end

        for k, v in pairs(guiAnimatedPositions) do
            if not colorSwitch["guiAnimatedPosition:" .. guiIds[k]] then
                colorSwitch["guiAnimatedPosition:" .. guiIds[k]] = {guiElements[k][3], guiElements[k][4], 0, 0}
            end
            local x, y = processColorSwitchEffect("guiAnimatedPosition:" .. guiIds[k], v[1], v[2], 0, 0, v[3], v[4])
            guiElements[k][3] = x
            guiElements[k][4] = y

            if math.ceil(guiElements[k][3]) == v[1] and math.ceil(guiElements[k][4]) == v[2] then
                guiElements[k][3] = math.ceil(guiElements[k][3])
                guiElements[k][4] = math.ceil(guiElements[k][4])
                guiAnimatedPositions[k] = nil
            end
        end

        for k, v in pairs(guiAnimatedSizes) do
            if not colorSwitch["guiAnimatedSize:" .. guiIds[k]] then
                colorSwitch["guiAnimatedSize:" .. guiIds[k]] = {guiElements[k][5], guiElements[k][6], 0, 0}
            end
            local x, y = processColorSwitchEffect("guiAnimatedSize:" .. guiIds[k], v[1], v[2], 0, 0, v[3], v[4])
            guiElements[k][5] = x
            guiElements[k][6] = y

            if math.ceil(guiElements[k][5]) == v[1] and math.ceil(guiElements[k][6]) == v[2] then
                guiElements[k][5] = math.ceil(guiElements[k][5])
                guiElements[k][6] = math.ceil(guiElements[k][6])
                x, y = math.ceil(x), math.ceil(y)
                guiAnimatedSizes[k] = nil

                if type(guiElements[k][8]) == "string" then
                    local bgtype, color = unpack(split(guiElements[k][8], ":"))
                    if bgtype == "gradient" then
                        local w, h, r, g, b, r2, g2, b2, gradientRotation = unpack(split(color, "-"))
                        if (w and h and r and g and b and r2 and g2 and b2 and gradientRotation) then
                            guiElements[k][8] = "gradient:" .. table.concat({x, y, r, g, b, r2, g2, b2, gradientRotation}, "-")
                        end
                    end
                end
            
                if type(guiElements[k][9]) == "string" then
                    local bgtype, color = unpack(split(guiElements[k][9], ":"))
                    if bgtype == "gradient" then
                        local w, h, r, g, b, r2, g2, b2, gradientRotation = unpack(split(color, "-"))
                        if (w and h and r and g and b and r2 and g2 and b2 and gradientRotation) then
                            guiElements[k][9] = "gradient:" .. table.concat({x, y, r, g, b, r2, g2, b2, gradientRotation}, "-")
                        end
                    end
                end
            end
        end

        for i = #guiPriority, 1, -1 do
            local guiElement = guiPriority[i]
            local gui = guiElements[guiElement]

            if not guiRenderDisabled[guiElement] and gui then
                for i = 1, 25 do
                    if not guiElements[guiElement][i] then
                        guiElements[guiElement][i] = false
                    end
                end

                if cx and cy then
                    local _, _, x, y, w, h, parent = unpack(gui)
                    if parent then
                        x, y = getGuiRealPosition(guiElement)
                    end
                    if cx >= x and cx <= x + w and cy >= y and cy <= y + h then
                        guiHovers[guiElement] = true
                    end
                end
                
                if guiHoverEvents[guiElement] then
                    if previousHovers[guiElement] ~= guiHovers[guiElement] then
                        triggerEvent(guiHoverEvents[guiElement], getRootElement(), guiElement, guiHovers[guiElement])
                    end
                end

                local guiFunc = gui[1]
                if guiFunc == "createGuiElement" then
                    if gui[2] == "rectangle" then
                        local _, type, x, y, w, h, parent, color, hoverColor, image = unpack(gui)

                        if color then
                            if parent then
                                x, y = getGuiRealPosition(guiElement)
                            end

                            if render[type] then
                                render[type](guiElement, type, x, y, w, h, parent, color, hoverColor, image)
                            end
                        end
                    elseif gui[2] == "label" then
                        local _, type, x, y, w, h, parent, text, font, alignX, alignY, clip, wordBreak, rotation, color, shadow = unpack(gui)
                        font = font or defaultFont
                        rotation = rotation or 0
                        alignX = alignX or "left"
                        alignY = alignY or "center"
                        color = color or {255, 255, 255}

                        if text and font and alignX and alignY then
                            if parent then
                                x, y = getGuiRealPosition(guiElement)
                            end

                            if render[type] then
                                render[type](guiElement, type, x, y, w, h, parent, text, font, alignX, alignY, clip, wordBreak, rotation, color, shadow)
                            end
                        end
                    elseif gui[2] == "button" then
                        local _, type, x, y, w, h, parent, color, hoverColor, font, textColor, text, padding, alignX, alignY, iconColor, icon, textColor = unpack(gui)
                        font = font or defaultFont
                        textColor = gui[11] or "#ffffff"
                        text = text or ""
                        padding = padding or {0, 0}
                        alignX = alignX or "center"
                        alignY = alignY or "center"
                        iconColor = iconColor or "white"

                        if color then
                            if parent then
                                x, y = getGuiRealPosition(guiElement)
                            end

                            if render[type] then
                                render[type](guiElement, type, x, y, w, h, parent, color, hoverColor, font, textColor, text, padding, alignX, alignY, iconColor, icon)
                            end
                        end
                    elseif gui[2] == "input" then
                        local _, type, x, y, w, h, parent, color, hoverColor, font, placeHolder, padding, iconColor, icon = unpack(gui)
                        font = font or defaultFont
                        placeHolder = placeHolder or ""
                        iconColor = iconColor or "white"
                        color = color or "grey"

                        if not inputValues[guiElement] then
                            inputValues[guiElement] = ""
                        end

                        if placeHolder then
                            if parent then
                                x, y = getGuiRealPosition(guiElement)
                            end

                            if render[type] then
                                render[type](guiElement, type, x, y, w, h, parent, color, hoverColor, font, placeHolder, padding, iconColor, icon)
                            end
                        end
                    elseif gui[2] == "image" then
                        local _, type, x, y, w, h, parent, color, hoverColor, image, imgColor = unpack(gui)
                        imgColor = imgColor or "#ffffff"

                        if image then
                            if parent then
                                x, y = getGuiRealPosition(guiElement)
                            end

                            if render[type] then
                                render[type](guiElement, type, x, y, w, h, parent, color, hoverColor, image, imgColor)
                            end
                        end
                    elseif gui[2] == "checkbox" then
                        local _, type, x, y, w, h, parent, color, hoverColor, font, placeHolder, iconColor, icon, textColor = unpack(gui)
                        color = color or "grey2"
                        font = font or defaultFont
                        placeHolder = placeHolder or ""
                        iconColor = iconColor or "solid:primary"
                        textColor = textColor or "#ffffff"
                        
                        if icon then
                            if parent then
                                x, y = getGuiRealPosition(guiElement)
                            end

                            if render[type] then
                                render[type](guiElement, type, x, y, w, h, parent, color, hoverColor, font, placeHolder, iconColor, icon, textColor)
                            end
                        end
                    elseif gui[2] == "logo" then
                        local _, type, x, y, w, h, parent, color, hoverColor = unpack(gui)
                        
                        if true then
                            if parent then
                                x, y = getGuiRealPosition(guiElement)
                            end

                            if render[type] then
                                render[type](guiElement, type, x, y, w, h, parent, color, hoverColor)
                            end
                        end
                    elseif gui[2] == "slider" then
                        local _, type, x, y, w, h, parent, color, hoverColor, sliderColor = unpack(gui)
                        
                        if sliderColor then
                            if parent then
                                x, y = getGuiRealPosition(guiElement)
                            end

                            if render[type] then
                                render[type](guiElement, type, x, y, w, h, parent, color, hoverColor, sliderColor)
                            end
                        end
                    end
                end
            else
                if not gui then
                    table.remove(guiPriority, i)
                end
            end
        end

        if getKeyState("mouse1") then
            for guiElement in pairs(guiHovers) do
                if guiMoveables[guiElement] then
                    local bx, by, bw, bh = unpack(guiMoveables[guiElement])
                    local x, y = getGuiRealPosition(guiElement)
                    if cx >= x + bx and cx <= x + bx + bw and cy >= y + by and cy <= y + by + bh then
                        if not movingGui then
                            movingGui = {cx - bx - guiElements[guiElement][3], cy - by - guiElements[guiElement][4], guiElement}
                        end
                    end
                end
            end
        else
            movingGui = false
        end
        
        local tooltipShown = false
        for guiElement in pairs(guiHovers) do
            if guiTooltips[guiElement] and not tooltipShown then
                tooltipShown = true
                drawTooltip(guiElement, guiTooltips[guiElement])
            end
        end
        if not tooltipShown then
            tooltipState = false
        end

        if movingGui then
            local guiElement = movingGui[3]
            if guiElements[guiElement] then
                guiElements[guiElement][3] = cx - movingGui[1]
                guiElements[guiElement][4] = cy - movingGui[2]
            else
                movingGui = false
            end
        end
    end, true, "low-99999")

addEventHandler("onClientClick", getRootElement(),
    function(key, state, cx, cy)
        if state == "up" then
            if key == "left" then
                activeInput = false

                for i = #guiPriority, 1, -1 do
                    local guiElement = guiPriority[i]
                    local gui = guiElements[guiElement]
        
                    if gui and not guiRenderDisabled[guiElement] then
                        if cx and cy then
                            local _, type, x, y, w, h, parent = unpack(gui)
                            if parent then
                                x, y = getGuiRealPosition(guiElement)
                            end
                            if cx >= x and cx <= x + w and cy >= y and cy <= y + h then
                                if guiClickEvents[guiElement] then
                                    triggerEvent(guiClickEvents[guiElement], getRootElement(), guiElement)
                                end
                                if guiClickSounds[guiElement] then
                                    playSound(guiClickSounds[guiElement])
                                end
                                if type == "input" then
                                    activeInput = guiElement
                                elseif type == "checkbox" then
                                    checkboxValues[guiElement] = not checkboxValues[guiElement]
                                end
                            end
                        end
                    end
                end
            end
        end
    end
)

addEventHandler("onClientResourceStart", resourceRoot,
    function()
        defaultFont = getFont("BebasNeueBold", 14)
        defaultFont2 = getFont("BebasNeueBold", 14)
        tooltipFont = getFont("BebasNeueBold", 12)

        local file = fileOpen("fa/icons.json")
        local jsonData = fileRead(file, fileGetSize(file))
        faIcons = fromJSON(jsonData)

        jsonData = nil
        fileClose(file)
        collectgarbage("collect")
    end
)

addEventHandler("onClientResourceStop", getRootElement(),
    function(stoppedRes)
        for k, v in pairs(guiResourceElements) do
            if v == source then
                destroyElement(k)
            end
        end
    end
)

addEventHandler("onClientElementDestroy", getRootElement(),
    function()
        if guiElements[source] then
            guiElements[source] = nil
            guiResourceElements[source] = nil
            for i = #guiPriority, 1, -1 do
                if guiPriority[i] == source then table.remove(guiPriority, i) end
            end
            guiTree[source] = nil
            guiHovers[source] = nil
            guiClickEvents[source] = nil
            guiClickSounds[source] = nil
            guiAnimatedPositions[source] = nil
            guiAnimatedSizes[source] = nil
            guiAnimatedAlphas[source] = nil
            guiIds[source] = nil
            guiRenderDisabled[source] = nil
            

            local childs = getGuiChilds(source)
            for i = 1, #childs do
                destroyElement(childs[i])
            end
        end
    end
)

colorSwitch = {}
startingColors = {}
function processColorSwitchEffect(key, r, g, b, a, effectDuration, effectEasingType)
    local effectData = colorSwitch[key] or {}

    r = tonumber(r) or 255
    g = tonumber(g) or 255
    b = tonumber(b) or 255
    a = tonumber(a) or 255

    local hexCode = r .. "," .. g .. "," .. b .. "," .. a

    if not effectData[1] then
        effectData = {r, g, b, a, hexCode}
    end

    effectDuration = tonumber(effectDuration) or 500

    if effectData[5] ~= hexCode then
        startingColors[key] = {unpack(effectData)}
        effectData[5] = hexCode
        effectData[6] = getTickCount()
    end

    if effectData[6] then
        local linearValue = math.min(1, (getTickCount() - effectData[6]) / (tonumber(effectDuration) or 500))
        local easingValue = getEasingValue(linearValue, effectEasingType or "Linear")

        local r2, g2, b2 = interpolateBetween(startingColors[key][1], startingColors[key][2], startingColors[key][3], r, g, b, easingValue, "Linear")
        local a2 = interpolateBetween(startingColors[key][4], 0, 0, a, 0, 0, easingValue, "Linear")
        effectData[1] = r2
        effectData[2] = g2
        effectData[3] = b2
        effectData[4] = a2

        if linearValue >= 1 then
            effectData[1], effectData[2], effectData[3], effectData[4] = r, g, b, a
            effectData[6] = nil
        end
    end

    colorSwitch[key] = effectData

    return effectData[1], effectData[2], effectData[3], effectData[4]
end

addEventHandler("onClientPreRender", getRootElement(),
    function(delta)
    end
)

function togCursor()
    showCursor(not isCursorShowing())
end
bindKey("m", "down", togCursor)
addCommandHandler("togglecursor", togCursor)