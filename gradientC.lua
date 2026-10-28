local shaderRaw = [[
float rotation = 0;
float4 colorFrom = float4(1,1,1,1);
float4 colorTo = float4(1,1,1,1);
float2 boxSize = float2(1,1);
float cornerRadius = 0;
#define PI 3.1415926535897932384626433832795

float4 gradientShader(float2 tex:TEXCOORD0, float4 color:COLOR0):COLOR0{
    float2 p = tex * boxSize;
    float2 q = abs(p - boxSize * 0.5) - (boxSize * 0.5 - cornerRadius);
    float dist = length(max(q, 0)) + min(max(q.x, q.y), 0) - cornerRadius;
    float mask = saturate(0.5 - dist);

    float rad = rotation / 180 * PI;
    float rotSin = sin(rad);
    float rotCos = cos(rad);
    float2 t = tex - 0.5;
    float2 kValue = float2(t.x * rotCos - t.y * rotSin, t.x * rotSin + t.y * rotCos) + 0.5;
    float4 result = colorFrom + (colorTo - colorFrom) * saturate(kValue.x);
    result.a *= mask;
    return result;
}

technique Gradient{
    pass P0{
        SeparateAlphaBlendEnable = true;
        SrcBlendAlpha = One;
        DestBlendAlpha = InvSrcAlpha;
        PixelShader = compile ps_2_0 gradientShader();
    }
}]]

function createGradient(w, h, r, g, b, r2, g2, b2, rotation, radius)
    rotation = rotation or 0
    radius = radius or 0
    local shader = dxCreateShader(shaderRaw)

    dxSetShaderValue(shader, "colorFrom", r / 255, g / 255, b / 255, 1)
    dxSetShaderValue(shader, "colorTo", r2 / 255, g2 / 255, b2 / 255, 1)
    dxSetShaderValue(shader, "rotation", rotation)
    dxSetShaderValue(shader, "boxSize", w, h)
    dxSetShaderValue(shader, "cornerRadius", radius)

    local rt = dxCreateRenderTarget(w, h, true)
    dxSetRenderTarget(rt, true)
    dxSetBlendMode("modulate_add")
    dxDrawImage(0, 0, w, h, shader)
    dxSetBlendMode("blend")
    dxSetRenderTarget()
    local pixels = dxGetTexturePixels(rt, 0, 0, w, h)

    local tex = dxCreateTexture(w, h)
    dxSetTexturePixels(tex, pixels)

    if isElement(shader) then
        destroyElement(shader)
    end
    if isElement(rt) then
        destroyElement(rt)
    end
    pixels = nil
    collectgarbage("collect")

    return tex
end

local gradientCache = {}
function getGradient(w, h, r, g, b, r2, g2, b2, rotation, radius)
    w, h = math.floor(w), math.floor(h)
    radius = math.floor(radius or 0)
    local fileName = "gradients/" .. table.concat({w, h, r, g, b, r2, g2, b2, rotation, "r" .. radius}, "-") .. ".png"
    if not gradientCache[fileName] then
        gradientCache[fileName] = fileExists(fileName)

        if not gradientCache[fileName] then
            local tex = createGradient(w, h, r, g, b, r2, g2, b2, rotation, radius)

            if tex then
                local pixels = dxGetTexturePixels(tex)
                pixels = dxConvertPixels(pixels, "png", 100)

                local file = fileCreate(fileName)
                fileWrite(file, pixels)
                fileClose(file)

                pixels = nil
                destroyElement(tex)
                collectgarbage("collect")
                gradientCache[fileName] = true
            end
        end
    end
    return fileName
end
