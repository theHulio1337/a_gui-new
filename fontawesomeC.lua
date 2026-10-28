local maskSource = [[

	texture MaskTexture;
	sampler implicitMaskTexture = sampler_state
	{
		Texture = <MaskTexture>;
	};


	float4 MaskTextureMain( float2 uv : TEXCOORD0 ) : COLOR0
	{

		float4 sampledTexture = float4(1, 1, 1, 0);

		float4 maskSampled = tex2D( implicitMaskTexture, uv );

		sampledTexture.a = (maskSampled.r + maskSampled.g + maskSampled.b) / 3.0f;

		return sampledTexture;
	}

	technique Technique1
	{
		pass Pass1
		{
			PixelShader = compile ps_2_0 MaskTextureMain();
		}
	}

]]

local faCache = {}
function getFaIconFilename(icon, size, style)
    style = style or "solid"
    local fileName = ":a_gui/faicons/" .. table.concat({icon, size, style}, "-") .. ".png"
    if not faCache[fileName] then
		faCache[fileName] = fileExists(fileName)

		if not faCache[fileName] then
			local font2 = dxCreateFont("fa/" .. style .. ".otf", 100)
			local fontHeight = dxGetFontHeight(1, font2)
			local fontWidth = dxGetTextWidth(utf8.char(tonumber("0x" .. faIcons[icon].unicode)), 1, font2)
			destroyElement(font2)

			local fontSize = ((faIcons[icon].svg[style].height / faIcons[icon].svg[style].width)*size)/(fontHeight/100)
			fontSize = fontSize * 0.8
			--[[if faIcons[icon].svg[style].height > faIcons[icon].svg[style].width then
				fontSize = ((faIcons[icon].svg[style].height / faIcons[icon].svg[style].width)*size)/(fontHeight/100)
			else
				fontSize = ((faIcons[icon].svg[style].width / faIcons[icon].svg[style].height)*size)/(fontWidth/100)
			end]]

			local font = dxCreateFont("fa/" .. style .. ".otf", fontSize)
			local rt = dxCreateRenderTarget(size, size, true)
			local rt2 = dxCreateRenderTarget(size, size, true)
			local shader = dxCreateShader(maskSource)
			if isElement(rt) then
				dxSetShaderValue(shader, "MaskTexture", rt2)

				dxSetRenderTarget(rt2, true)
				dxSetBlendMode("modulate_add")
				dxDrawRectangle(0, 0, size, size, tocolor(0, 0, 0))
				dxDrawText(utf8.char(tonumber("0x" .. faIcons[icon].unicode)), 0, 0, size, size, tocolor(255, 255, 255), 1, font, "center", "center")
				dxSetRenderTarget(rt, true)
				dxSetBlendMode("overwrite")
				dxDrawImage(0, 0, size, size, shader)
				dxSetBlendMode("blend")
				dxSetRenderTarget()
			end
			local pixels = dxGetTexturePixels(rt)

			if isElement(rt) then
				destroyElement(rt)
			end
			rt = nil
			
			if isElement(rt2) then
				destroyElement(rt2)
			end
			rt2 = nil
			
			if isElement(shader) then
				destroyElement(shader)
			end
			shader = nil
			
			destroyElement(font)
			font = nil

			if pixels then
				pixels = dxConvertPixels(pixels, "png")
				local file = fileCreate(fileName)
				fileWrite(file, pixels)
				fileClose(file)

				pixels = nil
			end 
			collectgarbage("collect")
		end 
	end
	return fileName
end