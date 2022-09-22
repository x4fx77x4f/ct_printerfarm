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
				net.writeColor(v, false)
			else
				net.writeBit(0)
				net.writeString(v)
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

pf.whitelist = {}
local printers = find.byClass('scriptis_printer')
for i=1, #printers do
	pf.whitelist[printers[i]] = {
		owner = owner(),
	}
end

hook.add('moneyPrinterCatchFire', pf.ID_HOOK, function(printer)
	pf.tprintf(owner(), "moneyPrinterCatchFire: %s", tostring(printer))
end)
hook.add('moneyPrinterPrinted', pf.ID_HOOK, function(printer, bag)
	pf.tprintf(owner(), "moneyPrinterPrinted: %s, %s", tostring(printer), tostring(bag))
end)
hook.add('moneyPrinterPrintMoney', pf.ID_HOOK, function(printer, amount)
	pf.tprintf(owner(), "moneyPrinterPrintMoney: %s, %s", tostring(printer), darkrp.formatMoney(amount))
end)

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
			pf.tprintf(sender, retval)
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
	local func, err = loadstring('local pf, me = ...\n'..parameters, "pf_l")
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
	local success
	success, err = pcall(func, pf, sender)
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

pf.printf("Run \"%shelp\" for commands.", pf.command_prefix)
