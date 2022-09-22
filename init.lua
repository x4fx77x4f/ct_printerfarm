--@name Printer farm
--@server
--@include ./client.lua
--@clientmain ./client.lua
--@include ./shared.lua
local pf = dofile('./shared.lua')

function pf.tprint(target, ...)
	net.start(pf.ID_NET)
		net.writeUInt(pf.NET_PRINT, pf.NET_BITS)
		local j = select('#', ...)
		net.writeUInt(j, 8)
		for i=1, j do
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

hook.add('moneyPrinterCatchFire', pf.ID_HOOK, function(printer)
	pf.tprintf(owner(), "moneyPrinterCatchFire: %s", tostring(printer))
end)
hook.add('moneyPrinterPrinted', pf.ID_HOOK, function(printer, bag)
	pf.tprintf(owner(), "moneyPrinterPrinted: %s, %s", tostring(printer), tostring(bag))
end)
hook.add('moneyPrinterPrintMoney', pf.ID_HOOK, function(printer, amount)
	pf.tprintf(owner(), "moneyPrinterPrintMoney: %s, %s", tostring(printer), darkrp.formatMoney(amount))
end)
