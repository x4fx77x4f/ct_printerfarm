--@shared
local pf = {}

pf.output_color = Color(191, 191, 191, 255)
pf.output_prefix = string.format("[%d] ", chip():entIndex())
pf.output_prefix_color = Color('#4d7bc8')
pf.color_menu = Color('#4caf50')
pf.color_client = Color('#dea909')
pf.color_server = Color('#03a9f4')
function pf.printf(...)
	return pf.print(string.format(...))
end

function pf.enum(prefix, enum)
	local bits = 1
	while 2^bits < #enum do
		bits = bits+1
	end
	assert(bits <= 32, "number of values in enum cannot exceed 2^32")
	prefix = prefix..'_'
	pf[prefix..'BITS'] = bits
	for i=1, #enum do
		pf[prefix..enum[i]] = i-1
	end
end
pf.ID_NET = ''
pf.ID_HOOK = ''
pf.ID_TIMER = ''
pf.enum('NET', {
	'PRINT', -- CB: Display message in chat
	'WHITELIST_CLEAR', -- SB/CB: Clear printer list
	'WHITELIST_ADD', -- SB/CB: Add entity to printer list
	'WHITELIST_REMOVE', -- SB/CB: Remove entity from printer list
})
pf.net_incoming = {}
net.receive(pf.ID_NET, function(length, sender)
	if SERVER and not isValid(sender) then
		return
	end
	repeat
		length = length-pf.NET_BITS
		if length < 0 then
			return
		end
		local packet_type = net.readUInt(pf.NET_BITS)
		local packet_handler = pf.net_incoming[packet_type]
		if packet_handler == nil then
			break
		end
		length = packet_handler(length, sender)
	until length == nil
end)

return pf
