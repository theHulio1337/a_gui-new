local createdFonts = {}

-- A régi exportnevek megmaradnak; az alapfelület BebasNeueBold-ot használ.
-- Natív, egész pontos méret: dxDrawText alatt nincs felnagyított kis raszter.
local availableFonts = {
    ["Ubuntu"] = {"fonts/BebasNeueBold.otf", 1},
    ["UbuntuB"] = {"fonts/BebasNeueBold.otf", 1},
    ["UbuntuM"] = {"fonts/BebasNeueBold.otf", 1},
    ["UbuntuL"] = {"fonts/BebasNeueLight.otf", 1},
    ["Poppins"] = {"fonts/Poppins-Regular.ttf", 1},
    ["PoppinsB"] = {"fonts/Poppins-Bold.ttf", 1},
    ["PoppinsSB"] = {"fonts/Poppins-SemiBold.ttf", 1},
    ["PoppinsM"] = {"fonts/Poppins-Medium.ttf", 1},
    ["PoppinsL"] = {"fonts/Poppins-Light.ttf", 1},
    ["Pricedown"] = {"fonts/Pricedown.otf", 1},
    ["BebasNeueBold"] = {"fonts/BebasNeueBold.otf", 1},
    ["BebasNeueLight"] = {"fonts/BebasNeueLight.otf", 1},
    ["BebasNeueRegular"] = {"fonts/BebasNeueRegular.otf", 1},
}

function getFont(fontName, fontSize)
    fontSize = tonumber(fontSize)
    local fontData = availableFonts[fontName]
    if not fontData or not fontSize or fontSize ~= fontSize then
        return false
    end
    local size = math.max(5, math.min(150, math.floor(fontSize * fontData[2] + 0.5)))
    local key = fontData[1] .. ":" .. size
    if createdFonts[key] then
        return createdFonts[key]
    end

    local fontElement = dxCreateFont(fontData[1], size, false, "cleartype")
        or dxCreateFont(fontData[1], size, false, "antialiased")
    if fontElement then
        createdFonts[key] = fontElement
        return fontElement
    end
    -- Kevés videomemória esetén se tűnjön el a felirat. A hibát nem cache-eljük.
    return "default-bold"
end
