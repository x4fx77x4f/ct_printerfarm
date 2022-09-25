-- 1. Put this somewhere in your 'garrysmod/lua/' folder.
-- 2. Flash ctpf to a chip if you haven't already.
-- 3. Look directly at the chip.
-- 4. Run this script with 'lua_openscript_cl'.
local me = LocalPlayer()
local this = me:GetEyeTrace().Entity
if not IsValid(this) then
	print("Invalid entity")
	return
end
local instance = this.instance
if instance == nil then
	print("No instance")
	return
end
local function setEyeAngles(self, angles)
	self = instance.Types.Entity.GetEntity(self)
	angles = instance.Types.Angle.Unwrap(angles)
	if (self ~= me or self ~= instance.player) and instance.player ~= SF.Superuser then
		SF.Throw("may only set your own angles on your own chip", 2)
		return
	end
	self:SetEyeAngles(angles)
end
rawset(instance.Types.Player.Methods, 'setEyeAngles', setEyeAngles)
print("OK")
