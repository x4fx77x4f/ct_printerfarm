--@name Printer farm
--@client
--@include ./shared.lua
local pf = dofile('./shared.lua')

if player() == owner() then
	function pf.print(...)
		return print(pf.output_prefix_color, pf.output_prefix, pf.output_color, ...)
	end
else
	function pf.print(...)
		if canPrintLocal ~= nil and canPrintLocal() then
			return printLocal(pf.output_prefix_color, pf.output_prefix, pf.output_color, ...)
		elseif render.isHUDActive() then
			return pcall(printHud, pf.output_prefix_color, pf.output_prefix, pf.output_color, ...)
		end
	end
end
pf.net_incoming[pf.NET_PRINT] = function(length)
	local t, i = {}, 0
	while true do
		i = i+1
		length = length-1
		if length < 0 then
			break
		elseif net.readBit() == 1 then
			length = length-8*3
			if length < 0 then
				break
			end
			t[i] = net.readColor(false)
		else
			local s = net.readString()
			length = length-(#s+1)*8
			t[i] = s
		end
	end
	return pf.print(unpack(t))
end

pf.color_bg = Color(31, 31, 31, 223)
pf.color_bg_border = Color(127, 127, 127)
pf.color_fg = Color(223, 223, 223)
pf.color_fg_error = Color(255, 127, 127)
pf.color_fg_warning = Color(255, 255, 127)
pf.color_fg_success = Color(127, 255, 127)
hook.add('drawhud', pf.ID_HOOK, function()
	if pf.extinguishing ~= nil then
		local p = 8
		local sw, sh = render.getResolution()
		local w, h = 640, 240
		local x, y = (sw-w)/2, (sh-h)/2
		render.setColor(pf.color_bg)
		render.drawRect(x, y, w, h)
		render.setColor(pf.color_bg_border)
		render.drawRectOutline(x, y, w, h, 2)
		x, y = x+w/2, y+p
		local hm = Matrix()
		hm:setTranslation(Vector(x, y, 0))
		local hs = 4
		hm:setScale(Vector(hs, hs, 1))
		render.setColor(pf.color_fg_error)
		render.setFont('DermaLarge')
		render.pushMatrix(hm)
			local ew, eh = render.drawSimpleText(0, 0, "Stop!", TEXT_ALIGN.CENTER)
		render.popMatrix()
		y = y+eh*hs+p
		render.setColor(pf.color_fg)
		render.setFont('DermaLarge')
		ew, eh = render.drawSimpleText(x, y, "Hands off all input devices!", TEXT_ALIGN.CENTER)
		y = y+eh+p
		render.setFont('DermaDefault')
		ew, eh = render.drawSimpleText(x, y, "One of your money printers is on fire.", TEXT_ALIGN.CENTER)
		y = y+eh+p
		ew, eh = render.drawSimpleText(x, y, "Moving or looking around could disrupt the automated extinguishing process.", TEXT_ALIGN.CENTER)
		y = y+eh+p
	end
end)
if player() == owner() then
	pcall(enableHud, player(), true)
end
