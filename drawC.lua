-- Közös rajzoló primitívek: lekerekített téglalap, keret, árnyék, kör
theme = {
    radius = 8,
    childRadius = 5,
    shadowSize = 16,
    shadowAlpha = 53, -- az eredeti 120 kb. 44%-a
    borderAlpha = 0.9,
}

local function buildCircleTexture(size, soft)
    local px = {}
    local c = size / 2
    for y = 0, size - 1 do
        for x = 0, size - 1 do
            local dx, dy = x + 0.5 - c, y + 0.5 - c
            local d = math.sqrt(dx * dx + dy * dy)
            local a
            if soft then
                a = math.max(0, 1 - d / c)
                a = a * a * (3 - 2 * a)
            else
                a = math.max(0, math.min(1, c - d + 0.5))
            end
            px[#px + 1] = string.char(255, 255, 255, math.floor(a * 255))
        end
    end
    local lo, hi = size % 256, math.floor(size / 256)
    px[#px + 1] = string.char(lo, hi, lo, hi)
    return dxCreateTexture(table.concat(px), "argb", true, "clamp")
end

local CIRCLE_SIZE = 64
local SHADOW_SIZE = 64
circleTexture = buildCircleTexture(CIRCLE_SIZE, false)
shadowTexture = buildCircleTexture(SHADOW_SIZE, true)

function dxDrawCircleAA(cx, cy, radius, color)
    dxDrawImage(cx - radius, cy - radius, radius * 2, radius * 2, circleTexture, 0, 0, 0, color)
end

function dxDrawRoundedRect(x, y, w, h, r, color)
    if w <= 0 or h <= 0 then return end
    r = math.min(r or theme.radius, w / 2, h / 2)
    if r < 1 then
        dxDrawRectangle(x, y, w, h, color)
        return
    end
    local q = CIRCLE_SIZE / 2
    dxDrawImageSection(x, y, r, r, 0, 0, q, q, circleTexture, 0, 0, 0, color)
    dxDrawImageSection(x + w - r, y, r, r, q, 0, q, q, circleTexture, 0, 0, 0, color)
    dxDrawImageSection(x, y + h - r, r, r, 0, q, q, q, circleTexture, 0, 0, 0, color)
    dxDrawImageSection(x + w - r, y + h - r, r, r, q, q, q, q, circleTexture, 0, 0, 0, color)
    dxDrawRectangle(x + r, y, w - r * 2, h, color)
    if h - r * 2 > 0 then
        dxDrawRectangle(x, y + r, r, h - r * 2, color)
        dxDrawRectangle(x + w - r, y + r, r, h - r * 2, color)
    end
end

-- Keret + kitöltés (1px-es lekerekített körvonal)
function dxDrawRoundedBox(x, y, w, h, r, fillColor, borderColor, borderSize)
    borderSize = borderSize or 1
    if borderColor then
        dxDrawRoundedRect(x, y, w, h, r, borderColor)
        dxDrawRoundedRect(x + borderSize, y + borderSize, w - borderSize * 2, h - borderSize * 2, math.max(0, r - borderSize), fillColor)
    else
        dxDrawRoundedRect(x, y, w, h, r, fillColor)
    end
end

function dxDrawSoftShadow(x, y, w, h, alpha, size, offsetY)
    size = size or theme.shadowSize
    offsetY = offsetY or 4
    local color = tocolor(0, 0, 0, alpha)
    local q = SHADOW_SIZE / 2
    local X, Y = x - size, y - size + offsetY
    local W, H = w + size * 2, h + size * 2
    dxDrawImageSection(X, Y, size, size, 0, 0, q, q, shadowTexture, 0, 0, 0, color)
    dxDrawImageSection(X + W - size, Y, size, size, q, 0, q, q, shadowTexture, 0, 0, 0, color)
    dxDrawImageSection(X, Y + H - size, size, size, 0, q, q, q, shadowTexture, 0, 0, 0, color)
    dxDrawImageSection(X + W - size, Y + H - size, size, size, q, q, q, q, shadowTexture, 0, 0, 0, color)
    dxDrawImageSection(X + size, Y, W - size * 2, size, q - 1, 0, 1, q, shadowTexture, 0, 0, 0, color)
    dxDrawImageSection(X + size, Y + H - size, W - size * 2, size, q - 1, q, 1, q, shadowTexture, 0, 0, 0, color)
    dxDrawImageSection(X, Y + size, size, H - size * 2, 0, q - 1, q, 1, shadowTexture, 0, 0, 0, color)
    dxDrawImageSection(X + W - size, Y + size, size, H - size * 2, q, q - 1, q, 1, shadowTexture, 0, 0, 0, color)
end

function getElementRadius(guiElement, w, h)
    local r = guiTree[guiElement] and theme.childRadius or theme.radius
    if math.min(w, h) <= 4 then
        return 0
    end
    return math.min(r, w / 2, h / 2)
end

function lighten(r, g, b, amount)
    return math.min(255, r + amount), math.min(255, g + amount), math.min(255, b + amount)
end

function parseGradient(colorString)
    local colorDetails = split(colorString, ":")
    if colorDetails[1] ~= "gradient" then
        return false
    end
    local data = {}
    local gradientDetails = split(colorDetails[2], "-")
    for i = 1, 9 do
        data[i] = tonumber(gradientDetails[i])
    end
    return data
end

-- Háttér + hover overlay kirajzolása egységesen
function drawElementSurface(guiElement, x, y, w, h, r, color, hoverColor, hoverActive, hoverKey)
    local alpha = guiAlphas[guiElement]
    local grad = parseGradient(color)
    if grad then
        grad[10] = r
        dxDrawImage(x, y, w, h, getGradient(unpack(grad)), 0, 0, 0, tocolor(255, 255, 255, 255 * alpha))
    else
        local cr, cg, cb = getColor(color)
        dxDrawRoundedRect(x, y, w, h, r, tocolor(cr, cg, cb, 255 * alpha))
    end

    if hoverColor then
        local hgrad = parseGradient(hoverColor)
        local hr, hg, hb = 255, 255, 255
        if not hgrad then
            hr, hg, hb = getColor(hoverColor)
        end
        local _, _, _, ha = processColorSwitchEffect(hoverKey or guiElement, hr, hg, hb, hoverActive and 255 or 0, 180, "OutQuad")
        if ha and ha > 0.5 then
            if hgrad then
                hgrad[10] = r
                dxDrawImage(x, y, w, h, getGradient(unpack(hgrad)), 0, 0, 0, tocolor(255, 255, 255, ha * alpha))
            else
                dxDrawRoundedRect(x, y, w, h, r, tocolor(hr, hg, hb, ha * alpha))
            end
        end
    end
    return grad
end
