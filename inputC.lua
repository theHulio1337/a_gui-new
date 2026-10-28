activeInput = false
inputValues = {}
inputMaxLengths = {}
inputChangeEvents = {}
inputNumberOnly = {}
inputPassword = {}
inputTypes = {}

local function caretAlpha()
    return 0.55 + 0.45 * math.cos(getTickCount() / 260)
end

function render.input(guiElement, type, x, y, w, h, parent, color, hoverColor, font, placeHolder, padding, iconColor, icon, textColor)
    local a = guiAlphas[guiElement]
    local id = guiIds[guiElement]
    local focused = activeInput == guiElement
    local r = getElementRadius(guiElement, w, h)

    local pr, pg, pb = getColor("primary")
    local br, bg, bb = getColor("grey4")
    if focused then
        br, bg, bb = pr, pg, pb
    elseif guiHovers[guiElement] then
        br, bg, bb = lighten(br, bg, bb, 18)
    end
    br, bg, bb = processColorSwitchEffect("inputBorder:" .. id, br, bg, bb, 255, 200, "OutQuad")
    local glow = select(1, processColorSwitchEffect("inputGlow:" .. id, focused and 1 or 0, 0, 0, 0, 220, "OutQuad"))

    if glow > 0.01 then
        dxDrawRoundedRect(x - 3, y - 3, w + 6, h + 6, r + 3, tocolor(pr, pg, pb, 45 * glow * a))
    end
    dxDrawRoundedRect(x, y, w, h, r, tocolor(br, bg, bb, 255 * a))
    local isGradient = drawElementSurface(guiElement, x + 1, y + 1, w - 2, h - 2, math.max(0, r - 1), color, hoverColor, guiHovers[guiElement] and not focused)

    local cr, cg, cb = getColor(color)
    local lr, lg, lb = lighten(cr, cg, cb, 95)
    local placeholderColor = isGradient and tocolor(40, 40, 40, 220 * a) or tocolor(lr, lg, lb, 255 * a)

    if icon then
        local isz = h * 0.5
        local ir, ig, ib = 150, 158, 175
        if focused then ir, ig, ib = pr, pg, pb end
        ir, ig, ib = processColorSwitchEffect("inputIcon:" .. id, ir, ig, ib, 255, 200, "OutQuad")
        dxDrawImage(x + h / 2 - isz / 2 + 2, y + h / 2 - isz / 2, isz, isz, icon, 0, 0, 0, tocolor(ir, ig, ib, 255 * a))
        x = x + h
        w = w - h
    end

    local pad = icon and 2 or 12
    local fontH = dxGetFontHeight(1, font)
    local inputValue = inputValues[guiElement]
    if inputPassword[guiElement] then
        inputValue = string.rep("•", utfLen(inputValue))
    end
    local textW = dxGetTextWidth(inputValue, 1, font)
    local hasValue = utfLen(inputValues[guiElement]) > 0
    local overflow = textW > w - pad - 10
    local alignX = overflow and "right" or "left"

    if hasValue then
        dxDrawText(inputValue, x + pad, y, x + w - 10, y + h, tocolor(236, 240, 245, 255 * a), 1, font, alignX, "center", true)
    else
        dxDrawText(placeHolder, x + pad, y, x + w - 10, y + h, placeholderColor, 1, font, "left", "center", true)
    end

    if focused then
        local cx2
        if overflow then
            cx2 = x + w - 9
        else
            cx2 = x + pad + (hasValue and textW + 1 or 0)
        end
        dxDrawRectangle(cx2, y + h / 2 - fontH / 2 + 1, 2, fontH - 2, tocolor(pr, pg, pb, 255 * caretAlpha() * a))
    end
end

function setInputPlaceholder(guiElement, text)
    guiElements[guiElement][11] = text
end

function setInputValue(guiElement, value)
    inputValues[guiElement] = value
end

function setInputFont(guiElement, setFont)
    if not fonts[setFont] then
        local size, font = unpack(split(setFont, "/"))
        fonts[setFont] = getFont(font, tonumber(size))
    end
    guiElements[guiElement][10] = fonts[setFont]
end

function setInputIcon(guiElement, icon)
    local iconDetails = split(icon, ":")
    if iconDetails[1] == "fa" then
        local faDetails = split(iconDetails[2], "/")
        icon = getFaIconFilename(faDetails[1], math.floor(guiElements[guiElement][6] * 0.5), faDetails[2])
    end
    guiElements[guiElement][14] = icon
end

function setInputMaxLength(guiElement, maxLength)
    inputMaxLengths[guiElement] = maxLength
end

function setInputChangeEvent(guiElement, changeEvent)
    inputChangeEvents[guiElement] = changeEvent
end

function setInputNumberOnly(guiElement, state)
    inputNumberOnly[guiElement] = state
end

function setInputColor(guiElement, color)
    guiElements[guiElement][15] = color
end

function setInputPassword(guiElement, state)
    inputPassword[guiElement] = state
end

function getInputValue(guiElement)
    return inputValues[guiElement]
end

function getActiveInput()
    return activeInput
end

function setActiveInput(guiElement)
    activeInput = guiElement
end

function setInputType(guiElement, type)
    inputTypes[guiElement] = type
end

addEventHandler("onClientCharacter", getRootElement(),
    function(character)
        if activeInput and (not inputMaxLengths[activeInput] or (#inputValues[activeInput] < inputMaxLengths[activeInput])) then
            if inputTypes[activeInput] and not string.find(character, inputTypes[activeInput]) then
                return
            end
            if inputNumberOnly[activeInput] and not tonumber(character) then
                return
            end

            inputValues[activeInput] = inputValues[activeInput] .. character
            if inputChangeEvents[activeInput] then
                triggerEvent(inputChangeEvents[activeInput], getRootElement(), inputValues[activeInput])
            end
        end
    end
)

function subFakeInputText(inputname, repeatTheTimer)
    if utf8.len(inputValues[inputname]) > 0 then
        inputValues[inputname] = utf8.sub(inputValues[inputname], 1, -2)

        if repeatTheTimer then
            repeatTimer = setTimer(subFakeInputText, 50, 1, inputname, repeatTheTimer)
        end
        if inputChangeEvents[activeInput] then
            triggerEvent(inputChangeEvents[activeInput], getRootElement())
        end
    end
end

addEventHandler("onClientKey", getRootElement(),
    function(key, press)
        if activeInput then
            cancelEvent()
        end
        if press then
            if activeInput and key == "backspace" then
                subFakeInputText(activeInput)

                if getKeyState(key) then
                    repeatStartTimer = setTimer(subFakeInputText, 500, 1, activeInput, true)
                end
            end
        else
            if isTimer(repeatStartTimer) then
                killTimer(repeatStartTimer)
            end

            if isTimer(repeatTimer) then
                killTimer(repeatTimer)
            end
        end
    end
)
