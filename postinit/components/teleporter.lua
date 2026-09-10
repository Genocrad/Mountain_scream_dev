local Teleporter = require("components/teleporter")
local old_Teleport = Teleporter.Teleport


local ENV = env
GLOBAL.setfenv(1, GLOBAL)

function Teleporter:Teleport(obj, ...)
	-- Fixed teleport_offset: land exactly at destination + offset (no long search — that overshot through the mountain).
	local targetDesination = self.targetTeleporterTemporary or self.targetTeleporter
	local targetTeleporter = self.targetTeleporterTemporary or (self.selfmanaged and self.inst) or self.targetTeleporter
	if targetDesination ~= nil
		and targetDesination.components.teleporter ~= nil
		and targetDesination.components.teleporter.teleport_offset then
		local notself = targetDesination.components.teleporter
		if targetTeleporter ~= nil then
			local target_x, target_y, target_z = targetDesination.Transform:GetWorldPosition()
			local ox = notself.teleport_offset.x or 0
			local oy = notself.teleport_offset.y or 0
			local oz = notself.teleport_offset.z or 0
			if obj.Physics ~= nil then
				obj.Physics:Teleport(target_x + ox, target_y + oy, target_z + oz)
			elseif obj.Transform ~= nil then
				obj.Transform:SetPosition(target_x + ox, target_y + oy, target_z + oz)
			end
		end
	else
		old_Teleport(self, obj, ...)
	end
end
