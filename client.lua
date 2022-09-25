--@name Printer farm
--@client
--@include ./shared.lua
local pf = dofile('./shared.lua')
setName(pf.output_prefix..chip():getChipName())

if player() == owner() then
	pcall(enableHud, player(), true)
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
			local r = net.readUInt(8)
			local g = net.readUInt(8)
			local b = net.readUInt(8)
			t[i] = Color(r, g, b)
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
	if pf.extinguishing ~= pf.NET_EXTINGUISHING_NULL then
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
function pf.lookat(target)
	local pos = target:obbCenterW()
	pos:sub(eyePos())
	pos:normalize()
	player():setEyeAngles(pos:getAngle())
end
pf.net_incoming[pf.NET_EXTINGUISHING_PRE] = function(length)
	pf.extinguishing = pf.NET_EXTINGUISHING_PRE
	pf.extinguishee = net.readEntity()
	pf.extinguisher_eyeangles_old = eyeAngles()
end
pf.net_incoming[pf.NET_EXTINGUISHING_TELEPORT] = function(length)
	pf.extinguishing = pf.NET_EXTINGUISHING_TELEPORT
	pf.extinguisher_activeweapon_old = player():getActiveWeapon()
	input.selectWeapon(player():getWeapon('pocket'))
	pf.lookat(pf.extinguishee)
	concmd('+duck')
end
pf.net_incoming[pf.NET_EXTINGUISHING_TELEPORTPOST] = function(length)
	pf.extinguishing = pf.NET_EXTINGUISHING_TELEPORTPOST
	pf.extinguisher_activeweapon_old = player():getActiveWeapon()
	input.selectWeapon(player():getWeapon('pocket'))
	pf.lookat(pf.extinguishee)
end
pf.net_incoming[pf.NET_EXTINGUISHING_POCKET] = function(length)
	pf.extinguishing = pf.NET_EXTINGUISHING_POCKET
	input.selectWeapon(player():getWeapon('pocket'))
	pf.lookat(pf.extinguishee)
	concmd('+attack')
	timer.simple(0, function()
		concmd('-attack')
	end)
end
pf.net_incoming[pf.NET_EXTINGUISHING_UNPOCKET] = function(length)
	pf.extinguishing = pf.NET_EXTINGUISHING_UNPOCKET
	input.selectWeapon(player():getWeapon('pocket'))
	concmd('+attack2')
	timer.simple(0, function()
		concmd('-attack2')
	end)
end
pf.net_incoming[pf.NET_EXTINGUISHING_NULL] = function(length)
	pf.extinguishing = pf.NET_EXTINGUISHING_NULL
	input.selectWeapon(pf.extinguisher_activeweapon_old)
	player():setEyeAngles(pf.extinguisher_eyeangles_old)
	concmd('-duck')
end

function pf.get_ready()
	local ready = 0
	if not hasPermission('console.command') then
		ready = bit.bor(ready, pf.READY_CONCMD)
	end
	if not hasPermission('input.emulate') then
		ready = bit.bor(ready, pf.READY_INPUTEMULATE)
	end
	if player().setEyeAngles == nil then
		ready = bit.bor(ready, pf.READY_SETEYEANGLES)
	end
	pf.ready = ready
	return ready, pf.READY_BITS
end
net.start(pf.ID_NET)
	net.writeUInt(pf.NET_READY, pf.NET_BITS)
	net.writeUInt(pf.get_ready())
net.send()
