local function drawButtonContent(guiElement, x, y, w, h, font, text, padding, alignX, alignY, icon, tr, tg, tb, a)
    text = parseGuiText(text, {tr, tg, tb})
    local coded = containsHex(text)
    local textColor = tocolor(tr, tg, tb, 255 * a)
    if icon then
        local fontH = dxGetFontHeight(1, font)
        local textW = text ~= "" and dxGetTextWidth(text, 1, font, true) or 0
        local size = math.floor(fontH * 1.15)
        local gap = text ~= "" and 8 or 0
        local total = size + gap + textW

        local ix
        if alignX == "left" then
            ix = x + padding[1] + 10
        elseif alignX == "right" then
            ix = x + padding[1] + w - total - 10
        else
            ix = x + padding[1] + w / 2 - total / 2
        end

        local iy
        if alignY == "top" then
            iy = y + padding[2]
        elseif alignY == "bottom" then
            iy = y + padding[2] + h - size
        else
            iy = y + padding[2] + h / 2 - size / 2
        end

        dxDrawImage(ix, iy, size, size, icon, 0, 0, 0, textColor)
        if text ~= "" then
            dxDrawText(text, ix + size + gap, y + padding[2], x + w, y + padding[2] + h, textColor, 1, font, "left", alignY, true, false, false, coded, false)
        end
    else
        dxDrawText(text, x + padding[1], y + padding[2], x + padding[1] + w, y + padding[2] + h, textColor, 1, font, alignX, alignY, true, false, false, coded, false)
    end
end

function render.button(guiElement, type, x, y, w, h, parent, color, hoverColor, font, textColor, text, padding, alignX, alignY, iconColor, icon)
    local a = guiAlphas[guiElement]
    local hovered = guiHovers[guiElement]
    local pressed = hovered and getKeyState("mouse1")

    local press = select(1, processColorSwitchEffect("btnPress:" .. guiIds[guiElement], pressed and 1 or 0, 0, 0, 0, 120, "OutQuad"))
    local inset = press * 1.5
    x, y, w, h = x + inset, y + inset, w - inset * 2, h - inset * 2

    local r = getElementRadius(guiElement, w, h)
    if not parent then
        dxDrawSoftShadow(x, y, w, h, 31 * a, 10, 3)
    end
    local isGradient = drawElementSurface(guiElement, x, y, w, h, r, color, hoverColor, hovered and not pressed)

    -- Felső fényperem és alsó mélységvonal
    if r > 0 and w > r * 2 then
        dxDrawRectangle(x + r, y, w - r * 2, 1, tocolor(255, 255, 255, 28 * a))
        dxDrawRectangle(x + r, y + h - 1, w - r * 2, 1, tocolor(0, 0, 0, 60 * a))
    end

    local tr, tg, tb = getColor(textColor)
    drawButtonContent(guiElement, x, y, w, h, font, text, padding, alignX, alignY, icon, tr, tg, tb, a)
end

function setButtonFont(guiElement, setFont)
    if not fonts[setFont] then
        local size, font = unpack(split(setFont, "/"))
        fonts[setFont] = getFont(font, tonumber(size))
    end
    guiElements[guiElement][10] = fonts[setFont]
end

function setButtonTextColor(guiElement, color)
    guiElements[guiElement][11] = color
end

function setButtonText(guiElement, text)
    guiElements[guiElement][12] = tostring(text or "")
end

function setButtonTextPadding(guiElement, x, y)
    guiElements[guiElement][13] = {x, y}
end

function setButtonTextAlign(guiElement, x, y)
    guiElements[guiElement][14] = x
    guiElements[guiElement][15] = y
end

function setButtonIconColor(guiElement, color)
    guiElements[guiElement][16] = color
end

function setButtonIcon(guiElement, icon)
    local iconDetails = split(icon, ":")
    if iconDetails[1] == "fa" then
        local faDetails = split(iconDetails[2], "/")
        icon = getFaIconFilename(faDetails[1], math.floor(dxGetFontHeight(1, guiElements[guiElement][10] or defaultFont) * 1.15), faDetails[2])
    end
    guiElements[guiElement][17] = icon
end
