sliderValues = {}
sliderEvents = {}
grabSlider = false

function reMap(x, in_min, in_max, out_min, out_max)
    return (x - in_min) * (out_max - out_min) / (in_max - in_min) + out_min
end

function render.slider(guiElement, type, x, y, w, h, parent, color, hoverColor, sliderColor)
    local a = guiAlphas[guiElement]
    local id = guiIds[guiElement]

    if not sliderValues[guiElement] then
        sliderValues[guiElement] = 0
    end
    local v = sliderValues[guiElement]

    local th = math.max(4, math.floor(h * 0.36))
    local ty = y + h / 2 - th / 2
    local left, right = x + h / 2, x + w - h / 2
    local kx = left + (right - left) * v
    local ky = y + h / 2

    if color then
        local r, g, b = getColor(color)
        dxDrawRoundedRect(x, ty, w, th, th / 2, tocolor(r, g, b, 255 * a))
    end

    if sliderColor then
        local r, g, b = getColor(sliderColor)
        dxDrawRoundedRect(x, ty, math.max(th, kx - x), th, th / 2, tocolor(r, g, b, 255 * a))

        local knobR = h / 2 + 2
        local overKnob = cx and cx >= kx - knobR and cx <= kx + knobR and cy >= ky - knobR and cy <= ky + knobR
        local grabbing = grabSlider and grabSlider[1] == guiElement

        local ring = select(1, processColorSwitchEffect("sliderRing:" .. id, (grabbing or overKnob) and 1 or 0, 0, 0, 0, 160, "OutQuad"))
        if ring > 0.01 then
            dxDrawCircleAA(kx, ky, knobR + 5 * ring, tocolor(r, g, b, 60 * ring * a))
        end
        dxDrawCircleAA(kx, ky + 1.5, knobR, tocolor(0, 0, 0, 90 * a))
        dxDrawCircleAA(kx, ky, knobR, tocolor(r, g, b, 255 * a))
        dxDrawCircleAA(kx, ky, knobR * 0.45, tocolor(255, 255, 255, 235 * a))

        if overKnob or grabSlider then
            if getKeyState("mouse1") then
                if not grabSlider then
                    grabSlider = {guiElement}
                elseif grabSlider[1] == guiElement then
                    local nv = math.max(0, math.min(1, reMap(cx, left, right, 0, 1)))
                    local trigger = sliderEvents[guiElement] and sliderValues[guiElement] ~= nv
                    sliderValues[guiElement] = nv
                    if trigger then
                        triggerEvent(sliderEvents[guiElement], getRootElement())
                    end
                end
            elseif grabSlider then
                grabSlider = false
            end
        end
    end
end

function DxDrawBorderedRectangle(x, y, width, height, color1, color2, _width, postGUI)
    local _width = _width or 1
    dxDrawRectangle(x + 1, y + 1, width - 1, height - 1, color1, postGUI)
    dxDrawLine(x, y, x + width, y, color2, _width, postGUI)
    dxDrawLine(x, y, x, y + height, color2, _width, postGUI)
    dxDrawLine(x, y + height, x + width, y + height, color2, _width, postGUI)
    dxDrawLine(x + width, y, x + width, y + height, color2, _width, postGUI)
end

function setSliderChangeEvent(guiElement, event)
    sliderEvents[guiElement] = event
end

function getSliderValue(guiElement)
    return sliderValues[guiElement]
end

function setSliderValue(guiElement, v)
    sliderValues[guiElement] = v
end

function setSliderColor(guiElement, color)
    guiElements[guiElement][10] = color
end
