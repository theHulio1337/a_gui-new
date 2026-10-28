local alerts = {}
local alertTypes = {
    ["error"] = {
        rgb = {244, 86, 104},
        iconName = "times-circle"
    },
    ["success"] = {
        rgb = {74, 222, 128},
        iconName = "check-circle"
    },
    ["warning"] = {
        rgb = {255, 177, 82},
        iconName = "exclamation-triangle"
    },
    ["info"] = {
        rgb = {34, 211, 190},
        iconName = "info-circle"
    },
}

local ALERT_LIFETIME = 10000
local ALERT_FADE = 320
local ALERT_H = 54
local ALERT_GAP = 10
local ALERT_MARGIN = 24

local alertId = 0

function createAlert(type, msg)
    if not alertTypes[type] then
        type = "info"
    end

    if not alertTypes[type].icon then
        alertTypes[type].icon = getFaIconFilename(alertTypes[type].iconName, 40)
    end

    alertId = alertId + 1
    table.insert(alerts, {
        type = type,
        msg = parseGuiText(msg, "#ecf0f5"),
        id = alertId,
        tick = getTickCount()
    })
end

addEvent("createAlert", true)
addEventHandler("createAlert", resourceRoot, createAlert)

addCommandHandler("createalert",
    function(_, type, ...)
        createAlert(type, table.concat({...}, " "))
    end
)

local function drawAlert(alert, index)
    local font = defaultFont2
    local data = alertTypes[alert.type]
    local cr, cg, cb = unpack(data.rgb)

    local tw = dxGetTextWidth(alert.msg, 1, font, true)
    local w = tw + ALERT_H + 28
    local h = ALERT_H
    local targetY = ALERT_MARGIN + (index - 1) * (h + ALERT_GAP)

    local elapsed = getTickCount() - alert.tick
    local inP = getEasingValue(math.min(1, elapsed / ALERT_FADE), "OutBack")
    local outP = getEasingValue(math.max(0, math.min(1, (elapsed - (ALERT_LIFETIME - ALERT_FADE)) / ALERT_FADE)), "InQuad")
    local a = math.min(1, elapsed / ALERT_FADE) * (1 - outP)

    local y = select(1, processColorSwitchEffect("alertY:" .. alert.id, targetY, 0, 0, 0, 250, "OutQuad"))
    local x = (screenX - w) / 2 + (1 - inP) * (screenX / 2 + w / 2) - outP * 60

    dxDrawSoftShadow(x, y, w, h, 62 * a, 18, 4)
    dxDrawRoundedRect(x, y, w, h, 10, tocolor(42, 49, 64, 255 * a))
    dxDrawRoundedRect(x + 1, y + 1, w - 2, h - 2, 9, tocolor(20, 24, 32, 250 * a))

    local iconBox = h - 18
    dxDrawCircleAA(x + 9 + iconBox / 2, y + h / 2, iconBox / 2, tocolor(cr, cg, cb, 40 * a))
    local isz = iconBox * 0.62
    dxDrawImage(x + 9 + iconBox / 2 - isz / 2, y + h / 2 - isz / 2, isz, isz, data.icon, 0, 0, 0, tocolor(cr, cg, cb, 255 * a))

    dxDrawText(alert.msg, x + iconBox + 22, y, x + w - 10, y + h - 3, tocolor(236, 240, 245, 255 * a), 1, font, "left", "center", false, false, false, containsHex(alert.msg), false)

    local life = 1 - math.min(1, elapsed / ALERT_LIFETIME)
    local barW = (w - 20) * life
    dxDrawRectangle(x + 10, y + h - 4, w - 20, 2, tocolor(255, 255, 255, 12 * a))
    dxDrawRectangle(x + 10, y + h - 4, barW, 2, tocolor(cr, cg, cb, 220 * a))
end

addEventHandler("onClientRender", getRootElement(),
    function()
        for i = #alerts, 1, -1 do
            if getTickCount() - alerts[i].tick >= ALERT_LIFETIME then
                colorSwitch["alertY:" .. alerts[i].id] = nil
                table.remove(alerts, i)
            end
        end

        for i = 1, #alerts do
            drawAlert(alerts[i], i)
        end
    end
)