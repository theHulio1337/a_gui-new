local logoStart = {}
local letters = {
    {file = "a.png", delay = 0, phase = 0},
    {file = "s.png", delay = 140, phase = 1.2},
    {file = "t.png", delay = 280, phase = 2.4},
}

local function logoPath(w, h)
    local s = math.max(w, h)
    for _, size in ipairs({32, 64, 128, 256, 512, 1024}) do
        if s <= size then
            return "files/logos/" .. size .. "_"
        end
    end
    return "files/logos/2048_"
end

function render.logo(guiElement, type, x, y, w, h, parent, color, hoverColor)
    local a = guiAlphas[guiElement]
    local path = logoPath(w, h)

    if not logoStart[guiElement] then
        logoStart[guiElement] = getTickCount()
    end
    local now = getTickCount()
    local elapsed = now - logoStart[guiElement]

    local pr, pg, pb = unpack(colorSchemes.primary.rgb)
    local ar, ag, ab = unpack(colorSchemes.accent.rgb)
    local lift = h * 0.06

    for i = 1, #letters do
        local letter = letters[i]
        local p = math.max(0, math.min(1, (elapsed - letter.delay) / 650))
        local intro = getEasingValue(p, "OutBack")
        local fade = getEasingValue(p, "OutQuad")

        local wave = (math.sin(now / 1400 + letter.phase) + 1) / 2
        local r, g, b = interpolateBetween(pr, pg, pb, ar, ag, ab, wave * wave, "Linear")

        local float = math.sin(now / 900 + letter.phase) * lift * 0.25
        local oy = (1 - intro) * lift * 3 + float
        local scale = 0.85 + 0.15 * intro
        local lw, lh = w * scale, h * scale
        local lx, ly = x + (w - lw) / 2, y + (h - lh) / 2 + oy

        dxDrawImage(lx, ly + lift * 0.6, lw, lh, path .. letter.file, 0, 0, 0, tocolor(0, 0, 0, 80 * fade * a))
        dxDrawImage(lx, ly, lw, lh, path .. letter.file, 0, 0, 0, tocolor(r, g, b, 255 * fade * a))
    end
end

addEventHandler("onClientElementDestroy", getRootElement(),
    function()
        logoStart[source] = nil
    end
)
