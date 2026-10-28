colorSchemes = {
    grey = {
        rgb = {14, 12, 20}
    },
    grey2 = {
        rgb = {20, 16, 29}
    },
    grey3 = {
        rgb = {29, 23, 42}
    },
    grey4 = {
        rgb = {43, 34, 61}
    },
    primary = {
        rgb = {129, 53, 254}
    },
    primary2 = {
        rgb = {158, 101, 255}
    },
    accent = {
        rgb = {190, 145, 255}
    },
    accent2 = {
        rgb = {105, 35, 220}
    },
    red = {
        rgb = {244, 86, 104}
    },
    red2 = {
        rgb = {255, 125, 140}
    },
    green = {
        rgb = {74, 222, 128}
    },
}

function getColorSchemes()
    return colorSchemes
end

function RGBToHex(red, green, blue)
    return string.format("#%.2X%.2X%.2X", red, green, blue)
end

for k, v in pairs(colorSchemes) do
    colorSchemes[k].hex = RGBToHex(unpack(colorSchemes[k].rgb))
end

-- A DX motor csak #RRGGBB kódot ért. Minden felirattípus ugyanitt alakítja át
-- a tageket, az alap-színre visszaváltást és az egymásba ágyazott színezést.
function parseGuiText(text, baseColor)
    text = tostring(text or "")
    if not text:find("[", 1, true) then return text end
    local base = RGBToHex(getColor(baseColor or "#ffffff"))
    local current, stack = base, {}
    return (text:gsub("%[([^%[%]]+)%]", function(tag)
        if tag == "/color" then
            current = table.remove(stack) or base
            return current
        elseif tag == "color=reset" or tag == "color=default" then
            stack, current = {}, base
            return base
        end
        local name = tag:match("^color=%s*(.-)%s*$")
        if not name then return "[" .. tag .. "]" end
        local scheme = colorSchemes[name]
        local hex = scheme and scheme.hex
        if not hex and (name:match("^#%x%x%x%x%x%x$") or name:match("^#%x%x%x$")) then
            hex = RGBToHex(HEXtoRGB(name))
        end
        stack[#stack + 1] = current
        if hex then current = hex end
        -- Ismeretlen szín nem kerül nyersen a feliratra; marad az előző szín.
        return hex or ""
    end))
end

function getColor(c)
    local r, g, b = 0, 0, 0

    if type(c) == "table" then
        r, g, b = unpack(c)
    else
        local type, color = unpack(split(c, ":"))
        if type == "solid" then
            if colorSchemes[color] then
                r, g, b = unpack(colorSchemes[color].rgb)
            elseif utfSub(color, 0, 1) == "#" then
                r, g, b = HEXtoRGB(color)
            end
        elseif type == "gradient" then
            if colorSchemes[color] then
                r, g, b = unpack(colorSchemes[color].rgb)
            elseif utfSub(color, 0, 1) == "#" then
                r, g, b = HEXtoRGB(color)
            end
        else
            if colorSchemes[c] then
                r, g, b = unpack(colorSchemes[c].rgb)
            elseif utfSub(c, 0, 1) == "#" then
                r, g, b = HEXtoRGB(c)
            end
        end
    end

    return r, g, b
end

function HEXtoRGB(hexArg)
	hexArg = hexArg:gsub('#','')

	if(string.len(hexArg) == 3) then
		return tonumber('0x'..hexArg:sub(1,1)) * 17, tonumber('0x'..hexArg:sub(2,2)) * 17, tonumber('0x'..hexArg:sub(3,3)) * 17
	elseif(string.len(hexArg) == 6) then
		return tonumber('0x'..hexArg:sub(1,2)), tonumber('0x'..hexArg:sub(3,4)), tonumber('0x'..hexArg:sub(5,6))
	else
		return 0, 0, 0
	end
end