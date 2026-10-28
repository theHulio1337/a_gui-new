checkboxValues = {}

function render.checkbox(guiElement, type, x, y, w, h, parent, color, hoverColor, font, placeHolder, iconColor, icon, textColor)
    local a = guiAlphas[guiElement]
    local id = guiIds[guiElement]
    local checked = checkboxValues[guiElement] and true or false
    local r = math.min(theme.childRadius, h / 2)

    local k = select(1, processColorSwitchEffect("cbCheck:" .. id, checked and 1 or 0, 0, 0, 0, 220, "OutQuad"))
    local ar, ag, ab = getColor(iconColor)

    local br, bg, bb = getColor("grey4")
    if guiHovers[guiElement] then
        br, bg, bb = lighten(br, bg, bb, 25)
    end
    br, bg, bb = processColorSwitchEffect("cbBorder:" .. id, br, bg, bb, 255, 180, "OutQuad")
    br, bg, bb = interpolateBetween(br, bg, bb, ar, ag, ab, k, "Linear")

    dxDrawRoundedRect(x, y, h, h, r, tocolor(br, bg, bb, 255 * a))
    drawElementSurface(guiElement, x + 1, y + 1, h - 2, h - 2, math.max(0, r - 1), color, hoverColor, guiHovers[guiElement] and not getKeyState("mouse1"))

    if k > 0.01 then
        dxDrawRoundedRect(x + 1, y + 1, h - 2, h - 2, math.max(0, r - 1), tocolor(ar, ag, ab, 255 * k * a))
        local s = (h - 6) * (0.55 + 0.45 * k)
        dxDrawImage(x + h / 2 - s / 2, y + h / 2 - s / 2, s, s, icon, 0, 0, 0, tocolor(14, 17, 23, 255 * k * a))
    end

    local tr, tg, tb = getColor(textColor)
    placeHolder = parseGuiText(placeHolder, textColor)
    dxDrawText(placeHolder, x + h + 10, y, x + w, y + h, tocolor(tr, tg, tb, (200 + 55 * k) * a), 1, font, "left", "center", true, false, false, containsHex(placeHolder), false)
end

function isCheckboxChecked(guiElement)
    return checkboxValues[guiElement]
end

function setCheckboxChecked(guiElement, state)
    checkboxValues[guiElement] = state
end

function setCheckboxIcon(guiElement, icon)
    local iconDetails = split(icon, ":")
    if iconDetails[1] == "fa" then
        local faDetails = split(iconDetails[2], "/")
        icon = getFaIconFilename(faDetails[1], guiElements[guiElement][6] - 4, faDetails[2])
    end
    guiElements[guiElement][13] = icon
end

function setCheckboxIconColor(guiElement, color)
    guiElements[guiElement][12] = color
end

function setCheckboxFont(guiElement, setFont)
    if not fonts[setFont] then
        local size, font = unpack(split(setFont, "/"))
        fonts[setFont] = getFont(font, tonumber(size))
    end
    guiElements[guiElement][10] = fonts[setFont]
end

function setCheckboxText(guiElement, text)
    guiElements[guiElement][11] = text
end
