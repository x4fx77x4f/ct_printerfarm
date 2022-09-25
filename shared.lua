--@shared
local pf = {}

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
function pf.bitfield(prefix, bitfield)
	local bits = #bitfield
	assert(bits >= 1, "number qq")
	assert(bits <= 31, "number of values in bitfield cannot exceed 31")
	prefix = prefix..'_'
	pf[prefix..'BITS'] = bits
	for i=1, #bitfield do
		pf[prefix..bitfield[i]] = bit.lshift(1, i-1)
	end
end

pf.ID_NET = ''
pf.ID_HOOK = ''
pf.ID_TIMER = ''
pf.enum('NET', {
	'PRINT', -- CB: Display message in chat
	'EXTINGUISHING_NULL', -- CB
	'EXTINGUISHING_PRE', -- CB
	'EXTINGUISHING_TELEPORT', -- CB
	'EXTINGUISHING_TELEPORTPOST', -- CB
	'EXTINGUISHING_POCKET', -- CB
	'EXTINGUISHING_UNPOCKET', -- CB
	'READY', -- SB
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

pf.output_color = Color(191, 191, 191, 255)
pf.output_prefix = string.format("[%d] ", chip():entIndex())
pf.output_prefix_color = Color('#4d7bc8')
pf.color_menu = Color('#4caf50')
pf.color_client = Color('#dea909')
pf.color_server = Color('#03a9f4')
function pf.printf(...)
	return pf.print(string.format(...))
end

pf.extinguishing = pf.NET_EXTINGUISHING_NULL

pf.bitfield('READY', {
	'CONCMD',
	'INPUTEMULATE',
	'SETEYEANGLES',
	'USER',
})

return pf
