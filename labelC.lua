function render.label(guiElement, type, x, y, w, h, parent, text, font, alignX, alignY, clip, wordBreak, rotation, color, shadow)
    local a = guiAlphas[guiElement]
    text = parseGuiText(text, color)
    local coded = containsHex(text)
    -- Álló feliratot egész pixelre rajzolunk, 1:1 betűmérettel.
    x, y = math.floor(x + 0.5), math.floor(y + 0.5)
    local right, bottom = math.floor(x + w + 0.5), math.floor(y + h + 0.5)
    local subpixel = rotation ~= 0
    if shadow then
        local plain = string.gsub(text, "#%x%x%x%x%x%x", "")
        dxDrawText(plain, x, y + 2, right, bottom + 2, tocolor(0, 0, 0, 60 * a), 1, font, alignX, alignY, clip, wordBreak, false, false, subpixel, rotation)
        dxDrawText(plain, x, y + 1, right, bottom + 1, tocolor(0, 0, 0, 130 * a), 1, font, alignX, alignY, clip, wordBreak, false, false, subpixel, rotation)
    end
    local r, g, b = getColor(color)
    dxDrawText(text, x, y, right, bottom, tocolor(r, g, b, 255 * a), 1, font, alignX, alignY, clip, wordBreak, false, coded, subpixel, rotation)
end

function containsHex(inputString)
    return type(inputString) == "string" and inputString:find("#%x%x%x%x%x%x") ~= nil
end

function setLabelText(guiElement, text)
    -- Nyers forrás megőrzése: a lezáró tag a később beállított alapszínt is követi.
    guiElements[guiElement][8] = text and tostring(text) or false
end

function setLabelFont(guiElement, setFont)
    if not fonts[setFont] then
        local size, font = unpack(split(setFont, "/"))
        fonts[setFont] = getFont(font, tonumber(size))
    end
    guiElements[guiElement][9] = fonts[setFont]
end

function setLabelAlignment(guiElement, alignX, alignY)
    guiElements[guiElement][10] = alignX
    guiElements[guiElement][11] = alignY
end

function getLabelTextWidth(guiElement)
    local data = guiElements[guiElement]
    return dxGetTextWidth(parseGuiText(data[8], data[15]), 1, data[9] or defaultFont, true)
end

function getLabelFontHeight(guiElement)
    return dxGetFontHeight(1, guiElements[guiElement][9] or defaultFont)
end

function setLabelClip(guiElement, state)
    guiElements[guiElement][12] = state
end

function setLabelWordBreak(guiElement, state)
    guiElements[guiElement][13] = state
end

function setLabelRotation(guiElement, rotation)
    guiElements[guiElement][14] = rotation
end

function setLabelColor(guiElement, color)
    guiElements[guiElement][15] = color
end

function setLabelShadow(guiElement, state)
    guiElements[guiElement][16] = state
end