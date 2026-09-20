local Teleporter = require("components/teleporter")
local UpvalueHacker = require("tools/upvaluehacker")
local old_Teleport = Teleporter.Teleport
local old_ReceivePlayer = Teleporter.ReceivePlayer

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

-- 幽灵 SG 有 jumpout，没有 abyss_drop / 进塔落地。到达时改 jumpout。
local old_ondoerarrive = UpvalueHacker.GetUpvalue(old_ReceivePlayer, "ondoerarrive")
if old_ondoerarrive ~= nil then
	local function ondoerarrive(inst, self, doer)
		local saved
		if doer ~= nil and doer:IsValid() and doer:HasTag("playerghost") then
			saved = self.overrideteleportarrivestate
			if saved ~= nil and saved ~= "jumpout" then
				self.overrideteleportarrivestate = "jumpout"
			end
		end
		old_ondoerarrive(inst, self, doer)
		if saved ~= nil then
			self.overrideteleportarrivestate = saved
		end
	end
	UpvalueHacker.SetUpvalue(old_ReceivePlayer, ondoerarrive, "ondoerarrive")
end
