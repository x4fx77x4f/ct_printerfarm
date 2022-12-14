--@name Printer farm
--@server
--@include ./client.lua
--@clientmain ./client.lua
--@include ./shared.lua
local pf = dofile('./shared.lua')

function pf.tprint(target, ...)
	net.start(pf.ID_NET)
		net.writeUInt(pf.NET_PRINT, pf.NET_BITS)
		for i=1, select('#', ...) do
			local v = select(i, ...)
			if v == nil then
				break
			elseif type(v) == 'Color' then
				net.writeBit(1)
				net.writeUInt(v[1], 8)
				net.writeUInt(v[2], 8)
				net.writeUInt(v[3], 8)
			elseif isstring(v) then
				net.writeBit(0)
				net.writeString(v)
			else
				error(string.format("bad argument #%d to '%s' (Color or string expected, got %s)", i+1, debug.getinfo(1, 'n').name, type(v)), 2)
			end
		end
	net.send(target)
end
function pf.tprintf(target, ...)
	return pf.tprint(target, string.format(...))
end
function pf.print(...)
	return pf.tprint(nil, ...)
end

pf.command_prefix = string.format("$%d ", chip():entIndex())
pf.commands = {}
pf.command_help = {}
hook.add('PlayerSay', pf.ID_HOOK, function(sender, message, is_team)
	if string.sub(message, 1, #pf.command_prefix) == pf.command_prefix then
		message = string.sub(message, #pf.command_prefix+1)
	else
		return
	end
	local first_space = string.find(message, ' ', nil, true)
	local command = string.lower(first_space == nil and message or string.sub(message, 1, first_space-1))
	local command_func = pf.commands[command]
	if command_func ~= nil then
		local parameters = first_space == nil and "" or string.sub(message, first_space+1)
		local success, retval = command_func(sender, command, parameters, is_team)
		if not success then
			if type(retval) == 'table' then
				retval = rawget(retval, 'message')
			end
			retval = tostring(retval)
			pf.tprint(sender, retval)
		end
		return ""
	end
	pf.tprintf(sender, "Unknown command %q.", command)
	return ""
end)
pf.commands.help = function(sender, command, parameters, is_team)
	if parameters ~= '' then
		local help = pf.command_help[parameters]
		if help == nil then
			return false, "No such command %q."
		end
		pf.tprintf(sender, "Help for %q: %s", parameters, help)
		return true
	end
	local commands_list = {}
	for k in pairs(pf.commands) do
		table.insert(commands_list, k)
	end
	table.sort(commands_list)
	commands_list = table.concat(commands_list, ", ")
	pf.tprintf(sender, "Available commands: %s", commands_list)
	return true
end
pf.command_help.help = "Get documentation for command, or list all commands if none specified."

pf.commands.l = function(sender, command, parameters, is_team)
	if sender ~= owner() then
		return false, "Not authorized."
	end
	local func, err = loadstring('local pf, me, this, there = ...\n'..parameters, "pf_l")
	if func ~= nil and type(func) ~= 'function' then
		func, err = nil, func
	end
	if func == nil then
		if type(err) == 'table' then
			err = rawget(err, 'message')
		end
		err = tostring(err)
		return false, "Compilation error: "..err
	end
	local trace = sender:getEyeTrace()
	local success
	success, err = pcall(func, pf, sender, trace.Entity, trace.HitPos)
	if not success then
		if type(err) == 'table' then
			err = rawget(err, 'message')
		end
		err = tostring(err)
		return false, "Runtime error: "..err
	end
	return true
end
pf.command_help.l = "Run Lua code."

pf.aabbs = {}
if game.getMap() == 'rp_construct_b5' then
	table.insert(pf.aabbs, {Vector(-1352, -2560, 48), Vector(-864, -2368, 176)})
	table.insert(pf.aabbs, {Vector(-1104, -2368, 48), Vector(-864, -2080, 176)})
end
pf.commands.aabb_list = function(sender, command, parameters, is_team)
	if sender ~= owner() then
		return false, "Not authorized."
	end
	local aabbs = pf.aabbs
	if #aabbs == 0 then
		pf.tprint(sender, "No AABBs.")
		return true
	end
	for i=1, #aabbs do
		local aabb = aabbs[i]
		local mins, maxs = aabb[1], aabb[2]
		pf.tprintf(sender, "%d: Vector(%s, %s, %s), Vector(%s, %s, %s)", i, mins[1], mins[2], mins[3], maxs[1], maxs[2], maxs[3])
	end
	return true
end
pf.command_help.aabb_list = "List AABBs."
pf.commands.aabb_clear = function(sender, command, parameters, is_team)
	if sender ~= owner() then
		return false, "Not authorized."
	end
	pf.aabbs = {}
	pf.tprint(sender, "Cleared.")
	return true
end
pf.command_help.aabb_clear = "Clear list of AABBs."
local function parse_vector(parameter)
	if string.sub(parameter, -1, -1) == ')' then
		if string.sub(parameter, 1, 7) == 'Vector(' then
			parameter = string.sub(parameter, 8, -2)
		elseif string.sub(parameter, 1, 1) == '(' then
			parameter = string.sub(parameter, 2, -2)
		end
	end
	local first_comma = string.find(parameter, ',', 1, true)
	if first_comma == nil then
		return nil
	end
	local second_comma = string.find(parameter, ',', first_comma+1, true)
	if second_comma == nil then
		return nil
	end
	local x = tonumber(string.sub(parameter, 1, first_comma-1))
	local y = tonumber(string.sub(parameter, first_comma+1, second_comma-1))
	local z = tonumber(string.sub(parameter, second_comma+1))
	if x == nil or y == nil or z == nil then
		return nil
	end
	return Vector(x, y, z)
end
pf.commands.aabb_add = function(sender, command, parameters, is_team)
	if sender ~= owner() then
		return false, "Not authorized."
	end
	local first_space = string.find(parameters, ' ', 1, true)
	if first_space == nil then
		return false, "Malformed parameters."
	end
	local mins = parse_vector(string.sub(parameters, 1, first_space-1))
	local maxs = parse_vector(string.sub(parameters, first_space+1))
	if mins == nil or maxs == nil then
		return false, "Malformed parameters."
	end
	local minx, miny, minz = math.min(mins[1], maxs[1]), math.min(mins[2], maxs[2]), math.min(mins[3], maxs[3])
	local maxx, maxy, maxz = math.max(mins[1], maxs[1]), math.max(mins[2], maxs[2]), math.max(mins[3], maxs[3])
	mins, maxs = Vector(minx, miny, minz), Vector(maxx, maxy, maxz)
	table.insert(pf.aabbs, {mins, maxs})
	pf.tprint(sender, "Added.")
	return true
end
pf.command_help.aabb_add = "Add AABB to list."
pf.commands.aabb_remove = function(sender, command, parameters, is_team)
	if sender ~= owner() then
		return false, "Not authorized."
	end
	local i = tonumber(parameters)
	if i == nil then
		return false, "Malformed parameters."
	end
	local aabbs = pf.aabbs
	if aabbs[i] == nil then
		return false, "No such AABB."
	end
	table.remove(aabbs, i)
	pf.tprint(sender, "Removed.")
	return true
end
pf.command_help.aabb_remove = "Remove AABB from list."

hook.add('ClientInitialized', pf.ID_HOOK, function(ply)
	if ply ~= owner() then
		return
	end
	pf.tprintf(ply, "Run \"%shelp\" for commands.", pf.command_prefix)
end)

function pf.is_entity_in_aabb(printer)
	local pos = printer:obbCenterW()
	local posx, posy, posz = pos[1], pos[2], pos[3]
	local aabbs = pf.aabbs
	for i=1, #aabbs do
		local aabb = aabbs[i]
		local mins, maxs = aabb[1], aabb[2]
		local minx, miny, minz = mins[1], mins[2], mins[3]
		local maxx, maxy, maxz = maxs[1], maxs[2], maxs[3]
		if (
			posx >= minx and posx < maxx
			and posy >= miny and posy < maxy
			and posz >= minz and posz < maxz
		) then
			return true, i
		end
	end
	return false
end
function pf.extinguish_update()
	local extinguishing = pf.extinguishing
	net.start(pf.ID_NET)
		net.writeUInt(extinguishing, pf.NET_BITS)
		if extinguishing == pf.NET_EXTINGUISHING_PRE then
			net.writeEntity(pf.extinguishee)
		end
	net.send(pf.extinguisher)
end
pf.seat_pos = Vector(0, 0, 0)
pf.seat = prop.createSeat(pf.seat_pos, Angle(), 'models/hunter/plates/plate.mdl', true)
pf.seat:setNoDraw(false)
pf.seat:setSolid(false)
pf.seat:setColor(Color(0, 0, 0, 0))
pf.seat:setDrawShadow(false)
function pf.extinguish_teleport(sender, pos, target)
	if not pcall(sender.setPos, sender, pos) then
		local seat = pf.seat
		local eyeangles_old = sender:getEyeAngles()
		seat:setPos(pos)
		seat:use()
		seat:ejectDriver()
		seat:setPos(pf.seat_pos)
		pcall(sender.setEyeAngles, sender, eyeangles_old)
	end
end
function pf.extinguish(extinguishee, extinguisher)
	if extinguisher == nil then
		extinguisher = owner()
	end
	pf.extinguisher = extinguisher
	pf.extinguishee = extinguishee
	pf.extinguishing = pf.NET_EXTINGUISHING_PRE
	pf.extinguish_update()
	timer.simple(2, function()
		if not isValid(extinguisher) or not isValid(extinguishee) then
			return
		end
		pf.extinguishing = pf.NET_EXTINGUISHING_TELEPORT
		pf.extinguish_update()
		local pos_old = extinguisher:getPos()
		pf.extinguish_teleport(extinguisher, extinguishee:getPos())
		timer.simple(1, function()
			if not isValid(extinguisher) or not isValid(extinguishee) then
				return
			end
			pf.extinguishing = pf.NET_EXTINGUISHING_TELEPORTPOST
			pf.extinguish_update()
			timer.simple(0.5, function()
				if not isValid(extinguisher) or not isValid(extinguishee) then
					return
				end
				pf.extinguishing = pf.NET_EXTINGUISHING_POCKET
				pf.extinguish_update()
				timer.simple(1, function()
					if not isValid(extinguisher) then
						return
					end
					pf.extinguishing = pf.NET_EXTINGUISHING_UNPOCKET
					pf.extinguish_update()
					timer.simple(1, function()
						if not isValid(extinguisher) then
							return
						end
						pf.extinguish_teleport(extinguisher, pos_old)
						timer.simple(0.5, function()
							pf.extinguishing = pf.NET_EXTINGUISHING_NULL
							pf.extinguish_update()
						end)
					end)
				end)
			end)
		end)
	end)
end
pf.extinguish_queue = {}
function pf.extinguish_tick()
	if pf.extinguishing ~= pf.NET_EXTINGUISHING_NULL then
		return
	end
	local queue = pf.extinguish_queue
	for i=#queue, 1, -1 do
		local printer, extinguisher = queue[i]
		if type(printer) ~= 'Entity' then
			printer, extinguisher = printer[1], printer[2]
		end
		if isValid(printer) then
			pf.extinguish(printer, extinguisher)
			queue[i] = nil
			break
		else
			pf.printf("Invalid printer %q in queue at %d.", tostring(printer), i)
			queue[i] = nil
		end
	end
end
pf.commands.extinguish = function(sender, command, parameters, is_team)
	if sender ~= owner() then
		return false, "Not authorized."
	end
	local target = tonumber(parameters)
	if target == nil then
		return false, "Malformed parameters."
	end
	target = entity(target)
	if not isValid(target) then
		return false, "Invalid entity."
	end
	table.insert(pf.extinguish_queue, {target, sender})
	return true
end
pf.command_help.extinguish = "Manually trigger an extinguishing of a printer."
hook.add('moneyPrinterCatchFire', pf.ID_HOOK, function(printer)
	if not pf.is_entity_in_aabb(printer) then
		return
	end
	if pf.VERBOSE then
		pf.tprintf(owner(), "moneyPrinterCatchFire: %s", tostring(printer))
	end
	table.insert(pf.extinguish_queue, printer)
end)

wire.adjustPorts({User='entity'}, {Use='number'})
function pf.collect(printer)
	local ports = wire.ports
	local user = ports.User
	if not isValid(user) then
		return
	end
	local pos_old = user:getPos()
	local angles_old = user:getAngles()
	local frozen_old = user:isFrozen()
	user:setFrozen(true)
	user:setPos(printer:obbCenterW())
	user:setAngles(Angle())
	ports.Use = 1
	ports.Use = 0
	user:setPos(pos_old)
	user:setAngles(angles_old)
	user:setFrozen(frozen_old)
end
pf.collect_queue = {}
pf.start_time = timer.curtime()
pf.total_money_collected = 0
hook.add('moneyPrinterPrinted', pf.ID_HOOK, function(printer, bag)
	if not pf.is_entity_in_aabb(printer) then
		return
	end
	pf.tprintf(owner(), "moneyPrinterPrinted: %s, %s", tostring(printer), tostring(bag))
end)
hook.add('moneyPrinterPrintMoney', pf.ID_HOOK, function(printer, amount)
	if not pf.is_entity_in_aabb(printer) then
		return
	end
	if pf.VERBOSE then
		pf.tprintf(owner(), "moneyPrinterPrintMoney: %s, %s", tostring(printer), darkrp.formatMoney(amount))
	end
	pf.total_money_collected = pf.total_money_collected+amount
	table.insert(pf.collect_queue, printer)
end)
pf.every_tick = true
pf.is_on_fire = {}
pf.collect_order = {}
function pf.collect_tick()
	local collect = pf.collect
	if pf.every_tick then
		local is_entity_in_aabb = pf.is_entity_in_aabb
		local is_on_fire = pf.is_on_fire
		local extinguish_queue = pf.extinguish_queue
		local collect_order = pf.collect_order
		local coi = pf.collect_order_i
		if coi == nil then
			coi = 1
		else
			coi = coi+1
		end
		local coj = #collect_order
		if coi >= coj and coj ~= 0 then
			coi = (coi-1)%coj+1
		end
		local coe = collect_order[coi]
		pf.collect_order_i = coi
		for i=1, #collect_order do
			local printer = collect_order[i]
			if isValid(printer) then
				if printer:isOnFire() and not is_on_fire[printer] then
					is_on_fire[printer] = true
					table.insert(extinguish_queue, printer)
				end
				if printer == coe then
					collect(printer)
				end
			end
		end
		for printer in pairs(is_on_fire) do
			if not printer:isValid() or not printer:isOnFire() then
				is_on_fire[printer] = nil
			end
		end
		return
	end
	local queue = pf.collect_queue
	local isValid = isValid
	for i=#queue, 1, -1 do
		local printer = queue[i]
		if isValid(printer) then
			collect(printer)
			queue[i] = nil
		else
			queue[i] = nil
		end
	end
end
timer.create(pf.ID_TIMER, 1, 0, function()
	if not pf.every_tick then
		return
	end
	local is_entity_in_aabb = pf.is_entity_in_aabb
	local collect_order = {}
	local printers = find.byClass('scriptis_printer')
	for i=1, #printers do
		local printer = printers[i]
		if is_entity_in_aabb(printer) then
			table.insert(collect_order, printer)
		end
	end
	pf.collect_order = collect_order
end)
pf.commands.stats = function(sender, command, parameters, is_team)
	if sender ~= owner() then
		return false, "Not authorized"
	end
	local now = timer.curtime()
	local uptime = now-pf.start_time
	pf.tprintf(sender, "Collected a total of %s over %s.", darkrp.formatMoney(pf.total_money_collected), string.niceTime(uptime))
	return true
end
pf.command_help.stats = "Display total collected money and uptime."

hook.add('tick', pf.ID_HOOK, function()
	pf.extinguish_tick()
	pf.collect_tick()
end)
